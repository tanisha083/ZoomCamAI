import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_pytorch/pigeon.dart';
// ignore: depend_on_referenced_packages
import 'package:flutter_pytorch/flutter_pytorch.dart';
import 'package:object_detection/LoaderState.dart';
import 'package:flutter_native_image/flutter_native_image.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:gallery_saver/gallery_saver.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late ModelObjectDetection _objectModel;
  String? _imagePrediction;
  File? _image;
  ImagePicker _picker = ImagePicker();
  bool objectDetection = false;
  bool zoom = false;
  List<ResultObjectDetection?> objDetect = [];
  bool firststate = false;
  bool message = true;

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  Future loadModel() async {
    String pathObjectDetectionModel = "assets/models/yolov5s.torchscript";
    try {
      _objectModel = await FlutterPytorch.loadObjectDetectionModel(
          pathObjectDetectionModel, 80, 640, 640,
          labelPath: "assets/labels/labels.txt");
    } catch (e) {
      if (e is PlatformException) {
        print("only supported for android, Error is $e");
      } else {
        print("Error is $e");
      }
    }
  }

  void handleTimeout() {
    // callback function
    // Do some work.
    setState(() {
      firststate = true;
    });
  }

  Timer scheduleTimeout([int milliseconds = 10000]) =>
      Timer(Duration(milliseconds: milliseconds), handleTimeout);
  // running detections on image
  Future runObjectDetection() async {
    setState(() {
      firststate = false;
      message = false;
    });
    print('inside run');
    //pick an image
    print('image');
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    print(image);
    if (image != null) {
      objDetect = await _objectModel.getImagePrediction(
          await File(image.path).readAsBytes(),
          minimumScore: 0.1,
          IOUThershold: 0.3);

      print('tanisha');
      objDetect.sort((b, a) => a!.score.compareTo(b!.score));
      // for (var element in obj)

      objDetect.forEach((element) {
        print({
          "score": element?.score,
          "className": element?.className,
          "class": element?.classIndex,
          "rect": {
            "left": element?.rect.left,
            "top": element?.rect.top,
            "width": element?.rect.width,
            "height": element?.rect.height,
            "right": element?.rect.right,
            "bottom": element?.rect.bottom,
          }
        });
      });
      scheduleTimeout(1 * 1000);
      setState(() {
        // _image = croppedFile;
        _image = File(image.path);
      });
    }
    print('outside run');
  }

  Future crop(String? classname) async {
    for (var element in objDetect) {
      if (classname == element!.className) {
        ImageProperties properties =
            await FlutterNativeImage.getImageProperties(_image!.path);
        print(properties.height);
        print(properties.width);
        File croppedFile = await FlutterNativeImage.cropImage(
            _image!.path,
            (element.rect.left * properties.width!).toInt(),
            (element.rect.top * properties.height!).toInt(),
            (element.rect.width * properties.width!).toInt(),
            (element.rect.height * properties.height!).toInt());
        scheduleTimeout(2 * 1000);
        print("!!!!!!!!!!!!!!!!!!!!!!!!");

        final directory = await getApplicationDocumentsDirectory();
        final path = directory.path;
        // final file = File('$path/image.png');
        // var appDocDir = await getTemporaryDirectory();
        // String savePath = "${appDocDir.path}/image.png";
        // final result = await ImageGallerySaver.saveFile(path);
        // print(result);
        // await file.writeAsBytes(await croppedFile.readAsBytes());
        // print('Image saved to: ${file.path}');
        setState(() {
          _image = croppedFile;
          // _properties = properties;
          // _image = File(image.path);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double deviceHeight = size.height;
    final double deviceWidth = size.width;
    return Scaffold(
      appBar: AppBar(title: const Text("Intelligent Autozoom Camera")),
      backgroundColor: CupertinoColors.white,
      body: Center(
          child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //Image with Detections....

          if (!firststate)
            !message
                ? LoaderState()
                : const Text(
                    "Tap on camera to autozoom on detected items",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                      fontStyle: FontStyle.normal,
                      letterSpacing: 0.5,
                      wordSpacing: 1,
                    ),
                  )
          else
            Center(
              child: Column(
                children: [
                  if (!zoom)
                    Center(
                      child: DropdownButton<ResultObjectDetection?>(
                        iconSize: 50,
                        alignment: AlignmentDirectional.center,
                        iconEnabledColor: Colors.teal,
                        value: objDetect.isNotEmpty ? objDetect[0] : null,
                        onChanged: (newValue) async {
                          if (newValue != null) {
                            print("beforeeee");
                            await crop(newValue.className);
                            print("in on changed");
                            print(newValue);
                          }
                          setState(() {
                            // objDetect[0] = newValue;
                            zoom = true;
                          });
                        },
                        items: objDetect
                            .map((ResultObjectDetection? detection) =>
                                DropdownMenuItem<ResultObjectDetection?>(
                                    value: detection,
                                    child: Text(
                                      detection?.className ?? '',
                                      style: const TextStyle(
                                        fontFamily: '',
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal,
                                        fontStyle: FontStyle.normal,
                                        letterSpacing: 1,
                                        wordSpacing: 2.0,
                                      ),
                                    )))
                            .toList(),
                      ),
                    ),
                  if (zoom)
                    Container(
                      height: deviceHeight - 200,
                      width: deviceWidth,
                      child: Image.file(_image!),
                    ),
                ],
              ),
            ),

          // !firststate
          //     ? LoaderState()
          //     : Expanded(
          //         child: Container(
          //             height: 150,
          //             width: 300,
          //             child: objDetect.isEmpty
          //                 ? Text("hello")
          //                 : _objectModel.renderBoxesOnImage(
          //                     _image!, objDetect)),
          //       ),
          Center(
            child: Visibility(
              visible: _imagePrediction != null,
              child: Text("$_imagePrediction"),
            ),
          ),
          //Button to click pic
          ElevatedButton(
            onPressed: () {
              if (kDebugMode) {
                print('click camera');
              }
              zoom = false;
              firststate = false;
              message = true;
              runObjectDetection();
            },
            child: const Icon(Icons.camera_alt),
          )
        ],
      )),
    );
  }
}
