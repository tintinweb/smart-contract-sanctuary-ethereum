//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

contract TicTacToe {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _gameId;
    CountersUpgradeable.Counter private _endGame;
    uint8 constant MAX_COUNT = 8;

    enum PlayerStatus {
        WIN,
        LOSE,
        TIE,
        PLAYING
    }

    struct Player {
        address payable addr;
        uint256 betAmount;
        PlayerStatus status;
    }

    enum GameStatus {
        NOT_STARTED,
        STARTED,
        COMPLETED,
        TIED
    }

    enum SquareState {
        EMPTY,
        USER1,
        USER2
    }

    struct Game {
        Player user1;
        Player user2;
        address payable turn;
        uint8 count;
        uint256 betAmount;
        SquareState[3][3] board;
        GameStatus status;
    }

    mapping(uint256 => Game) games;

    function createGame() public payable returns (uint256) {
        SquareState[3][3] memory board;
        uint256 gameId = _gameId.current();
        games[gameId] = Game({
            user1: Player({
                addr: payable(msg.sender),
                betAmount: msg.value,
                status: PlayerStatus.PLAYING
            }),
            user2: Player({
                addr: payable(address(0x0)),
                betAmount: 0,
                status: PlayerStatus.PLAYING
            }),
            betAmount: msg.value,
            board: board,
            count: 0,
            turn: payable(msg.sender),
            status: GameStatus.NOT_STARTED
        });
        _gameId.increment();

        return gameId;
    }

    function joinGame(uint256 gameId) public payable {
        Game storage game = games[gameId];

        require(game.user1.betAmount == msg.value, "Invalid bet amount");
        game.user2 = Player({
            addr: payable(msg.sender),
            betAmount: msg.value,
            status: PlayerStatus.PLAYING
        });
        game.betAmount += msg.value;
    }

    function play(
        uint8 x,
        uint8 y,
        uint256 gameId
    )
        public
        payable
        validPositionInBoard(x, y)
        isGamer(gameId)
        isNotGameOver(gameId)
    {
        Game storage game = games[gameId];
        require(game.turn == msg.sender, "Not your turn");
        require(game.board[x][y] == SquareState.EMPTY, "Not a empty position");

        if (game.status == GameStatus.NOT_STARTED) {
            game.status = GameStatus.STARTED;
        }

        game.board[x][y] = _playerToShape(gameId, msg.sender);
        game.count += 1;
        _nextTurn(game);

        // 1. count가 MAX_COUNT 보다 커졌는 지 확인
        if (game.count > MAX_COUNT) {
            if (_checkTie(gameId)) {
                game.status = GameStatus.TIED;
                _endGame.increment();
                _recordGameResult(gameId, address(0x0));
            }
        } else {
            // 2. 3줄이 완성되었는 지 확인
            if (_checkWin(gameId, msg.sender)) {
                game.status = GameStatus.COMPLETED;
                _endGame.increment();
                _recordGameResult(gameId, msg.sender);
            }
        }
    }

    function _nextTurn(Game storage game) private {
        if (game.turn == game.user1.addr) {
            game.turn = game.user2.addr;
        } else {
            game.turn = game.user1.addr;
        }
    }

    function getWinner(uint256 gameId)
        public
        view
        isGameOver(gameId)
        returns (address winner)
    {
        Game memory game = games[gameId];

        if (game.user1.status == PlayerStatus.WIN) {
            winner = game.user1.addr;
        } else if (game.user2.status == PlayerStatus.WIN) {
            winner = game.user2.addr;
        } else {
            // TODO: throw error
            winner = address(0x0);
        }

        // return winner;
    }

    // winner, game status 기록
    function _recordGameResult(uint256 gameId, address winner)
        private
        isGameOver(gameId)
    {
        Game storage game = games[gameId];

        if (game.status == GameStatus.COMPLETED) {
            if (winner == game.user1.addr) {
                game.user1.status = PlayerStatus.WIN;
                game.user2.status = PlayerStatus.LOSE;
            } else if (winner == game.user2.addr) {
                game.user1.status = PlayerStatus.LOSE;
                game.user2.status = PlayerStatus.WIN;
            } else {
                // TODO: throw error
            }
        } else if (game.status == GameStatus.TIED) {
            game.user1.status = PlayerStatus.TIE;
            game.user2.status = PlayerStatus.TIE;
        } else {
            // TODO: throw error
        }
    }

    function _playerToShape(uint256 gameId, address user)
        private
        view
        returns (SquareState player)
    {
        Game memory game = games[gameId];

        if (user == game.user1.addr) {
            player = SquareState.USER1;
        } else if (user == game.user2.addr) {
            player = SquareState.USER2;
        } else {
            // TODO: throw error
        }
    }

    function _completeOneLine(
        uint256 gameId,
        address user,
        uint8 r0,
        uint8 r1,
        uint8 r2,
        uint8 c0,
        uint8 c1,
        uint8 c2
    ) private view returns (bool) {
        Game memory game = games[gameId];
        SquareState player = _playerToShape(gameId, user);

        if (
            game.board[r0][c0] == player &&
            game.board[r1][c1] == player &&
            game.board[r2][c2] == player
        ) {
            return true;
        }
        return false;
    }

    function _checkTie(uint256 gameId) private view returns (bool) {
        Game memory game = games[gameId];
        require(game.count > MAX_COUNT, "game.count <= 8");
        if (
            !_checkWin(gameId, game.user1.addr) &&
            !_checkWin(gameId, game.user2.addr)
        ) {
            return true;
        }
        return false;
    }

    function _checkWin(uint256 gameId, address user)
        private
        view
        returns (bool)
    {
        // 대각선으로 같은 지 확인
        if (
            _completeOneLine(gameId, user, 0, 1, 2, 0, 1, 2) ||
            _completeOneLine(gameId, user, 0, 1, 2, 2, 1, 0)
        ) {
            return true;
        }

        // 로우 or 컬럼이 같은 지 확인
        for (uint8 r = 0; r < 3; r++)
            if (
                _completeOneLine(gameId, user, r, r, r, 0, 1, 2) ||
                _completeOneLine(gameId, user, 0, 1, 2, r, r, r)
            ) {
                return true;
            }

        return false;
    }

    // if _checkWin(user1) => winner: user1
    // if _checkWin(user2) => winner: user2
    // if !_checkWin(user1) && _checkWin(user2) && game.count > 8 => tied
    function findOutWinner(uint256 gameId) public view returns (address addr) {
        Game memory game = games[gameId];

        if (_checkWin(gameId, game.user1.addr)) {
            addr = game.user1.addr;
        } else if (_checkWin(gameId, game.user2.addr)) {
            addr = game.user2.addr;
        } else {
            // TODO: throw error
        }
    }

    modifier validPositionInBoard(uint8 x, uint8 y) {
        require(x >= 0 && x < 3 && y >= 0 && y < 3, "Invalid position");
        _;
    }

    modifier isGamer(uint256 gameId) {
        Game memory game = games[gameId];

        require(
            msg.sender == game.user1.addr || msg.sender == game.user2.addr,
            "msg.sender is not gamer"
        );
        _;
    }

    modifier isNotGameOver(uint256 gameId) {
        Game memory game = games[gameId];
        require(!_isGameOver(gameId), "Game over");
        _;
    }

    modifier isGameOver(uint256 gameId) {
        Game memory game = games[gameId];
        require(_isGameOver(gameId), "Playing game");
        _;
    }

    function _isGameOver(uint256 gameId) private view returns (bool) {
        Game memory game = games[gameId];
        if (
            game.status == GameStatus.TIED ||
            game.status == GameStatus.COMPLETED ||
            game.count > MAX_COUNT
        ) {
            return true;
        }
        return false;
    }

    function gameInfo(uint256 gameId) public view returns (Game memory) {
        Game memory game = games[gameId];

        return game;
    }

    function getNotStartedGames() public view returns (Game[] memory) {
        uint256 gameCount = _gameId.current();
        uint256 notStartedGameCount = _gameId.current() - _endGame.current();
        uint256 currentIndex = 0;

        Game[] memory notStartedGames = new Game[](notStartedGameCount);

        for (uint256 i = 0; i < gameCount; i++) {
            if (games[i].status == GameStatus.NOT_STARTED) {
                notStartedGames[currentIndex] = games[i];
                currentIndex += 1;
            }
        }

        return notStartedGames;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}