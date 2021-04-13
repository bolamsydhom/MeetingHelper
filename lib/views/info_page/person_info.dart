import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:feature_discovery/feature_discovery.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tinycolor/tinycolor.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:meetinghelper/utils/globals.dart';

import '../../models/copiable_property.dart';
import '../../models/data_object_widget.dart';
import '../../models/history_property.dart';
import '../../models/models.dart';
import '../../models/user.dart';
import '../../utils/helpers.dart';

class PersonInfo extends StatefulWidget {
  final Person person;
  const PersonInfo({Key key, this.person}) : super(key: key);

  @override
  _PersonInfoState createState() => _PersonInfoState();
}

class _PersonInfoState extends State<PersonInfo> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(Duration(milliseconds: 300));
      FeatureDiscovery.discoverFeatures(context, [
        if (User.instance.write) 'Person.Edit',
        'Person.Share',
        if (User.instance.write) 'Person.LastVisit'
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool>(
      selector: (_, user) => user.write,
      builder: (c, permission, data) => StreamBuilder<Person>(
        initialData: widget.person,
        stream: widget.person.ref.snapshots().map(Person.fromDoc),
        builder: (context, data) {
          Person person = data.data;
          if (person == null)
            return Scaffold(
              body: Center(
                child: Text('تم حذف المخدوم'),
              ),
            );
          return Scaffold(
            body: NestedScrollView(
              headerSliverBuilder:
                  (BuildContext context, bool innerBoxIsScrolled) {
                return <Widget>[
                  SliverAppBar(
                    backgroundColor: person.color != Colors.transparent
                        ? (Theme.of(context).brightness == Brightness.light
                            ? TinyColor(person.color).lighten().color
                            : TinyColor(person.color).darken().color)
                        : null,
                    actions: person.ref.path.startsWith('Deleted')
                        ? <Widget>[
                            if (permission)
                              IconButton(
                                icon: Icon(Icons.restore),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  recoverDoc(context, person.ref.path);
                                },
                              )
                          ]
                        : <Widget>[
                            if (permission)
                              IconButton(
                                icon: DescribedFeatureOverlay(
                                  barrierDismissible: false,
                                  contentLocation: ContentLocation.below,
                                  featureId: 'Person.Edit',
                                  tapTarget: Icon(
                                    Icons.edit,
                                    color: IconTheme.of(context).color,
                                  ),
                                  title: Text('تعديل'),
                                  description: Column(
                                    children: <Widget>[
                                      Text('يمكنك تعديل البيانات من هنا'),
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
                                        onPressed: () => FeatureDiscovery
                                            .completeCurrentStep(context),
                                      ),
                                      OutlinedButton(
                                        onPressed: () =>
                                            FeatureDiscovery.dismissAll(
                                                context),
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
                                  backgroundColor:
                                      Theme.of(context).accentColor,
                                  targetColor: Colors.transparent,
                                  textColor: Theme.of(context)
                                      .primaryTextTheme
                                      .bodyText1
                                      .color,
                                  child: Builder(
                                    builder: (context) => Stack(
                                      children: <Widget>[
                                        Positioned(
                                          left: 1.0,
                                          top: 2.0,
                                          child: Icon(Icons.edit,
                                              color: Colors.black54),
                                        ),
                                        Icon(Icons.edit,
                                            color: IconTheme.of(context).color),
                                      ],
                                    ),
                                  ),
                                ),
                                onPressed: () async {
                                  dynamic result = await navigator.currentState
                                      .pushNamed('Data/EditPerson',
                                          arguments: person);
                                  if (result is DocumentReference) {
                                    scaffoldMessenger.currentState.showSnackBar(
                                      SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                  } else if (result == 'deleted')
                                    navigator.currentState.pop();
                                },
                                tooltip: 'تعديل',
                              ),
                            IconButton(
                              icon: DescribedFeatureOverlay(
                                barrierDismissible: false,
                                contentLocation: ContentLocation.below,
                                featureId: 'Person.Share',
                                tapTarget: Icon(
                                  Icons.share,
                                ),
                                title: Text('مشاركة البيانات'),
                                description: Column(
                                  children: <Widget>[
                                    Text(
                                        'يمكنك مشاركة البيانات بلينك يفتح البيانات مباشرة داخل البرنامج'),
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
                                          FeatureDiscovery.completeCurrentStep(
                                              context),
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
                                textColor: Theme.of(context)
                                    .primaryTextTheme
                                    .bodyText1
                                    .color,
                                child: Builder(
                                  builder: (context) => Stack(
                                    children: <Widget>[
                                      Positioned(
                                        left: 1.0,
                                        top: 2.0,
                                        child: Icon(Icons.share,
                                            color: Colors.black54),
                                      ),
                                      Icon(Icons.share,
                                          color: IconTheme.of(context).color),
                                    ],
                                  ),
                                ),
                              ),
                              onPressed: () async {
                                await Share.share(await sharePerson(person));
                              },
                              tooltip: 'مشاركة برابط',
                            ),
                            PopupMenuButton(
                              onSelected: (item) async {
                                await sendNotification(context, person);
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  PopupMenuItem(
                                      child: Text(
                                          'ارسال إشعار للمستخدمين عن المخدوم'))
                                ];
                              },
                            ),
                          ],
                    expandedHeight: 250.0,
                    floating: false,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                        title: AnimatedOpacity(
                          duration: Duration(milliseconds: 300),
                          opacity:
                              constraints.biggest.height > kToolbarHeight * 1.7
                                  ? 0
                                  : 1,
                          child: Text(
                            person.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        background: person.photo(),
                      ),
                    ),
                  ),
                ];
              },
              body: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      ListTile(
                        title: Text(person.name,
                            style: Theme.of(context).textTheme.headline6),
                      ),
                      PhoneNumberProperty(
                        'موبايل:',
                        person.phone,
                        (n) => _phoneCall(context, n),
                        (n) => _contactAdd(context, n, person),
                      ),
                      PhoneNumberProperty(
                        'موبايل (الأب):',
                        person.fatherPhone,
                        (n) => _phoneCall(context, n),
                        (n) => _contactAdd(context, n, person),
                      ),
                      PhoneNumberProperty(
                        'موبايل (الأم):',
                        person.motherPhone,
                        (n) => _phoneCall(context, n),
                        (n) => _contactAdd(context, n, person),
                      ),
                      if (person.phones != null)
                        ...person.phones.entries
                            .map(
                              (e) => PhoneNumberProperty(
                                e.key,
                                e.value,
                                (n) => _phoneCall(context, n),
                                (n) => _contactAdd(context, n, person),
                              ),
                            )
                            .toList(),
                      ListTile(
                        title: Text('السن:'),
                        subtitle: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(toDurationString(person.birthDate,
                                  appendSince: false)),
                            ),
                            Text(
                                person.birthDate != null
                                    ? DateFormat('yyyy/M/d').format(
                                        person.birthDate.toDate(),
                                      )
                                    : '',
                                style: Theme.of(context).textTheme.overline),
                          ],
                        ),
                      ),
                      CopiableProperty('العنوان:', person.address),
                      if (person.location != null &&
                          !person.ref.path.startsWith('Deleted'))
                        ElevatedButton.icon(
                          icon: Icon(Icons.map),
                          onPressed: () => navigator.currentState.push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: Text(person.name)),
                                body: person.getMapView(),
                              ),
                            ),
                          ),
                          label: Text('إظهار على الخريطة'),
                        ),
                      ListTile(
                        title: Text('المدرسة:'),
                        subtitle: FutureBuilder(
                          future: person.getSchoolName(),
                          builder: (context, data) {
                            if (data.hasData) return Text(data.data);
                            return LinearProgressIndicator();
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('الكنيسة:'),
                        subtitle: FutureBuilder(
                          future: person.getChurchName(),
                          builder: (context, data) {
                            if (data.hasData) return Text(data.data);
                            return LinearProgressIndicator();
                          },
                        ),
                      ),
                      ListTile(
                        title: Text('اب الاعتراف:'),
                        subtitle: FutureBuilder(
                          future: person.getCFatherName(),
                          builder: (context, data) {
                            if (data.hasData) return Text(data.data);
                            return LinearProgressIndicator();
                          },
                        ),
                      ),
                      CopiableProperty('ملاحظات', person.notes),
                      Divider(thickness: 1),
                      if (!person.ref.path.startsWith('Deleted'))
                        ElevatedButton.icon(
                          icon: Icon(Icons.analytics),
                          label: Text('احصائيات الحضور'),
                          onPressed: () => _showAnalytics(context, person),
                        ),
                      DayHistoryProperty('تاريخ أخر حضور اجتماع:',
                          person.lastMeeting, person.id, 'Meeting'),
                      DayHistoryProperty('تاريخ أخر حضور قداس:',
                          person.lastKodas, person.id, 'Kodas'),
                      DayHistoryProperty('تاريخ أخر تناول:', person.lastTanawol,
                          person.id, 'Tanawol'),
                      TimeHistoryProperty(
                          'تاريخ أخر اعتراف:',
                          person.lastConfession,
                          person.ref.collection('ConfessionHistory')),
                      Divider(thickness: 1),
                      HistoryProperty('تاريخ أخر زيارة:', person.lastVisit,
                          person.ref.collection('VisitHistory')),
                      HistoryProperty('تاريخ أخر مكالمة:', person.lastCall,
                          person.ref.collection('CallHistory')),
                      EditHistoryProperty(
                        'أخر تحديث للبيانات:',
                        person.lastEdit,
                        person.ref.collection('EditHistory'),
                      ),
                      if (!person.ref.path.startsWith('Deleted'))
                        ListTile(
                          title: Text('داخل فصل:'),
                          subtitle: person.classId != null &&
                                  person.classId.parent.id != 'null'
                              ? FutureBuilder<Class>(
                                  future: Class.fromId(person.classId.id),
                                  builder: (context, _class) => _class.hasData
                                      ? DataObjectWidget<Class>(_class.data,
                                          isDense: true)
                                      : LinearProgressIndicator(),
                                )
                              : Text('غير موجودة'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            floatingActionButton: permission &&
                    !person.ref.path.startsWith('Deleted')
                ? FloatingActionButton(
                    tooltip: 'تسجيل أخر زيارة اليوم',
                    onPressed: () => recordLastVisit(context, person),
                    child: DescribedFeatureOverlay(
                      onBackgroundTap: () async {
                        await FeatureDiscovery.completeCurrentStep(context);
                        return true;
                      },
                      onDismiss: () async {
                        await FeatureDiscovery.completeCurrentStep(context);
                        return true;
                      },
                      backgroundDismissible: true,
                      contentLocation: ContentLocation.above,
                      featureId: 'Person.LastVisit',
                      tapTarget: Icon(Icons.update),
                      title: Text('تسجيل أخر زيارة'),
                      description: Column(
                        children: [
                          Text('يمكنك تسجيل أخر زيارة للمخدوم بسرعة من هنا'),
                          OutlinedButton(
                            onPressed: () =>
                                FeatureDiscovery.completeCurrentStep(context),
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
                      targetColor: Theme.of(context).primaryColor,
                      textColor:
                          Theme.of(context).primaryTextTheme.bodyText1.color,
                      child: Icon(Icons.update),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  void recordLastVisit(BuildContext context, Person person) async {
    try {
      if (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('هل تريد تسجيل أخر زيارة ل' + person.name + '؟'),
              actions: [
                TextButton(
                  onPressed: () => navigator.currentState.pop(true),
                  child: Text('تسجيل أخر زيارة'),
                ),
                TextButton(
                  onPressed: () => navigator.currentState.pop(false),
                  child: Text('رجوع'),
                ),
              ],
            ),
          ) !=
          true) return;
      await person.ref.update({
        'LastVisit': Timestamp.now(),
        'LastEdit': FirebaseAuth.instance.currentUser.uid
      });
      scaffoldMessenger.currentState.showSnackBar(SnackBar(
        content: Text('تم بنجاح'),
      ));
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'PersonInfo.recordLastVisit');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      await showErrorDialog(context, 'حدث خطأ أثناء تحديث تاريخ اخر زيارة!');
    }
  }

  void _phoneCall(BuildContext context, String number) async {
    var result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text('هل تريد اجراء مكالمة الأن'),
        actions: [
          OutlinedButton.icon(
            icon: Icon(Icons.call),
            label: Text('اجراء مكالمة الأن'),
            onPressed: () => navigator.currentState.pop(true),
          ),
          TextButton.icon(
            icon: Icon(Icons.dialpad),
            label: Text('نسخ في لوحة الاتصال فقط'),
            onPressed: () => navigator.currentState.pop(false),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result) {
      await Permission.phone.request();
      await launch('tel:' + getPhone(number, false));
      var recordLastCall = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: Text('هل تريد تسجيل تاريخ هذه المكالمة؟'),
          actions: [
            TextButton(
              onPressed: () => navigator.currentState.pop(true),
              child: Text('نعم'),
            ),
            TextButton(
              onPressed: () => navigator.currentState.pop(false),
              child: Text('لا'),
            ),
          ],
        ),
      );
      if (recordLastCall == true) {
        await widget.person.ref.update(
            {'LastEdit': User.instance.uid, 'LastCall': Timestamp.now()});
        scaffoldMessenger.currentState.showSnackBar(
          SnackBar(
            content: Text('تم بنجاح'),
          ),
        );
      }
    } else
      await launch('tel://' + getPhone(number, false));
  }

  void _showAnalytics(BuildContext context, Person person) {
    navigator.currentState.pushNamed('Analytics', arguments: person);
  }

  Future<void> _contactAdd(
      BuildContext context, String phone, Person person) async {
    if ((await Permission.contacts.request()).isGranted) {
      TextEditingController _name = TextEditingController(text: person.name);
      if (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('ادخل اسم جهة الاتصال:'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(controller: _name),
                  Container(height: 10),
                  Text(phone ?? ''),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () => navigator.currentState.pop(true),
                    child: Text('حفظ جهة الاتصال'))
              ],
            ),
          ) ==
          true) {
        final c = Contact(
            photo: person.hasPhoto
                ? await person.photoRef.getData(100 * 1024 * 1024)
                : null,
            phones: [Phone(phone)])
          ..name.first = _name.text;
        await c.insert();
      }
    }
  }
}
