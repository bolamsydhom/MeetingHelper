import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:churchdata_core/churchdata_core.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' hide ListOptions;
import 'package:flutter/material.dart' hide Notification;
import 'package:get_it/get_it.dart';
import 'package:meetinghelper/models/data/class.dart';
import 'package:meetinghelper/models/data/service.dart';
import 'package:meetinghelper/repositories.dart';
import 'package:meetinghelper/views/services_list.dart';
import 'package:photo_view/photo_view.dart';
import 'package:rxdart/rxdart.dart' hide Notification;
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import '../main.dart';
import '../models/data/person.dart';
import '../models/data/user.dart';
import '../utils/globals.dart';

List<RadioListTile> getOrderingOptions(
    BehaviorSubject<OrderOptions> orderOptions, Type type) {
  return (type == Class
          ? Class.propsMetadata()
          : type == Service
              ? Service.propsMetadata()
              : Person.propsMetadata())
      .entries
      .map(
        (e) => RadioListTile<String>(
          value: e.key,
          groupValue: orderOptions.value.orderBy,
          title: Text(e.value.label),
          onChanged: (value) {
            orderOptions.add(
                OrderOptions(orderBy: value!, asc: orderOptions.value.asc));
            navigator.currentState!.pop();
          },
        ),
      )
      .toList()
    ..addAll(
      [
        RadioListTile(
          value: 'true',
          groupValue: orderOptions.value.asc.toString(),
          title: const Text('تصاعدي'),
          onChanged: (value) {
            orderOptions.add(OrderOptions(
                orderBy: orderOptions.value.orderBy, asc: value == 'true'));
            navigator.currentState!.pop();
          },
        ),
        RadioListTile(
          value: 'false',
          groupValue: orderOptions.value.asc.toString(),
          title: const Text('تنازلي'),
          onChanged: (value) {
            orderOptions.add(OrderOptions(
                orderBy: orderOptions.value.orderBy, asc: value == 'true'));
            navigator.currentState!.pop();
          },
        ),
      ],
    );
}

bool notService(String subcollection) =>
    subcollection == 'Meeting' ||
    subcollection == 'Kodas' ||
    subcollection == 'Confession';

void import(BuildContext context) async {
  try {
    final picked = await FilePicker.platform.pickFiles(
        allowedExtensions: ['xlsx'], withData: true, type: FileType.custom);
    if (picked == null) return;
    final fileData = picked.files[0].bytes!;
    final decoder = SpreadsheetDecoder.decodeBytes(fileData);
    if (decoder.tables.containsKey('Classes') &&
        decoder.tables.containsKey('Persons')) {
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار رفع الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      final filename = DateTime.now().toIso8601String();
      await FirebaseStorage.instance
          .ref('Imports/' + filename + '.xlsx')
          .putData(
            fileData,
            SettableMetadata(
              customMetadata: {
                'createdBy': User.instance.uid,
              },
            ),
          );

      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('جار استيراد الملف...'),
          duration: Duration(minutes: 9),
        ),
      );
      await GetIt.I<FunctionsService>()
          .httpsCallable('importFromExcel')
          .call({'fileId': filename + '.xlsx'});
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      scaffoldMessenger.currentState!.showSnackBar(
        const SnackBar(
          content: Text('تم الاستيراد بنجاح'),
        ),
      );
    } else {
      scaffoldMessenger.currentState!.hideCurrentSnackBar();
      await showErrorDialog(context, 'ملف غير صالح');
    }
  } catch (e) {
    scaffoldMessenger.currentState!.hideCurrentSnackBar();
    await showErrorDialog(context, e.toString());
  }
}

Future<List<T>?> selectServices<T extends DataObject>(List<T>? selected) async {
  final _controller = ServicesListController<T>(
    objectsPaginatableStream:
        PaginatableStream.loadAll(stream: Stream.value([])),
    groupByStream: (_) => MHDatabaseRepo.I.groupServicesByStudyYearRef<T>(),
  )..selectAll(selected);

  if (await navigator.currentState!.push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('اختر الفصول'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  onPressed: _controller.selectAll,
                  tooltip: 'تحديد الكل',
                ),
                IconButton(
                  icon: const Icon(Icons.check_box_outline_blank),
                  onPressed: _controller.deselectAll,
                  tooltip: 'تحديد لا شئ',
                ),
                IconButton(
                  icon: const Icon(Icons.done),
                  onPressed: () => navigator.currentState!.pop(true),
                  tooltip: 'تم',
                ),
              ],
            ),
            body: ServicesList<T>(
              options: _controller,
              autoDisposeController: false,
            ),
          ),
        ),
      ) ==
      true) {
    unawaited(_controller.dispose());
    return _controller.currentSelection?.whereType<T>().toList();
  }
  await _controller.dispose();
  return null;
}

Future<void> showErrorDialog(BuildContext context, String? message,
    {String? title}) async {
  return showDialog(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) => AlertDialog(
      title: title != null ? Text(title) : null,
      content: Text(message!),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            navigator.currentState!.pop();
          },
          child: const Text('حسنًا'),
        ),
      ],
    ),
  );
}

Future<void> showErrorUpdateDataDialog(
    {BuildContext? context, bool pushApp = true}) async {
  if (pushApp ||
      GetIt.I<CacheRepository>().box('Settings').get('DialogLastShown') !=
          DateTime.now().truncateToDay().millisecondsSinceEpoch) {
    await showDialog(
      context: context!,
      builder: (context) => AlertDialog(
        content: const Text(
            'الخادم مثال حى للنفس التائبة ـ يمارس التوبة فى حياته الخاصة'
            ' وفى أصوامـه وصلواته ، وحب المسـيح المصلوب\n'
            'أبونا بيشوي كامل \n'
            'يرجي مراجعة حياتك الروحية والاهتمام بها'),
        actions: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              shape: StadiumBorder(side: BorderSide(color: primaries[13]!)),
            ),
            onPressed: () async {
              final user = User.instance;
              await navigator.currentState!
                  .pushNamed('UpdateUserDataError', arguments: user);
              if (user.permissions.lastTanawol != null &&
                  user.permissions.lastConfession != null &&
                  ((user.permissions.lastTanawol!.millisecondsSinceEpoch +
                              2592000000) >
                          DateTime.now().millisecondsSinceEpoch &&
                      (user.permissions.lastConfession!.millisecondsSinceEpoch +
                              5184000000) >
                          DateTime.now().millisecondsSinceEpoch)) {
                navigator.currentState!.pop();
                if (pushApp)
                  // ignore: unawaited_futures
                  navigator.currentState!.pushReplacement(
                      MaterialPageRoute(builder: (context) => const App()));
              }
            },
            icon: const Icon(Icons.update),
            label: const Text('تحديث بيانات التناول والاعتراف'),
          ),
          TextButton.icon(
            onPressed: () => navigator.currentState!.pop(),
            icon: const Icon(Icons.close),
            label: const Text('تم'),
          ),
        ],
      ),
    );
    await GetIt.I<CacheRepository>().box('Settings').put('DialogLastShown',
        DateTime.now().truncateToDay().millisecondsSinceEpoch);
  }
}

class MessageIcon extends StatelessWidget {
  const MessageIcon(this.url, {Key? key}) : super(key: key);

  final String? url;

  Color get color => Colors.transparent;

  String get name => '';

  Widget getPhoto(BuildContext context) {
    return build(context);
  }

  Future<String> getSecondLine() async => '';

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints.expand(width: 55.2, height: 55.2),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => Dialog(
              child: Hero(
                tag: url!,
                child: CachedNetworkImage(
                  useOldImageOnUrlChange: true,
                  imageUrl: url!,
                  imageBuilder: (context, imageProvider) => PhotoView(
                    imageProvider: imageProvider,
                    tightMode: true,
                    enableRotation: true,
                  ),
                  progressIndicatorBuilder: (context, url, progress) =>
                      CircularProgressIndicator(value: progress.progress),
                ),
              ),
            ),
          ),
          child: CachedNetworkImage(
            useOldImageOnUrlChange: true,
            memCacheHeight: 221,
            imageUrl: url!,
            progressIndicatorBuilder: (context, url, progress) =>
                CircularProgressIndicator(value: progress.progress),
          ),
        ),
      ),
    );
  }
}

class QueryIcon extends StatelessWidget {
  const QueryIcon({Key? key}) : super(key: key);

  Color get color => Colors.transparent;

  String get name => 'نتائج بحث';

  Widget getPhoto(BuildContext context) {
    return build(context);
  }

  Future<String> getSecondLine() async => '';

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.search,
        size: MediaQuery.of(context).size.shortestSide / 7.2);
  }
}
