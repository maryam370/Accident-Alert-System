import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CaseDetailPage extends StatelessWidget {
  final Map<String, dynamic> caseData;

  const CaseDetailPage({Key? key, required this.caseData}) : super(key: key);

  @override
Widget build(BuildContext context) {
  final victim = caseData['victim'] as Map<String, dynamic>?;
  final ambulance = caseData['ambulance'] as Map<String, dynamic>?;
  final hospital = caseData['hospital'] as Map<String, dynamic>?;
  final location = caseData['location'] as Map<String, dynamic>?;
  final medicalRecords = victim?['medicalRecords'] as Map<String, dynamic>?;
  final emergencyContact = victim?['emergencyContact'] as Map<String, dynamic>?;
  final status = caseData['status']?.toString() ?? 'Pending';
  final timestamp = caseData['timestamp'] as DateTime;

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Report',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0D5D9F),
        ),
      ),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 3,
      shadowColor: Colors.blue.shade50,
      toolbarHeight: kToolbarHeight + 10,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20),
        ),
      ),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderInfo(caseData['id'].toString(), timestamp),
          const SizedBox(height: 12),
          _buildStatusSection(status),
          const SizedBox(height: 16),

          _buildSectionWithIcon('Accident Information', Icons.car_crash, [
            _buildField('Reported At',
                DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp)),
            if (caseData['severity'] != null)
              _buildField('Severity', caseData['severity'].toString()),
            if (caseData['description'] != null)
              _buildField('Description', caseData['description'].toString()),
          ]),

          if (victim != null)
            _buildSectionWithIcon('Victim Information', Icons.person, [
              _buildField('Name', victim['name']?.toString()),
              _buildField('Phone', victim['phoneNumber']?.toString()),
              _buildField(
                'Date of Birth',
                victim['dateOfBirth'] != null
                    ? DateFormat('MMM dd, yyyy').format(
                        (victim['dateOfBirth'] as Timestamp).toDate())
                    : null,
              ),
              _buildField('Gender', victim['gender']?.toString()),
              _buildField('Social Status', victim['socialStatus']?.toString()),
            ]),

          if (medicalRecords != null)
            _buildSectionWithIcon('Medical Information', Icons.medical_services, [
              _buildField('Blood Group', medicalRecords['bloodGroup']?.toString()),
              if (medicalRecords['allergies'] != null)
                _buildField('Allergies',
                    (medicalRecords['allergies'] as List<dynamic>?)?.join(', ')),
              if (medicalRecords['emergencyContact'] != null)
                ..._buildEmergencyContact(medicalRecords['emergencyContact']),
            ]),

          if (emergencyContact != null)
            _buildSectionWithIcon('Emergency Contact', Icons.phone_in_talk, [
              _buildField('Name', emergencyContact['name']?.toString()),
              _buildField('Phone', emergencyContact['number']?.toString()),
              _buildField('Relation', emergencyContact['relation']?.toString()),
            ]),

         

          if (ambulance != null)
            _buildSectionWithIcon('Ambulance', Icons.local_shipping, [
              _buildField('Service Name', ambulance['name']?.toString()),
              _buildField('Phone', ambulance['phoneNumber']?.toString()),
              _buildField('Email', ambulance['contactEmail']?.toString()),
              _buildField('Service Area', ambulance['serviceArea']?.toString()),
            ]),
             if (location != null)
            _buildSectionWithIcon('Location', Icons.location_on, [
              _buildField('Latitude', location['latitude']?.toString()),
              _buildField('Longitude', location['longitude']?.toString()),
              if (location['address'] != null)
                _buildField('Address', location['address']?.toString()),
            ]),

          if (hospital != null)
            _buildSectionWithIcon('Hospital', Icons.local_hospital, [
              _buildField('Hospital Name', hospital['name']?.toString()),
              _buildField('Type', hospital['hospitalType']?.toString()),
              _buildField('Address', hospital['hospitalAddress']?.toString()),
              _buildField('Phone', hospital['phoneNumber']?.toString()),
              _buildField('Email', hospital['contactEmail']?.toString()),
              _buildField('Geographical Area',
                  hospital['geographicalArea']?.toString()),
              if (hospital['bedCapacity'] != null)
                _buildField('Bed Capacity', hospital['bedCapacity'].toString()),
              if (hospital['availableServices'] != null)
                _buildField('Services',
                    hospital['availableServices']?.toString()),
            ]),

          if (caseData['assignedPoliceId'] != null)
            _buildSectionWithIcon('Police', Icons.local_police, [
              _buildField('Assigned Officer ID',
                  caseData['assignedPoliceId']?.toString()),
            ]),

          _buildSectionWithIcon('System Info', Icons.info, [
            _buildField('Case ID', caseData['id']?.toString()),
            _buildField('Created At', timestamp.toString()),
          ]),
        ],
      ),
    ),
  );
}
Widget _buildSectionWithIcon(String title, IconData icon, List<Widget> fields) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(children: fields),
      ),
    ],
  );
}

Widget _buildField(String label, String? value) {
  if (value == null || value.isEmpty) return const SizedBox.shrink();
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

  List<Widget> _buildEmergencyContact(Map<String, dynamic> contact) {
    return [
      _buildField('Emergency Contact', contact['name']),
      _buildField('Phone Number', contact['number']),
      _buildField('Relation', contact['relation']),
    ];
  }

  Widget _buildHeaderInfo(String caseId, DateTime timestamp) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'CASE #${caseId.substring(0, 6).toUpperCase()}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 18,
          ),
        ),
        Text(
          DateFormat('MMM dd, yyyy - hh:mm a').format(timestamp),
          style: TextStyle(color: Colors.grey[700]),
        ),
      ],
    );
  }

  Widget _buildStatusSection(String status) {
    Color statusColor;
    switch (status.toLowerCase()) {
      case 'resolved':
        statusColor = Colors.green;
        break;
      case 'in progress':
      case 'hospital_notified':
      case 'ambulance_dispatched':
        statusColor = Colors.orange;
        break;
      case 'detected':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Status:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue,
            fontSize: 16,
          ),
        ),
        const Divider(),
        ...children,
      ],
    );
  }

}
