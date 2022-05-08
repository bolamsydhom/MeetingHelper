import 'dart:math';

import 'package:churchdata_core/churchdata_core.dart';
import 'package:churchdata_core_mocks/churchdata_core.dart';
import 'package:collection/collection.dart';
import 'package:device_info_plus_platform_interface/device_info_plus_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:meetinghelper/models.dart';
import 'package:meetinghelper/repositories.dart';
import 'package:meetinghelper/utils/globals.dart';
import 'package:meetinghelper/views/edit_pages/edit_person.dart';
import 'package:meetinghelper/views/root.dart';
import 'package:meetinghelper/widgets.dart';
import 'package:mock_data/mock_data.dart';
import 'package:mockito/annotations.dart';

import '../utils.dart';

@GenerateMocks([MHAuthRepository])
void main() {
  final StructureTestVariants structureTestVariants = StructureTestVariants();

  group(
    'Root View tests:',
    () {
      setUp(() async {
        registerFirebaseMocks();
        setUpMHPlatformChannels();
        await initFakeCore();

        DeviceInfoPlatform.instance = FakeDeviceInfo();

        navigator = GlobalKey();

        GetIt.I.registerSingleton<MHViewableObjectTapHandler>(
            MHViewableObjectTapHandler(navigator));

        HivePersistenceProvider.instance =
            AllCompletedHivePersistenceProvider();
      });

      tearDown(() async {
        await GetIt.I.reset();
      });

      testWidgets(
        'Structure',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(1080 * 3, 2400 * 3));

          await tester.pumpWidget(
            wrapWithMaterialApp(
              const Root(),
              navigatorKey: navigator,
            ),
          );
          await tester.pumpAndSettle();

          final currentPermissions = structureTestVariants.current!;

          expect(find.byIcon(Icons.search), findsOneWidget);
          expect(find.byIcon(Icons.notifications), findsOneWidget);
          expect(
            find.widgetWithIcon(FloatingActionButton, Icons.group_add),
            findsNWidgets(currentPermissions.write ? 1 : 0),
          );

          expect(
            find.descendant(
                of: find.byType(TabBar), matching: find.text('الخدام')),
            findsNWidgets(currentPermissions.manageUsers ||
                    currentPermissions.manageAllowedUsers
                ? 1
                : 0),
          );
          expect(
            find.descendant(
                of: find.byType(TabBar), matching: find.text('الخدمات')),
            findsOneWidget,
          );
          expect(
            find.descendant(
                of: find.byType(TabBar), matching: find.text('المخدومين')),
            findsOneWidget,
          );

          if (currentPermissions.manageUsers ||
              currentPermissions.manageAllowedUsers) {
            await tester.tap(
              find.descendant(
                  of: find.byType(TabBar), matching: find.text('الخدام')),
            );
            await tester.pumpAndSettle();
            expect(
              find.byType(
                DataObjectListView<Class?, UserWithPerson>,
              ),
              findsOneWidget,
            );
            expect(find.text('0 خادم'), findsOneWidget);
          }

          await tester.tap(
            find.descendant(
                of: find.byType(TabBar), matching: find.text('الخدمات')),
          );
          await tester.pumpAndSettle();
          expect(find.byType(ServicesList), findsOneWidget);
          expect(find.text('0 خدمة'), findsOneWidget);

          await tester.tap(
            find.descendant(
                of: find.byType(TabBar), matching: find.text('المخدومين')),
          );
          await tester.pumpAndSettle();
          expect(
            find.byType(
              DataObjectListView<void, Person>,
            ),
            findsOneWidget,
          );
          expect(find.text('0 مخدوم'), findsOneWidget);

          //Drawer
          expect(find.byIcon(Icons.menu), findsOneWidget);
          await tester.tap(
            find.byIcon(Icons.menu),
          );
          await tester.pumpAndSettle();

          expect(find.widgetWithText(ListTile, 'حسابي'), findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'إدارة المستخدمين'),
            findsNWidgets(currentPermissions.manageUsers ||
                    currentPermissions.manageAllowedUsers
                ? 1
                : 0),
          );
          expect(
            find.widgetWithText(ListTile, 'كشف حضور المخدومين'),
            findsNWidgets(currentPermissions.recordHistory ? 1 : 0),
          );
          expect(
            find.widgetWithText(ListTile, 'كشف حضور الخدام'),
            findsNWidgets(currentPermissions.secretary ? 1 : 0),
          );
          expect(find.widgetWithText(ListTile, 'السجل'), findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'سجل الخدام'),
            findsNWidgets(currentPermissions.secretary ? 1 : 0),
          );
          expect(find.widgetWithText(ListTile, 'تحليل سجل المخدومين'),
              findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'تحليل بيانات سجل الخدام'),
            findsNWidgets(currentPermissions.secretary ? 1 : 0),
          );
          expect(
            find.widgetWithText(ListTile, 'تحليل بيانات الخدمة'),
            findsNWidgets(currentPermissions.manageUsers ||
                    currentPermissions.manageAllowedUsers
                ? 1
                : 0),
          );
          expect(find.widgetWithText(ListTile, 'بحث مفصل'), findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'سلة المحذوفات'),
            findsNWidgets(currentPermissions.manageDeleted ? 1 : 0),
          );
          expect(find.widgetWithText(ListTile, 'عرض خريطة الافتقاد'),
              findsOneWidget);
          expect(find.widgetWithText(ListTile, 'الإعدادات'), findsOneWidget);
          expect(find.widgetWithText(ListTile, 'استيراد من ملف اكسل'),
              findsOneWidget);
          expect(
            find.widgetWithText(ListTile, 'تصدير فصل إلى ملف اكسل'),
            findsNWidgets(currentPermissions.export ? 1 : 0),
          );
          expect(
            find.widgetWithText(ListTile, 'تصدير جميع البيانات'),
            findsNWidgets(currentPermissions.export ? 1 : 0),
          );
          expect(
            find.widgetWithText(ListTile, 'عمليات التصدير السابقة'),
            findsNWidgets(currentPermissions.export ? 1 : 0),
          );
          expect(
              find.widgetWithText(ListTile, 'تحديث البرنامج'), findsOneWidget);
          expect(find.widgetWithText(ListTile, 'حول البرنامج'), findsOneWidget);
          expect(find.widgetWithText(ListTile, 'تسجيل الخروج'), findsOneWidget);
        },
        variant: structureTestVariants,
      );

      group(
        'Functionality:',
        () {
          setUp(
            () async {
              await mockMHUser(
                user: User(
                  ref: GetIt.I<DatabaseRepository>()
                      .collection('UsersData')
                      .doc('personId'),
                  uid: 'uid',
                  name: 'displayName',
                  email: 'email',
                  password: 'password',
                  permissions: MHPermissionsSet.fromJson(
                    const {
                      'approved': true,
                      'birthdayNotify': true,
                      'changeHistory': true,
                      'confessionsNotify': true,
                      'export': true,
                      'kodasNotify': true,
                      'manageAllowedUsers': true,
                      'manageDeleted': true,
                      'manageUsers': true,
                      'meetingNotify': true,
                      'secretary': true,
                      'recordHistory': true,
                      'superAccess': true,
                      'tanawolNotify': true,
                      'visitNotify': true,
                      'write': true,
                      'personId': 'personId',
                    },
                  ),
                  lastTanawol: DateTime.now(),
                  lastConfession: DateTime.now(),
                ),
              );
            },
          );
          testWidgets(
            'Adding new entity',
            (tester) async {
              await tester.pumpWidget(
                wrapWithMaterialApp(
                  const Root(),
                  navigatorKey: navigator,
                  routes: {
                    'Data/EditClass': (context) => const Text('EditClass'),
                    'Data/EditService': (context) => const Text('EditService'),
                    'Data/EditPerson': (context) => const Text('EditPerson'),
                  },
                ),
              );
              await tester.pumpAndSettle();

              await tester.tap(find.widgetWithIcon(
                FloatingActionButton,
                Icons.group_add,
              ));
              await tester.pumpAndSettle();

              expect(find.byType(Dialog), findsOneWidget);
              expect(find.text('اضافة فصل'), findsOneWidget);
              expect(find.text('اضافة خدمة'), findsOneWidget);

              await tester.tap(find.text('اضافة فصل'));
              await tester.pumpAndSettle();

              expect(find.text('EditClass'), findsOneWidget);

              navigator.currentState!.pop();
              await tester.pumpAndSettle();

              await tester.tap(find.widgetWithIcon(
                FloatingActionButton,
                Icons.group_add,
              ));
              await tester.pumpAndSettle();

              await tester.tap(find.text('اضافة خدمة'));
              await tester.pumpAndSettle();

              expect(find.text('EditService'), findsOneWidget);

              navigator.currentState!.pop();
              await tester.pumpAndSettle();

              await tester.tap(
                find.descendant(
                    of: find.byType(TabBar), matching: find.text('الخدام')),
              );
              await tester.pumpAndSettle();

              await tester.tap(find.widgetWithIcon(
                FloatingActionButton,
                Icons.person_add,
              ));
              await tester.pumpAndSettle();

              expect(find.byType(EditPerson), findsOneWidget);
              expect(
                  tester
                      .firstWidget<EditPerson>(find.byType(EditPerson))
                      .person,
                  isNotNull);
              expect(
                  tester
                      .firstWidget<EditPerson>(find.byType(EditPerson))
                      .person!
                      .ref
                      .parent
                      .id,
                  'UsersData');

              navigator.currentState!.pop();
              await tester.pumpAndSettle();

              await tester.tap(
                find.descendant(
                    of: find.byType(TabBar), matching: find.text('المخدومين')),
              );
              await tester.pumpAndSettle();

              await tester.tap(find.widgetWithIcon(
                FloatingActionButton,
                Icons.person_add,
              ));
              await tester.pumpAndSettle();

              expect(find.text('EditPerson'), findsOneWidget);
            },
          );

          testWidgets(
            'Displayed data',
            (tester) async {
              final mockData = await setUpMockData();

              await tester.binding
                  .setSurfaceSize(const Size(1080 * 3, 2400 * 3));

              await tester.pumpWidget(
                wrapWithMaterialApp(
                  const Root(),
                  navigatorKey: navigator,
                ),
              );
              await tester.pumpAndSettle();

              /* expect(find.text('ابتدائي'), findsOneWidget);
              expect(find.text('اعدادي'), findsOneWidget);
              expect(find.text('ثانوي'), findsOneWidget);

              expect(find.text(studyYears.values.first.name), findsOneWidget);
              await tester.tap(find.text(studyYears.values.first.name));
              await tester.pumpAndSettle();

              for (final class$ in classes) {
                expect(
                  find.widgetWithText(
                    ViewableObjectWidget<Class>,
                    class$.name,
                  ),
                  findsOneWidget,
                );
              } */
              await tester.tap(find.text('المخدومين'));
              await tester.pumpAndSettle();

              for (final person in mockData.item1) {
                expect(
                  find.widgetWithText(
                    ViewableObjectWidget<Person>,
                    person.name,
                  ),
                  findsOneWidget,
                );
              }

              await tester.tap(find.text('الخدام'));
              await tester.pumpAndSettle();

              await tester.tap(find.text('غير محددة'));
              await tester.pumpAndSettle();

              for (final user in mockData.item2) {
                expect(
                  find.widgetWithText(
                    ViewableObjectWidget<UserWithPerson>,
                    user.name,
                  ),
                  findsOneWidget,
                );
              }
            },
          );

          testWidgets(
            'Search',
            (tester) async {
              final mockData = await setUpMockData();

              await tester.binding
                  .setSurfaceSize(const Size(1080 * 3, 2400 * 3));

              await tester.pumpWidget(
                wrapWithMaterialApp(
                  const Root(),
                  navigatorKey: navigator,
                ),
              );
              await tester.pumpAndSettle();

              await tester.tap(find.text('المخدومين'));
              await tester.pumpAndSettle();

              await tester.tap(find.byIcon(Icons.search));
              await tester.pumpAndSettle();

              expect(
                find.descendant(
                  of: find.byType(AppBar),
                  matching: find.byType(TextField),
                ),
                findsOneWidget,
              );

              final searchString = mockData
                  .item1[Random().nextInt(mockData.item1.length)].name
                  .substring(0, 3);

              await tester.enterText(
                find.descendant(
                  of: find.byType(AppBar),
                  matching: find.byType(TextField),
                ),
                searchString,
              );
              await tester.pumpAndSettle();

              for (final person in mockData.item1) {
                expect(
                  find.widgetWithText(
                    ViewableObjectWidget<Person>,
                    person.name,
                  ),
                  person.name.contains(searchString)
                      ? findsOneWidget
                      : findsNothing,
                );
              }

              await tester.tap(find.text('الخدام'));
              await tester.pumpAndSettle();

              if (mockData.item2
                  .where((u) => u.name.contains(searchString))
                  .isNotEmpty) {
                await tester.tap(find.text('غير محددة'));
                await tester.pumpAndSettle();
              }

              for (final user in mockData.item2) {
                expect(
                  find.widgetWithText(
                    ViewableObjectWidget<UserWithPerson>,
                    user.name,
                  ),
                  user.name.contains(searchString)
                      ? findsOneWidget
                      : findsNothing,
                );
              }
            },
          );
        },
      );
    },
  );
}

Future<Tuple2<List<Person>, List<UserWithPerson>>> setUpMockData() async {
  final personsRef = MHDatabaseRepo.I.collection('Persons');
  final usersRef = MHDatabaseRepo.I.collection('UsersData');
  /* final classesRef = MHDatabaseRepo.I.collection('Classes');
              final servicesRef = MHDatabaseRepo.I.collection('Services');
              final studyYearsRef = MHDatabaseRepo.I.collection('StudyYears'); */

  final persons = List.generate(
    20,
    (_) => Person(
      ref: personsRef.doc(),
      name: mockName() + '-' + mockString(),
    ),
  ).sorted(
    (a, b) => a.name.compareTo(b.name),
  );

  final users = List.generate(
    20,
    (_) => UserWithPerson(
      uid: 'uid',
      permissions: const MHPermissionsSet.empty(),
      adminServices: const [],
      allowedUsers: const [],
      ref: usersRef.doc(),
      name: mockName() + '-' + mockString(),
    ),
  ).sorted(
    (a, b) => a.name.compareTo(b.name),
  );

  /* final studyYears = {
                1: StudyYear(
                  ref: studyYearsRef.doc(),
                  name: 'أولى ابتدائي',
                  grade: 1,
                ),
                2: StudyYear(
                  ref: studyYearsRef.doc(),
                  name: 'تانية ابتدائي',
                  grade: 2,
                ),
                7: StudyYear(
                  ref: studyYearsRef.doc(),
                  name: 'أولى اعدادي',
                  grade: 7,
                ),
                10: StudyYear(
                  ref: studyYearsRef.doc(),
                  name: 'أولى ثانوي',
                  grade: 10,
                ),
              };

              final classes = [
                Class(
                  ref: classesRef.doc(),
                  name: '1 ب ولاد',
                  studyYear: studyYears[1]!.ref,
                ),
                Class(
                  ref: classesRef.doc(),
                  name: '1 ب ولاد',
                  studyYear: studyYears[1]!.ref,
                  gender: false,
                ),
                Class(
                  ref: classesRef.doc(),
                  name: '2 ب',
                  studyYear: studyYears[2]!.ref,
                  gender: null,
                ),
                Class(
                  ref: classesRef.doc(),
                  name: '1 ع',
                  studyYear: studyYears[7]!.ref,
                  gender: null,
                ),
                Class(
                  ref: classesRef.doc(),
                  name: '1 ث',
                  studyYear: studyYears[10]!.ref,
                  gender: null,
                ),
              ];

              final service = Service(
                ref: servicesRef.doc(),
                name: 'خدمة أخرى',
                lastEdit: null,
              ); */

  await Future.wait(persons
          .map(
            (p) => p.set(),
          )
          .followedBy(
            users.map(
              (u) => u.ref.set(
                {
                  ...u.userJson(),
                  'Permissions': u.permissions.toJson(),
                },
              ),
            ),
          )
      /* .followedBy(
                      studyYears.values.map(
                        (s) => s.set(),
                      ),
                    )
                    .followedBy(
                      classes.map(
                        (s) => s.set(),
                      ),
                    )
                    .followedBy(
                  [
                    service.set(),
                  ],
                ), */
      );
  return Tuple2(persons, users);
}

class AllCompletedHivePersistenceProvider implements HivePersistenceProvider {
  @override
  Future<void> clearStep(String featureId) async {}

  @override
  Future<void> clearSteps(Iterable<String> featuresIds) async {}

  @override
  Future<void> completeStep(String? featureId) async {}

  @override
  Set<String> completedSteps(Iterable<String?>? featuresIds) {
    return featuresIds?.whereType<String>().toSet() ?? {};
  }

  @override
  bool hasCompletedStep(String featureId) {
    return true;
  }
}

class FakeDeviceInfo extends DeviceInfoPlatform {
  @override
  Future<AndroidDeviceInfo> androidInfo() async {
    return AndroidDeviceInfo(
      version: FakeAndroidBuildVersion(),
      supported32BitAbis: [],
      supported64BitAbis: [],
      supportedAbis: [],
      systemFeatures: [],
    );
  }
}

class FakeAndroidBuildVersion implements AndroidBuildVersion {
  @override
  String? get baseOS => null;

  @override
  String? get codename => null;

  @override
  String? get incremental => null;

  @override
  int? get previewSdkInt => null;

  @override
  String? get release => null;

  @override
  int? get sdkInt => 22;

  @override
  String? get securityPatch => null;

  @override
  Map<String, dynamic> toMap() {
    return {};
  }
}

class StructureTestVariants extends TestVariant<MHPermissionsSet> {
  MHPermissionsSet? _current;
  MHPermissionsSet? get current => _current;

  @override
  String describeValue(MHPermissionsSet value) {
    final filtered = value.toJson().entries.where((kv) => !kv.value);
    return filtered.isEmpty ? 'Admin' : Map.fromEntries(filtered).toString();
  }

  @override
  Future<MHPermissionsSet> setUp(MHPermissionsSet value) async {
    await mockMHUser(
      user: User(
        ref: GetIt.I<DatabaseRepository>()
            .collection('UsersData')
            .doc('personId'),
        uid: 'uid',
        name: 'displayName',
        email: 'email',
        password: 'password',
        permissions: value,
        lastTanawol: DateTime.now(),
        lastConfession: DateTime.now(),
      ),
    );
    return _current = value;
  }

  @override
  Future<void> tearDown(
      MHPermissionsSet value, covariant Object? memento) async {
    await GetIt.I.popScope();
  }

  @override
  Iterable<MHPermissionsSet> get values sync* {
    final basePermissions = MHPermissionsSet.fromJson(
      const {
        'approved': true,
        'birthdayNotify': true,
        'changeHistory': true,
        'confessionsNotify': true,
        'export': true,
        'kodasNotify': true,
        'manageAllowedUsers': true,
        'manageDeleted': true,
        'manageUsers': true,
        'meetingNotify': true,
        'secretary': true,
        'recordHistory': true,
        'superAccess': true,
        'tanawolNotify': true,
        'visitNotify': true,
        'write': true,
        'personId': 'personId',
      },
    );

    yield basePermissions;
    yield basePermissions.copyWith(write: false);
    yield basePermissions.copyWith(manageUsers: false);
    yield basePermissions.copyWith(manageAllowedUsers: false);
    yield basePermissions.copyWith(recordHistory: false);
    yield basePermissions.copyWith(secretary: false);
    yield basePermissions.copyWith(manageDeleted: false);
    yield basePermissions.copyWith(export: false);
  }
}
