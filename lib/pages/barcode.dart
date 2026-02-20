import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:refresh/refresh.dart';
import 'package:lete_sgam/pages/home.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lete_sgam/global.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class Barcode extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<Barcode> with SingleTickerProviderStateMixin {
  String? qr;
  String? nome = '';
  bool camState = false;
  bool errore = false;
  bool dirState = false;
  String? selectedId;
  bool? presenzaLinea;
  final FocusNode _focusNode = FocusNode();
  String? messaggioLinea;
  TextEditingController _controller = TextEditingController();
  String lastBarcode = "";
  String _barcodeBuffer = "";
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<ConnectivityResult>? connectivityRisultato;
  RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  // FUNZIONI

  // ONMOUNTED
  @override
  void initState() {
    super.initState();

    chiudiCamera();
    checkConnessione();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> result,
    ) {
      setState(() {
        if (result[0] == ConnectivityResult.none) {
          presenzaLinea = false;
          messaggioLinea = 'Connessione Assente';
          MotionToast.warning(
            title: Text(
              "ATTENZIONE!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            width: 400, // Imposta una larghezza personalizzata
            height: 150,
            description: Text(messaggioLinea!, style: TextStyle(fontSize: 16)),
            toastDuration: Duration(seconds: 10),
            // position: MotionToastPosition.top,
          ).show(context);
        } else {
          presenzaLinea = true;
          messaggioLinea = 'Connessione Attiva';
          // recheckVersion();
        }
      });
    });
  }

  @override
  void dispose() {
    // Annulla l'iscrizione al listener di connettività per prevenire perdite di memoria
    _connectivitySubscription.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> checkConnessione() async {
    connectivityRisultato = await Connectivity().checkConnectivity();

    if (connectivityRisultato!.contains(ConnectivityResult.none)) {
      setState(() {
        presenzaLinea = false;
        messaggioLinea = 'Connessione Assente!';
        MotionToast.warning(
          title: Text(
            "ATTENZIONE!",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          width: 400, // Imposta una larghezza personalizzata
          height: 150,
          description: Text(messaggioLinea!, style: TextStyle(fontSize: 16)),
          toastDuration: Duration(seconds: 5),
          dismissable: true,
          toastAlignment: Alignment.topCenter,
        ).show(context);
      });
    } else {
      setState(() {
        presenzaLinea = true;
        messaggioLinea = 'Connessione Attiva';
      });
    }
  }

  // REFRESH RELOAD
  void _onRefresh() async {
    chiudiCamera();
    checkConnessione();
    _refreshController.refreshCompleted();
  }

  Future<void> chiudiCamera() async {
    setState(() {
      camState = false;
      qr = null;
    });
    WakelockPlus.toggle(enable: false);
  }

  void showAlertVersion(
    BuildContext context,
    String message,
    String versioneAgg,
  ) {
    Alert(
      context: context,
      type: AlertType.error,
      title: "ATTENZIONE",
      desc: message,
      closeFunction: () {
        if (Platform.isAndroid) {
          SystemNavigator.pop(); // Prova a chiudere l'app su Android
          exit(0); // Termina completamente l'app
        } else {
          exit(0);
        }
      },
      style: AlertStyle(
        isOverlayTapDismiss: false, // Disabilita la chiusura cliccando fuori
      ),
      buttons: [],
    ).show();
  }

  // AZIONETURNO
  Future<void> azioneQr() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var qrLavorato = jsonDecode(qr!);
    await prefs.setString('urlOdoo', qrLavorato['domain']);
    // await chiudiCamera();
    print('YAaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa');

    // showAlert(context, "ssdfdsfsdds");
  }

  // SWEET ALERT
  void showAlert(BuildContext context, String message) {
    Alert(
      context: context,
      type: AlertType.error,
      title: "ATTENZIONE",
      desc: messaggioLinea,
      style: AlertStyle(
        isOverlayTapDismiss: false, // Disabilita la chiusura cliccando fuori
      ),
      buttons: [
        DialogButton(
          child: Text(
            "Ok",
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
          onPressed: () {
            setState(() {
              print(messaggioLinea);
            });
            Navigator.pop(context);
          },
          width: 120,
        ),
      ],
    ).show();
  }

  // LOADER
  Future<void> showLoadingDialog(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text("Caricamento..."),
              ],
            ),
          ),
        );
      },
    );
    await Future.delayed(Duration(milliseconds: 1500));
    azioneQr();
  }

  // NASCONDI LOADER
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _processBarcode(String value) {
    setState(() {
      lastBarcode = value;
      _barcodeBuffer = "";
    });
    print("Barcode letto: $value");
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final appBarHeight = screenHeight * 0.5;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(65),
          child: AppBar(
             centerTitle: true,
            title: SizedBox(
              height: 50,
              child: Image(
                              image: AssetImage('assets/images/logo_sgam.png'),
                              fit: BoxFit
                                  .contain, // Per mantenere le proporzioni dell'immagine
                            ),
            ),
              backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(180),
          ),
        ),
        body: Container(
          child: SmartRefresher(
            controller: _refreshController,
            header: WaterDropMaterialHeader(),
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: screenHeight - 100),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                                  KeyboardListener(
  focusNode: _focusNode,
  autofocus: true,
  onKeyEvent: (KeyEvent event) {
    if (event is KeyDownEvent) {
      // Usa "character" se disponibile
      final String? char = event.character;

      if (char != null && char.isNotEmpty) {
        if (char == '\n') {
          _processBarcode(_barcodeBuffer);
        } else {
          _barcodeBuffer += char;
        }
      }
    }
  },
  child:       Text(
                          "Ultimo barcode: $lastBarcode", // qui il valore cambia dinamicamente
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
  // child: TextField(
  //   controller: TextEditingController(text: _barcodeBuffer),
  //   readOnly: true,
  //   decoration: InputDecoration(
  //     labelText: "Scansiona barcode",
  //     border: OutlineInputBorder(),
  //   ),
  // ),
                        ),
                        SizedBox(height: 20),
                        Text(
                          "Ultimo barcode: $lastBarcode", // qui il valore cambia dinamicamente
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                            ]
                          ),
                        ),
                      ),
                
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        drawer: Container(
          width: MediaQuery.of(context).size.width / 1.6,
          child: Drawer(
            child: ListView(
              padding: EdgeInsets.all(0),
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFFFFFF), // #ffffff
                        Color(0xFFDCDCDC), // #dcdcdc
                        Color(0xFFDCDCDC), // #dcdcdc
                      ],
                    ),
                  ),
                  child: Image(
                              image: AssetImage('assets/images/logo_sgam.png'),
                              fit: BoxFit
                                  .contain, // Per mantenere le proporzioni dell'immagine
                            ),
                ),
                ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Home()),
                  ),
                  leading: Icon(Icons.home),
                  title: Text("Home"),
                ),
                ListTile(
                  onTap: () => print('sdsds'),
                  leading: Icon(Icons.logout),
                  title: Text("Log Out"),
                ),
              ],
            ),
          ),
        ),
        // floatingActionButton: camState
        //     ? FloatingActionButton(
        //         child: const Text(
        //           "Camera off",
        //           textAlign: TextAlign.center,
        //         ),
        //         onPressed: () {
        //           setState(() {
        //             camState = false; // Disabilita la camera
        //             qr = null;
        //           });
        //         },
        //       )
        // : null
      ),
    );
  }
}
