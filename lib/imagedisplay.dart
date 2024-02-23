import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    MaterialApp(
      home: ImageDisplayPage(imageBase64: ''),
    ),
  );
}

class ImageDisplayPage extends StatefulWidget {
  final String imageBase64;

  ImageDisplayPage({required this.imageBase64});

  @override
  _ImageDisplayPageState createState() => _ImageDisplayPageState();
}

class _ImageDisplayPageState extends State<ImageDisplayPage> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Outpaint Display Page'),
        actions: [
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Img2img info"),
                    content: SingleChildScrollView(
                      child: ListBody(
                        children: <Widget>[
                          Text(
                            'Outpainting is an advanced technique that expands images beyond their original borders using the exisitng image generation algorithm',
                          ),
                          Text(
                            'Unlike traditional image generation, it has the potential to create seamless extentions of images while harmoniously blending new elements.',
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                ),
                                child: Text("Credits"),
                                onPressed: () {
                                  Navigator.pushNamed(
                                      context, '/another_page1');
                                },
                              ),
                              SizedBox(
                                  width:
                                      8.0), // Add desired horizontal spacing between buttons
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors.white,
                                ),
                                child: Text("OK"),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: _buildImageDisplay(context),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildImageDisplay(BuildContext context) {
    return Center(
      child: Image.memory(
        base64Decode(widget.imageBase64),
        // You can set other parameters like width, height, fit, etc.
      ),
    );
  }

  void _saveImage(String base64Image) async {
    if (!mounted) {
      return; // Break out of the function if widget is not mounted
    }
    List<int> imageBytes = base64Decode(base64Image);

    final tempDir = await Directory.systemTemp.createTemp();
    final file = File('${tempDir.path}/image.png');
    await file.writeAsBytes(imageBytes);

    Fluttertoast.showToast(
      msg: 'Image downloading!',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
    );

    await GallerySaver.saveImage(file.path);
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            heroTag: "save",
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Save Image"),
                    content: Text("Do you want to save the returned image?"),
                    actions: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          _saveImage(widget.imageBase64);
                          Navigator.of(context).pop();
                        },
                        child: Text("Save"),
                      ),
                    ],
                  );
                },
              );
            },
            tooltip: 'Save Image',
            child: Icon(Icons.download_rounded),
          ),
        ),
        Positioned(
          bottom: 80,
          right: 16,
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return IgnorePointer(
                ignoring:
                    _isLoading, // Prevent user interactions during loading
                child: FloatingActionButton(
                  heroTag: "info",
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  onPressed: () async {
                    var connectivityResult =
                        await (Connectivity().checkConnectivity());
                    if (connectivityResult == ConnectivityResult.mobile) {
                      // I am connected to a mobile network.
                    } else if (connectivityResult == ConnectivityResult.wifi) {
                      // I am connected to a wifi network.
                    } else if (connectivityResult == ConnectivityResult.none) {
                      Fluttertoast.showToast(
                        msg: 'Error: networking please try again',
                        gravity: ToastGravity.BOTTOM,
                        toastLength: Toast.LENGTH_SHORT,
                      );
                      return;
                    }

                    setState(() {
                      _isLoading = true; // Set loading status to true
                    });

                    try {
                      setState(() {
                        _isLoading = true;
                      });

                      final url = Uri.parse(
                          'https://ai.serverboi.org/sdapi/v1/png-info');
                      final headers = {'Content-Type': 'application/json'};
                      final body = jsonEncode({'image': widget.imageBase64});

                      final response =
                          await http.post(url, headers: headers, body: body);
                      if (response.statusCode == 200) {
                        final jsonResponse = jsonDecode(response.body);
                        final info = jsonResponse['info'];

                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Info'),
                              content: SingleChildScrollView(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SelectableText(
                                      'Prompt: $info',
                                    ),
                                    SizedBox(height: 16),
                                  ],
                                ),
                              ),
                              actions: [
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                  ),
                                  child: Text('OK'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      } else {
                        throw Exception('Failed to send image request');
                      }
                    } on SocketException catch (e) {
                      debugPrint('Caught SocketException: $e');
                      // Handle the SocketException
                    } on Exception catch (e) {
                      debugPrint('Caught Exception: $e');
                      // Handle other exceptions
                    } finally {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  },
                  tooltip: 'Image info',
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.0,
                        )
                      : Icon(Icons.info_outline_rounded),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
