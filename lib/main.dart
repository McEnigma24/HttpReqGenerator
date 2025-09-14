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
  
  // Listy dla dropdown'ów
  List<String> _ipList = [];
  List<String> _portList = [];
  String? _selectedIp;
  String? _selectedPort;
  
  // Stany rozwinięcia dropdown'ów
  bool _isIpDropdownOpen = false;
  bool _isPortDropdownOpen = false;
  

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
      _ipList = prefs.getStringList('ip_list') ?? [];
      _portList = prefs.getStringList('port_list') ?? [];
      
      // Walidacja wczytanych wartości
      String? savedIp = prefs.getString('selected_ip');
      String? savedPort = prefs.getString('selected_port');
      
      _selectedIp = (savedIp != null && _ipList.contains(savedIp)) ? savedIp : null;
      _selectedPort = (savedPort != null && _portList.contains(savedPort)) ? savedPort : null;
      
      _ipController.text = _selectedIp ?? '';
      _portController.text = _selectedPort ?? '';
      _apiPathController.text = prefs.getString('api_path') ?? '/dupa';
      _contentController.text = prefs.getString('content') ?? 'hs';
      _appendChecked = prefs.getBool('append') ?? false;
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ip_address', _ipController.text);
    await prefs.setString('port', _portController.text);
    
    // Zapisz tylko prawidłowe wartości
    await prefs.setString('selected_ip', (_selectedIp != null && _ipList.contains(_selectedIp)) ? _selectedIp! : '');
    await prefs.setString('selected_port', (_selectedPort != null && _portList.contains(_selectedPort)) ? _selectedPort! : '');
    
    await prefs.setStringList('ip_list', _ipList);
    await prefs.setStringList('port_list', _portList);
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

  void _addNewIp(String newIp) {
    if (newIp.isNotEmpty && !_ipList.contains(newIp)) {
      setState(() {
        _ipList.add(newIp);
        _selectedIp = newIp;
        _ipController.text = newIp;
      });
      _saveData();
    }
  }

  void _addNewPort(String newPort) {
    if (newPort.isNotEmpty && !_portList.contains(newPort)) {
      setState(() {
        _portList.add(newPort);
        _selectedPort = newPort;
        _portController.text = newPort;
      });
      _saveData();
    }
  }

  void _removeIp(String ip) {
    setState(() {
      _ipList.remove(ip);
      if (_selectedIp == ip) {
        _selectedIp = null;
        _ipController.text = '';
      }
      // Walidacja - upewnij się, że wybrana wartość istnieje w liście
      if (_selectedIp != null && !_ipList.contains(_selectedIp)) {
        _selectedIp = null;
        _ipController.text = '';
      }
    });
    _saveData();
  }

  void _removePort(String port) {
    setState(() {
      _portList.remove(port);
      if (_selectedPort == port) {
        _selectedPort = null;
        _portController.text = '';
      }
      // Walidacja - upewnij się, że wybrana wartość istnieje w liście
      if (_selectedPort != null && !_portList.contains(_selectedPort)) {
        _selectedPort = null;
        _portController.text = '';
      }
    });
    _saveData();
  }

  void _showAddIpDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dodaj nowy adres IP'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(
              hintText: 'np. 192.168.1.100',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                _addNewIp(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  void _showAddPortDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Dodaj nowy port'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              hintText: 'np. 9000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Anuluj'),
            ),
            TextButton(
              onPressed: () {
                _addNewPort(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('Dodaj'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _sendRequest() async {
    if (_selectedIp == null || _selectedPort == null) {
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
    
    final url = Uri.parse('http://$_selectedIp:$_selectedPort$apiPath');
    
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
      body: SingleChildScrollView(
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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isIpDropdownOpen = !_isIpDropdownOpen;
                            });
                          },
                          child: DropdownButtonFormField<String>(
                            value: _selectedIp,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Wybierz IP'),
                            items: [
                              ..._ipList.map((ip) => DropdownMenuItem(
                                value: ip,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(ip, overflow: TextOverflow.ellipsis),
                                    ),
                                    if (_isIpDropdownOpen)
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        onPressed: () {
                                          _removeIp(ip);
                                          setState(() {
                                            _isIpDropdownOpen = false;
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              )),
                              const DropdownMenuItem(
                                value: 'ADD_NEW_IP',
                                child: Text('+ Dodaj nowy IP', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _isIpDropdownOpen = false;
                              });
                              if (newValue == 'ADD_NEW_IP') {
                                _showAddIpDialog();
                              } else if (newValue != null) {
                                setState(() {
                                  _selectedIp = newValue;
                                  _ipController.text = newValue;
                                });
                                _saveData();
                              }
                            },
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
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isPortDropdownOpen = !_isPortDropdownOpen;
                            });
                          },
                          child: DropdownButtonFormField<String>(
                            value: _selectedPort,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            hint: const Text('Port'),
                            items: [
                              ..._portList.map((port) => DropdownMenuItem(
                                value: port,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(port, overflow: TextOverflow.ellipsis),
                                    ),
                                    if (_isPortDropdownOpen)
                                      IconButton(
                                        icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                                        onPressed: () {
                                          _removePort(port);
                                          setState(() {
                                            _isPortDropdownOpen = false;
                                          });
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              )),
                              const DropdownMenuItem(
                                value: 'ADD_NEW_PORT',
                                child: Text('+ Dodaj', overflow: TextOverflow.ellipsis),
                              ),
                            ],
                            onChanged: (String? newValue) {
                              setState(() {
                                _isPortDropdownOpen = false;
                              });
                              if (newValue == 'ADD_NEW_PORT') {
                                _showAddPortDialog();
                              } else if (newValue != null) {
                                setState(() {
                                  _selectedPort = newValue;
                                  _portController.text = newValue;
                                });
                                _saveData();
                              }
                            },
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