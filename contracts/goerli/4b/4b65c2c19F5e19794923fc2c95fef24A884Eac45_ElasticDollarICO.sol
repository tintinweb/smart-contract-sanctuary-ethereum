// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { IERC20 } from "./interfaces/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { PaymentSplitter } from "./finance/PaymentSplitter.sol";
import { SafeERC20 } from "./libraries/SafeERC20.sol";

error PausedICOError();
error WrongTokenError();
error WrongBuyAmoutError(uint256);

contract ElasticDollarICO is Ownable, PaymentSplitter {
    using SafeERC20 for IERC20;

    mapping (address => bool) public purchaseTokens;
    address public quoteToken;
    uint256 public price = 1e6;
    uint256 public minBuyAmount = 100 * 1e6;
    uint32 public nativePrice;
    bool public isOn;

    constructor(
        address payable ownerAddress, address payable devAddress, uint8 ownerShare,
        address _quoteToken
    ) PaymentSplitter(ownerAddress, devAddress, ownerShare) {
        quoteToken = _quoteToken;

        transferOwnership(ownerAddress);
    }

    function setQuoteToken(address _quoteToken) external onlyOwner {
        quoteToken = _quoteToken;
    }

    function setPurchaseToken(address _purchaseToken, bool _isPurchaseToken) external onlyOwner {
        if (!_isPurchaseToken) {
            delete purchaseTokens[_purchaseToken];
        }
        purchaseTokens[_purchaseToken] = _isPurchaseToken;
    }

    function setPrice(uint256 _price) external onlyOwner {
        price = _price;
    }

    function setMinBuyAmount(uint32 amount) external onlyOwner {
        minBuyAmount = amount;
    }

    function setNativePrice(uint32 _price) external onlyOwner {
        nativePrice = _price;
    }

    function setState(bool _isOn) external onlyOwner {
        isOn = _isOn;
    }

    function deposit(uint256 amount) external onlyOwner {
        IERC20(quoteToken).safeTransferFrom(_msgSender(), address(this), amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            (bool success, ) = payable(_msgSender()).call{ value: amount }("");
            require(success, "");
        } else {
            IERC20(token).safeTransfer(_msgSender(), amount);
        }
    }

    function calculateQuoteAmount(uint256 amount) public view returns(uint256) {
        return amount * 1e9 / price;
    }

    function _buy(address recipient) private {
        uint256 amount = (msg.value * nativePrice) / 1e14;
        if (amount < minBuyAmount) revert WrongBuyAmoutError(minBuyAmount);

        splitPayment();

        uint256 quoteAmount = calculateQuoteAmount(amount);
        IERC20(quoteToken).safeTransfer(recipient, quoteAmount);
    }

    function _buy(address token, uint256 amount, address recipient) private {
        if (!purchaseTokens[token]) revert WrongTokenError();
        if (amount < minBuyAmount) revert WrongBuyAmoutError(minBuyAmount);

        IERC20(token).safeTransferFrom(_msgSender(), address(this), amount);
        splitPayment(token);

        uint256 quoteAmount = calculateQuoteAmount(amount);
        IERC20(quoteToken).safeTransfer(recipient, quoteAmount);
    }

    function buy(address token, uint256 amount, address recipient) public payable {
        if (!isOn) revert PausedICOError();

        if (token == address(0)) {
            return _buy(recipient);
        }
        _buy(token, amount, recipient);
    }

    receive() external payable {
        _buy(_msgSender());
    }

    fallback () external payable {
        _buy(_msgSender());
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
pragma solidity ^0.8.10;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { IERC20 } from "../interfaces/IERC20.sol";
import { SafeERC20 } from "../libraries/SafeERC20.sol";

error NotRoleOwner(address);
error WrongShareAmount();

contract PaymentSplitter is Context {
    using SafeERC20 for IERC20;

    struct ShareRequest {
        uint8 ownerSideOwnerShare;
        uint8 devSideOwnerShare;
    }

    enum Roles {
        owner,
        dev
    }

    address payable public ownerAddress;
    address payable public devAddress;

    uint8 public ownerShare;

    ShareRequest public changeShareRequest;

    constructor(address payable _ownerAddress, address payable _devAddress, uint8 _ownerShare) {
        ownerAddress = _ownerAddress;
        devAddress = _devAddress;
        ownerShare = _ownerShare;
    }

    function changeAccount(address payable account, Roles role) external {
        if (role == Roles.owner) {
            if (_msgSender() != ownerAddress) revert NotRoleOwner(ownerAddress);
            ownerAddress = account;
        } else if (role == Roles.dev) {
            if (_msgSender() != devAddress) revert NotRoleOwner(devAddress);
            devAddress = account;
        }
    }

    function changeOwnerShare(uint8 share) external {
        if (share >= 100) revert WrongShareAmount();

        address from = _msgSender();
        if (from == ownerAddress) {
            changeShareRequest.ownerSideOwnerShare = share;
        } else if (from == devAddress) {
            changeShareRequest.devSideOwnerShare = share;
        } else {
            revert NotRoleOwner(from);
        }

        if (changeShareRequest.ownerSideOwnerShare == changeShareRequest.devSideOwnerShare) {
            ownerShare = share;
        }
    }

    function calculateAmounts(uint256 amount) private view returns(uint256 ownerAmount, uint256 devAmount) {
        ownerAmount = amount * ownerShare / 100;
        devAmount = amount - ownerAmount;
    }

    function splitPayment() internal {
        uint256 amount = address(this).balance;

        (uint256 ownerAmount, uint256 devAmount) = calculateAmounts(amount);

        (bool successOwner, ) = ownerAddress.call{ value: ownerAmount }("");
        (bool successDev, ) = devAddress.call{ value: devAmount }("");
        require(successOwner && successDev, "");
    }

    function splitPayment(address token) internal {
        uint256 amount = IERC20(token).balanceOf(address(this));

        uint256 ownerAmout = amount * ownerShare / 100;
        uint256 devAmount = amount - ownerAmout;

        IERC20(token).safeTransfer(ownerAddress, ownerAmout);
        IERC20(token).safeTransfer(devAddress, devAmount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
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