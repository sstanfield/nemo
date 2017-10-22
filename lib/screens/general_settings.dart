import 'package:flutter/material.dart';
import '../deco/plan.dart';

class GeneralSettings extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;

  GeneralSettings({Key key, this.appBar, this.dive}): super(key: key);

  @override
  _GeneralSettingsState createState() => new _GeneralSettingsState(appBar, dive);
}

class _GeneralSettingsState extends State<GeneralSettings> {
  final AppBar _appBar;
  //final BottomNavigationBar _botNavBar;
  final Dive _dive;
  final TextEditingController _gfLo;
  final TextEditingController _gfHi;
  final TextEditingController _atmPressure;

  _GeneralSettingsState(this._appBar, this._dive):
        _gfLo = new TextEditingController(text: "${(_dive.gfLo*100).round()}"),
        _gfHi = new TextEditingController(text: "${(_dive.gfHi*100).round()}"),
        _atmPressure = new TextEditingController(text: "${_dive.atmPressure}");

  @override
  Widget build(BuildContext context) {
    Column c3 = new Column(children: [
      new TextField(controller: _gfLo, decoration: new InputDecoration(labelText:  "gfLo:"), keyboardType: TextInputType.number),
      new TextField(controller: _gfHi, decoration: new InputDecoration(labelText:  "gfHi:"), keyboardType: TextInputType.number),
      new TextField(controller: _atmPressure, decoration: new InputDecoration(labelText:  "ATM Pressure:"), keyboardType: TextInputType.number),
      new FlatButton(
        child: const Text('Save'),
        onPressed: () {
          double lo = .5;
          double hi = .8;
          int atm = 1013;
          try { lo = (int.parse(_gfLo.text)/100.0); } catch (ignored) {}
          try { hi = (int.parse(_gfHi.text)/100.0); } catch (ignored) {}
          try { atm = int.parse(_atmPressure.text); } catch (ignored) {}
          _dive.setGradients(lo, hi);
          _dive.atmPressure = atm;
          Navigator.of(context).pop();
        },
      ),
    ]);
    return new Scaffold(
      appBar: _appBar,
      body: c3,
      //bottomNavigationBar: _botNavBar,
      //floatingActionButton: _floatingActionButton,
    );
  }
}
