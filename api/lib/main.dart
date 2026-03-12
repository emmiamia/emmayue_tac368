import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const YosemiteApp());
}

class YosemiteApp extends StatelessWidget {
  const YosemiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'National Parks Info',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const ParkHomePage(),
    );
  }
}

class ParkHomePage extends StatefulWidget {
  const ParkHomePage({super.key});

  @override
  State<ParkHomePage> createState() => _ParkHomePageState();
}

class _ParkHomePageState extends State<ParkHomePage> {
  bool isLoading = false;
  String errorMessage = '';
  ParkModel? park;

  // Replace with your own API key
  static const String apiKey = 'bWX9diErXRopUZTEpyVxu6W4jhJmpK4l7HpfEelQ';

  // Park name -> park code
  final Map<String, String> parks = {
    'Yosemite National Park': 'yose',
    'Yellowstone National Park': 'yell',
    'Grand Canyon National Park': 'grca',
    'Zion National Park': 'zion',
    'Bryce Canyon National Park': 'brca',
    'Rocky Mountain National Park': 'romo',
    'Sequoia National Park': 'seki',
    'Joshua Tree National Park': 'jotr',
    'Olympic National Park': 'olym',
    'Acadia National Park': 'acad',
  };

  String? selectedParkName = 'Yosemite National Park';

  Future<void> fetchPark() async {
    if (selectedParkName == null) {
      setState(() {
        errorMessage = 'Please select a park.';
        park = null;
      });
      return;
    }

    final String code = parks[selectedParkName]!;

    setState(() {
      isLoading = true;
      errorMessage = '';
      park = null;
    });

    try {
      final Uri url = Uri.parse(
        'https://developer.nps.gov/api/v1/parks?parkCode=$code&fields=images&api_key=$apiKey',
      );

      final response = await http.get(url);

      if (response.statusCode != 200) {
        setState(() {
          errorMessage = 'Request failed: ${response.statusCode}';
          isLoading = false;
        });
        return;
      }

      final Map<String, dynamic> data = jsonDecode(response.body);

      if (data['data'] == null ||
          data['data'] is! List ||
          (data['data'] as List).isEmpty) {
        setState(() {
          errorMessage = 'No park information found.';
          isLoading = false;
        });
        return;
      }

      final ParkModel loadedPark = ParkModel.fromJson(data['data'][0]);

      setState(() {
        park = loadedPark;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Widget buildParkCard(ParkModel park) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              park.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (park.imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  park.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey.shade300,
                      alignment: Alignment.center,
                      child: const Text('Could not load image'),
                    );
                  },
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Text('No image available'),
              ),

            const SizedBox(height: 16),
            Text(
              'Park Code: ${park.parkCode}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Entrance Fee: ${park.entranceFee}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Website: ${park.url}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),

            const Text(
              'Description:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              park.description,
              style: const TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> parkNames = parks.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('National Parks API App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Choose a national park from the dropdown and load its information.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: selectedParkName,
              decoration: const InputDecoration(
                labelText: 'Select a Park',
                border: OutlineInputBorder(),
              ),
              items: parkNames.map((String parkName) {
                return DropdownMenuItem<String>(
                  value: parkName,
                  child: Text(parkName),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  selectedParkName = newValue;
                });
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : fetchPark,
                child: const Text('Load Park Info'),
              ),
            ),

            const SizedBox(height: 20),

            if (isLoading) const CircularProgressIndicator(),

            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),

            if (park != null) buildParkCard(park!),
          ],
        ),
      ),
    );
  }
}

class ParkModel {
  final String name;
  final String description;
  final String imageUrl;
  final String entranceFee;
  final String parkCode;
  final String url;

  ParkModel({
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.entranceFee,
    required this.parkCode,
    required this.url,
  });

  factory ParkModel.fromJson(Map<String, dynamic> json) {
    String image = '';
    if (json['images'] != null &&
        json['images'] is List &&
        (json['images'] as List).isNotEmpty) {
      image = json['images'][0]['url'] ?? '';
    }

    String fee = 'No fee information available';
    if (json['entranceFees'] != null &&
        json['entranceFees'] is List &&
        (json['entranceFees'] as List).isNotEmpty) {
      fee = '\$${json['entranceFees'][0]['cost'] ?? 'N/A'}';
    }

    return ParkModel(
      name: json['fullName'] ?? 'Unknown Park',
      description: json['description'] ?? 'No description available.',
      imageUrl: image,
      entranceFee: fee,
      parkCode: json['parkCode'] ?? '',
      url: json['url'] ?? '',
    );
  }
}