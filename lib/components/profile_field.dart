
//components/profile_field.dart
import 'package:flutter/material.dart';

class ProfileText extends StatelessWidget {


  const ProfileText({
    Key? key,

  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(

        decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            fillColor: Colors.black,
            filled: true,
        ),
      ),
    );
  }
}
