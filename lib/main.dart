import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_uploader/flutter_uploader.dart';
import 'package:photoprism/api/albums.dart';
import 'package:photoprism/pages/settings.dart';
import 'package:provider/provider.dart';
import 'package:photoprism/common/hexcolor.dart';
import 'api/photos.dart';
import 'model/photoprism_model.dart';

final uploader = FlutterUploader();

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => PhotoprismModel(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Photoprism',
      theme: ThemeData(),
      home: MainPage('Photoprism', context),
    );
  }
}

class MainPage extends StatelessWidget {
  final String title;
  final PageController _pageController;
  final BuildContext context;

  MainPage(this.title, this.context)
      : _pageController = PageController(initialPage: 0);

  void _onTappedNavigationBar(int index) {
    _pageController.jumpToPage(index);
    Provider.of<PhotoprismModel>(context).setSelectedPageIndex(index);
  }

  void emptyCache() async {
    await DefaultCacheManager().emptyCache();
  }

  Future<void> refreshPhotosPull() async {
    print('refreshing photos..');

    await Photos.loadPhotos(Provider.of<PhotoprismModel>(context),
        Provider.of<PhotoprismModel>(context).photoprismUrl, "");

    await Photos.loadPhotosFromNetworkOrCache(
        Provider.of<PhotoprismModel>(context),
        Provider.of<PhotoprismModel>(context).photoprismUrl,
        "");
  }

  Future<void> refreshAlbumsPull() async {
    print('refreshing albums..');

    await Albums.loadAlbums(Provider.of<PhotoprismModel>(context),
        Provider.of<PhotoprismModel>(context).photoprismUrl);

    await Albums.loadAlbumsFromNetworkOrCache(
        Provider.of<PhotoprismModel>(context),
        Provider.of<PhotoprismModel>(context).photoprismUrl);
  }

  AppBar getAppBar(context) {
    if (Provider.of<PhotoprismModel>(context).selectedPageIndex == 0) {
      return AppBar(
        title: Provider.of<PhotoprismModel>(context)
                    .gridController
                    .selection
                    .selectedIndexes
                    .length >
                0
            ? Text("Selected " +
                Provider.of<PhotoprismModel>(context)
                    .gridController
                    .selection
                    .selectedIndexes
                    .length
                    .toString() +
                " photos")
            : Text(title),
        backgroundColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
        actions: Provider.of<PhotoprismModel>(context)
                    .gridController
                    .selection
                    .selectedIndexes
                    .length >
                0
            ? <Widget>[
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Add to album',
                  onPressed: () {
                    //Provider.of<PhotoprismModel>(context).createAlbum();
                    _selectAlbumDialog(context);
                    print(Provider.of<PhotoprismModel>(context)
                        .gridController
                        .selection
                        .selectedIndexes);
                  },
                ),
              ]
            : null,
      );
    } else if (Provider.of<PhotoprismModel>(context).selectedPageIndex == 1) {
      return AppBar(
        title: Text(title),
        backgroundColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create album',
            onPressed: () {
              Provider.of<PhotoprismModel>(context).createAlbum();
            },
          ),
        ],
      );
    } else {
      return AppBar(
        title: Text(title),
        backgroundColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
      );
    }
  }

  _selectAlbumDialog(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select album'),
            content: ListView.builder(
                itemCount: Albums.getAlbumList(context).length,
                itemBuilder: (BuildContext ctxt, int index) {
                  return GestureDetector(
                      onTap: () {
                        addPhotosToAlbum(
                            Albums.getAlbumList(context)[index].id, context);
                      },
                      child: Card(
                          child: ListTile(
                              title: Text(
                                  Albums.getAlbumList(context)[index].name))));
                }),
          );
        });
  }

  addPhotosToAlbum(albumId, context) async {
    List<String> selectedPhotos = [];

    Provider.of<PhotoprismModel>(context)
        .gridController
        .selection
        .selectedIndexes
        .forEach((element) {
      selectedPhotos.add(Photos.getPhotoList(context, "")[element].photoUUID);
    });

    await Provider.of<PhotoprismModel>(context)
        .addPhotosToAlbum(albumId, selectedPhotos);

    Provider.of<PhotoprismModel>(context).gridController.clear();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final PhotoprismModel photorismModel =
        Provider.of<PhotoprismModel>(context);
    return Scaffold(
      appBar: getAppBar(context),
      body: PageView(
          physics: NeverScrollableScrollPhysics(),
          controller: _pageController,
          children: <Widget>[
            RefreshIndicator(
                child: Photos(
                    context: context,
                    photoprismUrl:
                        Provider.of<PhotoprismModel>(context).photoprismUrl,
                    albumId: ""),
                onRefresh: refreshPhotosPull,
                color: HexColor(photorismModel.applicationColor)),
            RefreshIndicator(
                child: Albums(
                    photoprismUrl:
                        Provider.of<PhotoprismModel>(context).photoprismUrl),
                onRefresh: refreshAlbumsPull,
                color: HexColor(photorismModel.applicationColor)),
            Settings(),
          ]),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.photo),
            title: Text('Photos'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.photo_album),
            title: Text('Albums'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            title: Text('Settings'),
          ),
        ],
        currentIndex: Provider.of<PhotoprismModel>(context).selectedPageIndex,
        selectedItemColor:
            HexColor(Provider.of<PhotoprismModel>(context).applicationColor),
        onTap: _onTappedNavigationBar,
      ),
    );
  }
}
