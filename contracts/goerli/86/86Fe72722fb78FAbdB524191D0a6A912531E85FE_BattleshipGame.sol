//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "./IBattleshipGame.sol";

contract BattleshipGame is IBattleshipGame {

    /// MODIFIERS ///

    /**
     * Ensure only contract owner can collect procedes/ administrate contract
     */
    modifier onlyOperator() {
        require(_msgSender() == operator, "!Operator");
        _;
    }

    /**
     * Ensure a message sender has approved ticket erc20 and is not currently playing another game
     */
    modifier canPlay() {
        require(
            ticket.allowance(_msgSender(), address(this)) >= 1 ether,
            "!Tickets"
        );
        require(playing[_msgSender()] == 0, "Reentrant");
        _;
    }

    /**
     * Determine whether message sender is allowed to call a turn function
     *
     * @param _game uint256 - the nonce of the game to check playability for 
     */
    modifier myTurn(uint256 _game) {
        require(playing[_msgSender()] == _game, "!Playing");
        require(games[_game].winner == address(0), "!Playable");
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
            games[_game].participants[0] != address(0) &&
                games[_game].participants[1] == address(0),
            "!Open"
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
     * @param _ticket address - the address of the ERC20 token required to be spent to play the game
     */
    constructor(address _forwarder, address _bv, address _sv, address _ticket) 
        ERC2771Context(_forwarder)
    {
        bv = IBoardVerifier(_bv);
        sv = IShotVerifier(_sv);
        ticket = IERC20(_ticket);
        operator = _msgSender();
    }

    /// MUTABLE FUNCTIONS ///

    function newGame(
        uint256 _boardHash,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
    ) external override canPlay {
        require(
            bv.verifyProof(a, [b_0, b_1], c, [_boardHash]),
            "Invalid Board Config!"
        );
        ticket.transferFrom(_msgSender(), address(this), 1 ether);
        gameIndex++;
        games[gameIndex].participants[0] = _msgSender();
        games[gameIndex].boards[0] = _boardHash;
        playing[_msgSender()] = gameIndex;
        emit Started(gameIndex);
    }

    function joinGame(
        uint256 _game,
        uint256 _boardHash,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
    ) external override canPlay joinable(_game) {
        require(
            bv.verifyProof(a, [b_0, b_1], c, [_boardHash]),
            "Invalid Board Config!"
        );
        ticket.transferFrom(_msgSender(), address(this), 1 ether);
        games[_game].participants[1] = _msgSender();
        games[_game].boards[1] = _boardHash;
        playing[_msgSender()] = _game;
        emit Joined(_game);
    }

    function firstTurn(uint256 _game, uint256[2] memory _shot) external override myTurn(_game) {
        Game storage game = games[_game];
        require(game.nonce == 0, "!Turn1");
        game.shots[game.nonce] = _shot;
        game.nonce++;
    }

    function turn(
        uint256 _game,
        bool _hit,
        uint256[2] memory _next,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
    ) external override myTurn(_game) {
        Game storage game = games[_game];
        require(game.nonce != 0, "Turn=0");
        // check proof
        uint256 boardHash = game.boards[game.nonce % 2];
        uint256[2] memory shot = game.shots[game.nonce - 1];
        uint256 hitInt;
        assembly { hitInt := _hit }
        require(
            sv.verifyProof(
                a,
                [b_0, b_1],
                c,
                [boardHash, shot[0], shot[1], hitInt]
            ),
            "Invalid turn proof"
        );
        // update game state
        game.hits[game.nonce - 1] = _hit;
        if (_hit) game.hitNonce[(game.nonce - 1) % 2]++;
        emit Shot(_game, game.nonce - 1, _hit);
        // check if game over
        if (game.hitNonce[(game.nonce - 1) % 2] >= HIT_MAX) gameOver(_game);
        else {
            // add next shot
            game.shots[game.nonce] = _next;
            game.nonce++;
        }
    }

    function collectProceeds(address _to) external override onlyOperator {
        uint256 balance = ticket.balanceOf(address(this));
        emit Collected(balance);
        ticket.transfer(_to, balance);
    }

    /// VIEWABLE FUNCTIONS ///

    function gameState(uint256 _game) external override view returns (
        address[2] memory _participants,
        uint256[2] memory _boards,
        uint256 _turnNonce,
        uint256[2] memory _hitNonce,
        address _winner
    ) {
        _participants = games[_game].participants;
        _boards = games[_game].boards;
        _turnNonce = games[_game].nonce;
        _hitNonce = games[_game].hitNonce;
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
        ticket.transfer(game.winner, 1.95 ether);
        emit Won(game.winner, _game);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import "./IVerifier.sol";

/**
 * Abstraction for Zero-Knowledge Battleship Game
 * Operates at a 5% margin on winnings (1 XDAI in from 2 players, 1.95 XDAI to winner)
 */
abstract contract IBattleshipGame is ERC2771Context {

    event Started(uint256 _nonce);
    event Joined(uint256 _nonce);
    event Shot(uint256 _game, uint256 _turn, bool _hit);
    event Won(address _winner, uint256 _nonce);
    event Collected(uint256 _amount);

    struct Game {
        address[2] participants; // the two players in the game
        uint256[2] boards; // mimcsponge hash of board placement for each player
        uint256 nonce; // turn #
        mapping(uint256 => uint256[2]) shots; // map turn number to shot coordinates
        mapping(uint256 => bool) hits; // map turn number to hit/ miss
        uint256[2] hitNonce; // track # of hits player has made
        address winner; // game winner
    }

    uint256 constant HIT_MAX = 17; // number of hits before all ships are sunk

    uint256 gameIndex; // current game nonce
    address operator; // owner

    mapping(uint256 => Game) public games; // map game nonce to game data
    mapping(address => uint256) public playing; // map player address to game played

    IBoardVerifier bv; // verifier for proving initial board rule compliance
    IShotVerifier sv; // verifier for proving shot hit/ miss

    IERC20 ticket; // token for cost of entry / winner's proceeds

    /**
     * Start a new board by uploading a valid board hash
     * @dev modifier canPlay
     *
     * @param _boardHash uint256 - hash of ship placement on board
     * @param a uint256[2] - zk proof part 1
     * @param b_0 uint256[2] - zk proof part 2 split 1
     * @param b_1 uint256[2] - zk proof part 2 split 2
     * @param c uint256[2] - zk proof part 3
     */
    function newGame(
        uint256 _boardHash,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
    ) external virtual;

    /**
     * Join existing game by uploading a valid board hash
     * @dev modifier canPlay joinable
     *
     * @param _game uint256 - the nonce of the game to join
     * @param _boardHash uint256 - hash of ship placement on board
     * @param a uint256[2] - zk proof part 1
     * @param b_0 uint256[2] - zk proof part 2 split 1
     * @param b_1 uint256[2] - zk proof part 2 split 2
     * @param c uint256[2] - zk proof part 3
     */
    function joinGame(
        uint256 _game,
        uint256 _boardHash,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
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
     * @param a uint256[2] - zk proof part 1
     * @param b_0 uint256[2] - zk proof part 2 split 1
     * @param b_1 uint256[2] - zk proof part 2 split 2
     * @param c uint256[2] - zk proof part 3
     */
    function turn(
        uint256 _game,
        bool _hit,
        uint256[2] memory _next,
        uint256[2] memory a,
        uint256[2] memory b_0,
        uint256[2] memory b_1,
        uint256[2] memory c
    ) external virtual;

    /**
     * Collect accumulated profit from game fee
     * @dev modifier onlyOperator
     *
     * @param _to address - the address the operator wants to receive tokens at
     */
    function collectProceeds(address _to) external virtual;

    /**
     * Return current game info
     *
     * @param _game uint256 - nonce of game to look for
     * @return _participants address[2] - addresses of host and guest players respectively
     * @return _boards uint256[2] - hashes of host and guest boards respectively
     * @return _turnNonce uint256 - the current turn number for the game
     * @return _hitNonce uint256[2] - the current number of hits host and guest have scored respectively
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
            address _winner
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.11;

interface IBoardVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) external view returns (bool r);
}

interface IShotVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[4] memory input
    ) external view returns (bool r);
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