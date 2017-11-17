import 'package:flutter/material.dart';
import 'widgets/int_edit.dart';
import 'widgets/common_form_buttons.dart';
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

  @override
  Widget build(BuildContext context) {
    ListView c3 = new ListView(padding: const EdgeInsets.all(8.0), children: [
      new IntEdit(initialValue: _dive.gfLo,
          onSaved: (int v) => _dive.gfLo = v,
          validator: (int v) => (v < 0 || v > 100)?"Enter gradiant factor 0-100":null,
          label: "gfLo"),
      new IntEdit(initialValue: _dive.gfHi,
          onSaved: (int v) => _dive.gfHi = v,
          validator: (int v) => (v < 0 || v > 100)?"Enter gradiant factor 0-100":null,
          label: "gfHi"),
      new IntEdit(initialValue: _dive.atmPressure,
          onSaved: (int v) => _dive.atmPressure = v,
          validator: (int v) => (v < 500 || v > 3000)?"Enter surface pressure in mbar (500-3000)":null,
          label: "ATM Pressure"),
      new IntEdit(initialValue: _dive.descentRate,
          onSaved: (int v) => _dive.descentRate = v,
          validator: (int v) => (v < 1 || v > (_dive.metric?300:900))?"Enter Descent Rate ${_dive.metric?"M":"ft"}/min (1-${_dive.metric?"300":"900"})":null,
          label: "Descent (${_dive.metric?"M":"ft"}/min):"),
      new IntEdit(initialValue: _dive.ascentRate,
          onSaved: (int v) => _dive.ascentRate = v,
          validator: (int v) => (v < 1 || v > (_dive.metric?300:900))?"Enter Ascent Rate ${_dive.metric?"M":"ft"}/min (1-${_dive.metric?"300":"900"})":null,
          label: "Ascent (${_dive.metric?"M":"ft"}/min):"),
      new IntEdit(initialValue: _dive.surfaceInterval,
          onSaved: (int v) => _dive.surfaceInterval = v,
          validator: (int v) => (v < 0 || v > 14400)?"Enter Surface Interval Minutes (0-14,400 (10 days))":null,
          label: "Surface Interval Min"),
      new CommonButtons(formKey: _formKey, submit: _handleSubmitted),
    ]);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: _appBar,
      body: new Form(key: _formKey, child: c3),
    );
  }
}
