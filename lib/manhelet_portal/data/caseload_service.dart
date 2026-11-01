import '../domain/models.dart';
import 'portal_client.dart';

class CaseloadService {
  Future<List<TreatmentUnitSummary>> listMyUnits() async {
    final rows = await portalClient
        .from('v_treatment_unit_caseload')
        .select()
        .order('unit_code');

    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return TreatmentUnitSummary(
        id: m['treatment_unit_id'] as String,
        unitCode: m['unit_code'] as String,
        titleHe: m['title_he'] as String,
        familyId: m['family_id'] as String,
        familyNameHe: m['family_name_he'] as String,
        status: m['status'] as String,
        primaryCaseManagerId: m['primary_case_manager_id'] as String?,
        personCount: (m['person_count'] as num?)?.toInt() ?? 0,
        openTaskCount: (m['open_task_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<TreatmentUnitSummary?> getUnit(String id) async {
    final rows = await listMyUnits();
    try {
      return rows.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<FamilySummary>> listFamilies({String search = ''}) async {
    var query = portalClient
        .from('families')
        .select('id, family_code, display_name_he, primary_locality_he, scenario_tag')
        .isFilter('deleted_at', null)
        .order('display_name_he');

    final rows = await query.limit(200);
    var list = (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return FamilySummary(
        id: m['id'] as String,
        familyCode: m['family_code'] as String,
        displayNameHe: m['display_name_he'] as String,
        localityHe: m['primary_locality_he'] as String?,
        scenarioTag: m['scenario_tag'] as String?,
      );
    }).toList();

    if (search.trim().isNotEmpty) {
      final q = search.trim().toLowerCase();
      list = list
          .where(
            (f) =>
                f.displayNameHe.toLowerCase().contains(q) ||
                f.familyCode.toLowerCase().contains(q) ||
                (f.localityHe?.toLowerCase().contains(q) ?? false),
          )
          .toList();
    }
    return list;
  }

  Future<FamilySummary?> getFamily(String id) async {
    final row = await portalClient
        .from('families')
        .select('id, family_code, display_name_he, primary_locality_he, scenario_tag')
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return FamilySummary(
      id: row['id'] as String,
      familyCode: row['family_code'] as String,
      displayNameHe: row['display_name_he'] as String,
      localityHe: row['primary_locality_he'] as String?,
      scenarioTag: row['scenario_tag'] as String?,
    );
  }

  Future<List<PersonSummary>> listPersons({String? unitId, String? familyId}) async {
    var query = portalClient
        .from('persons')
        .select(
          'id, first_name_he, last_name_he, treatment_unit_id, family_id, status, date_of_birth, phone, is_index_case',
        )
        .isFilter('deleted_at', null);

    if (unitId != null) query = query.eq('treatment_unit_id', unitId);
    if (familyId != null) query = query.eq('family_id', familyId);

    final rows = await query.order('last_name_he').limit(300);
    return (rows as List).map((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return PersonSummary(
        id: m['id'] as String,
        firstNameHe: m['first_name_he'] as String,
        lastNameHe: m['last_name_he'] as String,
        treatmentUnitId: m['treatment_unit_id'] as String,
        familyId: m['family_id'] as String,
        status: m['status'] as String,
        dateOfBirth: m['date_of_birth'] == null
            ? null
            : DateTime.tryParse(m['date_of_birth'] as String),
        phone: m['phone'] as String?,
        isIndexCase: m['is_index_case'] as bool? ?? false,
      );
    }).toList();
  }

  Future<PersonSummary?> getPerson(String id) async {
    final row = await portalClient
        .from('persons')
        .select(
          'id, first_name_he, last_name_he, treatment_unit_id, family_id, status, date_of_birth, phone, is_index_case',
        )
        .eq('id', id)
        .isFilter('deleted_at', null)
        .maybeSingle();
    if (row == null) return null;
    return PersonSummary(
      id: row['id'] as String,
      firstNameHe: row['first_name_he'] as String,
      lastNameHe: row['last_name_he'] as String,
      treatmentUnitId: row['treatment_unit_id'] as String,
      familyId: row['family_id'] as String,
      status: row['status'] as String,
      dateOfBirth: row['date_of_birth'] == null
          ? null
          : DateTime.tryParse(row['date_of_birth'] as String),
      phone: row['phone'] as String?,
      isIndexCase: row['is_index_case'] as bool? ?? false,
    );
  }

  Future<Map<String, int>> executiveSituation() async {
    final row =
        await portalClient.from('v_executive_situation').select().maybeSingle();
    if (row == null) return {};
    return row.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
  }
}
