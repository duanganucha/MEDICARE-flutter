import 'package:flutter/material.dart';

/// The colour schemes the user can switch between from the header.
enum Brand {
  /// The plum/peach design.
  plum('ม่วง'),

  /// The original teal palette from the web app.
  teal('เขียว');

  const Brand(this.label);

  /// Shown in the switcher's tooltip.
  final String label;

  Brand get next => this == Brand.plum ? Brand.teal : Brand.plum;
}

/// Holds the active [Brand] and lets any descendant change it.
class BrandScope extends InheritedWidget {
  const BrandScope({
    super.key,
    required this.brand,
    required this.onChanged,
    required super.child,
  });

  final Brand brand;
  final ValueChanged<Brand> onChanged;

  static BrandScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BrandScope>();
    assert(scope != null, 'No BrandScope above this widget');
    return scope!;
  }

  @override
  bool updateShouldNotify(BrandScope old) => old.brand != brand;
}
