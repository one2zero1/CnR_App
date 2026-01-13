import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audio_session/audio_session.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_database/firebase_database.dart';
import 'auth_service.dart';
import '../models/game_types.dart';

class VoiceService {
  final AuthService _authService;

  // Audio Components
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();

  bool _isInit = false;

  // Recording State
  StreamSubscription<List<int>>? _recorderSubscription;
  String? _currentStreamId;
  int _currentSequence = 0;

  // Buffer for micro-chunking (accumulate PCM bytes until 300ms)
  // 16kHz * 1ch * 2 bytes/sample = 32000 bytes/sec.
  // 300ms = 9600 bytes.
  final List<int> _audioBuffer = [];
  final int _chunkSize = 9600;

  // Receiving State
  StreamSubscription? _firebaseSubscription;

  // Jitter Buffer: Map<streamId, PriorityQueue<AudioChunk>>
  // For sound_stream, we just write to player buffer.
  // Ideally implementation needs sequencing, but for MVP we feed directly.

  final StreamController<bool> _isTalkingController =
      StreamController.broadcast();
  Stream<bool> get isTalkingStream => _isTalkingController.stream;

  final StreamController<String> _whoIsTalkingController =
      StreamController.broadcast();
  Stream<String> get whoIsTalkingStream => _whoIsTalkingController.stream;

  VoiceService(this._authService);

  Future<void> init() async {
    debugPrint('VoiceService: init called');
    if (_isInit) {
      debugPrint('VoiceService: Already initialized');
      return;
    }

    await _requestPermissions();
    await _initAudioSession();

    await _recorder.initialize();
    await _player.initialize();

    _isInit = true;
    debugPrint('VoiceService: init complete');
  }

  Future<void> _requestPermissions() async {
    debugPrint('VoiceService: Requesting microphone permission');
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      debugPrint('VoiceService: Microphone permission denied: $status');
      // Should we throw or handle?
    } else {
      debugPrint('VoiceService: Microphone permission granted');
    }
  }

  Future<void> _initAudioSession() async {
    // sound_stream might handle this internally but explicit config is safer for iOS background
    final session = await AudioSession.instance;
    await session.configure(
      const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
        avAudioSessionCategoryOptions:
            AVAudioSessionCategoryOptions.defaultToSpeaker,
        avAudioSessionMode: AVAudioSessionMode.voiceChat,
        avAudioSessionRouteSharingPolicy:
            AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.speech,
          flags: AndroidAudioFlags.none,
          usage: AndroidAudioUsage.voiceCommunication,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: true,
      ),
    );
  }

  void dispose() {
    _recorderSubscription?.cancel();
    _firebaseSubscription?.cancel();
    _recorder.stop(); // Stop if running
    // _player.stop(); // Player cleanup?
    _isTalkingController.close();
    _whoIsTalkingController.close();
  }

  // --- Sending ---

  Future<void> startRecording(String roomId, TeamRole myTeam) async {
    debugPrint('VoiceService: startRecording');
    if (!_isInit) {
      debugPrint('VoiceService: Not initialized, calling init()');
      await init();
    }

    final user = _authService.currentUser;
    if (user == null) {
      debugPrint('VoiceService: No user found');
      return;
    }

    _currentStreamId = const Uuid().v4();
    _currentSequence = 1;
    _audioBuffer.clear();
    _isTalkingController.add(true);
    debugPrint('VoiceService: Recorder stream starting');

    // ... (rest of stream code)

    _recorderSubscription = _recorder.audioStream.listen((data) {
      if (data.isEmpty) return;
      // debugPrint('VoiceService: Stream data received: ${data.length} bytes');
      _audioBuffer.addAll(data);
      if (_audioBuffer.length >= _chunkSize) {
        debugPrint(
          'VoiceService: Buffer full (${_audioBuffer.length}), sending chunk',
        );
        // Extract chunk
        final chunk = Uint8List.fromList(_audioBuffer.sublist(0, _chunkSize));
        _audioBuffer.removeRange(0, _chunkSize);
        _sendChunk(roomId, user.uid, user.nickname, myTeam, chunk, false);
      }
    });

    await _recorder.start();
  }

  Future<void> stopRecording(
    String roomId,
    String uid,
    String nickname,
    TeamRole team,
  ) async {
    if (!_isInit) return;

    await _recorder.stop();
    _recorderSubscription?.cancel();
    _isTalkingController.add(false);

    // Send remaining buffer
    if (_audioBuffer.isNotEmpty) {
      _sendChunk(
        roomId,
        uid,
        nickname,
        team,
        Uint8List.fromList(_audioBuffer),
        false,
      );
      _audioBuffer.clear();
    }

    // Send Last Chunk marker
    await _sendChunk(roomId, uid, nickname, team, Uint8List(0), true);
  }

  Future<void> _sendChunk(
    String roomId,
    String uid,
    String nickname,
    TeamRole team,
    Uint8List data,
    bool isLast,
  ) async {
    // If empty and not last, skip (but stopRecording handles sending leftover)
    if (data.isEmpty && !isLast) return;

    final seq = _currentSequence++;
    final streamId = _currentStreamId!;

    try {
      final body = {
        "sender_id": uid,
        "sender_name": nickname,
        "team": team.name,
        "stream_id": streamId,
        "sequence": seq,
        "is_last": isLast,
        "duration_ms": 300,
        "voice_data": base64Encode(data),
        "timestamp": ServerValue.timestamp,
      };

      debugPrint(
        'VoiceService: Sending chunk (seq: $seq, size: ${data.length}, isLast: $isLast)',
      );
      debugPrint(
        'VoiceService: Writing chunk to DB (seq: $seq, size: ${data.length})',
      );

      final ref = FirebaseDatabase.instance.ref('voice_chat/$roomId');
      ref.push().set(body).catchError((e) {
        debugPrint('VoiceService: Firebase write error: $e');
      });
    } catch (e) {
      debugPrint('Error preparing chunk: $e');
    }
  }

  // --- Receiving ---

  Future<void> startListening(String roomId, TeamRole myTeam) async {
    if (!_isInit) await init();

    final ref = FirebaseDatabase.instance.ref('voice_chat/$roomId');

    // Start player (it will idle until data is written)
    await _player.start();

    // Listen new events
    _firebaseSubscription = ref
        .limitToLast(10)
        .onChildAdded
        .listen(
          (event) {
            final val = event.snapshot.value;
            if (val == null) return;

            try {
              final data = Map<String, dynamic>.from(val as Map);
              _onDataReceived(data, myTeam);
            } catch (e) {
              debugPrint('Error parsing voice data: $e');
            }
          },
          onError: (error) {
            debugPrint('Voice Service error (likely permission): $error');
          },
        );
  }

  void stopListening() {
    _firebaseSubscription?.cancel();
    _player.stop();
  }

  void _onDataReceived(Map<String, dynamic> data, TeamRole myTeam) {
    if (_authService.currentUser == null) return;
    final myUid = _authService.currentUser!.uid;

    final senderId = data['sender_id'];
    final teamStr = data['team'];

    if (senderId == myUid) return;
    if (teamStr != myTeam.name) return;

    final encodedData = data['voice_data'] as String;
    final senderName = data['sender_name'] as String? ?? 'Unknown';

    _whoIsTalkingController.add(senderName);

    if (encodedData.isNotEmpty) {
      final bytes = base64Decode(encodedData);
      // Write to player buffer directly
      _player.writeChunk(bytes);
    }
  }
}
