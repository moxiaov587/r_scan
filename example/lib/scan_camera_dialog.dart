import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:r_scan/r_scan.dart';

import 'scan_dialog.dart';

List<RScanCameraDescription>? rScanCameras;

class RScanCameraDialog extends StatefulWidget {
  @override
  _RScanCameraDialogState createState() => _RScanCameraDialogState();
}

class _RScanCameraDialogState extends State<RScanCameraDialog> {
  RScanCameraController? _controller;
  bool isFirst = true;

  Future<void> initCamera() async {
    if (rScanCameras?.isEmpty != false) {
      final Map<Permission, PermissionStatus> status = await <Permission>[
        Permission.camera,
      ].request();
      if (status[Permission.camera] == PermissionStatus.granted) {
        rScanCameras = await availableRScanCameras();
        print('返回可用的相机：${rScanCameras!.join('\n')}');
      } else {
        print('相机权限被拒绝，无法使用');
        return;
      }
    }

    if (rScanCameras?.isNotEmpty == true) {
      _controller = RScanCameraController(
        rScanCameras![0],
        RScanCameraResolutionPreset.high,
      )
        ..addListener(() {
          final RScanResult? result = _controller!.result;
          if (result != null) {
            if (isFirst) {
              Navigator.of(context).pop(result);
              isFirst = false;
            }
          }
        })
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
          }
        });
    }
  }

  @override
  void initState() {
    super.initState();
    initCamera();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (rScanCameras?.isEmpty != false) {
      return Scaffold(
        body: Container(
          alignment: Alignment.center,
          child: const Text('not have available camera'),
        ),
      );
    }
    if (_controller?.value.isInitialized != true) {
      return const SizedBox.shrink();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: <Widget>[
          ScanImageView(
            child: AspectRatio(
              aspectRatio: 1 / _controller!.value.aspectRatio,
              child: RScanCamera(_controller!),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FutureBuilder<bool>(
              future: getFlashMode(),
              builder: _buildFlashBtn,
            ),
          )
        ],
      ),
    );
  }

  Future<bool> getFlashMode() async {
    bool isOpen = false;
    try {
      isOpen = (await _controller?.getFlashMode()) ?? false;
    } catch (_) {}
    return isOpen;
  }

  Widget _buildFlashBtn(BuildContext context, AsyncSnapshot<bool> snapshot) {
    if (!snapshot.hasData) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.of(context).padding.bottom,
      ),
      child: IconButton(
        icon: Icon(snapshot.data! ? Icons.flash_on : Icons.flash_off),
        color: Colors.white,
        iconSize: 46,
        onPressed: () {
          if (snapshot.data!) {
            _controller?.setFlashMode(false);
          } else {
            _controller?.setFlashMode(true);
          }
          setState(() {});
        },
      ),
    );
  }
}
