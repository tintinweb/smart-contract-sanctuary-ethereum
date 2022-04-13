// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract RockPaperScissors is Ownable, ReentrancyGuard {
    enum Move {
        ROCK,
        PAPER,
        SCISSORS
    }

    enum GameState {
        PARTICIPATED,
        CREATED
    }

    enum Result {
        TIED,
        FIRST,
        SECOND,
        UNEXPECTED
    }
    // global setup
    uint256 public minBet = 0.1 ether;
    uint256 public gameCounter = 0;
    mapping(Move => Move) public winningRules;
    // to prevent someone reuse used hash
    mapping(bytes32 => bool) public usedHash;
    mapping(uint256 => bool) public usedNonce;
    Move[] rpsMove = [Move.ROCK, Move.PAPER, Move.SCISSORS];

    mapping(uint256 => Game) games;
    // key should be keccak256(abi.encodePacked(_gameId,_playerIndex))
    mapping(bytes32 => Bet) bets;

    constructor() Ownable() ReentrancyGuard() {
        winningRules[Move.ROCK] = Move.SCISSORS;
        winningRules[Move.PAPER] = Move.ROCK;
        winningRules[Move.SCISSORS] = Move.PAPER;
    }

    struct Game {
        uint256 id;
        uint256 bet;
        GameState state;
    }
    struct Bet {
        address payable player;
        bytes move;
    }
    // emit event when a player enter the game
    event BetEvent(address player, bytes move, uint256 bet, uint256 game, bool first);
    // emit even when end game
    event GameResult(
        uint256 game,
        address p1,
        address p2,
        uint8 p1Move,
        uint8 p2Move,
        uint256 p1Rng,
        uint256 p2Rng,
        Result result
    );

    function _endGameAndTransfer(
        uint256 _gameId,
        uint8 _p1Move,
        uint8 _p2Move,
        uint256 _p1Nonce,
        uint256 _p2Nonce,
        Result result
    ) internal nonReentrant {
        Game storage game = games[_gameId];
        Bet storage b1 = bets[_computeHash(game.id, 0)];
        Bet storage b2 = bets[_computeHash(game.id, 1)];
        address payable p1 = b1.player;
        address payable p2 = b2.player;

        if (result == Result.FIRST) {
            // p1 win
            require(p1.send(2 * game.bet), 'cannot refund player1');
        } else if (result == Result.SECOND) {
            // p2 win
            require(p2.send(2 * game.bet), 'cannot refund player2');
        } else {
            // tier or unexpected result, refund
            require(p1.send(game.bet) && p2.send(game.bet), 'cannot refund both players');
        }
        emit GameResult(_gameId, p1, p2, _p1Move, _p2Move, _p1Nonce, _p2Nonce, result);
    }

    function createNew(bytes calldata _sahMove) external payable {
        require(msg.value >= minBet, 'you have to bet more');
        require(!usedHash[bytes32(_sahMove)], 'your input has been used');
        Game memory game;
        game.id = gameCounter;
        game.bet = msg.value;
        game.state = GameState.CREATED;
        games[gameCounter] = game;
        bets[_computeHash(game.id, 0)] = Bet({player: payable(msg.sender), move: _sahMove});
        gameCounter++;
        usedHash[bytes32(_sahMove)] = true;
        emit BetEvent(msg.sender, _sahMove, msg.value, game.id, true);
    }

    function participate(uint256 _gameId, bytes calldata _sahMove) external payable {
        Game storage game = games[_gameId];
        require(msg.value >= game.bet, 'not enough bet for this game');
        require(!usedHash[bytes32(_sahMove)], 'your input has been used');
        //also throw if game does not exist
        require(game.state == GameState.CREATED, 'game must be in CREATED state');
        require(msg.sender != bets[_computeHash(game.id, 0)].player, 'same player cannot join this game twice');
        // send extra fund back to player 2
        if (msg.value > game.bet) {
            payable(msg.sender).transfer(msg.value - game.bet);
        }
        bets[_computeHash(game.id, 1)] = Bet({player: payable(msg.sender), move: _sahMove});
        game.state = GameState.PARTICIPATED;
        usedHash[bytes32(_sahMove)] = true;
        emit BetEvent(msg.sender, _sahMove, game.bet, _gameId, false);
    }

    function revealResult(
        uint256 _gameId,
        uint256 _p1Nonce,
        uint256 _p2Nonce
    ) external onlyOwner {
        Game storage game = games[_gameId];
        require(game.state == GameState.PARTICIPATED, 'this game does not exists or this game is not in final stage');
        // calcuted players hash match corresponding moves or not
        Bet storage b1 = bets[_computeHash(game.id, 0)];
        Bet storage b2 = bets[_computeHash(game.id, 1)];
        uint8 p1Move = 3;
        uint8 p2Move = 3;
        for (uint256 i = 0; i < rpsMove.length; i++) {
            if (_computeHash(uint8(rpsMove[i]), _p1Nonce) == bytes32(b1.move)) p1Move = uint8(rpsMove[i]);
            if (_computeHash(uint8(rpsMove[i]), _p2Nonce) == bytes32(b2.move)) p2Move = uint8(rpsMove[i]);
        }
        // if any one of the hashes is not matched, set result to unknown and treat the same as TIED state
        Result result = Result.UNEXPECTED;
        // if one of nonce has been used before, treat it as unexpected, refund players
        if (!(usedNonce[_p1Nonce] && usedNonce[_p2Nonce])) {
            if (uint8(p1Move) < 3 && uint8(p2Move) < 3) {
                if (uint8(p1Move) == uint8(p2Move)) result = Result.TIED;
                else if (uint8(p2Move) == uint8(winningRules[Move(p1Move)])) result = Result.FIRST;
                else result = Result.SECOND;
            }
        }
        return _endGameAndTransfer(_gameId, p1Move, p2Move, _p1Nonce, _p2Nonce, result);
    }

    function _computeHash(uint256 v1, uint256 v2) private pure returns (bytes32) {
        bytes32 result = keccak256(abi.encodePacked(v1, v2));
        return result;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}