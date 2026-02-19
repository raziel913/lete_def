import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lete_sgam/pages/home.dart';
// import 'package:intl/date_symbol_data_local.dart';
import 'package:lete_sgam/global.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  await Globals.initializeGlobals();

  runApp(
    MaterialApp(
         theme: ThemeData(
        // Definire i colori principali e di sfondo
        appBarTheme: AppBarTheme(backgroundColor: Color.fromARGB(255, 187, 167, 167)),
        buttonTheme: ButtonThemeData(buttonColor:Color(0xFFFE5F00), disabledColor: const Color.fromARGB(255, 179, 26, 26), ),
        primaryColor: Color.fromARGB(255, 226, 33, 31),
        colorScheme: ColorScheme.fromSeed(seedColor: Color.fromARGB(255, 35, 35, 92),
        primary: Color(0xFFFE5F00),
        secondary: Color.fromARGB(255, 219, 203, 203),
        ),

        scaffoldBackgroundColor: Color.fromARGB(255, 255, 255, 255),
        
        // Definire il font globale
        fontFamily: 'Roboto',
        floatingActionButtonTheme: FloatingActionButtonThemeData(
           backgroundColor: Color(0xFFFE5F00), // Colore di sfondo del FloatingActionButton
    foregroundColor: Colors.white,  
        )
    
        ),
      home: Home(),
    ),
  );
}
