import 'package:bbb_app/src/connect/meeting/main_websocket/video/connection/video_connection.dart';
import 'package:bbb_app/src/utils/log.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class OutgoingScreenshareVideoConnection extends VideoConnection {
  /// The screenshare stream.
  MediaStream _localStream;

  OutgoingScreenshareVideoConnection(var meetingInfo) : super(meetingInfo);

  @override
  Future<void> init() async {
    _localStream = await _createScreenshareStream();
    if (_localStream == null) {
      FlutterForegroundTask.stop();
      throw Exception("local stream was null");
    }
    return super.init();
  }

  @override
  void close() {
    super.close();
    _localStream.dispose();
    FlutterForegroundTask.stop();
  }

  @override
  afterCreatePeerConnection() async {
    for (MediaStreamTrack track in _localStream.getTracks()) {
      await pc.addTrack(track, _localStream);
    }
  }

  @override
  onIceCandidate(candidate) {
    send({
      'callerName': meetingInfo.internalUserID,
      'id': 'iceCandidate',
      'role': 'send',
      'type': 'screenshare',
      'voiceBridge': meetingInfo.voiceBridge,
      'candidate': {
        'candidate': candidate.candidate,
        'sdpMLineIndex': candidate.sdpMlineIndex,
        'sdpMid': candidate.sdpMid,
      }
    });
  }

  @override
  sendOffer(RTCSessionDescription s) {
    send({
      'callerName': meetingInfo.internalUserID,
      'id': 'start',
      'internalMeetingId': meetingInfo.meetingID,
      'role': 'send',
      'type': 'screenshare',
      'userName': meetingInfo.fullUserName,
      'vh': 1920, //TODO
      'vw': 1080, //TODO
      'voiceBridge': meetingInfo.voiceBridge,
      'sdpOffer': s.sdp,
    });
  }

  // startForegroundService() async {
  //   // await FlutterForegroundTask.setServiceMethodInterval(seconds: 1);
  //   // await FlutterForegroundTask.init(androidNotificationOptions: androidNotificationOptions, iosNotificationOptions: iosNotificationOptions);
  //   await FlutterForegroundTask.start(
  //     callback: () {
  //       Log.info("[OutgoingScreenshareVideoConnection] Foreground on Started");
  //     },
  //     notificationText: '',
  //     notificationTitle: '',
  //   );
  //   return true;
  // }

  void initForegroundService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when a foreground task is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
      ),
      iosNotificationOptions: IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
      ),
      printDevLog: true,
    );
  }

  static void someDummyFunctionDoingExactlyNothing() {}

  Future<MediaStream> _createScreenshareStream() async {
    final Map<String, dynamic> mediaConstraints = {
      'audio': false,
      'video': {
        'mandatory': {
          'minFrameRate': '15',
        },
        'optional': [],
      }
    };

    // await startForegroundService();
    initForegroundService();

    MediaStream stream = await navigator.mediaDevices
        .getDisplayMedia(mediaConstraints)
        .catchError((e) {
      Log.error(
          "[OutgoingScreenshareVideoConnection] error opening screenshare stream: " +
              e);
      return null;
    });

    return stream;
  }
}
