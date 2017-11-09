import 'package:flutter/material.dart';
import '../deco/plan.dart';

class GasEdit extends StatefulWidget {
  final AppBar appBar;
  final Gas gas;
  final Function _save;
  final Dive dive;

  GasEdit(
      {Key key,
      this.appBar,
      this.gas,
      this.dive,
      void save(Dive dive, Gas original, Gas changed)})
      : _save = save,
        super(key: key);

  @override
  _GasEditState createState() => new _GasEditState(appBar, gas, _save, dive);
}

class _GasEditState extends State<GasEdit> {
  final AppBar _appBar;
  final Gas _gas;
  bool _decoGas = false;
  final Dive _dive;
  int _pO2;
  int _pHe;
  var _save;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();

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
      Gas newGas = !_decoGas
          ? new Gas.bottom(_pO2 / 100.0, _pHe / 100.0, 1.4)
          : new Gas.deco(_pO2 / 100.0, _pHe / 100.0);
      _save(_dive, _gas, newGas);
    }
  }

  String _validateGas(String gas) {
    int igas = -1;
    if (gas.length == 0)
      igas = 0;
    else
      try {
        igas = int.parse(gas);
      } catch (ignored) {}
    if (igas < 0 || igas > 100) return "Enter gas percent 0-100";
    return null;
  }

  _GasEditState(this._appBar, this._gas, this._save, this._dive)
      : _pO2 = (_gas.fO2 * 100).round(),
        _pHe = (_gas.fHe * 100).round();

  @override
  Widget build(BuildContext context) {
    Column c3 = new Column(children: [
      new TextFormField(
          initialValue: "$_pO2",
          onSaved: (String val) => _pO2 = val.length == 0 ? 0 : int.parse(val),
          validator: _validateGas,
          decoration: new InputDecoration(labelText: "O2 %:"),
          keyboardType: TextInputType.number),
      new TextFormField(
          initialValue: "$_pHe",
          onSaved: (String val) => _pHe = val.length == 0 ? 0 : int.parse(val),
          validator: _validateGas,
          decoration: new InputDecoration(labelText: "He %:"),
          keyboardType: TextInputType.number),
      new Row(children: [
        new Checkbox(
            value: _decoGas,
            onChanged: (bool v) => setState(() {
                  _decoGas = v;
                })),
        const Text('Deco Gas')
      ]),
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
