import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:googledrive/pdfviewer.dart';
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  const Upload({super.key});

  @override
  State<Upload> createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  bool isUploading = false;
  double uploadProgress = 0.0;
  final FirebaseFirestore _firebasefirestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> pdfData = [];
  bool doesexit = true;
 

  Future<void> uploadPdf(String filename, File file) async {
    final reference = FirebaseStorage.instance.ref().child("pdf/$filename");
    final UploadTask = reference.putFile(file,
     SettableMetadata(
      customMetadata: {"percentage":"0"},
    ),
    
    );
   
    setState(() {
      isUploading = true;
    });
    UploadTask.snapshotEvents.listen(( TaskSnapshot snapshot) {
  final double progress = snapshot.bytesTransferred/ snapshot.totalBytes;
  reference.updateMetadata(SettableMetadata(

    customMetadata: {"percentage":(progress *100).toStringAsFixed(2)},
  ));
  setState(() {
    uploadProgress = progress;
  });

     });
   await UploadTask.whenComplete(()  {
    setState(() {
      isUploading = false;
      uploadProgress = 0.0;

    });
     
    });
  }

  void pickfile() async {
    try {
      final pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (pickedFile != null) {
         var uuid = Uuid();
        String filename = pickedFile.files[0].name;
        // filecheck(filename);

        print(filename);
        File file = File(pickedFile.files[0].path!);
        print(doesexit);
      if (await doesFileExist(filename)) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("File name already exist"), backgroundColor: Colors.red,));
       
      } 
      else{
         await uploadPdf(filename, file); 
         final downloadLink = await FirebaseStorage.instance
            .ref()
            .child("pdf/$filename")
            .getDownloadURL();
        await _firebasefirestore.collection("pdf").add({
          "name": filename,
          "url": downloadLink,
          "id": uuid.v4(),
        });
      }
      
      // Wait for the upload to complete
       
        getPDF();
        print("Pdf upload Sucessfully");
      }
    } catch (e) {
      print("Exce ${e}");
    }
  }

  void getPDF() async {
    final result = await _firebasefirestore.collection("pdf").get();
    pdfData = result.docs.map((e) => e.data()).toList();
    print(pdfData);
    setState(() {
      
    });
  }

Future<bool> doesFileExist (String filename) async{
  DocumentSnapshot<Map<String, dynamic>> document = await FirebaseFirestore.instance.collection("pdf").doc(filename).get();


  if (document.exists) {
    return false;
    
  }else{
    return true;
  }
}



Future<void> deleteFile(String fileId) async {
  try {
    await FirebaseFirestore.instance.collection("pdf").where("id", isEqualTo: fileId).get().then((querySnapshot) {
      querySnapshot.docs.forEach((doc) {
        doc.reference.delete();
      });
    });
    print("PDF deleted from Firestore");
  } catch (e) {
    print("Error deleting PDF from Firestore: $e");
  }
}

Future<void> deletPDF(String filename) async{
  try {
    final reference = FirebaseStorage.instance.ref().child("pdf/$filename");
    await reference.delete();
    print("Deleted from storage");
  } catch (e) {
    print("Error deleting: $e");
    
  }
}

void deletePDFs(String docid, String filename) async{
  await deleteFile(docid);
  await deletPDF(filename);
  getPDF();
}
// 
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPDF();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Firebase PDF Upload"),
        backgroundColor: Colors.deepPurpleAccent,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          
          if(isUploading)BackdropFilter(filter: ImageFilter.blur(sigmaX: 5,sigmaY: 5),
          child: Container(
            color: Colors.black.withOpacity(0.5),
          ),
          
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               if (isUploading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                        
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Uploading ${uploadProgress.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 30),
                  itemCount: pdfData.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(builder: (context)=>PdfViewer(pdfUrl: pdfData[index]['url'])));
                        },
                        onDoubleTap: ()async {
                         deletePDFs(pdfData[index]['id'], pdfData[index]['name']);
                         
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Image.network(
                                "https://play-lh.googleusercontent.com/9XKD5S7rwQ6FiPXSyp9SzLXfIue88ntf9sJ9K250IuHTL7pmn2-ZB0sngAX4A2Bw4w",
                                height: 120,
                                width: 100,
                              ),
                              Text(pdfData[index]['name'],
                                  style: TextStyle(fontSize: 10)),
                            
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.upcoming_rounded),
        onPressed: isUploading? null : pickfile,
      ),
    );
   
  }
}
