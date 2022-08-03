//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

// import "hardhat/console.sol";

/// @title ConnectFour
/// @author Bloomtech
/// @notice Allows any two players to place a 50-50 bet on who will win a game of Connect Four.
/// @notice For info on the rules of Connect Four, see https://en.wikipedia.org/wiki/Connect_Four
/// @dev See the {Game} struct for details on how the board is represented
contract ConnectFour {
    /// @dev represents a single disc in the Connect Four board
    enum Disc { Empty, Player1, Player2 }

    /// @dev status of an individual Game
    enum Status { NonExistent, Initialized, Started, BetWithdrawn }

    /// @dev indicates the direction to check the winning line of 4 discs
    enum WinningDirection { LeftDiagonal, Up, RightDiagonal, Right }

    /// @notice struct to represent a Connect Four game between 2 opponents. Each opponent
    /// enters the game by sending the betAmount, so that each game will have a pool of 2 * betAmount
    /// @dev player1 is the address who called ConnectFour.initializeGame, and player2
    /// is the player that called ConnectFour.startGame
    /// @dev each board is comprised of 7 columns, 6 rows, and starts out with each Cell initialized
    /// to Cell.Empty. The board is a single array, and to get the correct disc given a column and row
    /// ID (which are 0-indexed), see ConnectFour.boardIndex. We represent a position in the board as a tuple of
    /// (column, row). The disc (0, 0) is in the bottom left of the board and the disc in the top left of
    /// the board has the coordinates (0, 5) and exists at index 35 in the board array
    ///
    /// See this ASCII grid below for the board and the indexes of different slots
    ///
    /// -------------------------
    /// |/35/  /  /  /  /  /41/|
    /// |/  /  /  /  /  /  /  /|
    /// |/  /  /  /  /  /  /  /|
    /// |/  /  /  /  /  /  /  /|
    /// |/  /  /  /  /  /  /  /|
    /// |/0 /  /  /  /  /  /6 /|
    /// -------------------------

    struct Game {
        address player1;    // address of the player that first initialized the game and chose the betAmount
        address player2;    // address of the player that started the previously initialized game
        Disc[42] board;     // array representing the state of board's discs in a 7 column 6 row grid, at first all are empty
        uint256 betAmount;  // number of wei each player bets on the game; the winner will receive 2 * betAmount
        Status status;      // various states that denote the lifecycle of a game
        bool isPlayer1Turn; // true if it is player 1's turn, false if it is player 2's turn. Initially it is player 1's turn
    }

    event GameInitialized(
        uint256 gameId,
        address player1,
        uint256 betAmount
    );

    event GameStarted(
        uint256 gameId,
        address player2
    );

    event RewardClaimed(
        uint256 gameId,
        address winner,
        address recipient,
        uint256 rewardAmount
    );

    event BoardUpdated(
        uint256 gameId,
        uint8 player,
        uint256 idx
    );

    /// @notice stores the Game structs for each game, identified by each uint256 game ID
    mapping(uint256 => Game) public games;

    /// @notice the minimum amount of wei that can be bet in a game. Setting a higher value (e.g. 1 ETH) indicates
    /// this is a contract meant for whales only. Set this lower if you want everyone to participate
    uint256 public minBetAmount;

    /// @notice the maximum amount of wei that can be bet in a game. Set this to ensure people don't lose their shirts :D
    uint256 public maxBetAmount;

    /// @dev A monotonically incrementing counter used for new Game IDs. Starts out at 0, and increments by 1 with every new Game
    uint256 internal gameIdCounter = 0;

    /// @dev Validates that gameId exists and the game is in the expected state
    modifier IsValidGame(uint256 _gameId, Status _expectedStatus) {
        require(_gameId < gameIdCounter, "Invalid game id");
        require(games[_gameId].status == _expectedStatus, "Unexpected game status");
        _;
    }

    /// @dev Validates that player is registered participant of this game and that it is their turn to play
    modifier IsValidPlayer(uint256 _gameId, address _player) {
        require(_player == games[_gameId].player1 || _player == games[_gameId].player2, "Invalid player");
        if(
            (_player == games[_gameId].player1 && !games[_gameId].isPlayer1Turn) ||
            (_player == games[_gameId].player2 && games[_gameId].isPlayer1Turn)
        ) {
            revert("Not your turn");
        }
        _;
    }

    /// @notice Set the minimum and maximum amounts that can be bet on any Games created through
    /// this contract
    /// @dev Increase _minBetAmount if you want to attract degenerates, lower _maxBetAmount to keep them away
    /// @param _minBetAmount the lowest amount a player will be able to bet
    /// @param _maxBetAmount the largest amount a player will be able to bet
    constructor(uint256 _minBetAmount, uint256 _maxBetAmount) {
        minBetAmount = _minBetAmount;
        maxBetAmount = _maxBetAmount;
    }

    /// @notice Create a Game that can be started by any other address. To start a game the caller
    /// must send an ETH amount between the min and max bet amounts
    /// @notice Each game is for a 50/50 bet, so when the caller of this functions sends, say, 1 ETH,
    /// the opponent must send in the same amount of ETH in ConnectFour.startGame
    /// @dev the returned gameId is a monotonically increasing ID used to interact with this new Game
    /// @return a game ID, which can be used by each player to interact with the new Game
    function initializeGame() external payable returns (uint256) {
        require(gameIdCounter < type(uint256).max, "No more games can be played");
        require(msg.value >= minBetAmount, "Raise to minBetAmount");
        require(msg.value <= maxBetAmount, "Lower to maxBetAmount");

        uint256 gameId = gameIdCounter++;
        Game storage newGame = games[gameId];
        newGame.player1 = msg.sender;
        newGame.betAmount = msg.value;
        newGame.isPlayer1Turn = true;
        newGame.status = Status.Initialized;

        emit GameInitialized(gameId, msg.sender, msg.value);
        return gameId;
    }

    /// @notice Start a game that has already been initialized by player1. The caller of this function (player2)
    /// must send in the same amount of ETH as player1 sent in. Afterwards the Game has started, and players
    /// may call ConnectFour.playMove to place their discs
    /// @param _gameId the game's ID, returned when player1 called ConnectFour.initializeGame
    function startGame(uint256 _gameId) external payable IsValidGame(_gameId, Status.Initialized) {
        require(msg.sender != games[_gameId].player1, "Cannot play against yourself");
        require(games[_gameId].betAmount == msg.value, "Must match bet");

        games[_gameId].player2 = msg.sender;
        games[_gameId].status = Status.Started;

        emit GameStarted(_gameId, msg.sender);
    }

    /// @notice Place a disc in the given column with the given Game. player1 and player2 will take
    /// turns placing one of their discs in a column, where it will fall until it stays in the bottom-most
    /// slot or onto the bottom-most previously-placed disc. For more info on how to play Connect Four, see
    /// the wikipedia page https://en.wikipedia.org/wiki/Connect_Four
    /// @dev illegal moves will cause the transaction to revert, such as placing a disc out of bounds of the 7x6
    /// board, trying to place a disc in a column which is already full, or going out of turn
    /// @param _gameId the game's ID, returned when player1 called ConnectFour.initializeGame
    /// @param _col the index of the column to place a disc in, valid values are 0 through 6 inclusive
    function playMove(uint256 _gameId, uint256 _col)
        external
        IsValidGame(_gameId, Status.Started)
        IsValidPlayer(_gameId, msg.sender)
    {
        uint256 index = boardIndex(_col, 0);
        Disc[42] storage board = games[_gameId].board;
        require(board[index + 35] == Disc.Empty, "Column full");
        
        while (index < 42) {
            if (board[index] == Disc.Empty) {
                board[index] = (games[_gameId].isPlayer1Turn) ? Disc.Player1 : Disc.Player2;
                emit BoardUpdated(_gameId, games[_gameId].isPlayer1Turn ? 1 : 2, index);
                games[_gameId].isPlayer1Turn = !games[_gameId].isPlayer1Turn;
                return;
            }
            index += 7;
        }
    }

    /// @notice Withdraws the bet amounts of both players to the recipient for the given game when there exists
    /// a winning four-in-a-row of the caller's discs. The caller specifies the four-in-a-row by providing
    /// starting column and row coordinates, as well as a direction in which to look for the 4 winning discs
    /// @dev As an example, imagine there is a winning four-in-a-row at coordinates (0,0), (0,1), (0,2), (0,3).
    /// Then the following function arguments will correctly claim the reward:
    /// _startingWinDiscCol = 0, _startingWinDiscRow = 0, _direction = Up
    /// @dev Note: there exists a vulnerability in this contract that we will exploit in a later Sprint :D
    /// @param _gameId the game's ID, returned when player1 called ConnectFour.initializeGame
    /// @param _recipient the address who will receive the bet's reward ETH
    /// @param _startingWinDiscCol the column index of one of the two end chips of the four-in-a-row
    /// @param _startingWinDiscRow the row index of one of the two end chips of the four-in-a-row
    /// @param _direction one of 4 possible directions in which to move when verifying the four-in-a-row
    function claimReward(
        uint256 _gameId,
        address payable _recipient,
        uint256 _startingWinDiscCol,
        uint256 _startingWinDiscRow,
        WinningDirection _direction
    ) 
        external
        IsValidGame(_gameId, Status.Started)
    {
        uint256 index = boardIndex(_startingWinDiscCol, _startingWinDiscRow);
        Game memory game = games[_gameId];
        Disc disc = game.board[index];

        if(
            (disc == Disc.Empty) ||
            (disc == Disc.Player1 && msg.sender != game.player1) ||
            (disc == Disc.Player2 && msg.sender != game.player2)
        ) {
            revert("Not caller's disc");
        }

        uint256 indexDelta;
        if(_direction == WinningDirection.LeftDiagonal) {
            require(_startingWinDiscCol >= 3 && _startingWinDiscRow <= 2, "Out of bounds");
            indexDelta = 6;
        } else if (_direction == WinningDirection.Up) {
            require(_startingWinDiscRow <= 2, "Out of bounds");
            indexDelta = 7;
        } else if (_direction == WinningDirection.RightDiagonal) {
            require(_startingWinDiscCol <= 3 && _startingWinDiscRow <= 2, "Out of bounds");
            indexDelta = 8;
        } else if (_direction == WinningDirection.Right) {
            require(_startingWinDiscCol <= 3, "Out of bounds");
            indexDelta = 1;
        } else {
            revert("Invalid direction");
        }

        for(uint8 i = 0; i < 3; i++) {
            index += indexDelta;
            require(index < 42, "Out of bounds");  // maybe remove: shouldn't be possible at this point
            require(game.board[index] == disc, "Not a win");
        }

        game.status = Status.BetWithdrawn;
        (bool sent,) = _recipient.call{value: game.betAmount * 2}("");  // check into limiting the amount of gas that can be used
        require(sent, "Tranasction Failed");
        emit RewardClaimed(_gameId, msg.sender, _recipient, game.betAmount * 2);
    }


    /// @notice Return the index of a disc in the board, given its column and row index (0-indexed)
    /// @dev this function will throw if the column or row are out of bounds
    /// @param _col the index of the column, valid values are 0 through 6 inclusive
    /// @param _row the index of the row, valid values are 0 through 5 inclusive
    /// @return the index of the board corresponding to these coordinates
    function boardIndex(uint256 _col, uint256 _row) public pure returns (uint256) {
        require(_col < 7 , "Max _col: 6");
        require(_row < 6, "Max _row: 5");

        return (_row * 7) + _col;
    }
}