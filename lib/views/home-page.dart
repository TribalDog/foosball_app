import 'dart:convert';
import 'dart:io';

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
  bool _isScanning = false;
  String _sideId = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    if (!mounted) return;

    if (Platform.isAndroid) {
      final receivedIntent = await AndroidIntent.ReceiveIntent
          .getInitialIntent();

      if (receivedIntent!.data != null) {
        _setSideState(receivedIntent.data);
      }
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
      _isScanning = true;
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
              _isScanning = false;
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

          if (found) {
            setState(() {
              _errorMessage = '';
              _isScanning = false;
            });
          } else {
            setState(() {
              _errorMessage = 'This is an unknown Foosball side tag.';
              _isScanning = false;
            });
          }

          await Future.delayed(const Duration(seconds: 2), () {
            NfcManager.instance.stopSession();
            setState(() {
              _isScanning = false;
            });
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
            SizedBox(
              height: 24,
            ),
            _isScanning ? CircularProgressIndicator(
              semanticsLabel: 'Scanning',
            ):Container(),
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
