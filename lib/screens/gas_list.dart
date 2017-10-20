import 'package:flutter/material.dart';
import '../deco/plan.dart';
import 'gas_edit.dart';

class GasList extends StatelessWidget {
  final AppBar _appBar;
  final BottomNavigationBar _botNavBar;
  final Dive _dive;
  final Function _delete;
  final Function _save;

  GasList(this._appBar, this._botNavBar, this._dive, void delete(Gas gas), void save(Gas original, Gas changed)): _delete = delete, _save = save;

  @override
  Widget build(BuildContext context) {
    List<Widget> gchildren = new List<Widget>();
    for (final g in _dive.gasses) {
      gchildren.add(
          new Card(
            child: new Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                new ListTile(
                  //leading: const Icon(Icons.album),
                  title: new Text("$g  PPO2: ${g.ppo2}"),
                  subtitle: new Text("Depth range: ${g.minDepth}-${g.maxDepth}"),
                ),
                new ButtonTheme.bar( // make buttons use the appropriate styles for cards
                  child: new ButtonBar(
                    children: <Widget>[
                      new FlatButton(
                        child: const Text('Edit'),
                        onPressed: () {
                          Navigator.of(context).push(new MaterialPageRoute<Null>(
                              builder: (BuildContext context) {
                                return new GasEdit(appBar: _appBar, gas: g, save: _save);
                              })
                          );}),
                      new FlatButton(
                        child: const Text('Delete'),
                        onPressed: () {
                          // Work around stupid analyzer bug, should be _delete(g);
                          // Use Function instead of var so it can be final (stateless widget).
                          Function.apply(_delete, [g]);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
      );
    }
    final FloatingActionButton floatingActionButton = new FloatingActionButton(
      onPressed: () {
          Navigator.of(context).push(new MaterialPageRoute<Null>(
              builder: (BuildContext context) {
                return new GasEdit(appBar: _appBar, gas: new Gas.bottom(.21, .0, 1.2), save: _save);
              })
          );},
      tooltip: 'Add new gas',
      child: new Icon(Icons.add),
    );
    return new Scaffold(
      appBar: _appBar,
      body: new ListView(
          padding: const EdgeInsets.all(20.0),
          children: gchildren),
      bottomNavigationBar: _botNavBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
