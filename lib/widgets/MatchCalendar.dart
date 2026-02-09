import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../theme/theme.dart';

class MatchCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> matches;
  final Function(DateTime, List<Map<String, dynamic>>) onDaySelected;
  final Locale locale;

  const MatchCalendar({
    super.key,
    required this.matches,
    required this.onDaySelected,
    required this.locale,
  });

  @override
  State<MatchCalendar> createState() => _MatchCalendarState();
}

class _MatchCalendarState extends State<MatchCalendar> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;

  // Map to store matches grouped by date (normalized to midnight)
  Map<DateTime, List<Map<String, dynamic>>> _groupedMatches = {};

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = _focusedDay;
    _groupMatches();
  }

  @override
  void didUpdateWidget(covariant MatchCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.matches != widget.matches) {
      _groupMatches();
    }
  }

  void _groupMatches() {
    _groupedMatches = {};
    for (var match in widget.matches) {
      // Parse date from match data
      // Supporting both String ('yyyy-MM-dd') and DateTime objects
      DateTime? date;
      final rawDate = match['date'];

      if (rawDate is DateTime) {
        date = rawDate;
      } else if (rawDate is String) {
        date = DateTime.tryParse(rawDate);
      } else if (match['timestamp'] is DateTime) {
        date = match['timestamp'];
      }

      if (date != null) {
        final normalizedDate = DateTime(date.year, date.month, date.day);
        if (_groupedMatches[normalizedDate] == null) {
          _groupedMatches[normalizedDate] = [];
        }
        _groupedMatches[normalizedDate]!.add(match);
      }
    }
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final normalizedDate = DateTime(day.year, day.month, day.day);
    return _groupedMatches[normalizedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appTheme = context.appTheme;

    return TableCalendar<Map<String, dynamic>>(
      firstDay: DateTime.now().subtract(const Duration(days: 365)),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      locale: widget.locale.languageCode,
      eventLoader: _getEventsForDay,
      startingDayOfWeek: StartingDayOfWeek.monday,

      // Visual Styling
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
        weekendTextStyle: TextStyle(color: theme.textTheme.bodyMedium?.color),
      ),

      headerStyle: HeaderStyle(
        titleCentered: true,
        formatButtonVisible: false,
        titleTextStyle: theme.textTheme.titleMedium!.copyWith(
          fontWeight: FontWeight.bold,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: theme.iconTheme.color),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: theme.iconTheme.color,
        ),
      ),

      onDaySelected: (selectedDay, focusedDay) {
        if (!isSameDay(_selectedDay, selectedDay)) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          widget.onDaySelected(selectedDay, _getEventsForDay(selectedDay));
        }
      },
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
      },

      // Custom Builders for Cells
      calendarBuilders: CalendarBuilders(
        // 1. Marker Builder: Handles the Badge/Counter for multiple matches
        markerBuilder: (context, day, events) {
          if (events.isEmpty || events.length <= 1) return null;

          return Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: appTheme.errorColor, // Use error/alert color for badge
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Center(
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },

        // 2. Default Builder: Handles unselected days with matches (Stadium Icon)
        defaultBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          return _buildDayCell(context, day, events, false, theme, appTheme);
        },

        // 3. Selected Builder: Handles selected day
        selectedBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          return _buildDayCell(context, day, events, true, theme, appTheme);
        },

        // 4. Today Builder
        todayBuilder: (context, day, focusedDay) {
          final events = _getEventsForDay(day);
          return _buildDayCell(
            context,
            day,
            events,
            false,
            theme,
            appTheme,
            isToday: true,
          );
        },
      ),
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    DateTime day,
    List<Map<String, dynamic>> events,
    bool isSelected,
    ThemeData theme,
    AppTheme appTheme, {
    bool isToday = false,
  }) {
    final hasMatches = events.isNotEmpty;

    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isSelected
            ? appTheme.primaryColor
            : (isToday ? appTheme.primaryColor.withOpacity(0.1) : null),
        borderRadius: BorderRadius.circular(12),
        border: isToday && !isSelected
            ? Border.all(color: appTheme.primaryColor, width: 1)
            : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Stadium/Field Icon for days with matches
          if (hasMatches && !isSelected)
            Opacity(
              opacity: 0.15,
              child: Icon(
                Icons.sports_soccer, // Represents the field/match
                size: 28,
                color: appTheme.primaryColor,
              ),
            ),

          // Day Number
          Text(
            '${day.day}',
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : (isToday
                        ? appTheme.primaryColor
                        : theme.textTheme.bodyMedium?.color),
              fontWeight: (isSelected || isToday || hasMatches)
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
