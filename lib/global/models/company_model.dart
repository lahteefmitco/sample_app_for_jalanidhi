/// The company a user works for, as returned inside `/users` items.
class CompanyModel {
  /// Creates a company; both fields are required.
  const CompanyModel({required this.name, required this.catchPhrase});

  /// Builds a [CompanyModel] from the API's JSON object.
  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      name: json['name'] as String,
      catchPhrase: json['catchPhrase'] as String,
    );
  }

  /// Company name.
  final String name;

  /// Company slogan.
  final String catchPhrase;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'catchPhrase': catchPhrase,
  };

  /// Readable description, handy in logs.
  @override
  String toString() => 'CompanyModel(name: $name, catchPhrase: $catchPhrase)';
}
