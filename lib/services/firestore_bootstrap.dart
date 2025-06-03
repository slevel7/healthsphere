import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> initializeFirestoreSchema() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // 1. Create sample doctor
  await firestore.collection('doctors').doc('doc_001').set({
    'doctorName': 'Dr. Marcus Horizon',
    'specialization': 'Cardiologist',
    'rating': 4.7,
    'hospitalID': 'hosp_001',
    'doctorPhoneNo': '+919999999999',
    'doctorEmail': 'marcus@healthsphere.com',
    'doctorHistory': 'Experienced cardiologist with 10+ years',
  });

  // 2. Create sample patient
  await firestore.collection('patients').doc('pat_001').set({
    'profileID': 'profile_001',
    'pastMedicalHistory': 'Diabetes, Hypertension',
    'patientPhone': '+918888888888',
    'patientEmail': 'patient1@email.com',
  });

  // 3. Create sample profile
  await firestore.collection('profiles').doc('profile_001').set({
    'name': 'Rahul Sharma',
    'DOB': '1990-05-12',
    'profilePhoneNo': '+918888888888',
    'profileEmail': 'rahul@example.com',
    'patientID': 'pat_001',
    'appointmentID': 'appt_001',
  });

  // 4. Create appointment (linked globally and in doctor subcollection)
  final appointment = {
    'appointmentID': 'appt_001',
    'patientID': 'pat_001',
    'doctorID': 'doc_001',
    'doctorName': 'Dr. Marcus Horizon',
    'status': 'pending',
    'date': Timestamp.fromDate(DateTime(2025, 5, 22, 5, 30)),
    'time': '09:00 AM',
    'createdAt': FieldValue.serverTimestamp(),
  };

  await firestore.collection('appointments').doc('appt_001').set(appointment);
  await firestore
      .collection('doctors')
      .doc('doc_001')
      .collection('appointments')
      .doc('appt_001')
      .set(appointment);

  // 5. Create sample ambulance request
  await firestore.collection('ambulances').doc('ambulance_001').set({
    'ambulanceID': 'ambulance_001',
    'pickupLocation': 'Thana Chariali, Dibrugarh',
    'hospitalID': 'hosp_001',
    'patientCondition': 'Critical',
  });

  // 6. Create sample medicine entry
  await firestore.collection('medicines').doc('med_001').set({
    'medicineID': 'med_001',
    'medicineDetails': 'Paracetamol 500mg',
    'medicineQuantity': 100,
  });

  // 7. Create admin credentials (NOT RECOMMENDED to store plain)
  await firestore.collection('admin').doc('admin_001').set({
    'email': 'admin@healthsphere.com',
    'password': '123456', // 🛑 Don't store plain passwords in real apps!
  });

  print("Firestore schema initialized.");
}
