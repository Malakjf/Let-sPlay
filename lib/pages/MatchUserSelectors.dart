import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/language.dart';

class MatchUserSelectors extends StatefulWidget {

  final LocaleController ctrl;

  final List<String> initialOrganizers;
  final List<String> initialCoaches;

  final Function(List<String>) onOrganizersChanged;
  final Function(List<String>) onCoachesChanged;

  const MatchUserSelectors({
    super.key,
    required this.ctrl,
    required this.initialOrganizers,
    required this.initialCoaches,
    required this.onOrganizersChanged,
    required this.onCoachesChanged,
  });

  @override
  State<MatchUserSelectors> createState() => _MatchUserSelectorsState();
}

class _MatchUserSelectorsState extends State<MatchUserSelectors> {

  List<Map<String,dynamic>> _users = [];

  List<String> _selectedOrganizers = [];
  List<String> _selectedCoaches = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _selectedOrganizers = List.from(widget.initialOrganizers);
    _selectedCoaches = List.from(widget.initialCoaches);

    _loadUsers();
  }

  Future<void> _loadUsers() async {

    try {

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();

      List<Map<String,dynamic>> users = [];

      for (final doc in snapshot.docs) {

        final data = doc.data();

        final role =
            (data['role'] ?? '').toString().toLowerCase().trim();

        if (role.contains('admin') ||
            role.contains('coach') ||
            role.contains('organizer') ||
            role.contains('referee')) {

          users.add({
            "id": doc.id,
            "name": data['name'] ??
                    data['username'] ??
                    data['displayName'] ??
                    "Unknown",
            "role": role
          });
        }
      }

      users.sort((a,b)=>a['name'].compareTo(b['name']));

      if(!mounted) return;

      setState(() {

        _users = users;
        _loading = false;

      });

    } catch(e) {

      debugPrint("Users load error: $e");

      if(mounted){
        setState(()=>_loading=false);
      }
    }
  }

  Future<void> _openUserSelector({
    required bool organizer
  }) async {

    final selectedList =
        organizer ? _selectedOrganizers : _selectedCoaches;

    await showDialog(
      context: context,
      builder: (context){

        return StatefulBuilder(
          builder:(context,setDialogState){

            return AlertDialog(

              title: Text(
                organizer
                    ? (widget.ctrl.isArabic ? "اختر المنظمين" : "Select Organizers")
                    : (widget.ctrl.isArabic ? "اختر المدربين / الحكام" : "Select Coaches / Referees")
              ),

              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(

                  shrinkWrap: true,
                  itemCount: _users.length,

                  itemBuilder:(context,index){

                    final user = _users[index];
                    final id = user['id'];

                    final selected =
                        selectedList.contains(id);

                    return CheckboxListTile(

                      value: selected,

                      title: Text(user['name']),

                      subtitle: Text(user['role']),

                      onChanged:(v){

                        setDialogState((){

                          if(selected){

                            selectedList.remove(id);

                          }else{

                            selectedList.add(id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),

              actions: [

                TextButton(
                  onPressed: ()=>Navigator.pop(context),
                  child: Text(widget.ctrl.isArabic ? "إغلاق" : "Close"),
                )
              ],
            );
          }
        );
      }
    );

    setState((){});

    if(organizer){

      widget.onOrganizersChanged(_selectedOrganizers);

    }else{

      widget.onCoachesChanged(_selectedCoaches);
    }
  }

  @override
  Widget build(BuildContext context) {

    final ar = widget.ctrl.isArabic;

    if(_loading){
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [

        /// ORGANIZERS
        ListTile(

          leading: const Icon(Icons.people),

          title: Text(ar ? "المنظمون" : "Organizers"),

          subtitle: Text(
            _selectedOrganizers.length.toString()
          ),

          trailing: const Icon(Icons.arrow_drop_down),

          onTap: (){
            _openUserSelector(organizer:true);
          },
        ),

        const SizedBox(height:12),

        /// COACHES
        ListTile(

          leading: const Icon(Icons.sports_soccer),

          title: Text(ar ? "المدرب / الحكم" : "Coach / Referee"),

          subtitle: Text(
            _selectedCoaches.length.toString()
          ),

          trailing: const Icon(Icons.arrow_drop_down),

          onTap: (){
            _openUserSelector(organizer:false);
          },
        ),
      ],
    );
  }
}