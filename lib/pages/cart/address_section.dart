import 'package:flutter/material.dart';

class AddressSectionWidget
    extends StatelessWidget {
  final Map<String, dynamic>?
  selectedAddress;

  final VoidCallback onTap;

  const AddressSectionWidget({
    super.key,
    required this.selectedAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [
        /// HEADER
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,

          children: [
            Text(
              "DELIVERY ADDRESS",

              style: TextStyle(
                fontSize: 12,

                letterSpacing: 2,

                color: Colors.grey,
              ),
            ),

            TextButton(
              onPressed: onTap,

              child: const Text(
                "Change",
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        /// ADDRESS CARD
        GestureDetector(
          onTap: onTap,

          child: Container(
            padding:
                const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: const Color(
                0xFFF6F3F4,
              ),

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Icon(
                  Icons
                      .location_on_outlined,
                  color: Color(
                    0xFF6F0562,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child:
                      selectedAddress ==
                              null
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                const Text(
                                  "No Address Selected",

                                  style:
                                      TextStyle(
                                        fontWeight:
                                            FontWeight.w600,

                                        fontSize:
                                            15,
                                      ),
                                ),

                                const SizedBox(
                                  height:
                                      4,
                                ),

                                Text(
                                  "Tap here to add or select delivery address",

                                  style:
                                      TextStyle(
                                        color:
                                            Colors.grey[600],

                                        fontSize:
                                            13,
                                      ),
                                ),
                              ],
                            )
                          : Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                /// NAME
                                Text(
                                  selectedAddress!['name'] ??
                                      '',

                                  style:
                                      const TextStyle(
                                        fontWeight:
                                            FontWeight.bold,

                                        fontSize:
                                            15,
                                      ),
                                ),

                                const SizedBox(
                                  height:
                                      6,
                                ),

                                /// ADDRESS
                                Text(
                                  "${selectedAddress!['address']}, ${selectedAddress!['city']}",

                                  style:
                                      TextStyle(
                                        color:
                                            Colors.grey[700],
                                      ),
                                ),

                                const SizedBox(
                                  height:
                                      4,
                                ),

                                /// STATE + PINCODE
                                Text(
                                  "${selectedAddress!['state']} - ${selectedAddress!['pincode']}",

                                  style:
                                      TextStyle(
                                        color:
                                            Colors.grey[700],
                                      ),
                                ),

                                const SizedBox(
                                  height:
                                      4,
                                ),

                                /// PHONE
                                Text(
                                  selectedAddress!['phone'] ??
                                      '',

                                  style:
                                      TextStyle(
                                        color:
                                            Colors.grey[700],
                                      ),
                                ),
                              ],
                            ),
                ),

                const SizedBox(width: 8),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}