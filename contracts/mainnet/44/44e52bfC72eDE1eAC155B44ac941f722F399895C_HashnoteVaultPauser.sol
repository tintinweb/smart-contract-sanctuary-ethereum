// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum TokenType {
    PUT,
    PUT_SPREAD,
    CALL,
    CALL_SPREAD
}

/**
 * @dev action types
 */
enum ActionType {
    AddCollateral,
    RemoveCollateral,
    MintShort,
    BurnShort,
    MergeOptionToken,
    SplitOptionToken,
    AddLong,
    RemoveLong,
    SettleAccount,
    // actions that influece more than one subAccounts:
    MintShortIntoAccount, // increase short (debt) position in one subAccount, increase long token directly to another subAccount
    TransferCollateral, // transfer collateral direclty to another subAccount
    TransferLong, // transfer long directly to another subAccount
    TransferShort // transfer short directly to another subAccount
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant MAX_UINT256 = 2**256 - 1;

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // Divide x * y by the denominator.
            z := div(mul(x, y), denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(MAX_UINT256, y)))))) {
                revert(0, 0)
            }

            // If x * y modulo the denominator is strictly greater than 0,
            // 1 is added to round up the division of x * y by the denominator.
            z := add(gt(mod(mul(x, y), denominator), 0), div(mul(x, y), denominator))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let y := x // We start y at x, which will help us make our initial estimate.

            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // We check y >= 2^(k + 8) but shift right by k bits
            // each branch to ensure that if x >= 256, then y >= 256.
            if iszero(lt(y, 0x10000000000000000000000000000000000)) {
                y := shr(128, y)
                z := shl(64, z)
            }
            if iszero(lt(y, 0x1000000000000000000)) {
                y := shr(64, y)
                z := shl(32, z)
            }
            if iszero(lt(y, 0x10000000000)) {
                y := shr(32, y)
                z := shl(16, z)
            }
            if iszero(lt(y, 0x1000000)) {
                y := shr(16, y)
                z := shl(8, z)
            }

            // Goal was to get z*z*y within a small factor of x. More iterations could
            // get y in a tighter range. Currently, we will have y in [256, 256*2^16).
            // We ensured y >= 256 so that the relative difference between y and y+1 is small.
            // That's not possible if x < 256 but we can just verify those cases exhaustively.

            // Now, z*z*y <= x < z*z*(y+1), and y <= 2^(16+8), and either y >= 256, or x < 256.
            // Correctness can be checked exhaustively for x < 256, so we assume y >= 256.
            // Then z*sqrt(y) is within sqrt(257)/sqrt(256) of sqrt(x), or about 20bps.

            // For s in the range [1/256, 256], the estimate f(s) = (181/1024) * (s+1) is in the range
            // (1/2.84 * sqrt(s), 2.84 * sqrt(s)), with largest error when s = 1 and when s = 256 or 1/256.

            // Since y is in [256, 256*2^16), let a = y/65536, so that a is in [1/256, 256). Then we can estimate
            // sqrt(y) using sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2^18.

            // There is no overflow risk here since y < 2^136 after the first branch above.
            z := shr(18, mul(z, add(y, 65536))) // A mul() is saved from starting z at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If x+1 is a perfect square, the Babylonian method cycles between
            // floor(sqrt(x)) and ceil(sqrt(x)). This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { Vault } from "../libraries/Vault.sol";

interface IHashnoteOptionsVault {
    function whitelist() external view returns (address);

    function vaultParams() external view returns (Vault.VaultParams memory);

    function vaultState() external view returns (Vault.VaultState memory);

    function optionState() external view returns (Vault.OptionState memory);

    function auctionId() external view returns (uint256);

    function depositFor(uint256 amount, address creditor) external;

    function requestWithdraw(uint256 numShares) external;

    function instruments() external view returns (Vault.Instrument[] memory);

    function getCollaterals() external view returns (Vault.Collateral[] memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IVaultPauser {
    /// @notice pause vault position of an account with max amount
    /// @param _account the address of user
    /// @param _amount amount of shares
    function pausePosition(address _account, uint256 _amount) external;

    /// @notice processes all pending withdrawals
    /// @param _balances of assets transfered to pauser
    function processVaultWithdraw(uint256[] calldata _balances) external;

    /// @notice user withdraws collateral
    /// @param _vault the address of vault
    /// @param _destination the address of the recipient
    function withdrawCollaterals(address _vault, address _destination) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface ISanctionsList {
    function isSanctioned(address _address) external view returns (bool);
}

interface IWhitelist {
    function isCustomer(address _address) external view returns (bool);

    function isLP(address _address) external view returns (bool);

    function isOTC(address _address) external view returns (bool);

    function isVault(address _vault) external view returns (bool);

    function engineAccess(address _address) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

// common
error Unauthorized();
error Overflow();

// Vault
error HV_ActiveRound();
error HV_AuctionInProgress();
error HV_BadAddress();
error HV_BadAmount();
error HV_BadCap();
error HV_BadCollaterals();
error HV_BadCollateralPosition();
error HV_BadDepositAmount();
error HV_BadDuration();
error HV_BadExpiry();
error HV_BadFee();
error HV_BadLevRatio();
error HV_BadNumRounds();
error HV_BadNumShares();
error HV_BadNumStrikes();
error HV_BadOption();
error HV_BadPPS();
error HV_BadRound();
error HV_BadRoundConfig();
error HV_BadSB();
error HV_BadStructures();
error HV_CustomerNotPermissioned();
error HV_ExistingWithdraw();
error HV_ExceedsCap();
error HV_ExceedsAvailable();
error HV_Initialized();
error HV_InsufficientFunds();
error HV_OptionNotExpired();
error HV_RoundClosed();
error HV_RoundNotClosed();
error HV_Unauthorized();
error HV_Uninitialized();

// VaultPauser
error VP_BadAddress();
error VP_CustomerNotPermissioned();
error VP_Overflow();
error VP_PositionPaused();
error VP_RoundOpen();
error VP_Unauthorized();
error VP_VaultNotPermissioned();

// VaultUtil
error VL_BadCap();
error VL_BadCollateral();
error VL_BadCollateralAddress();
error VL_BadDuration();
error VL_BadExpiryDate();
error VL_BadFee();
error VL_BadFeeAddress();
error VL_BadId();
error VL_BadInstruments();
error VL_BadManagerAddress();
error VL_BadOracleAddress();
error VL_BadOwnerAddress();
error VL_BadPauserAddress();
error VL_BadPrecision();
error VL_BadStrikeAddress();
error VL_BadSupply();
error VL_BadUnderlyingAddress();
error VL_BadWeight();
error VL_DifferentLengths();
error VL_ExceedsSurplus();
error VL_Overflow();
error VL_Unauthorized();

// FeeUtil
error FU_NPSLow();

// BatchAuction
error BA_AuctionClosed();
error BA_AuctionNotClosed();
error BA_AuctionSettled();
error BA_AuctionUnsettled();
error BA_BadAddress();
error BA_BadAmount();
error BA_BadBiddingAddress();
error BA_BadCollateral();
error BA_BadOptionAddress();
error BA_BadOptions();
error BA_BadPrice();
error BA_BadSize();
error BA_BadTime();
error BA_EmptyAuction();
error BA_Unauthorized();
error BA_Uninitialized();

// Whitelist
error WL_BadAddress();
error WL_BadRole();
error WL_Paused();
error WL_Unauthorized();

// VaultShare
error VS_SupplyExceeded();

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { TokenType } from "../../lib/grappa/src/config/enums.sol";

library Vault {
    /*///////////////////////////////////////////////////////////////
                        Constants and Immutables
    //////////////////////////////////////////////////////////////*/

    // Fees are 18-decimal places. For example: 20 * 10**18 = 20%
    uint256 internal constant FEE_MULTIPLIER = 10 ** 18;

    // Otokens have 6 decimal places.
    uint256 internal constant DECIMALS = 6;

    // Otokens have 6 decimal places.
    uint256 internal constant UNIT = 10 ** 6;

    // Placeholder uint value to prevent cold writes
    uint256 internal constant PLACEHOLDER_UINT = 1;

    /**
     * @notice Initialization parameters for the vault.
     * @param _owner is the owner of the vault with critical permissions
     * @param _manager is the address that is responsible for advancing the vault
     * @param _feeRecipient is the address to recieve vault performance and management fees
     * @param _oracle is used to calculate NA
     * @param _managementFee is the management fee pct.
     * @param _performanceFee is the perfomance fee pct.
     * @param _pauser is where withdrawn collateral exists waiting for client to withdraw
     * @param _auction is the auction contract
     * @param _instruments linear combination of options
     * @param _collaterals is the assets used in the vault
     * @param _auctionDuration is the duration of the gnosis auction
     * @param _leverageRatio how much of the funds are used in a round
     * @param _roundConfig sets the duration and expiration of options
     */
    struct InitParams {
        address _owner;
        address _manager;
        address _feeRecipient;
        address _oracle;
        uint256 _managementFee;
        uint256 _performanceFee;
        address _pauser;
        address _auction;
        Instrument[] _instruments;
        Collateral[] _collaterals;
        uint256 _auctionDuration;
        uint256 _leverageRatio;
        RoundConfig _roundConfig;
    }

    struct Collateral {
        // Grappa asset Id
        uint8 id;
        // ERC20 token address for the required collateral
        address addr;
        // the amount of decimals or token
        uint8 decimals;
    }

    struct Instrument {
        TokenType tokenType;
        // Indicated how much the vault is short or long this instrument in a structure
        int64 weight;
        // oracle for product
        address oracle;
        // Underlying asset of the options
        address underlying;
        // asset that the strike price is denominated in
        address strike;
        // Asset backing the option
        address collateral;
    }

    struct VaultParams {
        // Minimum supply of the vault shares issued, for ETH it's 10**10
        uint56 minimumSupply;
        // Vault cap
        uint104 cap;
    }

    struct OptionState {
        // Option that the vault is shorting / longing in the next cycle
        uint256[] nextOptions;
        // Option that the vault is currently shorting / longing
        uint256[] currentOptions;
        // Current premium per structure
        int256 premium;
        // Max number of structures possible to sell based on
        // = lockedBalance * leverageRatio
        uint256 maxStructures;
        // Total structures minted this round
        uint256 mintedStructures;
        // Amount of collateral required by the vault per structure
        uint256[] vault;
        // Amount of collateral required by the counterparty per structure
        uint256[] counterparty;
    }

    struct VaultState {
        // 32 byte slot 1
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Amount that is currently locked for selling options
        uint104 lockedAmount;
        // Amount that was locked for selling options in the previous round
        // used for calculating performance fee deduction
        uint104 lastLockedAmount;
        // 32 byte slot 2
        // Stores the total tally of how much of `asset` there is
        // to be used to mint vault tokens
        uint128 totalPending;
        // store the number of shares queued for withdraw this round
        // zero'ed out at the start of each round, pauser withdraws all queued shares.
        uint128 queuedWithdrawShares;
    }

    struct DepositReceipt {
        // Round represents the number of periods elapsed. There's a hard limit of 4,294,967,295 rounds
        uint32 round;
        // Deposit amount, max 20,282,409,603,651 or 20 trillion ETH deposit
        uint104 amount;
        // Unredeemed shares balance
        uint128 unredeemedShares;
    }

    struct RoundConfig {
        // the duration of the option
        uint32 duration;
        // day of the week the option should expire. 0-8, 0 is sunday, 7 is sunday, 8 is wild
        uint8 dayOfWeek;
        // hour of the day the option should expire. 0 is midnight
        uint8 hourOfDay;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import { IERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "../../lib/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "../../lib/openzeppelin/contracts/access/Ownable.sol";
import { FixedPointMathLib } from "../../lib/solmate/src/utils/FixedPointMathLib.sol";

import { IVaultPauser } from "../interfaces/IVaultPauser.sol";
import { IHashnoteOptionsVault } from "../interfaces/IHashnoteOptionsVault.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

import { Vault } from "../libraries/Vault.sol";

import "../libraries/Errors.sol";

contract HashnoteVaultPauser is Ownable, IVaultPauser {
    using FixedPointMathLib for uint256;
    using SafeERC20 for IERC20;

    /*///////////////////////////////////////////////////////////////
                            Structures
    //////////////////////////////////////////////////////////////*/

    /// @notice Stores all the vault's paused positions
    struct PauseReceipt {
        uint32 round;
        uint128 shares;
    }

    /*///////////////////////////////////////////////////////////////
                            Storage
    //////////////////////////////////////////////////////////////*/

    // vault => account => pause receipt
    mapping(address => mapping(address => PauseReceipt)) public pausedPositions;

    // vault => round => total withdrawn shares
    mapping(address => mapping(uint256 => uint128)) public roundTotalShares;

    // vault => round => array of collateral balances
    mapping(address => mapping(uint256 => uint256[])) public roundBalances;

    IWhitelist public immutable whitelist;

    /*///////////////////////////////////////////////////////////////
                                Events
    //////////////////////////////////////////////////////////////*/

    event Pause(address indexed account, address indexed vaultAddress, uint256 share, uint256 round);

    event Withdraw(address indexed account, address indexed vaultAddress, uint256[] withdrawAmounts);

    event ProcessWithdraws(address indexed vaultAddress, uint256 round, uint256[] withdrawAmounts);

    /*///////////////////////////////////////////////////////////////
                            Constructor
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Initializes the contract with immutable variables
     * @param _whitelist is the the whitelist manager
     */
    constructor(address _whitelist) {
        if (_whitelist == address(0)) revert VP_BadAddress();

        whitelist = IWhitelist(_whitelist);
    }

    /*///////////////////////////////////////////////////////////////
                            Getters
    //////////////////////////////////////////////////////////////*/

    function getPausePosition(address _vault, address _userAddress) external view returns (PauseReceipt memory) {
        return pausedPositions[_vault][_userAddress];
    }

    function roundTotalBalances(address _vault, uint256 _round) external view returns (uint256[] memory balances) {
        balances = roundBalances[address(_vault)][_round];
    }

    /*///////////////////////////////////////////////////////////////
                            Pauser Operations
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice pause position from vault by redeem all the shares from vault to Pauser
     * @param _account user's address
     * @param _shares the amount of shares
     */
    function pausePosition(address _account, uint256 _shares) external override {
        address _vault = msg.sender;

        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);

        uint32 currentRound = vault.vaultState().round;

        PauseReceipt storage pausedPosition = pausedPositions[_vault][_account];

        uint256 pausedInRound = pausedPosition.round;

        // check if position is paused and no longer the same round
        if (pausedInRound > 0 && pausedInRound != currentRound) revert VP_PositionPaused();

        // tops up paused shares
        uint256 accountShares = pausedPosition.shares + _shares;

        if (accountShares > type(uint128).max) revert VP_Overflow();

        // updates storage with new pause receipt
        pausedPositions[_vault][_account] = PauseReceipt({round: currentRound, shares: uint128(accountShares)});

        // increases total shares for a given vault round
        uint256 roundShares = roundTotalShares[_vault][currentRound] + _shares;

        if (roundShares > type(uint128).max) revert VP_Overflow();

        roundTotalShares[_vault][currentRound] = uint128(roundShares);

        emit Pause(_account, _vault, _shares, currentRound);
    }

    /**
     * @notice customer withdraws collateral
     * @param _vault vault's address
     * @param _destination address
     */
    function withdrawCollaterals(address _vault, address _destination) external override {
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        if (_destination == address(0)) _destination = msg.sender;

        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);

        address vaultWhitelistAddr = vault.whitelist();

        // if whitelist set on vault, then check it for permissions
        if (vaultWhitelistAddr != address(0)) {
            IWhitelist vaultWhitelist = IWhitelist(vaultWhitelistAddr);

            if (!vaultWhitelist.isCustomer(msg.sender)) revert VP_CustomerNotPermissioned();

            if (_destination != msg.sender) {
                if (!vaultWhitelist.isCustomer(msg.sender)) revert VP_CustomerNotPermissioned();
            }
        }

        // get current round
        uint256 round = vault.vaultState().round;

        PauseReceipt memory pauseReceipt = pausedPositions[_vault][msg.sender];

        uint256 pauseReceiptRound = pauseReceipt.round;

        // check if round is closed before withdrawing user funds
        if (pauseReceiptRound >= round) revert VP_RoundOpen();

        // delete position once transfer (revert to zero)
        delete pausedPositions[_vault][msg.sender];

        _withdrawCollaterals(vault, pauseReceipt, _destination);
    }

    /**
     * @notice process withdrawals
     * @dev receives assets amount from vault
     */
    function processVaultWithdraw(uint256[] calldata balances) external override {
        address _vault = msg.sender;
        // check if vault is registered
        if (!whitelist.isVault(_vault)) revert VP_VaultNotPermissioned();

        IHashnoteOptionsVault vault = IHashnoteOptionsVault(_vault);
        // we can only process withdrawal after closing the previous round
        // hence round should be - 1
        uint256 round = vault.vaultState().round - 1;

        roundBalances[address(vault)][round] = balances;

        emit ProcessWithdraws(_vault, round, balances);
    }

    /**
     * @notice Recovery function that returns an ERC20 token to the recipient
     * @param token is the ERC20 token to recover from the vault
     * @param recipient is the recipient of the recovered tokens
     * @param amount of the recovered token to send
     */
    function recoverTokens(address token, address recipient, uint256 amount) external {
        _onlyOwner();

        if (recipient == address(0) || recipient == address(this)) revert VP_BadAddress();

        IERC20(token).safeTransfer(recipient, amount);
    }

    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }

    /*///////////////////////////////////////////////////////////////
                            Internal Functions
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Throws if called by any account other than the owner.
     */
    function _onlyOwner() internal view {
        if (msg.sender != owner()) revert VP_Unauthorized();
    }

    /**
     * @notice Helper function to withdraw collateral for a given vault account
     */
    function _withdrawCollaterals(IHashnoteOptionsVault vault, PauseReceipt memory pauseReceipt, address _destination) internal {
        uint256 round = pauseReceipt.round;
        uint256[] memory balances = roundBalances[address(vault)][round];
        uint256 totalShares = roundTotalShares[address(vault)][round];

        Vault.Collateral[] memory collaterals = vault.getCollaterals();

        uint256[] memory amounts = new uint256[](collaterals.length);

        for (uint256 i; i < collaterals.length;) {
            amounts[i] = balances[i].mulDivDown(pauseReceipt.shares, totalShares);

            if (amounts[i] > 0) IERC20(collaterals[i].addr).safeTransfer(_destination, amounts[i]);

            unchecked {
                ++i;
            }
        }

        emit Withdraw(msg.sender, address(vault), amounts);
    }
}