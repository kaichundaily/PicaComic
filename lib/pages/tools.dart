import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pica_comic/components/components.dart';
import 'package:pica_comic/foundation/app.dart';
import 'package:pica_comic/tools/app_links.dart';
import 'package:pica_comic/tools/extensions.dart';
import 'package:pica_comic/tools/translations.dart';

import 'ehentai/subscription.dart';
import 'jm/jm_comic_page.dart';
import 'webview.dart';

void openTool() {
  showModalBottomSheet(
    context: App.globalContext!,
    builder: (context) => Column(
      children: [
        ListTile(
          title: Text("工具".tl),
        ),
        ListTile(
          leading: const Icon(Icons.subscriptions),
          title: Text("EH订阅".tl),
          onTap: () {
            App.globalBack();
            App.mainNavigatorKey?.currentContext?.to(() => const SubscriptionPage());
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search_outlined),
          title: Text("图片搜索 [搜图bot酱]".tl),
          onTap: () async {
            App.globalBack();
            if (App.isMobile) {
              App.mainNavigatorKey?.currentContext?.to(
                () => AppWebview(
                  initialUrl: "https://soutubot.moe/",
                  onNavigation: (uri) {
                    return handleAppLinks(Uri.parse(uri),
                        showMessageWhenError: false);
                  },
                ),
              );
            } else {
              var webview = DesktopWebview(
                initialUrl: "https://soutubot.moe/",
                onNavigation: (s, webview) {
                  if (handleAppLinks(Uri.parse(s),
                      showMessageWhenError: false)) {
                    Future.microtask(() => webview.close());
                  }
                },
              );
              webview.open();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.image_search),
          title: Text("图片搜索 [SauceNAO]".tl),
          onTap: () async {
            App.globalBack();
            if (App.isMobile || App.isMacOS) {
              App.mainNavigatorKey?.currentContext?.to(
                () => AppWebview(
                  initialUrl: "https://saucenao.com/",
                  onNavigation: (uri) {
                    return handleAppLinks(Uri.parse(uri),
                        showMessageWhenError: false);
                  },
                ),
              );
            } else {
              var webview = DesktopWebview(
                initialUrl: "https://saucenao.com/",
                onNavigation: (s, webview) {
                  if (handleAppLinks(Uri.parse(s),
                      showMessageWhenError: false)) {
                    Future.microtask(() => webview.close());
                  }
                },
              );
              webview.open();
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.web),
          title: Text("打开链接".tl),
          onTap: () {
            App.globalBack();
            showDialog(
              context: App.globalContext!,
              builder: (context) {
                final controller = TextEditingController();

                validateText() {
                  var text = controller.text;
                  if (text == "") {
                    return null;
                  }

                  if (!text.contains("http://") && !text.contains("https://")) {
                    text = "https://$text";
                  }

                  if (!text.isURL) {
                    return "不支持的链接".tl;
                  }
                  var uri = Uri.parse(text);
                  if (![
                    "exhentai.org",
                    "e-hentai.org",
                    "hitomi.la",
                    "nhentai.net",
                    "nhentai.xxx"
                  ].contains(uri.host)) {
                    return "不支持的链接".tl;
                  }
                  return null;
                }

                void Function(void Function())? stateSetter;

                onFinish() {
                  if (validateText() != null) {
                    stateSetter?.call(() {});
                  } else {
                    App.globalBack();
                    var text = controller.text;
                    if (!text.contains("http://") &&
                        !text.contains("https://")) {
                      text = "https://$text";
                    }
                    handleAppLinks(Uri.parse(text));
                  }
                }

                return AlertDialog(
                  title: Text("输入链接".tl),
                  content: StatefulBuilder(
                    builder: (BuildContext context,
                        void Function(void Function()) setState) {
                      stateSetter = setState;
                      return TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          errorText: validateText(),
                        ),
                        onSubmitted: (s) => onFinish(),
                      );
                    },
                  ),
                  actions: [
                    TextButton(onPressed: onFinish, child: Text("打开".tl)),
                  ],
                );
              },
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.insert_drive_file),
          title: Text("禁漫漫画ID".tl),
          onTap: () {
            App.globalBack();
            var controller = TextEditingController();
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: Text("输入禁漫漫画ID".tl),
                  content: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                    child: TextField(
                      keyboardType: TextInputType.number,
                      controller: controller,
                      onEditingComplete: () {
                        App.globalBack();
                        if (controller.text.isNum) {
                          context.to(() => JmComicPage(controller.text));
                        } else {
                          showToast(message: "输入的ID不是数字".tl);
                        }
                      },
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp("[0-9]"))
                      ],
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "ID",
                          prefix: Text("JM")),
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          App.globalBack();
                          if (controller.text.isNum) {
                            App.mainNavigatorKey?.currentContext
                                ?.to(() => JmComicPage(controller.text));
                          } else {
                            showToast(message: "输入的ID不是数字".tl);
                          }
                        },
                        child: Text("提交".tl))
                  ],
                );
              },
            );
          },
        )
      ],
    ),
  );
}
