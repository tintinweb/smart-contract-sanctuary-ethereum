// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/// @title TicTacToe contract
/// @author Dampilov D.

contract TicTacToe {
    uint gameId;

    mapping(uint => Game) public games;

    /// @notice Sign for gamer, cross or zero
    mapping(address => mapping(uint => SquareState)) public sign;

    enum GameState {
        free,
        playing,
        finished
    }

    /// @dev Conditions for cells
    enum SquareState {
        free,
        cross,
        zero,
        draw
    }

    /// @dev isCrossMove - switch to determine the current move
    /// @dev winner - sign of the winner, or draw if ended in a draw
    struct Game {
        uint id;
        address owner;
        GameState state;
        SquareState[3][3] cell;
        bool isCrossMove;
        SquareState winner;
        address rival;
        uint waitingTime;
        uint lastActiveTime;
    }

    event GameCreated(uint indexed _gameId, address indexed owner, uint indexed waitingTime, uint createdTime);
    event JoinedToGame(uint indexed _gameId, address indexed joined, SquareState joinedSign, uint indexed timeOfJoin);
    event MoveMade(uint indexed _gameId, address indexed whoMoved, uint x, uint y, uint indexed timeOfMove);
    event GameResult(uint indexed _gameId, SquareState indexed winner,address indexed winnerAddress, uint finishedTime);
    
    /// @dev Game should be free
    modifier GameIsFree(uint _roomId) {
        require(games[_roomId].state == GameState.free, "Not free game");
        _;
    }

    /// @dev Already playing the game
    modifier GameIsStarted(uint _roomId) {
        require(games[_roomId].state == GameState.playing, "Don't being played");
        _;
    }

    /// @notice Create new game
    /// @param _days, _hours, _minutes - move waiting time
    function createGame(uint64 _days, uint64 _hours, uint64 _minutes) external {
        SquareState[3][3] memory tictac;
        games[gameId] = Game(
            gameId,
            msg.sender, 
            GameState.free, 
            tictac,
            true, 
            SquareState.free, 
            address(0), 
            (_days * 1 days) + (_hours * 1 hours) + (_minutes * 1 minutes),
            block.timestamp
        );
        emit GameCreated(gameId, msg.sender, games[gameId].waitingTime, block.timestamp);
        gameId++;
    }

    /// @notice Join free play
    function joinGame(uint _gameId) external GameIsFree(_gameId) {
        require(_gameId < gameId, "That game not exist");
        require(msg.sender != games[_gameId].owner, "Can't play with yourself");
        games[_gameId].rival = msg.sender;

        /// @dev Randomly determined sign for players
        if (rand(block.timestamp, blockhash(block.number))) {
            sign[msg.sender][_gameId] = SquareState.cross;
            sign[games[_gameId].owner][_gameId] = SquareState.zero;
        } else {
            sign[msg.sender][_gameId] = SquareState.zero;
            sign[games[_gameId].owner][_gameId] = SquareState.cross;
        }
        games[_gameId].state = GameState.playing;
        games[_gameId].lastActiveTime = block.timestamp;
        emit JoinedToGame(_gameId, msg.sender, sign[msg.sender][_gameId], block.timestamp);
    }

    /// @notice Make a move
    /// @param _x, _y - coordinates where you want to put your sign
    function step(uint _gameId, uint _x, uint _y) external GameIsStarted(_gameId) {
        require(msg.sender == games[_gameId].owner || msg.sender == games[_gameId].rival, "Not your game");
        require(block.timestamp <= games[_gameId].waitingTime + games[_gameId].lastActiveTime, "Move time over");
        require(games[_gameId].cell[_x][_y] == SquareState.free, "Square not free");
        require(_x < 3 && _y < 3, "Not correct position");
        require(games[_gameId].isCrossMove && sign[msg.sender][_gameId] == SquareState.cross ||
                !games[_gameId].isCrossMove && sign[msg.sender][_gameId] == SquareState.zero, "Not your move");

        games[_gameId].cell[_x][_y] = sign[msg.sender][_gameId];
        games[_gameId].isCrossMove = !games[_gameId].isCrossMove;
        games[_gameId].lastActiveTime = block.timestamp;
        emit MoveMade(_gameId, msg.sender, _x, _y, block.timestamp);
        SquareState gameWinner = checkEndGame(games[_gameId], sign[msg.sender][_gameId], _x, _y);
        /// @dev If game is over
        if (gameWinner != SquareState.free) {
            games[_gameId].state = GameState.finished;
            games[_gameId].winner = gameWinner;
            emit GameResult(
                _gameId, 
                gameWinner, 
                gameWinner == SquareState.draw ? address(0) : msg.sender, 
                block.timestamp
            );
        }
    }

    /// @notice Checking if the turn time has expired
    /// @dev If the time is up then the game is over
    function checkGameTime(uint _gameId) external {
        if (block.timestamp > games[_gameId].waitingTime + games[_gameId].lastActiveTime) {
            games[_gameId].state = GameState.finished;
            if (games[_gameId].isCrossMove) {
                /// @dev Zero won
                games[_gameId].winner = SquareState.zero;
                if (sign[games[_gameId].owner][_gameId] == SquareState.cross)
                    emit GameResult(_gameId, SquareState.zero, games[_gameId].rival, block.timestamp);
                else
                    emit GameResult(_gameId, SquareState.zero, games[_gameId].owner, block.timestamp);
            } else {
                /// @dev Cross won
                games[_gameId].winner = SquareState.cross;
                if (sign[games[_gameId].owner][_gameId] == SquareState.cross)
                    emit GameResult(_gameId, SquareState.cross, games[_gameId].owner, block.timestamp);
                else
                    emit GameResult(_gameId, SquareState.cross, games[_gameId].rival, block.timestamp);
            }
        }
    }

    /// @return freeGamesList - List of free games
    function freeGames() external view returns (Game[] memory freeGamesList) {
        /// @dev Number of free games
        (uint gameCount,) = getGamesByFilter(GameState.free, SquareState.free, address(0));
        freeGamesList = new Game[](gameCount);
        uint counter;
        for(uint i; i < gameId; i++) {
            if (games[i].state == GameState.free) {
                freeGamesList[counter] = games[i];  
                counter++;
            }
        }
    }

    /// @return Percentage of games ending in a draw
    function getDrawGameStatistic() external view returns (uint) {
        /// @dev Numbers of finished and ending in a draw games
        (uint gameCount, uint signCount) = getGamesByFilter(GameState.finished, SquareState.draw, address(0));
        return gameCount > 0
            ? (signCount * 100) / gameCount
            : 0;
    }

    /// @return Percentage of games where the cross wins
    function getCrossGameStatistic() external view returns (uint) {
        /// @dev Numbers of finished and the cross wins games
        (uint gameCount, uint signCount) = getGamesByFilter(GameState.finished, SquareState.cross, address(0));
        return gameCount > 0
            ? (signCount * 100) / gameCount
            : 0;
    }

    /// @return Percentage of games where the zero wins
    function getZeroGameStatistic() external view returns (uint) {
        /// @dev Numbers of finished and the zero wins games
        (uint gameCount, uint signCount) = getGamesByFilter(GameState.finished, SquareState.zero, address(0));
        return gameCount > 0
            ? (signCount * 100) / gameCount
            : 0;
    }

    /// @param _gamer - address of player
    /// @return Percentage of games where the player wins
    function getStatisticByAddress(address _gamer) external view returns (uint) {
        /// @dev Numbers of finished and the player wins games
        (uint gameCount, uint signCount) = getGamesByFilter(GameState.finished, SquareState.free, _gamer);
        return gameCount > 0
            ? (signCount * 100) / gameCount
            : 0;
    }

    /// @return cell - game board, three by three matrix
    function getCell(uint _gameId) external view returns (uint8[3][3] memory cell) {
        for (uint i; i < 3; i++) {
            for(uint j; j < 3; j++) {
                if (games[_gameId].cell[i][j] == SquareState.free)
                    cell[i][j] = 0;
                if (games[_gameId].cell[i][j] == SquareState.cross)
                    cell[i][j] = 1;
                if (games[_gameId].cell[i][j] == SquareState.zero)
                    cell[i][j] = 2;
            }
        }
    }

    /// @dev Get number of all games and number of games where the corresponding sign won
    function getGamesByFilter(GameState _state, SquareState _sign, address _gamer) internal view returns (uint gameCount, uint signCount) {
        for(uint i; i < gameId; i++) {
            if (games[i].state == _state) {
                gameCount++;
                if (games[i].winner == _sign || games[i].winner == sign[_gamer][i])
                    signCount++;
            }
        }
    }

    /// @dev Checking if the game is over
    /// @param _x, _y - coordinates where you want to put your sign
    /**
     @return If game is not over, return SquareState.free.
     If someone won, return his sign.
     If game over in draw, return SquareState.draw
     */
    function checkEndGame(Game memory game, SquareState _sign, uint _x, uint _y) internal pure returns (SquareState) {
        bool[5] memory line;
        line[0] = true;
        line[1] = true;
        line[4] = true;
        /// @dev If lies on one of the diagonals, then you can check
        if ((_x+_y) % 2 == 0) {
            line[2] = true;
            line[3] = true;
        }

        for (uint i; i < 3 && (line[0] || line[1] || line[2] || line[3] || line[4]); i++) {
            /// @dev Vertical and horizontal check
            if (game.cell[_x][i] != _sign) {
                line[0] = false;
            }
            if (game.cell[i][_y] != _sign) {
                line[1] = false;
            }
            /// @dev Diagonals check
            if ((_x+_y) % 2 == 0) {
                if (game.cell[i][i] != _sign) {
                    line[2] = false;
                }

                if (game.cell[i][2 - i] != _sign) {
                    line[3] = false;
                }
            }
            /// @dev Checking for a draw
            for (uint j; j < 3 && line[4]; j++) {
                if (game.cell[i][j] == SquareState.free)
                    line[4] = false;
            }
        }
        if (line[0] || line[1] || line[2] || line[3])
            return _sign;
        if (line[4])
            return SquareState.draw;
        return SquareState.free;
    }

    /// @param factor1 - block.timestamp
    /// @param factor2 - block hash
    /// @return Bool which determines which sign the players will get
    function rand(uint factor1, bytes32 factor2) internal pure returns (bool) {
        uint random = uint(keccak256(abi.encodePacked(factor1, factor2)));
        return random % 2 == 0
            ? true
            : false;
    }
}