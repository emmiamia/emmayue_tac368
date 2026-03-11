import 'package:flutter/material.dart';

class BB extends Container
{
  BB( String s ) : super
  ( decoration: BoxDecoration
    ( border: Border.all(width:2),),
    width:200, height:60,
    child: Text(s, style: const TextStyle(fontSize: 20) ),
  );
}