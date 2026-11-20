import 'package:flutter/material.dart';

import '../data/models.dart';
import '../logic/settings.dart';

/// Lets the user choose All of Juz 30, one surah, or a range of surahs.
class ScopeSelector extends StatelessWidget {
  const ScopeSelector({
    super.key,
    required this.settings,
    required this.data,
    required this.onChanged,
  });

  final AppSettings settings;
  final QuranData data;
  final ValueChanged<AppSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<ScopeType>(
          showSelectedIcon: false,
          segments: const <ButtonSegment<ScopeType>>[
            ButtonSegment<ScopeType>(value: ScopeType.all, label: Text('All Juz 30')),
            ButtonSegment<ScopeType>(value: ScopeType.surah, label: Text('One Surah')),
            ButtonSegment<ScopeType>(value: ScopeType.range, label: Text('Range')),
          ],
          selected: <ScopeType>{settings.scopeType},
          onSelectionChanged: (Set<ScopeType> s) =>
              onChanged(settings.copyWith(scopeType: s.first)),
        ),
      ),
    ];

    if (settings.scopeType == ScopeType.surah) {
      children.add(const SizedBox(height: 14));
      children.add(_SurahDropdown(
        label: 'Surah',
        data: data,
        value: settings.fromSurah,
        onChanged: (int v) => onChanged(settings.copyWith(fromSurah: v)),
      ));
    } else if (settings.scopeType == ScopeType.range) {
      final int lo = settings.fromSurah <= settings.toSurah ? settings.fromSurah : settings.toSurah;
      final int hi = settings.fromSurah <= settings.toSurah ? settings.toSurah : settings.fromSurah;
      children.add(const SizedBox(height: 14));
      children.add(_SurahDropdown(
        label: 'From Surah',
        data: data,
        value: lo,
        onChanged: (int v) => onChanged(
          settings.copyWith(fromSurah: v, toSurah: hi < v ? v : hi),
        ),
      ));
      children.add(const SizedBox(height: 12));
      children.add(_SurahDropdown(
        label: 'To Surah',
        data: data,
        value: hi,
        onChanged: (int v) => onChanged(
          settings.copyWith(toSurah: v, fromSurah: lo > v ? v : lo),
        ),
      ));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

class _SurahDropdown extends StatelessWidget {
  const _SurahDropdown({
    required this.label,
    required this.data,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final QuranData data;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          isExpanded: true,
          value: value,
          borderRadius: BorderRadius.circular(16),
          items: <DropdownMenuItem<int>>[
            for (final Surah s in data.surahs)
              DropdownMenuItem<int>(
                value: s.number,
                child: Text('${s.number} · ${s.nameEn} (${s.ayahCount} ayahs)'),
              ),
          ],
          onChanged: (int? v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}
