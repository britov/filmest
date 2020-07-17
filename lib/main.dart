import 'dart:async';

import 'package:flare_flutter/flare_actor.dart';
import 'package:flare_flutter/flare_controls.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_create/generated/i18n.dart';
import 'package:flutter_create/model.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:share/share.dart';
import 'package:tuple/tuple.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

const youtubePlayerFlags = YoutubePlayerFlags(
  disableDragSeek: true,
  autoPlay: false,
  enableCaption: false,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => FilmsModel()..loadMovies(),
              lazy: false,
            )
          ],
          child: MaterialApp(
              title: 'Filmest',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                brightness: Brightness.dark,
                accentColor: Colors.orange.shade300,
                toggleableActiveColor: Colors.orange.shade300,
                backgroundColor: Colors.grey.shade600,
              ),
              initialRoute: 'splash',
              routes: {'splash': (_) => SplashPage(), 'home': (_) => MainPage()},
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              supportedLocales: S.delegate.supportedLocales,
              localeResolutionCallback: S.delegate.resolution(fallback: const Locale('en', ''))));
}

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ru') {
      context.read<FilmsModel>().lang = 'ru-RU';
    } else {
      context.read<FilmsModel>().lang = 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          const FlareActor(
            'assets/man.flr',
            fit: BoxFit.fill,
            animation: 'move_phone',
          ),
          FutureBuilder(
              future: Future.delayed(const Duration(seconds: 4)),
              builder: (context, snapshot) => AnimatedOpacity(
                  opacity: snapshot.connectionState == ConnectionState.done ? 1 : 0,
                  duration: const Duration(seconds: 2),
                  onEnd: () => Navigator.of(context).pushReplacementNamed('home'),
                  curve: Curves.bounceInOut,
                  child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text('Filmest', style: Theme.of(context).textTheme.headline3.copyWith(fontFamily: 'Oswald')),
                      Text(S.of(context).slashSubtitle,
                          style: Theme.of(context).textTheme.subtitle1.copyWith(fontFamily: 'Oswald')),
                      const SizedBox(height: 10),
                      Text('Used TMDB API',
                          style: Theme.of(context).textTheme.subtitle1.copyWith(fontFamily: 'Oswald')),
                    ],
                  )))),
        ],
      );
}

class MainPage extends StatefulWidget {
  @override
  State createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _isVisibleHelpInfo = true;
  final _videoIndx$ = BehaviorSubject.seeded(0);
  final _indx$ = BehaviorSubject.seeded(0);

  PageController pageController = PageController();
  PageController videoPageController = PageController();
  YoutubePlayerController _youtubePlayerController;

  final _swipeTrailersController = FlareControls();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final locale = Localizations.localeOf(context);
    if (locale.languageCode == 'ru') {
      context.read<FilmsModel>().lang = 'ru-RU';
    } else {
      context.read<FilmsModel>().lang = 'en-US';
    }
  }

  @override
  Widget build(BuildContext context) {
    final _scaffoldKey = GlobalKey<ScaffoldState>();
    return Scaffold(
            key: _scaffoldKey,
            bottomNavigationBar: _buildBottomAppBar(context, _scaffoldKey),
            endDrawer: GenresDrawer(),
            backgroundColor: Colors.black,
            body: SafeArea(
                child: Stack(
              children: <Widget>[
                _buildBody(context),
                if (_isVisibleHelpInfo == true) _buildHelpInfo(context),
              ],
            )));
  }

  Widget _buildHelpInfo(BuildContext context) => GestureDetector(
        onPanEnd: (_) => setState(() => _isVisibleHelpInfo = false),
        child: Container(
          decoration: BoxDecoration(backgroundBlendMode: BlendMode.darken, color: Colors.black.withOpacity(0.6)),
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.headline3.copyWith(color: Colors.white),
            child: Column(children: <Widget>[
              AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Center(
                      child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(
                        height: 80,
                        child: FlareActor(
                          'assets/swipe.flr',
                          animation: 'to_right',
                          callback: (_) => _swipeTrailersController.play('to_right'),
                        ),
                      ),
                      Text(S.of(context).swipeTrailer)
                    ],
                  ))),
              Expanded(
                  child: Center(
                      child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  SizedBox(
                    height: 80,
                    child: FlareActor(
                      'assets/swipe.flr',
                      controller: _swipeTrailersController,
                    ),
                  ),
                  Text(S.of(context).swipeFilms)
                ],
              )))
            ]),
          ),
        ),
      );

  Widget _buildBody(BuildContext context) => Column(children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
           // color: Theme.of(context).cardColor
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
              ],
            ),
          ),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildPlayer(),
          ),
        ),
        Expanded(child: _buildMoviesPageView(context))
      ]);

  Widget _buildMoviesPageView(BuildContext context) => Consumer<FilmsModel>(
        builder: (context, model, child) => PageView.builder(

            onPageChanged: _indx$.add,
            itemCount: model.movies.length,
            controller: PageController(initialPage: _indx$.value),
            itemBuilder: (c, i) {
              if (i + 5 == model.movies.length) {
                model.loadMovies();
              }
              final m = model.movies.elementAt(i);
              m.videoKeys ??= model.getVideo(m.id);
              m.videoKeys.then((_) {});
              return Container(
                  color: Colors.black,
                  child: Column(children: <Widget>[
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        child: Text(
                          m.title,
                          style: Theme.of(context).textTheme.headline5,
                          maxLines: 3,
                          textAlign: TextAlign.center,
                          softWrap: true,
                        )),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Icon(Icons.calendar_today),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                          child: Text(m.json['release_date'],
                              style: Theme.of(context).textTheme.subtitle1,),
                        ),
                        Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                                  child: Text('IMDb',
                                    style: Theme.of(context)
                                        .textTheme
                                        .caption
                                        .copyWith(fontWeight: FontWeight.w900),
                                  )),
                            ),
                        Text.rich(TextSpan(
                            text: '${m.json['vote_average']}',
                            style: Theme.of(context)
                                .textTheme
                                .headline6
                                .copyWith(fontWeight: FontWeight.w900),
                            children: [
                              TextSpan(
                                  text: '/10',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      .copyWith(fontWeight: FontWeight.w500))
                            ])),

                      ]),
                    ),
                    Expanded(
                        child: Scrollbar(
                            child: SingleChildScrollView(
                                child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(m.json['overview'],
                          style: Theme.of(context)
                              .textTheme
                              .subtitle1),
                    )))),
                  ]));
            }),
      );

  Widget _buildPlayer() => Consumer<FilmsModel>(
        builder: (context, model, child) => StreamBuilder(
            stream: _indx$.asyncMap((i) => model.movies?.elementAt(i)?.videoKeys),
            builder: (context, AsyncSnapshot<List<String>> videoKeysSnapshot) {
              _videoIndx$.add(0);
              return videoKeysSnapshot.data?.isEmpty != false
                  ? Container()
                  : Container(
                      color: Theme.of(context).primaryColor,
                      child: PageView.builder(
                          onPageChanged: _videoIndx$.add,
                          itemCount: videoKeysSnapshot.data.length,
                          itemBuilder: (context, i) => videoKeysSnapshot.data == null
                              ? Container()
                              : YoutubePlayer(
                                  key: ValueKey(videoKeysSnapshot.data[i]),
                                  showVideoProgressIndicator: true,
                                  controller: _youtubePlayerController?.initialVideoId == videoKeysSnapshot.data[i]
                                      ? _youtubePlayerController
                                      : _youtubePlayerController = YoutubePlayerController(
                                          initialVideoId: videoKeysSnapshot.data[i], flags: youtubePlayerFlags),
                            bottomActions: <Widget>[
                                SizedBox(width: 14.0),
                                CurrentPosition(),
                                SizedBox(width: 8.0),
                                ProgressBar(isExpanded: true),
                                RemainingDuration(),
                                PlaybackSpeedButton(),
                            ],

                          )));
            }),
      );

  Widget _buildBottomAppBar(BuildContext context, GlobalKey<ScaffoldState> _scaffoldKey) => BottomAppBar(
        color: Colors.black12,
        elevation: 10,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Consumer<FilmsModel>(
              builder: (contest, model, child) => StreamBuilder(
                  stream: _indx$.asyncExpand((i) => model.movies[i].videoKeys.asStream()),
                  builder: (context, AsyncSnapshot<List<String>> snapshot) => IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: snapshot.data?.isEmpty != false
                          ? null
                          : () => Share.share('https://youtu.be/${snapshot.data[_videoIndx$.value]}'))),
            ),
            Consumer<FilmsModel>(
                builder: (contest, model, child) => FlatButton(
                      child: Text(S.of(context).searchInGoogle),
                      onPressed: () => launch(
                          'https://www.google.com/search?q=${model.movies[_indx$.value].title..replaceAll(' ', '+')}+${S.of(context).online}'),
                    )),
              Consumer<FilmsModel>(
              builder: (contest, model, child) => IconButton(
                icon: const Icon(Icons.filter_list),
//                onPressed: () => _scaffoldKey.currentState.openEndDrawer()
                onPressed: () => showModalBottomSheet(
                  context: context,
                  builder: (_) => BottomSheet(

                    onClosing: () {},
                    builder: (_) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.only(top: 16, bottom: 8),
                            child: Text('Filters',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headline6,),
                          ),
                          ListTile(
                            title: const Text('Release date'),
                            subtitle: Text(_buildReleaseDateSubtitle(model.fromYear, model.toYear)),
                            onTap: () async {
                              final result = await showModalBottomSheet<Tuple2<int, int>>(
                                context: context,
                                builder: (_) => SelectDateRange(
                                  fromYear: model.fromYear,
                                  toYear: model.toYear,
                                )
                            );
                              if (result != null) {
                                context.read<FilmsModel>().setDateFilter(result.item1, result.item2);
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: SizedBox(
                                width: double.infinity,
                                child: const Text('Genre', textAlign: TextAlign.start,)),
                          ),
                           Padding(
                             padding: const EdgeInsets.symmetric(horizontal: 16),
                             child: DropdownButtonFormField<int>(
                                value: model.currentGenre,
                                items: [
                                  const DropdownMenuItem<int>(
                                    value: null,
                                    child: Text('All'),
                                  ),
                                  for (final genre in model.genres)
                                    DropdownMenuItem<int>(
                                      value: genre['id'],
                                      child: Text(genre['name']),
                                    )
                                ],
                                onChanged: (value) { context.read<FilmsModel>().currentGenre = value; },
                              ),
                           ),
                        ],
                      ),
                    ),
                  ),

                )
              ),
            )
          ],
        ),
      );

  String _buildReleaseDateSubtitle(int fromYear, int toYear) {
    if (fromYear == null && toYear == null) {
      return 'Any';
    }

    var result = '';

    if (fromYear != null) {
      result += 'After $fromYear';
    }
    if (toYear != null && fromYear != null) {
      result += ' and before $fromYear';
    } else if (toYear != null) {
      result += 'Before $fromYear';
    }

    return result;
  }

}

class SelectDateRange extends StatefulWidget {

  const SelectDateRange({Key key, this.fromYear, this.toYear}) : super(key: key);

  final int fromYear;
  final int toYear;

  @override
  _SelectDateRangeState createState() => _SelectDateRangeState();
}

class _SelectDateRangeState extends State<SelectDateRange> {
  final int minYear = 1890;
  final int maxYear = DateTime.now().year;

  int fromIndex;
  int toIndex;

  int get fromYear => fromIndex != null ? fromIndex + minYear - 1 : null;
  int get toYear => toIndex != null ? toIndex + minYear - 1 : null;


  @override
  void initState() {
    super.initState();
    if (widget.fromYear != null) {
      fromIndex = widget.fromYear - minYear + 1;
    }
    if (widget.toYear != null) {
      toIndex = widget.toYear - minYear + 1;
    }
  }

  @override
  Widget build(BuildContext context) => BottomSheet(
      onClosing: () {},
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: Text('Release date', style: Theme.of(context).textTheme.headline6,),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ],),

          Padding(
            padding: const EdgeInsets.only(top: 15),
            child: Container(
              constraints: BoxConstraints.tight(Size(double.infinity, 210)),
              child: Stack(
                children: <Widget>[
                  
                  Center(
                    child: Container(
                      constraints: BoxConstraints.tight(Size(
                          double.infinity, 70
                      )),
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),

                  DefaultTextStyle(
                    style: Theme.of(context).textTheme.subtitle1.copyWith(
                      color: Colors.white
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: fromIndex ?? 0),
                            diameterRatio: 4,
                            physics: const FixedExtentScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            itemExtent: 70,
                            onSelectedItemChanged: (index) => fromIndex = index,
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: <Widget>[
                                _buildItem(const Text('from')),
                                for (var year = minYear; year <= maxYear; year++)
                                  _buildItem(Text('$year'))
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: FixedExtentScrollController(initialItem: toIndex ?? 0),
                            physics: const FixedExtentScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            diameterRatio: 4,
                            itemExtent: 70,
                            onSelectedItemChanged: (index) => toIndex = index,
                            childDelegate: ListWheelChildLoopingListDelegate(
                              children: <Widget>[
                                _buildItem(const Text('to')),
                                for (var year = minYear; year <= maxYear; year++)
                                  _buildItem(Text('$year'))
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          ButtonBar(
            buttonTextTheme: ButtonTextTheme.accent,
            alignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FlatButton(
                child: const Text('CLEAR'),
                onPressed: () => Navigator.pop(context, const Tuple2<int, int>(null, null)),
              ),
              FlatButton(
                child: const Text('APPLY'),
                onPressed: () => Navigator.pop(context, Tuple2<int, int>(fromYear, toYear)),
              )
            ],
          )
        ],
      ),
    );

  Expanded buildDividers() => Expanded(
                          child: Column(
                            children: <Widget>[
                              Divider(height: 1, color: Colors.white,),
                              Spacer(),
                              Divider(color: Colors.white,),
                            ],
                          ),
                        );

  Widget _buildItem(Widget child, {double height = 70}) => SizedBox(
      width: double.infinity,
      height: height,
      child: Center(
        child: child,
      ),
    );
}


class GenresDrawer extends StatefulWidget {
  @override
  _GenresDrawerState createState() => _GenresDrawerState();
}

class _GenresDrawerState extends State<GenresDrawer> {

  @override
  Widget build(BuildContext context) {
    final model = context.watch<FilmsModel>();
    return Drawer(
        child: ListView.builder(
              itemCount: (model.genres?.length ?? 0) + 1,
              itemBuilder: (BuildContext context, int index) => index == 0
                  ? _buildRadio(context, model.currentGenre, null, Text(S.of(context).all))
                  : _buildRadio(context, model.currentGenre, model.genres[index - 1]['id'],
                  Text(model.genres[index - 1]['name'] ?? ''))),
        );
  }


  Widget _buildRadio(BuildContext context, int currentGenre, int value, Widget title) => RadioListTile<int>(
      value: value,
      groupValue: currentGenre,
      title: title,
      onChanged: (s) {
        context.read<FilmsModel>().currentGenre = s;
        Navigator.pop(context);
      });
}


Widget _loadView(BuildContext c) => Center(child: SpinKitFadingCube(color: Theme.of(c).primaryColor));
