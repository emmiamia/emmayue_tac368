// api key c192f3823c604341a3152947261103
// Emma Yue

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;


import 'bb.dart';

void main()
{
  runApp(const WeatherApi());
}

class WeatherState
{
  String zipCode;
  String tempC;
  String windKph;
  String message;
  bool loading;

  WeatherState({
    required this.zipCode,
    required this.tempC,
    required this.windKph,
    required this.message,
    required this.loading,
  });

  WeatherState copyWith({
    String? zipCode,
    String? tempC,
    String? windKph,
    String? message,
    bool? loading,
  })
  {
    return WeatherState(
      zipCode: zipCode ?? this.zipCode,
      tempC: tempC ?? this.tempC,
      windKph: windKph ?? this.windKph,
      message: message ?? this.message,
      loading: loading ?? this.loading,
    );
  }
}

class WeatherCubit extends Cubit<WeatherState>
{
  WeatherCubit()
      : super(
          WeatherState(
            zipCode: "90802",
            tempC: "--",
            windKph: "--",
            message: "Enter a ZIP code and press the button",
            loading: false,
          ),
        );

  void updateZip(String z)
  {
    emit(state.copyWith(zipCode: z));
  }

  Future<void> fetchWeather() async
  {
    if (state.zipCode.trim().isEmpty)
    {
      emit(
        state.copyWith(
          message: "Please enter a ZIP code",
          tempC: "--",
          windKph: "--",
          loading: false,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        loading: true,
        message: "Loading...",
      ),
    );

    try
    {
      final url = Uri.parse(
        'http://api.weatherapi.com/v1/current.json'
        '?key=c192f3823c604341a3152947261103&q=${state.zipCode}&aqi=no',      
      );

      final response = await http.get(url);

      if (response.statusCode != 200)
      {
        emit(
          state.copyWith(
            loading: false,
            message: "Network error: ${response.statusCode}",
            tempC: "--",
            windKph: "--",
          ),
        );
        return;
      }

      Map<String, dynamic> dataAsMap = jsonDecode(response.body);
      print("Let's see what the weather thingy sent us ...");
      print(dataAsMap);

      if (dataAsMap['error'] != null)
      {
        emit(
          state.copyWith(
            loading: false,
            message: "Invalid ZIP code or API error",
            tempC: "--",
            windKph: "--",
          ),
        );
        return;
      }

      Map<String, dynamic> currentPart = dataAsMap['current'];

      double tempC = currentPart['temp_c'];
      double windKph = currentPart['wind_kph'];

      emit(
        state.copyWith(
          tempC: tempC.toString(),
          windKph: windKph.toString(),
          message: "Weather loaded",
          loading: false,
        ),
      );
    }
    catch (e)
    {
      emit(
        state.copyWith(
          loading: false,
          message: "Error: $e",
          tempC: "--",
          windKph: "--",
        ),
      );
    }
  }
}


class WeatherApi extends StatelessWidget
{
  const WeatherApi({super.key});

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: "weather demo",
      home: Scaffold(
        appBar: AppBar(title: const Text("weather demo")),
        body: const Row(
          children: [
            Weather1(),
          ],
        ),
      ),
    );
  }
}

class Weather1 extends StatelessWidget
{
  const Weather1({super.key});

  @override
  Widget build(BuildContext context)
  {
    final TextEditingController zipController = TextEditingController();

    return BlocProvider<WeatherCubit>(
      create: (context) => WeatherCubit(),
      child: BlocBuilder<WeatherCubit, WeatherState>(
        builder: (context, state)
        {
          return Builder(
            builder: (context)
            {
              WeatherCubit wc = BlocProvider.of<WeatherCubit>(context);

              zipController.text = state.zipCode;
              zipController.selection = TextSelection.fromPosition(
                TextPosition(offset: zipController.text.length),
              );

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        BB("ZIP code: "),
                        const SizedBox(width: 10),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: zipController,
                            keyboardType: TextInputType.number,
                            onChanged: (value)
                            {
                              wc.updateZip(value);
                            },
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    ElevatedButton(
                      onPressed: state.loading
                          ? null
                          : () async
                            {
                              await wc.fetchWeather();
                            },
                      child: BB("get weather"),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        BB("temp C: "),
                        const SizedBox(width: 10),
                        BB(state.tempC),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        BB("wind kph: "),
                        const SizedBox(width: 10),
                        BB(state.windKph),
                      ],
                    ),

                    const SizedBox(height: 20),

                    BB(state.message),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}