import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pica_comic/network/webdav.dart';


enum HistoryType{
  picacg(0),
  ehentai(1),
  jmComic(2),
  hitomi(3),
  htmanga(4),
  nhentai(5);

  final int value;
  const HistoryType(this.value);
}

base class History extends LinkedListEntry<History>{
  HistoryType type;

  DateTime time;

  String title;

  String subtitle;

  String cover;

  /// 标记为0表示没有阅读位置记录
  int ep;

  int page;

  String target;

  Set<int> readEpisode;

  History(this.type,this.time,this.title,this.subtitle,this.cover,this.ep,
      this.page,this.target,[this.readEpisode=const <int>{}]);


  Map<String, dynamic> toMap()=>{
    "type": type.value,
    "time": time.millisecondsSinceEpoch,
    "title": title,
    "subtitle": subtitle,
    "cover": cover,
    "ep": ep,
    "page": page,
    "target": target,
    "readEpisode": readEpisode.toList()
  };

  History.fromMap(Map<String, dynamic> map):
    type=HistoryType.values[map["type"]],
    time=DateTime.fromMillisecondsSinceEpoch(map["time"]),
    title=map["title"],
    subtitle=map["subtitle"],
    cover=map["cover"],
    ep=map["ep"],
    page=map["page"],
    target=map["target"],
    readEpisode=Set<int>.from((map["readEpisode"] as List<dynamic>?)?.toSet() ?? const <int>{});

  @override
  String toString() {
    return 'NewHistory{type: $type, time: $time, title: $title, subtitle: $subtitle, cover: $cover, ep: $ep, page: $page, target: $target}';
  }
}

class HistoryManager{
  static HistoryManager? cache;

  HistoryManager.create();

  factory HistoryManager() => cache==null?(cache=HistoryManager.create()):cache!;

  LinkedList<History>? history;

  List<dynamic> toJson() => history!.map((h)=>h.toMap()).toList();

  void readDataFromJson(List<dynamic> json){
    history = LinkedList<History>();
    for(var h in json){
      history!.add(History.fromMap((h as Map<String, dynamic>)));
    }
    saveData();
  }

  /// remove repeated item
  void check(){
    Set<String> keys = {};
    var shouldRemove = <History>[];
    for(var value in history!){
      if(keys.contains(value.target)){
        shouldRemove.add(value);
        continue;
      }else{
        keys.add(value.target);
      }
    }
    for(var value in shouldRemove){
      history!.remove(value);
    }
  }

  void saveData() async{
    if(history == null){
      return;
    }
    check();
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(!(await file.exists())){
      await file.create();
    }
    file.writeAsStringSync(const JsonEncoder().convert(history!.map((h)=>h.toMap()).toList()));
    Webdav.uploadData();
  }

  Future<void> readData() async{
    if(history != null) return;
    history = LinkedList<History>();
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(!(await file.exists())){
      return;
    }
    var data = const JsonDecoder().convert(file.readAsStringSync());
    for(var h in data){
      history!.add(History.fromMap((h as Map<String, dynamic>)));
    }
  }

  ///搜索是否存在, 存在则移至最前, 并且转移历史记录
  ///调用此方法不会记录阅读数据, 只是添加历史记录
  Future<void> addHistory(History newItem) async{
    if(history == null) {
      await readData();
    }
    try {
      var p = history!.firstWhere((element) => element.target == newItem.target);
      history!.remove(p);
      history!.addFirst(p);
    }
    catch(e){
      //没有之前的历史记录
      history!.addFirst(History.fromMap(newItem.toMap()));
      //做一个限制, 避免极端情况
      if(history!.length >= 10000){
        history!.remove(history!.last);
      }
    }
  }

  ///退出阅读器时调用此函数, 修改阅读位置
  Future<void> saveReadHistory(String target, int ep, int page) async{
    if(history == null) {
      await readData();
    }
    try {
      var p = history!.firstWhere((element) => element.target == target);
      p.ep = ep;
      p.page = page;
      saveData();
    }
    catch(e){
      //可能存在进入阅读器前添加历史记录失败情况, 此时忽略
    }
  }

  void clearHistory() async{
    //清除历史记录
    final dataPath = await getApplicationSupportDirectory();
    var file = File("${dataPath.path}${Platform.pathSeparator}history.json");
    if(file.existsSync()){
      await file.delete();
    }
    history = null;
  }

  void remove(String id) async{
    await readData();
    history!.remove(history!.firstWhere((element) => element.target==id));
  }

  Future<History?> find(String target) async{
    await readData();
    try {
      return history!.firstWhere((element) => element.target == target);
    }
    catch(e){
      return null;
    }
  }

  History? findSync(String target){
    try {
      return history!.firstWhere((element) => element.target == target);
    }
    catch(e){
      return null;
    }
  }
}