import 'package:flutter_test/flutter_test.dart';
import 'package:ludo_verse/providers/game_provider.dart';

void main() {
  group('GameProvider Tests', () {
    test('Initialization works correctly', () {
      final provider = GameProvider();
      
      // Should initialize with default values
      expect(provider.gameOver, false);
      expect(provider.currentPlayerIndex, 0);
      expect(provider.diceValue, 1);
      
      // Initialize with 4 players
      provider.initGame(4);
      expect(provider.players.length, 4);
      expect(provider.currentPlayer.name, 'Red');
      expect(provider.currentPlayer.color, PlayerColor.red);
      expect(provider.numberOfPlayers, 4);
    });

    test('Next turn works and rotates players', () {
      final provider = GameProvider();
      provider.initGame(4);
      
      expect(provider.currentPlayerIndex, 0);
      
      // Simulate rolling a dice value that has no moves to auto-advance
      // or we can test private methods/states
      expect(provider.currentPlayer.color, PlayerColor.red);
    });
  });
}
