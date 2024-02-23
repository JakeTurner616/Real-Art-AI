import 'dart:convert';
import 'package:http/http.dart';
import 'post_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

bool includePrompt0 = false;
bool includePrompt1 = false;
bool includePrompt2 = false;
bool includePrompt3 = false;
bool includePrompt4 = false;
String seedParam = "";
String seedParam1 = "";

class HttpService {
  String selectedOption = 'Euler a';
  String seedParam = "";
  int steps = 50;
  int steps1 = 50;
  final String baseURL = "https://sdapi.serverboi.org/text";

  Future<List<Post>> getPosts(String query) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile) {
      // I am connected to a mobile network.
    } else if (connectivityResult == ConnectivityResult.wifi) {
      // I am connected to a wifi network.
    } else if (connectivityResult == ConnectivityResult.none) {
      //force a page nav
      return [];
    }
    if (query.isEmpty) {
      return [];
    }

    try {
      String prompt = query;
      if (includePrompt0) {
        prompt = "SFW, modelshoot style, safe for work, detailed face, $prompt";
      }
      if (includePrompt1) {
        prompt = "SFW, In the style of a masterpeice painting, $prompt";
      }
      if (includePrompt2) {
        prompt = "SFW, Anime style, $prompt";
      }
      if (includePrompt3) {
        prompt = "SFW, Crazy vibrant colors, Psychedelic expression, $prompt";
      }
      if (includePrompt4) {
        prompt =
            "SFW, Beautiful highly detailed, sharp focus, futuristic vaporwave and cyberpunk style, $prompt";
      }

      String apiUrl = "$baseURL?input=%22$prompt%22";

      if (seedParam.isNotEmpty) {
        apiUrl += "&seed=$seedParam";
      }

      apiUrl += "&steps=$steps";

      apiUrl += "&sampler=$selectedOption";
      Response res = await get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        Map<String, dynamic> body = jsonDecode(res.body);

        List<Post> posts = body.entries
            .map(
                (MapEntry<String, dynamic> entry) => Post.fromJson(entry.value))
            .toList();
        if (posts.isEmpty) {
          // handle the case where the list is empty
          return [];
        }
        return posts;
      } else {
        print('Request failed with status: $res.');
      }
      if (res.statusCode == 502) {
        print('Error 502: Bad Gateway. Please try again later.');
        return []; //set condition to return empty list instead of throwing error
      }
      if (res.statusCode == 500) {
        print('Error 500: Internal error. Please try again later.');
        return []; //set condition to return empty list instead of throwing error
      } else {
        return []; //set condition to return empty list instead of throwing error
      }
    } on FormatException catch (e) {
      print('Exception has occurred.\n$e');
      return [];
    } on SocketException catch (e) {
      print('Error connecting to server: $e');
      return []; // or handle the error in some other way
    } on HttpException catch (e) {
      print('Error: $e');
      return []; // or handle the error in some other way
    } catch (e) {
      print('Error: $e');
      return []; // or handle the error in some other way
    }
  }

  Future<List<Post>> getPostsimg2img(
      String query,
      String imageBase64,
      double denoisingStrength,
      int steps,
      String selectedOption,
      String seedParam) async {
    if (query.isEmpty) {
      return [];
    }

    if (seedParam.isEmpty) {
      seedParam = "-1";
    }

    Map<String, dynamic> requestBody = {
      "init_images": ["$imageBase64"],
      "prompt": "$query",
      "negative_prompt":
          "NSFW, ugly, bad quality, error, blurr, poorly Rendered face, poorly drawn face, poor facial details, imperfect anatomy, text, typography",
      "sd_model_checkpoint":
          "realisticVisionV51_v51VAE.safetensors [15012c538f]",
      "seed": seedParam,
      "cfg_scale": 7,
      "sampler_index": selectedOption,
      "sampler": selectedOption,
      "steps": steps,
      "denoising_strength": denoisingStrength,
      "mask_blur": 4,
      "inpainting_fill": 0,
      "batch_size": 1,
      "inpaint_full_res": true,
      "inpaint_full_res_padding": 0,
      "inpainting_mask_invert": 0,
      "width": 512,
      "height": 512,
      "n_iter": 1,
      "include_init_images": true,
    };
    final uri = Uri.parse('https://ai.serverboi.org/sdapi/v1/img2img');

    // Set the Content-Type header to application/json
    var headers = {"Content-Type": "application/json"};
    // Send the request body as a RAW JSON string
    try {
      Response res =
          await post(uri, headers: headers, body: jsonEncode(requestBody));
      print(res.body);
      print(res.statusCode);
      if (res.statusCode == 502) {
        print('Error 502: Bad Gateway. Please try again later.');
        return []; //set condition to return empty list instead of throwing error
      } else {
        Map<String, dynamic> body = jsonDecode(res.body);
        List<dynamic> images = body['images'];
        List<Post> posts = images.map((image) => Post.fromJson(image)).toList();
        if (posts.isEmpty) {
          // handle the case where the list is empty
          return [];
        }
        // do something with the posts
        return posts;
      }
    } catch (e) {
      print('Error: $e');
      return []; // or handle the error in some other way
    }
  }

  getRequest(String s) {}
}
