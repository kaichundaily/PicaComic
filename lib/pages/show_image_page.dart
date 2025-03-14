import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:pica_comic/foundation/image_loader/cached_image.dart';
import 'package:pica_comic/foundation/image_manager.dart';
import 'package:pica_comic/tools/save_image.dart';
import 'package:pica_comic/tools/translations.dart';

class ShowImagePage extends StatelessWidget {
  const ShowImagePage(this.url, {super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("图片".tl),
      ),
      body: PhotoView(
        minScale: PhotoViewComputedScale.contained * 0.9,
        imageProvider: CachedImageProvider(url),
        loadingBuilder: (context, event) {
          return Container(
            decoration: const BoxDecoration(color: Colors.black),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class ShowImagePageWithHero extends StatelessWidget {
  const ShowImagePageWithHero(this.url, this.tag, {super.key});

  final String url;

  final String tag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("图片".tl),
        actions: [
          Tooltip(
            message: "保存".tl,
            child: IconButton(
              icon: const Icon(Icons.download),
              onPressed: () async{
                var file = await ImageManager().getFile(url);
                if(file != null){
                  saveImage(file);
                }
              }
          ))
        ],
      ),
      body: Hero(
        tag: tag,
        child: PhotoView(
          minScale: PhotoViewComputedScale.contained * 0.9,
          imageProvider: CachedImageProvider(url),
          loadingBuilder: (context, event) {
            return Container(
              decoration: const BoxDecoration(color: Colors.black),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }
}

