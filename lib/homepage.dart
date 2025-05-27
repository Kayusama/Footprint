import 'package:flutter/material.dart';
import 'package:footprint3/AppDrawer.dart';
import 'package:footprint3/BarcodeScannerPage.dart';
import 'package:footprint3/DocumentDetailsPage.dart';
import 'package:footprint3/Holdings_page.dart';
import 'package:footprint3/NotificationBell.dart';
import 'package:footprint3/Notifications_page.dart';
import 'package:footprint3/RegisterDocument_page.dart';
import 'package:footprint3/TrackableDocument_class.dart';
import 'package:footprint3/chatlist_page.dart';
import 'package:footprint3/database_helper.dart';
import 'package:footprint3/utils.dart';


class DocumentTrackingScreen extends StatefulWidget {
  @override
  _DocumentTrackingScreenState createState() => _DocumentTrackingScreenState();
}

class _DocumentTrackingScreenState extends State<DocumentTrackingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Widget> pages = [
    HomePage(),
    ChatList(),
    HoldingsPage(),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      actions: [
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NotificationPage()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: FutureBuilder<List<NotificationItem>>(
              future: getHoldersNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return NotificationBell(notificationCount: 0);
                } else if (snapshot.hasError) {
                  return NotificationBell(notificationCount: 0);
                } else {
                  int count = snapshot.data != null ? snapshot.data!.length : 0;
                  return NotificationBell(notificationCount: count);
                }
              },
            ),
          ),
        ),

      ],
    ),
      drawer: AppDrawer(),
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return pages[index];
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: MediaQuery.of(context).viewInsets.bottom == 0
      ? BottomNavigationBar(
            currentIndex: _currentPage,
            onTap: _goToPage,
            selectedItemColor: mainOrange,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: "Home",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.chat),
                label: "Chat",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.article),
                label: "Holdings",
              ),
            ],
          )
      : null,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  final TextEditingController _trackingController = TextEditingController();
  List<String> searchSuggestions = [];
  List<String> words = []; 
  List<TrackableDocument> Alldocuments = [];

  @override
  void initState() {
    super.initState();
    getWords();
  }
  @override
  void dispose() {
    _trackingController.dispose();
    super.dispose();
  }

  void getWords() async {
    // Fetch all documents and extract their keys
    Alldocuments = await getAllDocuments();
    words = Alldocuments.map((doc) => doc.key).toList();
    words.addAll(Alldocuments.map((doc) => doc.title));
  }



  Widget _buildRegisterDocumentButton(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegisterdocumentPage()),
          );
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            mainOrange,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Register Document',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.add,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  void _generateSearchSuggestions(String query) {
    print("Generating suggestions for: $query");
    setState(() {
      searchSuggestions = words.where((word) => word.toLowerCase().contains(query.toLowerCase())).take(10).toList();
    });
    print("Suggestions: $searchSuggestions");
  }

  Widget _buildQuickscanButton(BuildContext context) {
    return Container(
      height: 50,
      margin: const EdgeInsets.all(10),
      child: ElevatedButton(
        onPressed: () {
          scanBarcode(context);
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all<Color>(
            mainOrange,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Scan',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Icon(
              Icons.qr_code,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> scanBarcode(BuildContext context) async {
    String barcodeScanRes;
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Barcodescannerpage(),
        ),
      );

      if (result != null) {
        barcodeScanRes = result;
        TrackableDocument? document = await getDocumentbyCode(barcodeScanRes);
        if (document != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DocumentDetailsPage(documentKey: document.key,),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Document not found"),
            ),
          );

        }
      }
    } catch (e) {
    }
  }

  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(text); 
    }

    String lowerText = text.toLowerCase();
    String lowerQuery = query.toLowerCase();

    int startIndex = lowerText.indexOf(lowerQuery);
    if (startIndex == -1) {
      return Text(text);
    }

    int endIndex = startIndex + query.length;

    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, startIndex)), // Before match
          TextSpan(
            text: text.substring(startIndex, endIndex), // Matched part
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red), // Highlight style
          ),
          TextSpan(text: text.substring(endIndex)), // After match
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              child: Stack(
                children: [
                  Container(
                    height: 113,
                    decoration: BoxDecoration(
                      color: mainOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: Colors.white,
                              child: Text(
                                curTracker.fullName[0],
                                style: TextStyle(
                                    color: mainOrange, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              curTracker.fullName,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 5,
                    left: 5,
                    right: 5,
                    child: Container(
                      height: 55,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "PSU - Taytay Campus",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Container(
              width: 300,
              height: 40,
              margin: const EdgeInsets.all(15),
              child: TextFormField(
                style: TextStyle(color: mainOrange),
                controller: _trackingController,
                decoration: InputDecoration(
                  label: Text(
                    "Search Document",
                    style: TextStyle(color: mainOrange),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: mainOrange),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                      color: Colors.red,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: 
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_trackingController.text.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.clear, color: mainOrange),
                            onPressed: () {
                              _trackingController.clear();
                              loseFocus();
                              setState(() {
                                searchSuggestions.clear();
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.search,
                              color: mainOrange,
                            ),
                            onPressed: () {
                              loseFocus();
                              setState(() {
                                searchSuggestions.clear();
                              });
                              TrackableDocument? document = Alldocuments.firstWhere(
                                (doc) => doc.key == _trackingController.text || doc.title == _trackingController.text,
                                orElse: () => TrackableDocument.empty(),
                              );
                              if (document.key.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DocumentDetailsPage(documentKey: document.key,),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Document not found"),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      )
                      
                ),
                onChanged: (value) {
                  setState(() {
                    if (value.isEmpty) {
                      searchSuggestions.clear();
                    }
                    else{
                      if(value.length < 20){
                        _generateSearchSuggestions(value);
                      }
                    }
                  });
                },
              ),
            ),
            if (searchSuggestions.isNotEmpty)
                    Container(
                      margin: EdgeInsets.only(top: 5),
                      constraints: BoxConstraints(maxHeight: 150),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [BoxShadow(color: Colors.grey, blurRadius: 2)],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: searchSuggestions.length,
                        itemBuilder: (context, index) {
                          print("Showing suggestion: ${searchSuggestions[index]}"); // Debug
                          return ListTile(
                            title: _highlightText(searchSuggestions[index], _trackingController.text.trim()),
                            onTap: () {
                              _trackingController.text = searchSuggestions[index];
                              TrackableDocument? document = Alldocuments.firstWhere(
                                (doc) => doc.key == searchSuggestions[index] || doc.title == searchSuggestions[index],
                                orElse: () => TrackableDocument.empty(),
                              );
                              if (document.key.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DocumentDetailsPage(documentKey: document.key,),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Document not found"),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
            Column(children: [ _buildRegisterDocumentButton(context), _buildQuickscanButton(context),],),
            SizedBox(height: 16),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Holdings",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<List<TrackableDocument>>(
                          stream: getHoldersDocumentsStream(), // Stream instead of Future
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(child: Text("Error loading documents"));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return Center(child: Text("No holdings found"));
                            }
    
                            final documents = snapshot.data!;
    
                            return ListView.builder(
                              itemCount: documents.length,
                              itemBuilder: (context, index) {
                                final doc = documents[index];
    
                                return GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DocumentDetailsPage(documentKey: doc.key,),
                                    ),
                                  ),
                                  child: ListTile(
                                    title: Text(
                                      doc.trackingCode,
                                      style: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    subtitle: Text(
                                      '"${doc.title}"',
                                      style: TextStyle(color: Colors.black, fontSize: 15),
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          formatTimeDifference(doc.records[0].date),
                                          style: TextStyle(color: Colors.black, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
