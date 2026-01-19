import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const AkulMindApp());

class AkulMindApp extends StatelessWidget {
  const AkulMindApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        fontFamily: 'monospace',
      ),
      home: const AkulMindEngine(),
    );
  }
}

class AkulMindEngine extends StatefulWidget {
  const AkulMindEngine({super.key});
  @override
  State<AkulMindEngine> createState() => _AkulMindEngineState();
}

class _AkulMindEngineState extends State<AkulMindEngine> {
  bool isUnlocked = false;
  double loginProgress = 0.0;
  Timer? _loginTimer;

  String selectedMode = "ARQUITECTO";
  String? apiKey;
  bool isThinking = false;
  List<String> attachedFiles = [];
  final TextEditingController _queryController = TextEditingController();
  final List<Map<String, String>> chatHistory = [];

  // --- LÓGICA DE ACCESO ---
  void _startUnlock() {
    _loginTimer = Timer.periodic(const Duration(milliseconds: 20), (t) {
      if (loginProgress < 1.0) {
        setState(() => loginProgress += 0.05);
      } else {
        t.cancel();
        setState(() => isUnlocked = true);
      }
    });
  }

  // --- MÓDULOS PRO ---
  void _attachFile() {
    setState(() {
      String fileName = "CONTEXT_0${attachedFiles.length + 1}.dart";
      attachedFiles.add(fileName);
      chatHistory.insert(0, {"role": "SISTEMA", "msg": "FILE_INJECTED: $fileName"});
    });
  }

  void _generateReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("EXPORT_SYSTEM", style: TextStyle(fontSize: 12, letterSpacing: 2)),
        content: const Text("Generando reporte técnico... ¿Confirmar descarga PDF?", style: TextStyle(fontSize: 10)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("EXPORTAR", style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Future<void> _callAI(String prompt) async {
    if (apiKey == null || apiKey!.isEmpty) {
      _showConfigDialog();
      return;
    }
    setState(() {
      isThinking = true;
      chatHistory.insert(0, {"role": "USER", "msg": prompt});
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      chatHistory.insert(0, {
        "role": "AKULMIND",
        "msg": "MODO_$selectedMode >> Análisis de '${prompt.toUpperCase()}' completado con éxito."
      });
      isThinking = false;
    });
  }

  void _showConfigDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text("API_AUTH", style: TextStyle(fontSize: 12)),
        content: TextField(
          obscureText: true,
          onChanged: (v) => apiKey = v,
          decoration: const InputDecoration(hintText: "Pega tu Key..."),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isUnlocked ? _buildMainInterface() : _buildLoginScreen(),
    );
  }

  // --- PANTALLA DE ENTRADA ---
  Widget _buildLoginScreen() {
    return GestureDetector(
      onTapDown: (_) => _startUnlock(),
      onTapUp: (_) {
        _loginTimer?.cancel();
        setState(() => loginProgress = 0.0);
      },
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("AkulMind", style: TextStyle(letterSpacing: 20, fontSize: 32, fontWeight: FontWeight.w100)),
            const SizedBox(height: 50),
            Container(
              width: 100,
              height: 1,
              color: Colors.white10,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: loginProgress,
                child: Container(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- INTERFAZ DE TRABAJO ---
  Widget _buildMainInterface() {
    const white = Colors.white;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("AkulMind", style: TextStyle(letterSpacing: 5, fontSize: 18)),
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.attach_file, size: 18, color: Colors.white24), onPressed: _attachFile),
                    IconButton(icon: const Icon(Icons.description_outlined, size: 18, color: Colors.white24), onPressed: _generateReport),
                    IconButton(icon: Icon(Icons.vpn_key, size: 18, color: (apiKey == null || apiKey!.isEmpty) ? Colors.red : Colors.green), onPressed: _showConfigDialog),
                  ],
                )
              ],
            ),
          ),
          
          if (attachedFiles.isNotEmpty)
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: attachedFiles.map((f) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
                  child: Text(f, style: const TextStyle(fontSize: 8, color: Colors.white30)),
                )).toList(),
              ),
            ),

          _buildModeSelector(white),

          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(20),
              itemCount: chatHistory.length,
              itemBuilder: (context, i) => _buildBubble(chatHistory[i], white),
            ),
          ),

          if (isThinking) const LinearProgressIndicator(color: Colors.white, backgroundColor: Colors.black, minHeight: 1),
          _buildInput(white),
        ],
      ),
    );
  }

  Widget _buildModeSelector(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ["ARQUITECTO", "ESTRATEGA", "AUDITOR"].map((m) => GestureDetector(
          onTap: () => setState(() => selectedMode = m),
          child: Text(m, style: TextStyle(color: selectedMode == m ? Colors.white : Colors.white10, fontSize: 8, letterSpacing: 2)),
        )).toList(),
      ),
    );
  }

  Widget _buildBubble(Map<String, String> chat, Color color) {
    bool isAi = chat['role'] == "AKULMIND";
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAi ? color.withOpacity(0.03) : Colors.transparent,
        border: isAi ? null : Border.all(color: color.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(chat['role']!, style: TextStyle(color: color.withOpacity(0.2), fontSize: 7, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(chat['msg']!, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInput(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 0, 25, 20),
      child: TextField(
        controller: _queryController,
        style: const TextStyle(fontSize: 12),
        decoration: InputDecoration(
          hintText: ">>> ANALIZAR...",
          hintStyle: TextStyle(color: color.withOpacity(0.1), fontSize: 9),
          border: InputBorder.none,
        ),
        onSubmitted: (v) {
          _callAI(v);
          _queryController.clear();
        },
      ),
    );
  }
}