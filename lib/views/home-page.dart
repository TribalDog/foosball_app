import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:nfc_manager/nfc_manager.dart';

class HomePage extends StatefulWidget {
  HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _sideId = '';

  void _scan() async {
    String sideId = '';
    setState(() {
      _sideId = sideId;
    });

    bool isAvailable = await NfcManager.instance.isAvailable();

    if (isAvailable) {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            print('Tag is not compatible with NDEF');
            return;
          }

          NdefMessage ndefMessage = await ndef.read();
          ndefMessage.records.forEach((record) {
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown) {
              var rawSideId = utf8.decode(record.payload);

              if (rawSideId.contains('SideA')) {
                sideId = 'Red';
              }
              if (rawSideId.contains('SideB')) {
                sideId = 'Blue';
              }
            }
          });

          setState(() {
            _sideId = sideId;
          });

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
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scan,
        tooltip: 'Scan',
        child: Icon(Icons.add),
      ),
    );
  }
}
