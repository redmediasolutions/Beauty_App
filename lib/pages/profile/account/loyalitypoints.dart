import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoyaltyPointsPage extends StatelessWidget {
  const LoyaltyPointsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Defining the brand background color

    return Scaffold(
      backgroundColor: Colors.white, // Deep purple background
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Seamless with background
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () {
            if (context.canPop()) {
              context.pop(); // This is the GoRouter-friendly way to go back
            } else {
              context.go(
                '/profile',
              ); // Fallback: send them to the profile route if no history
            }
          },
        ),
        title: Text(
          "Loyalty Rewards",
            style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -1.5,
                                color: Colors.black,
                              ),
                        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            // --- COMPONENT 1: Gradient Balance Card ---
            _buildBalanceCard(),

            const SizedBox(height: 25),

            // --- COMPONENT 2: Redeem Button (Matching your image style) ---
            _buildRedeemButton(context),

            const SizedBox(height: 20),

            // --- COMPONENT 3: Points History (Empty placeholder for now) ---
            _buildHistoryHeader(),
            const SizedBox(height: 10),
            _buildTransactionHistory(),

            const SizedBox(height: 50), // Bottom padding
          ],
        ),
      ),
    );
  }

  // --- WIDGET 1: Dynamic Balance Card with Gradient ---
  Widget _buildBalanceCard() {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('walletTransactions')
        .snapshots(),
    builder: (context, txSnapshot) {

      if (!txSnapshot.hasData) {
        return const SizedBox();
      }

     double confirmedAmount = 0;
double pendingAmount = 0;

for (final doc in txSnapshot.data!.docs) {

  final data =
      doc.data()
          as Map<String, dynamic>;

  final amount =
      ((data['amount'] ?? 0) as num)
          .toDouble();

  final status =
      data['status'] ?? '';

  final source =
      data['source'] ?? '';

  final type =
      data['type'] ?? 'credit';

  /// AVAILABLE BALANCE

  if (status == 'credited') {

    if (type == 'credit') {
      confirmedAmount += amount;
    }

    if (type == 'debit') {
      confirmedAmount -= amount;
    }
  }

  /// Once approved, remove it from balance immediately

  if (status == 'approved' &&
      type == 'debit') {
    confirmedAmount -= amount;
  }

  /// Pending referral rewards only

  if (status == 'pending' &&
      type == 'credit' &&
      source != 'withdrawal_request') {

    pendingAmount += amount;
  }
}

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6F0562),
              Color(0xFF8C277B),
            ],
          ),
          borderRadius:
              BorderRadius.circular(32),
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              "AVAILABLE REWARDS",
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              "₹${confirmedAmount.toStringAsFixed(2)}",
              style: GoogleFonts.lora(
                color: Colors.white,
                fontSize: 46,
                fontWeight:
                    FontWeight.w500,
              ),
            ),

            if (pendingAmount > 0) ...[

  const SizedBox(height: 20),

  Text(
    "PENDING REWARDS",
    style: GoogleFonts.inter(
      color: Colors.white70,
      fontSize: 12,
      letterSpacing: 2,
      fontWeight: FontWeight.w600,
    ),
  ),

  const SizedBox(height: 12),

  Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    ),
    decoration: BoxDecoration(
<<<<<<< Updated upstream
      color: Colors.white.withOpacity(0.15),
=======
      color: Colors.white.withValues(alpha: 0.15),
>>>>>>> Stashed changes
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      "₹${pendingAmount.toStringAsFixed(2)} Awaiting Delivery Confirmation",
      style: GoogleFonts.inter(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    ),
  ),
],
            const SizedBox(height: 25),

            Row(
              children: [

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color: Colors.white
<<<<<<< Updated upstream
                        .withOpacity(0.15),
=======
                        .withValues(alpha: 0.15),
>>>>>>> Stashed changes
                    borderRadius:
                        BorderRadius
                            .circular(30),
                  ),
                  child: Text(
                    "GladSkin Member",
                    style:
                        GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),

                const Spacer(),

                const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

  // --- WIDGET 2: Shadowed Redeem Button (Specific to image design) ---
Widget _buildRedeemButton(BuildContext context) {
  final uid = FirebaseAuth.instance.currentUser?.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('walletTransactions')
        .snapshots(),
    builder: (context, snapshot) {

      double confirmedRewards = 0;

      if (snapshot.hasData) {
        for (final doc in snapshot.data!.docs) {

          final data =
              doc.data()
                  as Map<String, dynamic>;

          final amount =
              ((data['amount'] ?? 0) as num)
                  .toDouble();

          final status =
              data['status'] ?? '';

          final type =
              data['type'] ?? 'credit';

          if (status == 'credited') {

            if (type == 'credit') {
              confirmedRewards += amount;
            }

            if (type == 'debit') {
              confirmedRewards -= amount;
            }
          }

          if (
              (status == 'pending' ||
                  status == 'approved') &&
              type == 'debit') {
            confirmedRewards -= amount;
          }
        }
      }

      final canRedeem =
          confirmedRewards >= 1000;

      return SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: canRedeem
              ? () => _showRedeemDialog(
                    context,
                    confirmedRewards,
                  )
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: canRedeem
                ? const Color(0xFF6F0562)
                : Colors.grey.shade300,
            disabledBackgroundColor:
                Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(30),
            ),
          ),
          child: Text(
            canRedeem
                ? "REDEEM REWARDS"
                : "MIN ₹1000 REQUIRED",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showRedeemDialog(
  BuildContext context,
  double availableAmount,
) async {

  final uid =
      FirebaseAuth.instance.currentUser!.uid;

  final upiController =
      TextEditingController();

  final amountController =
      TextEditingController(
    text:
        availableAmount.toStringAsFixed(0),
  );

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(30),
      ),
    ),
    builder: (context) {

      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom:
              MediaQuery.of(context)
                      .viewInsets
                      .bottom +
                  20,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {

            return Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [

                Text(
                  "Redeem Rewards",
                  style:
                      GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight:
                        FontWeight.w700,
                        
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller:
                      amountController,
                  keyboardType:
                      TextInputType.number,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "Amount",
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 15),

                TextField(
                  controller:
                      upiController,
                  decoration:
                      const InputDecoration(
                    labelText:
                        "UPI ID",
                    border:
                        OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width:
                      double.infinity,
                  height: 55,
                  child:
                      ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(
                        0xFF6F0562,
                      ),
                    ),
                    onPressed:
                        () async {

                      final amount =
                          double.tryParse(
                                amountController
                                    .text,
                              ) ??
                              0;

                      if (
                          amount <
                              1000 ||
                          amount >
                              availableAmount) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Invalid amount",
                            ),
                          ),
                        );

                        return;
                      }

                      if (upiController
                          .text
                          .trim()
                          .isEmpty) {

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Enter UPI ID",
                            ),
                          ),
                        );

                        return;
                      }

                      final withdrawalRef =
                          FirebaseFirestore
                              .instance
                              .collection(
                                  'rewardWithdrawals')
                              .doc();

                      final txRef =
                          FirebaseFirestore
                              .instance
                              .collection(
                                  'Users')
                              .doc(uid)
                              .collection(
                                  'walletTransactions')
                              .doc();

                      final batch =
                          FirebaseFirestore
                              .instance
                              .batch();

                      batch.set(
                        withdrawalRef,
                        {

                          'uid': uid,

                          'amount':
                              amount,

                          'upiId':
                              upiController
                                  .text
                                  .trim(),

                          'status':
                              'pending',

                          'createdAt':
                              FieldValue
                                  .serverTimestamp(),
                        },
                      );

                      batch.set(
                        txRef,
                        {

                          'type':
                              'debit',

                          'source':
                              'withdrawal_request',

                          'amount':
                              amount,

                          'status':
                              'pending',

                          'withdrawalId':
                              withdrawalRef.id,

                          'createdAt':
                              FieldValue
                                  .serverTimestamp(),
                        },
                      );

                      await batch
                          .commit();

                      if (context
                          .mounted) {

                        Navigator.pop(
                            context);

                        ScaffoldMessenger.of(
                                context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Withdrawal request submitted",
                            ),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "SUBMIT REQUEST",
                      style: TextStyle(
                        color: Colors.white
                      )
                    ),
                  ),
                ),

                const SizedBox(
                    height: 15),
              ],
            );
          },
        ),
      );
    },
  );
}
  // --- WIDGET 3: History Header ---
  Widget _buildHistoryHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "POINTS HISTORY",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const Icon(Icons.filter_list_outlined, color: Colors.white60, size: 18),
      ],
    );
  }

  // --- WIDGET 4: Empty History Placeholder ---
  Widget _buildTransactionHistory() {
  final uid =
      FirebaseAuth.instance.currentUser?.uid;

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('Users')
        .doc(uid)
        .collection('walletTransactions')
        .orderBy(
          'createdAt',
          descending: true,
        )
        .snapshots(),
    builder: (context, snapshot) {

      if (!snapshot.hasData) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }

      if (snapshot.data!.docs.isEmpty) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            vertical: 40,
          ),
          child: Column(
            children: [

              Icon(
                Icons.workspace_premium_outlined,
                size: 42,
                color: Colors.grey.shade400,
              ),

              const SizedBox(height: 12),

              Text(
                "No rewards yet",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "Start referring friends to earn rewards.",
                style: GoogleFonts.inter(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children:
            snapshot.data!.docs.map((doc) {

         final data =
    doc.data() as Map<String, dynamic>;

final amount =
    ((data['amount'] ?? 0) as num)
        .toDouble();

final status =
    data['status'] ?? '';

final source =
    data['source'] ?? '';

final orderId =
    data['orderId']?.toString() ?? '';

final type =
    data['type'] ?? 'credit';

final createdAt =
    data['createdAt'] as Timestamp?;

String title;
IconData icon;

switch (source) {

  case 'referral_reward':
    title = 'Referral Reward';
    icon = Icons.workspace_premium;
    break;

  case 'withdrawal_request':
    title = 'Withdrawal Request';
    icon = Icons.account_balance_wallet_outlined;
    break;

  case 'withdrawal_approved':
    title = 'Withdrawal Paid';
    icon = Icons.check_circle_outline;
    break;

  case 'withdrawal_rejected':
    title = 'Withdrawal Rejected';
    icon = Icons.cancel_outlined;
    break;

  default:
    title = 'Reward Credit';
    icon = Icons.workspace_premium;
}

String statusText;

switch (status) {
  case 'credited':
    statusText = 'CONFIRMED';
    break;

  case 'approved':
    statusText = 'APPROVED';
    break;

  case 'rejected':
    statusText = 'REJECTED';
    break;

  default:
    statusText = 'PENDING';
}

final isDebit = type == 'debit';

final amountColor =
    isDebit
        ? Colors.red
        : const Color(0xFF6F0562);

final statusColor =
    status == 'credited'
        ? Colors.green
        : status == 'approved'
            ? Colors.blue
            : status == 'rejected'
                ? Colors.red
                : Colors.orange;
          

          

          return Container(
  margin: const EdgeInsets.only(
    bottom: 12,
  ),
  padding: const EdgeInsets.all(18),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius:
        BorderRadius.circular(20),
    border: Border.all(
      color: Colors.grey.shade200,
    ),
  ),
  child: Row(
    children: [

      Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(
            0xFF6F0562,
<<<<<<< Updated upstream
          ).withOpacity(0.08),
=======
          ).withValues(alpha: 0.08),
>>>>>>> Stashed changes
          borderRadius:
              BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(
            0xFF6F0562,
          ),
        ),
      ),

      const SizedBox(width: 14),

      Expanded(
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight:
                    FontWeight.w600,
                color:
                    Colors.black87,
              ),
            ),

            const SizedBox(height: 4),

            if (orderId.isNotEmpty)
              Text(
                'Order #$orderId',
                style:
                    GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

            if (createdAt != null)
              Text(
                '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}',
                style:
                    GoogleFonts.inter(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),

      Column(
        crossAxisAlignment:
            CrossAxisAlignment.end,
        children: [

          Text(
            isDebit
                ? '- ₹${amount.toStringAsFixed(2)}'
                : '+ ₹${amount.toStringAsFixed(2)}',
            style:
                GoogleFonts.inter(
              fontSize: 16,
              fontWeight:
                  FontWeight.w700,
              color:
                  amountColor,
            ),
          ),

          const SizedBox(height: 6),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration:
                BoxDecoration(
              color: statusColor
<<<<<<< Updated upstream
                  .withOpacity(0.10),
=======
                  .withValues(alpha: 0.10),
>>>>>>> Stashed changes
              borderRadius:
                  BorderRadius.circular(
                      30),
            ),
            child: Text(
              statusText,
              style:
                  GoogleFonts.inter(
                color:
                    statusColor,
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
);
        }).toList(),
      );
    },
  );
}
}
