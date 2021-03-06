// Copyright (C) 2019 - present Instructure, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

import 'package:fluro/fluro.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_parent/router/parent_router.dart';
import 'package:flutter_parent/utils/logger.dart';
import 'package:flutter_parent/utils/service_locator.dart';

class QuickNav {
  Future<T> push<T extends Object>(BuildContext context, Widget widget) {
    _logShow(widget);
    return Navigator.of(context).push(MaterialPageRoute(builder: (context) => widget));
  }

  /// Default method for pushing screens, uses material transition
  Future<T> pushRoute<T extends Object>(BuildContext context, String route,
      {TransitionType transitionType = TransitionType.material}) {
    return ParentRouter.router.navigateTo(context, route, transition: transitionType);
  }

  Future<T> replaceRoute<T extends Object>(BuildContext context, String route,
      {TransitionType transitionType = TransitionType.material}) {
    return ParentRouter.router.navigateTo(context, route, transition: transitionType, replace: true);
  }

  Future<T> pushRouteAndClearStack<T extends Object>(BuildContext context, String route,
      {TransitionType transitionType = TransitionType.material}) {
    return ParentRouter.router.navigateTo(context, route, transition: transitionType, clearStack: true);
  }

  void _logShow(Widget widget) {
    final message = 'Pushing widget: ${widget.runtimeType.toString()}';
    locator<Logger>().log(message);
  }
}
