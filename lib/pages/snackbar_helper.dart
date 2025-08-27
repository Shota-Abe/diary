import 'package:flutter/material.dart';

void showAppSnackBar(BuildContext context, int Achivegoals){
  if(Achivegoals!=0){
    final snackBar = SnackBar(
      content: Text.rich(
        TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: Achivegoals.toString(),
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                )
            ),
            TextSpan(
              text: '個の目標を達成しました！',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16,
              )
            )
          ]
        )
      ),
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}