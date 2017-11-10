import 'package:flutter/material.dart';
import '../deco/plan.dart';

class GeneralSettings extends StatefulWidget {
  final AppBar appBar;
  final Dive dive;

  GeneralSettings({Key key, this.appBar, this.dive}) : super(key: key);

  @override
  _GeneralSettingsState createState() =>
      new _GeneralSettingsState(appBar, dive);
}

class _GeneralSettingsState extends State<GeneralSettings> {
  final AppBar _appBar;
  final Dive _dive;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

  _GeneralSettingsState(this._appBar, this._dive);

  void showInSnackBar(String value) {
    _scaffoldKey.currentState
        .showSnackBar(new SnackBar(content: new Text(value)));
  }

  void _handleSubmitted() {
    final FormState form = _formKey.currentState;
    if (!form.validate()) {
      //_autovalidate = true;  // Start validating on every change.
      showInSnackBar('Please fix the errors in red before submitting.');
    } else {
      form.save();
      Navigator.of(context).pop();
    }
  }

  String _validateGf(String gf) {
    int igf = -1;
    try {
      igf = int.parse(gf);
    } catch (ignored) {}
    if (igf < 0 || igf > 100) return "Enter gradiant factor 0-100";
    return null;
  }

  String _validateAtm(String atm) {
    int iatm = -1;
    try {
      iatm = int.parse(atm);
    } catch (ignored) {}
    if (iatm < 500 || iatm > 3000)
      return "Enter surface pressure in mbar (500-3000)";
    return null;
  }

  String _validateRate(String rate) {
    int irate = -1;
    try {
      irate = int.parse(rate);
    } catch (ignored) {}
    if (irate < 1 || irate > 300) return "Enter M/min (1-300)";
    return null;
  }

  String _validateSurfaceInterval(String rate) {
    int irate = -1;
    try {
      irate = int.parse(rate);
    } catch (ignored) {}
    if (irate < 0 || irate > 14400) return "Enter Surface Interval Minutes (0-14,400 (10 days))";
    return null;
  }

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(children: [
      new TextFormField(
          initialValue: "${_dive.gfLo}",
          onSaved: (String val) => _dive.gfLo = int.parse(val),
          validator: _validateGf,
          decoration: new InputDecoration(labelText: "gfLo:"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "${_dive.gfHi}",
          onSaved: (String val) => _dive.gfHi = int.parse(val),
          validator: _validateGf,
          decoration: new InputDecoration(labelText: "gfHi:"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "${_dive.atmPressure}",
          onSaved: (String val) => _dive.atmPressure = int.parse(val),
          validator: _validateAtm,
          decoration: new InputDecoration(labelText: "ATM Pressure:"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "${_dive.descentRate}",
          onSaved: (String val) => _dive.descentRate = int.parse(val),
          validator: _validateRate,
          decoration: new InputDecoration(labelText: "Descent (${_dive.metric?"M":"ft"}/min):"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "${_dive.ascentRate}",
          onSaved: (String val) => _dive.ascentRate = int.parse(val),
          validator: _validateRate,
          decoration: new InputDecoration(labelText: "Ascent (${_dive.metric?"M":"ft"}/min):"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "${_dive.surfaceInterval}",
          onSaved: (String val) => _dive.surfaceInterval = int.parse(val),
          validator: _validateSurfaceInterval,
          decoration: new InputDecoration(labelText: "Surface Interval Min:"),
          keyboardType: TextInputType.number),
      new FlatButton(
        child: const Text('Save'),
        onPressed: _handleSubmitted,
      ),
    ]);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: _appBar,
      body: new Form(key: _formKey, child: c3),
    );
  }
}
