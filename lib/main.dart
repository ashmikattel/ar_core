import 'dart:io';

import 'package:arcore_flutter_plugin/arcore_flutter_plugin.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';

List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(CameraView());
}

class CameraView extends StatefulWidget {
  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  ArCoreFaceController arCoreFaceController;

  int crownToShow;

  ByteData textureBytes;

  File imageFile;

  CameraController controller;

  Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();

    initController();

    setState(() {
      controller = CameraController(cameras[1], ResolutionPreset.medium);
      _initializeControllerFuture = controller.initialize();
    });
  }

  initController() async {
    textureBytes = await rootBundle.load('resources/images/black.png');

    arCoreFaceController.loadMesh(
      textureBytes: textureBytes.buffer.asUint8List(),
      skin3DModelFilename: "c.sfb",
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          body: FutureBuilder(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return Stack(
                    children: <Widget>[
                      ArCoreFaceView(
                        onArCoreViewCreated: _onArCoreViewCreated,
                        enableAugmentedFaces: true,
                      ),
                      Positioned(
                        bottom: 0.0,
                        left: 10.0,
                        right: 10.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              height: 50.0,
                              width: 50.0,
                              margin: EdgeInsets.symmetric(vertical: 5.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30.0)),
                              child: IconButton(
                                icon: Icon(
                                  Icons.camera,
                                  color: Colors.yellow,
                                  size: 40.0,
                                ),
                                onPressed: () async {
                                  try {
                                    await _initializeControllerFuture;

                                    final path = join(
                                      // Store the picture in the temp directory.
                                      // Find the temp directory using the `path_provider` plugin.
                                      (await getTemporaryDirectory()).path,
                                      '${DateTime.now()}.png',
                                    );
                                    // Attempt to take a picture and log where it's been saved.
                                    await controller.takePicture(path);

                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DisplayPictureScreen(
                                                imagePath: path),
                                      ),
                                    );
                                  } catch (e) {
                                    // If an error occurs, log the error to the console.
                                    print(e);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              })),
    );
  }

  void _onArCoreViewCreated(ArCoreFaceController controller) {
    arCoreFaceController = controller;
    loadMesh();
  }

  loadMesh() async {
    final ByteData textureBytes =
        await rootBundle.load('resources/images/black.png');

    arCoreFaceController.loadMesh(
      textureBytes: textureBytes.buffer.asUint8List(),
      skin3DModelFilename: "tt.sfb",
    );
  }

  @override
  void dispose() {
    arCoreFaceController.dispose();
    super.dispose();
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key key, this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Display the Picture')),
      body: Image.file(File(imagePath)),
    );
  }
}
