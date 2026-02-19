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
import 'package:google_fonts/google_fonts.dart';
import 'package:lete_sgam/global.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';


class Home extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<Home> with SingleTickerProviderStateMixin {
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
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<ConnectivityResult>? connectivityRisultato;
  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

// FUNZIONI

// ONMOUNTED
  @override
  void initState() {
    super.initState();
    
    chiudiCamera();
      checkConnessione();
       _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      setState(() {
        if (result[0] == ConnectivityResult.none) {
          presenzaLinea = false;
          messaggioLinea = 'Connessione Assente';
             MotionToast.warning(
        title: Text("ATTENZIONE!",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
         width: 400, // Imposta una larghezza personalizzata
         height: 150,
        description: Text(messaggioLinea!,style: TextStyle(fontSize: 16),),
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
        title: Text("ATTENZIONE!",style: TextStyle(fontSize: 16,fontWeight: FontWeight.bold),),
         width: 400, // Imposta una larghezza personalizzata
         height: 150,
        description: Text(messaggioLinea!,style: TextStyle(fontSize: 16),),
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
      BuildContext context, String message, String versioneAgg) {
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
      buttons: [
      ],
    ).show();
  }

  // AZIONETURNO
  Future<void> azioneQr() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
var qrLavorato=jsonDecode(qr!);
    await prefs.setString('urlOdoo',qrLavorato['domain']);
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
        )
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
    });

    print("Barcode letto: $value");

    // Pulisce l'input e mantiene il focus
    _controller.clear();
    FocusScope.of(context).requestFocus(_focusNode);
  }
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
  final appBarHeight = screenHeight * 0.28;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SmartRefresher(
          controller: _refreshController,
          header: WaterDropMaterialHeader(),
          onRefresh: _onRefresh,
           child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight,
                ), // Imposta l'altezza per garantire il corretto scroll
                child: IntrinsicHeight(
                  child: Stack(
                    children: [
       Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: appBarHeight,
                        child: PreferredSize(
                          preferredSize: Size.fromHeight(appBarHeight),
                          child: AppBar(
                            centerTitle: true, 
                             title: SizedBox(
                height: 57,
                child: Image(
                  image: AssetImage('assets/images/logo_sgam.png'),
                  fit: BoxFit
                      .contain, // Per mantenere le proporzioni dell'immagine
                ),
              ),
                            // automaticallyImplyLeading: false,
                             backgroundColor: Theme.of(context).primaryColor.withAlpha(200), // 50% opaco
                            elevation: 0,
                            flexibleSpace: Container(
                              padding:
                                  EdgeInsets.only(left: 12.0, bottom: 20),
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Benvenuto!",
                                    style: GoogleFonts.lato(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                      ),
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    // user!['descrizione'] ??
                                        "Descrizione non disponibile",
                                    style: GoogleFonts.lato(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                      ),
                                      fontSize: 20,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                          
                Column(
                                children: [
                                  SizedBox(height: 50),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        InkWell(
                                          onTap: () {
                                            print('asdasd');
                                          },
                                          child: Card(
                                            elevation: 20,
                                            child: Container(
                                              width: screenWidth * 0.4,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_2_rounded,
                                                      color: const Color(
                                                          0xFFBA0000),
                                                      size: 100.0,
                                                    ),

                                                    SizedBox(height: 12),
                                                    Text(
                                                      "PRESENZA",
                                                      style: GoogleFonts.lato(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),

                                                    // Aggiungi altri widget qui se necessario
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        
                                        
                                      ]
                                      ),
                                        SizedBox(height: 100),
                                                               TextField(
              controller: _controller,
              autofocus: true,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Scansiona barcode",
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                if (value.trim().isEmpty) return;

                _processBarcode(value);

                _controller.clear(); // puliamo subito per il prossimo scan
              },
            ),
  SizedBox(height: 20),
            Text(
              "Ultimo barcode: $lastBarcode", // qui il valore cambia dinamicamente
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
                                ],
                                
                              ),
    
                    ],
                  ),
              
              
                ),
              ),
             
         

        ),
        
        // floatingActionButton: camState
        //       ? FloatingActionButton(
        //           child: const Text(
        //             "Camera off",
        //             textAlign: TextAlign.center,
        //           ),
        //           onPressed: () {
        //             setState(() {
        //               camState = false; // Disabilita la camera
        //               qr = null;
        //             });
        //           },
        //         )
        //       : null
      ),
      
    ),
    );
  }
}
