import 'package:flutter/material.dart';
import 'posts.dart';
import 'gallery.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/services.dart'
    show DeviceOrientation, PlatformException, SystemChrome, rootBundle;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'dart:io';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_state_notifier/flutter_state_notifier.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scribble/scribble.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:image_cropper/image_cropper.dart';

class Config {
  static Map<String, dynamic>? _config;

  static Future<void> load() async {
    final configString = await rootBundle.loadString('assets/adsconfig.json');
    _config = json.decode(configString);
  }

  static String getAdUnitId(
      {required bool isRelease, required bool isAndroid}) {
    if (isRelease) {
      return isAndroid
          ? _config!['androidAdUnitIdRelease']
          : _config!['iosAdUnitIdRelease'];
    } else {
      return isAndroid
          ? _config!['androidAdUnitIdDebug']
          : _config!['iosAdUnitIdDebug'];
    }
  }
}

int _sendButtonPressCount = 0;

int get sendButtonPressCount => _sendButtonPressCount;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await Config.load();
  requestConsent();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  MobileAds.instance.initialize();

  int initialPressCount = sendButtonPressCount; // Get the initial value

  if (initialPressCount != 0) {
    _sendButtonPressCount = initialPressCount;
  }

  runApp(MyApp());
}

void requestConsent() {
  if (!kReleaseMode) {
    ConsentInformation.instance.reset();
  }
  ConsentDebugSettings debugSettings = ConsentDebugSettings(
    debugGeography: DebugGeography.debugGeographyEea,
    testIdentifiers: ['7017C9040B0BBB865A301590C55CC6C5'],
  );

  ConsentRequestParameters params = ConsentRequestParameters(
    consentDebugSettings: debugSettings,
  );

  ConsentInformation.instance.requestConsentInfoUpdate(
    params,
    () {
      loadForm(); // Call loadForm() after requestConsentInfoUpdate() success
    },
    (error) {
      // Handle error if needed
      debugPrint("requestConsent() error");
    },
  );
}

void loadForm() {
  ConsentForm.loadConsentForm(
    (ConsentForm consentForm) async {
      var status = await ConsentInformation.instance.getConsentStatus();
      //print(status);
      if (status == ConsentStatus.required) {
        consentForm.show(
          (FormError? formError) {
            // Handle dismissal by reloading form
            loadForm();
          },
        );
      }
    },
    (FormError formError) {
      debugPrint("loadForm() error");
      // Handle the error
    },
  );
}

const MaterialColor white = const MaterialColor(
  0xFFFFFFFF,
  const <int, Color>{
    50: const Color(0xFFFFFFFF),
    100: const Color(0xFFFFFFFF),
    200: const Color(0xFFFFFFFF),
    300: const Color(0xFFFFFFFF),
    400: const Color(0xFFFFFFFF),
    500: const Color(0xFFFFFFFF),
    600: const Color(0xFFFFFFFF),
    700: const Color(0xFFFFFFFF),
    800: const Color(0xFFFFFFFF),
    900: const Color(0xFFFFFFFF),
  },
);

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: white,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        primarySwatch: white,
        brightness: Brightness.dark,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      routes: <String, WidgetBuilder>{
        '/another_page': (BuildContext context) => AnotherPage(),
        '/another_page1': (BuildContext context) => AnotherPage1(),
        '/painterpage': (BuildContext context) => PainterPage()
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            SizedBox(height: 120.0),
            Text('Txt2img'),
          ],
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.help),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Txt2img info"),
                    content: SingleChildScrollView(
                      physics: ClampingScrollPhysics()
                          .applyTo(NeverScrollableScrollPhysics()),
                      child: ListBody(
                        children: <Widget>[
                          Text(
                              'The "Txt2img" tool works by utilizing an algorithm that has been trained on a dataset of images and their corresponding textual descriptions.'),
                          Text(
                              '\nThis allows the AI model to make sense of the complex relationships between text and images, and to generate new images that accurately reflect a given text prompt.'),
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
                      )
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: PostsPage(),
    );
  }
}

class CustomLicensePage extends StatelessWidget {
  Future<Map<String, String>> _getLatestPackageLicenses() async {
    final packageLicenseMap = <String, String>{};

    await for (final license in LicenseRegistry.licenses) {
      final package = license.packages.join(', ');
      final licenseText =
          license.paragraphs.map((paragraph) => paragraph.text).join('\n');
      packageLicenseMap[package] = licenseText;
    }

    return packageLicenseMap;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Third Party Licenses'),
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getLatestPackageLicenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading licenses'));
          } else if (snapshot.hasData) {
            final packageLicenseMap = snapshot.data!;
            return ListView.builder(
              itemCount: packageLicenseMap.length,
              itemBuilder: (context, index) {
                final package = packageLicenseMap.keys.elementAt(index);
                final licenseText = packageLicenseMap[package]!;
                return ExpansionTile(
                  title: Text(package),
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(licenseText),
                    ),
                  ],
                );
              },
            );
          } else {
            return Center(child: Text('No license information available'));
          }
        },
      ),
    );
  }
}

class LicenseEntry {
  final String package;
  final String licenseText;

  LicenseEntry(this.package, this.licenseText);
}

class AnotherPage1 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Credits"),
        actions: [
          IconButton(
            icon: Icon(Icons.cloud_done_sharp),
            onPressed: () async {
              final Uri _url =
                  Uri.parse('https://status.serverboi.org/status/app');
              if (await canLaunchUrl(_url)) {
                await launchUrl(_url);
              } else {
                throw 'Could not launch $_url';
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8.0, right: 8.0, top: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Color.fromARGB(255, 255, 255, 255),
                  width: 1.0,
                ),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: IntrinsicWidth(
                child: Container(
                  child: DropdownButton<String>(
                    hint: Text(" AI Models"),
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
                          onTap: () async {
                            final Uri _url = Uri.parse(
                                'https://huggingface.co/FredZhang7/distilgpt2-stable-diffusion-v2');
                            if (await canLaunchUrl(_url)) {
                              await launchUrl(_url);
                            } else {
                              throw 'Could not launch $_url';
                            }
                          },
                          child: Text(
                            "Prompting - distilgpt2-stable-diffusion-v2\n",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        value: "Prompting",
                      ),
                      DropdownMenuItem<String>(
                        child: GestureDetector(
                          onTap: () async {
                            final Uri _url = Uri.parse(
                                'https://huggingface.co/CompVis/stable-diffusion-safety-checker');
                            if (await canLaunchUrl(_url)) {
                              await launchUrl(_url);
                            } else {
                              throw 'Could not launch $_url';
                            }
                          },
                          child: Text(
                            "Saftey checking - stable diffusion safety checker\n",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        value: "Safety Checking",
                      ),
                      DropdownMenuItem<String>(
                        child: GestureDetector(
                          onTap: () async {
                            final Uri _url = Uri.parse(
                                'https://huggingface.co/stabilityai/stable-diffusion-2-inpainting');
                            if (await canLaunchUrl(_url)) {
                              await launchUrl(_url);
                            } else {
                              throw 'Could not launch $_url';
                            }
                          },
                          child: Text(
                            "Safetensors (inpaint) - stable-diffusion-2-inpainting",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        value: "Inpainting",
                      ),
                      DropdownMenuItem<String>(
                        child: GestureDetector(
                          onTap: () async {
                            final Uri _url = Uri.parse(
                                'https://civitai.com/models/4201/realistic-vision-v20');
                            if (await canLaunchUrl(_url)) {
                              await launchUrl(_url);
                            } else {
                              throw 'Could not launch $_url';
                            }
                          },
                          child: Text(
                            "Safetensors - realisticVisionV51_v51VAE\n",
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        value: "Txt2txt, Img2img",
                      ),
                    ],
                    onChanged: (String? value) {},
                  ),
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Container(
                      width: 150.0, // set the desired width
                      height: 150.0, // set the desired height
                      child: CircleAvatar(
                        radius: 100.0,
                        backgroundImage: AssetImage('assets/icons/avatar.png'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: Text(
                      'Jake Turner',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_on),
                      SizedBox(width: 5),
                      Text(
                        'Denver, Colorado',
                        style: TextStyle(fontSize: 16.0),
                      ),
                    ],
                  ),
                  SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () async {
                      final Uri _emailLaunchUri = Uri.parse(
                        'mailto:jake@serverboi.org?subject=',
                      );
                      await launchUrl(_emailLaunchUri);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.email),
                        SizedBox(width: 10.0),
                        Text(
                          'jake@serverboi.org',
                          style: TextStyle(
                              decoration: TextDecoration.underline,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () async {
                      final Uri _url = Uri.parse('https://serverboi.org');
                      if (await canLaunchUrl(_url)) {
                        await launchUrl(_url);
                      } else {
                        throw 'Could not launch $_url';
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.link),
                        SizedBox(width: 5),
                        Text(
                          "serverboi.org",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.0),
                  GestureDetector(
                    onTap: () async {
                      final Uri _url =
                          Uri.parse('https://app.serverboi.org/privacy.html');
                      if (await canLaunchUrl(_url)) {
                        await launchUrl(_url);
                      } else {
                        throw 'Could not launch $_url';
                      }
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_sharp),
                        SizedBox(width: 5),
                        Text(
                          "Privacy policy",
                          style: TextStyle(
                            fontSize: 16.0,
                            color: Colors.white,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsets.all(8.0), // Adjust the padding as needed
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.black,
                        backgroundColor:
                            Colors.white, // Set the background color to white
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => CustomLicensePage()),
                        );
                      },
                      child: Text('Third Party Licenses'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PainterPage extends StatefulWidget {
  const PainterPage({Key? key}) : super(key: key);

  @override
  State<PainterPage> createState() => _PainterPageState();
}

class _PainterPageState extends State<PainterPage> {
  String _query = '';
  TextEditingController _textEditingController = TextEditingController();
  TextEditingController queryController = TextEditingController();
  final myFocusNode = FocusNode();
  Uint8List? imageBytes; // Declare class-level variable
  late ScribbleNotifier notifier;
  Widget? _selectedImageWidget;
  XFile? _selectedImage; // Add this line
  // ignore: unused_field
  late ImagePicker _imagePicker;
  bool isLoading = false;

  TextEditingController inputController =
      TextEditingController(); // Add this line
  @override
  void initState() {
    removeFocus(); // Removes the keyboard from the screen
    super.initState();
    notifier = ScribbleNotifier(
        widths: [14.0, 27.0]); // Create a new instance with updated widths
    notifier.setColor(Color.fromARGB(255, 255, 17,
        0)); //this can be changed to set the opacity of the pen with the downside of it layering on itseld
    _imagePicker = ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xff424242),
        selectedItemColor: Color.fromARGB(255, 255, 255, 255),
        unselectedItemColor: Color.fromARGB(255, 107, 106, 106),
        currentIndex: 1, // Set the index of the active item
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
              break;
            case 2:
              imageCache.clear();
              Navigator.pushReplacementNamed(context, '/another_page');
              // Handle the 'Add' button tap
              break;
          }
        },
      ),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: const [
            Text('AI paint'),
          ],
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
                      physics: ClampingScrollPhysics()
                          .applyTo(NeverScrollableScrollPhysics()),
                      child: ListBody(
                        children: <Widget>[
                          Text(
                              'AI painting allows for finely placed adjustments to an image, enhancing details and adding new elements while preserving select sections.\n'),
                          Text(
                              '\nAI painting requires three essential components: an input image, a prompt, and a drawn paint overlay.',
                              style: TextStyle(fontWeight: FontWeight.bold)),
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
                      )
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            // Rest of the children
            if (_selectedImage != null)
              // This fixes the image warp to left issue
              Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Image.file(File(_selectedImage!.path)),
                  ),
                ],
              ),

// Important nested hierarchy of relationships between widgets:
            GestureDetector(
              onPanEnd: isLoading
                  ? null
                  : (_) {
                      setState(() {
                        removeFocus();
                        scribbleExists = true;
                      });
                    },
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: ClipRect(
                      child: Listener(
                        onPointerUp: isLoading
                            ? null
                            : (_) {
                                setState(() {
                                  removeFocus();
                                  scribbleExists = true;
                                });
                              },
                        child: Stack(
                          children: [
                            if (_selectedImage == null)
                              ElevatedButton(
                                onPressed: () {
                                  _pickImageFromGallery();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255,
                                      48,
                                      48,
                                      48), // Replace with the desired background color
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Upload an image',
                                        style: TextStyle(
                                          color: Colors
                                              .white, // Replace with the desired text color
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_selectedImage != null)
                              Positioned.fill(
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    double size = constraints.maxWidth <
                                            constraints.maxHeight
                                        ? constraints.maxWidth
                                        : constraints.maxHeight;
                                    return IgnorePointer(
                                      ignoring: isLoading,
                                      child: Stack(
                                        children: [
                                          // Render the selected image as the background

                                          // Postitioned here fixes image scale issue when keyboard opens on small screens
                                          Positioned(
                                            top: 0,
                                            left: 0,
                                            right: 0,
                                            child: Image.file(
                                                File(_selectedImage!.path)),
                                          ),
                                          // Add the Scribble widget with adjusted size and position
                                          Container(
                                            width: size,
                                            height: size,
                                            child: ClipRect(
                                              child: Align(
                                                alignment: Alignment.center,
                                                child: Scribble(
                                                  notifier: notifier,
                                                  drawPen: true,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SingleChildScrollView(
              child: Stack(
                children: [
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Align(
                      alignment: Alignment.center,
                      child: Builder(
                        builder: (context) {
                          if (_selectedImageWidget != null) {
                            return _selectedImageWidget!;
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Visibility(
                      visible: _selectedImage != null && imageBytes != null,
                      child: imageBytes != null
                          ? Container(
                              width: 400, // Adjust the width as needed
                              height: 392, // Adjust the height as needed
                            )
                          : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Column(
                children: [
                  _buildColorToolbar(context),
                  _buildStrokeToolbar(context),
                ],
              ),
            ),
            if (isLoading) // Add this condition to show the loading indicator
              Positioned(
                  child: LinearProgressIndicator(
                minHeight: 3,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )),

            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween, // Add this line
                children: [
                  ValueListenableBuilder(
                    valueListenable: inputController,
                    builder: (context, value, child) {
                      return FocusScope(
                          child: TextField(
                        focusNode: myFocusNode,
                        controller: _textEditingController,
                        maxLength: 100,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Color.fromARGB(255, 48, 48, 48),
                          labelText: 'Enter text prompt',
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
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.clear,
                                color: Colors.white), // Set icon color to white
                            onPressed: () {
                              _textEditingController.clear();
                            },
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        cursorColor:
                            Colors.white, // Set the cursor color to white
                        onChanged: (query) {
                          setState(() {
                            _query = query;
                          });
                        },
                      ));
                    },
                  ),
                  ElevatedButton(
                    onPressed: _selectedImage != null &&
                            scribbleExists &&
                            _query.isNotEmpty &&
                            !isLoading
                        ? () async {
                            removeFocus();
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
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors.black,
                                          backgroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          Navigator.of(context)
                                              .pop(); // Close the dialog
                                        },
                                        child: Text("Cancel"),
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            if (mounted) {
                              setState(() {
                                _sendButtonPressCount++;
                                print(_sendButtonPressCount);
                              });
                            }

                            // Show ad every 2nd time the button is pressed
                            if (_sendButtonPressCount % 3 == 0) {
                              MobileAds.instance.updateRequestConfiguration(
                                RequestConfiguration(testDeviceIds: [
                                  '7017C9040B0BBB865A301590C55CC6C5'
                                ]),
                              );
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
                                    ad.show();
                                  },
                                  onAdFailedToLoad: (LoadAdError error) {
                                    debugPrint(
                                        'InterstitialAd failed to load: $error');
                                  },
                                ),
                              );
                            }
                            //print(!notifier.currentSketch.lines.isEmpty);
                            if (notifier.currentSketch.lines.isEmpty == true) {
                              Fluttertoast.showToast(
                                  msg: "Draw a mask first",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                              return;
                            } else {
                              Fluttertoast.showToast(
                                  msg: "Image processing",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.CENTER,
                                  timeInSecForIosWeb: 1,
                                  backgroundColor:
                                      const Color.fromARGB(255, 0, 0, 0),
                                  textColor: Colors.white,
                                  fontSize: 16.0);
                            }
                            if (mounted) {
                              setState(() {
                                isLoading = true;
                              });
                            }
                            //print(isLoading);
                            await _saveImage(
                                context); // Wait for saveImage to complete before executing request

                            final directory =
                                await getApplicationDocumentsDirectory();
                            final initImagePath =
                                '${directory.path}/selected_image.jpg';
                            final maskImagePath =
                                '${directory.path}/merged_image.jpg';
                            final url = Uri.parse(
                                'https://inpaint.serverboi.org/image2image?input=${_query}'); // Updated request URL
                            var request = http.MultipartRequest('POST', url);
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                  'init_image', initImagePath),
                            );
                            request.files.add(
                              await http.MultipartFile.fromPath(
                                  'mask_image', maskImagePath),
                            );

                            var response = await request.send();
                            if (response.statusCode == 200) {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                if (mounted) {
                                  isLoading = false;
                                }
                              });
                              // Handle successful response

                              debugPrint('Request succeeded');

                              final responseData =
                                  await response.stream.bytesToString();
                              List<dynamic> images = [];

                              try {
                                final decodedData = json.decode(responseData);
                                images = decodedData['images'] as List<dynamic>;
                              } catch (e) {
                                // Handle the JSON decoding error
                                debugPrint('JSON decoding error: $e');
                                //  We need to Retry the request
                              }

                              if (images.isNotEmpty) {
                                print(_sendButtonPressCount);
                                setState(() {
                                  if (mounted) {
                                    imageBytes =
                                        base64.decode(images[0] as String);
                                    _selectedImageWidget = Container(
                                      width: 400, // Adjust the width as needed
                                      height:
                                          392, // Adjust the height as needed
                                      child: GestureDetector(
                                        onTap: imageBytes != null
                                            ? () {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title:
                                                          Text("Start over?"),
                                                      content: Text(
                                                          "Do you want to start over?"),
                                                      actions: [
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.black,
                                                            backgroundColor: Colors
                                                                .white, // Set the button text color to black
                                                          ),
                                                          child: Text("Cancel"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Close the dialog
                                                            removeFocus();
                                                          },
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.black,
                                                            backgroundColor: Colors
                                                                .white, // Set the button text color to black
                                                          ),
                                                          child: Text("Clear"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Close the dialog
                                                            setState(() {
                                                              _selectedImage =
                                                                  null; // Clear the uploaded image
                                                              _selectedImageWidget =
                                                                  null;
                                                              imageBytes =
                                                                  null; // Clear the returned image
                                                              scribbleExists =
                                                                  false; // Clear the scribble state
                                                              notifier
                                                                  .clear(); // Clear the scribble drawing
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );

                                                removeFocus();
                                              }
                                            : null,
                                        onPanEnd: imageBytes != null
                                            ? (_) {
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      title:
                                                          Text("Start over?"),
                                                      content: Text(
                                                          "Do you want to start over?"),
                                                      actions: [
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.black,
                                                            backgroundColor: Colors
                                                                .white, // Set the button text color to black
                                                          ),
                                                          child: Text("Cancel"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Close the dialog
                                                            removeFocus();
                                                          },
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            foregroundColor:
                                                                Colors.black,
                                                            backgroundColor: Colors
                                                                .white, // Set the button text color to black
                                                          ),
                                                          child: Text("Clear"),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(); // Close the dialog
                                                            setState(() {
                                                              _selectedImage =
                                                                  null; // Clear the uploaded image
                                                              _selectedImageWidget =
                                                                  null;
                                                              imageBytes =
                                                                  null; // Clear the returned image
                                                              scribbleExists =
                                                                  false; // Clear the scribble state
                                                              notifier
                                                                  .clear(); // Clear the scribble drawing
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            : null,
                                        child: imageBytes != null
                                            ? Image.memory(
                                                imageBytes!,
                                                fit: BoxFit.cover,
                                                gaplessPlayback: true,
                                              )
                                            : Container(),
                                      ),
                                    );
                                  }
                                });
                              }
                            } else {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Error: No image returned'),
                                    content: Text(
                                        'Please try again later. This is an unexpected server issue with the image generation network.'),
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
                              setState(() {
                                if (mounted) {
                                  isLoading = false;
                                }
                              });
// Handle error response
                              if (kDebugMode) {
                                debugPrint(
                                    'Request failed with status ${response.statusCode}');
                              }
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor:
                          _selectedImage != null ? Colors.white : Colors.grey,
                    ),
                    child: const Text('Send ➤'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void removeFocus() {
    myFocusNode.unfocus();
  }

  Future<void> _saveImage(BuildContext context) async {
    if (!mounted) return;
    final image = await notifier.renderImage();

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/scribble_image.jpg';

    final file = File(imagePath);
    await file.writeAsBytes(image.buffer.asUint8List());

    if (_selectedImage != null) {
      if (!mounted) return;
      final backgroundImage = img.decodeImage(
        await _selectedImage!.readAsBytes(),
      );
      final scribbleImage = img.decodeImage(image.buffer.asUint8List());

      final mergedImage = img.copyResize(
        scribbleImage!,
        width: backgroundImage!.width,
        height: backgroundImage.height,
      );

      final tempDir = await getApplicationDocumentsDirectory();
      final mergedImagePath = '${tempDir.path}/merged_image.jpg';
      File(mergedImagePath).writeAsBytesSync(img.encodeJpg(mergedImage));

      //final mergedImageFile = File(mergedImagePath);
    }
  }

  void _saveImageToGallery(Uint8List imageBytes) async {
    final directory = await getTemporaryDirectory();
    final imagePath = path.join(directory.path, 'image.png');
    final imageFile = File(imagePath);

    // Write the image bytes to a PNG file
    await imageFile.writeAsBytes(imageBytes, mode: FileMode.write, flush: true);

    GallerySaver.saveImage(imagePath).then((bool? success) {
      if (success != null && success) {
        removeFocus();
        Fluttertoast.showToast(
          msg: "Image saved to gallery",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      } else {
        removeFocus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save image to gallery')),
        );
      }
    });
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final pickedImage = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );

      if (pickedImage != null) {
        if (!mounted) return;
        setState(() {
          removeFocus();
          notifier.clear();
          scribbleExists = false;
          _clearButtonPressCount = 0;
          _selectedImage = null;
          _selectedImageWidget = null;
          imageBytes = null;
        });

        final croppedImage = await ImageCropper().cropImage(
          sourcePath: pickedImage.path,
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
          compressQuality: 100,
          maxHeight: 1920,
          maxWidth: 1080,
        );

        if (croppedImage != null) {
          final decodedImage =
              img.decodeImage(await croppedImage.readAsBytes());
          final resizedImage =
              img.copyResize(decodedImage!, width: 512, height: 512);

          final directory = await getApplicationDocumentsDirectory();
          final imagePath = '${directory.path}/selected_image.jpg';
          final file = File(imagePath);

          // Save the resized image to the file
          await file.writeAsBytes(img.encodeJpg(resizedImage));

          setState(() {
            _selectedImage = XFile(file.path);
            _selectedImageWidget = Image.file(file);
          });

          Fluttertoast.showToast(
            msg: 'Image selected!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.black87,
            textColor: Colors.white,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Image cropping canceled!',
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            timeInSecForIosWeb: 1,
            backgroundColor: Colors.red,
            textColor: Colors.white,
          );
          setState(() {
            _clearButtonPressCount = 0;
          });
        }
      } else {
        Fluttertoast.showToast(
          msg: 'No image selected!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        setState(() {
          _clearButtonPressCount = 0;
        });
      }
    } catch (e) {
      if (e is PlatformException) {
        debugPrint('Platform Exception: $e');
        Fluttertoast.showToast(
          msg: 'Error loading image filetype!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Error loading image!',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
        debugPrint('Error: $e');
      }
    }
  }

  Widget _buildColorToolbar(BuildContext context) {
    return StateNotifierBuilder<ScribbleState>(
      stateNotifier: notifier,
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildUploadButton(context),
          _buildClearButton(context),
          Visibility(
            visible: imageBytes != null,
            child: AbsorbPointer(
              absorbing: imageBytes == null,
              child: Opacity(
                opacity: imageBytes == null
                    ? 0.3
                    : 1.0, // Adjust the opacity value as needed
                child: _buildConfirmButton(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrokeToolbar(BuildContext context) {
    return StateNotifierBuilder<ScribbleState>(
      stateNotifier: notifier,
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  thumbColor: Colors.white, // Set the thumb color to white
                  trackHeight: 8.0, // Adjust the track height as desired
                  activeTrackColor:
                      Colors.white, // Set the active track color to grey
                  inactiveTrackColor: Color.fromARGB(
                      255, 77, 76, 76), // Set the inactive track color to grey
                ),
                child: Slider(
                  value: state.selectedWidth,
                  min: notifier.widths.first,
                  max: notifier.widths.last,
                  onChanged: isLoading
                      ? null
                      : (newValue) {
                          notifier.setStrokeWidth(newValue);
                        },
                ),
              )),
          SizedBox(height: 20), // Add some spacing
          Container(
            width: state.selectedWidth * 1.7,
            height: state.selectedWidth * 1.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 1.5,
              ),
              color: const Color.fromARGB(255, 255, 0, 0),
            ),
          )
        ],
      ),
    );
  }

  Future<void> updateScribbleExists() async {
    if (!notifier.currentSketch.lines.isEmpty) {
      setState(() {
        if (mounted) {
          removeFocus();
          scribbleExists = !notifier.currentSketch.lines.isEmpty;
        }
      });
    }
  }

  int _clearButtonPressCount = 0;
  bool scribbleExists = false;

  Widget _buildClearButton(BuildContext context) {
    //print(!notifier.currentSketch.lines.isEmpty);

    return FloatingActionButton.small(
      heroTag: "btn1",
      tooltip: "Clear",
      onPressed: isLoading
          ? null
          : () {
              //print(_clearButtonPressCount);
              if (_clearButtonPressCount == 0 ||
                  (_clearButtonPressCount == 1 && _selectedImage == null)) {
                // Clear the scribble drawing on the first press if no image is selected
                notifier.clear();
                setState(() {
                  if (mounted) {
                    scribbleExists = false;
                    _clearButtonPressCount = 0;
                  }
                });
              } else if (_clearButtonPressCount == 1) {
                setState(() {
                  if (mounted) {
                    _selectedImage = null; // Clear the uploaded image
                    _selectedImageWidget = null;
                    imageBytes = null; // Clear the returned image
                    scribbleExists = false; // Clear the scribble state
                  }
                });
              }
              _clearButtonPressCount++;
              if (_clearButtonPressCount > 1) {
                _clearButtonPressCount =
                    0; // Reset the press count after the second press
              } else {
                if (_selectedImage != null) {
                  Fluttertoast.showToast(
                    msg: "Press twice to start over",
                    toastLength: Toast.LENGTH_SHORT,
                    gravity: ToastGravity.CENTER,
                    timeInSecForIosWeb: 1,
                    textColor: Colors.white,
                    fontSize: 16.0,
                  );
                }
                // Delay the reset logic by 2 seconds
                Future.delayed(const Duration(seconds: 2), () {
                  if (_clearButtonPressCount < 2) {
                    if (!mounted) return;
                    setState(() {
                      if (mounted) {
                        _clearButtonPressCount = 0;
                      }
                    });
                  }
                });
              }
            },
      disabledElevation: 0,
      backgroundColor: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
      child: const Icon(Icons.clear),
    );
  }

  Widget _buildConfirmButton(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: "btn2",
      tooltip: "Save to gallery",
      onPressed: isLoading || imageBytes == null
          ? null
          : () {
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
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: _selectedImage != null
                            ? () {
                                _saveImageToGallery(imageBytes!);
                                Navigator.of(context).pop(); // Close the dialog
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                        child: Text("Save"),
                      )
                    ],
                  );
                },
              );
            },
      disabledElevation: 0,
      backgroundColor: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
      child: const Icon(Icons.download_rounded),
    );
  }

  Widget _buildUploadButton(BuildContext context) {
    //print(!notifier.currentSketch.lines.isEmpty);
    return FloatingActionButton.small(
      heroTag: "btn3",
      tooltip: "Upload",
      onPressed: isLoading
          ? null
          : () {
              _pickImageFromGallery();
            },
      disabledElevation: 0,
      backgroundColor: isLoading ? Colors.grey.withOpacity(0.5) : Colors.white,
      child: const Icon(Icons.image_rounded),
    );
  }
}
