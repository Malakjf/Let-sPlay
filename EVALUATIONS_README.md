# Evaluations - Role-based workflow

This implements a coach -> admin -> player evaluation workflow.

Key changes:
- New model: `lib/models/evaluation.dart`
- Firebase helpers added to `FirebaseService` for saving/listing and workflow actions
  - `saveEvaluation`, `getEvaluation`, `listEvaluationsForAdmin`, `listEvaluationsByCoach`, `listEvaluationsForPlayer`, `sendEvaluationToAdmin`, `approveAndSendToPlayer`, `rejectEvaluation`
- Pages added:
  - `lib/pages/CoachEvaluationEditor.dart` (coach UI: Save Draft, Send to Admin)
  - `lib/pages/AdminEvaluations.dart` (admin: "Sent By Coach" list, Approve/Reject)
  - `lib/pages/ViewMyPerformance.dart` (player: view-only list)

Quick test steps (local emulator or real project):
1. Start the app and sign in as a test coach account (role must be `Coach` in Firestore).
2. Navigate to `CoachEvaluationEditor` and create an evaluation. Use "Save Draft" and "Send to Admin".
3. Sign in as an Admin and open `AdminEvaluations` to review items under "Sent By Coach". Use Approve & Send or Reject.
4. Sign in as the evaluated player and open `ViewMyPerformance` to see final evaluations.

Notes & next steps:
- UI is intentionally minimal and intended as a scaffold; integrate into app navigation and style system as needed.
- Consider adding Firestore security rules to prevent unauthorized writes/reads.
- Add animations and status badges per design spec.

Contact: developer for further integration and polish.
