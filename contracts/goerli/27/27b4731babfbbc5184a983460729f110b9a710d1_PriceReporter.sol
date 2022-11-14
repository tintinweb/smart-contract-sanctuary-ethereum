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

pragma solidity 0.8.15;

import {Ownable} from "openzeppelin/access/Ownable.sol";

interface IPriceFeed {
    function postPrice(address token, uint256 price) external;
}

interface IOrderManager {
    function executeOrders(uint256[] calldata _key, address payable _feeTo) external;
}

/**
 * @title PriceReporter
 * @notice Utility contract to call post prices and execute orders on a single transaction. Used on
 * testnet only
 */
contract PriceReporter is Ownable {
    IPriceFeed private immutable oracle;
    IOrderManager private immutable orderManager;
    mapping(address => bool) public isReporter;
    address[] public reporters;

    constructor(address _oracle, address _orderManager) {
        require(_oracle != address(0), "PriceReporter:invalidOracle");
        require(_orderManager != address(0), "PriceReporter:invalidPositionManager");
        oracle = IPriceFeed(_oracle);
        orderManager = IOrderManager(_orderManager);
    }

    function postPriceAndExecuteOrders(
        address[] calldata tokens,
        uint256[] calldata prices,
        uint256[] calldata orders
    ) external {
        require(isReporter[msg.sender], "PriceReporter:unauthorized");
        require(tokens.length == prices.length, "PriceReporter:invalidTokenPricesData");
        for (uint256 i = 0; i < tokens.length; i++) {
            oracle.postPrice(tokens[i], prices[i]);
        }

        if (orders.length > 0) {
            orderManager.executeOrders(orders, payable(msg.sender));
        }
    }

    function addReporter(address reporter) external onlyOwner {
        require(reporter != address(0), "PriceReporter:invalidAddress");
        require(!isReporter[reporter], "PriceReporter:reporterAlreadyAdded");
        isReporter[reporter] = true;
        reporters.push(reporter);
    }

    function removeReporter(address reporter) external onlyOwner {
        require(isReporter[reporter], "PriceReporter:reporterNotExists");
        isReporter[reporter] = false;
        for (uint256 i = 0; i < reporters.length; i++) {
            if (reporters[i] == reporter) {
                reporters[i] = reporters[reporters.length - 1];
                break;
            }
        }
        reporters.pop();
    }
}