import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _urlController = TextEditingController();
  Map<String, dynamic> _results = {};
  String _error = "";
  bool _isLoading = false;
  String? _downloadLink;

  Future<void> scanUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a valid URL")),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = "";
      _results = {};
      _downloadLink = null;
    });

    try {
      final response = await http.post(
        Uri.parse("http://127.0.0.1:5000/scan"),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"url": url}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _results = data["results"];
          _downloadLink = "http://127.0.0.1:5000" + data["download_link"];
        });
      } else {
        setState(() => _error = "Error: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _downloadReport() async {
    if (_downloadLink != null) {
      final Uri url = Uri.parse(_downloadLink!);
      if (await canLaunchUrl(url)) {
 
        await launchUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not open download link")),
        );
      }
    }
  }

  Widget _buildResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.blueAccent),
            SizedBox(height: 10),
            Text("Scanning...", style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    if (_error.isNotEmpty) {
      return Text(
        _error,
        style: TextStyle(color: Colors.red, fontSize: 16),
      );
    }

    if (_results.isEmpty) {
      return Text(
        "No results yet. Enter a URL to start scanning.",
        style: TextStyle(fontSize: 16),
        textAlign: TextAlign.center,
      );
    }

    return Expanded(
      child: ListView(
        children: _results.entries.map((entry) {
          final vulnerability = entry.key;
          final result = entry.value;

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            elevation: 5,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vulnerability.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                  SizedBox(height: 8),
                  if (result is Map<String, dynamic>)
                    ...result.entries.map((subEntry) {
                      final key = subEntry.key;
                      final value = subEntry.value;

                      if (key == "results") {
                        return Column(
                          children: (value as List<dynamic>).map((item) {
                            final payload = item["payload"];
                            final vulnerable = item["vulnerable"];
                            return ListTile(
                              title: Text("Payload: $payload"),
                              subtitle: Text(
                                vulnerable ? "Vulnerable" : "Not Vulnerable",
                                style: TextStyle(
                                  color: vulnerable ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      } else {
                        return ListTile(
                          title: Text("$key: $value"),
                        );
                      }
                    }).toList()
                  else
                    Text(
                      result.toString(),
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200], 
      appBar: AppBar(
        title: Text("Vulnerability Scanner"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
        elevation: 5,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade100, Colors.blue.shade300],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.grey.shade400, blurRadius: 5),
                  ],
                ),
                child: TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: "Enter URL",
                    prefixIcon: Icon(Icons.link, color: Colors.blueAccent),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: scanUrl,
                icon: Icon(Icons.search),
                label: Text("Scan"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              _buildResults(),
              if (_downloadLink != null) ...[
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _downloadReport,
                  icon: Icon(Icons.download),
                  label: Text("Download Report"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
