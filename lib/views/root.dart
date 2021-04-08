import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:app_settings/app_settings.dart';
import 'package:battery_optimization/battery_optimization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';

import '../main.dart';
import '../models/list_options.dart';
import '../models/models.dart';
import '../models/order_options.dart';
import '../models/user.dart';
import '../utils/globals.dart';
import '../utils/helpers.dart';
import 'auth_screen.dart';
import 'list.dart';
import 'services_list.dart';

class Root extends StatefulWidget {
  const Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  Timer _keepAliveTimer;
  bool _timeout = false;
  bool _pushed = false;
  bool dialogsNotShown = true;

  final BehaviorSubject<bool> _showSearch = BehaviorSubject<bool>.seeded(false);
  final FocusNode _searchFocus = FocusNode();

  final GlobalKey _addHistory = GlobalKey();
  final GlobalKey _history = GlobalKey();
  final GlobalKey _search = GlobalKey();
  final GlobalKey _map = GlobalKey();

  final BehaviorSubject<OrderOptions> _personsOrder =
      BehaviorSubject.seeded(OrderOptions());

  final BehaviorSubject<String> _searchQuery =
      BehaviorSubject<String>.seeded('');

  void addTap() {
    if (_tabController.index == 0) {
      Navigator.of(context).pushNamed('Data/EditClass');
    } else if (_tabController.index == 1) {
      Navigator.of(context).pushNamed('Data/EditPerson');
    }
  }

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
      key: mainScfld,
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
                    icon: DescribedFeatureOverlay(
                      barrierDismissible: false,
                      contentLocation: ContentLocation.below,
                      featureId: 'Search',
                      tapTarget: const Icon(Icons.search),
                      title: Text('البحث السريع'),
                      description: Column(
                        children: <Widget>[
                          Text(
                              'يمكنك في أي وقت عمل بحث سريع بالاسم عن المخدومين'),
                          OutlinedButton.icon(
                            icon: Icon(Icons.forward),
                            label: Text(
                              'التالي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () {
                              mainScfld.currentState.openDrawer();
                              FeatureDiscovery.completeCurrentStep(context);
                            },
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: const Icon(Icons.search),
                    ),
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
              icon: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'Services',
                tapTarget: const Icon(Icons.miscellaneous_services),
                title: Text('الخدمات'),
                description: Column(
                  children: <Widget>[
                    Text(
                        'هنا تجد قائمة بكل الفصول في البرنامج مقسمة الى الخدمات وسنوات الدراسة'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () =>
                          FeatureDiscovery.completeCurrentStep(context),
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.miscellaneous_services),
              ),
            ),
            Tab(
              text: 'الأشخاص',
              icon: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'Persons',
                tapTarget: const Icon(Icons.person),
                title: Text('المخدومين /الأشخاص'),
                description: Column(
                  children: <Widget>[
                    Text('هنا تجد قائمة بكل المخدومين بالبرنامج'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () =>
                          FeatureDiscovery.completeCurrentStep(context),
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.person),
              ),
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
      extendBody: true,
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: null,
        onPressed: addTap,
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) => Icon(
              _tabController.index == 0 ? Icons.group_add : Icons.person_add),
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
      drawer: Drawer(
        child: ListView(
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/Logo.png'),
                ),
                gradient: LinearGradient(
                  colors: [Colors.limeAccent, Colors.amber],
                  stops: [0, 1],
                ),
              ),
              child: Container(),
            ),
            ListTile(
              leading: Consumer<User>(
                builder: (context, user, snapshot) {
                  return DescribedFeatureOverlay(
                    barrierDismissible: false,
                    contentLocation: ContentLocation.below,
                    featureId: 'MyAccount',
                    tapTarget: user.getPhoto(true, false),
                    title: Text('حسابي'),
                    description: Column(
                      children: <Widget>[
                        Text(
                            'يمكنك الاطلاع على حسابك بالبرنامج وجميع الصلاحيات التي تملكها من خلال حسابي'),
                        OutlinedButton.icon(
                          icon: Icon(Icons.forward),
                          label: Text(
                            'التالي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                          onPressed: () {
                            Scrollable.ensureVisible(
                                _addHistory.currentContext);
                            FeatureDiscovery.completeCurrentStep(context);
                          },
                        ),
                        OutlinedButton(
                          onPressed: () => FeatureDiscovery.dismissAll(context),
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).accentColor,
                    targetColor: Colors.transparent,
                    textColor:
                        Theme.of(context).primaryTextTheme.bodyText1.color,
                    child: user.getPhoto(true, false),
                  );
                },
              ),
              title: Text('حسابي'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.pushNamed(context, 'MyAccount');
              },
            ),
            Selector<User, bool>(
              selector: (_, user) =>
                  user.manageUsers || user.manageAllowedUsers,
              builder: (c, permission, data) {
                if (!permission)
                  return Container(
                    width: 0,
                    height: 0,
                  );
                return ListTile(
                    leading: DescribedFeatureOverlay(
                      barrierDismissible: false,
                      featureId: 'ManageUsers',
                      tapTarget: const Icon(Icons.admin_panel_settings),
                      contentLocation: ContentLocation.below,
                      title: Text('إدارة المستخدمين'),
                      description: Column(
                        children: <Widget>[
                          Text(
                              'يمكنك دائمًا الاطلاع على مستخدمي البرنامج وتعديل صلاحياتهم من هنا'),
                          OutlinedButton.icon(
                            icon: Icon(Icons.forward),
                            label: Text(
                              'التالي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                            onPressed: () =>
                                FeatureDiscovery.completeCurrentStep(context),
                          ),
                          OutlinedButton(
                            onPressed: () =>
                                FeatureDiscovery.dismissAll(context),
                            child: Text(
                              'تخطي',
                              style: TextStyle(
                                color:
                                    Theme.of(context).textTheme.bodyText2.color,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: Theme.of(context).accentColor,
                      targetColor: Colors.transparent,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: const Icon(Icons.admin_panel_settings),
                    ),
                    onTap: () async {
                      mainScfld.currentState.openEndDrawer();
                      if (await Connectivity().checkConnectivity() !=
                          ConnectivityResult.none) {
                        // ignore: unawaited_futures
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AuthScreen(
                              nextRoute: 'ManageUsers',
                            ),
                          ),
                        );
                      } else {
                        await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                content: Text('لا يوجد اتصال انترنت')));
                      }
                    },
                    title: Text('إدارة المستخدمين'));
              },
            ),
            Divider(),
            ListTile(
              key: _addHistory,
              leading: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'AddHistory',
                tapTarget: const Icon(Icons.add),
                title: Text('اضافة / عرض كشف حضور اليوم'),
                description: Column(
                  children: <Widget>[
                    Text('يمكنك تسجيل كشف حضور المخدومين لليوم من هنا'),
                    Text(
                        'بالإضافة الى حضور القداس والتناول وامكانية وضع الملاحظات لكل مخدوم'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () =>
                          FeatureDiscovery.completeCurrentStep(context),
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.add),
              ),
              title: Text('كشف الحضور اليوم'),
              onTap: () async {
                if (await Connectivity().checkConnectivity() !=
                    ConnectivityResult.none) {
                  var today = (await FirebaseFirestore.instance
                          .collection('History')
                          .where('Day',
                              isEqualTo: Timestamp.fromMillisecondsSinceEpoch(
                                DateTime.now().millisecondsSinceEpoch -
                                    (DateTime.now().millisecondsSinceEpoch %
                                        86400000),
                              ))
                          .get(dataSource))
                      .docs;
                  mainScfld.currentState.openEndDrawer();
                  if (today.isNotEmpty) {
                    await Navigator.of(context).pushNamed('Day',
                        arguments: HistoryDay.fromDoc(today[0]));
                  } else {
                    await Navigator.of(context).pushNamed('Day');
                  }
                } else {
                  await showDialog(
                      context: context,
                      builder: (context) =>
                          AlertDialog(content: Text('لا يوجد اتصال انترنت')));
                }
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.secretary,
              builder: (c, permission, data) => permission
                  ? ListTile(
                      leading: DescribedFeatureOverlay(
                        barrierDismissible: false,
                        contentLocation: ContentLocation.below,
                        featureId: 'AddServantsHistory',
                        tapTarget: const Icon(Icons.add),
                        title: Text('اضافة / عرض كشف حضور اليوم للخدام'),
                        description: Column(
                          children: <Widget>[
                            Text('يمكنك تسجيل كشف حضور الخدام لليوم من هنا'),
                            Text(
                                'بالإضافة الى حضور القداس والتناول وامكانية وضع الملاحظات لكل خادم'),
                            OutlinedButton.icon(
                              icon: Icon(Icons.forward),
                              label: Text(
                                'التالي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color,
                                ),
                              ),
                              onPressed: () =>
                                  FeatureDiscovery.completeCurrentStep(context),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  FeatureDiscovery.dismissAll(context),
                              child: Text(
                                'تخطي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Theme.of(context).accentColor,
                        targetColor: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.bodyText1.color,
                        child: const Icon(Icons.add),
                      ),
                      title: Text('كشف حضور اليوم (سجل الخدام)'),
                      onTap: () async {
                        mainScfld.currentState.openEndDrawer();
                        if (await Connectivity().checkConnectivity() ==
                            ConnectivityResult.none) {
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              content: Text('لا يوجد اتصال انترنت'),
                            ),
                          );
                          return;
                        }
                        var today = (await FirebaseFirestore.instance
                                .collection('ServantsHistory')
                                .where('Day',
                                    isEqualTo:
                                        Timestamp.fromMillisecondsSinceEpoch(
                                      DateTime.now().millisecondsSinceEpoch -
                                          (DateTime.now()
                                                  .millisecondsSinceEpoch %
                                              86400000),
                                    ))
                                .get(dataSource))
                            .docs;
                        if (today.isNotEmpty) {
                          await Navigator.of(context).pushNamed('ServantsDay',
                              arguments: ServantsHistoryDay.fromDoc(today[0]));
                        } else {
                          await Navigator.of(context).pushNamed('ServantsDay');
                        }
                      },
                    )
                  : Container(),
            ),
            ListTile(
              key: _history,
              leading: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'History',
                tapTarget: const Icon(Icons.history),
                title: Text('عرض سجلات الحضور'),
                description: Column(
                  children: <Widget>[
                    Text('يمكنك عرض جميع سجلات / كشوفات الحضور من هنا'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () {
                        FeatureDiscovery.completeCurrentStep(context);
                      },
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.history),
              ),
              title: Text('السجل'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('History');
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.secretary,
              builder: (c, permission, data) => permission
                  ? ListTile(
                      leading: DescribedFeatureOverlay(
                        barrierDismissible: false,
                        contentLocation: ContentLocation.below,
                        featureId: 'ServantsHistory',
                        tapTarget: const Icon(Icons.history),
                        title: Text('عرض سجلات الحضور للخدام'),
                        description: Column(
                          children: <Widget>[
                            Text(
                                'يمكنك عرض جميع سجلات / كشوفات الحضور للخدام من هنا'),
                            OutlinedButton.icon(
                              icon: Icon(Icons.forward),
                              label: Text(
                                'التالي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color,
                                ),
                              ),
                              onPressed: () =>
                                  FeatureDiscovery.completeCurrentStep(context),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  FeatureDiscovery.dismissAll(context),
                              child: Text(
                                'تخطي',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyText2
                                      .color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Theme.of(context).accentColor,
                        targetColor: Colors.transparent,
                        textColor:
                            Theme.of(context).primaryTextTheme.bodyText1.color,
                        child: const Icon(Icons.history),
                      ),
                      title: Text('سجل الخدام'),
                      onTap: () {
                        mainScfld.currentState.openEndDrawer();
                        Navigator.of(context).pushNamed('ServantsHistory');
                      },
                    )
                  : Container(),
            ),
            ListTile(
              leading: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'Analytics',
                tapTarget: const Icon(Icons.analytics_outlined),
                title: Text('عرض تحليل لبيانات سجلات الحضور'),
                description: Column(
                  children: <Widget>[
                    Text(
                        'الأن يمكنك عرض تحليل لبيانات المخدومين خلال فترة معينة من هنا'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () {
                        Scrollable.ensureVisible(_search.currentContext);
                        FeatureDiscovery.completeCurrentStep(context);
                      },
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.analytics_outlined),
              ),
              title: Text('تحليل بيانات السجل'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('Analytics');
              },
            ),
            Divider(),
            ListTile(
              key: _search,
              leading: DescribedFeatureOverlay(
                barrierDismissible: false,
                contentLocation: ContentLocation.below,
                featureId: 'AdvancedSearch',
                tapTarget: Icon(Icons.search),
                title: Text('البحث المفصل'),
                description: Column(
                  children: <Widget>[
                    Text(
                        'يمكن عمل بحث مفصل عن البيانات بالبرنامج بالخصائص المطلوبة\nمثال: عرض كل الأشخاص الذين يصادف عيد ميلادهم اليوم\nعرض كل الأشخاص داخل منطقة معينة'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () {
                        Scrollable.ensureVisible(_map.currentContext);
                        FeatureDiscovery.completeCurrentStep(context);
                      },
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.search),
              ),
              title: Text('بحث مفصل'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('Search');
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.manageDeleted,
              builder: (context, permission, _) {
                if (!permission)
                  return Container(
                    width: 0,
                    height: 0,
                  );
                return ListTile(
                  leading: DescribedFeatureOverlay(
                    backgroundDismissible: false,
                    barrierDismissible: false,
                    featureId: 'ManageDeleted',
                    tapTarget: Icon(Icons.delete_outline),
                    contentLocation: ContentLocation.below,
                    title: Text('سلة المحذوفات'),
                    description: Column(
                      children: <Widget>[
                        Text(
                            'يمكنك الأن استرجاع المحذوفات خلال مدة شهر من حذفها من هنا'),
                        OutlinedButton.icon(
                          icon: Icon(Icons.forward),
                          label: Text(
                            'التالي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                          onPressed: () =>
                              FeatureDiscovery.completeCurrentStep(context),
                        ),
                        OutlinedButton(
                          onPressed: () => FeatureDiscovery.dismissAll(context),
                          child: Text(
                            'تخطي',
                            style: TextStyle(
                              color:
                                  Theme.of(context).textTheme.bodyText2.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: Theme.of(context).accentColor,
                    targetColor: Colors.transparent,
                    textColor:
                        Theme.of(context).primaryTextTheme.bodyText1.color,
                    child: Icon(Icons.delete_outline),
                  ),
                  onTap: () {
                    mainScfld.currentState.openEndDrawer();
                    Navigator.pushNamed(context, 'Trash');
                  },
                  title: Text('سلة المحذوفات'),
                );
              },
            ),
            ListTile(
              key: _map,
              leading: DescribedFeatureOverlay(
                barrierDismissible: false,
                featureId: 'DataMap',
                contentLocation: ContentLocation.below,
                tapTarget: const Icon(Icons.map),
                title: Text('خريطة الافتقاد'),
                description: Column(
                  children: [
                    Text(
                        'يمكنك دائمًا الاطلاع على جميع مواقع العائلات بالبرنامج عن طريق خريطة الافتقاد'),
                    OutlinedButton.icon(
                      icon: Icon(Icons.forward),
                      label: Text(
                        'التالي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                      onPressed: () {
                        FeatureDiscovery.completeCurrentStep(context);
                      },
                    ),
                    OutlinedButton(
                      onPressed: () => FeatureDiscovery.dismissAll(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: Icon(Icons.map),
              ),
              title: Text('عرض خريطة الافتقاد'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('DataMap');
              },
            ),
            Divider(),
            ListTile(
              leading: DescribedFeatureOverlay(
                onBackgroundTap: () async {
                  await FeatureDiscovery.completeCurrentStep(context);
                  return true;
                },
                onDismiss: () async {
                  await FeatureDiscovery.completeCurrentStep(context);
                  return true;
                },
                backgroundDismissible: true,
                contentLocation: ContentLocation.below,
                featureId: 'Settings',
                tapTarget: const Icon(Icons.settings),
                title: Text('الإعدادات'),
                description: Column(
                  children: <Widget>[
                    Text(
                        'يمكنك ضبط بعض الاعدادات بالبرنامج مثل مظهر البرنامج ومظهر البيانات وبعض البيانات الاضافية مثل الوظائف والأباء الكهنة'),
                    OutlinedButton(
                      onPressed: () =>
                          FeatureDiscovery.completeCurrentStep(context),
                      child: Text(
                        'تخطي',
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyText2.color,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Theme.of(context).accentColor,
                targetColor: Colors.transparent,
                textColor: Theme.of(context).primaryTextTheme.bodyText1.color,
                child: const Icon(Icons.settings),
              ),
              title: Text('الإعدادات'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('Settings');
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.cloud_upload),
              title: Text('استيراد من ملف اكسل'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                import(context);
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.exportClasses,
              builder: (context2, permission, _) {
                return permission
                    ? ListTile(
                        leading: Icon(Icons.cloud_download),
                        title: Text('تصدير فصل إلى ملف اكسل'),
                        onTap: () async {
                          mainScfld.currentState.openEndDrawer();
                          Class rslt = await showDialog(
                            context: context,
                            builder: (context) => Dialog(
                              child: Column(
                                children: [
                                  Text('برجاء اختيار الفصل الذي تريد تصديره:',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headline5),
                                  Expanded(
                                    child: ServicesList(
                                      options: ServicesListOptions(
                                        searchQuery: Stream.value(''),
                                        tap: (_class) => Navigator.pop(
                                          context,
                                          _class,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          if (rslt != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('جار تصدير ' + rslt.name + '...'),
                                    LinearProgressIndicator(),
                                  ],
                                ),
                                duration: Duration(minutes: 9),
                              ),
                            );
                            try {
                              String filename = Uri.decodeComponent(
                                  (await FirebaseFunctions.instance
                                          .httpsCallable('exportToExcel')
                                          .call({'onlyClass': rslt.id}))
                                      .data);
                              var file = await File(
                                      (await getApplicationDocumentsDirectory())
                                              .path +
                                          '/' +
                                          filename.replaceAll(':', ''))
                                  .create(recursive: true);
                              await FirebaseStorage.instance
                                  .ref(filename)
                                  .writeToFile(file);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم تصدير البيانات ينجاح'),
                                  action: SnackBarAction(
                                    label: 'فتح',
                                    onPressed: () {
                                      OpenFile.open(file.path);
                                    },
                                  ),
                                ),
                              );
                            } on Exception catch (e, st) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل تصدير البيانات')),
                              );
                              await FirebaseCrashlytics.instance.setCustomKey(
                                  'LastErrorIn', 'Root.exportOnlyArea');
                              await FirebaseCrashlytics.instance
                                  .recordError(e, st);
                            }
                          }
                        },
                      )
                    : Container();
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.exportClasses,
              builder: (context2, permission, _) {
                return permission
                    ? ListTile(
                        leading: Icon(Icons.cloud_download),
                        title: Text('تصدير جميع البيانات'),
                        onTap: () async {
                          mainScfld.currentState.openEndDrawer();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'جار تصدير جميع البيانات...\nيرجى الانتظار...'),
                                  LinearProgressIndicator(),
                                ],
                              ),
                              duration: Duration(minutes: 9),
                            ),
                          );
                          try {
                            String filename = Uri.decodeComponent(
                                (await FirebaseFunctions.instance
                                        .httpsCallable('exportToExcel')
                                        .call())
                                    .data);
                            var file = await File(
                                    (await getApplicationDocumentsDirectory())
                                            .path +
                                        '/' +
                                        filename.replaceAll(':', ''))
                                .create(recursive: true);
                            await FirebaseStorage.instance
                                .ref(filename)
                                .writeToFile(file);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تم تصدير البيانات ينجاح'),
                                action: SnackBarAction(
                                  label: 'فتح',
                                  onPressed: () {
                                    OpenFile.open(file.path);
                                  },
                                ),
                              ),
                            );
                          } on Exception catch (e, st) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('فشل تصدير البيانات')),
                            );
                            await FirebaseCrashlytics.instance
                                .setCustomKey('LastErrorIn', 'Root.exportAll');
                            await FirebaseCrashlytics.instance
                                .recordError(e, st);
                          }
                        },
                      )
                    : Container();
              },
            ),
            Selector<User, bool>(
              selector: (_, user) => user.exportClasses,
              builder: (context, user, _) => ListTile(
                leading: Icon(Icons.list_alt),
                title: Text('عمليات التصدير السابقة'),
                onTap: () => Navigator.pushNamed(context, 'ExportOps'),
              ),
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.system_update_alt),
              title: Text('تحديث البرنامج'),
              onTap: () {
                mainScfld.currentState.openEndDrawer();
                Navigator.of(context).pushNamed('Update');
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('حول البرنامج'),
              onTap: () async {
                mainScfld.currentState.openEndDrawer();
                showAboutDialog(
                  context: context,
                  applicationIcon:
                      Image.asset('assets/Logo.png', width: 50, height: 50),
                  applicationName: 'خدمة مدارس الأحد',
                  applicationLegalese:
                      'جميع الحقوق محفوظة: كنيسة السيدة العذراء مريم بالاسماعيلية',
                  applicationVersion:
                      (await PackageInfo.fromPlatform()).version,
                  children: [
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            style:
                                Theme.of(context).textTheme.bodyText2.copyWith(
                                      color: Colors.blue,
                                    ),
                            text: 'شروط الاستخدام',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                //   final url =
                                //       'https://church-data.flycricket.io/terms.html';
                                //   if (await canLaunch(url)) {
                                //     await launch(url);
                                //   }
                              },
                          ),
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyText2,
                            text: ' • ',
                          ),
                          TextSpan(
                            style:
                                Theme.of(context).textTheme.bodyText2.copyWith(
                                      color: Colors.blue,
                                    ),
                            text: 'سياسة الخصوصية',
                            recognizer: TapGestureRecognizer()
                              ..onTap = () async {
                                // final url =
                                //     'https://church-data.flycricket.io/privacy.html';
                                // if (await canLaunch(url)) {
                                //   await launch(url);
                                // }
                              },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            ListTile(
              leading:
                  Icon(const IconData(0xe9ba, fontFamily: 'MaterialIconsR')),
              title: Text('تسجيل الخروج'),
              onTap: () async {
                mainScfld.currentState.openEndDrawer();
                var user = User.instance;
                await Hive.box('Settings').put('FCM_Token_Registered', false);
                // ignore: unawaited_futures
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                      return App();
                    },
                  ),
                );
                await user.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (_timeout && !_pushed) {
          _pushed = true;
          Navigator.of(context)
              .push(
            MaterialPageRoute(
              builder: (context) => WillPopScope(
                onWillPop: () => Future.delayed(Duration.zero, () => false),
                child: AuthScreen(),
              ),
            ),
          )
              .then((value) {
            _pushed = false;
            _timeout = false;
          });
        }
        _keepAlive(true);
        _recordActive();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.paused:
        _keepAlive(false);
        _recordLastSeen();
        break;
    }
  }

  @override
  void didChangePlatformBrightness() {
    changeTheme(context: mainScfld.currentContext);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('ar_EG', null);
    _tabController = TabController(vsync: this, length: 2);
    WidgetsBinding.instance.addObserver(this);
    _keepAlive(true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dialogsNotShown) showPendingUIDialogs();
    });
  }

  Future<void> showBatteryOptimizationDialog() async {
    if ((await DeviceInfoPlugin().androidInfo).version.sdkInt >= 23 &&
        !await BatteryOptimization.isIgnoringBatteryOptimizations() &&
        Hive.box('Settings').get('ShowBatteryDialog', defaultValue: true)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text(
              'برجاء الغاء تفعيل حفظ الطاقة للبرنامج لإظهار الاشعارات في الخلفية'),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await AppSettings.openBatteryOptimizationSettings();
                ;
              },
              child: Text('الغاء حفظ الطاقة للبرنامج'),
            ),
            TextButton(
              onPressed: () async {
                await Hive.box('Settings').put('ShowBatteryDialog', false);
                Navigator.pop(context);
              },
              child: Text('عدم الاظهار مجددًا'),
            ),
          ],
        ),
      );
    }
  }

  Future showDynamicLink() async {
    PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    FirebaseDynamicLinks.instance.onLink(
      onSuccess: (dynamicLink) async {
        if (dynamicLink == null) return;
        Uri deepLink = dynamicLink.link;

        await processLink(deepLink, context);
      },
      onError: (e) async {
        debugPrint('DynamicLinks onError $e');
      },
    );
    if (data == null) return;
    Uri deepLink = data.link;
    await processLink(deepLink, context);
  }

  void showPendingUIDialogs() async {
    dialogsNotShown = false;
    if (!await User.instance.userDataUpToDate()) {
      await showErrorUpdateDataDialog(context: context, pushApp: false);
    }
    await showDynamicLink();
    await showPendingMessage();
    await processClickedNotification(context);
    await showBatteryOptimizationDialog();
    FeatureDiscovery.discoverFeatures(context, [
      'Services',
      'Persons',
      'Search',
      'MyAccount',
      if (User.instance.manageUsers || User.instance.manageAllowedUsers)
        'ManageUsers',
      'AddHistory',
      if (User.instance.secretary) 'AddServantsHistory',
      'History',
      if (User.instance.secretary) 'ServantsHistory',
      'Analytics',
      'DataMap',
      'AdvancedSearch',
      if (User.instance.manageDeleted)
        'ManageDeleted'
            'Settings'
    ]);
  }

  void _keepAlive(bool visible) {
    _keepAliveTimer?.cancel();
    if (visible) {
      _keepAliveTimer = null;
    } else {
      _keepAliveTimer = Timer(
        Duration(minutes: 1),
        () => _timeout = true,
      );
    }
  }

  Future<void> _recordActive() async {
    await User.instance.recordActive();
  }

  Future<void> _recordLastSeen() async {
    await User.instance.recordLastSeen();
  }
}
