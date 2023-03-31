import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoaderState extends StatelessWidget {
  const LoaderState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 20,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Color(0XFF0000FFFF),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Center(
          child: SpinKitPouringHourGlass(
            color: Colors.teal,
            size: 80.0,
          ),
        ),
      ),
    );
  }
}
