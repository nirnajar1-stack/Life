enum TaskStatus {
  inbox,
  ready,
  inProgress,
  waiting,
  done,
  archived,
}

extension TaskStatusX on TaskStatus {
  String get dbValue {
    switch (this) {
      case TaskStatus.inbox:
        return 'inbox';
      case TaskStatus.ready:
        return 'ready';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.waiting:
        return 'waiting';
      case TaskStatus.done:
        return 'done';
      case TaskStatus.archived:
        return 'archived';
    }
  }

  String get labelHe {
    switch (this) {
      case TaskStatus.inbox:
        return 'תיבה';
      case TaskStatus.ready:
        return 'מוכן';
      case TaskStatus.inProgress:
        return 'בעבודה';
      case TaskStatus.waiting:
        return 'ממתין';
      case TaskStatus.done:
        return 'הושלם';
      case TaskStatus.archived:
        return 'ארכיון';
    }
  }

  static TaskStatus fromDb(String? raw) {
    switch (raw) {
      case 'inbox':
        return TaskStatus.inbox;
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'waiting':
        return TaskStatus.waiting;
      case 'done':
        return TaskStatus.done;
      case 'archived':
        return TaskStatus.archived;
      default:
        return TaskStatus.ready;
    }
  }
}

enum Eisenhower {
  doNow,
  schedule,
  delegate,
  eliminate,
}

extension EisenhowerX on Eisenhower {
  String get dbValue {
    switch (this) {
      case Eisenhower.doNow:
        return 'P1_DO';
      case Eisenhower.schedule:
        return 'P2_SCHEDULE';
      case Eisenhower.delegate:
        return 'P3_DELEGATE';
      case Eisenhower.eliminate:
        return 'P4_ELIMINATE';
    }
  }

  String get shortLabel {
    switch (this) {
      case Eisenhower.doNow:
        return 'P1';
      case Eisenhower.schedule:
        return 'P2';
      case Eisenhower.delegate:
        return 'P3';
      case Eisenhower.eliminate:
        return 'P4';
    }
  }

  String get labelHe {
    switch (this) {
      case Eisenhower.doNow:
        return 'עשה עכשיו';
      case Eisenhower.schedule:
        return 'תזמן';
      case Eisenhower.delegate:
        return 'האצל';
      case Eisenhower.eliminate:
        return 'בטל / נמוך';
    }
  }

  String get hintHe {
    switch (this) {
      case Eisenhower.doNow:
        return 'דחוף וחשוב';
      case Eisenhower.schedule:
        return 'חשוב, לא דחוף';
      case Eisenhower.delegate:
        return 'דחוף, לא חשוב';
      case Eisenhower.eliminate:
        return 'לא דחוף ולא חשוב';
    }
  }

  int get rank {
    switch (this) {
      case Eisenhower.doNow:
        return 1;
      case Eisenhower.schedule:
        return 2;
      case Eisenhower.delegate:
        return 3;
      case Eisenhower.eliminate:
        return 4;
    }
  }

  static Eisenhower fromDb(String? raw) {
    switch (raw) {
      case 'P1_DO':
        return Eisenhower.doNow;
      case 'P3_DELEGATE':
        return Eisenhower.delegate;
      case 'P4_ELIMINATE':
        return Eisenhower.eliminate;
      default:
        return Eisenhower.schedule;
    }
  }

  static Eisenhower fromRank(int priority) {
    switch (priority) {
      case 1:
        return Eisenhower.doNow;
      case 3:
        return Eisenhower.delegate;
      case 4:
        return Eisenhower.eliminate;
      default:
        return Eisenhower.schedule;
    }
  }
}

enum EnergyLevel { highFocus, medium, lowEnergy }

extension EnergyLevelX on EnergyLevel {
  String get dbValue {
    switch (this) {
      case EnergyLevel.highFocus:
        return 'high_focus';
      case EnergyLevel.medium:
        return 'medium';
      case EnergyLevel.lowEnergy:
        return 'low_energy';
    }
  }

  String get labelHe {
    switch (this) {
      case EnergyLevel.highFocus:
        return 'ריכוז גבוה';
      case EnergyLevel.medium:
        return 'בינוני';
      case EnergyLevel.lowEnergy:
        return 'אנרגיה נמוכה';
    }
  }

  static EnergyLevel fromDb(String? raw) {
    switch (raw) {
      case 'high_focus':
        return EnergyLevel.highFocus;
      case 'low_energy':
        return EnergyLevel.lowEnergy;
      default:
        return EnergyLevel.medium;
    }
  }
}

enum TasksWorkspaceView { inbox, today, matrix, calendar, review }
