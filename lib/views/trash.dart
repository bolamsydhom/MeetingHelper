import 'package:meetinghelper/models/list_options.dart';
import 'package:meetinghelper/models/models.dart';
import 'package:meetinghelper/utils/helpers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:meetinghelper/views/lists/lists.dart';
import 'package:rxdart/rxdart.dart';

import '../models/super_classes.dart';
import 'list.dart';

class Trash extends StatelessWidget {
  const Trash({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final listOptions = DataObjectListOptions<TrashDay>(
      onLongPress: (_) {},
      tap: (day) {
        Navigator.push(context,
            MaterialPageRoute(builder: (context) => TrashDayScreen(day)));
      },
      searchQuery: BehaviorSubject<String>.seeded(''),
      itemsStream: FirebaseFirestore.instance
          .collection('Deleted')
          .orderBy('Time', descending: true)
          .snapshots()
          .map(
            (s) => s.docs
                .map(
                  (d) => TrashDay(d.data()['Time'].toDate(), d.reference),
                )
                .toList(),
          ),
    );
    return Scaffold(
      appBar: AppBar(title: Text('سلة المحذوفات')),
      body: DataObjectList<TrashDay>(options: listOptions),
    );
  }
}

class TrashDay extends DataObject {
  final DateTime date;
  TrashDay(this.date, DocumentReference ref)
      : super(ref, date.toUtc().toIso8601String().split('T')[0],
            Colors.transparent);

  @override
  Map<String, dynamic> getHumanReadableMap() {
    return {'Time': toDurationString(Timestamp.fromDate(date))};
  }

  @override
  Map<String, dynamic> getMap() {
    return {'Time': Timestamp.fromDate(date)};
  }

  @override
  Future<String> getSecondLine() async {
    return name;
  }
}

class TrashDayScreen extends StatefulWidget {
  final TrashDay day;
  const TrashDayScreen(this.day, {Key key}) : super(key: key);

  @override
  _TrashDayScreenState createState() => _TrashDayScreenState();
}

class _TrashDayScreenState extends State<TrashDayScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  bool dialogsNotShown = true;

  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode _searchFocus = FocusNode();

  final BehaviorSubject<OrderOptions> _personsOrder =
      BehaviorSubject.seeded(OrderOptions());

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  @override
  Widget build(BuildContext context) {
    var _servicesOptions = ServicesListOptions(
      searchQuery: _searchQuery,
      itemsStream: classesByStudyYearRef(),
      tap: (c) => classTap(c, context),
    );
    var _personsOptions = DataObjectListOptions<Person>(
      searchQuery: _searchQuery,
      tap: (p) => personTap(p, context),
      //Listen to Ordering options and combine it
      //with the Data Stream from Firestore
      itemsStream: _personsOrder.switchMap(
        (order) =>
            Person.getAllForUser(orderBy: order.orderBy, descending: !order.asc)
                .map(
          (s) => s.docs.map(Person.fromDoc).toList(),
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          StreamBuilder<bool>(
            initialData: false,
            stream: _showSearch,
            builder: (context, data) => data.data
                ? AnimatedBuilder(
                    animation: _tabController,
                    builder: (context, child) =>
                        _tabController.index == 1 ? child : Container(),
                    child: IconButton(
                      icon: Icon(Icons.filter_list),
                      onPressed: () async {
                        await showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            children: [
                              TextButton.icon(
                                icon: Icon(Icons.select_all),
                                label: Text('تحديد الكل'),
                                onPressed: () {
                                  _personsOptions.selectAll();
                                  Navigator.pop(context);
                                },
                              ),
                              TextButton.icon(
                                icon: Icon(Icons.select_all),
                                label: Text('تحديد لا شئ'),
                                onPressed: () {
                                  _personsOptions.selectNone();
                                  Navigator.pop(context);
                                },
                              ),
                              Text('ترتيب حسب:',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              ...Person.getHumanReadableMap2()
                                  .entries
                                  .map(
                                    (e) => RadioListTile(
                                      value: e.key,
                                      groupValue: _personsOrder.value.orderBy,
                                      title: Text(e.value),
                                      onChanged: (value) {
                                        _personsOrder.add(
                                          OrderOptions(
                                              orderBy: value,
                                              asc: _personsOrder.value.asc),
                                        );
                                        Navigator.pop(context);
                                      },
                                    ),
                                  )
                                  .toList(),
                              RadioListTile(
                                value: true,
                                groupValue: _personsOrder.value.asc,
                                title: Text('تصاعدي'),
                                onChanged: (value) {
                                  _personsOrder.add(
                                    OrderOptions(
                                        orderBy: _personsOrder.value.orderBy,
                                        asc: value),
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile(
                                value: false,
                                groupValue: _personsOrder.value.asc,
                                title: Text('تنازلي'),
                                onChanged: (value) {
                                  _personsOrder.add(
                                    OrderOptions(
                                        orderBy: _personsOrder.value.orderBy,
                                        asc: value),
                                  );
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.search),
                    onPressed: () {
                      _searchFocus.requestFocus();
                      _showSearch.add(true);
                    },
                  ),
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: 'الإشعارات',
            onPressed: () {
              Navigator.of(context).pushNamed('Notifications');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'الخدمات',
              icon: const Icon(Icons.miscellaneous_services),
            ),
            Tab(
              text: 'الأشخاص',
              icon: const Icon(Icons.person),
            ),
          ],
        ),
        title: StreamBuilder<bool>(
          initialData: _showSearch.value,
          stream: _showSearch,
          builder: (context, data) => data.data
              ? TextField(
                  focusNode: _searchFocus,
                  style: Theme.of(context).textTheme.headline6.copyWith(
                      color:
                          Theme.of(context).primaryTextTheme.headline6.color),
                  decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(Icons.close,
                            color: Theme.of(context)
                                .primaryTextTheme
                                .headline6
                                .color),
                        onPressed: () {
                          _searchQuery.add('');
                          _showSearch.add(false);
                        },
                      ),
                      hintStyle: Theme.of(context).textTheme.headline6.copyWith(
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline6
                              .color),
                      icon: Icon(Icons.search,
                          color: Theme.of(context)
                              .primaryTextTheme
                              .headline6
                              .color),
                      hintText: 'بحث ...'),
                  onChanged: _searchQuery.add,
                )
              : Text('البيانات'),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        shape: CircularNotchedRectangle(),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => StreamBuilder(
            stream: _tabController.index == 0
                ? _servicesOptions.objectsData
                : _personsOptions.objectsData,
            builder: (context, snapshot) {
              return Text(
                (snapshot.data?.length ?? 0).toString() +
                    ' ' +
                    (_tabController.index == 0 ? 'خدمة' : 'شخص'),
                textAlign: TextAlign.center,
                strutStyle:
                    StrutStyle(height: IconTheme.of(context).size / 7.5),
                style: Theme.of(context).primaryTextTheme.bodyText1,
              );
            },
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ServicesList(options: _servicesOptions),
          DataObjectList<Person>(options: _personsOptions),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: 4);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}