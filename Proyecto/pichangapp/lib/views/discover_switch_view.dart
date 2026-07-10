import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'match_sport_view.dart';
import 'squad_discover_view.dart';

class DiscoverSwitchView extends StatefulWidget {
  const DiscoverSwitchView({super.key});

  @override
  State<DiscoverSwitchView> createState() => _DiscoverSwitchViewState();
}

class _DiscoverSwitchViewState extends State<DiscoverSwitchView> {
  bool _modoSquads = false;

  void _mostrarSquads() {
    setState(() {
      _modoSquads = true;
    });
  }

  void _mostrarPersonas() {
    setState(() {
      _modoSquads = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_modoSquads) {
      return SquadDiscoverView(
        onCambiarAModoPersonas: _mostrarPersonas,
      );
    }

    return Stack(
      children: [
        const MatchSportView(),
        Positioned(
          top: MediaQuery.of(context).padding.top + 6,
          left: 6,
          child: Material(
            color: Colors.transparent,
            child: Tooltip(
              message: 'Ver Squads',
              child: InkWell(
                onTap: _mostrarSquads,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surface.withOpacity(0.92),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.border,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.20),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.groups_2,
                    color: AppTheme.primarySoft,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}