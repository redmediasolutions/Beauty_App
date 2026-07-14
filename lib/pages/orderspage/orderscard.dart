import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderCard extends StatelessWidget {
  final int orderId;
  final String date;
  final String status;
  final Color statusColor;
  final Color iconBg;
  final String items;
  final String amount;
  final String delivery;
  final bool showTrack;
  final bool showReorder;
  final Icon odericon;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.date,
    required this.status,
    required this.statusColor,
    required this.iconBg,
    required this.items,
    required this.amount,
    required this.delivery,
    this.showTrack = false,
    this.showReorder = false,
    required this.odericon,
  });

  static const Color primaryColor =
      Color(0xFF6F0562);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          /// HEADER
          Row(
            children: [
              Container(
                width: 50,
                height: 50,

                decoration: BoxDecoration(
                  color:
                      primaryColor.withValues(
                    alpha: 0.08,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),

                child: Center(
                  child: Icon(
                    odericon.icon,
                    color: primaryColor,
                    size: 22,
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
                      "Order #$orderId",

                      style:
                          const TextStyle(
                        fontSize: 15,
                        fontWeight:
                            FontWeight.w700,
                        color:
                            Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      date,

                      style: TextStyle(
                        fontSize: 12,
                        color: Colors
                            .grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),

                decoration: BoxDecoration(
                  color: statusColor
                      .withValues(alpha: 0.10),

                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),

                child: Text(
                  status.toUpperCase(),

                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          /// INFO SECTION
          Row(
            children: [
              _info(
                "Total Items",
                items,
              ),

              _info(
                "Amount",
                "₹$amount",
              ),
            ],
          ),

          if (delivery.isNotEmpty) ...[
            const SizedBox(height: 14),

            Container(
              padding:
                  const EdgeInsets.all(12),

              decoration: BoxDecoration(
                color:
                    const Color(0xFFF8EEF7),

                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),

              child: Row(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 18,
                    color: primaryColor,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: Text(
                      delivery,

                      style:
                          const TextStyle(
                        fontSize: 13,
                        color:
                            Colors.black87,
                        fontWeight:
                            FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          Divider(
            color: Colors.grey.shade200,
            height: 1,
          ),

          const SizedBox(height: 18),

          /// BUTTONS
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,

                  child: ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(
                      elevation: 0,

                      backgroundColor:
                          primaryColor,

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),

                    onPressed: () {
                      context.pushNamed(
                        'orderDetail',
                        pathParameters: {
                          'id':
                              orderId.toString(),
                        },
                      );
                    },

                    child: const Text(
                      "VIEW DETAILS",

                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            FontWeight.w600,
                        letterSpacing:
                            0.8,
                      ),
                    ),
                  ),
                ),
              ),

              if (showTrack) ...[
                const SizedBox(width: 10),

                SizedBox(
                  height: 50,

                  child: OutlinedButton(
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          primaryColor,

                      side: const BorderSide(
                        color: primaryColor,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),

                    onPressed: () {},

                    child: const Text(
                      "TRACK",
                    ),
                  ),
                ),
              ],

              if (showReorder) ...[
                const SizedBox(width: 10),

                SizedBox(
                  height: 50,

                  child: OutlinedButton(
                    style:
                        OutlinedButton.styleFrom(
                      foregroundColor:
                          primaryColor,

                      side: const BorderSide(
                        color: primaryColor,
                      ),

                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(
                          30,
                        ),
                      ),
                    ),

                    onPressed: () {},

                    child: const Text(
                      "REORDER",
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(
    String title,
    String value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title.toUpperCase(),

            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              letterSpacing: 1,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            value,

            style: const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}