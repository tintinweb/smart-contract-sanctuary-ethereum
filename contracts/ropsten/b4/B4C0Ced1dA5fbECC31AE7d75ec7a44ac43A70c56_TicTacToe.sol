// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

/// @title Tic-Tac-Toe game
/// @author Starostin Dmitry
/// @notice Creation of a game party. Join the game party. Making a move. Checking combinations. Waiting time for a move player.
/// @dev Contract under testing
contract TicTacToe {
    enum State {
        FindPlayers, // Searching players
        EndFirst, // Move of the first player
        EndSecond, // Move of the second player
        Pause, // приостановка поиска игроков
        Draw, //
        WinFirst, // Win of the first player
        WinSecond // Win of the second player
    }

    struct Game {
        address player1; // master
        address player2; // slave
        uint8[9] grid; // Playing field
        uint256 timeStart; // Ending time of the move
        uint32 timeWait; // Waiting time of the move
        State state; // Game status
    }

    Game[] public games; // Games list
    uint8[3][8] private winCombinations = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [6, 4, 2]]; // All of the winning combinations
    mapping(address => uint256) playerGamesCount; // (player address => number of game)

    event CreateGame(uint256 indexed _IdGame, address indexed _player1, uint32 indexed _timeWait);
    event PauseGame(uint256 indexed _IdGame, State indexed _stateGame);
    event JoinGame(uint256 indexed _idGame, address indexed _player2);
    event MovePlayer(uint256 indexed _idGame, address indexed _player, uint256 _cell);
    event IsFinish(uint256 indexed _idGame, State indexed _stateGame);

    // Existence of the game
    modifier outOfRange(uint256 _idGame) {
        require(_idGame >= 0 && games.length > _idGame, "This game is not exist");
        _;
    }

    /// @notice Create a new game
    /// @param _timeWait Waiting time of the opponent's move
    function createGame(uint32 _timeWait) external {
        require(_timeWait > 0, "TimeWait must be more 0");
        games.push(Game({player1: msg.sender, player2: address(0), grid: [0, 0, 0, 0, 0, 0, 0, 0, 0], timeStart: 0, timeWait: _timeWait, state: State.FindPlayers})); // Add a new game to the list
        playerGamesCount[msg.sender]++; // Increasing number of games for player
        emit CreateGame(games.length - 1, msg.sender, _timeWait);
    }

    /// @notice Pause/Continue searching of player for the game
    /// @param _idGame Id game
    function pauseGame(uint256 _idGame) external outOfRange(_idGame) {
        require(games[_idGame].state == State.FindPlayers || games[_idGame].state == State.Pause, "This game has already started"); // For non-active games
        require(games[_idGame].player1 == msg.sender, "Only for creator of the game"); // The first player is a creator of the game
        require(games[_idGame].player2 == address(0));
        if (games[_idGame].state == State.FindPlayers) {
            games[_idGame].state = State.Pause; // Pause of searching
        } else if (games[_idGame].state == State.Pause) {
            games[_idGame].state = State.FindPlayers; // Continue of searching
        }
        emit PauseGame(_idGame, games[_idGame].state);
    }

    /// @notice Join to the new game
    /// @param _idGame Id game
    function joinGame(uint256 _idGame) external outOfRange(_idGame) {
        require(games[_idGame].state == State.FindPlayers, "This game is not available to join"); // For games that searching players
        require(games[_idGame].player1 != msg.sender, "You are the player1");
        require(games[_idGame].player2 == address(0), "The second player has been already exist");
        games[_idGame].player2 = msg.sender;
        games[_idGame].timeStart = block.timestamp; // Saving time of ending the move
        games[_idGame].state = State.EndSecond; // Move of the second player
        playerGamesCount[msg.sender]++; // Increasing number of games of the player
        emit JoinGame(_idGame, msg.sender);
    }

    /// @notice Player's move
    /// @param _idGame Id game
    /// @param _cell Cell of the playing field
    function movePlayer(uint256 _idGame, uint256 _cell) external outOfRange(_idGame) {
        require(_cell >= 0 && _cell <= 8, "This grid 3x3. Cell from 0 to 8");
        require((games[_idGame].player1 == msg.sender && games[_idGame].state == State.EndSecond) || (games[_idGame].player2 == msg.sender && games[_idGame].state == State.EndFirst), "It's not your turn to move!");
        require(games[_idGame].grid[_cell] == 0, "Cell is not free!"); // The cell is free

        require(checkingCombinations(games[_idGame].grid), "Game over. Winning combination is completed");
        require(checkingDraw(games[_idGame].grid), "Game over. Draw combination is completed");
        require(checkingTimeOut(games[_idGame].timeStart + games[_idGame].timeWait), "Game over. Your time to move is over");

        // Move of the firt or the second player
        if (games[_idGame].state == State.EndSecond) {
            games[_idGame].grid[_cell] = 1;
            games[_idGame].state = State.EndFirst;
            games[_idGame].timeStart = block.timestamp;
        } else if (games[_idGame].state == State.EndFirst) {
            games[_idGame].grid[_cell] = 2;
            games[_idGame].state = State.EndSecond;
            games[_idGame].timeStart = block.timestamp;
        }
        emit MovePlayer(_idGame, msg.sender, _cell);
    }

    /// @notice Check the status of the game
    /// @param _idGame Id game
    function isFinish(uint256 _idGame) external outOfRange(_idGame) {
        require(games[_idGame].state == State.EndFirst || games[_idGame].state == State.EndSecond, "Game is not active");
        if (checkingCombinations(games[_idGame].grid) == false) {
            // There is the winning combination on the field
            games[_idGame].state = nominationWinner(games[_idGame].state); // Who has won the game
            emit IsFinish(_idGame, games[_idGame].state);
            return;
        }

        if (checkingDraw(games[_idGame].grid) == false) {
            // There is the draw combination on the field
            games[_idGame].state = State.Draw;
            emit IsFinish(_idGame, games[_idGame].state);
            return;
        }

        if (checkingTimeOut(games[_idGame].timeStart + games[_idGame].timeWait) == false) {
            // Waiting time of the opponent's move is over
            games[_idGame].state = nominationWinner(games[_idGame].state); // Who has won the game
            emit IsFinish(_idGame, games[_idGame].state);
            return;
        }
        require(false, "Game hasn't ended.");
        return;
    }

    /// @notice Searching a new game
    /// @param _indexBegin Id game to begin the search
    /// @param _timeMin Minimum of waiting time of the move
    /// @param _timeMax Maximum of waiting time of the move
    /// @return index Id of finding
    function findOneGame(
        uint256 _indexBegin,
        uint256 _timeMin,
        uint256 _timeMax
    ) external view returns (uint256) {
        require(_indexBegin >= 0 && _indexBegin < games.length && _timeMin >= 0 && _timeMax >= _timeMin, "The input parameters are not correct");
        for (uint256 i = _indexBegin; i < games.length; i++) {
            if (games[i].player1 != msg.sender && games[i].state == State.FindPlayers && games[i].timeWait >= _timeMin && games[i].timeWait <= _timeMax) return i;
        }
        require(false, "There are no games with such parameters.");
        return 0;
    }

    /// @notice Getting information of the game
    /// @param _idGame Game Id
    /// @return Game Full information of the game
    function getOneGame(uint256 _idGame) external view outOfRange(_idGame) returns (Game memory) {
        return games[_idGame];
    }

    /// @notice Geting all the games of the player
    /// @param _player The address of the player
    /// @return GamesId Ids of games of the player
    function getGamesByPlayer(address _player) external view returns (uint256[] memory) {
        require(playerGamesCount[_player] > 0, "Player hasn't any games");
        uint256[] memory arrayId = new uint256[](playerGamesCount[_player]);
        uint256 index = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].player1 == _player || games[i].player2 == _player) {
                arrayId[index] = i;
                index++;
            }
        }
        return arrayId;
    }

    /// @notice Getting statistics of the player
    /// @param _player The address player
    /// @return StatisticPlayer [number of games, % of winning games, % of losing games , % of drawing games, % of active games]
    function statisticsPlayer(address _player) external view returns (uint256[] memory) {
        require(playerGamesCount[_player] > 0, "Player hasn't any games");
        uint256[] memory statistics = new uint256[](5); // [number of games, % of winning games, % of losing games , % of drawing games, % of active games]
        statistics[0] = playerGamesCount[_player];

        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].player1 == _player) {
                if (games[i].state == State.WinFirst) {
                    statistics[1]++;
                } else if (games[i].state == State.WinSecond) {
                    statistics[2]++;
                } else if (games[i].state == State.Draw) {
                    statistics[3]++;
                } else {
                    statistics[4]++;
                }
            } else if (games[i].player2 == _player) {
                if (games[i].state == State.WinFirst) {
                    statistics[2]++;
                } else if (games[i].state == State.WinSecond) {
                    statistics[1]++;
                } else if (games[i].state == State.Draw) {
                    statistics[3]++;
                } else {
                    statistics[4]++;
                }
            }
        }
        for (uint256 i = 1; i < statistics.length; i++) statistics[i] = (statistics[i] * 100) / statistics[0]; // Calculation of percent
        return statistics;
    }

    /// @notice Getting statistics of all games
    /// @return StatisticGames [number of games, % of winning the first player, % of winning the second player, % of drawing games, % of active games]
    function statisticsGames() external view returns (uint256[] memory) {
        require(games.length > 0, "Such games are not exist!");
        uint256[] memory statistics = new uint256[](5); // [number of games, % of winning the first player, % of winning the second player, % of drawing games, % of active games]
        statistics[0] = games.length;

        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].state == State.WinFirst) {
                statistics[1]++;
            } else if (games[i].state == State.WinSecond) {
                statistics[2]++;
            } else if (games[i].state == State.Draw) {
                statistics[3]++;
            } else {
                statistics[4]++;
            }
        }
        for (uint256 i = 1; i < statistics.length; i++) statistics[i] = (statistics[i] * 100) / statistics[0]; // Calculation of percent
        return statistics;
    }

    /// @notice Checking the winning combination on the field
    /// @param _grid Playing field
    /// @return bool Result of checking (inverse)
    function checkingCombinations(uint8[9] storage _grid) private view returns (bool) {
        for (uint256 i = 0; i < winCombinations.length; i++) {
            if ((_grid[winCombinations[i][0]] == uint256(1) && _grid[winCombinations[i][1]] == uint256(1) && _grid[winCombinations[i][2]] == uint256(1)) || (_grid[winCombinations[i][0]] == uint256(2) && _grid[winCombinations[i][1]] == uint256(2) && _grid[winCombinations[i][2]] == uint256(2)))
                return false;
        }
        return true;
    }

    /// @notice Checking the drawing combination on the field
    /// @param _grid Playing field
    /// @return bool Result of checking (inverse)
    function checkingDraw(uint8[9] storage _grid) private view returns (bool) {
        for (uint256 i = 0; i < _grid.length; i++) {
            if (_grid[i] == 0) return true;
        }
        return false;
    }

    /// @notice Checking the waiting time of the opponent's move is over
    /// @param _timeNow  Time of the beginning move + time of doing move
    /// @return bool Result of checking
    function checkingTimeOut(uint256 _timeNow) private view returns (bool) {
        return (block.timestamp <= _timeNow);
    }

    /// @notice Who has won the game
    /// @param _state Status of the game
    /// @return newState New status of the game
    function nominationWinner(State _state) private pure returns (State) {
        if (_state == State.EndFirst) return State.WinFirst;
        if (_state == State.EndSecond) return State.WinSecond;
        return _state;
    }
}