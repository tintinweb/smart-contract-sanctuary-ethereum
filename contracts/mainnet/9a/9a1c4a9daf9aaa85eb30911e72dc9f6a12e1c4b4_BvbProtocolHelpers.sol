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
pragma solidity >=0.8.4;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {IBvbProtocol} from "../interfaces/IBvbProtocol.sol";

contract BvbProtocolHelpers is Ownable {
    address public bvb;

    constructor(address _bvb) {
        bvb = _bvb;
    }

    /**
     * @notice Check if this Order (with his signature) can be matched on BvbProtocol
     * @param order The BvbProtocol Order
     * @param signature The signature of the Order hashed
     * @return true If BvbProtocol.checkIsValidOrder() doesn't revert and that BvbProtocol can retrieve enough assets from the maker
     */
    function isValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        return requireIsValidOrder(order, signature) && hasAllowanceOrder(order);
    }

    /**
     * @notice Check if this Order (with his signature) is valid for BvbProtocol
     * @param order The BvbProtocol Order
     * @param signature The signature of the Order hashed
     * @return true If BvbProtocol.checkIsValidOrder() doesn't revert
     */
    function requireIsValidOrder(IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidOrder(order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    /**
     * @notice Check if this maker has enough (approved) assets
     * @param order The BvbProtocol Order
     * @return true BvbProtocol can retrieve enough assets from the maker
     */
    function hasAllowanceOrder(IBvbProtocol.Order calldata order) public view returns (bool) {
        uint makerAllowance = IERC20(order.asset).allowance(order.maker, bvb);

        uint makerBalance = IERC20(order.asset).balanceOf(order.maker);

        uint makerPrice = getMakerPrice(order);

        return makerBalance >= makerPrice && makerAllowance >= makerPrice;
    }

    /**
     * @notice Check if this SellOrder (with his signature) can be used on BvbProtocol
     * @param sellOrder The BvbProtocol SellOrder
     * @param order The BvbProtocol SellOrder
     * @param signature The signature of the SellOrder hashed
     * @return true If BvbProtocol.checkIsValidSellOrder() doesn't revert
     */
    function isValidSellOrder(IBvbProtocol.SellOrder calldata sellOrder, IBvbProtocol.Order calldata order, bytes calldata signature) public view returns (bool) {
        bytes32 orderHash = IBvbProtocol(bvb).hashOrder(order);
        bytes32 sellOrderHash = IBvbProtocol(bvb).hashSellOrder(sellOrder);

        bool isValid;
        try IBvbProtocol(bvb).checkIsValidSellOrder(sellOrder, sellOrderHash, order, orderHash, signature) {
            isValid = true;
        } catch (bytes memory) {}

        return isValid;
    }

    /**
     * @notice Check if these Orders (with their signatures) can be matched on BvbProtocol
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of Orders hashed
     * @return Array of boolean, result of isValidOrder() call on each Order
     */
    function areValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = isValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    /**
     * @notice Check if these Orders (with their signatures) are valid on BvbProtocol
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of Orders hashed
     * @return Array of boolean, result of requireIsValidOrder() call on each Order
     */
    function requireAreValidOrders(IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");

        bool[] memory validityOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validityOrders[i] = requireIsValidOrder(orders[i], signatures[i]);
        }

        return validityOrders;
    }

    /**
     * @notice Check if Orders' makers have enough (approved) assets
     * @param orders BvbProtocol Orders
     * @return Array of boolean, result of hasAllowanceOrder() call on each Order
     */
    function haveAllowanceOrders(IBvbProtocol.Order[] calldata orders) public view returns (bool[] memory) {
        bool[] memory allowanceOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            allowanceOrders[i] = hasAllowanceOrder(orders[i]);
        }

        return allowanceOrders;
    }

    /**
     * @notice Check if these SellOrders (with their signatures) can be used on BvbProtocol
     * @param sellOrders BvbProtocol SellOrders
     * @param orders BvbProtocol Orders
     * @param signatures Signatures of SellOrders hashed
     * @return Array of boolean, result of isValidSellOrder() call on each SellOrder/Order
     */
    function areValidSellOrders(IBvbProtocol.SellOrder[] calldata sellOrders, IBvbProtocol.Order[] calldata orders, bytes[] calldata signatures) public view returns (bool[] memory) {
        require(orders.length == signatures.length, "INVALID_ORDERS_COUNT");
        require(orders.length == sellOrders.length, "INVALID_SELL_ORDERS_COUNT");

        bool[] memory validitySellOrders = new bool[](orders.length);
        for (uint i; i<orders.length; i++) {
            validitySellOrders[i] = isValidSellOrder(sellOrders[i], orders[i], signatures[i]);
        }

        return validitySellOrders;
    }

    /**
     * @notice Retrieve the amount of asset to be paid by the maker (fees included)
     * @param order BvbProtocol Order
     * @return Amount to be paid by the maker for this Order
     */
    function getMakerPrice(IBvbProtocol.Order calldata order) public view returns (uint) {
        uint16 fee = IBvbProtocol(bvb).fee();

        uint makerPrice;
        if (order.isBull) {
            makerPrice = order.collateral + (order.collateral * fee) / 1000;
        } else {
            makerPrice = order.premium + (order.premium * fee) / 1000;
        }

        return makerPrice;
    }

    /**
     * @notice Retrieve the amount of asset to be paid by the taker (fees included)
     * @param order BvbProtocol Order
     * @return Amount to be paid by the taker for this Order
     */
    function getTakerPrice(IBvbProtocol.Order calldata order) public view returns (uint) {
        uint16 fee = IBvbProtocol(bvb).fee();

        uint takerPrice;
        if (order.isBull) {
            takerPrice = order.premium + (order.premium * fee) / 1000;
        } else {
            takerPrice = order.collateral + (order.collateral * fee) / 1000;
        }

        return takerPrice;
    }

    /**
     * @notice Set the new BvbProtocol address
     * @param _bvb BvbProtocol address
     */
    function setBvb(address _bvb) public onlyOwner {
        bvb = _bvb;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IBvbProtocol {
    struct Order {
        uint premium;
        uint collateral;
        uint validity;
        uint expiry;
        uint nonce;
        uint16 fee;
        address maker;
        address asset;
        address collection;
        bool isBull;
    }

    struct SellOrder {
        bytes32 orderHash;
        uint price;
        uint start;
        uint end;
        uint nonce;
        address maker;
        address asset;
        address[] whitelist;
        bool isBull;
    }

    function fee() external view returns (uint16);

    function hashOrder(Order memory order) external view returns (bytes32);

    function hashSellOrder(SellOrder memory sellOrder) external view returns (bytes32);

    function checkIsValidOrder(Order calldata order, bytes32 orderHash, bytes calldata signature) external view;

    function checkIsValidSellOrder(SellOrder calldata sellOrder, bytes32 sellOrderHash, Order memory order, bytes32 orderHash, bytes calldata signature) external view;
}