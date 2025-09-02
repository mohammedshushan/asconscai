import 'package:asconscai/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
 // Assuming your localizations file path

class NetworkChecker {
  static Future<bool> isConnected() async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.mobile || connectivityResult == ConnectivityResult.wifi) {
      return true;
    }
    return false;
  }

  static void showNoInternetDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(localizations.translate('no_internet_connection') ?? 'No Internet Connection'),
        content: Text(localizations.translate('check_your_internet') ?? 'Please check your internet connection and try again.'),
        actions: <Widget>[
          TextButton(
            child: Text(localizations.translate('ok') ?? 'OK'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          )
        ],
      ),
    );
  }
}