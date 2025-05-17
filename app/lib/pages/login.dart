import 'package:app/pages/home.dart';
import 'package:app/pages/settings.dart';
import 'package:app/services/shared_pref.dart';
import 'package:app/shared/api_methods.dart';
import 'package:app/widgets/helper_button.dart';
import 'package:app/widgets/helper_textfield.dart';
import 'package:app/widgets/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final _loginController = TextEditingController();
  final _apiTokenController = TextEditingController();
  final _dbNameController = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiTokenController.text = prefs.getString('api_token') ?? '';
      _dbNameController.text = prefs.getString('database_name') ?? '';
      _loginController.text = prefs.getString('login') ?? '';
    });
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      // Save the API configuration
      final apiResult = await APIServices().configureApiSettings(
        apiToken: _apiTokenController.text,
        dbName: _dbNameController.text,
        login: _loginController.text,
      );

      if (apiResult != 'SUCCESS') {
        showSnackbar(
            context: context, content: 'API configuration failed: $apiResult');
        return;
      }

      // Verify the settings are correct by making a test request
      final isValid = await APIServices().validateCurrentApiSettings();

      if (!mounted) return;
      setState(() => _loading = false);

      if (isValid) {
        showSnackbar(context: context, content: 'Login Successful');
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => HomeScreen()));
      } else {
        showSnackbar(
            context: context,
            content: 'Invalid credentials or API configuration');
      }
    } catch (e) {
      if (!mounted) return;
      showSnackbar(context: context, content: 'Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("API Configuration"),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              HelperTextField(
                htxt: 'Database Name',
                iconData: Icons.storage,
                controller: _dbNameController,
                keyboardType: TextInputType.text,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              HelperTextField(
                htxt: 'API Token',
                iconData: Icons.vpn_key,
                controller: _apiTokenController,
                keyboardType: TextInputType.text,
                validator: (v) => v!.isEmpty ? 'Required' : null,
                obscure: true,
              ),
              HelperTextField(
                htxt: 'Login',
                iconData: Icons.person,
                controller: _loginController,
                keyboardType: TextInputType.text,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),
              _loading
                  ? const Center(child: CircularProgressIndicator())
                  : HelperButton(
                      name: 'Save & Connect',
                      onTap: _login,
                    ),
              const SizedBox(height: 16),
              Text(
                'Note: The API token is generated from your Odoo user profile.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
