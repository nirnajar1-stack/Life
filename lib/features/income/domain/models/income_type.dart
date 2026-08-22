enum IncomeType {
  salary,
  variable,
}

extension IncomeTypeX on IncomeType {
  String get label {
    switch (this) {
      case IncomeType.salary:
        return 'משכורת';
      case IncomeType.variable:
        return 'חד-פעמית';
    }
  }

  String get dbValue {
    switch (this) {
      case IncomeType.salary:
        return 'salary';
      case IncomeType.variable:
        return 'variable';
    }
  }

  static IncomeType fromDb(String? value) {
    switch (value) {
      case 'salary':
        return IncomeType.salary;
      default:
        return IncomeType.variable;
    }
  }
}

class IncomeCategoryTaxonomy {
  const IncomeCategoryTaxonomy._();

  static const String salary = 'משכורת';
  static const String freelance = 'עבודה צדדית';
  static const String sale = 'מכירה / יד שנייה';
  static const String investment = 'השקעות / ריבית';
  static const String refund = 'מתנה / החזר';
  static const String other = 'אחר';

  static const List<String> all = [
    salary,
    freelance,
    sale,
    investment,
    refund,
    other,
  ];
}
