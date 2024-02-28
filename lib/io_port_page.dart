import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class IOPortPage extends StatefulWidget {
  const IOPortPage({Key? key, required this.portName}) : super(key: key);

  final String portName;

  @override
  State<IOPortPage> createState() => _IOPortPageState(portName);
}

class _IOPortPageState extends State<IOPortPage> {
  final String portName;
  late SerialPort port;
  late SerialPortReader reader;

  FocusNode keepFocus = FocusNode();

  List<String> ioBuffer = [];
  List<String> io_Buffer = <String>[];

  TextEditingController inputData = TextEditingController();

  _IOPortPageState(this.portName);

  @override
  void initState() {
    super.initState();

    try {
      port = SerialPort(portName);
      port.openReadWrite();
    } catch (e, _) {
      print("----------  There is no port ---------\n ${portName}");
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    reader = SerialPortReader(port, timeout: 10);
    String stringData;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.portName),
        backgroundColor: const Color.fromARGB(247, 13, 16, 20),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 1, 9, 22),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverOverlapAbsorber(
                      handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                          context),
                    ),
                  ];
                },
                body: RawScrollbar(
                  thumbColor: Colors.amber,
                  radius: const Radius.circular(20),
                  thickness: 5,
                  child: Scrollbar(
                    child: StreamBuilder(
                      stream: reader.stream.map((data) {
                        final l = data
                            .map((e) => e.toRadixString(16).toUpperCase())
                            .toList();
                        //stringData = String.fromCharCodes(data);
                        stringData = l.fold('', (p, e) => p + ' ' + e);
                        stringData.replaceAll('\r', "");
                        stringData.replaceAll('\n', "");
                        print("read: $stringData");
                        io_Buffer.add("# $stringData");
                      }),
                      builder: ((context, snapshot) {
                        return ListView.builder(
                          reverse: true,
                          itemCount: io_Buffer.length,
                          itemBuilder: (BuildContext context, int index) {
                            int reversedIndex = io_Buffer.length - 1 - index;
                            // int reversedIndex = index;
                            return Container(
                              constraints: const BoxConstraints(maxHeight: 50),
                              child: SelectableText(
                                ' ${io_Buffer[reversedIndex]}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 236, 238, 242),
                borderRadius: BorderRadius.circular(20),
              ),
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          autofocus: true,
                          focusNode: keepFocus,
                          style: const TextStyle(color: Colors.blue),
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            labelText: 'Type command',
                            suffixIcon: IconButton(
                              onPressed: () {
                                inputData.clear();
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ),
                          controller: inputData,
                          onSubmitted: (str) {
                            if (inputData.text.isEmpty) {
                              setState(() => Null);
                            } else {
                              setState(
                                () async {
                                  Uint8List data = Uint8List.fromList(
                                      inputData.text.codeUnits);
                                  await port.write(data);
                                  print("write : $inputData");
                                  // port.write(Uint8List.fromList(" ".codeUnits));
                                  // port.write(inputData.text);
                                  // port.write(" ");
                                  // inputBuffer.add(inputData.text);

                                  inputData.clear();
                                },
                              );
                              inputData.clear();
                              keepFocus.requestFocus();
                            }
                          },
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Container(
                          width: 50,
                          margin: const EdgeInsets.only(left: 20, right: 20),
                          child: MaterialButton(
                            child: const Icon(Icons.send),
                            onPressed: () {
                              if (inputData.text.isEmpty) {
                                setState(() {
                                  Null;
                                });
                              } else {
                                setState(() {
                                  ioBuffer.add(inputData.text);
                                  inputData.clear();
                                });
                                keepFocus.requestFocus();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        Expanded(
                          child: TextButton(
                              onPressed: () {
                                Uint8List data = Uint8List.fromList([0x02]);

                                port.write(data);
                              },
                              child: Text("รับแบงค์(02)")),
                        ),
                        Expanded(
                          child: TextButton(
                              onPressed: () {
                                Uint8List data = Uint8List.fromList([0x30]);

                                port.write(data);
                              },
                              child: Text("Reset(30)")),
                        ),
                        Expanded(
                          child: TextButton(
                              onPressed: () {
                                Uint8List data = Uint8List.fromList([0x5B]);

                                print(data);
                                port.write(data);
                              },
                              child: Text("Request(5B)")),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
