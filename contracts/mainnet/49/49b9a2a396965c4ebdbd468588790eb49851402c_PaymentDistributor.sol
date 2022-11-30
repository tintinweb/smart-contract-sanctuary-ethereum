// Copyright (c) 2022 Fellowship
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice (including the next paragraph) shall be included in all copies
// or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

// SPDX-License-Identifier: MIT
// Copyright (c) 2022 Fellowship

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Payment Distributor
/// @notice Distributes tokens to payees according to their shares
/// @dev While `owner` already has full control, this contract uses `ReentrancyGuard` to prevent any footgun shenanigans
///  that could result from calling `setShares` during `withdraw`
contract PaymentDistributor is Ownable, ReentrancyGuard {
    uint256 private shareCount;
    address[] private payees;
    mapping(address => PayeeInfo) private payeeInfo;

    struct PayeeInfo {
        uint128 index;
        uint128 shares;
    }

    error NoBalance();
    error PaymentsNotConfigured();
    error OnlyPayee();
    error FailedPaying(address payee, bytes data);

    /// @dev Check that caller is owner or payee
    modifier onlyPayee() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        if (msg.sender != owner()) {
            // Get the stored index for the sender
            uint256 index = payeeInfo[msg.sender].index;
            // Check that they are actually at that index
            if (payees[index] != msg.sender) revert OnlyPayee();
        }

        _;
    }

    modifier paymentsConfigured() {
        if (shareCount == 0) revert PaymentsNotConfigured();
        _;
    }

    receive() external payable {}

    // PAYEE FUNCTIONS

    /// @notice Distributes the balance of this contract to the `payees`
    function withdraw() external onlyPayee nonReentrant {
        // CHECKS: don't bother with zero transfers
        uint256 shareSplit = address(this).balance / shareCount;
        if (shareSplit == 0) revert NoBalance();

        // INTERACTIONS
        bool success;
        bytes memory data;
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];
            unchecked {
                (success, data) = payee.call{value: shareSplit * payeeInfo[payee].shares}("");
            }
            if (!success) revert FailedPaying(payee, data);
        }
    }

    /// @notice Distributes tokens held by this contract to the `payees`
    function withdrawToken(IERC20 token) external onlyPayee nonReentrant {
        // CHECKS inputs
        require(address(token).code.length > 0, "Token address must be a contract");
        // INTERACTIONS: external call to get token balance, then pass off to _withdrawToken for the transfers
        _withdrawToken(token, token.balanceOf(address(this)));
    }

    /// @notice Distributes a fixed number of tokens held by this contract to the `payees`
    /// @dev Safety measure for exotic ERC20 contracts that charge a fee in addition to transfer, or other cases where
    ///  the whole balance may not be transferable.
    function withdrawToken(IERC20 token, uint256 balance) external onlyPayee nonReentrant {
        // CHECKS inputs
        require(address(token).code.length > 0, "Token address must be a contract");
        // INTERACTIONS: pass off to _withdrawToken for transfers
        _withdrawToken(token, balance);
    }

    // OWNER FUNCTIONS

    /// @notice Sets `payees_` who receive funds from this contract in accordance with shares in the `shares` array
    /// @dev `payees_` and `shares` must have the same length and non-zero values
    function setShares(address[] calldata payees_, uint128[] calldata shares) external onlyOwner nonReentrant {
        // CHECKS inputs
        require(payees_.length > 0, "Must set at least one payee");
        require(payees_.length < type(uint128).max, "Too many payees");
        require(payees_.length == shares.length, "Payees and shares must have the same length");

        // CHECKS + EFFECTS: check each payee before setting values
        shareCount = 0;
        payees = payees_;
        unchecked {
            // Unchecked arithmetic: already checked that the number of payees is less than uint128 max
            for (uint128 i = 0; i < payees_.length; i++) {
                address payee = payees_[i];
                uint128 payeeShares = shares[i];
                require(payee != address(0), "Payees must not be the zero address");
                require(payeeShares > 0, "Payees shares must not be zero");

                // Unchecked arithmetic: since number of payees is less than uint128 max and share values are uint128,
                // `shareCount` cannot exceed uint256 max.
                shareCount += payeeShares;
                PayeeInfo storage info = payeeInfo[payee];
                info.index = i;
                info.shares = payeeShares;
            }
        }
    }

    // PRIVATE FUNCTIONS

    function _withdrawToken(IERC20 token, uint256 balance) private {
        // CHECKS: don't bother with zero transfers
        uint256 shareSplit = balance / shareCount;
        if (shareSplit == 0) revert NoBalance();

        // INTERACTIONS
        for (uint256 i = 0; i < payees.length; i++) {
            address payee = payees[i];

            // Based on token/ERC20/utils/SafeERC20.sol and utils/Address.sol from OpenZeppelin Contracts v4.7.0
            (bool success, bytes memory data) = address(token).call(
                abi.encodeWithSelector(token.transfer.selector, payee, shareSplit * payeeInfo[payee].shares)
            );
            if (!success) {
                if (data.length > 0) revert FailedPaying(payee, data);
                revert FailedPaying(payee, "Transfer reverted");
            } else if (data.length > 0 && !abi.decode(data, (bool))) {
                revert FailedPaying(payee, "Transfer failed");
            }
        }
    }
}

// OpenZeppelin Contracts
//
// Copyright (c) 2016-2022 zOS Global Limited and contributors
//
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

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