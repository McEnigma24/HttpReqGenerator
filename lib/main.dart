import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HTTP Request Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HttpRequestGeneratorPage(),
    );
  }
}

class HttpRequestGeneratorPage extends StatefulWidget {
  const HttpRequestGeneratorPage({super.key});

  @override
  State<HttpRequestGeneratorPage> createState() => _HttpRequestGeneratorPageState();
}

class _HttpRequestGeneratorPageState extends State<HttpRequestGeneratorPage> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _apiPathController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  bool _appendChecked = false;
  bool _isLoading = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    
    // Add listeners for auto-save
    _ipController.addListener(_saveData);
    _portController.addListener(_saveData);
    _apiPathController.addListener(_saveData);
    _contentController.addListener(_saveData);
  }

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _apiPathController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('ip_address') ?? '192.168.1.35';
      _portController.text = prefs.getString('port') ?? '80';
      _apiPathController.text = prefs.getString('api_path') ?? '/dupa';
      _contentController.text = prefs.getString('content') ?? 'hs';
      _appendChecked = prefs.getBool('append') ?? false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_address', _ipController.text);
    await prefs.setString('port', _portController.text);
    await prefs.setString('api_path', _apiPathController.text);
    await prefs.setString('content', _contentController.text);
    await prefs.setBool('append', _appendChecked);
    
    // Resetuj stan po zmianie danych
    if (_isCompleted) {
      setState(() {
        _isCompleted = false;
      });
    }
  }

  Future<void> _sendRequest() async {
    if (_ipController.text.isEmpty || _portController.text.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _isCompleted = false;
    });

    // Automatycznie dodaj ukośnik na początku ścieżki API jeśli go nie ma
    String apiPath = _apiPathController.text;
    if (!apiPath.startsWith('/')) {
      apiPath = '/$apiPath';
    }
    
    final url = Uri.parse('http://${_ipController.text}:${_portController.text}$apiPath');
    
    final jsonPayload = {
      'append': _appendChecked,
      'text': _contentController.text,
    };

    // Ponawianie requestów aż do sukcesu
    bool success = false;
    int attempt = 0;
    const int maxAttempts = 10; // Maksymalnie 10 prób

    while (!success && attempt < maxAttempts && mounted) {
      attempt++;
      try {
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Connection': 'close',
          },
          body: jsonEncode(jsonPayload),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          success = true;
          if (mounted) {
            setState(() {
              _isLoading = false;
              _isCompleted = true;
            });
          }
        }
      } catch (e) {
        // Jeśli to nie ostatnia próba, czekaj chwilę przed ponowieniem
        if (attempt < maxAttempts && mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    // Jeśli nie udało się po wszystkich próbach
    if (!success && mounted) {
      setState(() {
        _isLoading = false;
        _isCompleted = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'HTTP Request Generator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      resizeToAvoidBottomInset: false, // Prevents keyboard from pushing UI up
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
              
              // IP Address and Port row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'IP Address',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _ipController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '192.168.1.35',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Port',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '80',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // API Path
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'API Path',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _apiPathController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '/dupa',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Append checkbox
              Row(
                children: [
                  Checkbox(
                    value: _appendChecked,
                    onChanged: (value) {
                      setState(() {
                        _appendChecked = value ?? false;
                      });
                      _saveData();
                    },
                  ),
                  const Text('Append'),
                  const SizedBox(width: 8),
                  const Text(
                    'Check if you want to append',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Content text area
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Content',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _contentController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Enter your content here...',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              
              // Send button
              ElevatedButton(
                onPressed: _isLoading ? null : _sendRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: _isCompleted ? Colors.green : null,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _isCompleted ? 'COMPLETED' : 'SEND',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _isCompleted ? Colors.white : null,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}