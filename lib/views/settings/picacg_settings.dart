import 'package:pica_comic/foundation/app.dart';
import 'package:flutter/material.dart';
import '../../base.dart';
import '../../tools/background_service.dart';
import '../widgets/select.dart';
import 'package:pica_comic/views/widgets/show_message.dart';
import 'package:pica_comic/network/picacg_network/methods.dart';
import 'package:pica_comic/tools/translations.dart';

class PicacgSettings extends StatefulWidget {
  const PicacgSettings(this.popUp, {Key? key}) : super(key: key);
  final bool popUp;

  @override
  State<PicacgSettings> createState() => _PicacgSettingsState();
}

class _PicacgSettingsState extends State<PicacgSettings> {
  bool showFrame = appdata.settings[5] == "1";
  bool punchIn = appdata.settings[6] == "1";
  bool useMyServer = appdata.settings[3] == "1";

  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 0,
        child: Column(
          children: [
            ListTile(
              title: Text("哔咔漫画".tl),
            ),
              ListTile(
                leading: const Icon(Icons.change_circle),
                title: Text("使用转发服务器".tl),
                subtitle: Text("同时使用网络代理工具会减慢速度".tl),
                trailing: Switch(
                  value: useMyServer,
                  onChanged: (b) {
                    b ? appdata.settings[3] = "1" : appdata.settings[3] = "0";
                    setState(() {
                      useMyServer = b;
                    });
                    network.updateApi();
                    appdata.writeData();
                  },
                ),
                onTap: () {},
              ),
            ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: Text("设置分流".tl),
              trailing: Select(
                initialValue: int.parse(appdata.appChannel)-1,
                values: [
                  "分流1".tl,
                  "分流2".tl,
                  "分流3".tl
                ],
                whenChange: (i){
                  appdata.appChannel = (i+1).toString();
                  appdata.writeData();
                  showMessage(App.globalContext, "正在获取分流IP".tl,time: 8);
                  network.updateApi().then((v)=>hideMessage(App.globalContext!));
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: Text("设置图片质量".tl),
              trailing: Select(
                initialValue: appdata.getQuality()-1,
                values: [
                  "低".tl,
                  "中".tl,
                  "高".tl,
                  "原图".tl
                ],
                whenChange: (i){
                  appdata.setQuality(i+1);
                },
                inPopUpWidget: widget.popUp,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.manage_search_outlined),
              trailing: Select(
                initialValue: appdata.getSearchMode(),
                values: [
                  "新到书".tl,"旧到新".tl,"最多喜欢".tl,"最多指名".tl
                ],
                whenChange: (i){
                  appdata.setSearchMode(i);
                },
                inPopUpWidget: widget.popUp,
              ),
              title: Text("设置搜索及分类排序模式".tl),
            ),
            ListTile(
              leading: const Icon(Icons.circle_outlined),
              title: Text("显示头像框".tl),
              trailing: Switch(
                value: showFrame,
                onChanged: (b) {
                  b ? appdata.settings[5] = "1" : appdata.settings[5] = "0";
                  setState(() {
                    showFrame = b;
                  });
                  appdata.writeData();
                },
              ),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.today),
              title: Text("自动打卡".tl),
              subtitle: App.isMobile?Text("APP启动或是距离上次打卡间隔一天时执行".tl): Text("启动时执行".tl),
              onTap: () {},
              trailing: Switch(
                value: punchIn,
                onChanged: (b) {
                  b ? appdata.settings[6] = "1" : appdata.settings[6] = "0";
                  if(App.isMobile) {
                    b ? runBackgroundService() : cancelBackgroundService();
                  }
                  setState(() {
                    punchIn = b;
                  });
                  appdata.writeData();
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              trailing: Select(
                initialValue: int.parse(appdata.settings[30]),
                values: [
                  "旧到新".tl, "新到书".tl
                ],
                whenChange: (i){
                  appdata.settings[30] = i.toString();
                  appdata.updateSettings();
                },
                inPopUpWidget: widget.popUp,
              ),
              title: Text("收藏夹漫画排序模式".tl),
            ),
          ],
        ));
  }
}
