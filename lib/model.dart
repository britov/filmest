import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_create/secret.dart';
import 'package:http/http.dart' as http;

class FilmsModel extends ChangeNotifier {

  List<Movie> movies = [];
  List<Map<String, dynamic>> genres;


  int _moviesRequestPage = 1;
  int _currentGenre;
  int _fromYear;
  int _toYear;
  String _tmdbLanguage = 'en-US';

  Future<void> loadMovies({bool added = true}) async {
    if (!added) {
      _moviesRequestPage = 1;
    }
    genres ??= await _getGenres(_tmdbLanguage);
    final results = (await _getMovies(_moviesRequestPage++, _currentGenre?.toString(), _tmdbLanguage))?.results;
    if (added && results != null) {
      movies.addAll(results);
    } else {
      movies = results ?? [];
    }
    notifyListeners();
  }

  set currentGenre(int genreId) {
    _currentGenre = genreId;
    notifyListeners();
    loadMovies(added: false);
  }

  void setDateFilter(int fromYear, int toYear) {
    _toYear = toYear;
    _fromYear = fromYear;
    notifyListeners();
    loadMovies(added: false);
  }

  int get currentGenre => _currentGenre;
  int get fromYear => _fromYear;
  int get toYear => _toYear;

  // ignore: avoid_setters_without_getters
  set lang(String lang) {
    print('language: $lang');
    _tmdbLanguage = lang;
  }

  Future<PaggableResult> _getMovies(int page, String genreId, String language, {int repeat = 0}) async {
    var url = 'https://api.themoviedb.org/3/discover/movie?api_key=$apiKey&page=$page&language=$language';
    if (genreId != null) {
      url += '&with_genres=$genreId';
    }
    if (fromYear != null) {
      url += '&release_date.gte=$fromYear-01-01';
    }
    if (toYear != null) {
      url += '&release_date.lte=$toYear-12-31';
    }
    print('getMovies from $url');
    final response = await http.get(url);
    if (response.statusCode == 200) {
      return PaggableResult.fromJson(json.decode(response.body));
    } else if (response.statusCode == 429 && repeat < 1) {
      print('statusCode == 429 && repeat');
      await Future.delayed(const Duration(seconds: 10));
      return _getMovies(page, genreId, language, repeat: repeat + 1);
    }
    print('getMovies return null');
    return null;
  }

  Future<List<Map<String, dynamic>>> _getGenres(String language) async {
    final response = await http.get('https://api.themoviedb.org/3/genre/movie/list?api_key=$apiKey&language=$language');
    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      final List<dynamic> genres = body['genres'];
      return genres.map((g) => g is Map<String, dynamic> ? g : null).toList();
    } else if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 10));
    }
    return null;
  }

  Future<List<String>> getVideo(num id) async {
    final response = await http.get('https://api.themoviedb.org/3/movie/$id/videos?api_key=$apiKey&language=$_tmdbLanguage');
    if (response.statusCode == 200) {
      return VideoResult.fromJson(json.decode(response.body)).res.map((v) => v.key).toList();
    } else if (response.statusCode == 429) {
      await Future.delayed(const Duration(seconds: 10));
    }
    return null;
  }

}

class PaggableResult {

  PaggableResult.fromJson(Map<String, dynamic> json) {
    if (json['results'] != null) {
      results = <Movie>[];
      json['results'].forEach((v) {
        results.add(Movie.fromJson(v));
      });
    }
    totalPages = json['total_pages'];
  }

  List<Movie> results;
  int totalPages;
}

class Movie {

  Movie.fromJson(this.json);

  Future<List<String>> videoKeys;
  Map<String, dynamic> json;

  String get poster => json['poster_path'];
  int get id => json['id'];
  String get title => json['title'];
}

class VideoResult {

  VideoResult.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    if (json['results'] != null) {
      res = <Video>[];
      json['results'].forEach((v) {
        res.add(Video.fromJson(v));
      });
    }
  }

  int id;
  List<Video> res;
}

class Video {

  Video.fromJson(Map<String, dynamic> json) {
    key = json['key'];
  }

  String key;
}

class Genre {

  Genre.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    name = json['name'];
  }

  num id;
  String name;
}
