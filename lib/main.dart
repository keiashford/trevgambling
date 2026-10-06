import 'dart:convert';
import 'dart:core';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as web;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trev\'s Gambling',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Trev\'s Betting Advice'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class  Bet
{
String team1="blank";
String team2="blank";
int TeamToBetOn=0;
int TeamToLay=0;
int id=-1;
final DateTime date;
Bet({
    required this.team1,
    required this.team2,
    required this.TeamToBetOn,
    required this.TeamToLay,
    required this.id,
    required this.date,
    
  });
  factory Bet.fromJson(Map<String, dynamic> json) {
    return Bet(
      team1: json['Team1'] ?? 'blank',
      team2: json['Team2'] ?? 'blank',
      TeamToBetOn: int.tryParse(json['TeamtoBetOn'].toString()) ?? 0,
      TeamToLay: int.tryParse(json['TeamToLay'].toString()) ?? 0,
      id: int.tryParse(json['id'].toString()) ?? -1,
     date: DateTime.parse(json['Date']),
    );
  }
  
}
    
Future<List<Bet>> fetchBet() async {
  final response = await http.get(
    Uri.parse('http://www.crystalstudios.co.uk/bet.php?id=1'),
    headers: {'Accept': 'application/json'},
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    //print (response.body);
    try {

      print (response.body);
final decoded = jsonDecode(response.body);
print (decoded);
List<dynamic> rawList = [];

if (decoded is List) {
  rawList = decoded;
} else if (decoded is Map) {
  // Check if it's a wrapper object with a list inside, or a single bet object
  if (decoded.containsKey('bets') && decoded['bets'] is List) {
    rawList = decoded['bets'];
  } else {
    // It's a single bet object, wrap it in a list so it can be parsed
    rawList = [decoded];
  }
}

List<Bet> bets = rawList.map((item) => Bet.fromJson(item as Map<String, dynamic>)).toList();
print (bets);

print (rawList);
return bets;


    } catch (e) {
      throw Exception('Failed to parse bet JSON: $e');
    }   
 
  } else {

    // If the server did not return a 200 OK response,
    // then throw an exception.
  throw Exception('Failed to load bet. Status: ${response.statusCode}');
  }


  }


class _MyHomePageState extends State<MyHomePage> {
  bool _isSignedIn = false;
  bool _isInitializing = true; // Prevents flashing the sign-in button on reload
  String? _avatarURL;
  String? _userName;
  int _counter = 0;
late Future<List<Bet>> futureBet;
  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }
   @override
  void initState() {
    super.initState();
    futureBet = fetchBet();
    _checkLocalSession();
  }


  Future<void> _checkLocalSession() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedIn = prefs.getBool('is_logged_in') ?? false;
    final name = prefs.getString('user_name');

    setState(() {
      _isSignedIn = loggedIn;
      _userName = name;
      _isInitializing = false; // Stop loading immediately
    });

    // Optional: Still run Google init in the background to keep tokens valid
    _initGoogleSignInSilently();
  }

  Future<void> _initGoogleSignInSilently() async {
    final GoogleSignIn signIn = GoogleSignIn.instance;

    signIn.authenticationEvents.listen((event) {
      if (event is GoogleSignInAuthenticationEventSignIn) {
        final user = event.user;
        if (user != null) {
          _saveSession(user.displayName ?? 'User');
        }
      } else if (event is GoogleSignInAuthenticationEventSignOut) {
        _clearSession();
      }
    });

    await signIn.initialize(clientId: '87903203856-k5iq875489hvnlea79qvvnrtb6qu9lht');
    await signIn.attemptLightweightAuthentication();
  }


  Future<void> _saveSession(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_name', name);
    setState(() {
      _isSignedIn = true;
      _userName = name;
      _isInitializing = false; // Stop loading immediately
    });
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    await prefs.remove('user_name');
    setState(() {
      _isSignedIn = false;
      _userName = null;
      _isInitializing = false; // Stop loading immediately
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

  
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(



        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          //R
          // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
          // action in the IDE, or press "p" in the console), to see the
          // wireframe for each widget.
            mainAxisAlignment: GoogleSignIn.instance.supportsAuthenticate() ? MainAxisAlignment.center : MainAxisAlignment.center,
            children: [
              if (_isInitializing)
                const CircularProgressIndicator()

              else if (_isSignedIn)
                Column(
                  children: [
                    Text('Signed in as $_userName', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await GoogleSignIn.instance.signOut();
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                )
              else if (GoogleSignIn.instance.supportsAuthenticate())
                ElevatedButton(
                  onPressed: () async {
                    // Standard mobile/native sign-in flow
                    await GoogleSignIn.instance.authenticate();
                  },
                  child: const Text('Sign in with Google'),
                )
              else if (kIsWeb)
                // Renders the official Google Sign-In button component for browsers
                  web.renderButton()
              ,
             /*Text('Duration is 16 minutes'),
              Text('Service is shower'),
               Text('Cost is 15'),
                Text('Unit is per shower'),
                 Text('You have pushed the button $_counter this many times:'),
             Text('You have pushed the button $_counter this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium),
              */

            Expanded( 
              child: FutureBuilder<List<Bet>>(
                future: futureBet , // Your async function
                builder: (context, snapshot) {


                  if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  // 3. Success state
                  if (snapshot.hasData && snapshot.data!=null) {

                      List<Bet> thisBetList=snapshot.data!;
                       List<Card> cards = [];
                
                  for (var thisBet in  thisBetList) {
                print(thisBet);
                        String teamName = switch (thisBet.TeamToBetOn) {
                    1 => "Bet on:${thisBet.team1}",
                    2 => "Bet on:${thisBet.team2}",
                    _ => 'no team to bet on',
                    };
                  if(teamName=='no team to bet on')
                  {
                  teamName = switch (thisBet.TeamToLay) {
                    1 => "Lay: ${thisBet.team1}",
                    2 => "Lay: ${thisBet.team2}",
                    _ => 'no team to bet on',
                    

                  };
                  }
                Card v=  Card(child:ListTile(
                          title: 
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children:[
                              Text("${thisBet.team1} vs ${thisBet.team2}"),
                          Text("${DateFormat('dd MMMM yyyy').format(thisBet.date)}"),
                            ]),
                          subtitle: Column(
                                    
                                     children: [
                                      Text(teamName),
                      
                                    ],
                                     ),  
                          
                        ),
                        );
                    cards.add(v);
                    }


                    
                   
                  
                    return ListView(
                      children:cards 
                    );
                    }
                    else
                  {return const Center(child: Text('No data found'));}
                },
              )
            ),


           
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
