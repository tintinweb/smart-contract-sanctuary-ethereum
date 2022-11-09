// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./GameTools.sol";

/**
 * @title shareORsteal game contract
 */
contract ShareORsteal is ReentrancyGuard, GameTools {
    using Counters for Counters.Counter;
    using ERC165Checker for address;
    uint256 pricePerSecond = 10**16;
    uint256 gamePeriod = 2.5 minutes;
    uint256 protectionPeriod = 10 seconds;
    uint16 gameId = 1;

    mapping(uint256 => GameRoom) public RoomIdToGameRoom;
    mapping(uint256 => Protection) public RoomIdToProtection;

    struct GameRoom {
        address player1;
        address player2;
        address erc20Address;
        uint256 betAmount;
        uint256 startedTime;
        uint16 result;
        bool isClosed;
    }

    struct Protection {
        uint256 protectTime1;
        uint256 protectTime2;
    }

    event GameStarted(uint256 indexed roomId);
    event GameEnded(uint256 indexed roomId);
    event Protected(uint256 indexed roomId);

    /**
     * @dev Initialize the contract
     * @param erc20TokenAddresses list of ERC20 tokens to be whitelisted initially
     */
    constructor(address[] memory erc20TokenAddresses)
        GameTools(erc20TokenAddresses)
    {}

    /**
     * @dev Change priucePerSecond only owner
     * @param price new price per second
     */
    function changePricePerSecond(uint256 price) external onlyOwner {
        pricePerSecond = price;
    }

    function getPricePerSecond() public view returns (uint256) {
        return pricePerSecond;
    }

    /**
     * @dev change gamePeriod
     * @param period new period by seconds
     */
    function changeGamePeriod(uint256 period) external onlyOwner {
        gamePeriod = period;
    }

    function getGamePeriod() public view returns (uint256) {
        return gamePeriod;
    }

    /**
     * @dev change protectPeriod
     * @param period new period by seconds
     */
    function changeProtectionPeriod(uint256 period) external onlyOwner {
        protectionPeriod = period;
    }

    function getProtectioPeriod() public view returns (uint256) {
        return protectionPeriod;
    }

    /**
     * @dev gameRoomClosed modifier
     * @param roomId Id of game room
     */
    modifier gameRoomClosed(uint256 roomId) {
        require(!RoomIdToGameRoom[roomId].isClosed, "Game room is closed");
        _;
    }

    /**
     * @dev Start Game
     * @param player1 the first player
     * @param player2 the second player
     * @param erc20Address erc20 token address that is used for betting
     * @param betAmount the amount of bet
     */
    function startGame(
        address player1,
        address player2,
        address erc20Address,
        uint256 betAmount
    )
        external
        whenNotPaused
        whiteListedToken(erc20Address)
        userPlaying(gameId, player1)
        userPlaying(gameId, player2)
    {
        uint256 startedTime = block.timestamp;

        require(betAmount > 0, "Must bet some amount");

        uint256 player1Allowance = IERC20(erc20Address).allowance(
            player1,
            address(this)
        );
        uint256 player2Allowance = IERC20(erc20Address).allowance(
            player2,
            address(this)
        );
        require(
            player1Allowance >= betAmount,
            "Not allowed to manage player1 tokens"
        );
        require(
            player2Allowance >= betAmount,
            "Not allowed to manage player2 tokens"
        );

        _roomIds.increment();
        uint256 roomId = _roomIds.current();

        RoomIdToGameRoom[roomId] = GameRoom(
            player1,
            player2,
            erc20Address,
            betAmount,
            startedTime,
            4,
            false
        );
        RoomIdToProtection[roomId] = Protection(0, 0);

        playerState[gameId][player1] = 1;
        playerState[gameId][player2] = 1;

        emit GameStarted(roomId);
    }

    /**
     * @dev Manage the result
     * @param roomId game room id
     * @param result the the player who press the take button 0->player1, 1->player2, 2->both
     */
    function endGame(uint256 roomId, uint16 result)
        external
        whenNotPaused
        validRoomId(roomId)
        gameRoomClosed(roomId)
    {
        uint256 endedTime = block.timestamp;

        GameRoom storage gameRoom = RoomIdToGameRoom[roomId];

        require(result >= 0 && result <= 2, "Invalid result");
        require(
            gameRoom.startedTime < endedTime &&
                gameRoom.startedTime + gamePeriod >= endedTime,
            "Invalid elapsed time"
        );
        require(
            result != 2 || gameRoom.startedTime + gamePeriod == endedTime,
            "Invalid elapsed time"
        );

        IERC20(gameRoom.erc20Address).transferFrom(
            address(this),
            gameRoom.player1,
            gameRoom.betAmount
        );
        IERC20(gameRoom.erc20Address).transferFrom(
            address(this),
            gameRoom.player2,
            gameRoom.betAmount
        );

        Protection storage protection = RoomIdToProtection[roomId];
        uint256 profit = gameRoom.betAmount *
            pricePerSecond *
            (endedTime - gameRoom.startedTime);

        if (result == 0) {
            if (
                protection.protectTime2 <= endedTime &&
                protection.protectTime2 + protectionPeriod >= endedTime
            ) {
                IERC20(gameRoom.erc20Address).transferFrom(
                    gameRoom.player2,
                    address(this),
                    profit
                );
                gameRoom.result = 1;
            } else {
                IERC20(gameRoom.erc20Address).transferFrom(
                    gameRoom.player1,
                    address(this),
                    profit
                );
                gameRoom.result = 0;
            }
        } else if (result == 1) {
            if (
                protection.protectTime1 <= endedTime &&
                protection.protectTime1 + protectionPeriod >= endedTime
            ) {
                IERC20(gameRoom.erc20Address).transferFrom(
                    gameRoom.player1,
                    address(this),
                    profit
                );
            } else {
                IERC20(gameRoom.erc20Address).transferFrom(
                    gameRoom.player2,
                    address(this),
                    profit
                );
            }
        } else {
            IERC20(gameRoom.erc20Address).transferFrom(
                gameRoom.player1,
                address(this),
                gameRoom.betAmount * 2
            );
            IERC20(gameRoom.erc20Address).transferFrom(
                gameRoom.player2,
                address(this),
                gameRoom.betAmount * 2
            );
        }

        playerState[gameId][gameRoom.player1] = 0;
        playerState[gameId][gameRoom.player2] = 0;
        gameRoom.isClosed = true;

        emit GameEnded(roomId);
    }

    /**
     * @dev Protect for 10 seconds
     * @param roomId game room id
     * @param protector the protector 0->player1, 1->player2
     */
    function Protect(uint256 roomId, uint16 protector)
        external
        whenNotPaused
        validRoomId(roomId)
        gameRoomClosed(roomId)
    {
        uint256 currentTime = block.timestamp;
        require(protector >= 0 && protector <= 1, "Invalid Protector");
        Protection storage protection = RoomIdToProtection[roomId];
        GameRoom storage gameRoom = RoomIdToGameRoom[roomId];
        require(
            gameRoom.startedTime <= currentTime &&
                gameRoom.startedTime + gamePeriod > currentTime,
            "Invalid protection time"
        );
        if (protector == 0) {
            require(
                gameRoom.startedTime <= protection.protectTime1 &&
                    gameRoom.startedTime + gamePeriod > protection.protectTime1,
                "Can't protect more than once in a game"
            );
            protection.protectTime1 = currentTime;
        } else {
            require(
                gameRoom.startedTime <= protection.protectTime2 &&
                    gameRoom.startedTime + gamePeriod > protection.protectTime2,
                "Can't protect more than once in a game"
            );
            protection.protectTime2 = currentTime;
        }
        emit Protected(roomId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/**
@title Common functionality for all marketplace contracts
 */
abstract contract GameTools is Ownable, Pausable {
    using Counters for Counters.Counter;
    using ERC165Checker for address;

    // Amount of tokens a user has for sale, per contract and per tokenId
    mapping(uint256 => mapping(address => uint256)) public playerState;
    Counters.Counter internal _roomIds;
    // Commission percentage for all sales
    uint256 public commissionPercent = 1;
    // List of ERC20 token addresses which are allowed to be used
    mapping(address => bool) public whitelistedERC20;

    /**
     * @dev Initializes the contract
     * @param erc20TokenAddresses List of ERC20 tokens to be whitelisted initially
     */
    constructor(address[] memory erc20TokenAddresses) {
        for (uint256 i = 0; i < erc20TokenAddresses.length; i++) {
            whitelistedERC20[erc20TokenAddresses[i]] = true;
        }
    }

    /**
     * @dev whiteListedToken modifier
     * @param erc20Address token address
     */
    modifier whiteListedToken(address erc20Address) {
        require(whitelistedERC20[erc20Address], "Invalid price token");
        _;
    }

    /**
     * @dev userPlaying modifier
     * @param gameId Game Id
     * @param userAddress address of a user
     */
    modifier userPlaying(uint16 gameId, address userAddress) {
        require(
            playerState[gameId][userAddress] == 0,
            "Player1 is playing a game"
        );
        _;
    }

    /**
     * @dev validRoomId modifier
     * @param roomId Id of game room
     */
    modifier validRoomId(uint256 roomId) {
        require(
            roomId <= _roomIds.current() && roomId >= 0,
            "Game room doesn't exist"
        );
        _;
    }

    /**
     * @dev Adds an ERC20 token to the whitelist
     * @param erc20TokenAddress The address of the token
     */
    function addToWhitelist(address erc20TokenAddress) public onlyOwner {
        whitelistedERC20[erc20TokenAddress] = true;
    }

    /**
     * @dev Removes an ERC20 token from the whitelist
     * @param erc20TokenAddress The address of the token
     */
    function removeFromWhitelist(address erc20TokenAddress) public onlyOwner {
        whitelistedERC20[erc20TokenAddress] = false;
    }

    /**
     * @dev Gets the latest listingId used in the contract
     * @return uint256 listingId
     */
    function getLatestRoomId() public view returns (uint256) {
        return _roomIds.current();
    }

    /**
     * @dev Returns the price after the given percentage has been deducted
     * @param price The original price
     * @param percent How big percentage should be deducted
     */
    function getPriceAfterPercent(uint256 price, uint256 percent)
        public
        pure
        returns (uint256)
    {
        uint256 _percent = percent;
        return (price * _percent) / 100;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.2) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}