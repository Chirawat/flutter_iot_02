import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart' as mqtt;
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
  final String broker = 'broker.hivemq.com';

  mqtt.MqttClient? client;
  mqtt.MqttConnectionState? connectionState;
  StreamSubscription? subscription;
  Set<String> topics = Set<String>();

  //////////////////////////////////////////////////////////////////////////////
  TextEditingController brokerController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('MQTT Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            //mainAxisAlignment: MainAxisAlignment.s,
            children: <Widget>[
              TextField(
                controller: brokerController,
                decoration: InputDecoration(labelText: 'Broker'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Port'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Password'),
              ),
              TextField(
                decoration: InputDecoration(labelText: 'Client Indentifier'),
              ),
              ElevatedButton(
                onPressed: () {
                  _connect();
                },
                child: Text('Connect'),
              ),
              ElevatedButton(
                onPressed: () {
                  _subscribe();
                },
                child: Text('Subscribe'),
              ),
              ElevatedButton(
                onPressed: () {
                  _publish();
                },
                child: Text('Publish'),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _publish() async {
    /// Lets publish to our topic
    /// Use the payload builder rather than a raw buffer
    /// Our known topic to publish to
    const pubTopic = '/nacademy/test1';
    final builder = mqtt.MqttClientPayloadBuilder();
    builder.addString('Hello from mqtt_client');

    /// Subscribe to it
    //print('EXAMPLE::Subscribing to the Dart/Mqtt_client/testtopic topic');
    //client?.subscribe(pubTopic, mqtt.MqttQos.exactlyOnce);

    /// Publish it
    print('EXAMPLE::Publishing our topic');
    client?.publishMessage(
        pubTopic, mqtt.MqttQos.exactlyOnce, builder.payload!);

    /// Ok, we will now sleep a while, in this gap you will see ping request/response
    /// messages being exchanged by the keep alive mechanism.
    print('EXAMPLE::Sleeping....');
    await mqtt.MqttUtilities.asyncSleep(120);

    /// Finally, unsubscribe and exit gracefully
    // print('EXAMPLE::Unsubscribing');
    // client?.unsubscribe(topic);

    /// Wait for the unsubscribe message from the broker if you wish.
    // await MqttUtilities.asyncSleep(2);
    //print('EXAMPLE::Disconnecting');
    //client.disconnect();
    //return 0;
  }

  void _subscribe() {
    /// Ok, lets try a subscription
    print('EXAMPLE::Subscribing to the test/lol topic');
    const topic = '/nacademy/test1'; // Not a wildcard topic
    client?.subscribe(topic, mqtt.MqttQos.atMostOnce);

    /// The client has a change notifier object(see the Observable class) which we then listen to to get
    /// notifications of published updates to each subscribed topic.
    client?.updates!
        .listen((List<mqtt.MqttReceivedMessage<mqtt.MqttMessage?>>? c) {
      final recMess = c![0].payload as mqtt.MqttPublishMessage;
      final pt = mqtt.MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message);

      /// The above may seem a little convoluted for users only interested in the
      /// payload, some users however may be interested in the received publish message,
      /// lets not constrain ourselves yet until the package has been in the wild
      /// for a while.
      /// The payload is a byte buffer, this will be specific to the topic
      print(
          'EXAMPLE::Change notification:: topic is <${c[0].topic}>, payload is <-- $pt -->');
      print('');
    });
  }

  void _connect() async {
    client = MqttServerClient(broker, '');

    /// A websocket URL must start with ws:// or wss:// or Dart will throw an exception, consult your websocket MQTT broker
    /// for details.
    /// To use websockets add the following lines -:
    /// client.useWebSocket = true;
    /// client.port = 80;  ( or whatever your WS port is)
    /// There is also an alternate websocket implementation for specialist use, see useAlternateWebSocketImplementation
    /// Note do not set the secure flag if you are using wss, the secure flags is for TCP sockets only.
    /// You can also supply your own websocket protocol list or disable this feature using the websocketProtocols
    /// setter, read the API docs for further details here, the vast majority of brokers will support the client default
    /// list so in most cases you can ignore this.
    /// Set logging on if needed, defaults to off
    client?.logging(on: false);

    /// If you intend to use a keep alive you must set it here otherwise keep alive will be disabled.
    client?.keepAlivePeriod = 5;

    /// Set auto reconnect
    client?.autoReconnect = true;

    /// If you do not want active confirmed subscriptions to be automatically re subscribed
    /// by the auto connect sequence do the following, otherwise leave this defaulted.
    client?.resubscribeOnAutoReconnect = false;

    /// Add an auto reconnect callback.
    /// This is the 'pre' auto re connect callback, called before the sequence starts.
    client?.onAutoReconnect = onAutoReconnect;

    /// Add an auto reconnect callback.
    /// This is the 'post' auto re connect callback, called after the sequence
    /// has completed. Note that re subscriptions may be occurring when this callback
    /// is invoked. See [resubscribeOnAutoReconnect] above.
    client?.onAutoReconnected = onAutoReconnected;

    /// Add the successful connection callback if you need one.
    /// This will be called after [onAutoReconnect] but before [onAutoReconnected]
    client?.onConnected = onConnected;

    /// Add a subscribed callback, there is also an unsubscribed callback if you need it.
    /// You can add these before connection or change them dynamically after connection if
    /// you wish. There is also an onSubscribeFail callback for failed subscriptions, these
    /// can fail either because you have tried to subscribe to an invalid topic or the broker
    /// rejects the subscribe request.
    client?.onSubscribed = onSubscribed;

    /// Set a ping received callback if needed, called whenever a ping response(pong) is received
    /// from the broker.
    client?.pongCallback = pong;

    /// Create a connection message to use or use the default one. The default one sets the
    /// client identifier, any supplied username/password and clean session,
    /// an example of a specific one below.
    final connMess = mqtt.MqttConnectMessage()
        .withClientIdentifier('Mqtt_MyClientUniqueId')
        .withWillTopic(
            'willtopic') // If you set this you must set a will message
        .withWillMessage('My Will message')
        .startClean() // Non persistent session for testing
        .withWillQos(mqtt.MqttQos.atLeastOnce);
    print('EXAMPLE::Mosquitto client connecting....');
    client?.connectionMessage = connMess;

    /// Connect the client, any errors here are communicated by raising of the appropriate exception. Note
    /// in some circumstances the broker will just disconnect us, see the spec about this, we however will
    /// never send malformed messages.
    try {
      await client?.connect();
    } on Exception catch (e) {
      print('EXAMPLE::client exception - $e');
      client?.disconnect();
    }

    /// Check we are connected
    if (client?.connectionStatus!.state == mqtt.MqttConnectionState.connected) {
      print('EXAMPLE::Mosquitto client connected');
    } else {
      /// Use status here rather than state if you also want the broker return code.
      print(
          'EXAMPLE::ERROR Mosquitto client connection failed - disconnecting, status is ${client?.connectionStatus}');
      client?.disconnect();
      // exit(-1);
    }
  }

  /// The subscribed callback
  void onSubscribed(String topic) {
    print('EXAMPLE::Subscription confirmed for topic $topic');
  }

  /// The pre auto re connect callback
  void onAutoReconnect() {
    print(
        'EXAMPLE::onAutoReconnect client callback - Client auto reconnection sequence will start');
  }

  /// The post auto re connect callback
  void onAutoReconnected() {
    print(
        'EXAMPLE::onAutoReconnected client callback - Client auto reconnection sequence has completed');
  }

  /// The successful connect callback
  void onConnected() {
    print(
        'EXAMPLE::OnConnected client callback - Client connection was successful');
  }

  /// Pong callback
  void pong() {
    print(
        'EXAMPLE::Ping response client callback invoked - you may want to disconnect your broker here');
  }
}
