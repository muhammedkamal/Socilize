import 'package:flutter/material.dart';
import 'package:socialize/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final _formKey = GlobalKey<FormState>();
  String username;

  submit()
  {
    _formKey.currentState.save();
    Navigator.pop(context,username);
  }
  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      appBar: header(context,isTimeLine: false,pageTitle: 'Create Acount'),
      body: Container(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 25.0),
              child: Center(
                child: Text('Enter Username',
                style: TextStyle(
                  fontSize: 25.0,
                ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: TextFormField(
                  onSaved: (val)=>username=val,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Username must be more than 4 characters',
                    labelText: 'Username',
                    labelStyle: TextStyle(
                      fontSize: 15.0,
                    ),
                  ),
                ),
              ),
            ),
            FlatButton(
              onPressed: submit,
              child: Container(
                height: 50.0, // not good for small mobiles please figure out how to solve it
                width: 350.0,
                decoration: BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.circular(7.0),
                  //may need to add a color
                ),
                child: Center(
                  child: Text('Submit',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                  ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
