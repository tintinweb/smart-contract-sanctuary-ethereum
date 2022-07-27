//SPDX-License-Identifier:MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

/// @title Whitelist Contract
/// @author Yanuka Deneth
/// @notice This a contract which stores whitelist members and only enable them to do particular activities
contract Whitelist is Ownable {
    /// @dev Using the Counter library for current whitelist ID
    using Counters for Counters.Counter;

    /// @notice Holds the Max number of whitelists possible
    /// @dev Can only hold 255 values
    uint8 public maxWhitelistedAddresses;

    /// @notice Holds the current number of whitelists
    Counters.Counter private currentWhitelistcount;

    /// @notice Mapping of Addressess to whether they are whitelisted
    /// @dev true = is a whitelist
    mapping(address => bool) whitelistmap;

    /// @notice Emitted when users get added to whitelist, with the address
    event userWhitelisted(address indexed _address);

    /// @notice Emitted when a user was removed from whitelist
    event userRemoved(address indexed _address);

    /// @notice Sets the Maximum whitelists available
    /// @param _maxWhitelistedAddresses Number less than 255, greater than 1
    constructor(uint8 _maxWhitelistedAddresses) {
        require(
            _maxWhitelistedAddresses > 1 && _maxWhitelistedAddresses < 255,
            "Number not within bounds"
        );
        maxWhitelistedAddresses = _maxWhitelistedAddresses;
    }

    /// @notice Is address a whitelist member?
    /// @param _address An Address to check if the address is a whitelist
    /// @return A boolean, if true, the address is a whitelist
    function isWhitelisted(address _address) external view returns (bool) {
        return whitelistmap[_address];
    }

    /// @notice Adds the calling Address as a whitelist provided there are available spots
    function joinWhitelist() external {
        require(!whitelistmap[msg.sender], "Address already a whitelist");
        require(
            currentWhitelistcount.current() < maxWhitelistedAddresses,
            "Max Whitelist amount reached!"
        );
        whitelistmap[msg.sender] = true;
        currentWhitelistcount.increment();
        emit userWhitelisted(msg.sender);
        assert(whitelistmap[msg.sender]);
    }

    /// @notice Removes the address from whitelist
    /// @dev Can be called only by owner
    function removeWhitelist(address _address) external onlyOwner {
        require(whitelistmap[_address], "Address not a whitelist!");
        delete whitelistmap[_address];
        currentWhitelistcount.decrement();
        emit userRemoved(_address);
        assert(!whitelistmap[_address]);
    }

    /// @notice Gets the current amount of whitelist taken
    function getNumberOfWhitelist() external view returns (uint256) {
        return currentWhitelistcount.current();
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