// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Address.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Counters } from "@openzeppelin/contracts/utils/Counters.sol";

import { TaxableGame } from "./TaxableGame.sol";
import { PRSLeaderboard } from "./PRSLeaderboard.sol";
import { Choices, Errors, Game } from "./PRSLibrary.sol";

//                                       .::^^^^::..
//                              .:^!?YPG##&&$$$$$&&#BP5J7~:
//                          .!PB#&$$$$$$$$$$$$$$$$$$$$$$$$&BPJ!:
//                       .!5#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$&BY^
//                    .!5&$$$$$$$$$$$$$$$$$#BB##&$$$$$$$$$$$$$$$$$$P^
//                  ~5#$$$$$$$$$$$$#G5YJ?!^.  ...:^!?5G#$$$$$$$$$$$$$Y:
//                !G$$$$$$$$$$$#57^.                   .~?G&$$$$$$$$$$&J.
//              ^G$$$$$$$$$$&P!.                           :?B$$$$$$$$$$#!
//             J$$$$$$$$$$#J:                                 !B$$$$$$$$$$5.
//           .P$$$$$$$$$#?.                                     ?&$$$$$$$$$G.
//          :G$$$$$$$$&?.              .                         :G$$$$$$$$$Y
//         ~#$$$$$$$$5:             .Y##Y.                         5$$$$$$$$&:
//        Y$$$$$$$$$?              :#$$$$?      .?YJ^               P$$$$$$$$5
//       ~$$$$$$$$$?               Y$$$$$Y     ^B$$$$!              .#$$$$$$$$^
//       P$$$$$$$$?     ~!^.       P$$$$$?     B$$$$$7               J$$$$$$$$J
//      7$$$$$$$$5     ^$$$#BB##Y  !$$$$G      B$$$$G                ^$$$$$$$$J
//     ^$$$$$$$$&.      J$$$$$$&Y   7GGY.      Y$$$G.                :&$$$$$$$!
//     Y$$$$$$$$G        7$$$$?.               .JP?    !J!~!??^      ^$$$$$$$$^
//     7$$$$$$$$#.       :$$$$^                       ?$$$$$$$$~     ?$$$$$$$$^
//     :&$$$$$$$$~        G$$$#:                      .5$$$$$#Y:     B$$$$$$$&:
//     .#$$$$$$$$7        ^&$$$#^                     .B$$$$J.      7$$$$$$$$?
//      5$$$$$$$#.         ^#$$$&7                   .G$$$$!       :#$$$$$$$J
//      !$$$$$$$#^          :P$$$$P~               .?#$$$$!        G$$$$$$$Y
//      .#$$$$$$$&!           !B$$$$BJ~:      .:~?P&$$$$G~       .P$$$$$$$P
//       Y$$$$$$$$$7            !P&$$$$&#GPPPG#&$$$$$$P~        :G$$$$$$$B.
//       :&$$$$$$$$$?             :!YG&$$$$$$$$$$$&GJ^         ?&$$$$$$$#:
//        7$$$$$$$$$$Y.               .^~7??7!~!!~:         .7B$$$$$$$$G:
//         ~B$$$$$$$$$B!                                  ^J#$$$$$$$$&J
//           J$$$$$$$$$$BJ~.                           ^JB$$$$$$$$$$P^
//            ^G$$$$$$$$$$$#P?^.                   :!YB$$$$$$$$$$$#!
//              ?&$$$$$$$$$$$$$#G5?!^:.  .:~7??J5P#&$$$$$$$$$$$&G?.
//               .J#$$$$$$$$$$$$$$$$$&#BB#&$$$$$$$$$$$$$$$$$$G7.
//                 .7P#$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$&G?^
//                    .^7J5G#$$$$$$$$$$$$$$$$$$$$$$$$&B57:
//                          .^7YPB#&&&$$$&&&&##BG5J7~:
//                                ..::::::::...
//

/// A competitive, token-based, on-chain game of skill that persists results
/// to a public leaderboard stored in tableland.
///
/// @title PAPER, ROCK, SCISSORS
/// @author DOPE DAO
contract PaperRockScissors is Ownable, Pausable, TaxableGame, PRSLeaderboard {
    /// Both players have 12 hours to reveal their move.
    /// If one of them fails to do so the other can take the pot.
    uint256 public revealTimeout = 12 hours;
    using Counters for Counters.Counter;
    Counters.Counter private _games;
    mapping(uint256 => Game) Games;

    event CreatedGame(address indexed, uint256, uint256);
    event JoinedGameOf(address indexed, address indexed, uint256, uint256, uint256);
    event WonGameAgainst(address indexed, Choices, address indexed, Choices, uint256, uint256);
    event GameDraw(address indexed, Choices, address indexed, Choices, uint256, uint256);

    /// Create tableland schema for our leaderboard.
    /// @param tablelandRegistry Address of the "tableland registry" on the chain this will be deployed on
    /// @dev Find the list of tableland registries here https://docs.tableland.xyz/limits-and-deployed-contracts#ae3cfc1cfd2941bfa401580aa1e05c5e
    constructor(address tablelandRegistry) {
        _createTable(tablelandRegistry);
    }

    function setRevealTimeout(uint256 newTimeout) public onlyOwner {
        revealTimeout = newTimeout;
    }

    /// @dev Get game by (internal) ID
    /// @return Game struct
    function getGame(uint256 gameId) public view returns (Game memory) {
        Game storage game = Games[gameId];
        if (game.p1 == address(0)) revert Errors.IndexOutOfBounds(gameId);

        return game;
    }

    /// Return time left for both players to reveal their move
    function getTimeLeft(uint256 gameId) public view returns (uint256) {
        Game memory game = getGame(gameId);
        if (_didTimerRunOut(game.timerStart)) revert Errors.TimerFinished();
        if (game.p2 == address(0)) revert Errors.NoActiveTimer();
        return revealTimeout - (block.timestamp - game.timerStart);
    }

    /// @return Entry fee for a game id. 1/2 the "pot"
    function getGameEntryFee(uint256 gameId) public view returns (uint256) {
        Game memory game = getGame(gameId);
        return game.entryFee;
    }

    function pauseGame() public onlyOwner {
        _pause();
    }

    function unpauseGame() public onlyOwner {
        _unpause();
    }

    /* ========================================================================================= */
    // Commit
    /* ========================================================================================= */

    /// Whoever calls this makes a new game and becomes "p1"
    /// Requires a sha256 encoded move and password to be stored as
    /// A player can make multiple games at a time.
    ///
    /// @param encChoice sha256 hashed move and password
    /// @param entryFee The amount of entry fee required for this game.
    function startGame(bytes32 encChoice, uint256 entryFee)
        public
        checkEntryFeeEnough(entryFee)
        checkAddressHasSufficientBalance(entryFee)
        whenNotPaused
    {
        Game storage game = Games[_games.current()];
        _games.increment();

        game.p1 = msg.sender;
        game.entryFee = entryFee;
        game.p1SaltedChoice = encChoice;

        _subtractFromBalance(msg.sender, entryFee);
        emit CreatedGame(msg.sender, entryFee, block.timestamp);
    }

    /// Allows p2 to join an existing game by gameId
    /// Requires player to commit their hashed move and password to join.
    /// Will fail if player does not have high enough balance on contract.
    ///
    /// @param gameId ID of game stored in local storage.
    /// @param encChoice sha256 hashed move and password
    /// @param entryFee The amount of entry fee required for this game.
    function joinGame(
        uint256 gameId,
        bytes32 encChoice,
        uint256 entryFee
    ) public checkAddressHasSufficientBalance(entryFee) whenNotPaused {
        Game storage game = Games[gameId];
        address player1 = game.p1;

        if (player1 == address(0)) revert Errors.IndexOutOfBounds(gameId);
        if (player1 == msg.sender) revert Errors.CannotJoinGame(false, true);
        if (game.p2 != address(0)) revert Errors.CannotJoinGame(true, false);
        if (entryFee < game.entryFee) revert Errors.AmountTooLow(entryFee, game.entryFee);

        game.p2 = msg.sender;
        game.p2SaltedChoice = encChoice;
        game.timerStart = block.timestamp;

        _subtractFromBalance(msg.sender, entryFee);
        emit JoinedGameOf(msg.sender, player1, gameId, entryFee, block.timestamp);
    }

    /* ========================================================================================= */
    // Reveal
    /* ========================================================================================= */

    function revealChoice(uint256 gameId, string calldata movePw) public whenNotPaused {
        Game storage game = Games[gameId];
        address player1 = game.p1;
        address player2 = game.p2;

        if (player1 == address(0)) revert Errors.IndexOutOfBounds(gameId);
        if (player2 == address(0)) revert Errors.NoSecondPlayer();

        if (msg.sender == player1) {
            if (game.p1ClearChoice != Choices.NONE)
                revert Errors.AlreadyRevealed(msg.sender, gameId);
            game.p1ClearChoice = _getHashChoice(game.p1SaltedChoice, movePw);
            return;
        }

        if (msg.sender == player2) {
            if (game.p2ClearChoice != Choices.NONE)
                revert Errors.AlreadyRevealed(msg.sender, gameId);
            game.p2ClearChoice = _getHashChoice(game.p2SaltedChoice, movePw);
            return;
        }
    }

    /* ========================================================================================= */
    // Resolve
    /* ========================================================================================= */

    /// @dev Game is not resolvable if timer is still running and both players
    ///      have not revealed their move.
    function resolveGame(uint256 gameId) public whenNotPaused {
        Game storage game = Games[gameId];
        if (game.p1 == address(0)) revert Errors.IndexOutOfBounds(gameId);
        if (game.p2 == address(0)) revert Errors.NoSecondPlayer();
        if (game.resolved) revert Errors.NotResolvable(false, false, false, true);

        bool isTimerRunning = !_didTimerRunOut(game.timerStart);
        bool isP1ChoiceNone = game.p1ClearChoice == Choices.NONE;
        bool isP2ChoiceNone = game.p2ClearChoice == Choices.NONE;

        if (isTimerRunning && (isP2ChoiceNone || isP1ChoiceNone))
            revert Errors.NotResolvable(isTimerRunning, isP1ChoiceNone, isP2ChoiceNone, false);
        uint256 gameBalance = game.entryFee * 2;

        /// Prevent re-entrancy.
        game.resolved = true;

        // If we are here that means both players revealed their move.
        // If both revealed their move in time we can choose a winner.
        if (isTimerRunning) {
            address winner = _chooseWinner(
                game.p1ClearChoice,
                game.p2ClearChoice,
                game.p1,
                game.p2,
                gameBalance
            );
            _insertTableRow(gameId, game, winner);
            return;
        }

        // Timer ran out and only p2 did not reveal
        if (!isTimerRunning && !isP1ChoiceNone && isP2ChoiceNone) {
            _payout(game.p1, gameBalance);
            _insertTableRow(gameId, game, game.p1);
            return;
        }

        // Timer ran out and only p1 did not reveal
        if (!isTimerRunning && isP1ChoiceNone && !isP2ChoiceNone) {
            _payout(game.p2, gameBalance);
            _insertTableRow(gameId, game, game.p2);
            return;
        }
        // If both players fail to reveal the entryFee gets "burned" ;)
    }

    /* ========================================================================================= */
    // Internals
    /* ========================================================================================= */

    /// How PRS chooses a winner when two choices are revealed.
    /// @dev Essential that you ZERO OUT ANY GAME BALANCES before calling this.
    function _chooseWinner(
        Choices p1Choice,
        Choices p2Choice,
        address p1,
        address p2,
        uint256 gameBalance
    ) internal returns (address) {
        if (p1Choice == p2Choice) {
            _payout(p1, gameBalance / 2);
            _payout(p2, gameBalance / 2);
            emit GameDraw(p1, p1Choice, p2, p2Choice, gameBalance, block.timestamp);
            return address(0);
        }

        if (
            (p1Choice == Choices.PAPER && p2Choice == Choices.ROCK) ||
            (p1Choice == Choices.ROCK && p2Choice == Choices.SCISSORS) ||
            (p1Choice == Choices.SCISSORS && p2Choice == Choices.PAPER)
        ) {
            _payout(p1, gameBalance);
            emit WonGameAgainst(p1, p1Choice, p2, p2Choice, gameBalance, block.timestamp);
            return p1;
        }

        if (p1Choice == Choices.INVALID) {
            _payout(p2, gameBalance);
            emit WonGameAgainst(p2, p2Choice, p1, p1Choice, gameBalance, block.timestamp);
            return p2;
        }

        if (p2Choice == Choices.INVALID) {
            _payout(p1, gameBalance);
            emit WonGameAgainst(p1, p1Choice, p2, p2Choice, gameBalance, block.timestamp);
            return p1;
        }

        _payout(p2, gameBalance);
        emit WonGameAgainst(p2, p2Choice, p1, p1Choice, gameBalance, block.timestamp);
        return p2;
    }

    function _didTimerRunOut(uint256 timerStart) internal view returns (bool) {
        return block.timestamp > timerStart + revealTimeout;
    }

    function _getHashChoice(bytes32 hashChoice, string calldata clearChoice)
        internal
        pure
        returns (Choices)
    {
        bytes32 hashedClearChoice = sha256(abi.encodePacked(clearChoice));
        if (hashChoice != hashedClearChoice) revert Errors.InvalidPassword();

        bytes1 first = bytes(clearChoice)[0];

        if (first == 0x31) {
            return Choices.ROCK;
        } else if (first == 0x32) {
            return Choices.PAPER;
        } else if (first == 0x33) {
            return Choices.SCISSORS;
        }

        return Choices.INVALID;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
library Counters {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { Errors } from "./PRSLibrary.sol";

// @notice Abstract contract to handle fees, taxes, balances, and payouts of players
abstract contract TaxableGame is Ownable, ReentrancyGuard, Pausable {
    // @notice Variable minimum entry fee in gwei
    uint256 public minEntryFee = 10000000 gwei; // 0.01 eth
    // @notice Tax percent the game takes for each round of play
    uint256 public taxPercent = 5;

    // @notice Where we keep balances of players and the contract itself
    mapping(address => uint256) internal _balances;

    event PaidOut(address indexed, uint256, uint256);

    // @notice Check to determine if this address has enough balance to participate
    modifier checkAddressHasSufficientBalance(uint256 entryFee) {
        uint256 balance = balanceOf(msg.sender);
        if (balance < entryFee) revert Errors.PlayerBalanceNotEnough(balance, entryFee);
        _;
    }

    modifier checkEntryFeeEnough(uint256 entryFee) {
        if (entryFee < minEntryFee) revert Errors.AmountTooLow(entryFee, minEntryFee);
        _;
    }

    /* ========================================================================================= */
    // Receiving and withdrawing
    /* ========================================================================================= */

    // @notice Players increase their balance by sending the contract tokens
    receive() external payable {
        _addToBalance(msg.sender, msg.value);
    }

    // @notice Players can withdraw their balance from the contract
    function withdraw() public payable whenNotPaused {
        uint256 balance = balanceOf(msg.sender);
        if (address(this).balance < balance) revert Errors.NotEnoughMoneyInContract(address(this).balance, balance);
        _setBalance(msg.sender, 0);
        payable(msg.sender).transfer(balance);
    }

    // @notice Withdraws tax from games played to contract owner
    function withdrawTax() public payable onlyOwner {
        uint256 balance = balanceOf(address(this));
        if (address(this).balance < balance) revert Errors.NotEnoughMoneyInContract(address(this).balance, balance);
        _setBalance(address(this), 0);
        payable(msg.sender).transfer(balance);
    }

    /* ========================================================================================= */
    // Fees and taxes
    /* ========================================================================================= */
    function setMinEntryFee(uint256 fee) public onlyOwner {
        minEntryFee = fee;
    }

    function setTaxPercent(uint256 pct) public onlyOwner {
        taxPercent = pct;
    }

    /* ========================================================================================= */
    // Balances
    /* ========================================================================================= */

    // @notice Entire balance of contract
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // @notice Balance for players and this contract itself
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _addToBalance(address account, uint256 amount) internal {
        uint256 currentBalance = balanceOf(account);
        uint256 newBalance = currentBalance + amount;
        _setBalance(account, newBalance);
    }

    function _subtractFromBalance(address account, uint256 amount) internal {
        uint256 currentBalance = balanceOf(account);
        uint256 newBalance = currentBalance - amount;
        if (0 >= newBalance) {
            newBalance = 0;
        }
        _setBalance(account, newBalance);
    }

    function _setBalance(address account, uint256 balance) internal {
        if (balance < 0) revert Errors.InvalidBalance(balance);
        _balances[account] = balance;
    }

    /* ========================================================================================= */
    // Payments
    /* ========================================================================================= */
    
    // @return payout Amount paid to player less tax
    // @return tax    Amount taxed from payout
    function _getPayoutWithTax(uint256 amount) internal view returns (uint256, uint256) {
        uint256 tax = (amount / 100) * taxPercent;
        uint256 payout = amount - tax;
        return (payout, tax);
    }

    // @notice A simple, and slightly UNSAFE payout function.
    //         Ensure that you're setting balances to zero wherever this is called.
    function _payout(address player, uint256 amount) internal {
        (uint256 payout, uint256 tax) = _getPayoutWithTax(amount);

        _addToBalance(address(this), tax);
        _addToBalance(player, payout);

        emit PaidOut(player, payout, block.timestamp);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import { ITablelandTables } from "@tableland/evm/contracts/ITablelandTables.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Game } from "./PRSLibrary.sol";

/// Tableland interface for Paper, Rock, Scissors.
///
/// Contains logic for creating table owned by contract, inserting rows for resolved games,
/// and accessing data from the leaderboard.
///
/// @dev These functions are extracted here for code modularity, and the ability to mock each
///      for testing purposes in our mock contract. We check they're working upon dev deployment.
///      Not the most sound approach, but it will work for now.
///      All functions "virtual" for this purpose.
abstract contract PRSLeaderboard {
    ITablelandTables private _tableland;
    uint256 private _gameTableId;
    string private _tablePrefix = "prs";
    string public gameTable;

    /// Initializes Tableland table to store record of games played.
    /// @param tablelandRegistry Address of the "tableland registry" on the chain this will be deployed on.
    function _createTable(address tablelandRegistry) internal virtual {
        _tableland = ITablelandTables(tablelandRegistry);

        /// @dev Stores unique ID for our created table
        _gameTableId = _tableland.createTable(
            address(this),
            string.concat(
                "CREATE TABLE ",
                _tablePrefix,
                "_",
                Strings.toString(block.chainid),
                " (",
                "game_id INT UNIQUE, ",
                "created_at_timestamp INT, ",
                "game_entry_fee INT, ",
                "player_1 TEXT, ",
                "player_2 TEXT, ",
                "winner TEXT, ",
                "player_1_move INT, ",
                "player_2_move INT ",
                ");"
            )
        );

        /// @dev Stores full table name for new table.
        gameTable = string.concat(
            _tablePrefix,
            "_",
            Strings.toString(block.chainid),
            "_",
            Strings.toString(_gameTableId)
        );
    }

    function _insertTableRow(
        uint256 gameId,
        Game memory game,
        address winner
    ) internal virtual {
        _tableland.runSQL(
            address(this),
            _gameTableId,
            string.concat(
                "INSERT INTO ",
                gameTable,
                " (game_id, created_at_timestamp, game_entry_fee, player_1, player_2, winner, player_1_move, player_2_move) ",
                " values (",
                Strings.toString(gameId),
                Strings.toString(block.timestamp),
                Strings.toString(game.entryFee),
                Strings.toHexString(game.p1),
                Strings.toHexString(game.p2),
                Strings.toHexString(winner),
                Strings.toString(uint8(game.p1ClearChoice)),
                Strings.toString(uint8(game.p2ClearChoice)),
                ");"
            )
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

library Errors {
    error AmountTooLow(uint256 available, uint256 required);
    error CannotJoinGame(bool alreadHasP2, bool tryingToJoinOwnGame);
    error InvalidBalance(uint256 balance);
    error IndexOutOfBounds(uint256 gameId);
    error InvalidPassword();
    error NoActiveTimer();
    error NoSecondPlayer();
    error NotEnoughMoneyInContract(uint256 available, uint256 requested);
    error NotSecondPlayer(address expected, address received);
    error PlayerBalanceNotEnough(uint256 available, uint256 required);
    error TimerFinished();
    error TimerStillRunning();
    error AlreadyRevealed(address player, uint256 gameId);
    error NotResolvable(
        bool timerStillRunning,
        bool p1Revealed,
        bool p2Revealed,
        bool alreadyResolved
    );
}

struct Game {
    bytes32 p1SaltedChoice;
    bytes32 p2SaltedChoice;
    Choices p1ClearChoice;
    Choices p2ClearChoice;
    address p1;
    address p2;
    uint256 entryFee;
    uint256 timerStart;
    bool resolved;
}

enum Choices {
    NONE,
    ROCK,
    PAPER,
    SCISSORS,
    INVALID
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
pragma solidity ^0.8.4;

import "./ITablelandController.sol";

/**
 * @dev Interface of a TablelandTables compliant contract.
 */
interface ITablelandTables {
    /**
     * The caller is not authorized.
     */
    error Unauthorized();

    /**
     * RunSQL was called with a query length greater than maximum allowed.
     */
    error MaxQuerySizeExceeded(uint256 querySize, uint256 maxQuerySize);

    /**
     * @dev Emitted when `owner` creates a new table.
     *
     * owner - the to-be owner of the table
     * tableId - the table id of the new table
     * statement - the SQL statement used to create the table
     */
    event CreateTable(address owner, uint256 tableId, string statement);

    /**
     * @dev Emitted when a table is transferred from `from` to `to`.
     *
     * Not emmitted when a table is created.
     * Also emitted after a table has been burned.
     *
     * from - the address that transfered the table
     * to - the address that received the table
     * tableId - the table id that was transferred
     */
    event TransferTable(address from, address to, uint256 tableId);

    /**
     * @dev Emitted when `caller` runs a SQL statement.
     *
     * caller - the address that is running the SQL statement
     * isOwner - whether or not the caller is the table owner
     * tableId - the id of the target table
     * statement - the SQL statement to run
     * policy - an object describing how `caller` can interact with the table (see {ITablelandController.Policy})
     */
    event RunSQL(
        address caller,
        bool isOwner,
        uint256 tableId,
        string statement,
        ITablelandController.Policy policy
    );

    /**
     * @dev Emitted when a table's controller is set.
     *
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     */
    event SetController(uint256 tableId, address controller);

    /**
     * @dev Creates a new table owned by `owner` using `statement` and returns its `tableId`.
     *
     * owner - the to-be owner of the new table
     * statement - the SQL statement used to create the table
     *
     * Requirements:
     *
     * - contract must be unpaused
     */
    function createTable(address owner, string memory statement)
        external
        payable
        returns (uint256);

    /**
     * @dev Runs a SQL statement for `caller` using `statement`.
     *
     * caller - the address that is running the SQL statement
     * tableId - the id of the target table
     * statement - the SQL statement to run
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` or contract owner
     * - `tableId` must exist
     * - `caller` must be authorized by the table controller
     * - `statement` must be less than or equal to 35000 bytes
     */
    function runSQL(
        address caller,
        uint256 tableId,
        string memory statement
    ) external payable;

    /**
     * @dev Sets the controller for a table. Controller can be an EOA or contract address.
     *
     * When a table is created, it's controller is set to the zero address, which means that the
     * contract will not enforce write access control. In this situation, validators will not accept
     * transactions from non-owners unless explicitly granted access with "GRANT" SQL statements.
     *
     * When a controller address is set for a table, validators assume write access control is
     * handled at the contract level, and will accept all transactions.
     *
     * You can unset a controller address for a table by setting it back to the zero address.
     * This will cause validators to revert back to honoring owner and GRANT bases write access control.
     *
     * caller - the address that is setting the controller
     * tableId - the id of the target table
     * controller - the address of the controller (EOA or contract)
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function setController(
        address caller,
        uint256 tableId,
        address controller
    ) external;

    /**
     * @dev Returns the controller for a table.
     *
     * tableId - the id of the target table
     */
    function getController(uint256 tableId) external returns (address);

    /**
     * @dev Locks the controller for a table _forever_. Controller can be an EOA or contract address.
     *
     * Although not very useful, it is possible to lock a table controller that is set to the zero address.
     *
     * caller - the address that is locking the controller
     * tableId - the id of the target table
     *
     * Requirements:
     *
     * - contract must be unpaused
     * - `msg.sender` must be `caller` and owner of `tableId`
     * - `tableId` must exist
     * - `tableId` controller must not be locked
     */
    function lockController(address caller, uint256 tableId) external;

    /**
     * @dev Sets the contract base URI.
     *
     * baseURI - the new base URI
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     */
    function setBaseURI(string memory baseURI) external;

    /**
     * @dev Pauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be unpaused
     */
    function pause() external;

    /**
     * @dev Unpauses the contract.
     *
     * Requirements:
     *
     * - `msg.sender` must be contract owner
     * - contract must be paused
     */
    function unpause() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/**
 * @dev Interface of a TablelandController compliant contract.
 *
 * This interface can be implemented to enabled advanced access control for a table.
 * Call {ITablelandTables-setController} with the address of your implementation.
 *
 * See {test/TestTablelandController} for an example of token-gating table write-access.
 */
interface ITablelandController {
    /**
     * @dev Object defining how a table can be accessed.
     */
    struct Policy {
        // Whether or not the table should allow SQL INSERT statements.
        bool allowInsert;
        // Whether or not the table should allow SQL UPDATE statements.
        bool allowUpdate;
        // Whether or not the table should allow SQL DELETE statements.
        bool allowDelete;
        // A conditional clause used with SQL UPDATE and DELETE statements.
        // For example, a value of "foo > 0" will concatenate all SQL UPDATE
        // and/or DELETE statements with "WHERE foo > 0".
        // This can be useful for limiting how a table can be modified.
        // Use {Policies-joinClauses} to include more than one condition.
        string whereClause;
        // A conditional clause used with SQL INSERT statements.
        // For example, a value of "foo > 0" will concatenate all SQL INSERT
        // statements with a check on the incoming data, i.e., "CHECK (foo > 0)".
        // This can be useful for limiting how table data ban be added.
        // Use {Policies-joinClauses} to include more than one condition.
        string withCheck;
        // A list of SQL column names that can be updated.
        string[] updatableColumns;
    }

    /**
     * @dev Returns a {Policy} struct defining how a table can be accessed by `caller`.
     */
    function getPolicy(address caller) external payable returns (Policy memory);
}