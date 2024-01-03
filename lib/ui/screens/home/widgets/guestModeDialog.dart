import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutterquiz/app/appLocalization.dart';


class guestModeDialog extends StatelessWidget {
  final Function onTapYesButton;
  final Function? onTapNoButton;
  const guestModeDialog({Key? key, required this.onTapYesButton, this.onTapNoButton}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: Text(
          AppLocalization.of(context)!.getTranslatedValues("guestMode")!,
        ),
        actions: [
          CupertinoButton(
            onPressed: () {
              onTapYesButton();
              //Navigator.pop(context);
            },
            child: Text(
              AppLocalization.of(context)!.getTranslatedValues("loginLbl")!,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
          CupertinoButton(
            onPressed: () {
              if (onTapNoButton != null) {
                onTapNoButton!();
                return;
              }
              Navigator.pop(context);
            },
            child: Text(
              AppLocalization.of(context)!.getTranslatedValues("cancel")!,
              style: TextStyle(color: Theme.of(context).primaryColor),
            ),
          ),
        ]);
  }
}
