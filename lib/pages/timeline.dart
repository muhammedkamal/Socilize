import 'package:flutter/material.dart';
import 'package:socialize/widgets/header.dart';
import 'package:socialize/widgets/progress.dart';

class Timeline extends StatefulWidget {
  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context,isTimeLine: true),
      body: linearProgress(),
    );
  }
}
