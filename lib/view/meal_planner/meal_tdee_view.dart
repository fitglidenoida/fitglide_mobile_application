import 'package:flutter/material.dart';
import 'package:fitglide_mobile_application/services/bmr_tdee_service.dart';
import 'package:fitglide_mobile_application/common/colo_extension.dart';

class MealTdeeView extends StatefulWidget {
  const MealTdeeView({super.key});

  @override
  State<MealTdeeView> createState() => _MealTdeeViewState();
}

class _MealTdeeViewState extends State<MealTdeeView> {
  late Future<Map<String, double>> tdeeOptionsFuture;

  @override
  void initState() {
    super.initState();
    // Fetch TDEE options using a sample BMR; adjust based on user data in practice
    final tdeeService = BmrTdeeService();
    tdeeOptionsFuture = Future.value(tdeeService.calculateTDEEOptions(2000, 'sedentary'));
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(gradient: LinearGradient(colors: TColor.primaryG)),
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              centerTitle: true,
              elevation: 0,
              leading: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: TColor.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(
                    "assets/img/black_btn.png",
                    width: 15,
                    height: 15,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: const Text(
                "TDEE Overview",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ];
        },
        body: Container(
          decoration: BoxDecoration(
            color: TColor.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: FutureBuilder<Map<String, double>>(
              future: tdeeOptionsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tdeeOptions = snapshot.data!;
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 50,
                            height: 4,
                            decoration: BoxDecoration(
                              color: TColor.gray.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: media.width * 0.05),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          "Your TDEE Goals",
                          style: TextStyle(
                            color: TColor.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(height: media.width * 0.05),
                      _buildTdeeSection(
                        context,
                        "Maintain Weight",
                        tdeeOptions['maintain']!,
                      ),
                      _buildTdeeSection(
                        context,
                        "Weight Loss",
                        tdeeOptions['loss_250g']!,
                        tdeeOptions['loss_500g']!,
                      ),
                      _buildTdeeSection(
                        context,
                        "Weight Gain",
                        tdeeOptions['gain_250g']!,
                        tdeeOptions['gain_500g']!,
                      ),
                      SizedBox(height: media.width * 0.25),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTdeeSection(BuildContext context, String title, double value1, [double? value2]) {
    var media = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: TColor.primaryG),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: TColor.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _buildTdeeRow("Goal 1", value1),
              if (value2 != null) ...[
                const SizedBox(height: 8),
                _buildTdeeRow("Goal 2", value2),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTdeeRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: TColor.white, fontSize: 14),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: TColor.lightGray.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${value.toStringAsFixed(1)} kcal',
            style: TextStyle(color: TColor.white, fontSize: 14),
          ),
        ),
      ],
    );
  }
}