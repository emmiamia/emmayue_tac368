import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/word_list.dart';
import 'data/word_repository.dart';
import 'locale/locale_cubit.dart';
import 'services/sound_service.dart';
import 'services/storage_service.dart';
import 'theme/theme_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageService(prefs);
  final wordList = WordList();
  await wordList.load();
  final repository = WordRepository(wordList: wordList);
  final sounds = SoundService();
  await sounds.init();

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit(prefs)),
        BlocProvider(create: (_) => LocaleCubit(prefs)),
      ],
      child: WordleApp(
        storageService: storage,
        wordList: wordList,
        wordRepository: repository,
        soundService: sounds,
      ),
    ),
  );
}
