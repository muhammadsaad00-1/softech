import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:soft/homeview.dart';

class MoodDetector extends StatefulWidget {
  const MoodDetector({super.key});

  @override
  State<MoodDetector> createState() => _MoodDetectorState();
}

class _MoodDetectorState extends State<MoodDetector> {
  final List<String> emojis = [
    'loving',
    'excited',
    'tired',
    'happy',
    'productive',
    'angry',
    'lazy',
    'sad'
  ];

  Drawer customDrawer() => Drawer(
      child: ListView(
          children: const <Widget>[
            DrawerHeader(child: Text('Navigation Sidebar')),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            ),
            ListTile(
              title: Text('ini listnya'),
            )
          ]
      )
  );

  void _onEmojiPressed(String emojiTitle) {
    Navigator.push(context, MaterialPageRoute(builder: (context)=> HomeView(emotion: emojiTitle)));
    print('Emoji pressed: $emojiTitle');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Current Mood",
          style: TextStyle(color: Colors.orange),
        ),
        backgroundColor: Colors.white,
      ),
      drawer: customDrawer(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Tell us how you currently feel?"),
          SizedBox(
            height: 160, // enough for image + title
            child: ListView.builder(
              itemCount: emojis.length,
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                String emojiTitle = emojis[index];
                return Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      onTap: () => _onEmojiPressed(emojiTitle),
                      child: Container(
                        width: 100,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(
                                'assets/emoji${index + 1}.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              emojiTitle,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
