// lib/blocs/navigation/navigation_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'navigation_event.dart';
part 'navigation_state.dart';

class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<ShowSearch>(_onShowSearch);
    on<ShowHome>(_onShowHome);
  }

  void _onShowSearch(ShowSearch event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isSearchVisible: true));
  }

  void _onShowHome(ShowHome event, Emitter<NavigationState> emit) {
    emit(state.copyWith(isSearchVisible: false));
  }
}
