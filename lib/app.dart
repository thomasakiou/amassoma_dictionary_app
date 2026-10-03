import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models/dictionary_entry.dart';
import 'services/dictionary_api.dart';

const ink = Color(0xFF18232C);
const ochre = Color(0xFF9B4B16);
const paper = Color(0xFFFCF9F2);
const paperInset = Color(0xFFF3EFE6);
const rule = Color(0xFFE6DFD2);

class AmassomaDictionaryApp extends StatelessWidget {
  const AmassomaDictionaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();
    return MaterialApp(
      title: 'Amassoma Dictionary',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ochre,
          primary: ink,
          secondary: ochre,
          surface: paper,
        ),
        textTheme: baseTextTheme.copyWith(
          headlineMedium: GoogleFonts.merriweather(
            fontSize: 22,
            height: 1.3,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          titleLarge: baseTextTheme.titleLarge?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: ink,
          ),
          bodyLarge: baseTextTheme.bodyLarge?.copyWith(height: 1.55),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: paper,
          foregroundColor: ink,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFF4E5D4),
          labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
                color: states.contains(WidgetState.selected) ? ochre : ink,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              )),
        ),
      ),
      home: const DictionaryShell(),
    );
  }
}

class DictionaryShell extends StatefulWidget {
  const DictionaryShell({super.key});

  @override
  State<DictionaryShell> createState() => _DictionaryShellState();
}

class _DictionaryShellState extends State<DictionaryShell> {
  static const _alphabetAudio = <String, String>{
    'A': 'a.mp3',
    'B': 'b.mp3',
    'D': 'd.mp3',
    'E': 'e.mp3',
    'Ẹ': 'ẹ.mp3',
    'F': 'f.mp3',
    'G': 'g.mp3',
    'H': 'h.mp3',
    'I': 'i.mp3',
    'J': 'j.mp3',
    'K': 'k.mp3',
    'L': 'l.mp3',
    'M': 'm.mp3',
    'N': 'n.mp3',
    'O': 'o.mp3',
    'Ọ': 'ọ.MP3',
    'P': 'p.mp3',
    'R': 'r.mp3',
    'S': 's.mp3',
    'T': 't.mp3',
    'U': 'u.mp3',
    'V': 'v.mp3',
    'W': 'w.mp3',
    'Y': 'y.mp3',
    'Z': 'z.mp3',
    'GB': 'gb.mp3',
    'KP': 'kp.mp3',
    'GH': 'gh.mp3',
  };
  static const _diacritics = [
    'ẹ',
    'ọ',
    'ị',
    'ụ',
    'ñ',
    'gh',
    'kp',
    'gb',
    '\u0301',
    '\u0300',
  ];

  final _api = const DictionaryApi();
  final _player = AudioPlayer();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  late final StreamSubscription<void> _audioSubscription;
  SharedPreferences? _preferences;
  List<DictionaryEntry> _entries = [];
  List<String> _savedIds = [];
  List<String> _recentIds = [];
  String? _error;
  String? _playingId;
  String? _playingAlphabet;
  String? _letter;
  String? _category;
  int _tab = 0;
  bool _loading = true;
  bool _englishFirst = false;

  @override
  void initState() {
    super.initState();
    _audioSubscription = _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playingId = null;
          _playingAlphabet = null;
        });
      }
    });
    _initialize();
  }

  Future<void> _initialize() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) return;
    _preferences = preferences;
    _savedIds = preferences.getStringList('saved_entry_ids') ?? [];
    _recentIds = preferences.getStringList('recent_entry_ids') ?? [];
    final cache = preferences.getString('dictionary_entries_cache');
    if (cache != null) {
      try {
        final values =
            (jsonDecode(cache) as List).whereType<Map<String, dynamic>>();
        setState(
            () => _entries = values.map(DictionaryEntry.fromJson).toList());
      } on FormatException {
        await preferences.remove('dictionary_entries_cache');
      } on TypeError {
        await preferences.remove('dictionary_entries_cache');
      }
    }
    await _refresh(showLoading: _entries.isEmpty);
  }

  Future<void> _refresh({bool showLoading = true}) async {
    if (showLoading && mounted) setState(() => _loading = true);
    try {
      final entries = await _api.fetchEntries();
      await _preferences?.setString(
        'dictionary_entries_cache',
        jsonEncode(entries.map((entry) => entry.toJson()).toList()),
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _audioSubscription.cancel();
    _player.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<DictionaryEntry> get _savedEntries =>
      _entries.where((entry) => _savedIds.contains(entry.id)).toList();

  List<DictionaryEntry> get _recentEntries => _recentIds
      .map((id) => _entries.where((entry) => entry.id == id).firstOrNull)
      .whereType<DictionaryEntry>()
      .toList();

  List<DictionaryEntry> get _searchResults {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];
    return _entries.where((entry) {
      final searched = _englishFirst ? entry.translation : entry.word;
      final alternate = _englishFirst ? entry.word : entry.translation;
      return searched.toLowerCase().contains(query) ||
          alternate.toLowerCase().contains(query);
    }).toList();
  }

  List<DictionaryEntry> get _browseEntries => _entries.where((entry) {
        final startsWithLetter =
            _letter == null || entry.word.toUpperCase().startsWith(_letter!);
        final matchesCategory =
            _category == null || entry.category == _category;
        return startsWithLetter && matchesCategory;
      }).toList()
        ..sort((first, second) =>
            first.word.toLowerCase().compareTo(second.word.toLowerCase()));

  Future<void> _toggleSaved(DictionaryEntry entry) async {
    setState(() {
      if (_savedIds.contains(entry.id)) {
        _savedIds.remove(entry.id);
      } else {
        _savedIds.add(entry.id);
      }
    });
    await _preferences?.setStringList('saved_entry_ids', _savedIds);
  }

  Future<void> _openEntry(DictionaryEntry entry) async {
    _recentIds.remove(entry.id);
    _recentIds.insert(0, entry.id);
    if (_recentIds.length > 8) _recentIds = _recentIds.take(8).toList();
    await _preferences?.setStringList('recent_entry_ids', _recentIds);
    if (!mounted) return;
    setState(() {});
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _entryDetails(entry),
    );
  }

  Future<void> _playAudio(DictionaryEntry entry) async {
    final path = entry.audioUrl;
    if (path == null || path.isEmpty) return;
    try {
      await _player.stop();
      setState(() {
        _playingId = entry.id;
        _playingAlphabet = null;
      });
      await _player.play(UrlSource(_api.audioUri(path).toString()));
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This recording could not be played.')),
      );
    }
  }

  Future<void> _playAlphabetSound(String letter) async {
    final filename = _alphabetAudio[letter];
    if (filename == null) return;
    try {
      await _player.stop();
      setState(() {
        _playingId = null;
        _playingAlphabet = letter;
      });
      await _player.play(AssetSource('audio/alphabet/$filename'));
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingAlphabet = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This letter recording could not be played.')),
      );
    }
  }

  void _insertDiacritic(String value) {
    final selection = _searchController.selection;
    final start =
        selection.isValid ? selection.start : _searchController.text.length;
    final end =
        selection.isValid ? selection.end : _searchController.text.length;
    final text = _searchController.text.replaceRange(start, end, value);
    _searchController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: start + value.length),
    );
    setState(() {});
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_homePage(), _browsePage(), _savedPage()];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AMASSOMA DICTIONARY',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: ochre,
                )),
            Text('Amassoma · Bayelsa',
                style: Theme.of(context).textTheme.titleSmall),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh dictionary',
            onPressed: _loading ? null : () => _refresh(),
            icon: const Icon(Icons.sync),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
          top: false, child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.manage_search),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Browse'),
          NavigationDestination(
              icon: Icon(Icons.bookmark_border),
              selectedIcon: Icon(Icons.bookmark),
              label: 'Saved'),
        ],
      ),
    );
  }

  Widget _homePage() {
    final query = _searchController.text.trim();
    return RefreshIndicator(
      onRefresh: () => _refresh(showLoading: false),
      color: ochre,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text('A living record of Amassoma Language',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text('Look up words and phrases in the Amassoma lexicon.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: const Color(0xFF65635D))),
          const SizedBox(height: 20),
          _searchPanel(),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeading('Search results',
                trailing: '${_searchResults.length}'),
            const SizedBox(height: 8),
            if (_searchResults.isEmpty)
              _emptyMessage('No matching entries in the approved lexicon.')
            else
              ..._searchResults.map(_entryTile),
          ] else ...[
            const SizedBox(height: 20),
            if (_error != null) _errorNotice(),
            if (_loading && _entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator(color: ochre)),
              )
            else if (_entries.isNotEmpty)
              _featuredEntry(_entries.first)
            else
              _emptyMessage('No approved vocabulary is available yet.'),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: _sectionHeading('Recently viewed')),
              TextButton.icon(
                onPressed: () => setState(() => _tab = 1),
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Browse'),
              ),
            ]),
            const SizedBox(height: 8),
            if (_recentEntries.isEmpty)
              _emptyMessage('Words you open will appear here.')
            else
              ..._recentEntries.take(3).map(_entryTile),
          ],
        ],
      ),
    );
  }

  Widget _searchPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: rule),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Amassoma → English')),
            ButtonSegment(value: true, label: Text('English → Amassoma')),
          ],
          selected: {_englishFirst},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              setState(() => _englishFirst = selection.first),
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            textStyle: WidgetStateProperty.all(
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: _englishFirst
                ? 'Search an English meaning...'
                : 'Search Amassoma or English...',
            prefixIcon: const Icon(Icons.search, color: ochre),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.close),
                  ),
            filled: true,
            fillColor: paper,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 10),
        Text('SPECIAL ORTHOGRAPHY',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: const Color(0xFF75736C),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                )),
        const SizedBox(height: 6),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _diacritics.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final value = _diacritics[index];
              final label = value == '\u0301'
                  ? '´'
                  : value == '\u0300'
                      ? '`'
                      : value;
              return SizedBox(
                width: value.length > 1 ? 42 : 38,
                child: OutlinedButton(
                  onPressed: () => _insertDiacritic(value),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    backgroundColor: paper,
                    foregroundColor: ink,
                    side: const BorderSide(color: rule),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5)),
                  ),
                  child: Text(label,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _featuredEntry(DictionaryEntry entry) {
    final saved = _savedIds.contains(entry.id);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration:
          BoxDecoration(color: ink, borderRadius: BorderRadius.circular(8)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.menu_book, size: 16, color: Color(0xFFFFC58F)),
          const SizedBox(width: 7),
          Expanded(
              child: Text('FROM THE APPROVED LEXICON',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFFFC58F),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ))),
          IconButton(
            tooltip: saved ? 'Remove saved word' : 'Save word',
            onPressed: () => _toggleSaved(entry),
            color: Colors.white,
            icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
          ),
        ]),
        const SizedBox(height: 8),
        Text(entry.word,
            style: GoogleFonts.merriweather(
              color: Colors.white,
              fontSize: 25,
              height: 1.35,
              fontWeight: FontWeight.w700,
            )),
        if (entry.pronunciation?.isNotEmpty == true) ...[
          const SizedBox(height: 5),
          Text(entry.pronunciation!,
              style: const TextStyle(color: Color(0xFFC8D0D1))),
        ],
        const SizedBox(height: 10),
        Text(entry.translation,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                height: 1.45,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(children: [
          _categoryTag(entry.category, dark: true),
          const Spacer(),
          if (entry.audioUrl?.isNotEmpty == true)
            IconButton.filledTonal(
              tooltip:
                  _playingId == entry.id ? 'Playing' : 'Play pronunciation',
              onPressed: () => _playAudio(entry),
              icon: Icon(
                  _playingId == entry.id ? Icons.graphic_eq : Icons.volume_up),
            ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _openEntry(entry),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: const Text('Open entry  →'),
          ),
        ]),
      ]),
    );
  }

  Widget _browsePage() {
    final categories = _entries.map((entry) => entry.category).toSet().toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Browse the lexicon',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Explore approved entries by initial or category.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF65635D))),
        if (_error != null) ...[const SizedBox(height: 16), _errorNotice()],
        const SizedBox(height: 18),
        _sectionHeading('ORTHOGRAPHIC INDEX'),
        const SizedBox(height: 9),
        Wrap(spacing: 7, runSpacing: 7, children: [
          _letterChip(null, 'All'),
          ..._alphabetAudio.keys.map((value) => _letterChip(value, value)),
        ]),
        if (categories.isNotEmpty) ...[
          const SizedBox(height: 22),
          _sectionHeading('CATEGORIES'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _categoryChip(null, 'All types'),
            ...categories.map((value) => _categoryChip(value, value)),
          ]),
        ],
        const SizedBox(height: 20),
        _sectionHeading(
            _letter == null ? 'Entries' : 'Words beginning with $_letter',
            trailing: '${_browseEntries.length}'),
        const SizedBox(height: 8),
        if (_browseEntries.isEmpty)
          _emptyMessage(_entries.isEmpty
              ? 'No approved words are available yet.'
              : 'No approved entries match these filters.')
        else
          ..._browseEntries.map(_entryTile),
      ],
    );
  }

  Widget _letterChip(String? value, String label) {
    final selected = _letter == value;
    return Container(
      width: value == null ? 64 : 74,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: selected ? ink : Colors.white,
        border: Border.all(color: selected ? ink : rule),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(children: [
        Expanded(
          child: TextButton(
            onPressed: () => setState(() => _letter = value),
            style: TextButton.styleFrom(
              foregroundColor: selected ? Colors.white : ink,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 3),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
        if (value != null)
          IconButton(
            tooltip: 'Play $label sound',
            onPressed: () => _playAlphabetSound(value),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 28, height: 36),
            color: _playingAlphabet == value ? ochre : const Color(0xFF77756E),
            icon: Icon(
              _playingAlphabet == value ? Icons.graphic_eq : Icons.volume_up,
              size: 16,
            ),
          ),
      ]),
    );
  }

  Widget _categoryChip(String? value, String label) {
    final selected = _category == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _category = value),
      labelStyle: TextStyle(
          color: selected ? ochre : ink,
          fontSize: 12,
          fontWeight: FontWeight.w600),
      backgroundColor: Colors.white,
      selectedColor: const Color(0xFFF5E8D8),
      side: BorderSide(color: selected ? ochre : rule),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    );
  }

  Widget _savedPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        Text('Saved vocabulary',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text('Your personal word list stays on this device.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: const Color(0xFF65635D))),
        const SizedBox(height: 20),
        if (_savedEntries.isEmpty)
          _emptyMessage('Save an entry to build your personal collection.')
        else ...[
          _sectionHeading('YOUR COLLECTION',
              trailing: '${_savedEntries.length}'),
          const SizedBox(height: 8),
          ..._savedEntries.map(_entryTile),
        ],
      ],
    );
  }

  Widget _entryTile(DictionaryEntry entry) {
    final saved = _savedIds.contains(entry.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: rule),
          borderRadius: BorderRadius.circular(7)),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: () => _openEntry(entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 8, 13),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(entry.word,
                            style: GoogleFonts.merriweather(
                                fontSize: 17,
                                height: 1.4,
                                fontWeight: FontWeight.w700,
                                color: ink)),
                        _categoryTag(entry.category),
                      ]),
                  if (entry.pronunciation?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(entry.pronunciation!,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF77756E))),
                  ],
                  const SizedBox(height: 6),
                  Text(entry.translation,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, height: 1.45)),
                ])),
            if (entry.audioUrl?.isNotEmpty == true)
              IconButton(
                tooltip: 'Play pronunciation',
                visualDensity: VisualDensity.compact,
                onPressed: () => _playAudio(entry),
                color: ochre,
                icon: Icon(_playingId == entry.id
                    ? Icons.graphic_eq
                    : Icons.volume_up_outlined),
              ),
            IconButton(
              tooltip: saved ? 'Remove saved word' : 'Save word',
              visualDensity: VisualDensity.compact,
              onPressed: () => _toggleSaved(entry),
              color: saved ? ochre : const Color(0xFF77756E),
              icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _entryDetails(DictionaryEntry entry) {
    return Container(
      constraints:
          BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.82),
      decoration: const BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            22, 12, 22, MediaQuery.viewInsetsOf(context).bottom + 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
              child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFCDC7BC),
                      borderRadius: BorderRadius.circular(4)))),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: _categoryTag(entry.category)),
            IconButton(
              tooltip: _savedIds.contains(entry.id)
                  ? 'Remove saved word'
                  : 'Save word',
              onPressed: () => _toggleSaved(entry),
              color: ochre,
              icon: Icon(_savedIds.contains(entry.id)
                  ? Icons.bookmark
                  : Icons.bookmark_border),
            ),
            IconButton(
                tooltip: 'Close entry',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close)),
          ]),
          const SizedBox(height: 8),
          Text(entry.word,
              style: GoogleFonts.merriweather(
                  fontSize: 28,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  color: ink)),
          if (entry.pronunciation?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Text(entry.pronunciation!,
                style: const TextStyle(color: Color(0xFF65635D), fontSize: 14)),
          ],
          const SizedBox(height: 20),
          const Divider(color: rule),
          const SizedBox(height: 12),
          Text('MEANING',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: ochre, fontWeight: FontWeight.w700, letterSpacing: 1)),
          const SizedBox(height: 8),
          Text(entry.translation,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontSize: 18, color: ink)),
          if (entry.authorUsername?.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text('Contributed by ${entry.authorUsername}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF77756E))),
          ],
          if (entry.audioUrl?.isNotEmpty == true) ...[
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => _playAudio(entry),
                icon: Icon(_playingId == entry.id
                    ? Icons.graphic_eq
                    : Icons.volume_up),
                label: Text(_playingId == entry.id
                    ? 'Playing pronunciation'
                    : 'Play pronunciation'),
                style: FilledButton.styleFrom(
                    backgroundColor: ink,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6))),
              ),
            ),
          ],
        ]),
      ),
    );
  }

  Widget _categoryTag(String category, {bool dark = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
          color: dark ? const Color(0xFF344149) : const Color(0xFFF6E8D9),
          borderRadius: BorderRadius.circular(4)),
      child: Text(category.toUpperCase(),
          style: TextStyle(
            color: dark ? const Color(0xFFFFC58F) : ochre,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.45,
          )),
    );
  }

  Widget _sectionHeading(String title, {String? trailing}) {
    return Row(children: [
      Expanded(
          child: Text(title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4))),
      if (trailing != null)
        Text(trailing,
            style: const TextStyle(
                color: Color(0xFF77756E),
                fontSize: 12,
                fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _emptyMessage(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: paperInset,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: rule)),
      child: Text(message,
          style: const TextStyle(color: Color(0xFF65635D), height: 1.5)),
    );
  }

  Widget _errorNotice() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
      decoration: BoxDecoration(
          color: const Color(0xFFFFF0E8),
          border: Border.all(color: const Color(0xFFE8C5B0)),
          borderRadius: BorderRadius.circular(6)),
      child: Row(children: [
        const Icon(Icons.cloud_off, size: 18, color: ochre),
        const SizedBox(width: 9),
        Expanded(
            child: Text(
          _entries.isEmpty
              ? 'Could not reach the dictionary. $_error'
              : 'Offline: showing saved dictionary data.',
          style: const TextStyle(fontSize: 12, height: 1.4),
        )),
        IconButton(
            tooltip: 'Retry',
            visualDensity: VisualDensity.compact,
            onPressed: () => _refresh(),
            icon: const Icon(Icons.refresh, size: 19)),
      ]),
    );
  }
}
