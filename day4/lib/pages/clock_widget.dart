import 'package:flutter/material.dart';
import 'dart:async';
import '../services/get_clock.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
  Timer? timer;
  late DateTime now_ = DateTime.now();
  Map<String, dynamic>? timeData; //for Asia/Ktm
  Map<String, dynamic>? dataLondon; //for Europe/London
  Map<String, dynamic>? userInputData;

  //Already defined date/time
  void loadTime(String zone) async {
    final data = await GetClock().fetchTime(zone: zone);
    setState(() {
      if (zone == 'Europe/London') {
        dataLondon = data;
      } else if (zone == 'Asia/Kathmandu') {
        timeData = data;
      } else {
        userInputData = data;
      }
    });
  }

  //for user input country
  void showCountryPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(225),
      //Buildcontext for position , themes,etc
      builder: (BuildContext build) {
        return SimpleDialog(
          backgroundColor: const Color.fromARGB(255, 50, 50, 50),
          title: Text(
            'Select Time Zone',
            style: TextStyle(color: Colors.white, fontSize: 25),
          ),
          //<Widget> tells the children are only for widgets
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                loadTime('America/New_York');
                Navigator.pop(context);
              },
              child: const Text(
                'America/New_York',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                loadTime('Asia/Tokyo');
                Navigator.pop(context);
              },
              child: const Text(
                'Asia/Tokyo',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SimpleDialogOption(
              onPressed: () {
                loadTime('Australia/Sydney');
                Navigator.pop(context);
              },
              child: const Text(
                'Australia/Sydney',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  //we can add for user input date
  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        now_ = DateTime.now();
        loadTime('Asia/Kathmandu');
        loadTime('Europe/London');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    int hour12 = now_.hour > 12
        ? now_.hour - 12
        : (now_.hour == 0 ? 12 : now_.hour);
    String period = now_.hour >= 12 ? 'PM' : 'AM';
    String minute = now_.minute.toString().padLeft(2, '0');
    String second = now_.second.toString().padLeft(2, '0');

    return Scaffold(
      body: Container(
        color: const Color.fromARGB(255, 21, 21, 21),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$hour12:$minute:$second',
                    style: TextStyle(
                      fontSize: 70,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  Text(
                    ' $period',
                    style: TextStyle(
                      fontSize: 20,
                      color: const Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                ],
              ),
              Text(
                timeData != null ? '${timeData!['timeZone']}' : '---------',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              Text(
                timeData != null
                    ? DateFormat('EEEE, d MMMM').format(
                        DateFormat('MM/dd/yyyy').parse(timeData!['date']),
                      )
                    : '---------',
                style: TextStyle(
                  fontSize: 15,
                  color: const Color.fromARGB(255, 255, 255, 255),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(height: 50),
              buildClockWidget(context, dataLondon),
              SizedBox(height: 10),
              if (userInputData != null)
                buildClockWidget(context, userInputData),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showCountryPicker(context);
        },
        backgroundColor: const Color.fromARGB(255, 29, 32, 34),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

//Buildcontext to get the size of the screen
Widget buildClockWidget(
  BuildContext context,
  Map<String, dynamic>? widgetData,
) {
  return Container(
    height: 110,
    width: MediaQuery.of(context).size.width - 20,
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 50, 50, 50),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: EdgeInsets.fromLTRB(10, 10, 20, 0),
              child: Column(
                children: [
                  Text(
                    widgetData != null
                        ? '${widgetData['timeZone']}'
                        : '---------',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Center(
                    child: Text(
                      widgetData != null
                          ? DateFormat('EEEE, d MMMM').format(
                              DateFormat(
                                'MM/dd/yyyy',
                              ).parse(widgetData['date']),
                            )
                          : '---------',
                      style: TextStyle(
                        color: const Color.fromARGB(255, 200, 200, 200),
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    widgetData != null
                        ? DateFormat('yyyy').format(
                            DateFormat('MM/dd/yyyy').parse(widgetData['date']),
                          )
                        : '---------',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 200, 200, 200),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              margin: EdgeInsets.fromLTRB(0, 35, 10, 0),
              child: Center(
                child: Text(
                  widgetData != null ? widgetData['time'] : '-----',
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}
