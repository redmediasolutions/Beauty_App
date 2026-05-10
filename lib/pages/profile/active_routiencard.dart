import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ActiveRoutiencard extends StatelessWidget {
  const ActiveRoutiencard({super.key});

  @override
  Widget build(BuildContext context) {
    return  Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(
          0xFFF2F0F0,
        ), // The soft gray background from the image
        borderRadius: BorderRadius.circular(35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Header Section ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Active\nRoutine",
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: const Color(0xFF5E2A66),
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('carts')
                    .doc(FirebaseAuth.instance.currentUser?.uid)
                    .collection('items')
                    .snapshots(),
                builder: (context, snapshot) {
                  int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "$count",
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: const Color(0xFF5E2A66)),
                      ),
                      Text(
                        "PRODUCTS",
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 25),

          // --- Products Grid ---
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('carts')
                .doc(FirebaseAuth.instance.currentUser?.uid)
                .collection('items')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No products in routine"));
              }

              final cartItems = snapshot.data!.docs;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cartItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, index) {
                  final data = cartItems[index].data() as Map<String, dynamic>;
                  return _buildRoutineTile(
                    data['name'] ?? 'Product',
                    data['image'] ?? '',

                    // You can add a 'timeOfDay' field to your cart items in Firestore
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

   Widget _buildRoutineTile(String name, String imageUrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: const Color(0xFF1D212C),
          ),
        ),
      
      ],
    );
  }
}