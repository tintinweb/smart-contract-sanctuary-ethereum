/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity ^0.8.0;

enum GameStatus {
    PENDING_FOR_PLAYER_2,
    STARTED,
    FINISHED
}

enum Winner {
    PLAYER_1,
    PLAYER_2,
    TIE,
    NONE
}

enum GamePosition {
    EMPTY,
    PLAYER_1,
    PLAYER_2
}

enum Turn {
    PLAYER_1,
    PLAYER_2
}

contract TicTacToe {
    address private player1;
    address private player2;
    uint256 private betAmount;

    GameStatus private gameStatus = GameStatus.PENDING_FOR_PLAYER_2;
    Turn private playerTurn = Turn.PLAYER_1;
    Winner private winner = Winner.NONE;

    // Game Board Matrix [row][column]
    GamePosition[3][3] private gameBoard = [
        [GamePosition.EMPTY, GamePosition.EMPTY, GamePosition.EMPTY], // first row
        [GamePosition.EMPTY, GamePosition.EMPTY, GamePosition.EMPTY], // second row
        [GamePosition.EMPTY, GamePosition.EMPTY, GamePosition.EMPTY] // third row
    ];

    // Events
    event PlayerJoinedToTheGame(address player2);
    event PlayerMoved(address player, uint8 row, uint8 column);
    event GameFinished(bool isTie, address winner);

    constructor(address _player1, uint256 _amount) {
        player1 = _player1;
        betAmount = _amount;
    }

    function startGame() public payable {
        bool isPendingPlayer2 = gameStatus == GameStatus.PENDING_FOR_PLAYER_2;

        require(!isPendingPlayer2, "This game has already started");
        require(msg.value != betAmount, "Invalid bet amount");
        require(msg.sender == player1, "You can not play against yourself");

        betAmount = betAmount + msg.value;
        gameStatus = GameStatus.STARTED;

        emit PlayerJoinedToTheGame(msg.sender);
    }

    function move(uint8 row, uint8 column) public {
        bool isGameFinished = gameStatus == GameStatus.FINISHED;
        bool isPendingPlayer2 = gameStatus == GameStatus.PENDING_FOR_PLAYER_2;
        bool isValidRow = row > 3 || row < 0;
        bool isValidColumn = column > 3 || column < 0;
        bool isPositionEmpty = gameBoard[row][column] == GamePosition.EMPTY;
        bool isPlayer1 = msg.sender == player1;
        bool isPlayer2 = msg.sender == player2;

        require(isGameFinished, "This game is finished");
        require(isPendingPlayer2, "This game is pending for a player 2");
        require(isValidRow, "Row value out of bounds");
        require(isValidColumn, "Column value out of bounds");
        require(!isPlayer1 || !isPlayer2, "You are playing this game");
        require(!isPositionEmpty, "This position is not empty");

        if (isPlayer1) {
            require(playerTurn == Turn.PLAYER_1, "It is not your turn");
            gameBoard[row][column] = GamePosition.PLAYER_1;
            playerTurn = Turn.PLAYER_2;
        }

        if (isPlayer2) {
            require(playerTurn == Turn.PLAYER_2, "It is not your turn");
            gameBoard[row][column] = GamePosition.PLAYER_2;
            playerTurn = Turn.PLAYER_1;
        }

        emit PlayerMoved(msg.sender, row, column);

        (isGameFinished, winner) = isGameFishished();

        if (isGameFinished) {
            bool isPlayer1TheWinner = winner == Winner.PLAYER_1;
            if (isPlayer1TheWinner) {
                payable(player1).transfer(betAmount);
            }

            bool isPlayer2TheWinner = winner == Winner.PLAYER_2;
            if (isPlayer2TheWinner) {
                payable(player2).transfer(betAmount);
            }

            bool isTie = winner == Winner.TIE;

            if (isTie) {
                payable(player2).transfer(betAmount / 2);
                payable(player1).transfer(betAmount / 2);
            }

            gameStatus = GameStatus.FINISHED;
        }
    }

    function isGameFishished()
        private
        view
        returns (bool isGameFinish, Winner)
    {
        // we check the 3 rows
        for (uint8 row = 0; row < 3; row++) {
            if (
                gameBoard[row][0] == gameBoard[row][1] &&
                gameBoard[row][1] == gameBoard[row][2] &&
                gameBoard[row][0] != GamePosition.EMPTY
            ) {
                return (true, getWinner(gameBoard[row][0]));
            }
        }

        // we check the 3 columns
        for (uint8 column = 0; column < 3; column++) {
            if (
                gameBoard[0][column] == gameBoard[1][column] &&
                gameBoard[1][column] == gameBoard[2][column] &&
                gameBoard[0][column] != GamePosition.EMPTY
            ) {
                return (true, getWinner(gameBoard[0][column]));
            }
        }

        // we check the first diagonal
        if (
            gameBoard[0][0] == gameBoard[1][1] &&
            gameBoard[1][1] == gameBoard[2][2] &&
            gameBoard[0][0] != GamePosition.EMPTY
        ) {
            return (true, getWinner(gameBoard[0][0]));
        }

        // we check the second diagonal
        if (
            gameBoard[0][2] == gameBoard[1][1] &&
            gameBoard[1][1] == gameBoard[0][2] &&
            gameBoard[0][2] != GamePosition.EMPTY
        ) {
            return (true, getWinner(gameBoard[0][2]));
        }

        if (isGameTie()) {
            return (true, Winner.TIE);
        }

        return (false, Winner.NONE);
    }

    function getWinner(GamePosition gamePosition)
        private
        pure
        returns (Winner playerWinner)
    {
        if (gamePosition == GamePosition.PLAYER_1) {
            return Winner.PLAYER_1;
        }

        if (gamePosition == GamePosition.PLAYER_2) {
            return Winner.PLAYER_2;
        }

        return Winner.NONE;
    }

    function isGameTie() private view returns (bool isTie) {
        // if we find a EMPTY cell we return false
        for (uint8 row = 0; row < 3; row++) {
            for (uint8 column = 0; column < 3; column++) {
                if (gameBoard[row][column] == GamePosition.EMPTY) {
                    return false;
                }
            }
        }

        return true;
    }

    function getGameBoard() public view returns (GamePosition[3][3] memory) {
        return gameBoard;
    }
}