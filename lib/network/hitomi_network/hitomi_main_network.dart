import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:html/parser.dart';
import 'package:pica_comic/network/cache_network.dart';
import 'package:pica_comic/network/hitomi_network/search.dart';
import 'package:pica_comic/tools/extensions.dart';
import '../../base.dart';
import '../../foundation/log.dart';
import '../http_client.dart';
import '../res.dart';
import 'fetch_data.dart';
import 'hitomi_models.dart';

/// 用于 hitomi.la 的网络请求类
class HiNetwork{
  factory HiNetwork() => cache==null ? (cache=HiNetwork._create()) : cache!;

  HiNetwork._create();

  static HiNetwork? cache;

  final baseUrl = "https://hitomi.la";

  ///基本的get请求
  Future<Res<String>> get(String url, {CacheExpiredTime expiredTime=CacheExpiredTime.short}) async{
    try{
      var options = BaseOptions(
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5),
          headers: {
            "User-Agent": webUA,
            "Referer": "https://hitomi.la/"
          }
      );
      var dio = CachedNetwork();
      var res = await dio.get(url, options, expiredTime: expiredTime);
      return Res(res.data);
    }
    catch(e){
      return Res(null, errorMessage: e.toString()=="null"?"未知错误":e.toString());
    }
  }

  ///从一个漫画列表中获取所有的漫画
  Future<Res<ComicList>> getComics(String url) async{
    var comicList = ComicList(url);
    var res = await loadNextPage(comicList);
    if(res.error){
      return Res(null, errorMessage: res.errorMessage!);
    }else{
      return Res(comicList);
    }
  }

  Future<Res<bool>> loadNextPage(ComicList comicList) async{
    if(comicList.toLoad >= comicList.total) return const Res(false);
    var comicIds = await fetchComicData(comicList.url, comicList.toLoad, maxLength: comicList.total);
    if(comicIds.error){
      return Res(false, errorMessage: comicIds.errorMessage!);
    }
    comicList.total = int.parse(comicIds.subData);
    comicList.toLoad += 100;
    comicList.comicIds.addAll(comicIds.data);
    return const Res(true);
  }

  ///获取一个漫画的简略信息
  Future<Res<HitomiComicBrief>> getComicInfoBrief(String id) async{
    var res = await get("https://ltn.hitomi.la/galleryblock/$id.html");
    if(res.error){
      return Res(null, errorMessage: res.errorMessage!);
    }
    try{
      var comicDiv = parse(res.data);
      var name = comicDiv.querySelector("h1.lillie > a")!.text;
      var link = comicDiv.querySelector("h1.lillie > a")!.attributes["href"]!;
      link = baseUrl + link;
      var artist = comicDiv.querySelector("div.artist-list a")?.text??"N/A";
      String cover;
      try {
        cover = comicDiv.querySelector("div.dj-img1 > picture > source")
            ?.attributes["data-srcset"] ??
            comicDiv.querySelector("div.cg-img1 > picture > source")!
            .attributes["data-srcset"]!;
        cover = cover.substring(2);
        cover = "https://a$cover";
        cover = cover.replaceAll(RegExp(r"2x.*"), "");
        cover = cover.removeAllBlank;
        cover = cover.replaceFirst("avifbigtn", "webpbigtn");
        cover = cover.replaceFirst(".avif", ".webp");
      }
      catch(e){
        cover = "";
      }
      var table = comicDiv.querySelectorAll("div.dj-content > table.dj-desc > tbody");
      String type = "", lang = "";
      var tags = <Tag>[];
      for (var tr in table[0].children) {
        if (tr.firstChild!.text == "Type") {
          type = tr.children[1].text;
        } else if (tr.firstChild!.text == "Language") {
          lang = tr.children[1].text;
        } else if (tr.firstChild!.text == "Tags") {
          for (var liA in tr.querySelectorAll("td.relatedtags > ul > li > a")) {
            tags.add(Tag(liA.text, liA.attributes["href"]!));
          }
        }
      }
      var time = comicDiv.querySelector("div.dj-content > p")!.text;
      return Res(HitomiComicBrief(name, type, lang, tags, time, artist, link, cover));
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Data Analysis", "$e\n$s");
      return Res(null, errorMessage: e.toString());
    }
  }

  ///搜索Hitomi
  Future<Res<List<int>>> search(String keyword) async{
    await getProxy();
    appdata.searchHistory.remove(keyword);
    appdata.searchHistory.add(keyword);
    appdata.writeHistory();
    try{
      var searchEngine = HitomiSearch(keyword);
      var res = await searchEngine.search();
      return Res(res.data);
    }
    catch(e, s){
      LogManager.addLog(LogLevel.error, "Network", "$e\n$s");
      return Res(null, errorMessage: "$e");
    }
  }

  ///获取漫画信息
  Future<Res<HitomiComic>> getComicInfo(String target) async{
    String id;
    if(target.isNum){
      id = target;
    }else {
      id = RegExp(r"\d+(?=\.html)").firstMatch(target)![0]!;
    }
    var brief = await getComicInfoBrief(id);
    if(brief.error){
      return Res(null, errorMessage: brief.errorMessage!);
    }
    var res = await get("https://ltn.hitomi.la/galleries/$id.js");
    if(res.error){
      return Res(null, errorMessage: res.errorMessage!);
    }
    //返回一个js脚本, 图片url也在这里面
    //直接将前面的"var galleryinfo = "删掉, 然后作为json解析即可
    var data = res.data.substring(res.data.indexOf('{'));
    var json = const JsonDecoder().convert(data);
    var tags = <Tag>[];
    var files = <HitomiFile>[];

    for(var tag in json["tags"]??[]){
      tags.add(Tag(tag["tag"], "$baseUrl${tag["url"]}"));
    }

    for(var file in json["files"]??[]){
      files.add(HitomiFile(file["name"], file["hash"],
          file["haswebp"]==1, file["hasavif"]==1, file["height"], file["width"], id));
    }

    return Res(HitomiComic(
      id,
      json["title"],
      List<int>.from(json["related"]),
      json["type"],
      List<String>.from((json["artists"]??[]).map((e) => e["artist"]).toList()),
      json["language_localname"] ?? "",
      tags,
      json["date"],
      files,
      List<String>.from((json["groups"]??[]).map((e) => e["group"]).toList()),
      brief.data.cover,
    ));
  }
}

enum HitomiUrls{
  homePageAll('https://ltn.hitomi.la/index-all.nozomi'),
  homePageCn("https://ltn.hitomi.la/index-chinese.nozomi"),
  homePageJp("https://ltn.hitomi.la/index-japanese.nozomi"),
  homePageEn("https://ltn.hitomi.la/index-english.nozomi");

  final String url;

  const HitomiUrls(this.url);
}

class HitomiDataUrls{
  static String homePageAll = 'https://ltn.hitomi.la/index-all.nozomi';
  static String homePageCn = "https://ltn.hitomi.la/index-chinese.nozomi";
  static String homePageJp = "https://ltn.hitomi.la/index-japanese.nozomi";
  static String homePageEn = "https://ltn.hitomi.la/index-english.nozomi";
  static String todayPopular = "https://ltn.hitomi.la/popular/today-all.nozomi";
  static String weekPopular = "https://ltn.hitomi.la/popular/week-all.nozomi";
  static String monthPopular = "https://ltn.hitomi.la/popular/month-all.nozomi";
  static String yearPopular = "https://ltn.hitomi.la/popular/year-all.nozomi";
}