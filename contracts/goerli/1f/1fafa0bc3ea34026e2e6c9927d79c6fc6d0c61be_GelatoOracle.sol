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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/access/Ownable.sol';
import './interfaces/IOracle.sol';

contract GelatoOracle is IOracle, Ownable {
    PriceData lastPrice;
    /// @notice min price deviation to accept a price update
    uint256 public deviation;
    address public dataProvider;
    uint8 _decimals;
    /// @notice heartbeat duration in seconds
    uint40 public heartBeat;

    modifier ensurePriceDeviation(uint256 newValue) {
        if (_computeDeviation(newValue) > deviation) {
            _;
        }
    }

    function _computeDeviation(
        uint256 newValue
    ) internal view returns (uint256) {
        if (lastPrice.price == 0) {
            return deviation + 1; // return the deviation amount if price is 0, so that the update will happen
        } else if (newValue > lastPrice.price) {
            return ((newValue - lastPrice.price) * 1e20) / lastPrice.price;
        } else {
            return ((lastPrice.price - newValue) * 1e20) / lastPrice.price;
        }
    }

    constructor() {}

    function initialize(
        uint256 deviation_,
        uint8 decimals_,
        uint40 heartBeat_,
        address dataProvider_
    ) external {
        _decimals = decimals_;
        deviation = deviation_;
        heartBeat = heartBeat_;
        dataProvider = dataProvider_;
        _transferOwnership(msg.sender);
    }

    // to be called by gelato bot to know if a price update is needed
    function isPriceUpdateNeeded(
        uint256 newValue
    ) external view returns (bool) {
        if ((lastPrice.timestamp + heartBeat) < block.timestamp) {
            return true;
        } else if (_computeDeviation(newValue) > deviation) {
            return true;
        }
        return false;
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function setPrice(uint256 _value) external onlyOwner {
        lastPrice.price = uint128(_value);
        lastPrice.timestamp = uint128(block.timestamp);

        emit NewValue(lastPrice.price, lastPrice.timestamp);
    }

    function getPrice() external view override returns (PriceData memory) {
        return lastPrice;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}