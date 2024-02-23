import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:flutter/material.dart';

import 'http_service.dart';
import 'post_model.dart';
import 'dart:convert';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'main.dart';

int _sendButtonPressCount = sendButtonPressCount;

class PostsPage extends StatelessWidget {
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.velocity.pixelsPerSecond.dx > 500) {
          // User swiped right
        } else {
          //print(details.velocity.pixelsPerSecond.dx);
          // User swiped left
          //FocusScope.of(context).unfocus();
          //Navigator.pushNamed(context, '/another_page');
        }
      },
      child: Scaffold(
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xff424242),
          selectedItemColor: Color.fromARGB(255, 255, 255, 255),
          unselectedItemColor: Color.fromARGB(255, 107, 106, 106),
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
                break;
              case 1:
                imageCache.clear();
                Navigator.pushReplacementNamed(context, '/painterpage');
                break;
              case 2:
                imageCache.clear();
                Navigator.pushReplacementNamed(context, '/another_page');
                // Handle the 'Add' button tap
                break;
            }
          },
        ),
        body: SafeArea(
          child: _PostsPage(),
        ),
      ),
    );
  }
}

class _PostsPage extends StatefulWidget {
  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<_PostsPage> {
  final HttpService httpService = HttpService();
  TextEditingController queryController = TextEditingController();
  List<Post> posts = [];
  String value = '';
  InterstitialAd? _interstitialAd;

  final myFocusNode = FocusNode();
  double denoising_strength = 0.5;

  int get sendButtonPressCount => _sendButtonPressCount;
  final Key imageKey = UniqueKey();
  final GlobalKey _imageKey = GlobalKey();
  bool _isLoadingButton = false; // New loading state variable
  // ignore: unused_field
  bool _isAdloaded = false;
  // ignore: unused_field
  String _base64Image = '';
  ValueNotifier<String> _query = ValueNotifier<String>('');
  bool _loading = false;
  bool _isLoading = false;
  bool _canPressButton = true;
  ValueNotifier<bool> _isQueryEmpty = ValueNotifier<bool>(true);
  String _selectedOption = 'Euler a';

  TextEditingController _textFieldController = TextEditingController();
  int steps = 50;

  @override
  void initState() {
    super.initState();
    _query = ValueNotifier<String>('');

    createInterstitialAd();
  }

  void createInterstitialAd() {
    String adUnitId = '';

    // Retrieve the appropriate ad unit ID based on the build mode and platform
    adUnitId = Config.getAdUnitId(
      isRelease: kReleaseMode,
      isAndroid: Platform.isAndroid,
    );

    MobileAds.instance.initialize();
    MobileAds.instance.updateRequestConfiguration(RequestConfiguration(
      testDeviceIds: ['7017C9040B0BBB865A301590C55CC6C5'],
    ));

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('InterstitialAd failed to load: $error');
        },
      ),
    );
  }

  void showInterstitialAd() {
    if (_interstitialAd == null) {
      debugPrint('InterstitialAd not yet loaded...');
      return;
    }

    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        ad.dispose();
        createInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        ad.dispose();
        createInterstitialAd();
      },
    );

    _interstitialAd?.show();
    _interstitialAd = null;
  }

  @override
  Widget build(BuildContext context) {
    void setState(fn) {
      if (mounted) {
        super.setState(fn);
      }
    }

    return SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
              child: TextField(
                cursorColor: Colors.white, // Set the cursor color to white
                focusNode: myFocusNode,
                controller: queryController,
                maxLength: 100,

                decoration: InputDecoration(
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                    ),
                  ),
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
                  contentPadding: EdgeInsets.zero,
                  suffixIcon: IconButton(
                    icon: Icon(
                      Icons.clear,
                      color: Colors.white, // Set the icon color to white
                    ),
                    onPressed: () {
                      myFocusNode.requestFocus();
                      setState(() {
                        queryController.clear();
                        _canPressButton = false;
                        _isQueryEmpty.value = true;
                      });
                    },
                  ),
                ),
                onChanged: (query) {
                  if (!_loading) {
                    _canPressButton = true;
                  }
                  _query.value = query;
                  _isQueryEmpty.value = query.isEmpty;
                },
              ),
            ),
            ValueListenableBuilder(
              valueListenable: _query,
              builder: (BuildContext context, String value, Widget? child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.settings,
                        size: 30,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        SystemChannels.textInput.invokeMethod('TextInput.hide');
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Advanced Txt2img Settings'),
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
                                                        offset:
                                                            seedParam.length));
                                          });
                                        },
                                        controller: _textFieldController,
                                      ),
                                      SizedBox(height: 16.0),
                                      Text(
                                          'Sampler: ${httpService.selectedOption == 'Euler a' ? 'Euler a (default)' : httpService.selectedOption}'),
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
                                              httpService.steps = value.round();
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
                      padding: const EdgeInsets.only(left: 8, right: 8),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor:
                              Colors.white, // Set the text color to black
                        ),
                        onPressed: _query.value.isNotEmpty && _canPressButton
                            ? () async {
                                SystemChannels.textInput
                                    .invokeMethod('TextInput.hide');
                                _sendButtonPressCount++;
                                print(_sendButtonPressCount);
                                if (_sendButtonPressCount % 3 == 0) {
                                  showInterstitialAd();
                                }
                                imageCache.clear();
                                setState(() {
                                  _loading = true;
                                  _canPressButton = false;
                                });

                                var connectivityResult =
                                    await (Connectivity().checkConnectivity());
                                if (connectivityResult ==
                                        ConnectivityResult.mobile ||
                                    connectivityResult ==
                                        ConnectivityResult.wifi) {
                                  // Check if we can connect to the URL
                                  var response = await http.get(
                                      Uri.parse('https://ai.serverboi.org'));
                                  if (response.statusCode == 200) {
                                    // We are connected to the internet and can connect to the URL
                                  } else {
                                    setState(() {
                                      _loading = false;
                                      _canPressButton = true;
                                    });
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title:
                                              Text('Error: No image returned'),
                                          content: Text(
                                              'Please try again later. This is an unexpected server issue with the image generation network.'),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                backgroundColor: Colors
                                                    .white, // Set the text color to black
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
                                } else {
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
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors
                                                  .white, // Set the text color to black
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
                                  setState(() {
                                    _loading = false;
                                    _canPressButton = true;
                                  });
                                  return;
                                }

                                FocusScope.of(context).unfocus();
                                if (_query.value.isNotEmpty) {
                                  if (_sendButtonPressCount % 3 != 0) {
                                    // Check if variable is divisible by 3
                                    Fluttertoast.showToast(
                                      msg: 'Image Processing',
                                      toastLength: Toast.LENGTH_SHORT,
                                      gravity: ToastGravity.BOTTOM,
                                      backgroundColor:
                                          const Color.fromARGB(255, 0, 0, 0),
                                      textColor: Colors.white,
                                      fontSize: 16.0,
                                    );
                                  }
                                  List<Post> newPosts =
                                      await httpService.getPosts(_query.value);

                                  while (newPosts.isEmpty) {
                                    newPosts = await httpService
                                        .getPosts(_query.value);
                                    if (newPosts.isEmpty) {
                                      // Show error message and wait for some time before retrying
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text(
                                                'Error: No image returned'),
                                            content: Text(
                                                'Please try again later. This is an unexpected server issue with the image generation network.'),
                                            actions: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  foregroundColor: Colors.black,
                                                  backgroundColor: Colors
                                                      .white, // Set the text color to black
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
                                      await Future.delayed(Duration(
                                          seconds:
                                              10)); // wait for 10 seconds before retrying
                                    }
                                  }
                                  setState(() {
                                    _loading = false;
                                    posts = newPosts;
                                  });

                                  Future.delayed(Duration(seconds: 0), () {
                                    setState(() {
                                      _canPressButton = true;
                                    });
                                  });
                                } else {
                                  if (_isQueryEmpty == true) {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                              'Error: prompt field is empty'),
                                          content: Text(
                                              'Please try again later. This is an unexpected server issue with the prompt generation network.'),
                                          actions: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                backgroundColor: Colors
                                                    .white, // Set the text color to black
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
                                  setState(() {
                                    _loading = true;
                                    _canPressButton = true;
                                  });
                                }
                              }
                            : null,
                        child: Text('Send ➤'),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor:
                              Colors.white, // Set the text color to black
                        ),
                        onPressed: _isQueryEmpty.value && !_loading ||
                                !_canPressButton
                            ? null
                            : () async {
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
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text('Error: networking'),
                                        content: Text(
                                            'No network/improper network conditions detected. We need to establish an internet connection to process image generations.'),
                                        actions: <Widget>[
                                          TextButton(
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
                                setState(() {
                                  _isLoading = true;
                                  _canPressButton = false;
                                });
                                try {
                                  var response = await http
                                      .get(Uri.parse(
                                          'https://prompt.serverboi.org'))
                                      .timeout(Duration(
                                          seconds:
                                              6)); // set a timeout of 6 seconds
                                  if (response.statusCode == 404) {
                                    // Expected 404 error
                                  } else {
                                    setState(() {
                                      _isLoading = false;
                                      _canPressButton = true;
                                    });
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text('Error: networking'),
                                          content: Text(
                                              'No network/improper network conditions detected. We need to establish an internet connection to process image generations.'),
                                          actions: <Widget>[
                                            TextButton(
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
                                } on TimeoutException catch (_) {
                                  setState(() {
                                    _isLoading = false;
                                    _canPressButton = true;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Error: prompt generation failure'),
                                        content: Text(
                                            'Please try again later. This is an unexpected server issue with the prompt generation network.'),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors
                                                  .white, // Set the text color to black
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
                                } catch (e) {
                                  debugPrint('Error: $e');
                                  setState(() {
                                    _isLoading = false;
                                    _canPressButton = true;
                                  });
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Error: prompt generation failure'),
                                        content: Text(
                                            'Please try again later. This is an unexpected server issue with the prompt generation network.'),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors
                                                  .white, // Set the text color to black
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

                                setState(() {
                                  _isLoading = true;
                                  _canPressButton = false;
                                });
                                // Set the URL and headers for the POST request
                                final url = Uri.parse(
                                    'https://prompt.serverboi.org/generate');
                                final headers = {
                                  'Content-Type': 'application/json'
                                };

                                // Set the request body with the prompt from the input box
                                final body = jsonEncode(
                                    {'prompt': queryController.text});

                                // Send the POST request and wait for the response
                                final response = await http.post(url,
                                    headers: headers, body: body);

                                // Check if the response was successful
                                if (response.statusCode == 200) {
                                  setState(() {
                                    _isLoading = false;
                                    _canPressButton = true;
                                  });
                                  // Update the input box with the response data
                                  final responseData =
                                      jsonDecode(response.body);
                                  String responseDataText = responseData[0];

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

                                  for (final unwantedString
                                      in unwantedStrings) {
                                    if (responseDataText
                                        .endsWith(unwantedString)) {
                                      responseDataText =
                                          responseDataText.substring(
                                                  0,
                                                  responseDataText.length -
                                                      unwantedString.length) +
                                              '';
                                      break;
                                    }
                                  }

                                  queryController.text = responseDataText;
                                  _query.value = responseDataText;
                                  queryController.selection =
                                      TextSelection.fromPosition(TextPosition(
                                    offset: queryController.text.length,
                                  ));
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            'Error: prompt generation failure'),
                                        content: Text(
                                            'Please try again later. This is an unexpected server issue with the prompt generation network.'),
                                        actions: [
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              foregroundColor: Colors.black,
                                              backgroundColor: Colors
                                                  .white, // Set the text color to black
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
                                  debugPrint('Error: ${response.reasonPhrase}');
                                }
                              },
                        child: _isLoading
                            ? CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ) // Show the progress indicator
                            : Text('🎲'),
                      ),
                    ),
                  ],
                );
              },
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Checkbox(
                    value: includePrompt0,
                    onChanged: (value) {
                      setState(() {
                        includePrompt0 = value!;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  Text(
                    'Model style?',
                    style: TextStyle(
                      color: _loading ? Colors.grey : Colors.white,
                    ),
                  ),
                  Checkbox(
                    value: includePrompt1,
                    onChanged: (value) {
                      setState(() {
                        includePrompt1 = value!;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  Text(
                    'Painting style?',
                    style: TextStyle(
                      color: _loading ? Colors.grey : Colors.white,
                    ),
                  ),
                  Checkbox(
                    value: includePrompt2,
                    onChanged: (value) {
                      setState(() {
                        includePrompt2 = value!;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  Text(
                    'Anime style?',
                    style: TextStyle(
                      color: _loading ? Colors.grey : Colors.white,
                    ),
                  ),
                  Checkbox(
                    value: includePrompt3,
                    onChanged: (value) {
                      setState(() {
                        includePrompt3 = value!;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  Text(
                    'Vibrant style?',
                    style: TextStyle(
                      color: _loading ? Colors.grey : Colors.white,
                    ),
                  ),
                  Checkbox(
                    value: includePrompt4,
                    onChanged: (value) {
                      setState(() {
                        includePrompt4 = value!;
                      });
                    },
                    activeColor: Colors.white,
                    checkColor: Colors.black,
                  ),
                  Text(
                    'Vaporwave style?',
                    style: TextStyle(
                      color: _loading ? Colors.grey : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              Container(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        height: 2.6,
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: LinearProgressIndicator(
                            minHeight: 3,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (posts.isNotEmpty)
              StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: [
                      GestureDetector(
                        onLongPress: () {},
                        child: RepaintBoundary(
                          key: _imageKey,
                          child: Stack(
                            children: [
                              Image.memory(
                                gaplessPlayback: true,
                                base64Decode(posts[0].imageBase64),
                              ),
                              if (!_loading)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: StatefulBuilder(
                                    builder: (BuildContext context,
                                        StateSetter setState) {
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
                                                await (Connectivity()
                                                    .checkConnectivity());
                                            if (connectivityResult ==
                                                ConnectivityResult.mobile) {
                                              // I am connected to a mobile network.
                                            } else if (connectivityResult ==
                                                ConnectivityResult.wifi) {
                                              // I am connected to a wifi network.
                                            } else if (connectivityResult ==
                                                ConnectivityResult.none) {
                                              Fluttertoast.showToast(
                                                msg:
                                                    'Error: networking please try again',
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
                                                'Content-Type':
                                                    'application/json'
                                              };
                                              final body = jsonEncode({
                                                'image': posts[0].imageBase64
                                              });

                                              final response = await http.post(
                                                  url,
                                                  headers: headers,
                                                  body: body);
                                              if (response.statusCode == 200) {
                                                final jsonResponse =
                                                    jsonDecode(response.body);
                                                final info =
                                                    jsonResponse['info'];

                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title: Text('Info'),
                                                      content:
                                                          SingleChildScrollView(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            SelectableText(
                                                              'Prompt: $info',
                                                            ),
                                                            SizedBox(
                                                                height: 16),
                                                          ],
                                                        ),
                                                      ),
                                                      actions: [
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.white,
                                                          ),
                                                          child: Text('OK'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              } else {
                                                throw Exception(
                                                    'Failed to send image request');
                                              }
                                            } on SocketException catch (e) {
                                              debugPrint(
                                                  'Caught SocketException: $e');
                                              // Handle the SocketException
                                            } on Exception catch (e) {
                                              debugPrint(
                                                  'Caught Exception: $e');
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
                            ],
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: Alignment.center,
                            child: Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.black,
                                  backgroundColor: Colors
                                      .white, // Set the text color to black
                                ),
                                onPressed: _loading
                                    ? null
                                    : () async {
                                        List<int> imageBytes =
                                            base64Decode(posts[0].imageBase64);
                                        String imageString =
                                            base64.encode(imageBytes);
                                        //debugPrint(imageString);
                                        //decode imageString here
                                        List<int> imageData =
                                            base64.decode(imageString);
                                        // Save image to temporary directory
                                        final tempDir = await Directory
                                            .systemTemp
                                            .createTemp();
                                        final file =
                                            File('${tempDir.path}/image.png');
                                        await file.writeAsBytes(imageData);
                                        Fluttertoast.showToast(
                                          msg: 'Image downloading',
                                          gravity: ToastGravity.BOTTOM,
                                          toastLength: Toast.LENGTH_SHORT,
                                        );
                                        // Download image from temporary directory
                                        await GallerySaver.saveImage(file.path);
                                      },
                                child: Text('Save to gallery'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
          ],
        ));
  }
}
