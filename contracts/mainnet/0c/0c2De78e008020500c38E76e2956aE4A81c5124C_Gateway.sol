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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

/// @title ergonomic and robust utility functions to set and reset allowances in a safe way
library ApproveUtils {
        using Address for address;
        using SafeERC20 for IERC20;

        /// @notice ERC20 safeApprove
        /// @dev Gives `spender` allowance to transfer `requiredAmount` of `token` held by this contract
        function safeApproveImproved(IERC20 token, address spender, uint256 requiredAmount) internal {
                uint256 allowance = token.allowance(address(this), spender);

                // only change allowance if we don't have enough of it already
                if (allowance >= requiredAmount) return;

                if (allowance == 0) {
                        // safeApprove works only if trying to set to 0 or current allowance is 0
                        token.safeApprove(spender, requiredAmount);
                        return;
                }

                // current allowance != 0 and less than the required amount
                // first try to set it to the required amount
                try token.approve(spender, requiredAmount) returns (bool result) {
                        // check return status safeApprove() does this for us, but not approve()
                        require(result, 'failed to approve spender');
                } catch {
                        // Probably a non standard ERC20, like USDT

                        // set allowance to 0
                        token.safeApprove(spender, 0);
                        // set allowance to required amount
                        token.safeApprove(spender, requiredAmount);
                }
        }

        /// @dev Reset ERC20 allowance to 0
        function zeroAllowance(IERC20 token, address spender) internal {
                // if already 0 don't do anything (can't be less than 0 because uint)
                if (token.allowance(address(this), spender) == 0) return;

                token.safeApprove(spender, 0);

                require(token.allowance(address(this), spender) == 0, 'failed to zero allowance');
        }
}

// SPDX-License-Identifier: AGPL-3.0

/*

 Used only by [swappin.gifts](https://swappin.gifts]) to accept payments in any token or native coin.
 We've designed this contract to be non-upgradable. Once the contract has been deployed to the blockchain, it will never change.
 This guarantee, as provided by the blockchain, together with the complete source code of the contract, will allow any party to verify the security properties and guarantees.
 By putting security and transparency first, we hope to pave the way for a more trustless and trustable ecosystem.
 Clara pacta, boni amici.


                                                             =;                                                                                                 
                                                            ;@f     `z.                                                                                         
                                                           [email protected]@o    *QR                                                                                          
                                                          [email protected]@@*`^[email protected]@~                                                                                          
                               `!vSjv*.                 [email protected]@@@%@@@@@B;;~~~:,,'`` `,.                                                                            
                           `^[email protected]@@}    :i      ``...';[email protected]@@@@@@@@@@@@@@@@@@@@@@@@QY;~'`                                                                         
                        :[email protected]@@@@@@Wi*[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@QNKa7<;,.     `                                                         
                      [email protected]@@@@@@@@@@@@@@@@@@@@@@DXUd&@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@@Qm<`                                                         
                      [email protected]@@[email protected]@@@@@@@@@@@@@@@Qf;,`,[email protected]@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@@@@@@@@@@@@@@NESE%@@@Q86}|~`                                                  
                       @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@[email protected]%[email protected]@@@[email protected]@@@@@@@@@@@@@QE=.                                              
                       [email protected]@b;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&hz?!^[email protected]@@@@@@@Q&#%[email protected]@@@@@@@@@@@@@@@@@@q*.                                           
                       '[email protected]@`[email protected]@@@@@@@@@@@@@@@@@@@@@@@@@Qbj\r,``;fDQQQWE|;,~~~~,[email protected]@@@[email protected]@@@@@@@@@@@@@@@@@Bj+`                                       
                        '[email protected] |~`qf .~wbDDgWD%[email protected]@@@@@@@@@@@@@@@@@@@QWEL,7yjz+,   ,?7yXqUSc;.~?}[email protected]|=*s}yZShXqDDy?^'                                   
                         `[email protected]*    ~   ,[email protected]@@@@@[email protected]@@@@@@@@@@@@@@@@@@@@@@@[email protected]@@@@[email protected]@@@@@@@Qw^Z6yc;   ,\i>~'[email protected]@@@@@@@@@W%D%j!                               
                           ^Q|      ;[email protected]@@@@QDk<@@@@@@@@@@@@@@@[email protected]@@@@@[email protected]@@@@@@Q*}@@@@@@@z`[email protected]@@@E,'|{XQQa=*[email protected]@@[email protected]@@@@@@@@@bAQQ^                             
                            `\i`  [email protected]@@@@DDQQ^[email protected]@@@@@[email protected]@@kT=vi^>[email protected]@@@@{@@@@@@Y``[email protected]@@@@@j ,@@@@@@@^:QgJ~~^^`'[email protected]@[email protected]@@@@@@@@@@[email protected]`                           
                               `;[email protected]@@@#[email protected]; [email protected]@@@@@@@P,Bi`[email protected]@{[email protected]@@@[email protected]@@@%i` [email protected]@@@87'`[email protected]@@@@@@@j [email protected]@@6,`:   `^[email protected]@@@@@@@@@@Q;                          
                              ,[email protected]@@@[email protected]`  ;@@@@@@@@@Qi  [email protected]+%[email protected]@@[email protected]#J_~<[email protected]%qX*[email protected]@@@@@@@Qi'}@@@@@Q ;Nx.   '`'r^':^|[email protected]@d;                        
                          `[email protected]@@@o^[email protected]: *@@@@@gSoLvEy   ?f\[email protected]@RLi5*''<aR8BNkjz^!yD%[email protected]@@@@@@7 '[email protected]@E``;[email protected]>~DNQQQNDdaLu\`                     
                        [email protected]@[email protected]@hsBhQI`[email protected]@@@@@@[email protected]@~     [email protected],     !R67^,     .\aEZs|!, 'iUg#%Ayz|;`[email protected]@@@@8 ;%}[email protected]@@[email protected]@@@@@@@@U|EK*`                  
                      ,[email protected]@@@;@#[email protected][email protected]@@%@@@@@j7QQf_ {    ;Dg6E%%Wq<      .r`        `,`       ~XE7^_,[email protected]@@@@@@@@, [email protected];j*[email protected]@[email protected]@@@@@@@@@@%[email protected];                 
                   ~*[email protected]@@@@@~^[email protected]' [email protected]@@@@@d}n8m~       `6D~:IQQs'                             '        .^[email protected]@@@Q%c  }@@Q.  `[email protected]@@@@@@@@@@@@@@;                
                  [email protected]'@@@@@Q^[email protected]    `~;;^=7T~          D\  DD!                                               ;xi?<*[email protected]@@@k j:  ~ugQQ#@@@@@@@@@@Q`               
                [email protected]@d*@@@QRxQ?                       .=  ^!                                                  `[email protected]@@@@@@^ [email protected]`XE+.\wc;;*[email protected]@@Q,              
               i} [email protected]@@w^gk8%m;                            `                                                       .;?vz|. `[email protected]@d`[email protected][email protected]@Qz}@@Q%DKDQE,            
             .K7 '[email protected]@@@'.QQ;L                                                                                      [email protected]@@@@,a^[email protected]@@[email protected]@@@@@@@K'           
            ~Q7 [email protected]@@@@L5#''                                                                                        [email protected]@@@@@@'[email protected]~ , ,[email protected]@[email protected]@@@@@@@@QI.         
           [email protected]#z;[email protected]@@@QDI~                                                                                              '~^in{\' [email protected]@;    [email protected]@@@@@@@@@@@o`       
          <[email protected]@@@@[email protected]:                                                                                                [email protected]@@#      ~U%[email protected]@@@@@@@@j       
         [email protected]~`@@[email protected]@!     .s.                                                                                           [email protected]@@@@@@`b. dj' >f|[email protected]@@@@@@`      
        <@i [email protected]@@u^[email protected]@^     ,Q~                                                                                               _\mDBq* 8#`[email protected]@z{@@NS,[email protected]@@@^      
       [email protected] ;@@@@@`[email protected]~   ^`[email protected]                                                                                               ^7;`    [email protected]@[email protected]@[email protected]@@[email protected]@[email protected]@@B.     
       QQ``[email protected]@@@@[email protected]~  'E:[email protected]@.                                                                                                [email protected]@[email protected]@@@Q,'<Qy,@@@[email protected]@@@@@hQ6+`   
    *\`@< [email protected]@@@@@h8  ~d'[email protected]@a=                                                                                                  ;[email protected]@@@@@h!Q`.K.,#@[email protected]@@@@@@@@j    
    [email protected]@ ;@@@@@@AQa ~B'[email protected]@@^%  !                                                                                                '`!7jY^ [email protected]\  , `[email protected]@@@@@@@@@}   
    [email protected]@@;}@@@@@[email protected]!'Q;[email protected]`{,                                                                                                _%n^,,[email protected]@D   ' `[email protected]@@@@@@@@U   
    b%[email protected]@[email protected]@@[email protected]`Bj>qy{EjUQB|                                                                                                  ,[email protected]@@@@@@B ! Wy .;;[email protected]@@@@@@E   
   <@;[email protected]@@Az%*[email protected]`EQ`[email protected];[email protected];                                                                                                     [email protected]@@@@n D~%@[email protected],[email protected]@@@@a   
  :@Q,@@@@@Q;`[email protected]'[email protected] [email protected]@|  ;`                                                                                                     `\_'*ti~ [email protected]|@[email protected]@@[email protected]@R   
  #@a<@@@@@@@\!,,@@, [email protected]@^ ,                                                                                                        ;@Q{^;!}@@* [email protected]`@@[email protected]@@y|[email protected]?  
 `@@[email protected]@@@@@@@@'[email protected]@`^@@@!=jD                                                                                                        [email protected]@@@@@@@'  [email protected]@@@@#`[email protected]~ 
  [email protected]|[email protected]@@@@@@@@[email protected] [email protected]@@;[email protected]                                                                                                        .;[email protected]@@@@?`+   [email protected]@@@@@@;'Q<`
'[email protected]}[email protected]@@@@@@[email protected]{`A,`@@@@;a7q'                                                                                                       SL`=5P}, of    P{[email protected]@@@@7 @+ 
 '[email protected]@|[email protected]@@@Q|@@_   ,@[email protected]|@;~                                                                                                       [email protected]+'``[email protected]| ~y `[email protected]@@@@U @Q 
  [email protected]@[email protected]@;[email protected] [email protected]',Q\,@>`                                                                                                        [email protected]@@@@@@Q` [email protected]: '[email protected]@@@@Q @@+
  *@[email protected]@@k*[email protected]    :g?+'< Q7                                                                                                        .`[email protected]@@@@%, [email protected]@^,y,[email protected]@@@@;@@~
  [email protected]:[email protected]@@@@U+z`  <=`[email protected]!  zi                                                                                                        c; ;fP};_7  Qh [email protected]@,[email protected]@@@[email protected]| 
  %@^'@@@@@@@Qf` @@7 [email protected]@i .^                                                                                                        [email protected]!    ^@,  |`[email protected]@@<[email protected]@@u  
  %@5 [email protected]@@@@@@8Q`[email protected]@`[email protected]@@* `                                                                                                        ;@@[email protected] [email protected]%[email protected]@@#|[email protected]~  
  [email protected] [email protected]@@@@@@DQX`[email protected] ^@@@@;                                                                                                        ``[email protected]@@@@y      [email protected]@@@@@=`@n  
   [email protected]| [email protected]@@@@@N%@,`= `@@@@@:                                                                                                       {f ;Jjz,~` ;X  [email protected]@@@@@@f,@S  
  `[email protected]! [email protected]@@@@[email protected] [email protected]@@@@:                                                                                                     `[email protected]' `;Uf [email protected]@~ [email protected]@@@@@[email protected]  
   `[email protected]@[email protected]@@[email protected]    ,@@i;[email protected]:                                                                                                    '@@@@@@@5 ^@#^`[email protected]@@@@@[email protected]@+  
     [email protected]@@#DK*~RD     [email protected] '~d~                                                                                                  h [email protected]@@@g^  Kj `[email protected]`[email protected]@@@@@@!   
     ,QQ:[email protected]@@@@S;>   `' ?j NX;;                                                                                                 ^@, :\i;,  `? `[email protected]@Q.`[email protected]@@@Q~    
      ,@D'@@@@@@@%Kn` QS:. [email protected]@Q>                                                                                                [email protected]!;}a      [email protected]@Q;@@@Q`     
       ,Qx*@@@@@@@@[email protected]^[email protected]@D,`[email protected]@@B;                                                                                             '@@@@@@i .T;  [email protected]@@@@X^@@i      
        [email protected]@@@@@@[email protected]@i;[email protected] ,@@@@@k`                                                                                        ~D `@@@@j. [email protected]@+  [email protected]@@@@g [email protected]~      
         `[email protected]@@@@[email protected]@* ,s  [email protected]@@@Q|                                                                                      ;@Q  |7~`` [email protected]@@[email protected]@@@@@@{'ES`      
          ^WUtJoPURQ'[email protected]@^     '[email protected]*oWf                                                                                    ,@@@K*^Tf^  Q&|;AE'@@@@@@@B'W+        
           `[email protected]@@@QDy?rc;      `5Q !i?;                                                                                `T [email protected]@@@@Q*   ;;`[email protected]@j [email protected]@@@@@!gQ         
            `S;[email protected]@@@@@@#Ay;  *Nz,;.;@@@@dL'                                                                          `{@f [email protected]@@U!      ,[email protected]@[email protected]@@@@[email protected]         
             ;g`|@@@@@@@@qN%_ [email protected]@Q' [email protected]@@@@@b;                                                                       ,[email protected]@D. ',;*' ~   '[email protected]@@@^@@@@[email protected]@R`         
              mQ,'[email protected]@@@@@@[email protected]'^[email protected] [email protected]@@@[email protected],                                                                 's:'@@@@@@[email protected]\  `[email protected]@@@@[email protected]@@@q;           
              `[email protected]^ ;[email protected]@@@@@[email protected]+ `*;  ,[email protected]@; `;^.                                                              `[email protected] [email protected]@@@Qw=` [email protected]@Q ,^[email protected]@@@@@;;@@y,             
               `[email protected]'`~zkd%RD!+zi'``   ``^#|'@@@@@#EL:                                                     .  ^[email protected]@8.,rvz=    [email protected]*^[email protected]*[email protected]@@@@@@f !R'               
                 :7%@[email protected]@@@@@@@@QWdKy{;i#XE,[email protected]@@@@@@@@q*`                                             `^ZN; ^@@@@@@@@d^`    : ;[email protected]@?`[email protected]@@@@@z`Sq`                
                    '{'`[email protected]@@@@@@@@@@[email protected],[email protected]@@@N^:,;+'`                                         [email protected]@@~  [email protected]@@@Qh*. ';`   ;[email protected]^@@@@@Q;+QN`                 
                     `A\` `}@@@@@@@@@@%[email protected]@k~^: 'v#@Q',[email protected]@@@@@@Qdy*_                         `[email protected]@@@Q*^;zjs+  [email protected]@D,  `[email protected]@@[email protected]@@@z;[email protected]                  
                      `BQ=  '[email protected]@@@@@@@DJgQD'     ~Yqr|[email protected]@@@@@w\>;,.~!=||*^;:.      `,!**~*[email protected]@@B' @@@@@@@@@@@87.`[email protected]@@y `''y%@@@@@@@[email protected]@B>[email protected]@Q~                   
                       '[email protected]<^v5UKKbKKquiJdN%Kyz;!mZY~ ;[email protected]@@; [email protected]@@@@@@@w?~.'*[email protected]@@E;>[email protected]@@@@K;'^EgQQgK5i;`  ,wm7*[email protected],<@@@@@@@@[email protected]@8o!                     
                         [email protected]|\[email protected]@@@@@@@@@@@@#[email protected]@E{SR|   '[email protected]@@@@@D` `{&@@@@@@L  [email protected]@@@@@@@@@gj<,'jXK%j`   [email protected]@@W:[email protected]@@@@@@K,,@Qy;`                        
                            `;iv,  _\[email protected]@@@@@@@@@@[email protected]@@%^     '\yuS! `!{[email protected]@Bi~{[email protected]@@@@@@@NUKKEI=!;,`  `[email protected]@@Wr  [email protected]@[email protected]@@@@D~`LNc                            
                                \K>`  ,[email protected]@@@@@@QU,,~?nSPaUDXfYyjSL      `,^xJ!``'~;;!^^;;|uzL*+;  'i7\L?^,``[email protected]@@@@@@@*[email protected]@@[email protected]                             
                                 ,WQZ;   ;\o5Ti\[email protected]@@@@@@N%%[email protected]'      [email protected]@@@A?`    <[email protected]@@Qj^` ';i}[email protected][email protected]@@@@@@@@[email protected]@K+7%@@y`                              
                                   ^[email protected]+;|o%@@@@@@@@@@@@@@@@Q+`,+\nSqDQQ%XYcI\*!~' `'''_^*?'`+}[email protected]@QQQQQK,[email protected]@@@@@@@@@u`[email protected]&KaL'                                
                                      `,;|[email protected]@@@@@@@@@[email protected]@@@@@@WDq6byi|[email protected]@@Qy+cXKD%[email protected]@@@@@@@8\,+fn~`                                      
                                           .aQUi;,!|zJcr*[email protected]@@@@@@@@@@@@@@Q*`^[email protected]@@QWwv. '[email protected]@@@@@@@@@@[email protected]@@@@@bucyBQ<                                          
                                             ,[email protected]@@[email protected]@@@@@@@@@@@@@@Di*[email protected]@@@@@@@@@@@L;[email protected]@@@@@@@@@@@[email protected]@@@@[email protected]@WL`                                           
                                               .^<<+!!\[email protected]@Qy|[email protected]@@@@@@@@@@@[email protected]@@@@@@@@@&[email protected]}T*!_.                                              
                                                         ;[email protected]<^[email protected]@Q%K6U66qqqUm*[email protected]@@@@@N6a}JYEwt<=z'                                                       
                                                            `!czv|z7<<[email protected]>'                                                             
                                                                         .^z5aY?~`~T;`                                                                          

*/

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './Whitelist.sol';
import './ApproveUtils.sol';

// hardhat network logging
// import 'hardhat/console.sol';

///
/// @title Used only by [swappin.gifts](https://swappin.gifts]) to accept payments in any token or native coin.
/// @author swappin.gifts
/// @notice We've designed this contract to be non-upgradable. Once the contract has been deployed to the blockchain, it will never change.
/// @notice This guarantee, as provided by the blockchain, together with the complete source code of the contract, will allow any party to verify the security properties and guarantees.
/// @notice By putting security and transparency first, we hope to pave the way for a more trustless and trustable ecosystem.
/// @notice Clara pacta, boni amici.
/// @dev See README.md for more information.
///
contract Gateway is ReentrancyGuard, Whitelist {
        using Address for address;
        using SafeERC20 for IERC20;
        using ApproveUtils for IERC20;

        /// @notice emitted on succesfull payment
        event Payment(bytes32 indexed orderId, uint64 indexed refId, address indexed dest, address tokenTo, uint256 amount);

        constructor() {}
        
        ///
        /// @notice The create2 constructor alternative. Initializes the whitelist and sets the owner.
        /// @dev Setting the owner this way is secure because the DeterministicDeployFactory.deploy() is onlyOwner.
        /// @dev `_dests` and `_tokens` are pairs so arrays must have same length. Same applies to `_providers` and `_providerSpenders`.
        ///
        /// @param _dests array of allowed destination wallets
        /// @param _tokens array of allowed destination tokens
        /// @param _providers array of allowed swap providers
        /// @param _providerSpenders array of allowed swap provider spender contracts (sometimes not the same as the provider main contract)
        /// @param _ownerAddress the constructor will transfer ownership to this account
        ///
        function init(address[] memory _dests, address[] memory _tokens, address[] memory _providers, address[] memory _providerSpenders, address _ownerAddress) external onlyOwner {
                // make sure pair lists lengths match
                require(_providers.length == _providerSpenders.length, 'providers and providerSpenders length differs');
                require(_dests.length == _tokens.length, 'destinations and tokens length differs');
                // fill white list of providers
                setProviders(_providers, _providerSpenders, TRUE);
                // fill white list of destinations
                setDestinations(_dests, _tokens, TRUE);
                transferOwnership(_ownerAddress);
        }

        ///
        /// @notice Transfers `amount` of `token` from msg.sender to `dest`
        /// @notice Emits a `Payment` event
        ///
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param amount amount in USD to transfer
        /// @param dest destination wallet (must be whitelisted)
        /// @param token destination token (i.e. USDC - must be whitelisted)
        ///
        function payWithUsdToken(bytes32 orderId, uint64 refId, uint256 amount, address dest, IERC20 token) external {
                // validate input
                require(amount > 1, 'invalid amount');
                require(token.balanceOf(msg.sender) >= amount, 'insufficient sender balance');
                // destination address and token are white listed
                require(validDestination(dest, address(token)) == TRUE, 'unknown destination');

                // save start balance of dest address
                uint256 startBalance = token.balanceOf(dest);

                // emit Event before external call
                emit Payment(orderId, refId, dest, address(token), amount);

                // transfer amount of tokens to dest address
                token.safeTransferFrom(msg.sender, dest, amount);

                // solidity checks and reverts on overflow (since 0.8 or so)
                // verify transferred amount
                require(token.balanceOf(dest) - startBalance == amount, 'transferred amount invalid');
        }

        ///
        /// @notice Accepts `amountFrom` ETH. Sends ETH to swap provider, which sends `token` back.
        /// @notice Sends received `token` to `dest`
        /// @notice Emits an event
        //
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param amountFrom amount of ETH to pay
        /// @param minAmountTo minimum amount of USD that is allowed (otherwise tx will revert)
        /// @param swapProvider a dex aggregator or dex address (must be whitelisted)
        /// @param swapCalldata calldata to pass arguments to the swap provider
        /// @param dest destination wallet (must be whitelisted)
        /// @param token destination token (i.e. USDC - must be whitelisted)
        ///
        function payWithEth(
                bytes32 orderId,
                uint64 refId,
                uint256 amountFrom,
                uint256 minAmountTo,
                address swapProvider,
                bytes calldata swapCalldata,
                address dest,
                IERC20 token
        ) external payable nonReentrant {
                // validate input
                require(msg.value == amountFrom, 'msg.value != amountFrom');
                require(minAmountTo > 1, 'invalid minAmountTo');
                require(amountFrom > 0, 'invalid amountFrom');
                // destination address and token are white listed
                require(validDestination(dest, address(token)) == TRUE, 'unknown destination');
                // provider address is white listed
                require(validProvider(swapProvider) == TRUE, 'unknown provider');

                // call provider to convert ETH to tokens
                uint256 amountReceived = swapEth(swapProvider, swapCalldata, token, minAmountTo);

                // send tokens to dest address
                transferToDest(dest, token, amountReceived, minAmountTo);

                // emit Event
                emit Payment(orderId, refId, dest, address(token), amountReceived);
        }

        ///
        /// @notice Accepts `amountFrom` of `tokenFrom`. Converts `tokenFrom` to `tokenTo` via a swap provider
        /// @notice Sends `tokenTo` to `dest`
        /// @notice Emits an event
        ///
        /// @param orderId swappin.gifts order id
        /// @param refId swappin.gifts partner id
        /// @param swapProvider  a dex aggregator or dex address (must be whitelisted)
        /// @param providerSpender  a dex aggregator or dex spender address (must be whitelisted)
        /// @param swapCalldata calldata to pass arguments to the swap provider
        /// @param tokenFrom the token the user pays with
        /// @param tokenTo destination token (i.e. USDC - must be whitelisted)
        /// @param amountFrom  amount of token to pay
        /// @param minAmountTo  minimum amount of USD that is allowed (otherwise tx will revert)
        /// @param dest destination wallet (must be whitelisted)
        ///
        function payWithAnyToken(
                bytes32 orderId,
                uint64 refId,
                address swapProvider,
                address providerSpender,
                bytes calldata swapCalldata,
                IERC20 tokenFrom,
                IERC20 tokenTo,
                uint256 amountFrom,
                uint256 minAmountTo,
                address dest
        ) external nonReentrant {
                // validate input
                require(amountFrom > 0, 'invalid amountFrom');
                require(minAmountTo > 1, 'invalid minAmountTo');
                require(tokenFrom.balanceOf(msg.sender) >= amountFrom, 'insufficient sender balance');
                // destination address and token are white listed
                require(validDestination(dest, address(tokenTo)) == TRUE, 'unknown destination');
                // provider address and provider spender address are white listed
                require(validProviderSpender(swapProvider, providerSpender) == TRUE, 'unknown provider');

                // save current token balance
                uint256 tokenFromBalance = tokenFrom.balanceOf(address(this));
                // transfer tokenFrom from sender to this contract
                tokenFrom.safeTransferFrom(msg.sender, address(this), amountFrom);
                // verify received tokenFrom amount
                require(tokenFrom.balanceOf(address(this)) - tokenFromBalance == amountFrom, 'invalid amount of tokenFrom received');

                // call provider to convert tokenFrom to tokenTo
                uint256 amountReceived = swapToken(swapProvider, providerSpender, swapCalldata, tokenFrom, tokenTo, amountFrom, minAmountTo);

                // verify transfered all received tokenFrom to provider
                require(tokenFromBalance == tokenFrom.balanceOf(address(this)), 'invalid amount transfered to swap provider');

                // send tokens to dest address
                transferToDest(dest, tokenTo, amountReceived, minAmountTo);

                // emit Event
                emit Payment(orderId, refId, dest, address(tokenTo), amountReceived);
        }

        ///
        /// @notice Call DEX provider to convert ETH to `token`
        ///
        function swapEth(address swapProvider, bytes calldata swapCalldata, IERC20 token, uint256 minAmountTo) private returns (uint256) {
                // save this contract's ETH  balance
                uint256 ethStartBalance = address(this).balance;
                // save this contract's token balance
                uint256 startBalance = token.balanceOf(address(this));

                // call provider to convert ETH to token
                swapProvider.functionCallWithValue(swapCalldata, msg.value);

                // verify received tokens amount from provider
                uint256 receivedAmount = token.balanceOf(address(this)) - startBalance;
                require(receivedAmount >= minAmountTo, 'invalid amount of token from swap provider');

                // verify transfered all received ETH to provider
                require(ethStartBalance - address(this).balance == msg.value, 'invalid amount transferred to swap provider');

                // return the actual amount calculated from balances (not what the provider might have returned)
                return receivedAmount;
        }

        ///
        /// @notice Call DEX provider to convert `tokenFrom` to `tokenTo`
        ///
        function swapToken(
                address swapProvider,
                address providerSpender,
                bytes calldata swapCalldata,
                IERC20 tokenFrom,
                IERC20 tokenTo,
                uint256 amountFrom,
                uint256 minAmountTo
        ) private returns (uint256) {
                // allow providerSpender to spend amountFrom of tokenFrom tokens held by this contract
                tokenFrom.safeApproveImproved(providerSpender, amountFrom);

                // save start tokenTo balance
                uint256 startBalance = tokenTo.balanceOf(address(this));

                // call swap provider
                swapProvider.functionCall(swapCalldata);

                // verify tokenTo amount received from provider corresponds to what was quoted
                uint256 receivedAmount = tokenTo.balanceOf(address(this)) - startBalance;
                require(receivedAmount >= minAmountTo, 'received invalid destToken amount from swap provider');

                // reset providerSpender allowance to 0
                tokenFrom.zeroAllowance(providerSpender);

                // return the actual amount calculated from balances
                return receivedAmount;
        }

        ///
        /// @notice Sends `toToken` received from swap provider to `dest` address
        ///
        function transferToDest(address dest, IERC20 tokenTo, uint256 receivedAmount, uint256 minAmountTo) private {
                // save dest address start balance
                uint256 startBalance = tokenTo.balanceOf(dest);

                // send tokenTo to dest address
                tokenTo.safeTransfer(dest, receivedAmount);

                // verify transfered full received amount and amount is valid
                uint256 destAmount = tokenTo.balanceOf(dest) - startBalance;
                require(destAmount == receivedAmount && destAmount >= minAmountTo, 'invalid amount transfered to dest');
        }
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.17;

import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @title A whitelist for provider addresses and destination addresses
/// @notice Use by inheriting
contract Whitelist is Ownable {
        using Address for address;
        using SafeERC20 for IERC20;

        /// @dev Allowed combinations of destination addresses and destination token
        mapping(bytes32 => bytes32) public destinations;

        /// @dev Allowed combinations of provider address and provider spender address
        mapping(bytes32 => bytes32) public providers;

        /// @dev allow flag in a whitelist
        bytes32 internal constant TRUE = bytes32(uint256(1));
        /// @dev deletes an entry from a whitelist - isn't currently used. kept for documentation purposes
        bytes32 internal constant ZERO = bytes32(uint256(0));

        /// @notice  on added destination
        event AddedDestination(address indexed dest, address indexed token);
        /// @notice  on removed destination
        event RemovedDestination(address indexed dest, address indexed token);
        /// @notice  on added provider
        event AddedProvider(address indexed provider, address indexed providerSpender);
        /// @notice  on removed provider
        event RemovedProvider(address indexed provider, address indexed providerSpender);

        constructor() {}

        /// @dev Returns current status flag for destination
        function validDestination(address dest, address token) internal view returns (bytes32) {
                return destinations[keccak256(abi.encode(dest, token))];
        }

        /// @dev Returns current status flag for provider and spender address combination
        function validProviderSpender(address providerAddress, address spenderAddress) internal view returns (bytes32) {
                return providers[keccak256(abi.encode(providerAddress, spenderAddress))];
        }

        /// @dev Returns current status flag for provider address
        function validProvider(address providerAddress) internal view returns (bytes32) {
                return providers[keccak256(abi.encode(providerAddress))];
        }

        /// @dev Adds/deletes the given destinations from the white list
        function setDestinations(address[] memory dests, address[] memory tokens, bytes32 flag) public onlyOwner {
                uint256 len = dests.length;
                for (uint256 i = 0; i < len; i++) {
                        if (flag == TRUE) {
                                emit AddedDestination(dests[i], tokens[i]);
                        } else {
                                emit RemovedDestination(dests[i], tokens[i]);
                        }
                        destinations[keccak256(abi.encode(dests[i], tokens[i]))] = flag;
                }
        }

        /// @dev Adds/deletes the given providers from the white list
        function setProviders(address[] memory _providers, address[] memory _providerSpenders, bytes32 flag) public onlyOwner {
                uint256 len = _providers.length;
                for (uint256 i = 0; i < len; i++) {
                        if (flag == TRUE) {
                                emit AddedProvider(_providers[i], _providerSpenders[i]);
                        } else {
                                emit RemovedProvider(_providers[i], _providerSpenders[i]);
                        }
                        providers[keccak256(abi.encode(_providers[i]))] = flag;
                        providers[keccak256(abi.encode(_providers[i], _providerSpenders[i]))] = flag;
                }
        }
}