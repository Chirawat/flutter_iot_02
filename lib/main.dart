import 'package:flutter/material.dart';
import './mqtt_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MQTT Connect',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String clientId = '';
  String server = '';
  String username = '';
  String password = '';
  String topic = '';
  String message = '';

  List<String> messages = <String>[];

  //MQTTClient? client = MQTTClient('a4818d92-da7e-4cc3-b49a-8468cfb67b25', 'broker.hivemq.com');

  MQTTClient? client;

  //////////////////////////////////////////////////////////////////////////////
  TextEditingController clientIdController = TextEditingController();
  TextEditingController serverController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController topicController = TextEditingController();
  TextEditingController messageController = TextEditingController();
  TextEditingController subScribeController = TextEditingController();

  @override
  void initState() {
    serverController.text = 'mqtt.netpie.io';
    clientIdController.text = '0de0d7b7-2f55-4679-bd3f-bd0bf93bbec0';
    usernameController.text = 'tnUdT2JKo2RfS48fVVGnkxuEHyV9TVNC';
    passwordController.text = '_AQKx-z0xeXKLO7Z15Ra_jP#MFkmSnqr';
    topicController.text = '@msg/test';

    topic = '';
    subScribeController.text = '@msg/test';

    // messages.add('One');
    // messages.add('Two');
    // messages.add('Three');
  }

  void sub_sb(String topic, String msg) {
    print(topic);
    print(msg);
    print('');

    setState(() {
      messages.add(msg);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Test'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              //mainAxisAlignment: MainAxisAlignment.s,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                TextField(
                  controller: serverController,
                  decoration: InputDecoration(labelText: 'Broker'),
                ),
                TextField(
                  controller: clientIdController,
                  decoration: InputDecoration(labelText: 'ClientID'),
                ),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(labelText: 'Username'),
                ),
                TextField(
                  controller: passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                ),
                // TextField(
                //   decoration: InputDecoration(labelText: 'Client Indentifier'),
                // ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        clientId = clientIdController.value.text;
                        server = serverController.value.text;
                        if (usernameController.value.text.isEmpty) {
                          client = MQTTClient(clientId, server);
                        } else {
                          username = usernameController.value.text;
                          password = passwordController.value.text;
                          client =
                              MQTTClient(clientId, server, username, password);
                        }
                        client?.connect();
                      },
                      child: Text('Connect'),
                    ),
                    SizedBox(width: 20.0),
                    ElevatedButton(
                      onPressed: () {
                        client?.disconnect();
                      },
                      child: Text('Disconnect'),
                    )
                  ],
                ),
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(labelText: 'Topic'),
                ),
                TextField(
                  controller: messageController,
                  decoration: InputDecoration(labelText: 'Message'),
                ),
                ElevatedButton(
                  onPressed: () {
                    topic = topicController.value.text;
                    message = messageController.value.text;
                    if (topic.isNotEmpty)
                      client?.publish(topic, message);
                    else
                      print('Error:: Topic can\'t be empty');
                  },
                  child: Text('Publish'),
                ),
                TextField(
                  controller: subScribeController,
                  decoration: InputDecoration(labelText: 'Subscibe topic'),
                ),
                ElevatedButton(
                  onPressed: () {
                    topic = subScribeController.value.text;
                    client?.subscribe(topic, sub_sb);
                    //addText('new text');
                  },
                  child: Text('Subscribe'),
                ),
                Container(
                  width: double.infinity,
                  color: Colors.greenAccent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recieved Text:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ...messages.map((message_t) {
                        return Text(message_t);
                      }).toList()
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
