// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "./IBattleshipGame.sol";

contract BattleshipGame is IBattleshipGame {
    /// MODIFIERS ///

    /**
     * Ensure a message sender is not currently playing another game
     */
    modifier canPlay() {
        require(playing[_msgSender()] == 0, "Reentrant");
        _;
    }

    /**
     * Determine whether message sender is a member of a created or active game
     *
     * @param _game uint256 - the nonce of the game to check playability for
     */
    modifier isPlayer(uint256 _game) {
        require(playing[_msgSender()] == _game, "Not a player in game");
        _;
    }

    /**
     * Determine whether message sender is allowed to call a turn function
     *
     * @param _game uint256 - the nonce of the game to check playability for
     */
    modifier myTurn(uint256 _game) {
        require(playing[_msgSender()] == _game, "!Playing");
        require(games[_game].status == GameStatus.Joined, "!Playable");
        address current = games[_game].nonce % 2 == 0
            ? games[_game].participants[0]
            : games[_game].participants[1];
        require(_msgSender() == current, "!Turn");
        _;
    }

    /**
     * Make sure game is joinable
     * Will have more conditions once shooting phase is implemented
     *
     * @param _game uint256 - the nonce of the game to check validity for
     */
    modifier joinable(uint256 _game) {
        require(_game != 0 && _game <= gameIndex, "out-of-bounds");
        require(
            games[_game].status == GameStatus.Started,
            "Game has two players already"
        );
        _;
    }

    /// CONSTRUCTOR ///

    /**
     * Construct new instance of Battleship manager
     *
     * @param _forwarder address - the address of the erc2771 trusted forwarder
     * @param _bv address - the address of the initial board validity prover
     * @param _sv address - the address of the shot hit/miss prover
     */
    constructor(
        address _forwarder,
        address _bv,
        address _sv
    ) ERC2771Context(_forwarder) {
        trustedForwarder = _forwarder;
        bv = IBoardVerifier(_bv);
        sv = IShotVerifier(_sv);
    }

    /// MUTABLE FUNCTIONS ///

    function newGame(uint256 _boardHash, bytes calldata _proof)
        external
        override
        canPlay
    {
        require(bv.verify(_proof), "Invalid Board Config!");
        gameIndex++;
        games[gameIndex].status = GameStatus.Started;
        games[gameIndex].participants[0] = _msgSender();
        games[gameIndex].boards[0] = _boardHash;
        playing[_msgSender()] = gameIndex;
        emit Started(gameIndex, _msgSender());
    }

    function leaveGame(uint256 _game) external override isPlayer(_game) {
        Game storage game = games[_game];
        // Check if game has been started with two players. If so then forfeit
        if (game.status == GameStatus.Joined) {
            game.winner = _msgSender() == game.participants[0]
                ? game.participants[1]
                : game.participants[0];
            playing[game.participants[0]] = 0;
            playing[game.participants[1]] = 0;
            emit Won(game.winner, _game);
        } else {
            playing[game.participants[0]] = 0;
            emit Left(_msgSender(), _game);
        }
        game.status = GameStatus.Over;
    }

    function joinGame(
        uint256 _game,
        uint256 _boardHash,
        bytes calldata _proof
    ) external override canPlay joinable(_game) {
        require(bv.verify(_proof), "Invalid Board Config!");
        games[_game].participants[1] = _msgSender();
        games[_game].boards[1] = _boardHash;
        games[_game].status = GameStatus.Joined;
        playing[_msgSender()] = _game;
        emit Joined(_game, _msgSender());
    }

    function firstTurn(uint256 _game, uint256[2] memory _shot)
        external
        override
        myTurn(_game)
    {
        Game storage game = games[_game];
        require(game.nonce == 0, "!Turn1");
        game.shots[game.nonce] = _shot;
        game.nonce++;
        emit Shot(uint8(_shot[0]), uint8(_shot[1]), _game);
    }

    function turn(
        uint256 _game,
        bool _hit,
        uint256[2] memory _next,
        bytes calldata _proof
    ) external override myTurn(_game) {
        Game storage game = games[_game];
        require(game.nonce != 0, "Turn=0");
        // check proof
        uint256 hitInt;
        assembly {
            hitInt := _hit
        }
        require(sv.verify(_proof), "Invalid turn proof");
        // update game state
        game.hits[game.nonce - 1] = _hit;
        if (_hit) game.hitNonce[(game.nonce - 1) % 2]++;
        emit Report(_hit, _game);
        // check if game over
        if (game.hitNonce[(game.nonce - 1) % 2] >= HIT_MAX) gameOver(_game);
        else {
            // add next shot
            game.shots[game.nonce] = _next;
            game.nonce++;
            emit Shot(uint8(_next[0]), uint8(_next[1]), _game);
        }
    }

    /// VIEWABLE FUNCTIONS ///

    function gameState(uint256 _game)
        external
        view
        override
        returns (
            address[2] memory _participants,
            uint256[2] memory _boards,
            uint256 _turnNonce,
            uint256[2] memory _hitNonce,
            GameStatus _status,
            address _winner
        )
    {
        _participants = games[_game].participants;
        _boards = games[_game].boards;
        _turnNonce = games[_game].nonce;
        _hitNonce = games[_game].hitNonce;
        _status = games[_game].status;
        _winner = games[_game].winner;
    }

    /// INTERNAL FUNCTIONS ///

    /**
     * Handle transitioning game to finished state & paying out
     *
     * @param _game uint256 - the nonce of the game being finalized
     */
    function gameOver(uint256 _game) internal {
        Game storage game = games[_game];
        require(
            game.hitNonce[0] == HIT_MAX || game.hitNonce[1] == HIT_MAX,
            "!Over"
        );
        require(game.winner == address(0), "Over");
        game.winner = game.hitNonce[0] == HIT_MAX
            ? game.participants[0]
            : game.participants[1];
        game.status = GameStatus.Over;
        playing[games[_game].participants[0]] = 0;
        playing[games[_game].participants[1]] = 0;
        emit Won(game.winner, _game);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./IVerifier.sol";

/**
 * Abstraction for Zero-Knowledge Battleship Game
 * Operates at a 5% margin on winnings (1 XDAI in from 2 players, 1.95 XDAI to winner)
 */
abstract contract IBattleshipGame is ERC2771Context {
    event Left(address _by, uint256 _nonce);
    event Started(uint256 _nonce, address _by);
    event Joined(uint256 _nonce, address _by);
    event Shot(uint8 _x, uint8 _y, uint256 _game);
    event Report(bool hit, uint256 _game);
    event Won(address _winner, uint256 _nonce);

    enum GameStatus {
        Joined,
        NotStarted,
        Over,
        Started
    }

    struct Game {
        address[2] participants; // the two players in the game
        uint256[2] boards; // mimcsponge hash of board placement for each player
        uint256 nonce; // turn #
        mapping(uint256 => uint256[2]) shots; // map turn number to shot coordinates
        mapping(uint256 => bool) hits; // map turn number to hit/ miss
        uint256[2] hitNonce; // track # of hits player has made
        GameStatus status;
        address winner; // game winner
    }

    uint256 public constant HIT_MAX = 17; // number of hits before all ships are sunk

    uint256 public gameIndex; // current game nonce

    address public trustedForwarder; // make trusted forwarder public

    mapping(uint256 => Game) public games; // map game nonce to game data
    mapping(address => uint256) public playing; // map player address to game played

    IBoardVerifier bv; // verifier for proving initial board rule compliance
    IShotVerifier sv; // verifier for proving shot hit/ miss

    /**
     * Start a new board by uploading a valid board hash
     * @dev modifier canPlay
     *
     * @param _boardHash uint256 - hash of ship placement on board
     * @param _proof bytes calldata - zk proof of valid board
     */
    function newGame(uint256 _boardHash, bytes calldata _proof)
        external
        virtual;

    /**
     * Forfeit a game in the middle of playing of leave a game prior to starting
     * @dev modifier isPlayer
     *
     * @param _game uint256 - nonce of the game being played
     */
    function leaveGame(uint256 _game) external virtual;

    /**
     * Join existing game by uploading a valid board hash
     * @dev modifier canPlay joinable
     *
     * @param _game uint256 - the nonce of the game to join
     * @param _boardHash uint256 - hash of ship placement on board
     * @param _proof bytes calldata - zk proof of valid board
     */
    function joinGame(
        uint256 _game,
        uint256 _boardHash,
        bytes calldata _proof
    ) external virtual;

    /**
     * Player 0 can makes first shot without providing proof
     * @dev modifier myTurn
     * @notice proof verification is inherently reactive
     *         first shot must be made to kick off the cycle
     * @param _game uint256 - the nonce of the game to take turn on
     * @param _shot uint256[2] - the (x,y) coordinate to fire at
     */
    function firstTurn(uint256 _game, uint256[2] memory _shot) external virtual;

    /**
     * Play turn in game
     * @dev modifier myTurn
     * @notice once first turn is called, repeatedly calling this function drives game
     *         to completion state. Loser will always be last to call this function and end game.
     *
     * @param _game uint256 - the nonce of the game to play turn in
     * @param _hit bool - 1 if previous shot hit and 0 otherwise
     * @param _next uint256[2] - the (x,y) coordinate to fire at after proving hit/miss
     *    - ignored if proving hit forces game over
     * @param _proof bytes calldata - zk proof of valid board
     */
    function turn(
        uint256 _game,
        bool _hit,
        uint256[2] memory _next,
        bytes calldata _proof
    ) external virtual;

    /**
     * Return current game info
     *
     * @param _game uint256 - nonce of game to look for
     * @return _participants address[2] - addresses of host and guest players respectively
     * @return _boards uint256[2] - hashes of host and guest boards respectively
     * @return _turnNonce uint256 - the current turn number for the game
     * @return _hitNonce uint256[2] - the current number of hits host and guest have scored respectively
     * @return _status GameStatus - status of the game
     * @return _winner address - if game is won, will show winner
     */
    function gameState(uint256 _game)
        external
        view
        virtual
        returns (
            address[2] memory _participants,
            uint256[2] memory _boards,
            uint256 _turnNonce,
            uint256[2] memory _hitNonce,
            GameStatus _status,
            address _winner
        );
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

interface IBoardVerifier {
    function verify(bytes calldata) external view returns (bool r);
}

interface IShotVerifier {
    function verify(bytes calldata) external view returns (bool r);
}