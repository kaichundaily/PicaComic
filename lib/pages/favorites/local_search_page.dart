import 'package:flutter/material.dart';
import 'package:pica_comic/foundation/ui_mode.dart';
import 'package:pica_comic/tools/translations.dart';
import 'package:pica_comic/components/components.dart';
import '../../foundation/app.dart';
import '../../foundation/local_favorites.dart';
import 'local_favorites.dart';
import 'main_favorites_page.dart';

class LocalSearchPage extends StatefulWidget {
  /// Search page for local favorites
  const LocalSearchPage({super.key});

  @override
  State<LocalSearchPage> createState() => _LocalSearchPageState();
}

class _LocalSearchPageState extends StateWithController<LocalSearchPage> {
  var comics = <FavoriteItemWithFolderInfo>[];

  String keyword = "";

  final controller = TextEditingController();

  final _focusNode = FocusNode();

  void search() {
    if (keyword.isEmpty) {
      comics = [];
    } else {
      comics = LocalFavoritesManager().search(keyword);
    }
  }

  @override
  void initState() {
    Future.delayed(const Duration(milliseconds: 200), _focusNode.requestFocus);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    search();
    return Material(
      child: Column(
        children: [
          SizedBox(
            height:
            UiMode.m1(context) ? MediaQuery.of(context).padding.top : null,
          ),
          Container(
            height: 56,
            width: double.infinity,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 0.8))),
            child: Row(
              children: [
                Tooltip(
                  message: "Back",
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_sharp),
                    onPressed: () {
                      App.back(context);
                    },
                  ),
                ),
                Expanded(
                  child: TextField(
                    focusNode: _focusNode,
                    controller: controller,
                    decoration: const InputDecoration(
                        border: InputBorder.none, hintText: "Search"),
                    onSubmitted: (s) => search(),
                    onChanged: (s) => setState(() {
                      keyword = s;
                    }),
                  ),
                ),
                if (keyword.isNotEmpty)
                  Tooltip(
                    message: "clear",
                    child: IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () {
                        controller.clear();
                        setState(() {
                          keyword = "";
                        });
                      },
                    ),
                  ),
                if (comics.isNotEmpty)
                  Tooltip(
                    message: "create folder",
                    child: IconButton(
                      icon: const Icon(Icons.create_new_folder_outlined),
                      onPressed: () {
                        showConfirmDialog(
                          App.globalContext!,
                          "创建收藏夹".tl,
                          "从当前的搜索结果创建新的收藏夹".tl,
                              () {
                            var name = LocalFavoritesManager()
                                .createFolder("search result", true);
                            for (var comic in comics) {
                              LocalFavoritesManager().addComic(name, comic.comic);
                            }
                            StateController.findOrNull<FavoritesPageController>()
                                ?.update();
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              primary: false,
              gridDelegate: SliverGridDelegateWithComics(),
              itemCount: comics.length,
              padding: EdgeInsets.zero,
              itemBuilder: (BuildContext context, int index) {
                return LocalFavoriteTile(
                  comics[index].comic,
                  comics[index].folder,
                      () => setState(() {}),
                  true,
                  showFolderInfo: true,
                );
              },
            ),
          )
        ],
      ),
    );
  }

  @override
  Object? get tag => "local_search_page";
}
