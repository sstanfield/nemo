import 'package:flutter/material.dart';

class IntEdit extends StatelessWidget {
  final int initialValue;
  final FormFieldSetter<int> onSaved;
  final FormFieldValidator<int> validator;
  final String label;

  IntEdit({
    Key key,
    this.initialValue,
    this.onSaved,
    this.validator,
    this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child:
        new TextFormField(
            initialValue: "$initialValue",
            onSaved: (String val) => onSaved(val.length == 0 ? 0 : int.parse(val)),
            validator: (String val) {
              int i = -1;
              if (val.length == 0)
                i = 0;
              else
                try {
                  i = int.parse(val);
                  return validator(i);
                } catch (ignored) {}
              return "$val is not an integer";
            },
            decoration: new InputDecoration(labelText: label),
            keyboardType: TextInputType.number));
  }
}
