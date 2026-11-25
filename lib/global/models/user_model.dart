import 'package:sample_app_for_jalanidhi/global/models/address_model.dart';
import 'package:sample_app_for_jalanidhi/global/models/company_model.dart';

/// A user from `/users`, with nested address and company.
class UserModel {
  /// Creates a user; every field is required.
  const UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.phone,
    required this.website,
    required this.address,
    required this.company,
  });

  /// Builds a [UserModel] from the API's JSON object.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      website: json['website'] as String,
      address: AddressModel.fromJson(json['address'] as Map<String, dynamic>),
      company: CompanyModel.fromJson(json['company'] as Map<String, dynamic>),
    );
  }

  /// Unique user id.
  final int id;

  /// Full name, e.g. `Leanne Graham`.
  final String name;

  /// Short login-style name, e.g. `Bret`.
  final String username;

  /// Contact email.
  final String email;

  /// Contact phone number (free text).
  final String phone;

  /// Personal website, without `https://`.
  final String website;

  /// Postal address.
  final AddressModel address;

  /// Employer.
  final CompanyModel company;

  /// Converts the model back to JSON (e.g. to send it to the API).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'username': username,
    'email': email,
    'phone': phone,
    'website': website,
    'address': address.toJson(),
    'company': company.toJson(),
  };

  /// Readable description, handy in logs.
  @override
  String toString() =>
      'UserModel(id: $id, name: $name, username: $username, email: $email, '
      'address: $address, company: $company)';
}
