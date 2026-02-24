import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:refresh/refresh.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lete_sgam/global.dart';
import 'package:lete_sgam/pages/barcode.dart';
import 'package:lete_sgam/pages/camera.dart';
import 'package:flutter/services.dart';
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
  RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  // FUNZIONI

  // ONMOUNTED
  @override
  void initState() {
    super.initState();
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
    checkConnessione();
    _refreshController.refreshCompleted();
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
    
  }

  // NASCONDI LOADER
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final orientation = MediaQuery.of(context).orientation;
    final appBarHeight = screenHeight * 0.3;
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
                           automaticallyImplyLeading: false,
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
                          backgroundColor: Theme.of(
                            context,
                          ).primaryColor.withAlpha(180), // 50% opaco
                          elevation: 0,
                          flexibleSpace: Container(
                            padding: EdgeInsets.only(left: 12.0, bottom: 20),
                            alignment: Alignment.bottomLeft,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  "Benvenuto!",
                                  style: GoogleFonts.lato(
                                    textStyle: TextStyle(
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
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
                                      color: const Color.fromARGB(
                                        255,
                                        255,
                                        255,
                                        255,
                                      ),
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

                    Padding(
                      padding: const EdgeInsets.all(8.0),

                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 100),
                          SizedBox(
                            child: Image.asset(
                              'assets/images/logo_sgam.png',
                              fit: BoxFit.contain,
                              width: 180,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 20, bottom: 20),
                            child: Divider(
                              color: Theme.of(
                                context,
                              ).primaryColor, // Colore della linea
                              thickness: 2, // Spessore della linea
                              height:
                                  15, // Altezza complessiva del Divider (incluso padding verticale)
                            ),
                          ),
                          Column(
                            children: [
                              // SizedBox(height: 50),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => Barcodex(),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 20,
                                      child: Container(
                                        width: screenWidth * 0.4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.barcode_reader,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                size: 100.0,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                "BARCODE",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => B2(),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      elevation: 6,
                                      child: Container(
                                        width: screenWidth * 0.4,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt_rounded,
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                size: 100.0,
                                              ),

                                              SizedBox(height: 12),
                                              Text(
                                                "CAMERA(beta)",
                                                style: GoogleFonts.lato(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),

                                              // Aggiungi altri widget qui se necessario
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Spacer(),
                              Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: Text(
                                  'Versione:${Globals.version}',
                                  style: TextStyle(
                                    color: const Color.fromARGB(255, 34, 6, 6),
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
