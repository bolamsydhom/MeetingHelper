import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.io) 'package:firebase_crashlytics/firebase_crashlytics.dart'
    if (dart.library.html) 'package:meetinghelper/crashlytics_web.dart';
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:meetinghelper/models/data/service.dart';
import 'package:meetinghelper/models/list_controllers.dart';
import 'package:meetinghelper/utils/globals.dart';
import 'package:meetinghelper/utils/typedefs.dart';
import 'package:meetinghelper/views/form_widgets/tapable_form_field.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:tinycolor2/tinycolor2.dart';

import '../../models/data/user.dart';
import '../../models/mini_models.dart';
import '../../models/search/search_filters.dart';
import '../lists/users_list.dart';
import '../mini_lists/colors_list.dart';

class EditService extends StatefulWidget {
  final Service? service;

  const EditService({Key? key, required this.service}) : super(key: key);
  @override
  _EditServiceState createState() => _EditServiceState();
}

class _EditServiceState extends State<EditService> {
  String? changedImage;
  bool deletePhoto = false;
  GlobalKey<FormState> form = GlobalKey<FormState>();
  List<User>? allowedUsers;

  late Service service;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              actions: <Widget>[
                if (service.id != 'null')
                  IconButton(
                    onPressed: _delete,
                    icon: const Icon(Icons.delete),
                    tooltip: 'حذف',
                  ),
                IconButton(
                  icon: Builder(
                    builder: (context) => Stack(
                      children: <Widget>[
                        const Positioned(
                          left: 1.0,
                          top: 2.0,
                          child:
                              Icon(Icons.photo_camera, color: Colors.black54),
                        ),
                        Icon(Icons.photo_camera,
                            color: IconTheme.of(context).color),
                      ],
                    ),
                  ),
                  onPressed: _selectImage,
                )
              ],
              backgroundColor: service.color != Colors.transparent
                  ? (Theme.of(context).brightness == Brightness.light
                      ? TinyColor(service.color).lighten().color
                      : TinyColor(service.color).darken().color)
                  : null,
              //title: Text(widget.me.name),
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) => FlexibleSpaceBar(
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: constraints.biggest.height > kToolbarHeight * 1.7
                        ? 0
                        : 1,
                    child: Text(service.name,
                        style: const TextStyle(
                          fontSize: 16.0,
                        )),
                  ),
                  background: changedImage == null || deletePhoto
                      ? service.photo(cropToCircle: false)
                      : PhotoView(
                          imageProvider: FileImage(File(changedImage!))),
                ),
              ),
            ),
          ];
        },
        body: Form(
          key: form,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'اسم الخدمة'),
                    initialValue: service.name,
                    onChanged: (v) => service.name = v,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'يجب ملئ اسم الخدمة';
                      }
                      return null;
                    },
                  ),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'السنوات الدراسية',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'ازالة',
                        onPressed: () {
                          setState(() => service.studyYearRange = null);
                        },
                      ),
                    ),
                    child: FutureBuilder<JsonQuery>(
                      future: StudyYear.getAllForUser(),
                      builder: (conext, data) {
                        if (!data.hasData)
                          return const LinearProgressIndicator();

                        return Row(
                          children: [
                            Flexible(
                              child: DropdownButtonFormField<JsonRef?>(
                                value: service.studyYearRange?.from,
                                items: data.data!.docs
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item.reference,
                                        child: Text(item.data()['Name']),
                                      ),
                                    )
                                    .toList()
                                  ..insert(
                                    0,
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text(''),
                                    ),
                                  ),
                                onChanged: (value) {
                                  if (service.studyYearRange == null)
                                    service.studyYearRange =
                                        StudyYearRange(from: value, to: null);
                                  else
                                    service.studyYearRange!.from = value;

                                  setState(() {});

                                  FocusScope.of(context).nextFocus();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'من',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            Flexible(
                              child: DropdownButtonFormField<JsonRef?>(
                                value: service.studyYearRange?.to,
                                items: data.data!.docs
                                    .map(
                                      (item) => DropdownMenuItem(
                                        value: item.reference,
                                        child: Text(item.data()['Name']),
                                      ),
                                    )
                                    .toList()
                                  ..insert(
                                    0,
                                    const DropdownMenuItem(
                                      value: null,
                                      child: Text(''),
                                    ),
                                  ),
                                onChanged: (value) {
                                  if (service.studyYearRange == null)
                                    service.studyYearRange =
                                        StudyYearRange(from: null, to: value);
                                  else
                                    service.studyYearRange!.to = value;

                                  setState(() {});

                                  FocusScope.of(context).nextFocus();
                                },
                                decoration: const InputDecoration(
                                  labelText: 'الى',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'مدة الصلاحية',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'ازالة',
                        onPressed: () {
                          setState(() => service.validity = null);
                        },
                      ),
                    ),
                    child: Row(
                      children: [
                        Flexible(
                          child: TapableFormField<DateTime?>(
                            initialValue: service.validity?.start,
                            onTap: (state) async {
                              final from = await _selectDate(
                                    'الصلاحية: من',
                                    state.value ?? DateTime.now(),
                                  ) ??
                                  state.value;
                              if (from == null) return;

                              service.validity = DateTimeRange(
                                start: from,
                                end: service.validity?.end ??
                                    from.add(const Duration(days: 365)),
                              );

                              state.didChange(from);
                            },
                            decoration: (context, state) => InputDecoration(
                              labelText: 'من',
                              errorText: state.errorText,
                              border: InputBorder.none,
                            ),
                            builder: (context, state) {
                              return state.value != null
                                  ? Text(DateFormat('yyyy/M/d')
                                      .format(state.value!))
                                  : null;
                            },
                            validator: (_) => null,
                          ),
                        ),
                        Flexible(
                          child: TapableFormField<DateTime?>(
                            initialValue: service.validity?.end,
                            onTap: (state) async {
                              final to = await _selectDate(
                                    'الصلاحية: الى',
                                    state.value ?? DateTime.now(),
                                  ) ??
                                  state.value;
                              if (to == null) return;

                              service.validity = DateTimeRange(
                                end: to,
                                start: service.validity?.start ??
                                    to.subtract(const Duration(days: 365)),
                              );

                              state.didChange(to);
                            },
                            decoration: (context, state) => InputDecoration(
                              labelText: 'الى',
                              errorText: state.errorText,
                              border: InputBorder.none,
                            ),
                            builder: (context, state) {
                              return state.value != null
                                  ? Text(DateFormat('yyyy/M/d')
                                      .format(state.value!))
                                  : null;
                            },
                            validator: (_) => null,
                          ),
                        ),
                      ],
                    ),
                  ),
                  CheckboxListTile(
                    title: const Text('اظهار كبند في السجل'),
                    value: service.showInHistory,
                    onChanged: (v) =>
                        setState(() => service.showInHistory = v!),
                  ),
                  ElevatedButton.icon(
                    style: service.color != Colors.transparent
                        ? ElevatedButton.styleFrom(
                            primary:
                                Theme.of(context).brightness == Brightness.light
                                    ? TinyColor(service.color).lighten().color
                                    : TinyColor(service.color).darken().color,
                          )
                        : null,
                    onPressed: selectColor,
                    icon: const Icon(Icons.color_lens),
                    label: const Text('اللون'),
                  ),
                  if (User.instance.manageAllowedUsers ||
                      User.instance.manageUsers)
                    ElevatedButton.icon(
                      style: service.color != Colors.transparent
                          ? ElevatedButton.styleFrom(
                              primary: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? TinyColor(service.color).lighten().color
                                  : TinyColor(service.color).darken().color,
                            )
                          : null,
                      icon: const Icon(Icons.visibility),
                      onPressed: _selectAllowedUsers,
                      label: const Text(
                        'الخدام المسؤلين عن الخدمة والمخدومين داخلها',
                        softWrap: false,
                        textScaleFactor: 0.95,
                        overflow: TextOverflow.fade,
                      ),
                    ),
                ].map((w) => Focus(child: w)).toList(),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'حفظ',
        onPressed: save,
        child: const Icon(Icons.save),
      ),
    );
  }

  Future<void> _selectImage() async {
    final source = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: <Widget>[
          TextButton.icon(
            onPressed: () => navigator.currentState!.pop(true),
            icon: const Icon(Icons.camera),
            label: const Text('التقاط صورة من الكاميرا'),
          ),
          TextButton.icon(
            onPressed: () => navigator.currentState!.pop(false),
            icon: const Icon(Icons.photo_library),
            label: const Text('اختيار من المعرض'),
          ),
          if (changedImage != null || service.hasPhoto)
            TextButton.icon(
              onPressed: () => navigator.currentState!.pop('delete'),
              icon: const Icon(Icons.delete),
              label: const Text('حذف الصورة'),
            ),
        ],
      ),
    );
    if (source == null) return;
    if (source == 'delete') {
      changedImage = null;
      deletePhoto = true;
      service.hasPhoto = false;
      setState(() {});
      return;
    }
    if (source as bool && !(await Permission.camera.request()).isGranted)
      return;

    final selectedImage = await ImagePicker()
        .pickImage(source: source ? ImageSource.camera : ImageSource.gallery);
    if (selectedImage == null) return;
    changedImage = (await ImageCropper.cropImage(
            sourcePath: selectedImage.path,
            cropStyle: CropStyle.circle,
            androidUiSettings: AndroidUiSettings(
                toolbarTitle: 'قص الصورة',
                toolbarColor: Theme.of(context).colorScheme.primary,
                initAspectRatio: CropAspectRatioPreset.original,
                lockAspectRatio: false)))
        ?.path;
    deletePhoto = false;
    setState(() {});
  }

  void _delete() async {
    if (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(service.name),
            content:
                Text('هل أنت متأكد من حذف ${service.name} وكل ما به مخدومين؟'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  navigator.currentState!.pop(true);
                },
                child: const Text('نعم'),
              ),
              TextButton(
                onPressed: () {
                  navigator.currentState!.pop();
                },
                child: const Text('تراجع'),
              ),
            ],
          ),
        ) ==
        true) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار حذف الخدمة...'),
          duration: Duration(seconds: 2),
        ),
      );
      if (await Connectivity().checkConnectivity() != ConnectivityResult.none) {
        if (service.hasPhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('ServicesPhotos/${service.id}')
              .delete();
        }
        await service.ref.delete();
      } else {
        if (service.hasPhoto) {
          // ignore: unawaited_futures
          FirebaseStorage.instance
              .ref()
              .child('ServicesPhotos/${service.id}')
              .delete();
        }
        // ignore: unawaited_futures
        service.ref.delete();
      }
      navigator.currentState!.pop('deleted');
    }
  }

  @override
  void initState() {
    super.initState();
    service = (widget.service ?? Service.empty()).copyWith();
  }

  void nameChanged(String value) {
    service.name = value;
  }

  Future save() async {
    try {
      if (form.currentState!.validate()) {
        form.currentState!.save();
        scaffoldMessenger.currentState!.showSnackBar(
          const SnackBar(
            content: Text('جار الحفظ...'),
            duration: Duration(minutes: 20),
          ),
        );
        final update = service.id != 'null';
        if (!update) {
          service.ref = FirebaseFirestore.instance.collection('Services').doc();
        }
        if (changedImage != null) {
          await FirebaseStorage.instance
              .ref()
              .child('ServicesPhotos/${service.id}')
              .putFile(File(changedImage!));
          service.hasPhoto = true;
        } else if (deletePhoto) {
          await FirebaseStorage.instance
              .ref()
              .child('ServicesPhotos/${service.id}')
              .delete();
        }

        service.lastEdit = auth.FirebaseAuth.instance.currentUser!.uid;

        if (update &&
            await Connectivity().checkConnectivity() !=
                ConnectivityResult.none) {
          await service.update(old: widget.service?.getMap() ?? {});
        } else if (update) {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          service.update(old: widget.service?.getMap() ?? {});
        } else if (await Connectivity().checkConnectivity() !=
            ConnectivityResult.none) {
          await service.set();
        } else {
          //Intentionally unawaited because of no internet connection
          // ignore: unawaited_futures
          service.set();
        }
        scaffoldMessenger.currentState!.hideCurrentSnackBar();
        navigator.currentState!.pop(service.ref);
      }
    } catch (err, stkTrace) {
      await FirebaseCrashlytics.instance
          .setCustomKey('LastErrorIn', 'ServiceP.save');
      await FirebaseCrashlytics.instance.recordError(err, stkTrace);
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(SnackBar(
        content: Text(err.toString()),
        duration: const Duration(seconds: 7),
      ));
    }
  }

  void selectColor() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () {
              navigator.currentState!.pop();
              setState(() {
                service.color = Colors.transparent;
              });
            },
            child: const Text('بلا لون'),
          ),
        ],
        content: ColorsList(
          selectedColor: service.color,
          onSelect: (color) {
            navigator.currentState!.pop();
            setState(() {
              service.color = color;
            });
          },
        ),
      ),
    );
  }

  void _selectAllowedUsers() async {
    allowedUsers = await navigator.currentState!.push(
          MaterialPageRoute(
            builder: (context) {
              return StreamBuilder<List<User>>(
                stream: allowedUsers != null
                    ? Stream.value(allowedUsers!)
                    : FirebaseFirestore.instance
                        .collection('UsersData')
                        .where('AdminServices', arrayContains: service.ref)
                        .snapshots()
                        .map((value) => value.docs.map(User.fromDoc).toList()),
                builder: (c, users) {
                  if (!users.hasData)
                    return const Center(child: CircularProgressIndicator());
                  return MultiProvider(
                    providers: [
                      Provider<DataObjectListController<User>>(
                        create: (_) => DataObjectListController<User>(
                          selectionMode: true,
                          itemsStream: User.getAllForUser(),
                          selected: {
                            for (final item in users.data!) item.id: item
                          },
                        ),
                        dispose: (context, c) => c.dispose(),
                      )
                    ],
                    builder: (context, child) => Scaffold(
                      persistentFooterButtons: [
                        TextButton(
                          onPressed: () {
                            navigator.currentState!.pop(context
                                .read<DataObjectListController<User>>()
                                .selectedLatest
                                ?.values
                                .toList());
                          },
                          child: const Text('تم'),
                        )
                      ],
                      appBar: AppBar(
                        title: SearchField(
                            showSuffix: false,
                            searchStream: context
                                .read<DataObjectListController<User>>()
                                .searchQuery,
                            textStyle: Theme.of(context).textTheme.bodyText2),
                      ),
                      body: const UsersList(
                        autoDisposeController: false,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ) ??
        allowedUsers;
  }

  Future<DateTime?> _selectDate(String helpText, DateTime initialDate) async {
    final picked = await showDatePicker(
        helpText: helpText,
        locale: const Locale('ar', 'EG'),
        context: context,
        initialDate: initialDate,
        firstDate: DateTime(1500),
        lastDate: DateTime.now());
    if (picked != null && picked != initialDate) {
      return picked;
    }
    return null;
  }
}