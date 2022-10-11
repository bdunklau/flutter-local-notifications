///
///
/// Copyright (c) 2022 Razeware LLC
/// Permission is hereby granted, free of charge, to any person
/// obtaining a copy of this software and associated documentation
/// files (the "Software"), to deal in the Software without
/// restriction, including without limitation the rights to use,
/// copy, modify, merge, publish, distribute, sublicense, and/or
/// sell copies of the Software, and to permit persons to whom
/// the Software is furnished to do so, subject to the following
/// conditions:

/// The above copyright notice and this permission notice shall be
/// included in all copies or substantial portions of the Software.

/// Notwithstanding the foregoing, you may not use, copy, modify,
/// merge, publish, distribute, sublicense, create a derivative work,
/// and/or sell copies of the Software in any work that is designed,
/// intended, or marketed for pedagogical or instructional purposes
/// related to programming, coding, application development, or
/// information technology. Permission for such use, copying,
/// modification, merger, publication, distribution, sublicensing,
/// creation of derivative works, or sale is expressly withheld.

/// This project and source code may use libraries or frameworks
/// that are released under various Open-Source licenses. Use of
/// those libraries and frameworks are governed by their own
/// individual licenses.

/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
/// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
/// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
/// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
/// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
/// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
/// DEALINGS IN THE SOFTWARE.
///
///

import 'dart:async';

import 'package:flutter/material.dart';
import '../styles.dart';
import 'timer_panel.dart';

const int kWorkDuration = 1500; // production: 25 minutes
const int kRestDuration = 300; // production: 300 (5 minutes)
const int kLongRestDuration = 900; // production: 900 (15 minutes)
const int kLongRestInterval = 4; // 4 short rest and then 1 long rest

enum PomodoroState {
  none,
  beingWork,
  atWork,
  beginRest,
  atRest,
}

class PomodoroTimer extends StatefulWidget {
  final _state = _PomodoroTimerState();
  PomodoroTimer({Key? key}) : super(key: key);

  void setRemainTime(int seconds, {Color color = Colors.white}) =>
      _state.setRemainTime(seconds, color: color);

  void changeState(PomodoroState state) {
    if (state == PomodoroState.beingWork) {
      _state.enterBeginWork();
    } else if (state == PomodoroState.beginRest) {
      _state.enterBeginRest();
    } else if (state == PomodoroState.atWork) {
      _state.enterAtWork();
    } else if (state == PomodoroState.atRest) {
      _state.enterAtRest();
    }
  }

  @override
  // ignore: no_logic_in_create_state
  State<PomodoroTimer> createState() => _state;
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  PomodoroState _state = PomodoroState.none;
  int remainTime = 0; // Second
  int pomodoroCount = 0;
  Color timerBgColor = kColorLightRed;
  Color mainColor = kColorRed;

  String subTitle = '';
  String buttonCaption = 'buttonCaption';

  Timer? _timer;
  int _endTime = -1;

  @override
  void initState() {
    super.initState();
    enterBeginWork();
  }

  // ------- Widget Logic --------------
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: mainColor,
      child: Column(
        children: [
          const Spacer(),
          _buildTitle(),
          const Spacer(),
          _buildSubTitle(),
          const SizedBox(height: 15),
          TimerPanel(
            remainTime: remainTime,
            bgColor: timerBgColor,
          ),
          const SizedBox(height: 5),
          _buildTimerButton(),
          const Spacer(flex: 6),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text('Pomodoro Timer', style: kTimerTitleTextStyle);
  }

  Widget _buildSubTitle() {
    return Text(subTitle, style: kTimerSubTitleTextStyle);
  }

  Widget _buildTimerButton() {
    return TextButton(
      onPressed: () => onButtonClicked(),
      child: Container(
        width: 300,
        height: 50,
        color: kColorLightGray,
        child: Center(
            child: Text(buttonCaption,
                style: TextStyle(
                  fontFamily: kMainFont,
                  fontSize: 20.0,
                  color: mainColor,
                ))),
      ),
    );
  }

  // ------- Button  Logic --------------
  void onButtonClicked() {
    debugPrint('onButtonClicked is called');
    if (_state == PomodoroState.beingWork) {
      enterAtWork();
    } else if (_state == PomodoroState.atWork) {
      // Discard
      // Next state: beingWork
      // #1
      _endAtWork(false);
    } else if (_state == PomodoroState.beginRest) {
      enterAtRest();
    } else if (_state == PomodoroState.atRest) {
      // Discard
      // Next state: beingWork
      _endAtRest();
    }
  }

  // ------- Utility --------------
  bool shouldHaveLongBreak() {
    return pomodoroCount > 0 && pomodoroCount % kLongRestInterval == 0;
  }

  // ------- State  Logic --------------
  void enterBeginWork() {
    _state = PomodoroState.beingWork;
    setState(() {
      remainTime = kWorkDuration;
      timerBgColor = kColorLightRed;
      mainColor = kColorRed;
      subTitle = 'Start to work';
      buttonCaption = 'START WORK';
    });
  }

  void enterBeginRest() {
    _state = PomodoroState.beginRest;
    final longBreak = shouldHaveLongBreak();
    setState(() {
      remainTime = longBreak ? kLongRestDuration : kRestDuration;
      timerBgColor = kColorLightGreen;
      mainColor = kColorGreen;
      subTitle = longBreak ? 'Let\'s take a long break' : 'Let\'s take a break';
      buttonCaption = 'START REST';
    });
  }

  void enterAtWork() {
    _state = PomodoroState.atWork;
    setState(() {
      remainTime = kWorkDuration;
      timerBgColor = kColorLightRed;
      mainColor = kColorRed;
      subTitle = 'Work in progress';
      buttonCaption = 'DISCARD';
    });

    // Define the endtime
    _endTime = DateTime.now().millisecondsSinceEpoch + remainTime * 1000;
    _startTimer();
  }

  void enterAtRest() {
    _state = PomodoroState.atRest;
    final longBreak = shouldHaveLongBreak();
    setState(() {
      remainTime = longBreak ? kLongRestDuration : kRestDuration;
      timerBgColor = kColorLightGreen;
      mainColor = kColorGreen;
      subTitle = 'Taking break';
      buttonCaption = 'DISCARD';
    });

    _endTime = DateTime.now().millisecondsSinceEpoch + remainTime * 1000;
    _startTimer();
  }

  // ------- Timer Logic --------------
  void _startTimer() {
    if (remainTime == 0) {
      return;
    }

    if (_timer != null) {
      _timer!.cancel();
    }

    const oneSec = Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (timer) {
      final remainTime = _calculateRemainTime();
      setRemainTime(remainTime);
      if (remainTime <= 0) {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    if (_state == PomodoroState.atWork) {
      _endAtWork(true);
    } else if (_state == PomodoroState.atRest) {
      _endAtRest();
    }
  }

  void _endAtRest() {
    _timer?.cancel();
    //
    enterBeginWork();
  }

  void _endAtWork(bool isCompleted) {
    if (isCompleted) {
      pomodoroCount++;
    }
    _timer?.cancel();
    enterBeginRest();
  }

  int _calculateRemainTime() {
    final timeDiff = _endTime - DateTime.now().millisecondsSinceEpoch;
    var result = (timeDiff / 1000).ceil();
    if (result < 0) {
      result = 0;
    }
    return result.toInt();
  }

  void setRemainTime(int seconds, {Color color = Colors.white}) {
    setState(() {
      remainTime = seconds;
    });
  }
}
