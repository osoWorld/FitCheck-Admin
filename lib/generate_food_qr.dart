import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'foodmodel.dart';

class GenerateFoodQR extends StatefulWidget {
  @override
  _GenerateFoodQRState createState() => _GenerateFoodQRState();
}

class _GenerateFoodQRState extends State<GenerateFoodQR> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController linkController = TextEditingController();
  final TextEditingController caloriesController = TextEditingController();
  final TextEditingController fatsController = TextEditingController();
  final TextEditingController proteinsController = TextEditingController();
  final TextEditingController carbsController = TextEditingController();
  final TextEditingController ingredientsSodiumController = TextEditingController();
  final TextEditingController ingredientsSugarController = TextEditingController();
  final TextEditingController ingredientsCholesterolController = TextEditingController();
  final TextEditingController ratingController = TextEditingController();

  final ScreenshotController screenshotController = ScreenshotController();

  Future<void> _saveQRCodeImage() async {

    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // Request appropriate permissions
    if (await Permission.storage.isDenied ||
        (await Permission.manageExternalStorage.isDenied &&
            androidInfo.version.sdkInt >= 30)) {
      final status = await Permission.storage.request();
      final manageStatus = androidInfo.version.sdkInt >= 30
          ? await Permission.manageExternalStorage.request()
          : PermissionStatus.granted;

      if (!status.isGranted || manageStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permissions are required.')),
        );
        return;
      }
    }

    try {
      final imageBytes = await screenshotController.capture();
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to capture QR code image.')),
        );
        return;
      }

      if (androidInfo.version.sdkInt < 30) {
        // Save using photo_manager for pre-Android 11 devices
        final result = await PhotoManager.editor.saveImage(
          imageBytes,
          title: 'QR_Image',
          filename: 'MQR_${DateTime.now().toIso8601String()}',
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code saved to gallery!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save QR Code.')),
          );
        }
      } else {
        // Use MediaStore for Android 11+
        final directory = await getExternalStorageDirectory();
        final filePath = '${directory!.path}/MQR_${DateTime.now().toIso8601String()}.png';
        final file = File(filePath);
        await file.writeAsBytes(imageBytes);

        // Add the file to the Media Store
        final result = await PhotoManager.editor.saveImage(
          imageBytes,
          title: 'QR_Image',
          filename: 'MQR_${DateTime.now().toIso8601String()}',
        );

        if (result != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR Code saved to gallery!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to save QR Code to gallery.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR Code: $e')),
      );
    }
  }

  void _saveFoodDetails() async {
    if (nameController.text.isEmpty ||
        linkController.text.isEmpty ||
        caloriesController.text.isEmpty ||
        fatsController.text.isEmpty ||
        proteinsController.text.isEmpty ||
        carbsController.text.isEmpty ||
        ingredientsSodiumController.text.isEmpty ||
        ingredientsSugarController.text.isEmpty ||
        ingredientsCholesterolController.text.isEmpty ||
    ratingController.text.isEmpty
    ) {
      const SnackBar(content: Text("Please fill in all details", style: TextStyle(fontSize: 16.0, color: Colors.black),), backgroundColor: Colors.redAccent,);
    } else {
      Food food = Food(
        name: nameController.text,
        calories: caloriesController.text,
        fats: fatsController.text,
        proteins: proteinsController.text,
        carbs: carbsController.text,
        imageUrl: linkController.text,
        sodium: ingredientsSodiumController.text,  // Added sodium
        sugar: ingredientsSugarController.text,    // Added sugar
        cholesterol: ingredientsCholesterolController.text,  // Added cholesterol
        rating: ratingController.text
      );

      _showQRDialog(food);
    }
  }

  void _showQRDialog(Food food) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Food Details QR Code', style: TextStyle(fontFamily: 'Poppins')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Screenshot(
                controller: screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: PrettyQr(
                    data: food.toJsonString(),  // Generates QR code from the food details
                    size: 200.0,
                    errorCorrectLevel: QrErrorCorrectLevel.M,
                    roundEdges: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Image.network(
                food.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Text('Name: ${food.name}', style:  const TextStyle(fontWeight: FontWeight.bold)),
              Text('Fats: ${food.fats}'),
              Text('Calories: ${food.calories}'),
              Text('Sodium: ${food.sodium}'),
              Text('Sugar: ${food.sugar}'),
              Text('Cholesterol: ${food.cholesterol}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>  _saveQRCodeImage(),
              child: const Text('Save'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: screenWidth * 0.08),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: screenWidth * 0.08,
                            backgroundColor: Colors.black12,
                            child: const Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: Colors.black,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'Food Details',
                            style: TextStyle(
                              fontSize: 29,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          Spacer(flex: 3),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    buildTextField(
                      controller: linkController,
                      hintText: 'Link',
                      icon: Icons.link,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(height: screenHeight * 0.02),

                    // Form Fields
                    buildTextField(
                      controller: nameController,
                      hintText: 'Food Name',
                      icon: Icons.fastfood,
                      screenWidth: screenWidth,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: caloriesController,
                      hintText: 'Calories (kcal)',
                      icon: Icons.local_fire_department,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: fatsController,
                      hintText: 'Fats (g)',
                      icon: Icons.opacity,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: proteinsController,
                      hintText: 'Proteins (g)',
                      icon: Icons.fitness_center,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: carbsController,
                      hintText: 'Carbohydrates (g)',
                      icon: Icons.rice_bowl,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: ingredientsSodiumController,
                      hintText: 'Sodium (mg)',
                      icon: Icons.kitchen,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: ingredientsSugarController,
                      hintText: 'Sugar (g)',
                      icon: Icons.spa,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: ingredientsCholesterolController,
                      hintText: 'Cholesterol (mg)',
                      icon: Icons.fastfood_sharp,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    buildTextField(
                      controller: ratingController,
                      hintText: 'Rating (A - E)',
                      icon: Icons.star,
                      screenWidth: screenWidth,
                      keyboardType: TextInputType.text,
                    ),
                    SizedBox(height: screenHeight * 0.02),

                  ],
                ),
              ),
            ),
          ),

          // Bottom Save Button
          Padding(
            padding: EdgeInsets.only(top: 20, bottom: screenHeight * 0.04, right: 15, left: 15),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(30),
              ),
              child: InkWell(
                onTap: _saveFoodDetails,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: screenWidth * 0.04),
                      child: const Text(
                        'Save Food Details',
                        style: TextStyle(fontSize: 17, color: Colors.white, fontFamily: 'Poppins'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.03),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required double screenWidth,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 20, fontFamily: 'Poppins'),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.grey[200],
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.green, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.green, width: 1),
        ),
        prefixIcon: Icon(icon, color: Colors.green),
        hintText: hintText,
        hintStyle: const TextStyle(color: Colors.grey),
      ),
    );
  }
}