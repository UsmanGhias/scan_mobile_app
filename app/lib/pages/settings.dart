import 'package:app/services/shared_pref.dart';
import 'package:app/widgets/helper_button.dart';
import 'package:app/widgets/helper_textfield.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  void _loadPrefs() async {
    _urlController.text = await SharedPrefsService.getServerUrl() ?? '';
    _tokenController.text = await SharedPrefsService.getAuthToken() ?? '';
  }

  void _saveSettings() async {
    await SharedPrefsService.saveServerSettings(
        _urlController.text, _tokenController.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Settings Saved')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Server Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          HelperTextField(
              htxt: "Server URL",
              iconData: Icons.web,
              controller: _urlController,
              keyboardType: TextInputType.text),
          HelperTextField(
              htxt: "Auth Token",
              iconData: Icons.token,
              controller: _tokenController,
              keyboardType: TextInputType.text),
          const SizedBox(height: 24),
          HelperButton(name: "Save", onTap: _saveSettings),
        ]),
      ),
    );
  }
}
