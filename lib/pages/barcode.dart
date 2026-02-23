import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:motion_toast/motion_toast.dart' as mt;
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
import 'package:mobile_scanner/mobile_scanner.dart';

class Barcodex extends StatefulWidget {
  @override
  MyHomeState createState() => MyHomeState();
}

class MyHomeState extends State<Barcodex> with SingleTickerProviderStateMixin {
  String? qr;
  String? nome = '';
  bool isCameraOn = false;
  bool errore = false;
  bool dirState = false;
  bool _isLoading = false;
  String? selectedId;
  bool? presenzaLinea;
  final FocusNode _focusNode = FocusNode();
  String? messaggioLinea;
  TextEditingController _controller = TextEditingController();
  String? lastBarcode;
  String _barcodeBuffer = "";
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  List<Map<String, dynamic>> _eltabella1 = [];
    List<Map<String, dynamic>> _eltabella2 = [];
      List<Map<String, dynamic>> _eltabella3 = [];
  List<ConnectivityResult>? connectivityRisultato;
  RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );
  final MobileScannerController controllerCam = MobileScannerController(
    autoStart: false,
  );
  Barcode? _barcode;

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
          mt.MotionToast.warning(
            title: Text(
              "ATTENZIONE!",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            width: 400, // Imposta una larghezza personalizzata
            height: 150,
            description: Text(messaggioLinea!, style: TextStyle(fontSize: 16)),
            toastDuration: Duration(seconds: 10),
         animationType: mt.AnimationType.slideInFromTop,
          ).show(context);
        } else {
          presenzaLinea = true;
          messaggioLinea = 'Connessione Attiva';
          // recheckVersion();
        }
      });
    });
  }

  Future<void> checkConnessione() async {
    connectivityRisultato = await Connectivity().checkConnectivity();

    if (connectivityRisultato!.contains(ConnectivityResult.none)) {
      setState(() {
        presenzaLinea = false;
        messaggioLinea = 'Connessione Assente!';
        mt.MotionToast.warning(
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
            animationType: mt.AnimationType.slideInFromTop,
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

  // AZIONETURNO
  Future<void> azioneQr() async {
      setState(() {
      _isLoading = true;
    
    });
    var payload = jsonEncode({"nomeConsegna": lastBarcode});
    var url = Uri.parse("${Globals.globalAPI}/api/sscc/consegna/verifica");
    print(url);
    var response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': "Bearer ${Globals.globalToken}",
      },
      body: payload,
    );
    print(response.statusCode);
    if (response.statusCode == 401) {
      showAlert(context, 'Errore Generale!');
      hideLoadingDialog(context);
    } else {
      var responseData = jsonDecode(response.body);
      hideLoadingDialog(context);
      if(responseData['successo']==true){
       _eltabella1 = List<Map<String, dynamic>>.from(
  responseData['consegna']['prodotti']
);

  // prodottiDaScansionare
  final prodottiDaScansionare =
      responseData['consegna']['prodottiDaScansionare'];

  if (prodottiDaScansionare != null &&
      prodottiDaScansionare is List &&
      prodottiDaScansionare.isNotEmpty) {

    _eltabella2 = List<Map<String, dynamic>>.from(
      prodottiDaScansionare,
    );
  }else {

  _eltabella2 = [];  // 👈 array vuoto

}

  // prodottiDaControllare
  final prodottiDaControllare =
      responseData['consegna']['prodottiDaControllare'];

  if (prodottiDaControllare != null &&
      prodottiDaControllare is List &&
      prodottiDaControllare.isNotEmpty) {

    _eltabella3 = List<Map<String, dynamic>>.from(
      prodottiDaControllare,
    );
  }else {

  _eltabella3 = [];  // 👈 array vuoto

}
      }else{
          mt.MotionToast.warning(
  title: Text(
    "ATTENZIONE!",
    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
  ),
  description: Text(
    responseData['errore'],
    style: TextStyle(fontSize: 16),
  ),
  width: 250,
  height: 100,
  toastDuration: Duration(seconds: 5),
  animationType: mt.AnimationType.slideInFromLeft, // ← usa il prefisso
).show(context);
      }
           setState(() {
      _isLoading = false;
    
    });
      // showAlert(context, "ssdfdsfsdds");
    }
  }

  // SWEET ALERT
  void showAlert(BuildContext context, String message) {
    Alert(
      context: context,
      type: AlertType.error,
      title: "ATTENZIONE",
      desc: message,
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
    // await Future.delayed(Duration(milliseconds: 1500));
   await azioneQr();
    //  hideLoadingDialog(context);
  }

  // NASCONDI LOADER
  void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
   
  }
// CODICE A BARRA
  void _processBarcode(String value) {
    setState(() {
      lastBarcode = value;
      _barcodeBuffer = "";
    });
    showLoadingDialog(context);
  }
// CAMERA
  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        print(_barcode!.displayValue);
        lastBarcode = _barcode!.displayValue;
      });
      showLoadingDialog(context);
      _toggleScanner();
    }
  }

  Future<void> _toggleScanner() async {
    if (!isCameraOn) {
      await controllerCam.start();
      await controllerCam.toggleTorch();
      isCameraOn = true;
    } else {
      await controllerCam.stop();
      await controllerCam.toggleTorch();
      isCameraOn = false;
    }
    setState(() {});
  }

  @override
  void dispose() {
    // Annulla l'iscrizione al listener di connettività per prevenire perdite di memoria
    _connectivitySubscription.cancel();
    _controller.dispose();
    _focusNode.dispose();
    controllerCam.stop();
    controllerCam.dispose();
    super.dispose();
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
            backgroundColor: Theme.of(context).primaryColor.withAlpha(180),
          ),
        ),
        body: Container(
          child: SmartRefresher(
            controller: _refreshController,
            header: WaterDropMaterialHeader(),
            onRefresh: _onRefresh,
            child: Stack(
              children: [
                _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : 
                SingleChildScrollView(
                 
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
                          child: Text(
                            "Ordine di Consegna: $lastBarcode", // qui il valore cambia dinamicamente
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),                    
                        ),
                          SizedBox(height: 10),
                            SingleChildScrollView(
                              physics: BouncingScrollPhysics(),
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                   width: MediaQuery.of(context).size.width,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(
                                      Color.fromARGB(255, 233, 230, 221)),
                                  dataRowMaxHeight: 70,
                                  columnSpacing: 30,
                                  columns: const <DataColumn>[
                                    DataColumn(
                                      label: Text(
                                        'Prodotto',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'Quantità',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    DataColumn(
                                      label: Text(
                                        'UoM',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    
                                  ],
                                  rows: _eltabella1.map((item) {
                                    // DateTime tempo =
                                    //     DateTime.parse(item['dataOra']!);
                                    return DataRow(
                                      cells: <DataCell>[
                                        DataCell(
                                          Text(
                                                  item['nome'].toString()),
                                        ),
                                        DataCell(
                                          Text(
                                                  item['quantita'].toString()),
                                        ),
                                     DataCell(
                                          Text(
                                                  item['unitaMisura'].toString()),
                                        ),
                                       
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // SECONDA TAB
                          if (_eltabella2 != null && _eltabella2.isNotEmpty) ...[
  Padding(
    padding: EdgeInsets.only(top: 10, bottom: 10),
    child: Divider(
      color: Theme.of(context).primaryColor,
      thickness: 2,
      height: 15,
    ),
  ),
  SingleChildScrollView(
    physics: BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: MediaQuery.of(context).size.width,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          Color.fromARGB(255, 233, 230, 221),
        ),
        dataRowMaxHeight: 70,
        columnSpacing: 30,
        columns: const <DataColumn>[
          DataColumn(
            label: Text(
              'Prodotto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Richiesta',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Scans.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Residua',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: _eltabella2.map((item) {
          return DataRow(
            cells: <DataCell>[
              DataCell(Text(item['prodotto'].toString())),
                 DataCell(Text(item['quantitaRichiesta'].toString())),
              DataCell(Text(item['quantitaScansionata'].toString())),
              DataCell(Text(item['quantitaResidua'].toString())),
            ],
          );
        }).toList(),
      ),
    ),
  ),
],

// TRZA TAB
                           if (_eltabella3 != null && _eltabella3.isNotEmpty) ...[
  Padding(
    padding: EdgeInsets.only(top: 10, bottom: 10),
    child: Divider(
      color: Theme.of(context).primaryColor,
      thickness: 2,
      height: 15,
    ),
  ),
  SingleChildScrollView(
    physics: BouncingScrollPhysics(),
    scrollDirection: Axis.horizontal,
    child: SizedBox(
      width: MediaQuery.of(context).size.width,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          Color.fromARGB(255, 233, 230, 221),
        ),
        dataRowMaxHeight: 70,
        columnSpacing: 30,
        columns: const <DataColumn>[
          DataColumn(
            label: Text(
              'Prodotto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'Da Controllare',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              'UoM',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: _eltabella3.map((item) {
          return DataRow(
            cells: <DataCell>[
              DataCell(Text(item['prodotto'].toString())),
              DataCell(Text(item['quantitaDaControllare'].toString())),
                 DataCell(Text(item['unitaMisura'].toString())),
            
            ],
          );
        }).toList(),
      ),
    ),
  ),
],


                        
                      ],
                    ),
                  
                ),

                MobileScanner(
                  controller: controllerCam,
                  onDetect: _handleBarcode,
                ),
              ],
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
        floatingActionButton: FloatingActionButton(
          child: const Text("Camera off", textAlign: TextAlign.center),
          onPressed: () {
            setState(() {
              _toggleScanner();
              // camState = false; // Disabilita la camera
              // qr = null;
            });
          },
        ),
      ),
    );
  }
}
