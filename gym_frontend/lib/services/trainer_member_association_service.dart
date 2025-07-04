import '../models/trainer_member_association.dart';
import 'api_service.dart';

class TrainerMemberAssociationService {
  final ApiService _apiService = ApiService();

  /// Get all active trainer-member associations
  Future<List<TrainerMemberAssociation>> getActiveAssociations() async {
    try {
      print('🔗 Fetching active trainer-member associations...');
      final data = await _apiService.getActiveTrainerMemberAssociations();
      final associations = data.map((json) => TrainerMemberAssociation.fromJson(json)).toList();
      print('✅ Fetched ${associations.length} active associations');
      return associations;
    } catch (e) {
      print('💥 Error fetching associations: $e');
      rethrow;
    }
  }

  /// Get associations for a specific trainer
  Future<List<TrainerMemberAssociation>> getAssociationsByTrainer(int trainerId) async {
    try {
      print('🔗 Fetching associations for trainer $trainerId...');
      final data = await _apiService.getTrainerMembers(trainerId);
      final associations = data.map((json) => TrainerMemberAssociation.fromJson(json)).toList();
      print('✅ Fetched ${associations.length} associations for trainer $trainerId');
      return associations;
    } catch (e) {
      print('💥 Error fetching trainer associations: $e');
      rethrow;
    }
  }

  /// Associate a member with a trainer
  Future<bool> associateMemberWithTrainerViaTrainerEndpoint(int trainerId, int memberId, {String? notes}) async {
    try {
      print('🔗 Associating member $memberId with trainer $trainerId...');
      return await _apiService.associateMemberWithTrainer(trainerId, memberId, notes: notes);
    } catch (e) {
      print('💥 Error associating member with trainer: $e');
      return false;
    }
  }

  /// Remove association using trainer endpoint
  Future<bool> unassociateMemberFromTrainerViaTrainerEndpoint(int trainerId, int memberId) async {
    try {
      print('🔗 Removing association between trainer $trainerId and member $memberId...');
      return await _apiService.unassociateMemberFromTrainer(trainerId, memberId);
    } catch (e) {
      print('💥 Error removing association: $e');
      return false;
    }
  }

  /// Get members associated with a trainer using trainer endpoint
  Future<List<TrainerMemberAssociation>> getTrainerMembers(int trainerId) async {
    try {
      print('🔗 Fetching members for trainer $trainerId via trainer endpoint...');
      final data = await _apiService.getTrainerMembers(trainerId);
      final associations = data.map((json) => TrainerMemberAssociation.fromJson(json)).toList();
      print('✅ Fetched ${associations.length} associated members for trainer $trainerId');
      return associations;
    } catch (e) {
      print('💥 Error fetching trainer members: $e');
      rethrow;
    }
  }
}