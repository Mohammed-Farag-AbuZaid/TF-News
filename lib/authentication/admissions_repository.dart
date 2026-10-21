import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:get/get.dart';
import 'package:tf_news/authentication/admissions_models.dart';
import 'package:tf_news/authentication/admissions_programs.dart';

class AdmissionsRepository {
  AdmissionsRepository._();
  static final AdmissionsRepository instance = AdmissionsRepository._();
  factory AdmissionsRepository() => instance;

  static const bool useSampleData = false;


  static const String apiBase = 'https://n8n.tfunions.com/webhook/tf';

  final GetConnect _http = GetConnect(timeout: const Duration(seconds: 25));
  // Short timeout for the optional /all-ways endpoint so a missing one never stalls loading.
  final GetConnect _probe = GetConnect(timeout: const Duration(seconds: 8));

  /// 0..1 while programs are loading, null otherwise (drives the progress bar).
  final ValueNotifier<double?> programsProgress = ValueNotifier<double?>(null);

  List<University>? _universities;
  final Map<int, List<ScholarshipWay>> _ways = {};
  List<ScholarshipWay>? _allWays;
  List<Program>? _programs;

  Future<dynamic> _getJson(String path, {GetConnect? client}) async {
    final res = await (client ?? _http).get('$apiBase$path');
    if (res.hasError) {
      throw Exception('Could not load data (${res.statusCode ?? 'no connection'})');
    }
    dynamic body = res.body;
    if (body is String) {
      body = body.trim().isEmpty ? null : jsonDecode(body);
    }
    return body;
  }

  Future<List<University>> getUniversities({bool refresh = false}) async {
    if (!refresh && _universities != null) return _universities!;
    List<University> list;
    if (useSampleData) {
      list = List<University>.of(_sampleUniversities); 
    } else {
      final body = await _getJson('/universities');
      final raw = (body is Map ? body['universities'] : body) as List? ?? const [];
      list = raw
          .whereType<Map>()
          .map((m) => University.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    list.sort((a, b) => a.uniId.compareTo(b.uniId)); 
    return _universities = list;
  }

  Future<University?> getUniversity(int uniId) async {
    final all = await getUniversities();
    for (final u in all) {
      if (u.uniId == uniId) return u;
    }
    return null;
  }

  Future<List<ScholarshipWay>> getWays(int uniId) async {
    final cached = _ways[uniId];
    if (cached != null) return cached;
    List<ScholarshipWay> list;
    if (useSampleData) {
      list = _sampleWays.where((w) => w.uniId == uniId).toList();
    } else {
      final body = await _getJson('/university-ways?uni_id=$uniId');
      final raw = (body is Map ? body['ways'] : body) as List? ?? const [];
      list = raw
          .whereType<Map>()
          .map((m) => ScholarshipWay.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }
    list.sort((a, b) => a.wayNo.compareTo(b.wayNo));
    return _ways[uniId] = list;
  }

  /// Every way for every university, in ONE request.
  /// Needs a new n8n webhook:  GET {apiBase}/all-ways  ->  { "ways": [ ...same shape as /university-ways... ] }
  /// If that endpoint does not exist yet, we fall back to loading the universities
  /// that have ways, 8 at a time (slower, but works with today's API).
  Future<List<ScholarshipWay>> getAllWays({bool refresh = false}) async {
    if (!refresh && _allWays != null) return _allWays!;
    List<ScholarshipWay> list;
    if (useSampleData) {
      list = List<ScholarshipWay>.of(_sampleWays);
    } else {
      try {
        final body = await _getJson('/all-ways', client: _probe);
        final raw = (body is Map ? body['ways'] : body) as List? ?? const [];
        list = raw
            .whereType<Map>()
            .map((m) => ScholarshipWay.fromJson(Map<String, dynamic>.from(m)))
            .toList();
      } catch (_) {
        list = await _loadWaysBatched();
      }
    }
    return _allWays = list;
  }

  Future<List<ScholarshipWay>> _loadWaysBatched() async {
    final unis = (await getUniversities()).where((u) => u.waysFound > 0).toList();
    final out = <ScholarshipWay>[];
    const chunkSize = 16;
    programsProgress.value = 0;
    for (var i = 0; i < unis.length; i += chunkSize) {
      final chunk = unis.skip(i).take(chunkSize);
      final results = await Future.wait(chunk.map((u) async {
        try {
          return await getWays(u.uniId);
        } catch (_) {
          return <ScholarshipWay>[]; // one bad university must not break the page
        }
      }));
      for (final r in results) {
        out.addAll(r);
      }
      programsProgress.value = (i + chunkSize).clamp(0, unis.length) / unis.length;
    }
    return out;
  }

  Future<List<Program>> getPrograms({bool refresh = false}) async {
    if (!refresh && _programs != null) return _programs!;
    final unis = await getUniversities(refresh: refresh);
    try {
      final ways = await getAllWays(refresh: refresh);
      return _programs = buildPrograms(unis, ways);
    } finally {
      programsProgress.value = null;
    }
  }

}



const _sampleUniversities = <University>[
  University(uniId: 1, name: 'Sample University One', country: 'United States of America', region: 'Americas', qsRank: 1, qsRankText: '1', website: 'https://example.edu', researched: true, waysFound: 2),
  University(uniId: 2, name: 'Sample University Two', country: 'United Kingdom', region: 'Europe', qsRank: 2, qsRankText: '2', website: 'https://example.ac.uk', researched: true, waysFound: 1),
  University(uniId: 3, name: 'Sample University Three', country: 'China (Mainland)', region: 'Asia', qsRank: 17, qsRankText: '17', website: 'https://example.edu.cn', researched: false, waysFound: 0),
  University(uniId: 347, name: 'Sample Cairo University', country: 'Egypt', region: 'Africa', qsRank: 347, qsRankText: '347', website: 'https://example.edu.eg', researched: true, waysFound: 1),
];

const _sampleBody = '''
# Sample way

**Provider:** Sample provider
**Coverage:** full
**University:** Sample

## Overview

> Sample text. In the real app this box holds a sentence copied word-for-word from the official page.

Source: https://example.edu/scholarships

## Requirements

> Sample requirement text copied from the official page.

Source: https://example.edu/scholarships

## How to apply

> Sample application steps copied from the official page.

Source: https://example.edu/apply

## Deadlines

> Sample deadline text copied from the official page.

Source: https://example.edu/apply

## Apply link

> Apply at https://example.edu/apply

Source: https://example.edu/apply
''';

const _sampleWays = <ScholarshipWay>[
  ScholarshipWay(uniId: 1, wayNo: 1, title: 'Sample need-blind aid', provider: 'Sample University One', scope: 'university', coverage: 'full', markdown: _sampleBody, sourceUrls: ['https://example.edu/scholarships']),
  ScholarshipWay(uniId: 1, wayNo: 2, title: 'Sample external foundation', provider: 'Sample Foundation', scope: 'external_program', coverage: 'partial', markdown: _sampleBody, sourceUrls: ['https://example.edu/apply']),
  ScholarshipWay(uniId: 2, wayNo: 1, title: 'Sample merit scholarship', provider: 'Sample University Two', scope: 'university', coverage: 'partial', markdown: _sampleBody, sourceUrls: ['https://example.ac.uk/fees']),
  ScholarshipWay(uniId: 347, wayNo: 1, title: 'Sample excellence scholarship', provider: 'Sample Cairo University', scope: 'university', coverage: 'full', markdown: _sampleBody, sourceUrls: ['https://example.edu.eg/scholarships']),
];