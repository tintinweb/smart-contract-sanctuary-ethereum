/**
 *Submitted for verification at Etherscan.io on 2022-03-29
*/

pragma solidity ^0.8.7;

// TicTacToe is a solidity implementation of the tic tac toe game.
// You can find the rules at https://en.wikipedia.org/wiki/Tic-tac-toe
contract TicTacToe {

    // Players enumerates all possible players
    enum Players { None, PlayerOne, PlayerTwo }
    // Winners enumerates all possible winners
    enum Winners { None, PlayerOne, PlayerTwo, Draw }

    // Game stores the state of a round of tic tac toe.
    // As long as `winner` is `None`, the game is not over.
    // `playerTurn` defines who may go next.
    // Player one must make the first move.
    // The `board` has the size 3x3 and in each cell, a player
    // can be listed. Initializes as `None` player, as that is the
    // first element in the enumeration.
    // That means that players are free to fill in any cell at the
    // start of the game.
    struct Game {
        address playerOne;
        address playerTwo;
        Winners winner;
        Players playerTurn;
        Players[3][3] board;
    }

    // games stores all the games.
    // Games that are already over as well as games that are still running.
    // It is possible to iterate over all games, as the keys of the mapping
    // are known to be the integers from `1` to `nrOfGames`.
     mapping(uint256 => Game) private games;
    // nrOfGames stores the total number of games in this contract.
    uint256 private nrOfGames;

    // GameCreated signals that `creator` created a new game with this `gameId`.
    event GameCreated(uint256 gameId, address creator);
    // PlayerJoinedGame signals that `player` joined the game with the id `gameId`.
    // That player has the player number `playerNumber` in that game.
    event PlayerJoinedGame(uint256 gameId, address player, uint8 playerNumber);
    // PlayerMadeMove signals that `player` filled in the board of the game with
    // the id `gameId`. She did so at the coordinates `xCoordinate`, `yCoordinate`.
    event PlayerMadeMove(uint256 gameId, address player, uint xCoordinate, uint yCoordinate);
    // GameOver signals that the game with the id `gameId` is over.
    // The winner is indicated by `winner`. No more moves are allowed in this game.
    event GameOver(uint256 gameId, Winners winner);

    // newGame creates a new game and returns the new game's `gameId`.
    // The `gameId` is required in subsequent calls to identify the game.
    function newGame() public returns (uint256 gameId) {
        Game memory game;
        game.playerTurn = Players.PlayerOne;

        nrOfGames++;
        games[nrOfGames] = game;

        emit GameCreated(nrOfGames, msg.sender);

        return nrOfGames;
    }

    // joinGame lets the sender of the message join the game with the id `gameId`.
    // It returns `success = true` when joining the game was possible and
    // `false` otherwise.
    // `reason` indicates why a game was joined or not joined.
    function joinGame(uint256 _gameId) public {
        require(_gameId <= nrOfGames, "No such game exists.");

        address player = msg.sender;
        Game storage game = games[_gameId];

        require(game.playerOne == address(0) || game.playerTwo == address(0), "Game already started.");

        // Assign the new player to slot 1 if it is still available.
        if (game.playerOne == address(0)) {
            game.playerOne = player;
            emit PlayerJoinedGame(_gameId, player, uint8(Players.PlayerOne));
            return;
        }

        // If slot 1 is taken, assign the new player to slot 2 if it is still available.
        if (game.playerTwo == address(0)) {
            game.playerTwo = player;
            emit PlayerJoinedGame(_gameId, player, uint8(Players.PlayerTwo));
            return;
        }
    }

    // makeMove inserts a player on the game board.
    // The player is identified as the sender of the message.
    function makeMove(uint256 _gameId, uint _xCoordinate, uint _yCoordinate) public  {
        require(_gameId <= nrOfGames, "No such game exists.");

        Game storage game = games[_gameId];

        // Any winner other than `None` means that no more moves are allowed.
    
        require(game.winner == Winners.None, "The game has already ended.");

        // Only the player whose turn it is may make a move.
        require(msg.sender == getCurrentPlayer(game), "It is not your turn.");

        // Players can only make moves in cells on the board that have not been played before.
        require(game.board[_xCoordinate][_yCoordinate] == Players.None, "There is already a mark at the given coordinates.");

        // Now the move is recorded and the according event emitted.
        game.board[_xCoordinate][_yCoordinate] = game.playerTurn;
        emit PlayerMadeMove(_gameId, msg.sender, _xCoordinate, _yCoordinate);

        // Check if there is a winner now that we have a new move.
        Winners winner = calculateWinner(game.board);
        if (winner != Winners.None) {
            // If there is a winner (can be a `Draw`) it must be recorded in the game and
            // the corresponding event must be emitted.
            game.winner = winner;
            emit GameOver(_gameId, winner);

            return;
        }

        // A move was made and there is no winner yet.
        // The next player should make her move.
        nextPlayer(game);
    }

    // getCurrentPlayer returns the address of the player that should make the next move.
    // Returns the `0x0` address if it is no player's turn.
    function getCurrentPlayer(Game storage _game) private view returns (address player) {
        if (_game.playerTurn == Players.PlayerOne) {
            return _game.playerOne;
        }

        if (_game.playerTurn == Players.PlayerTwo) {
            return _game.playerTwo;
        }

        return address(0);
    }

    // calculateWinner returns the winner on the given board.
    // The returned winner can be `None` in which case there is no winner and no draw.
    function calculateWinner(Players[3][3] memory _board) private pure returns (Winners winner) {
        // First we check if there is a victory in a row.
        // If so, convert `Players` to `Winners`
        // Subsequently we do the same for columns and diagonals.
        Players player = winnerInRow(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        player = winnerInColumn(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        player = winnerInDiagonal(_board);
        if (player == Players.PlayerOne) {
            return Winners.PlayerOne;
        }
        if (player == Players.PlayerTwo) {
            return Winners.PlayerTwo;
        }

        // If there is no winner and no more space on the board,
        // then it is a draw.
        if (isBoardFull(_board)) {
            return Winners.Draw;
        }

        return Winners.None;
    }

    // winnerInRow returns the player that wins in any row.
    // To win in a row, all cells in the row must belong to the same player
    // and that player must not be the `None` player.
    function winnerInRow(Players[3][3] memory _board) private pure returns (Players winner) {
        for (uint8 x = 0; x < 3; x++) {
            if (
                _board[x][0] == _board[x][1]
                && _board[x][1]  == _board[x][2]
                && _board[x][0] != Players.None
            ) {
                return _board[x][0];
            }
        }

        return Players.None;
    }

    // winnerInColumn returns the player that wins in any column.
    // To win in a column, all cells in the column must belong to the same player
    // and that player must not be the `None` player.
    function winnerInColumn(Players[3][3] memory _board) private pure returns (Players winner) {
        for (uint8 y = 0; y < 3; y++) {
            if (
                _board[0][y] == _board[1][y]
                && _board[1][y] == _board[2][y]
                && _board[0][y] != Players.None
            ) {
                return _board[0][y];
            }
        }

        return Players.None;
    }

    // winnerInDiagoral returns the player that wins in any diagonal.
    // To win in a diagonal, all cells in the diaggonal must belong to the same player
    // and that player must not be the `None` player.
    function winnerInDiagonal(Players[3][3] memory _board) private pure returns (Players winner) {
        if (
            _board[0][0] == _board[1][1]
            && _board[1][1] == _board[2][2]
            && _board[0][0] != Players.None
        ) {
            return _board[0][0];
        }

        if (
            _board[0][2] == _board[1][1]
            && _board[1][1] == _board[2][0]
            && _board[0][2] != Players.None
        ) {
            return _board[0][2];
        }

        return Players.None;
    }

    // isBoardFull returns true if all cells of the board belong to a player other
    // than `None`.
    function isBoardFull(Players[3][3] memory _board) private pure returns (bool isFull) {
        for (uint8 x = 0; x < 3; x++) {
            for (uint8 y = 0; y < 3; y++) {
                if (_board[x][y] == Players.None) {
                    return false;
                }
            }
        }

        return true;
    }

    // nextPlayer changes whose turn it is for the given `_game`.
    function nextPlayer(Game storage _game) private {
        if (_game.playerTurn == Players.PlayerOne) {
            _game.playerTurn = Players.PlayerTwo;
        } else {
            _game.playerTurn = Players.PlayerOne;
        }
    }
}