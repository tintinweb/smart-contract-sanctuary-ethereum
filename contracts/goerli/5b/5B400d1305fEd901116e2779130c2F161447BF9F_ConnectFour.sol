// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract ConnectFour {
    /// @notice revert if caller isn't current team
    error NotYourTurn();
    /// @notice revert if column choice is invalid
    error InvalidSelection();
    /// @notice revert if game has been completed
    error GameOver();
    /// @notice revert season is over (coming soon)
    error SeasonOver();

    /// @notice emiited when game is created
    event GameCreated(uint8 gameId, address teamOne, address teamTwo);
    /// @notice emitted after turn is successfully taken
    event TurnTaken(address team, uint8 column);
    /// @notice emitted when game is complete
    event GameFinished(address winner, uint8 gameId);

    /// @notice holds game data
    /// @param teamOne address of challenger
    /// @param teamTwo address of challenged
    /// @param winner address of winning team; default: address(0)
    /// @param turn current turn is calculated using bitwise for basically odd/even teamOne/teamTwo
    /// @param board holds game board data; each 'square' holds current data; 0 = no chip; 1 = team one; 2 = team two
    struct Game {
        address teamOne;
        address teamTwo;
        address winner;
        uint8 turn;
        uint8[6][6] board;
    }

    /// @notice Used as a counter for the next game index.
    /// @dev Initialised at 1 because it makes the first transaction slightly cheaper.
    uint8 internal gameId = 1;

    /// @notice An indexed list of games
    /// @dev This automatically generates a getter for us, which will return `Game.player1`, `Game.player2`, `Game.moves`, and `Game.finished` (the arrays are skipped)
    mapping(uint8 => Game) public getGame;

    /// @notice prevent move if column is invalid
    modifier validColumn(uint8 column) {
        if (column >= 6) revert InvalidSelection();
        _;
    }

    /// @notice prevents gameplay if game is over
    modifier gameOver(uint8 _gameId) {
        if (getGame[_gameId].winner != address(0)) revert GameOver();
        _;
    }

    /// @notice prevents new games when season is over. (coming soon)
    modifier seasonOver() {
        _;
    }

    /// @notice prevents teams being the same address
    modifier uniqueTeams(address opponent) {
        require(msg.sender != opponent);
        _;
    }

    /**
     * @notice challenge an address to a game of connect four
     * @param opponent challened
     * @dev opponent will go first
     * @dev game id is increated each time a new game is created
     * @dev season is over when timer (soon to be added) is past
     */
    function challenge(
        address opponent
    ) public uniqueTeams(opponent) returns (uint8) {
        uint8[6][6] memory newBoard;
        Game memory newGame = Game({
            teamOne: msg.sender,
            teamTwo: opponent,
            turn: uint8(0),
            winner: address(0),
            board: newBoard
        });

        getGame[gameId] = newGame;

        emit GameCreated(gameId, msg.sender, opponent);

        return gameId++;
    }

    /**
     * @notice current team plays a turn
     * @param _gameId id of game
     * @param column selected column for move
     */
    function makeMove(
        uint8 _gameId,
        uint8 column
    ) external gameOver(_gameId) validColumn(column) {
        Game storage game = getGame[_gameId];

        /// @notice row where chip will land
        uint8 row;
        /// @notice assigned team number for squares
        uint8 teamNum = game.turn & 1 == 0 ? 2 : 1;

        /// @notice prevents plays being made by other addresses
        /// @dev even or odd bitwise operator decides turn
        /// @dev starts with team two
        if (msg.sender != (game.turn & 1 == 0 ? game.teamTwo : game.teamOne)) {
            revert NotYourTurn();
        }

        /// @notice finds where chip will land
        for (uint8 i = 0; i < 6; i++) {
            uint8 square = game.board[column][i];
            if (i == 5) {
                revert InvalidSelection();
            }
            if (square == 0) {
                row = i++;
                break;
            }
        }

        /// @notice assigns chip to location onboard
        game.board[column][row] = teamNum;
        /// @notice increments turn
        game.turn++;

        emit TurnTaken(msg.sender, column);

        /// @notice checks surrounding squares for connected pieces
        if (didPlayerWin(_gameId, column, row, teamNum)) {
            game.winner = msg.sender;
            emit GameFinished(msg.sender, _gameId);
        }
    }

    /// @notice checks square for team's chip
    /// @param board game board data
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkSquare(
        uint8[6][6] storage board,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (bool) {
        return board[column][row] == teamNum;
    }

    /// @notice checks the horizontal win
    /// @param board game board data
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkHorizonalWin(
        uint8[6][6] storage board,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint8) {
        uint8 connectedPiecesCount = 1;

        /// @dev checks to the right of new piece
        for (uint8 i = column + 1; i < 6 - column; i++) {
            if (checkSquare(board, i, row, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }
        /// @dev checks to the left of new piece
        if (column != 0) {
            uint8 columnIndex = column - 1;
            while (columnIndex >= 0) {
                if (checkSquare(board, columnIndex, row, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (columnIndex == 0) {
                    break;
                } else {
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the veritical win
    /// @param board game board data
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkVericalWin(
        uint8[6][6] storage board,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint8) {
        uint8 connectedPiecesCount = 1;

        /// @dev checks rows above new piece
        for (uint8 i = row + 1; i < 6 - row; i++) {
            if (checkSquare(board, column, i, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }
        /// @dev checks rows below new piece
        if (row != 0) {
            uint8 rowIndex = row - 1;
            while (rowIndex >= 0) {
                if (checkSquare(board, column, rowIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0) {
                    break;
                } else {
                    rowIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the forward angle win
    /// @param board game board data
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkForwardAngleWin(
        uint8[6][6] storage board,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint8) {
        uint8 connectedPiecesCount = 1;

        /// @dev checks forward angle up
        for (uint8 i = row + 1; i < 6 - row; i++) {
            if (checkSquare(board, i, i, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }

        /// @dev checks forward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row - 1;
            uint8 columnIndex = column - 1;
            while (rowIndex >= 0 || columnIndex >= 0) {
                if (checkSquare(board, columnIndex, rowIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0 || columnIndex == 0) {
                    break;
                } else {
                    rowIndex--;
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the backward angle win
    /// @param board game board data
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkBackwardAngleWin(
        uint8[6][6] storage board,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint8) {
        uint8 connectedPiecesCount = 1;

        /// @dev checks backward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row - 1;
            uint8 columnIndex = column + 1;
            while (rowIndex >= 0 || columnIndex < 7) {
                if (checkSquare(board, columnIndex, rowIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0 || columnIndex > 6) {
                    break;
                } else {
                    rowIndex--;
                    columnIndex++;
                }
            }
        }

        /// @dev checks forward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row + 1;
            uint8 columnIndex = column - 1;
            while (rowIndex < 7 || columnIndex >= 0) {
                if (checkSquare(board, columnIndex, rowIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex > 6 || columnIndex == 0) {
                    break;
                } else {
                    rowIndex++;
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks to see if current play won the game
    function didPlayerWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (bool) {
        uint8[6][6] storage board = getGame[_gameId].board;
        /// @dev using new chip location as middle == m
        /// @dev [ [ C+1 | R-1 ] [  C+1  ] [ C+1 | R+1 ] ]
        /// @dev [ [    R-1    ] [ C | R ] [    R+1    ]
        /// @dev [ [ C-1 | R-1 ] [  C-1  ] [ C-1 | R+1 ] ]

        uint8 horionalCount = checkHorizonalWin(board, column, row, teamNum);
        if (horionalCount == 4) {
            return true;
        }
        uint8 vericalCount = checkVericalWin(board, column, row, teamNum);
        if (vericalCount == 4) {
            return true;
        }
        uint8 forwardAngleCount = checkForwardAngleWin(
            board,
            column,
            row,
            teamNum
        );
        if (forwardAngleCount == 4) {
            return true;
        }
        uint8 backwardAngleCount = checkBackwardAngleWin(
            board,
            column,
            row,
            teamNum
        );
        if (backwardAngleCount == 4) {
            return true;
        }
        return false;
    }

    function getGameBoard(
        uint8 _gameId
    ) public view returns (uint8[6][6] memory) {
        return getGame[_gameId].board;
    }
}