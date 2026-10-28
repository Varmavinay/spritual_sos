import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/quotes.dart';
import '../models/quote.dart';

/// A daily reminder that reached this device.
@immutable
class Delivery {
  const Delivery(this.quote, this.at);

  final Quote quote;
  final DateTime at;

  Map<String, Object> toJson() =>
      {'id': quote.id, 'at': at.millisecondsSinceEpoch};

  static Delivery? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final at = json['at'];
    final quote = id is int ? quoteById(id) : null;
    if (quote == null || at is! int) return null;
    return Delivery(quote, DateTime.fromMillisecondsSinceEpoch(at));
  }

  @override
  bool operator ==(Object other) =>
      other is Delivery &&
      other.quote.id == quote.id &&
      other.at.millisecondsSinceEpoch == at.millisecondsSinceEpoch;

  @override
  int get hashCode => Object.hash(quote.id, at.millisecondsSinceEpoch);
}

/// What the user keeps on this device: their name, saved quotes,
/// reflections, and the history of reminders received. Nothing here leaves
/// the device.
class LibraryStore extends ChangeNotifier {
  LibraryStore(this._prefs) {
    _saved = [
      for (final id in _prefs.getStringList(_savedKey) ?? const <String>[])
        ?quoteById(int.tryParse(id) ?? -1),
    ];
    _reflections = {
      for (final entry in _decodeMap(_prefs.getString(_reflectionsKey)).entries)
        if (int.tryParse(entry.key) case final id?)
          if (entry.value is String) id: entry.value as String,
    };
    _history = _decodeDeliveries(_prefs.getString(_historyKey));
  }

  static const _savedKey = 'saved_quotes';
  static const _reflectionsKey = 'reflections';
  static const _historyKey = 'delivery_history';
  static const _nameKey = 'user_name';

  /// Oldest entries are dropped beyond this.
  static const maxHistory = 365;

  final SharedPreferences _prefs;
  late List<Quote> _saved;
  late Map<int, String> _reflections;
  late List<Delivery> _history;

  /// The name shown on the profile; empty until the user sets one.
  String get userName => _prefs.getString(_nameKey) ?? '';

  void setUserName(String value) {
    final name = value.trim();
    if (name == userName) return;
    _prefs.setString(_nameKey, name);
    notifyListeners();
  }

  /// Saved quotes, most recently saved first.
  List<Quote> get saved => List.unmodifiable(_saved);

  bool isSaved(Quote quote) => _saved.any((q) => q.id == quote.id);

  /// Saves or un-saves [quote]; returns whether it is now saved.
  bool toggleSaved(Quote quote) {
    final wasSaved = isSaved(quote);
    if (wasSaved) {
      _saved.removeWhere((q) => q.id == quote.id);
    } else {
      _saved.insert(0, quote);
    }
    _prefs.setStringList(_savedKey, [for (final q in _saved) '${q.id}']);
    notifyListeners();
    return !wasSaved;
  }

  String reflection(Quote quote) => _reflections[quote.id] ?? '';

  int get reflectionCount => _reflections.length;

  void setReflection(Quote quote, String text) {
    if (text.trim().isEmpty) {
      if (_reflections.remove(quote.id) == null) return;
    } else {
      if (_reflections[quote.id] == text) return;
      _reflections[quote.id] = text;
    }
    _prefs.setString(_reflectionsKey, jsonEncode({
      for (final e in _reflections.entries) '${e.key}': e.value,
    }));
    notifyListeners();
  }

  /// Reminders received, newest first.
  List<Delivery> get history => List.unmodifiable(_history);

  /// The reminder received today, if any.
  Delivery? get todaysDelivery {
    if (_history.isEmpty) return null;
    final latest = _history.first;
    final now = DateTime.now();
    final sameDay = latest.at.year == now.year &&
        latest.at.month == now.month &&
        latest.at.day == now.day;
    return sameDay && !latest.at.isAfter(now) ? latest : null;
  }

  /// Adds deliveries reported by the platform, ignoring ones already known.
  void addDeliveries(Iterable<Delivery> deliveries) {
    final known = _history.toSet();
    final fresh = deliveries.where(known.add).toList();
    if (fresh.isEmpty) return;
    _history
      ..addAll(fresh)
      ..sort((a, b) => b.at.compareTo(a.at));
    if (_history.length > maxHistory) _history.length = maxHistory;
    _prefs.setString(
        _historyKey, jsonEncode([for (final d in _history) d.toJson()]));
    notifyListeners();
  }

  static Map<String, Object?> _decodeMap(String? raw) {
    if (raw == null) return const {};
    try {
      final value = jsonDecode(raw);
      return value is Map<String, Object?> ? value : const {};
    } catch (_) {
      return const {};
    }
  }

  static List<Delivery> _decodeDeliveries(String? raw) {
    if (raw == null) return [];
    try {
      final value = jsonDecode(raw);
      if (value is! List) return [];
      return [for (final item in value) ?Delivery.fromJson(item)];
    } catch (_) {
      return [];
    }
  }
}
