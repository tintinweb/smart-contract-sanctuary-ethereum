/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/// @title Connect Four
/// @author Miguel Piedrafita
/// @notice An optimised connect four game implementation on Solidity
contract ConnectFour {
	/// ERRORS ///

	/// @notice Thrown when trying to make an invalid move
	error InvalidMove();

	/// @notice Thrown when trying to make a move during someone else's turn
	error Unauthorized();

	/// @notice Thrown when trying to make a move after the game has ended
	error GameFinished();

	/// EVENTS ///

	/// @notice Emited when a new game is created
	/// @param challenger The address that created the game
	/// @param challenged The address proposed as a rival, and that should make the first move
	event GameProposed(address indexed challenger, address indexed challenged);

	/// @notice Emitted when a move is made
	/// @param mover The address that performed the move
	/// @param gameId The ID of the game in play
	/// @param row The row the user dropped its piece in
	event MovePerformed(address indexed mover, uint256 gameId, uint8 row);

	/// @notice Emitted when a game is won
	/// @param winner The address that won the game
	/// @param gameId The ID of the game that was won
	event GameWon(address indexed winner, uint256 gameId);

	/// @dev Parameters for games
	/// @param player1 The address of the first player
	/// @param player2 The address of the second player
	/// @param height A helper, used to track which position to assign to pieces for each row
	/// @param board Two bitboards (one for each player), each representing a 7x6 board with an extra column at the top to check for invalid moves.
	/// @param moves A counter of the amount of moves so far
	/// @param finished Wether the game has been won
	struct Game {
		address player1;
		address player2;
		uint64[7] height;
		uint64[2] board;
		uint8 moves;
		bool finished;
	}

	/// @notice The initial value of `Game.height`, representing the indexes of the bottom column of the 7x6(+1) board
	/// @dev Solidity doesn't support array immutable variables or constants yet, so we're forced to compute this at runtime (see constructor).
	uint64[7] internal initialHeight;

	/// @notice The indexes of the helper top column of the 7x6(+1) board
	uint64 internal constant topColumn = 283691315109952;

	/// @notice Used as a counter for the next game index.
	/// @dev Initialised at 1 because it makes the first transaction slightly cheaper.
	uint256 internal gameId = 1;

	/// @notice An indexed list of games
	/// @dev This automatically generates a getter for us, which will return `Game.player1`, `Game.player2`, `Game.moves`, and `Game.finished` (the arrays are skipped)
	mapping(uint256 => Game) public getGame;

	/// @notice Deploys a ConnectFour instance
	/// @dev Used to compute the value of `initialHeight`, since we cannot make it a constant (or immutable).
	constructor() payable {
		unchecked {
			for (uint8 i = 0; i < 7; i++) {
				initialHeight[i] = uint64(7 * i);
			}
		}
	}

	/// @notice Challenge another address to a game of connect four
	/// @param opponent The address you want to play against
	/// @return The ID of the newly-created game
	function challenge(address opponent) public payable returns (uint256) {
		Game memory game = Game({
			player1: opponent,
			player2: msg.sender,
			height: initialHeight,
			board: [uint64(0), uint64(0)],
			moves: 0,
			finished: false
		});

		emit GameProposed(msg.sender, opponent);

		getGame[gameId] = game;

		return gameId++;
	}

	/// @notice Perform a move on an active game
	/// @param gameId The ID of the game you want to perform your move on
	/// @param row The row on where you want to drop your piece
	function makeMove(uint256 gameId, uint8 row) public payable {
		Game storage game = getGame[gameId];
		if (msg.sender != (game.moves & 1 == 0 ? game.player1 : game.player2)) revert Unauthorized();
		if (game.finished) revert GameFinished();

		emit MovePerformed(msg.sender, gameId, row);

		game.board[game.moves & 1] ^= uint64(1) << game.height[row]++;

		if ((game.board[game.moves & 1] & topColumn) != 0) revert InvalidMove();

		if (didPlayerWin(gameId, game.moves++ & 1)) {
			game.finished = true;
			emit GameWon(msg.sender, gameId);
		}
	}

	/// @notice Check wether one of the players for a certain game has won the match
	/// @param gameId The ID for the game you want to perform the check on
	/// @param side Which side of the board you want to check (0 or 1).
	function didPlayerWin(uint256 gameId, uint8 side) public view returns (bool) {
		uint64 board = getGame[gameId].board[side];
		uint8[4] memory directions = [1, 7, 6, 8];

		uint64 bb;

		unchecked {
			for (uint8 i = 0; i < 4; i++) {
				bb = board & (board >> directions[i]);
				if ((bb & (bb >> (2 * directions[i]))) != 0) return true;
			}
		}

		return false;
	}

	function getBoards(uint256 gameId) public view returns (uint64, uint64) {
		uint64[2] memory boards = getGame[gameId].board;

		return (boards[0], boards[1]);
	}
}