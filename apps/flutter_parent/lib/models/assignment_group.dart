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

import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:flutter_parent/models/assignment.dart';

part 'assignment_group.g.dart';

/// To have this built_value be generated, run this command from the project root:
/// flutter packages pub run build_runner build --delete-conflicting-outputs
abstract class AssignmentGroup implements Built<AssignmentGroup, AssignmentGroupBuilder> {
  @BuiltValueSerializer(serializeNulls: true)
  static Serializer<AssignmentGroup> get serializer => _$assignmentGroupSerializer;

  AssignmentGroup._();

  factory AssignmentGroup([void Function(AssignmentGroupBuilder) updates]) = _$AssignmentGroup;

  String get id;

  String get name;

  int get position;

  @BuiltValueField(wireName: 'group_weight')
  double get groupWeight;

  BuiltList<Assignment> get assignments;

  static void _initializeBuilder(AssignmentGroupBuilder b) => b
    ..position = 0
    ..groupWeight = 0;
}
