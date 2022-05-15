import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:receive_intent/receive_intent.dart' as AndroidIntent;

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _sideId = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final receivedIntent = await AndroidIntent.ReceiveIntent.getInitialIntent();

    if (!mounted) return;

    if (receivedIntent!.data != null) {
      _setSideState(receivedIntent.data);
    }
  }

  void _setSideState(String? uri) {
    String sideId = '';

    if ((uri != null) && (uri.contains('red'))) {
      sideId = 'Red';
    }
    if ((uri != null) && (uri.contains('blue'))) {
      sideId = 'Blue';
    }

    setState(() {
      _sideId = sideId;
    });
  }

  void _scan() async {
    String sideId = '';
    setState(() {
      _sideId = sideId;
      _errorMessage = '';
    });

    bool isAvailable = await NfcManager.instance.isAvailable();

    if (isAvailable) {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            setState(() {
              _errorMessage = 'This is not a valid Foosball side tag.';
            });
            return;
          }

          bool found = false;
          NdefMessage ndefMessage = await ndef.read();
          ndefMessage.records.forEach((record) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
              found = true;
              _setSideState(utf8.decode(record.payload));
            }
          });

          if (!found) {
            setState(() {
              _errorMessage = 'This is an unknown Foosball side tag.';
            });
          }

          await Future.delayed(const Duration(seconds: 2), () {
            NfcManager.instance.stopSession();
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Playing for side...',
            ),
            Text(
              '$_sideId',
              style: TextStyle (
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: (_sideId == 'Red') ? Colors.red:Colors.blue
              ),
            ),
            SizedBox(
              height: 48,
            ),
            Text(
             '$_errorMessage',
              style: TextStyle (
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scan,
        tooltip: 'Re-Scan',
        child: Icon(Icons.nfc),
      ),
    );
  }
}
