import 'package:flutter/material.dart';

typedef void submitCallback();

class CommonButtons extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final submitCallback submit;

  CommonButtons({
    Key key,
    this.formKey,
    this.submit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Row(children: [
      new FlatButton(
        child: const Text('CANCEL'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      ),
      new FlatButton(
        child: const Text('RESET'),
        onPressed: () {
          final FormState form = formKey.currentState;
          form.reset();
        },
      ),
      new FlatButton(
        child: const Text('SAVE'),
        onPressed: submit,
      ),
    ]);
  }
}
