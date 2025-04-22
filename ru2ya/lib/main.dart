import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' ;
import 'package:ru2ya/Start.dart';

void main() {
  runApp( ProviderScope(child: MyApp()));}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context)
  {
    return  MaterialApp(
        debugShowCheckedModeBanner:false,
        theme: ThemeData(fontFamily: 'Inter'),
        home: Start()
    );
  }
}


