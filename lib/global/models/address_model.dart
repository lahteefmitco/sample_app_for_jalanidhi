/// Postal address of a user, as returned inside `/users` items.
class AddressModel {
  /// Creates an address; every part is required.
  const AddressModel({
    required this.street,
    required this.suite,
    required this.city,
    required this.zipcode,
  });

  /// Builds a [AddressModel] from the API's JSON object.
  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      street: json['street'] as String,
      suite: json['suite'] as String,
      city: json['city'] as String,
      zipcode: json['zipcode'] as String,
    );
  }

  /// Street name, e.g. `Kulas Light`.
  final String street;

  /// Apartment or suite, e.g. `Apt. 556`.
  final String suite;

  /// City name; the user list can be filtered by it.
  final String city;

  /// Postal code.
  final String zipcode;

  /// Single-line representation, e.g. `Kulas Light, Apt. 556, Gwenborough`.
  String get formatted => '$street, $suite, $city $zipcode';

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'street': street,
    'suite': suite,
    'city': city,
    'zipcode': zipcode,
  };

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'AddressModel(street: $street, suite: $suite, city: $city, '
      'zipcode: $zipcode)';
}
