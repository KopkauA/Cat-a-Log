import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatFilterSheet extends StatefulWidget {
  final Map<String, String?> filters;

  const CatFilterSheet({super.key, required this.filters});

  @override
  State<CatFilterSheet> createState() => _CatFilterSheetState();
}

class _CatFilterSheetState extends State<CatFilterSheet> {
  late Map<String, String?> _tempFilters;

  final List<String> _colorOptions = [
    'Black', 'White', 'Orange', 'Gray', 'Calico', 'Tabby', 'Tortoiseshell', 'Other'
  ];

  final List<String> _furLengthOptions = [
    'Short', 'Medium', 'Long', 'Hairless'
  ];

  final List<String> _locationOptions = [
    'AL','AK','AZ','AR','CA','CO','CT','DE','FL','GA','HI','ID','IL','IN',
    'IA','KS','KY','LA','ME','MD','MA','MI','MN','MS','MO','MT','NE','NV',
    'NH','NJ','NM','NY','NC','ND','OH','OK','OR','PA','RI','SC','SD','TN',
    'TX','UT','VT','VA','WA','WV','WI','WY'
  ];

  @override
  void initState() {
    super.initState();
    _tempFilters = Map<String, String?>.from(widget.filters);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 16,
        right: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Filter Cats", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Location'),
            initialValue: _tempFilters['location'],
            items: [
              const DropdownMenuItem(value: null, child: Text("Any")),
              ..._locationOptions.map((loc) => DropdownMenuItem(value: loc, child: Text(loc)))
            ],
            onChanged: (val) => setState(() => _tempFilters['location'] = val),
          ),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Fur Color'),
            initialValue: _tempFilters['color'],
            items: [
              const DropdownMenuItem(value: null, child: Text("Any")),
              ..._colorOptions.map((c) => DropdownMenuItem(value: c, child: Text(c)))
            ],
            onChanged: (val) => setState(() => _tempFilters['color'] = val),
          ),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Fur Length'),
            initialValue: _tempFilters['fur_length'],
            items: [
              const DropdownMenuItem(value: null, child: Text("Any")),
              ..._furLengthOptions.map((f) => DropdownMenuItem(value: f, child: Text(f)))
            ],
            onChanged: (val) => setState(() => _tempFilters['fur_length'] = val),
          ),

          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Sort By'),
            initialValue: _tempFilters['sort'],
            items: const [
              DropdownMenuItem(value: 'recent', child: Text('Most Recent')),
              DropdownMenuItem(value: 'oldest', child: Text('Oldest')),
            ],
            onChanged: (val) => setState(() => _tempFilters['sort'] = val),
          ),

          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context, {
                  'color': null,
                  'fur_length': null,
                  'location': null,
                  'sort': 'recent',
                }),
                child: const Text("Clear"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, _tempFilters),
                child: const Text("Apply"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CatFilter {
  static List<QueryDocumentSnapshot> applyFilters(
      List<QueryDocumentSnapshot> posts, Map<String, String?> filters) {
    List<QueryDocumentSnapshot> filtered = posts.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (filters['color'] != null && data['color'] != filters['color']) return false;
      if (filters['fur_length'] != null && data['fur_length'] != filters['fur_length']) return false;
      if (filters['location'] != null && data['location'] != filters['location']) return false;
      return true;
    }).toList();

    if (filters['sort'] == 'oldest') {
      filtered.sort((a, b) {
        final t1 = (a.data() as Map<String, dynamic>)['timestamp'];
        final t2 = (b.data() as Map<String, dynamic>)['timestamp'];
        return (t1?.millisecondsSinceEpoch ?? 0).compareTo(t2?.millisecondsSinceEpoch ?? 0);
      });
    }

    return filtered;
  }
}
