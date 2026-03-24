import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// import 'package:device_info_plus/device_info_plus.dart';

class AppSessionManager {
  // 싱글톤 인스턴스
  static final AppSessionManager _instance = AppSessionManager._internal();
  factory AppSessionManager() => _instance;
  AppSessionManager._internal();

  final String serverType = 'image';

  // 사용자 정보
  String id = '';
  String password = '';

  // 서버 연결 정보
  String ip = '';
  String port = '';

  // WebSocket 관리
  WebSocketChannel? channel;
  final _responseController = StreamController<dynamic>.broadcast();

  /// 로그인 시 데이터 초기화
  void initialize({
    required String ip,
    required String port,
    required String id,
    required String password,
  }) {
    this.ip = ip;
    this.port = port;
    this.id = id;
    this.password = password;
  }

  // 5️⃣ SharedPreferences에 저장
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip', ip);
    await prefs.setString('port', port);
    await prefs.setString('id', id);
    await prefs.setString('password', password);
  }

  // 6️⃣ SharedPreferences에서 불러오기
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    ip = prefs.getString('ip') ?? '';
    port = prefs.getString('port') ?? '';
    id = prefs.getString('id') ?? '';
    password = prefs.getString('password') ?? '';
  }

  void _handleConnectionError(Object error) {
    _showErrorDialog('서버 연결이 끊어졌습니다.\n재연결 시도 중...');
    _reconnect(ip, port);
  }

  void _reconnect(String ip, String port) async {
    await Future.delayed(const Duration(seconds: 3));
    debugPrint('🔁 재연결 시도');
    await connect();
  }

  void _showErrorDialog(String message) {
    // ⚠️ Flutter context가 없는 곳에서는 직접 다이얼로그를 띄울 수 없으므로
    // Provider나 NavigatorKey를 활용해서 안전하게 띄워야 합니다.
    debugPrint('📢 알림: $message');
  }

  void disconnect(dynamic status) {
    channel?.sink.close(status.goingAway);
    debugPrint('🔌 연결 종료');
  }

  Future<void> connect() async {
    final uri = Uri.parse('ws://$ip:$port');
    debugPrint('🔌 WebSocket 연결 시도 → $uri');

    try {
      channel = WebSocketChannel.connect(uri);
      debugPrint('✅ WebSocket 연결 성공');

      // 메시지 수신 리스너
      channel!.stream.listen(
        (message) {
          debugPrint('📩 message 수신: ');
          _responseController.add(message); // 응답을 컨트롤러로 중계
        },
        onError: (error) {
          debugPrint('❌ 스트림 오류: $error');
          _handleConnectionError(error);
        },
        onDone: () {
          debugPrint('⚠️ 연결 종료됨');
          _reconnect(ip, port);
        },
      );
    } on WebSocketChannelException catch (e) {
      debugPrint('🚫 WebSocket 연결 실패: $e');
      _showErrorDialog('서버에 연결할 수 없습니다.\n잠시 후 다시 시도해주세요.');
    } on SocketException catch (e) {
      debugPrint('🚫 소켓 예외: $e');
      _showErrorDialog('네트워크 연결을 확인해주세요.');
    } catch (e) {
      debugPrint('🚫 기타 예외: $e');
      _showErrorDialog('알 수 없는 오류가 발생했습니다.');
    }
  }

  Future<dynamic> sendCallback(String message) async {
    if (channel == null) return {};
    debugPrint('📤 전송: $message');
    final data = jsonEncode({"type": serverType, "text": message});
    channel!.sink.add(data);

    // ✅ 새 메시지가 들어올 때까지 기다림
    final response = await _responseController.stream.first;
    return response;
  }

  Future<dynamic> sendCallbackImage(
    Map<String, Object> header,
    Uint8List imageBytes,
  ) async {
    if (channel == null) return {};
    // final header = {
    //   "type": "imagecrop",
    //   "hasBinary": true,
    //   "handles": handlesToJson(handles),
    //   "imageSize": imageBytes.length,
    // };

    channel!.sink.add(jsonEncode(header));
    channel!.sink.add(imageBytes);

    // ✅ 새 메시지가 들어올 때까지 기다림
    final response = await _responseController.stream.first;
    return response;
  }

  // /// 시뮬레이터/기기에 따라 주소 보정
  // Future<String> _resolveAddress() async {
  //   if (Platform.isIOS) {
  //     final deviceInfo = DeviceInfoPlugin();
  //     final iosInfo = await deviceInfo.iosInfo;

  //     if (iosInfo.isPhysicalDevice == false) {
  //       // 시뮬레이터
  //       debugPrint('📱 iOS 시뮬레이터 감지됨');
  //       return ip;
  //     } else {
  //       // 실제 기기
  //       debugPrint('📱 실제 iPhone 감지됨');
  //       return ip; // 외부에서 전달된 IP
  //     }
  //   } else if (Platform.isAndroid) {
  //     final deviceInfo = DeviceInfoPlugin();
  //     final androidInfo = await deviceInfo.androidInfo;

  //     if (androidInfo.isPhysicalDevice == false) {
  //       // Android 에뮬레이터
  //       debugPrint('🤖 Android 에뮬레이터 감지됨');
  //       return '10.0.2.2';
  //     } else {
  //       // 실제 Android 기기
  //       return ip;
  //     }
  //   } else {
  //     // macOS, Windows 등 테스트 환경
  //     return '127.0.0.1';
  //   }
  // }

  /// 연결 종료
  void close() {
    try {
      channel?.sink.close();
      _responseController.close();
      debugPrint('✅ AppSessionManager disposed');
    } catch (e) {
      debugPrint('⚠️ Dispose error: $e');
    } finally {
      channel = null;
    }
  }
}
