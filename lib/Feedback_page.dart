import 'package:flutter/material.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/Feedback_class.dart' as FeedbackClass;
import 'package:footprint3/utils.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  double _rating = 3.0;
  final TextEditingController _feedbackController = TextEditingController();

  void _submitFeedback() {
    final rating = _rating.toInt();
    final comment = _feedbackController.text.trim();

    if (comment.isEmpty && rating < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a comment or a rating above 1.')),
      );
      return;
    }

    addFeedItem(FeedbackClass.Feedback(
      key: '',
      rating: rating,
      comment: comment,
      clientUid: curTracker.uid,
    ));

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Thank you!"),
        content: Text("You rated us $rating star(s).\n\nComment: $comment"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );

    _feedbackController.clear();
    setState(() => _rating = 3.0);
  }

  Widget _buildStarSlider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final zoneWidth = constraints.maxWidth / 5;

        int _ratingFromDx(double dx) => (dx / zoneWidth).clamp(0, 4).floor() + 1;

        void _handleDragOrTap(Offset localPos) {
          final newRating = _ratingFromDx(localPos.dx).toDouble();
          if (newRating != _rating) {
            setState(() => _rating = newRating);
          }
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanDown: (d) => _handleDragOrTap(d.localPosition),
          onPanUpdate: (d) => _handleDragOrTap(d.localPosition),
          onTapUp: (d) => _handleDragOrTap(d.localPosition),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (index) {
              return Icon(
                index < _rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 40,
              );
            }),
          ),
        );
      },
    );
  }

  Future<String> getClientName(String clientUid) async {
    var client = await getTracker(clientUid);
    return '${client?.firstname} ${client?.lastname}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text(
            'Feedback',
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          backgroundColor: mainOrange,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const Text(
                    'How would you rate your experience?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStarSlider(),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _feedbackController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Additional comments (optional)',
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.amber, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _submitFeedback,
                    icon: const Icon(Icons.send),
                    label: const Text("Submit Feedback"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Divider(thickness: 1.5),
                  const Text(
                    'Previous Feedbacks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  StreamBuilder<List<FeedbackClass.Feedback>>(
                    stream: streamAllFeedItems(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('No feedback yet.'));
                      }

                      final feedbacks = snapshot.data!;
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: feedbacks.length,
                        itemBuilder: (context, index) {
                          final fb = feedbacks[index];
                          return FutureBuilder<String>(
                            future: getClientName(fb.clientUid),
                            builder: (context, nameSnapshot) {
                              if (nameSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (nameSnapshot.hasError) {
                                return const Center(child: Text('Error loading client info.'));
                              } else if (nameSnapshot.hasData) {
                                return Card(
                                  child: ListTile(
                                    leading: const Icon(Icons.star, color: Colors.amber),
                                    title: Text('${fb.rating} star(s)'),
                                    subtitle: Text(fb.comment ?? 'No comment'),
                                    trailing: Text(nameSnapshot.data ?? 'Unknown Client'),
                                  ),
                                );
                              } else {
                                return const Center(child: Text('No feedback yet.'));
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
