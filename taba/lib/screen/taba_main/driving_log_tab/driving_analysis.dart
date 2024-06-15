import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class DrivingAnalysis extends StatefulWidget {
  final int drivingScore;

  const DrivingAnalysis({super.key, required this.drivingScore});

  @override
  _DrivingAnalysisState createState() => _DrivingAnalysisState();
}

class _DrivingAnalysisState extends State<DrivingAnalysis>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2), // 애니메이션 지속 시간
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: widget.drivingScore.toDouble())
        .animate(_controller)
      ..addListener(() {
        setState(() {});
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("운전분석"),
      ),
      body: Center(
        child: SfRadialGauge(
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 100,
              showLabels: false,
              showTicks: false,
              axisLineStyle: const AxisLineStyle(
                thickness: 0.2,
                cornerStyle: CornerStyle.bothCurve,
                color: Color(0xFFE9EDF0),
                thicknessUnit: GaugeSizeUnit.factor,
              ),
              pointers: <GaugePointer>[
                RangePointer(
                  value: _animation.value,
                  cornerStyle: CornerStyle.bothCurve,
                  width: 0.2,
                  sizeUnit: GaugeSizeUnit.factor,
                  color: const Color(0xFF14314A),
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  positionFactor: 0.1,
                  angle: 90,
                  widget: Text(
                    '${_animation.value.toStringAsFixed(0)}점',
                    style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
