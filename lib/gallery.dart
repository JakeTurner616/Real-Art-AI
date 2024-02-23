import 'package:Real_Art_AI/post_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'http_service.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:http/http.dart' as http;
import 'imagedisplay.dart';
import 'main.dart';

int _sendButtonPressCount = sendButtonPressCount;

class AnotherPage extends StatefulWidget {
  const AnotherPage({super.key});

  @override
  // reason for ignoring: It is not a public api
  // ignore: library_private_types_in_public_api
  _AnotherPageState createState() => _AnotherPageState();
}

class _AnotherPageState extends State<AnotherPage> {
  TextEditingController _textEditingController = TextEditingController();
  InterstitialAd? _interstitialAd;
  bool _adLoaded = false;
  bool _isLoadingButton = false; // New loading state variable
  File _imageFile = File('');
  String _base64Image = '';
  String _query = '';
  bool _isLoading = false;
  bool _imageReturned = false;
  bool _upscaled = false;
  bool _loading = false;
  double _denoisingStrength = 0.30; // added for slider
  String _denoisingStrengthText = '0.30'; // added for text
  final HttpService httpService = HttpService();
  String _selectedOption = 'Euler a';

  TextEditingController _textFieldController = TextEditingController();
  TextEditingController _textFieldControllerOutpaint = TextEditingController();
  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void initState() {
    if (!mounted) {
      return; // Break out of the function if widget is not mounted
    }
    super.initState();

    _denoisingStrengthText =
        'Denoising Strength: ${_denoisingStrength.toStringAsFixed(2)}'; // update text

    // Initialize the InterstitialAd
  }

  @override
  void dispose() {
    // Cancel any timers or animations here
    // Stop listening to callbacks

    super.dispose();
  }

  void _getFromGallery() async {
    if (!mounted) {
      return;
    }

    try {
      XFile? pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        CroppedFile? croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedFile.path,
          compressQuality: 100,
          aspectRatio: CropAspectRatio(ratioX: 1024, ratioY: 1024),
          uiSettings: [
            AndroidUiSettings(
              hideBottomControls: true,
              showCropGrid: true,
              initAspectRatio: CropAspectRatioPreset.square,
              toolbarTitle: '',
              toolbarColor: Color.fromARGB(255, 48, 48, 48),
              toolbarWidgetColor: Colors.white,
              lockAspectRatio: true,
            ),
          ],
        );

        if (croppedFile != null) {
          File? croppedImage = File(croppedFile.path);

          // Image has been cropped successfully
          Fluttertoast.showToast(
            msg: 'Image cropped!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );

          setState(() {
            _imageReturned = false;
            _imageFile = croppedImage;
            _imageWidget = Image.file(_imageFile);
          });
        } else {
          // Image cropping was canceled
          Fluttertoast.showToast(
            msg: 'Image cropping canceled!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
        }
      } else {
        // No image selected
        Fluttertoast.showToast(
          msg: 'No image selected!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      // Exception occurred
      Fluttertoast.showToast(
        msg: 'File type error!',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  void _updateQuery(String query) {
    if (!mounted) {
      return; // Break out of the function if widget is not mounted
    }
    setState(() {
      _query = query;
    });
  }

  Widget _imageWidget = Container();

  void _submitImageAndQuery() {
    if (!mounted) {
      return; // Break out of the function if widget is not mounted
    }
    // Increment the send button press count
    setState(() {
      _sendButtonPressCount++;
      print(_sendButtonPressCount);
    });

    // Show ad every 2nd time the button is pressed
    if (_sendButtonPressCount % 2 == 0) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5']));
      String adUnitId = Config.getAdUnitId(
        isRelease: kReleaseMode,
        isAndroid: Platform.isAndroid,
      );
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _adLoaded = true;
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    }
    // ignore: unnecessary_null_comparison
    if (_imageFile != null) {
      if (!mounted) {
        return; // Break out of the function if widget is not mounted
      }
      setState(() {
        _imageWidget = Image.file(_imageFile);
      });
    }
    int retryCount = 0;
    int maxRetries = 3;
    String selectedOption = 'Euler a';
    void fetchImage() {
      if (!mounted) {
        return; // Break out of the function if widget is not mounted
      }
      _base64Image = base64Encode(_imageFile.readAsBytesSync());
      HttpService service = HttpService();

      setState(() {
        _loading = true; // Set loading to true before making the request
      });

      service
          .getPostsimg2img(
              _query,
              _base64Image,
              _denoisingStrength,
              httpService.steps,
              httpService.selectedOption,
              httpService.seedParam)
          .then((posts) {
        if (posts.isNotEmpty) {
          setState(() {
            _upscaled = false;

            _imageWidget = Stack(
              children: [
                IgnorePointer(
                  ignoring: !_loading,
                  child: Image.memory(
                    gaplessPlayback: true,
                    base64Decode(posts[0].imageBase64),
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return IgnorePointer(
                        ignoring: _isLoadingButton,
                        child: IconButton(
                          splashRadius: 0.001,
                          icon: _isLoadingButton
                              ? CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3.0,
                                )
                              : Icon(Icons.info),
                          onPressed: () async {
                            var connectivityResult =
                                await (Connectivity().checkConnectivity());
                            if (connectivityResult ==
                                ConnectivityResult.mobile) {
                              // I am connected to a mobile network.
                            } else if (connectivityResult ==
                                ConnectivityResult.wifi) {
                              // I am connected to a wifi network.
                            } else if (connectivityResult ==
                                ConnectivityResult.none) {
                              Fluttertoast.showToast(
                                msg: 'Error: networking please try again',
                                gravity: ToastGravity.BOTTOM,
                                toastLength: Toast.LENGTH_SHORT,
                              );
                              return;
                            }

                            try {
                              setState(() {
                                _isLoadingButton = true;
                              });

                              final url = Uri.parse(
                                  'https://ai.serverboi.org/sdapi/v1/png-info');
                              final headers = {
                                'Content-Type': 'application/json'
                              };
                              final body =
                                  jsonEncode({'image': posts[0].imageBase64});

                              final response = await http.post(url,
                                  headers: headers, body: body);

                              if (response.statusCode == 413) {
                                if (!mounted) {
                                  return; // Break out of the function if widget is not mounted
                                }
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Error: Image too large'),
                                      content: Text(
                                          'The image that was sent to the image network is too large.'),
                                      actions: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors
                                                .white, // Set the background color to white
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
                              }
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                            foregroundColor: Colors.black,
                                            backgroundColor: Colors
                                                .white, // Set the text color
                                          ),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: Text('OK'),
                                        )
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
                                _isLoadingButton = false;
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                IntrinsicWidth(
                  child: Container(
                    child: DropdownButton<String>(
                      hint: Text("Outpaint menu"),
                      isExpanded: true,
                      dropdownColor: Color.fromARGB(255, 48, 48, 48),
                      icon: Icon(Icons.arrow_drop_down),
                      iconSize: 36,
                      iconEnabledColor: Colors.grey,
                      underline: Container(
                        height: 0,
                        color: Colors.transparent,
                      ),
                      items: [
                        DropdownMenuItem<String>(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  int _latentMode = 1;
                                  bool _initimageInclude =
                                      true; // Initial value for checkbox

                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return AlertDialog(
                                        title: Text('Settings'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Set the latent mode: \n'),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                0; // Corresponds to 'fill'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest2(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Fill'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                1; // Corresponds to 'original'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest2(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Original'),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ), // Adjust the spacing between columns
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                2; // Corresponds to 'latentNoise'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest2(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Noise'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                3; // Corresponds to 'latentNothing'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest2(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Nothing'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 16,
                                              ), // Adjust the spacing between the buttons and checkbox
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: _initimageInclude,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _initimageInclude =
                                                            value!;
                                                      });
                                                      print(_initimageInclude);
                                                    },
                                                    activeColor: Colors.white,
                                                    checkColor: Colors.black,
                                                  ),
                                                  Text('Include Initial Image'),
                                                ],
                                              ),
                                              // Declare a high-level variable to store the selected option

// Inside your widget's build method
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    TextField(
                                                      cursorColor: Colors
                                                          .white, // Set the cursor color to white
                                                      decoration:
                                                          InputDecoration(
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        labelText: 'Seed',
                                                        labelStyle: TextStyle(
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color:
                                                                  Colors.black,
                                                              offset:
                                                                  Offset(2, 2),
                                                              blurRadius: 14,
                                                            ),
                                                          ],
                                                        ),
                                                        hintText: '-1 (random)',
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          seedParam1 = value;
                                                          _textFieldControllerOutpaint
                                                                  .selection =
                                                              TextSelection.fromPosition(
                                                                  TextPosition(
                                                                      offset: seedParam1
                                                                          .length));
                                                        });
                                                      },
                                                      controller:
                                                          _textFieldControllerOutpaint,
                                                    ),
                                                    Text(
                                                      '\nSampler: ${selectedOption == 'Euler a' ? 'Euler a (default)' : selectedOption}',
                                                    ),
                                                    DropdownButton<String>(
                                                      value: selectedOption,
                                                      items: <String>[
                                                        'Euler a',
                                                        'Euler',
                                                        'LMS',
                                                        'Heun',
                                                        'DPM2',
                                                        'DPM2 a',
                                                        'DPM++ 2S a',
                                                        'DPM++ 2M',
                                                        'DPM++ SDE',
                                                        'DPM fast',
                                                        'DPM adaptive',
                                                        'LMS Karras',
                                                        'DPM2 Karras',
                                                        'DPM2 a Karras',
                                                        'DPM++ 2S a Karras',
                                                        'DPM++ 2M Karras',
                                                        'DPM++ SDE Karras',
                                                        'DDIM',
                                                        'PLMS'
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          selectedOption =
                                                              newValue!;
                                                          // Do something with the selected value
                                                          debugPrint(
                                                              'Selected option: $selectedOption');
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                        'Steps: ${httpService.steps1}${httpService.steps1 == 50 ? " (default)" : ""}'),
                                                    SliderTheme(
                                                      data: SliderThemeData(
                                                        thumbColor: Colors
                                                            .white, // Set the thumb color to white
                                                        activeTrackColor: Colors
                                                            .white, // Set the active track color to white
                                                        inactiveTrackColor:
                                                            Color.fromARGB(
                                                                255,
                                                                77,
                                                                76,
                                                                76), // Set the inactive track color to grey
                                                        trackHeight:
                                                            8.0, // Adjust the track height as desired
                                                        overlayColor: Colors
                                                            .transparent, // Set the overlay color to transparent
                                                        thumbShape:
                                                            RoundSliderThumbShape(
                                                                enabledThumbRadius:
                                                                    8.0), // Customize the thumb shape
                                                        overlayShape:
                                                            RoundSliderOverlayShape(
                                                                overlayRadius:
                                                                    16.0), // Customize the overlay shape
                                                        valueIndicatorColor: Colors
                                                            .white, // Set the value indicator color to white
                                                        valueIndicatorTextStyle:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black), // Set the value indicator text color to black
                                                      ),
                                                      child: Slider(
                                                        value: httpService
                                                            .steps1
                                                            .toDouble(),
                                                        min: 1.0,
                                                        max: 50.0,
                                                        divisions: 49,
                                                        onChanged:
                                                            (double value) {
                                                          setState(() {
                                                            httpService.steps1 =
                                                                value.round();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(
                              "Top\n",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          value: "Top",
                        ),
                        DropdownMenuItem<String>(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  int _latentMode = 1;
                                  bool _initimageInclude =
                                      true; // Initial value for checkbox

                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return AlertDialog(
                                        title: Text('Settings'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Set the latent mode: \n'),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                0; // Corresponds to 'fill'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest3(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Fill'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                1; // Corresponds to 'original'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest3(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Original'),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ), // Adjust the spacing between columns
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                2; // Corresponds to 'latentNoise'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest3(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Noise'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                3; // Corresponds to 'latentNothing'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest3(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Nothing'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 16,
                                              ), // Adjust the spacing between the buttons and checkbox
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: _initimageInclude,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _initimageInclude =
                                                            value!;
                                                      });
                                                      print(_initimageInclude);
                                                    },
                                                    activeColor: Colors.white,
                                                    checkColor: Colors.black,
                                                  ),
                                                  Text('Include Initial Image'),
                                                ],
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    TextField(
                                                      cursorColor: Colors
                                                          .white, // Set the cursor color to white
                                                      decoration:
                                                          InputDecoration(
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        labelText: 'Seed',
                                                        labelStyle: TextStyle(
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color:
                                                                  Colors.black,
                                                              offset:
                                                                  Offset(2, 2),
                                                              blurRadius: 14,
                                                            ),
                                                          ],
                                                        ),
                                                        hintText: '-1 (random)',
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          seedParam1 = value;
                                                          _textFieldControllerOutpaint
                                                                  .selection =
                                                              TextSelection.fromPosition(
                                                                  TextPosition(
                                                                      offset: seedParam1
                                                                          .length));
                                                        });
                                                      },
                                                      controller:
                                                          _textFieldControllerOutpaint,
                                                    ),
                                                    Text(
                                                      '\nSampler: ${selectedOption == 'Euler a' ? 'Euler a (default)' : selectedOption}',
                                                    ),
                                                    DropdownButton<String>(
                                                      value: selectedOption,
                                                      items: <String>[
                                                        'Euler a',
                                                        'Euler',
                                                        'LMS',
                                                        'Heun',
                                                        'DPM2',
                                                        'DPM2 a',
                                                        'DPM++ 2S a',
                                                        'DPM++ 2M',
                                                        'DPM++ SDE',
                                                        'DPM fast',
                                                        'DPM adaptive',
                                                        'LMS Karras',
                                                        'DPM2 Karras',
                                                        'DPM2 a Karras',
                                                        'DPM++ 2S a Karras',
                                                        'DPM++ 2M Karras',
                                                        'DPM++ SDE Karras',
                                                        'DDIM',
                                                        'PLMS'
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          selectedOption =
                                                              newValue!;
                                                          // Do something with the selected value
                                                          debugPrint(
                                                              'Selected option: $selectedOption');
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                        'Steps: ${httpService.steps1}${httpService.steps1 == 50 ? " (default)" : ""}'),
                                                    SliderTheme(
                                                      data: SliderThemeData(
                                                        thumbColor: Colors
                                                            .white, // Set the thumb color to white
                                                        activeTrackColor: Colors
                                                            .white, // Set the active track color to white
                                                        inactiveTrackColor:
                                                            Color.fromARGB(
                                                                255,
                                                                77,
                                                                76,
                                                                76), // Set the inactive track color to grey
                                                        trackHeight:
                                                            8.0, // Adjust the track height as desired
                                                        overlayColor: Colors
                                                            .transparent, // Set the overlay color to transparent
                                                        thumbShape:
                                                            RoundSliderThumbShape(
                                                                enabledThumbRadius:
                                                                    8.0), // Customize the thumb shape
                                                        overlayShape:
                                                            RoundSliderOverlayShape(
                                                                overlayRadius:
                                                                    16.0), // Customize the overlay shape
                                                        valueIndicatorColor: Colors
                                                            .white, // Set the value indicator color to white
                                                        valueIndicatorTextStyle:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black), // Set the value indicator text color to black
                                                      ),
                                                      child: Slider(
                                                        value: httpService
                                                            .steps1
                                                            .toDouble(),
                                                        min: 1.0,
                                                        max: 50.0,
                                                        divisions: 49,
                                                        onChanged:
                                                            (double value) {
                                                          setState(() {
                                                            httpService.steps1 =
                                                                value.round();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(
                              "Bottom\n",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          value: "Bottom",
                        ),
                        DropdownMenuItem<String>(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  int _latentMode = 1;
                                  bool _initimageInclude =
                                      true; // Initial value for checkbox

                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return AlertDialog(
                                        title: Text('Settings'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Set the latent mode: \n'),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                0; // Corresponds to 'fill'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest1(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Fill'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                1; // Corresponds to 'original'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest1(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Original'),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ), // Adjust the spacing between columns
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                2; // Corresponds to 'latentNoise'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest1(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Noise'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                3; // Corresponds to 'latentNothing'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest1(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Nothing'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 16,
                                              ), // Adjust the spacing between the buttons and checkbox
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: _initimageInclude,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _initimageInclude =
                                                            value!;
                                                      });
                                                      //print(_initimageInclude);
                                                    },
                                                    activeColor: Colors.white,
                                                    checkColor: Colors.black,
                                                  ),
                                                  Text('Include Initial Image'),
                                                ],
                                              ),
                                              // Declare a high-level variable to store the selected option

// Inside your widget's build method
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    TextField(
                                                      cursorColor: Colors
                                                          .white, // Set the cursor color to white
                                                      decoration:
                                                          InputDecoration(
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        labelText: 'Seed',
                                                        labelStyle: TextStyle(
                                                          color: Colors.white,
                                                          shadows: [
                                                            Shadow(
                                                              color:
                                                                  Colors.black,
                                                              offset:
                                                                  Offset(2, 2),
                                                              blurRadius: 14,
                                                            ),
                                                          ],
                                                        ),
                                                        hintText: '-1 (random)',
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          seedParam1 = value;
                                                          _textFieldControllerOutpaint
                                                                  .selection =
                                                              TextSelection.fromPosition(
                                                                  TextPosition(
                                                                      offset: seedParam1
                                                                          .length));
                                                        });
                                                      },
                                                      controller:
                                                          _textFieldControllerOutpaint,
                                                    ),
                                                    Text(
                                                      '\nSampler: ${selectedOption == 'Euler a' ? 'Euler a (default)' : selectedOption}',
                                                    ),
                                                    DropdownButton<String>(
                                                      value: selectedOption,
                                                      items: <String>[
                                                        'Euler a',
                                                        'Euler',
                                                        'LMS',
                                                        'Heun',
                                                        'DPM2',
                                                        'DPM2 a',
                                                        'DPM++ 2S a',
                                                        'DPM++ 2M',
                                                        'DPM++ SDE',
                                                        'DPM fast',
                                                        'DPM adaptive',
                                                        'LMS Karras',
                                                        'DPM2 Karras',
                                                        'DPM2 a Karras',
                                                        'DPM++ 2S a Karras',
                                                        'DPM++ 2M Karras',
                                                        'DPM++ SDE Karras',
                                                        'DDIM',
                                                        'PLMS'
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          selectedOption =
                                                              newValue!;
                                                          // Do something with the selected value
                                                          debugPrint(
                                                              'Selected option: $selectedOption');
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                        'Steps: ${httpService.steps1}${httpService.steps1 == 50 ? " (default)" : ""}'),
                                                    SliderTheme(
                                                      data: SliderThemeData(
                                                        thumbColor: Colors
                                                            .white, // Set the thumb color to white
                                                        activeTrackColor: Colors
                                                            .white, // Set the active track color to white
                                                        inactiveTrackColor:
                                                            Color.fromARGB(
                                                                255,
                                                                77,
                                                                76,
                                                                76), // Set the inactive track color to grey
                                                        trackHeight:
                                                            8.0, // Adjust the track height as desired
                                                        overlayColor: Colors
                                                            .transparent, // Set the overlay color to transparent
                                                        thumbShape:
                                                            RoundSliderThumbShape(
                                                                enabledThumbRadius:
                                                                    8.0), // Customize the thumb shape
                                                        overlayShape:
                                                            RoundSliderOverlayShape(
                                                                overlayRadius:
                                                                    16.0), // Customize the overlay shape
                                                        valueIndicatorColor: Colors
                                                            .white, // Set the value indicator color to white
                                                        valueIndicatorTextStyle:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black), // Set the value indicator text color to black
                                                      ),
                                                      child: Slider(
                                                        value: httpService
                                                            .steps1
                                                            .toDouble(),
                                                        min: 1.0,
                                                        max: 50.0,
                                                        divisions: 49,
                                                        onChanged:
                                                            (double value) {
                                                          setState(() {
                                                            httpService.steps1 =
                                                                value.round();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(
                              "Left\n",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          value: "Left",
                        ),
                        DropdownMenuItem<String>(
                          child: GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  int _latentMode = 1;
                                  bool _initimageInclude =
                                      true; // Initial value for checkbox

                                  return StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
                                      return AlertDialog(
                                        title: Text('Settings'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text('Set the latent mode: \n'),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                0; // Corresponds to 'fill'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Fill'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                1; // Corresponds to 'original'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Original'),
                                                      ),
                                                    ],
                                                  ),
                                                  SizedBox(
                                                    width: 16,
                                                  ), // Adjust the spacing between columns
                                                  Column(
                                                    children: [
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                2; // Corresponds to 'latentNoise'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Noise'),
                                                      ),
                                                      ElevatedButton(
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.black,
                                                          backgroundColor: Colors
                                                              .white, // Set the background color to white
                                                        ),
                                                        onPressed: () {
                                                          setState(() {
                                                            _latentMode =
                                                                3; // Corresponds to 'latentNothing'
                                                          });
                                                          // Process your data here
                                                          Navigator.of(context)
                                                              .pop();
                                                          Navigator.of(context)
                                                              .pop();
                                                          setState(() {
                                                            _loading = true;
                                                          });
                                                          processImageAndMakeRequest(
                                                              posts,
                                                              posts[0]
                                                                  .imageBase64,
                                                              _latentMode,
                                                              _initimageInclude,
                                                              selectedOption,
                                                              seedParam1,
                                                              httpService
                                                                  .steps1);
                                                        },
                                                        child: Text('Nothing'),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              SizedBox(
                                                height: 16,
                                              ), // Adjust the spacing between the buttons and checkbox
                                              Row(
                                                children: [
                                                  Checkbox(
                                                    value: _initimageInclude,
                                                    onChanged: (value) {
                                                      setState(() {
                                                        _initimageInclude =
                                                            value!;
                                                      });
                                                      //print(_initimageInclude);
                                                    },
                                                    activeColor: Colors.white,
                                                    checkColor: Colors.black,
                                                  ),
                                                  Text('Include Initial Image'),
                                                ],
                                              ),
                                              TextField(
                                                cursorColor: Colors
                                                    .white, // Set the cursor color to white
                                                decoration: InputDecoration(
                                                  focusedBorder:
                                                      UnderlineInputBorder(
                                                    borderSide: BorderSide(
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                  labelText: 'Seed',
                                                  labelStyle: TextStyle(
                                                    color: Colors.white,
                                                    shadows: [
                                                      Shadow(
                                                        color: Colors.black,
                                                        offset: Offset(2, 2),
                                                        blurRadius: 14,
                                                      ),
                                                    ],
                                                  ),
                                                  hintText: '-1 (random)',
                                                ),
                                                onChanged: (value) {
                                                  setState(() {
                                                    seedParam1 = value;
                                                    _textFieldControllerOutpaint
                                                            .selection =
                                                        TextSelection.fromPosition(
                                                            TextPosition(
                                                                offset: seedParam1
                                                                    .length));
                                                  });
                                                },
                                                controller:
                                                    _textFieldControllerOutpaint,
                                              ),
                                              Center(
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      '\nSampler: ${selectedOption == 'Euler a' ? 'Euler a (default)' : selectedOption}',
                                                    ),
                                                    DropdownButton<String>(
                                                      value: selectedOption,
                                                      items: <String>[
                                                        'Euler a',
                                                        'Euler',
                                                        'LMS',
                                                        'Heun',
                                                        'DPM2',
                                                        'DPM2 a',
                                                        'DPM++ 2S a',
                                                        'DPM++ 2M',
                                                        'DPM++ SDE',
                                                        'DPM fast',
                                                        'DPM adaptive',
                                                        'LMS Karras',
                                                        'DPM2 Karras',
                                                        'DPM2 a Karras',
                                                        'DPM++ 2S a Karras',
                                                        'DPM++ 2M Karras',
                                                        'DPM++ SDE Karras',
                                                        'DDIM',
                                                        'PLMS'
                                                      ].map((String value) {
                                                        return DropdownMenuItem<
                                                            String>(
                                                          value: value,
                                                          child: Text(value),
                                                        );
                                                      }).toList(),
                                                      onChanged: (newValue) {
                                                        setState(() {
                                                          selectedOption =
                                                              newValue!;
                                                          // Do something with the selected value
                                                          debugPrint(
                                                              'Selected option: $selectedOption');
                                                        });
                                                      },
                                                    ),
                                                    Text(
                                                        'Steps: ${httpService.steps1}${httpService.steps1 == 50 ? " (default)" : ""}'),
                                                    SliderTheme(
                                                      data: SliderThemeData(
                                                        thumbColor: Colors
                                                            .white, // Set the thumb color to white
                                                        activeTrackColor: Colors
                                                            .white, // Set the active track color to white
                                                        inactiveTrackColor:
                                                            Color.fromARGB(
                                                                255,
                                                                77,
                                                                76,
                                                                76), // Set the inactive track color to grey
                                                        trackHeight:
                                                            8.0, // Adjust the track height as desired
                                                        overlayColor: Colors
                                                            .transparent, // Set the overlay color to transparent
                                                        thumbShape:
                                                            RoundSliderThumbShape(
                                                                enabledThumbRadius:
                                                                    8.0), // Customize the thumb shape
                                                        overlayShape:
                                                            RoundSliderOverlayShape(
                                                                overlayRadius:
                                                                    16.0), // Customize the overlay shape
                                                        valueIndicatorColor: Colors
                                                            .white, // Set the value indicator color to white
                                                        valueIndicatorTextStyle:
                                                            TextStyle(
                                                                color: Colors
                                                                    .black), // Set the value indicator text color to black
                                                      ),
                                                      child: Slider(
                                                        value: httpService
                                                            .steps1
                                                            .toDouble(),
                                                        min: 1.0,
                                                        max: 50.0,
                                                        divisions: 49,
                                                        onChanged:
                                                            (double value) {
                                                          setState(() {
                                                            httpService.steps1 =
                                                                value.round();
                                                          });
                                                        },
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: Text(
                              "Right\n",
                              style: TextStyle(
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          value: "Right",
                        ),
                      ],
                      onChanged: (String? value) {
                        // Handle dropdown value changes if needed
                      },
                    ),
                  ),
                ),
              ],
            );

            _imageReturned = true;
            _loading = false; // Set loading to false when image arrives
          });
          _base64Image = posts[0].imageBase64;
        } else {
          setState(() {
            _loading = false; // Set loading to false when no posts are returned
          });
          if (retryCount < maxRetries) {
            retryCount++;
            fetchImage(); // Retry the request
          } else {
            showDialog(
              // Show error popup after max retries
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Error: No image returned'),
                  content: Text(
                    'Please try again later. This is an unexpected server issue with the image generation network.',
                  ),
                  actions: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.white, // Set the background color to white
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
          }
        }
      });
    }

// Call the function initially
    fetchImage();
    if (!mounted) {
      return; // Break out of the function if widget is not mounted
    }
    // Update the text to show the current value of _denoisingStrength
    setState(() {
      _denoisingStrengthText =
          'Denoising Strength: ${_denoisingStrength.toStringAsFixed(2)}';
    });
  }

  void _saveImage(String base64Image) async {
    // Convert the base64 encoded image to a list of bytes
    List<int> imageBytes = base64Decode(base64Image);

    // Save image to temporary directory
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
    // Save the image file to the gallery
    await GallerySaver.saveImage(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff424242),
        selectedItemColor: Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Color.fromARGB(255, 107, 106, 106),
        currentIndex: 2, // Set the currentIndex to 2 for the active icon
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.text_fields),
            label: 'txt2img',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.brush_outlined),
            label: 'AI paint',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.image),
            label: 'img2img',
          ),
        ],
        onTap: (int index) {
          switch (index) {
            case 0:
              imageCache.clear();
              Navigator.pushReplacementNamed(context, '/');
              break;
            case 1:
              imageCache.clear();
              Navigator.pushReplacementNamed(context, '/painterpage');
              break;
            case 2:
              // Handle the 'Add' button tap
              break;
          }
        },
      ),
      drawerEnableOpenDragGesture: false,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Container(
          alignment: Alignment.centerLeft,
          child: Text(
            'Img2img',
          ),
        ),
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
                            'Img2img is a method to generate AI images based on an input image and a text prompt. The generated image will follow the color and composition of the input image, while the text prompt fills in the details.',
                          ),
                          Text(
                            '\nBoth the input image and the prompt are necessary for img2img.',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '\nProcessed images, when outpainted, yield optimal results with a denoising strength of "1.00", and a contextually aware prompt.',
                            style: TextStyle(fontWeight: FontWeight.bold),
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
      body: Center(
        child: ListView(
          physics: BouncingScrollPhysics(),
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                    // Add padding to the text field
                    padding:
                        const EdgeInsets.only(top: 4.0, left: 8.0, right: 8.0),
                    child: TextField(
                      controller: _textEditingController,
                      maxLength: 100,
                      cursorColor:
                          Colors.white, // Set the cursor color to white
                      decoration: InputDecoration(
                        labelStyle: TextStyle(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black,
                              offset: Offset(2, 2),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                        labelText: 'Enter text prompt',
                        // Remove padding around the text field
                        contentPadding: EdgeInsets.zero,
                        // Add a clear icon button on the right side of the text field
                        suffixIcon: IconButton(
                          icon: Icon(Icons.clear,
                              color:
                                  Colors.white), // Set the icon color to white
                          onPressed: () {
                            if (!mounted) {
                              return; // Break out of the function if widget is not mounted
                            }
                            setState(() => _query = '');

                            _textEditingController.clear();
                          },
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.white,
                          ),
                        ),
                      ),
                      onChanged: (query) {
                        _updateQuery(query);
                      },
                    )),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.settings,
                          size: 30,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          SystemChannels.textInput
                              .invokeMethod('TextInput.hide');
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: Text('Advanced Img2img Settings'),
                                content: StatefulBuilder(
                                  builder: (BuildContext context,
                                      StateSetter setState) {
                                    return SingleChildScrollView(
                                        child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        TextField(
                                          cursorColor: Colors
                                              .white, // Set the cursor color to white
                                          decoration: InputDecoration(
                                            focusedBorder: UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                color: Colors.white,
                                              ),
                                            ),
                                            labelText: 'Seed',
                                            labelStyle: TextStyle(
                                              color: Colors.white,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.black,
                                                  offset: Offset(2, 2),
                                                  blurRadius: 14,
                                                ),
                                              ],
                                            ),
                                            hintText: '-1 (random)',
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              seedParam = value;
                                              _textFieldController.selection =
                                                  TextSelection.fromPosition(
                                                      TextPosition(
                                                          offset: seedParam
                                                              .length));
                                            });
                                          },
                                          controller: _textFieldController,
                                        ),
                                        SizedBox(height: 16.0),
                                        Text(
                                            '\nSampler: ${httpService.selectedOption == 'Euler a' ? 'Euler a (default)' : httpService.selectedOption}'),
                                        DropdownButton<String>(
                                          value: httpService.selectedOption,
                                          items: <String>[
                                            'Euler a',
                                            'Euler',
                                            'LMS',
                                            'Heun',
                                            'DPM2',
                                            'DPM2 a',
                                            'DPM++ 2S a',
                                            'DPM++ 2M',
                                            'DPM++ SDE',
                                            'DPM fast',
                                            'DPM adaptive',
                                            'LMS Karras',
                                            'DPM2 Karras',
                                            'DPM2 a Karras',
                                            'DPM++ 2S a Karras',
                                            'DPM++ 2M Karras',
                                            'DPM++ SDE Karras',
                                            'DDIM',
                                            'PLMS'
                                          ].map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (newValue) {
                                            setState(() {
                                              httpService.selectedOption =
                                                  newValue!;
                                              // Do something with the selected value
                                              debugPrint(
                                                  'Selected option: $_selectedOption');
                                            });
                                          },
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                            'Steps: ${httpService.steps}${httpService.steps == 50 ? " (default)" : ""}'),
                                        SliderTheme(
                                          data: SliderThemeData(
                                            thumbColor: Colors
                                                .white, // Set the thumb color to white
                                            activeTrackColor: Colors
                                                .white, // Set the active track color to white
                                            inactiveTrackColor: Color.fromARGB(
                                                255,
                                                77,
                                                76,
                                                76), // Set the inactive track color to grey
                                            trackHeight:
                                                8.0, // Adjust the track height as desired
                                            overlayColor: Colors
                                                .transparent, // Set the overlay color to transparent
                                            thumbShape: RoundSliderThumbShape(
                                                enabledThumbRadius:
                                                    8.0), // Customize the thumb shape
                                            overlayShape: RoundSliderOverlayShape(
                                                overlayRadius:
                                                    16.0), // Customize the overlay shape
                                            valueIndicatorColor: Colors
                                                .white, // Set the value indicator color to white
                                            valueIndicatorTextStyle: TextStyle(
                                                color: Colors
                                                    .black), // Set the value indicator text color to black
                                          ),
                                          child: Slider(
                                            value: httpService.steps.toDouble(),
                                            min: 1.0,
                                            max: 50.0,
                                            divisions: 49,
                                            onChanged: (double value) {
                                              setState(() {
                                                httpService.steps =
                                                    value.round();
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ));
                                  },
                                ),
                                actions: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.all(
                                        8.0), // Set the desired padding value
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors
                                            .white, // Set the background color to white
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          httpService.seedParam =
                                              _textFieldController.text;
                                        });
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                        'Save',
                                        style: TextStyle(
                                            color: Colors
                                                .black), // Set the text color to black
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                      Padding(
                        // Add left and top padding to the button
                        padding: const EdgeInsets.only(right: 4.0),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor:
                                Colors.white, // Set the text color to black
                          ),
                          child: Text('Send ➤'),
                          onPressed: _imageFile.path.isNotEmpty &
                                  _query.isNotEmpty &
                                  _denoisingStrengthText.isNotEmpty &
                                  !_loading
                              ? () async {
                                  if (!mounted) {
                                    return; // Break out of the function if widget is not mounted
                                  }
                                  //print(_sendButtonPressCount);
                                  if (_adLoaded) {
                                    _interstitialAd!.show();
                                    _adLoaded = false;
                                  }
                                  var connectivityResult = await (Connectivity()
                                      .checkConnectivity());
                                  if (connectivityResult ==
                                      ConnectivityResult.mobile) {
                                    // I am connected to a mobile network.
                                  } else if (connectivityResult ==
                                      ConnectivityResult.wifi) {
                                    // I am connected to a wifi network.
                                  } else if (connectivityResult ==
                                      ConnectivityResult.none) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Error: Networking'),
                                          content: Text(
                                              'No network/improper network conditions detected. We need to establish an internet connection to process image generations.'),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors
                                                    .white, // Set the background color to white
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
                                    return;
                                  }
                                  if (!mounted) {
                                    return; // Break out of the function if widget is not mounted
                                  }
                                  setState(() => _loading = true);
                                  _submitImageAndQuery();
                                  FocusScope.of(context).unfocus();
                                  Fluttertoast.showToast(
                                    msg: 'Image Processing',
                                    toastLength: Toast.LENGTH_SHORT,
                                    gravity: ToastGravity.BOTTOM,
                                    backgroundColor:
                                        const Color.fromARGB(255, 0, 0, 0),
                                    textColor: Colors.white,
                                    fontSize: 16.0,
                                  );
                                  // _cooldown prevents button spam
                                  //setState(() => _cooldown = true);
                                  //await Future.delayed(Duration(seconds: 12));
                                  //setState(() => _cooldown = false);
                                }
                              : null,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: _isLoading
                              ? Color.fromARGB(255, 77, 76, 76)
                              : Colors.white,
                        ),
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              )
                            : Text('🎲'),
                        onPressed: (_imageFile.path.isNotEmpty &&
                                _query.isNotEmpty &&
                                _denoisingStrengthText.isNotEmpty &&
                                !_loading)
                            ? () async {
                                debugPrint(_query);
                                if (!mounted) {
                                  return; // Break out of the function if widget is not mounted
                                }
                                setState(() {
                                  _isLoading = true;
                                });

                                // Set the URL and headers for the POST request
                                var url = Uri.parse(
                                    'https://prompt.serverboi.org/generate');
                                var headers = {
                                  'Content-Type': 'application/json'
                                };

                                // Set the request body with the prompt from the input box
                                var body = jsonEncode({'prompt': _query});

                                // Send the POST request and wait for the response
                                var response = await http.post(url,
                                    headers: headers, body: body);

                                // Check if the response was successful
                                if (response.statusCode == 200) {
                                  if (!mounted) {
                                    return; // Break out of the function if widget is not mounted
                                  }
                                  setState(() {});
                                  // Get the response data
                                  var jsonResponse = jsonDecode(response.body);
                                  var responseDataText = jsonResponse[0];

                                  // Define the list of unwanted strings to remove
                                  final unwantedStrings = [
                                    ' by',
                                    ' a',
                                    ' in',
                                    ' with',
                                    ' an',
                                    ' jus',
                                    ' at',
                                    ' the',
                                    ' at the',
                                    ' on ',
                                    ' on',
                                    ' on black',
                                    ' and',
                                    ' by the',
                                    ' by a',
                                    ' holding',
                                    '.',
                                    ' m',
                                    ' a m',
                                    ' of',
                                    ' the style',
                                    ' in the style',
                                    ' in the',
                                    ' in',
                                    ',',
                                    ' b',
                                    ' c',
                                    ' d',
                                    ' e',
                                    ' f',
                                    ' g',
                                    ' h',
                                    ' i',
                                    ' j',
                                    ' k',
                                    ' l',
                                    ' m',
                                    ' n',
                                    ' o',
                                    ' p',
                                    ' q',
                                    ' r',
                                    ' s',
                                    ' t',
                                    ' u',
                                    ' v',
                                    ' w',
                                    ' x',
                                    ' y',
                                    ' z'
                                  ];

                                  // Remove unwanted strings from the end of the response data
                                  for (var unwantedString in unwantedStrings) {
                                    if (responseDataText
                                        .endsWith(unwantedString)) {
                                      responseDataText =
                                          responseDataText.substring(
                                              0,
                                              responseDataText.length -
                                                  unwantedString.length);
                                    }
                                  }

                                  // Update the input box with the processed response data
                                  setState(() {
                                    _query = responseDataText;
                                    _textEditingController.text = _query;
                                    _textEditingController.selection =
                                        TextSelection.fromPosition(TextPosition(
                                      offset:
                                          _textEditingController.text.length,
                                    ));
                                    _isLoading = false;
                                  });
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Error: No image returned'),
                                        content: Text(
                                            'Please try again later. This is an unexpected server issue with the prompt generation network.'),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors
                                                  .white, // Set the background color to white
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
                                  // Handle the error
                                  //print('Request failed with status: ${response.statusCode}.');
                                  setState(() {
                                    _isLoading = false;
                                  });
                                }
                              }
                            : null,
                      ),
                      Padding(
                        // Add top padding to the button
                        padding: const EdgeInsets.only(left: 4.0, right: 4.0),

                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor:
                                Colors.white, // Set the text color to black
                          ),
                          child: const Text('Upload 🖼️'),
                          onPressed: _loading ? null : _getFromGallery,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: Icon(Icons.help_outline),
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
                                            'Denoising strength is a pivotal setting that controls the extent of noise reduction in generating AI images. A higher value intensifies noise removal, but can potentially diminish the resemblance to the original input. On the other hand, a lower value maintains the image\'s fidelity to the input, preserving original details and imperfections.',
                                          ),
                                          Text(
                                            '\nProcessed images, when outpainted, yield optimal results with a denoising strength of "1.00".',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
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
                          Text(
                            _denoisingStrengthText,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SliderTheme(
                      data: SliderThemeData(
                        thumbColor:
                            Colors.white, // Set the thumb color to white
                        trackHeight: 8.0, // Adjust the track height as desired
                        activeTrackColor:
                            Colors.white, // Set the active track color to grey
                        inactiveTrackColor: Color.fromARGB(255, 77, 76,
                            76), // Set the inactive track color to grey
                      ),
                      child: Slider(
                        value: _denoisingStrength,
                        min: 0.01,
                        max: 1,
                        onChanged: (value) {
                          if (!mounted) {
                            return; // Break out of the function if widget is not mounted
                          }
                          setState(() {
                            _denoisingStrength = value;
                            _denoisingStrengthText =
                                'Denoising Strength: ${_denoisingStrength.toStringAsFixed(2)}'; // update text
                          });
                        },
                      ),
                    ),
                    if (_loading)
                      SingleChildScrollView(
                        child: Column(
                          children: [
                            Container(
                              height: 3.0,
                              child: Align(
                                alignment: Alignment.bottomCenter,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (_loading)
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          height: 3.0,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Column(
                              children: [
                                LinearProgressIndicator(
                                  minHeight: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Container(
                  child: _imageWidget,
                ),
                if (_base64Image.isNotEmpty && _imageReturned)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          // Add left and top padding to the button
                          padding: const EdgeInsets.only(right: 4.0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                            child: const Text('Save to Gallery'),
                            onPressed: _loading
                                ? null
                                : () {
                                    _saveImage(_base64Image);
                                  },
                          ),
                        ),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: Colors.white,
                            ),
                            child: Text('Upscale'),
                            onPressed: _upscaled || _loading
                                ? null
                                : () async {
                                    if (!mounted) {
                                      return; // Break out of the function if widget is not mounted
                                    }
                                    setState(() {
                                      _upscaled = true;
                                      _loading = true;
                                    });
                                    Fluttertoast.showToast(
                                      msg: 'Processing Upscale',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor: Colors.grey[700],
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                    //print(_base64Image);
                                    // Create the request body
                                    final requestBody = jsonEncode({
                                      "resize_mode": 0,
                                      "show_extras_results": true,
                                      "gfpgan_visibility": 0,
                                      "codeformer_visibility": 0,
                                      "codeformer_weight": 0,
                                      "upscaling_resize": 2,
                                      "upscaling_resize_w": 1024,
                                      "upscaling_resize_h": 1024,
                                      "upscaling_crop": true,
                                      "upscaler_1": "Lanczos",
                                      "upscaler_2": "Lanczos",
                                      "extras_upscaler_2_visibility": 0.5,
                                      "upscale_first": false,
                                      "image":
                                          "$_base64Image" // Pass in the current image string
                                    });

                                    // Send the POST request
                                    final response = await http.post(
                                      Uri.parse(
                                          'https://ai.serverboi.org/sdapi/v1/extra-single-image'),
                                      headers: {
                                        'accept': 'application/json',
                                        'Content-Type': 'application/json',
                                      },
                                      body: requestBody,
                                    );

                                    // Handle the response
                                    if (response.statusCode == 200) {
                                      if (!mounted) {
                                        return; // Break out of the function if widget is not mounted
                                      }
                                      // Do something with the response
                                      Map<String, dynamic> responseMap =
                                          jsonDecode(response.body);
                                      String base64Image = responseMap['image'];

                                      setState(() {
                                        _base64Image =
                                            base64Image; // Update the _base64Image variable
                                        _imageWidget = Image.memory(
                                            gaplessPlayback: true,
                                            base64Decode(_base64Image));
                                        _imageReturned = true;
                                        _loading = false;
                                      });
                                      debugPrint(base64Image);
                                      // ...
                                    }
                                    // if we managed our states correctly this should never happen
                                    if (response.statusCode == 413) {
                                      if (!mounted) {
                                        return; // Break out of the function if widget is not mounted
                                      }
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title:
                                                Text('Error: Image too large'),
                                            content: Text(
                                                'The image that was sent to the upscaler network is too large.'),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors
                                                      .white, // Set the background color to white
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
                                      if (!mounted) {
                                        return; // Break out of the function if widget is not mounted
                                      }
                                      // given some http error code
                                      setState(() {
                                        _loading = false;
                                      });
                                      //print(response.body);
                                      debugPrint(_base64Image);
                                    }
                                  }),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void processImageAndMakeRequest(
    List<Post> posts,
    String imageBase64,
    _latentMode,
    _initimageInclude,
    selectedOption,
    String seedParam1,
    int steps1,
  ) async {
    setState(() {
      _sendButtonPressCount++;
      print(_sendButtonPressCount);
    });
    if (_sendButtonPressCount % 3 == 0) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5']));
      String adUnitId = '';

      // Retrieve the appropriate ad unit ID based on the build mode and platform
      adUnitId = Config.getAdUnitId(
        isRelease: kReleaseMode,
        isAndroid: Platform.isAndroid,
      );
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _adLoaded = true;
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    }

    //right?
    // Decode the base64 image string back to bytes
    List<int> imageBytes = base64Decode(imageBase64);
    String textInput = _textEditingController.text;
    // Prepare the request URL
    Uri apiUrl = Uri.parse(
        'https://outpaint.serverboi.org/image2image?input=$textInput&seed=$seedParam1&steps=$steps1&mask=0&invert=0&fill_mode=$_latentMode&init_include=$_initimageInclude&sampler=$selectedOption');

    print(apiUrl);
    // Prepare the request body (assuming the API accepts image data as a form field with key "init_image")
    var request = http.MultipartRequest('POST', apiUrl)
      ..files.add(http.MultipartFile.fromBytes('init_image', imageBytes,
          filename: 'input.jpg'));

    try {
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        setState(() {
          _loading = false;
        });
        // Handle the successful response here (e.g., display the result)
        String responseBody = await response.stream.bytesToString();
        debugPrint('Response: $responseBody');

        // Assuming the response contains a JSON object with a key "images"
        List<dynamic> imageList = jsonDecode(responseBody)['images'];

        if (imageList.isNotEmpty) {
          String newImageBase64 = imageList[0];

          // Navigate to the new page and pass the newImageBase64 data as a parameter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageDisplayPage(imageBase64: newImageBase64),
            ),
          );
        } else {
          setState(() {
            _loading = false;
          });
          debugPrint('Error: "images" key is empty in the API response.');
        }
      } else {
        setState(() {
          _loading = false;
        });
        // Handle any errors or unsuccessful response here
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // Handle any exceptions that occur during the request
      debugPrint('Error occurred: $e');
    }
  }

  void processImageAndMakeRequest1(
      List<Post> posts,
      String imageBase64,
      _latentMode,
      _initimageInclude,
      selectedOption,
      seedParam1,
      steps1) async {
    //left?
    setState(() {
      _sendButtonPressCount++;
      print(_sendButtonPressCount);
    });
    if (_sendButtonPressCount % 3 == 0) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5']));
      String adUnitId = '';

      // Retrieve the appropriate ad unit ID based on the build mode and platform
      adUnitId = Config.getAdUnitId(
        isRelease: kReleaseMode,
        isAndroid: Platform.isAndroid,
      );
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _adLoaded = true;
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    }
    // Decode the base64 image string back to bytes
    List<int> imageBytes = base64Decode(imageBase64);

    // Prepare the request URL
    String textInput = _textEditingController.text;
    // Prepare the request URL
    Uri apiUrl = Uri.parse(
        'https://outpaint.serverboi.org/image2image?input=$textInput&seed=$seedParam1&steps=$steps1&mask=0&invert=1&fill_mode=$_latentMode&init_include=$_initimageInclude&sampler=$selectedOption');

    // Prepare the request body (assuming the API accepts image data as a form field with key "init_image")
    var request = http.MultipartRequest('POST', apiUrl)
      ..files.add(http.MultipartFile.fromBytes('init_image', imageBytes,
          filename: 'input.jpg'));

    try {
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        setState(() {
          _loading = false;
        });
        // Handle the successful response here (e.g., display the result)
        String responseBody = await response.stream.bytesToString();
        debugPrint('Response: $responseBody');

        // Assuming the response contains a JSON object with a key "images"
        List<dynamic> imageList = jsonDecode(responseBody)['images'];

        if (imageList.isNotEmpty) {
          String newImageBase64 = imageList[0];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageDisplayPage(imageBase64: newImageBase64),
            ),
          );
        } else {
          setState(() {
            _loading = false;
          });
          debugPrint('Error: "images" key is empty in the API response.');
        }
      } else {
        setState(() {
          _loading = false;
        });
        // Handle any errors or unsuccessful response here
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // Handle any exceptions that occur during the request
      debugPrint('Error occurred: $e');
    }
  }

  void processImageAndMakeRequest2(
      List<Post> posts,
      String imageBase64,
      _latentMode,
      _initimageInclude,
      selectedOption,
      seedParam1,
      steps1) async {
    //top?
    setState(() {
      _sendButtonPressCount++;
      print(_sendButtonPressCount);
    });
    if (_sendButtonPressCount % 3 == 0) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5']));
      String adUnitId = '';

      // Retrieve the appropriate ad unit ID based on the build mode and platform
      adUnitId = Config.getAdUnitId(
        isRelease: kReleaseMode,
        isAndroid: Platform.isAndroid,
      );
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _adLoaded = true;
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    }
    // Decode the base64 image string back to bytes
    List<int> imageBytes = base64Decode(imageBase64);

    // Prepare the request URL
    String textInput = _textEditingController.text;
    // Prepare the request URL
    Uri apiUrl = Uri.parse(
        'https://outpaint.serverboi.org/image2image?input=$textInput&seed=$seedParam1&steps=$steps1&mask=1&invert=0&fill_mode=$_latentMode&init_include=$_initimageInclude&sampler=$selectedOption');

    // Prepare the request body (assuming the API accepts image data as a form field with key "init_image")
    var request = http.MultipartRequest('POST', apiUrl)
      ..files.add(http.MultipartFile.fromBytes('init_image', imageBytes,
          filename: 'input.jpg'));

    try {
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        setState(() {
          _loading = false;
        });
        // Handle the successful response here (e.g., display the result)
        String responseBody = await response.stream.bytesToString();
        debugPrint('Response: $responseBody');

        // Assuming the response contains a JSON object with a key "images"
        List<dynamic> imageList = jsonDecode(responseBody)['images'];

        if (imageList.isNotEmpty) {
          String newImageBase64 = imageList[0];

          // Navigate to the new page and pass the newImageBase64 data as a parameter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageDisplayPage(imageBase64: newImageBase64),
            ),
          );
        } else {
          setState(() {
            _loading = false;
          });
          debugPrint('Error: "images" key is empty in the API response.');
        }
      } else {
        setState(() {
          _loading = false;
        });
        // Handle any errors or unsuccessful response here
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // Handle any exceptions that occur during the request
      debugPrint('Error occurred: $e');
    }
  }

  void processImageAndMakeRequest3(
      List<Post> posts,
      String imageBase64,
      _latentMode,
      bool _initimageInclude,
      selectedOption,
      String seedParam1,
      steps1) async {
    //bottom?
    setState(() {
      _sendButtonPressCount++;
      print(_sendButtonPressCount);
    });
    if (_sendButtonPressCount % 3 == 0) {
      MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
          testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5']));
      String adUnitId = '';

      // Retrieve the appropriate ad unit ID based on the build mode and platform
      adUnitId = Config.getAdUnitId(
        isRelease: kReleaseMode,
        isAndroid: Platform.isAndroid,
      );
      InterstitialAd.load(
        adUnitId: adUnitId,
        request: AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            _interstitialAd = ad;
            _adLoaded = true;
            ad.show();
          },
          onAdFailedToLoad: (LoadAdError error) {
            debugPrint('InterstitialAd failed to load: $error');
          },
        ),
      );
    }
    // Decode the base64 image string back to bytes
    List<int> imageBytes = base64Decode(imageBase64);

    // Prepare the request URL
    String textInput = _textEditingController.text;
    // Prepare the request URL
    Uri apiUrl = Uri.parse(
        'https://outpaint.serverboi.org/image2image?input=$textInput&seed=$seedParam1&steps=$steps1&mask=1&invert=1&fill_mode=$_latentMode&init_include=$_initimageInclude&sampler=$selectedOption');

    // Prepare the request body (assuming the API accepts image data as a form field with key "init_image")
    var request = http.MultipartRequest('POST', apiUrl)
      ..files.add(http.MultipartFile.fromBytes('init_image', imageBytes,
          filename: 'input.jpg'));

    try {
      // Send the request and get the response
      http.StreamedResponse response = await request.send();
      // Check if the request was successful (status code 200)
      if (response.statusCode == 200) {
        setState(() {
          _loading = false;
        });
        // Handle the successful response here (e.g., display the result)
        String responseBody = await response.stream.bytesToString();
        debugPrint('Response: $responseBody');

        // Assuming the response contains a JSON object with a key "images"
        List<dynamic> imageList = jsonDecode(responseBody)['images'];

        if (imageList.isNotEmpty) {
          String newImageBase64 = imageList[0];

          // Navigate to the new page and pass the newImageBase64 data as a parameter
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ImageDisplayPage(imageBase64: newImageBase64),
            ),
          );
        } else {
          setState(() {
            _loading = false;
          });
          debugPrint('Error: "images" key is empty in the API response.');
        }
      } else {
        setState(() {
          _loading = false;
        });
        // Handle any errors or unsuccessful response here
        debugPrint('Request failed with status: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      // Handle any exceptions that occur during the request
      debugPrint('Error occurred: $e');
    }
  }
}
