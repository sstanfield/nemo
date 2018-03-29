import 'package:flutter/material.dart';

class DoubleEdit extends StatelessWidget {
  final double initialValue;
  final FormFieldSetter<double> onSaved;
  final FormFieldValidator<double> validator;
  final String label;
  final double padding;

  DoubleEdit({
    Key key,
    this.initialValue,
    this.onSaved,
    this.validator,
    this.label,
    this.padding = 0.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: new EdgeInsets.symmetric(horizontal: padding),
        child:
        new TextFormField(
            initialValue: "$initialValue",
            onSaved: (String val) => onSaved(val.length == 0 ? 0 : double.parse(val)),
            validator: (String val) {
              double i = -1.0;
              if (val.length == 0)
                i = 0.0;
              else
                try {
                  i = double.parse(val);
                  return validator(i);
                } catch (ignored) {}
              return "$val is not a double";
            },
            decoration: new InputDecoration(labelText: label),
            keyboardType: TextInputType.number));
  }
}
