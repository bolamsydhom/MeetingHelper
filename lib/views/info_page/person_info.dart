import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' show FirebaseAuth;
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';
import 'package:meetinghelper/models/data/class.dart';
import 'package:meetinghelper/models/data/person.dart';
import 'package:meetinghelper/models/data/service.dart';
import 'package:meetinghelper/models/hive_persistence_provider.dart';
import 'package:meetinghelper/utils/globals.dart';
import 'package:meetinghelper/utils/typedefs.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tinycolor2/tinycolor2.dart';
import 'package:tuple/tuple.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/copiable_property.dart';
import '../../models/data/user.dart';
import '../../models/data_object_widget.dart';
import '../../models/history/history_property.dart';
import '../../utils/helpers.dart';

class PersonInfo extends StatefulWidget {
  final Person person;
  final Person? Function(JsonDoc) converter;
  final bool showMotherAndFatherPhones;
  const PersonInfo(
      {Key? key,
      required this.person,
      this.converter = Person.fromDoc,
      this.showMotherAndFatherPhones = true})
      : super(key: key);

  @override
  _PersonInfoState createState() => _PersonInfoState();
}

class _PersonInfoState extends State<PersonInfo> {
  final _edit = GlobalKey();
  final _share = GlobalKey();
  final _lastVisit = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 300));

      if (([
        if (User.instance.write) 'Person.Edit',
        'Person.Share',
        if (User.instance.write) 'Person.LastVisit'
      ]..removeWhere(HivePersistenceProvider.instance.hasCompletedStep))
          .isNotEmpty)
        TutorialCoachMark(
          context,
          focusAnimationDuration: const Duration(milliseconds: 200),
          targets: [
            if (User.instance.write)
              TargetFocus(
                enableOverlayTab: true,
                contents: [
                  TargetContent(
                    child: Text(
                      'تحديث بيانات المخدوم',
                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ],
                identify: 'Person.Edit',
                keyTarget: _edit,
                color: Theme.of(context).colorScheme.secondary,
              ),
            TargetFocus(
              enableOverlayTab: true,
              contents: [
                TargetContent(
                  child: Text(
                    'يمكنك مشاركة البيانات بلينك يفتح البيانات مباشرة داخل البرنامج',
                    style: Theme.of(context).textTheme.subtitle1?.copyWith(
                        color: Theme.of(context).colorScheme.onSecondary),
                  ),
                ),
              ],
              identify: 'Person.Share',
              keyTarget: _share,
              color: Theme.of(context).colorScheme.secondary,
            ),
            if (User.instance.write)
              TargetFocus(
                alignSkip: Alignment.topRight,
                enableOverlayTab: true,
                contents: [
                  TargetContent(
                    align: ContentAlign.top,
                    child: Text(
                      'يمكنك تسجيل أخر افتقاد للمخدوم بسرعة من هنا',
                      style: Theme.of(context).textTheme.subtitle1?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondary),
                    ),
                  ),
                ],
                identify: 'Person.LastVisit',
                keyTarget: _lastVisit,
                color: Theme.of(context).colorScheme.secondary,
              ),
          ],
          alignSkip: Alignment.bottomLeft,
          textSkip: 'تخطي',
          onClickOverlay: (t) async {
            await HivePersistenceProvider.instance.completeStep(t.identify);
          },
          onClickTarget: (t) async {
            await HivePersistenceProvider.instance.completeStep(t.identify);
          },
        ).show();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Selector<User, bool?>(
      selector: (_, user) => user.write,
      builder: (c, permission, data) => StreamBuilder<Person?>(
        initialData: widget.person,
        stream: widget.person.ref.snapshots().map(widget.converter),
        builder: (context, data) {
          final Person? person = data.data;
          if (person == null)
            return const Scaffold(
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
                            if (permission!)
                              IconButton(
                                icon: const Icon(Icons.restore),
                                tooltip: 'استعادة',
                                onPressed: () {
                                  recoverDoc(context, person.ref.path);
                                },
                              )
                          ]
                        : <Widget>[
                            if (permission!)
                              IconButton(
                                key: _edit,
                                icon: Builder(
                                  builder: (context) => Stack(
                                    children: <Widget>[
                                      const Positioned(
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
                                onPressed: () async {
                                  final dynamic result = await navigator
                                      .currentState!
                                      .pushNamed('Data/EditPerson',
                                          arguments: person);
                                  if (result is JsonRef) {
                                    scaffoldMessenger.currentState!
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('تم الحفظ بنجاح'),
                                      ),
                                    );
                                  } else if (result == 'deleted') {
                                    scaffoldMessenger.currentState!
                                        .hideCurrentSnackBar();
                                    scaffoldMessenger.currentState!
                                        .showSnackBar(
                                      const SnackBar(
                                        content: Text('تم الحذف بنجاح'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    navigator.currentState!.pop();
                                  }
                                },
                                tooltip: 'تعديل',
                              ),
                            IconButton(
                              key: _share,
                              icon: Builder(
                                builder: (context) => Stack(
                                  children: <Widget>[
                                    const Positioned(
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
                              onPressed: () async {
                                await Share.share(await sharePerson(person));
                              },
                              tooltip: 'مشاركة برابط',
                            ),
                            PopupMenuButton(
                              onSelected: (dynamic item) async {
                                await sendNotification(context, person);
                              },
                              itemBuilder: (BuildContext context) {
                                return [
                                  const PopupMenuItem(
                                    value: '',
                                    child: Text(
                                        'ارسال إشعار للمستخدمين عن المخدوم'),
                                  )
                                ];
                              },
                            ),
                          ],
                    expandedHeight: 250.0,
                    pinned: true,
                    flexibleSpace: LayoutBuilder(
                      builder: (context, constraints) => FlexibleSpaceBar(
                        title: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity:
                              constraints.biggest.height > kToolbarHeight * 1.7
                                  ? 0
                                  : 1,
                          child: Text(
                            person.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        background: person.photo(cropToCircle: false),
                      ),
                    ),
                  ),
                ];
              },
              body: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  if (widget.showMotherAndFatherPhones)
                    PhoneNumberProperty(
                      'موبايل (الأب):',
                      person.fatherPhone,
                      (n) => _phoneCall(context, n),
                      (n) => _contactAdd(context, n, person),
                    ),
                  if (widget.showMotherAndFatherPhones)
                    PhoneNumberProperty(
                      'موبايل (الأم):',
                      person.motherPhone,
                      (n) => _phoneCall(context, n),
                      (n) => _contactAdd(context, n, person),
                    ),
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
                    title: const Text('السن:'),
                    subtitle: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(toDurationString(person.birthDate,
                              appendSince: false)),
                        ),
                        Text(
                            person.birthDate != null
                                ? DateFormat('yyyy/M/d').format(
                                    person.birthDate!.toDate(),
                                  )
                                : '',
                            style: Theme.of(context).textTheme.overline),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('السنة الدراسية:'),
                    subtitle: FutureBuilder<String>(
                      future: person.getStudyYearName(),
                      builder: (context, data) {
                        if (data.hasData) return Text(data.data!);
                        return const LinearProgressIndicator();
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('داخل فصل:'),
                    subtitle: person.classId != null &&
                            person.classId!.parent.id != 'null'
                        ? FutureBuilder<Class?>(
                            future: Class.fromId(person.classId!.id),
                            builder: (context, _class) => _class
                                            .connectionState ==
                                        ConnectionState.done &&
                                    _class.hasData
                                ? DataObjectWidget<Class>(_class.data!,
                                    isDense: true)
                                : _class.connectionState == ConnectionState.done
                                    ? const Text('لا يمكن ايجاد الفصل')
                                    : const LinearProgressIndicator(),
                          )
                        : const Text('غير موجود'),
                  ),
                  _PersonServices(person: person),
                  ListTile(
                    title: const Text('النوع:'),
                    subtitle: Text(person.gender ? 'ذكر' : 'أنثى'),
                  ),
                  if (person.gender)
                    ListTile(
                      title: const Text('شماس؟'),
                      subtitle: Text(person.isShammas ? 'نعم' : 'لا'),
                    ),
                  if (person.gender && person.isShammas)
                    ListTile(
                      title: const Text('رتبة الشموسية:'),
                      subtitle: Text(person.shammasLevel ?? ''),
                    ),
                  CopiableProperty('العنوان:', person.address),
                  if (person.location != null &&
                      !person.ref.path.startsWith('Deleted'))
                    ElevatedButton.icon(
                      icon: const Icon(Icons.map),
                      onPressed: () => navigator.currentState!.push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(title: Text(person.name)),
                            body: person.getMapView(),
                          ),
                        ),
                      ),
                      label: const Text('إظهار على الخريطة'),
                    ),
                  FutureBuilder<Tuple2<String, String>>(
                    future: () async {
                      final studyYear = await (person.studyYear ??
                              (await person.classId?.get())
                                  ?.data()?['StudyYear'] as JsonRef?)
                          ?.get();
                      final isCollegeYear =
                          studyYear?.data()?['IsCollegeYear']?.toString() ==
                              'true';

                      return Tuple2(
                          isCollegeYear ? 'الكلية' : ':المدرسة:',
                          isCollegeYear
                              ? await person.getCollegeName()
                              : await person.getSchoolName());
                    }(),
                    builder: (context, data) {
                      if (data.hasError)
                        return ErrorWidget(data.error!);
                      else if (data.hasData)
                        return ListTile(
                          title: Text(data.requireData.item1),
                          subtitle: Text(data.requireData.item2),
                        );

                      return const LinearProgressIndicator();
                    },
                  ),
                  ListTile(
                    title: const Text('الكنيسة:'),
                    subtitle: FutureBuilder<String>(
                      future: person.getChurchName(),
                      builder: (context, data) {
                        if (data.hasData) return Text(data.data!);
                        return const LinearProgressIndicator();
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text('اب الاعتراف:'),
                    subtitle: FutureBuilder<String>(
                      future: person.getCFatherName(),
                      builder: (context, data) {
                        if (data.hasData) return Text(data.data!);
                        return const LinearProgressIndicator();
                      },
                    ),
                  ),
                  CopiableProperty('ملاحظات', person.notes),
                  const Divider(thickness: 1),
                  if (!person.ref.path.startsWith('Deleted'))
                    ElevatedButton.icon(
                      icon: const Icon(Icons.analytics),
                      label: const Text('احصائيات الحضور'),
                      onPressed: () => _showAnalytics(context, person),
                    ),
                  DayHistoryProperty('تاريخ أخر حضور اجتماع:',
                      person.lastMeeting, person.id, 'Meeting'),
                  DayHistoryProperty('تاريخ أخر حضور قداس:', person.lastKodas,
                      person.id, 'Kodas'),
                  TimeHistoryProperty(
                    'تاريخ أخر تناول:',
                    person.lastTanawol,
                    person.ref.collection('TanawolHistory'),
                  ),
                  TimeHistoryProperty(
                    'تاريخ أخر اعتراف:',
                    person.lastConfession,
                    person.ref.collection('ConfessionHistory'),
                  ),
                  const Divider(thickness: 1),
                  HistoryProperty(
                    'تاريخ أخر افتقاد:',
                    person.lastVisit,
                    person.ref.collection('VisitHistory'),
                  ),
                  HistoryProperty(
                    'تاريخ أخر مكالمة:',
                    person.lastCall,
                    person.ref.collection('CallHistory'),
                  ),
                  EditHistoryProperty(
                    'أخر تحديث للبيانات:',
                    person.lastEdit,
                    person.ref.collection('EditHistory'),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
            floatingActionButton:
                permission! && !person.ref.path.startsWith('Deleted')
                    ? FloatingActionButton(
                        key: _lastVisit,
                        tooltip: 'تسجيل أخر افتقاد اليوم',
                        onPressed: () => recordLastVisit(context, person),
                        child: const Icon(Icons.update),
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
              title: Text('هل تريد تسجيل أخر افتقاد ل' + person.name + '؟'),
              actions: [
                TextButton(
                  onPressed: () => navigator.currentState!.pop(true),
                  child: const Text('تسجيل أخر افتقاد'),
                ),
                TextButton(
                  onPressed: () => navigator.currentState!.pop(false),
                  child: const Text('رجوع'),
                ),
              ],
            ),
          ) !=
          true) return;
      await person.ref.update({
        'LastVisit': Timestamp.now(),
        'LastEdit': FirebaseAuth.instance.currentUser!.uid
      });
      scaffoldMessenger.currentState!.showSnackBar(const SnackBar(
        content: Text('تم بنجاح'),
      ));
    } catch (err, stack) {
      await Sentry.captureException(err,
          stackTrace: stack,
          withScope: (scope) =>
              scope.setTag('LasErrorIn', '_PersonInfoState.recordLastVisit'));
      await showErrorDialog(context, 'حدث خطأ أثناء تحديث تاريخ أخر افتقاد!');
    }
  }

  void _phoneCall(BuildContext context, String? number) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('هل تريد اجراء مكالمة الأن'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.call),
            label: const Text('اجراء مكالمة الأن'),
            onPressed: () => navigator.currentState!.pop(true),
          ),
          TextButton.icon(
            icon: const Icon(Icons.dialpad),
            label: const Text('نسخ في لوحة الاتصال فقط'),
            onPressed: () => navigator.currentState!.pop(false),
          ),
        ],
      ),
    );
    if (result == null) return;
    if (result) {
      await Permission.phone.request();
      await launch('tel:' + getPhone(number ?? '', false));
      final recordLastCall = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text('هل تريد تسجيل تاريخ هذه المكالمة؟'),
          actions: [
            TextButton(
              onPressed: () => navigator.currentState!.pop(true),
              child: const Text('نعم'),
            ),
            TextButton(
              onPressed: () => navigator.currentState!.pop(false),
              child: const Text('لا'),
            ),
          ],
        ),
      );
      if (recordLastCall == true) {
        await widget.person.ref.update(
            {'LastEdit': User.instance.uid, 'LastCall': Timestamp.now()});
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('تم بنجاح'),
          ),
        );
      }
    } else
      await launch('tel://' + getPhone(number ?? '', false));
  }

  void _showAnalytics(BuildContext context, Person person) {
    navigator.currentState!.pushNamed('Analytics', arguments: person);
  }

  Future<void> _contactAdd(
      BuildContext context, String? phone, Person person) async {
    if ((await Permission.contacts.request()).isGranted) {
      final TextEditingController _name =
          TextEditingController(text: person.name);
      if (await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('ادخل اسم جهة الاتصال:'),
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
                    onPressed: () => navigator.currentState!.pop(true),
                    child: const Text('حفظ جهة الاتصال'))
              ],
            ),
          ) ==
          true) {
        final c = Contact(
            photo: person.hasPhoto
                ? await person.photoRef.getData(100 * 1024 * 1024)
                : null,
            phones: [Phone(phone ?? '')])
          ..name.first = _name.text;
        await c.insert();
      }
    }
  }
}

class _PersonServices extends StatelessWidget {
  const _PersonServices({
    Key? key,
    required this.person,
  }) : super(key: key);

  final Person person;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('الخدمات المشارك بها'),
      subtitle: person.services.isNotEmpty
          ? FutureBuilder<List<String>>(
              future: Future.wait(
                person.services.take(2).map(
                      (s) async =>
                          Service.fromDoc(
                            await s.get(),
                          )?.name ??
                          '',
                    ),
              ),
              builder: (context, servicesSnapshot) {
                if (!servicesSnapshot.hasData)
                  return const LinearProgressIndicator();

                if (person.services.length > 2)
                  return Text(
                    servicesSnapshot.requireData.take(2).join(' و') +
                        'و ' +
                        (person.services.length - 2).toString() +
                        ' أخرين',
                  );

                return Text(servicesSnapshot.requireData.join(' و'));
              },
            )
          : const Text('لا يوجد خدمات'),
      trailing: person.services.isNotEmpty
          ? IconButton(
              icon: const Icon(Icons.info),
              tooltip: 'اظهار الخدمات',
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: FutureBuilder<List<Service>>(
                      future: () async {
                        return (await Future.wait(
                          person.services.map(
                            (s) async => Service.fromDoc(
                              await s.get(),
                            ),
                          ),
                        ))
                            .whereType<Service>()
                            .toList();
                      }(),
                      builder: (context, data) {
                        if (data.hasError) return ErrorWidget(data.error!);
                        if (!data.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        return ListView.builder(
                          padding: const EdgeInsetsDirectional.all(8),
                          shrinkWrap: true,
                          itemCount: person.services.length,
                          itemBuilder: (context, i) {
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: DataObjectWidget(
                                data.requireData[i],
                                showSubTitle: false,
                                wrapInCard: false,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }
}
