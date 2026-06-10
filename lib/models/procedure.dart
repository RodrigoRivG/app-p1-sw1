class Procedure {
  final String id;
  final String clientName;
  final String clientEmail;
  final String status;
  final String createdAt;
  final String currentNodeId;
  final String policyId;

  const Procedure({
    required this.id,
    required this.clientName,
    required this.clientEmail,
    required this.status,
    required this.createdAt,
    required this.currentNodeId,
    required this.policyId,
  });

  factory Procedure.fromJson(Map<String, dynamic> json) {
    return Procedure(
      id: json['id'] as String? ?? '',
      clientName: json['clientName'] as String? ?? 'Sin nombre',
      clientEmail: json['clientEmail'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      createdAt: json['createdAt'] as String? ?? '',
      currentNodeId: json['currentNodeId'] as String? ?? '',
      policyId: json['policyId'] as String? ?? '',
    );
  }
}
