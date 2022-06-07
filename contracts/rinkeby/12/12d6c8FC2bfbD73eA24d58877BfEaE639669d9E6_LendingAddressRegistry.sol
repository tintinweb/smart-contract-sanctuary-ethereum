// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/ILendingAddressRegistry.sol";

contract LendingAddressRegistry is Ownable, ILendingAddressRegistry {
    using Counters for Counters.Counter;

    /// @notice lending contract
    bytes32 public constant LENDING_MARKET = "LENDING_MARKET";
    /// @notice token price oracle aggregator
    bytes32 public constant PRICE_ORACLE_AGGREGATOR = "PRICE_ORACLE_AGGREGATOR";
    /// @notice treasury address (10% of liquidation penalty + 20% of interest + borrow fee)
    bytes32 public constant TREASURY = "TREASURY";
    /// @notice staking address (40% of liquidation penalty + 80% of interest + borrow fee)
    bytes32 public constant STAKING = "STAKING";
    /// @notice stability pool
    bytes32 public constant STABLE_POOL = "STABLE_POOL";
    /// @notice swapper contract
    bytes32 public constant SWAPPER = "SWAPPER";

    mapping(bytes32 => address) private _addresses;

    Counters.Counter private _keeperIndexTracker;
    mapping(uint256 => address) private _keepers;
    mapping(address => bool) private _isKeeper;

    constructor() Ownable() {}

    // Set up all addresses for the registry.
    function initialize(
        address lendingMarket,
        address priceOracleAggregator,
        address treasury,
        address staking,
        address stablePool,
        address swapper
    ) external override onlyOwner {
        _addresses[LENDING_MARKET] = lendingMarket;
        _addresses[PRICE_ORACLE_AGGREGATOR] = priceOracleAggregator;
        _addresses[TREASURY] = treasury;
        _addresses[STAKING] = staking;
        _addresses[STABLE_POOL] = stablePool;
        _addresses[SWAPPER] = swapper;
    }

    function getLendingMarket() external view override returns (address) {
        return _addresses[LENDING_MARKET];
    }

    function setLendingMarket(address lendingMarket)
        external
        override
        onlyOwner
    {
        _addresses[LENDING_MARKET] = lendingMarket;
    }

    function getPriceOracleAggregator() external view returns (address) {
        return _addresses[PRICE_ORACLE_AGGREGATOR];
    }

    function setPriceOracleAggregator(address priceOracleAggregator) external {
        _addresses[PRICE_ORACLE_AGGREGATOR] = priceOracleAggregator;
    }

    function getTreasury() external view override returns (address) {
        return _addresses[TREASURY];
    }

    function setTreasury(address treasury) external override onlyOwner {
        _addresses[TREASURY] = treasury;
    }

    function getStaking() external view override returns (address) {
        return _addresses[STAKING];
    }

    function setStaking(address staking) external override onlyOwner {
        _addresses[STAKING] = staking;
    }

    function getStablePool() external view override returns (address) {
        return _addresses[STABLE_POOL];
    }

    function setStablePool(address stablePool) external override onlyOwner {
        _addresses[STABLE_POOL] = stablePool;
    }

    function getSwapper() external view override returns (address) {
        return _addresses[SWAPPER];
    }

    function setSwapper(address swapper) external override onlyOwner {
        _addresses[SWAPPER] = swapper;
    }

    function getKeepers() external view override returns (address[] memory) {
        uint256 length = _keeperIndexTracker.current();
        address[] memory keepers = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            keepers[i] = _keepers[i];
        }

        return keepers;
    }

    function addKeeper(address keeper) external override onlyOwner {
        _keepers[_keeperIndexTracker.current()] = keeper;
        _keeperIndexTracker.increment();
        _isKeeper[keeper] = true;
    }

    function isKeeper(address keeper) external view override returns (bool) {
        return _isKeeper[keeper];
    }

    function getAddress(bytes32 id) external view override returns (address) {
        return _addresses[id];
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

interface ILendingAddressRegistry {
    function initialize(
        address lendingMarket,
        address priceOracleAggregator,
        address treasury,
        address staking,
        address stablePool,
        address swapper
    ) external;

    function getLendingMarket() external view returns (address);

    function setLendingMarket(address lendingMarket) external;

    function getPriceOracleAggregator() external view returns (address);

    function setPriceOracleAggregator(address priceOracleAggregator) external;

    function getTreasury() external view returns (address);

    function setTreasury(address treasury) external;

    function getStaking() external view returns (address);

    function setStaking(address staking) external;

    function getStablePool() external view returns (address);

    function setStablePool(address stablePool) external;

    function getSwapper() external view returns (address);

    function setSwapper(address swapper) external;

    function getKeepers() external view returns (address[] memory);

    function addKeeper(address keeper) external;

    function isKeeper(address keeper) external view returns (bool);

    function getAddress(bytes32 id) external view returns (address);
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