/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// Sources flattened with hardhat v2.9.3 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]


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


// File @openzeppelin/contracts/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



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
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/security/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

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


// File contracts/EmployeeTokenVesting.sol

// SPDX-License-Identifier: 1MIT

pragma solidity ^0.8.13;





/**
 * @dev A contract for vesting ASM ASTO tokens for ASM employees.
 *
 * There are two types of schedules based on DelayType.
 *  - "Delay" schedules starts vesting tokens after a delay
 *     and tokens are only claimable after the 1st week of the delay
 *     period.
 *  - "Cliff" schedules vests tokens during the cliff period but
 *     they are unclaimable until the cliff has ended.
 *
 * The contract defining a tax-rate for schedules. Tax is reserved
 * in the contract vested tokens are claimed.
 *
 * The contract supports multiple vesting schedules for scenarios
 * when multiple schedules, tax-rates, updates are needed to be made.
 *
 * Schedules can be terminated any time after the last claimed date,
 * allowing tokens to be claimed until the termination timestamp.
 */
contract EmployeeTokenVesting is Ownable, Pausable {
    using SafeERC20 for IERC20;

    uint256 internal constant SECONDS_PER_WEEK = 1 weeks;

    enum DelayType {
        Delay,
        Cliff
    }

    struct VestingSchedule {
        uint256 startTime;
        uint256 amount;
        DelayType delayType;
        uint16 durationInWeeks;
        uint16 delayInWeeks;
        uint16 taxRate100;
        uint256 totalClaimed;
        uint256 totalTaxClaimed;
        uint256 terminationTime;
    }

    struct AddVestingScheduleInput {
        uint256 startTime;
        uint256 amount;
        address recipient;
        DelayType delayType;
        uint16 durationInWeeks;
        uint16 delayInWeeks;
        uint16 taxRate100;
        uint256 totalClaimed;
        uint256 totalTaxClaimed;
    }

    struct VestedTokens {
        uint256 amount;
        uint256 tax;
    }

    event VestingAdded(
        uint256 vestingId,
        uint256 startTime,
        uint256 amount,
        address indexed recipient,
        uint16 durationInWeeks,
        uint16 delayInWeeks,
        uint16 taxRate100,
        DelayType delayType,
        uint256 _totalClaimed,
        uint256 _totalTaxClaimed
    );

    event VestingTokensClaimed(address indexed recipient, uint256 vestingId, uint256 amountClaimed, uint256 taxClaimed);
    event VestingRemoved(address indexed recipient, uint256 vestingId, uint256 amountVested, uint256 amountNotVested);
    event TaxWithdrawn(address indexed recipient, uint256 taxAmount);
    event TokenWithdrawn(address indexed recipient, uint256 tokenAmount);

    IERC20 public immutable token;

    mapping(address => mapping(uint256 => VestingSchedule)) public vestingSchedules;
    mapping(address => uint256) private vestingIds;

    uint256 public totalAllocatedAmount;
    uint256 public totalCollectedTax;

    address public proposedOwner;

    string constant INVALID_MULTISIG = "Invalid Multisig contract";
    string constant INVALID_TOKEN = "Invalid Token contract";
    string constant INSUFFICIENT_TOKEN_BALANCE = "Insufficient token balance";
    string constant NO_TOKENS_VESTED_PER_WEEK = "No token vested per week";
    string constant INVALID_START_TIME = "Invalid start time";
    string constant INVALID_DURATION = "Invalid duration";
    string constant INVALID_TAX_RATE = "Invlaid tax rate";
    string constant INVALID_CLIFF_DURATION = "Invalid cliff duration";
    string constant NO_ACTIVE_VESTINGS = "No active vestings";
    string constant INVALID_VESTING_ID = "Invalid vestingId";
    string constant NO_TOKENS_VESTED = "No tokens vested";
    string constant TERMINATION_TIME_BEFORE_LAST_CLAIM = "Terminate before the last claim";
    string constant TERMINATION_TIME_BEFORE_START_TIME = "Terminate before the start time";
    string constant ERROR_CALLER_ALREADY_OWNER = "Already owner";
    string constant ERROR_NOT_PROPOSED_OWNER = "Not proposed owner";
    string constant MAX_ADD_LIMIT = "Can only add 30 max";
    string constant NO_SHEDULES_TO_ADD = "No schedules to add";
    string constant INVALID_PARTIAL_VESTING = "Total claimed more than amount";

    constructor(IERC20 _token, address multisig) {
        require(address(multisig) != address(0), INVALID_MULTISIG);
        require(address(_token) != address(0), INVALID_TOKEN);
        token = _token;

        _transferOwnership(multisig);
    }

    /**
     * @notice Add a new vesting schedule for a recipient address.
     *         for _delayType Cliff vesting, _durationInWeeks need be greater than _delayInWeeks.
     *
     * @param _recipient recipient of the vested tokens from the schedule
     * @param _startTime starting time for vesting schedule, including any delays
     * @param _amount amount to vest over the vesting duration
     * @param _durationInWeeks duration of the vesting schedule in weeks
     * @param _delayInWeeks delay/cliff of the vesting schedule in weeks
     * @param _taxRate100 tax rate, multiplied by 100 to allow fractionals
     * @param _delayType type of the schedule delay Delay/Cliff
     */
    function addVestingSchedule(
        address _recipient,
        uint256 _startTime,
        uint256 _amount,
        uint16 _durationInWeeks,
        uint16 _delayInWeeks,
        uint16 _taxRate100,
        DelayType _delayType,
        uint256 _totalClaimed,
        uint256 _totalTaxClaimed
    ) public onlyOwner {
        uint256 availableBalance = token.balanceOf(address(this)) - totalAllocatedAmount;
        require(_amount <= availableBalance, INSUFFICIENT_TOKEN_BALANCE);
        require(_durationInWeeks > 0, INVALID_DURATION);
        require((_totalClaimed + _totalTaxClaimed) <= _amount, INVALID_PARTIAL_VESTING);

        uint256 amountVestedPerWeek = _amount / _durationInWeeks;
        require(amountVestedPerWeek > 0, NO_TOKENS_VESTED_PER_WEEK);
        require(_startTime > 0, INVALID_START_TIME);
        require(_taxRate100 <= 10000, INVALID_TAX_RATE);

        if (_delayType == DelayType.Cliff) {
            require(_durationInWeeks > _delayInWeeks, INVALID_CLIFF_DURATION);
        }

        VestingSchedule memory vesting = VestingSchedule({
            startTime: _startTime,
            amount: _amount,
            durationInWeeks: _durationInWeeks,
            delayType: _delayType,
            delayInWeeks: _delayInWeeks,
            totalClaimed: _totalClaimed,
            totalTaxClaimed: _totalTaxClaimed,
            taxRate100: _taxRate100,
            terminationTime: 0
        });

        uint256 vestingId = vestingIds[_recipient];

        require(vestingId < 100, "Maximum vesting schedules for recipient reached");

        vestingSchedules[_recipient][vestingId] = vesting;
        vestingIds[_recipient] = vestingId + 1;

        emit VestingAdded(
            vestingId,
            vesting.startTime,
            _amount,
            _recipient,
            _durationInWeeks,
            _delayInWeeks,
            _taxRate100,
            _delayType,
            _totalClaimed,
            _totalTaxClaimed
        );

        // If the schedule is already partially claimed, reduce that amout from the total
        totalAllocatedAmount += (_amount - grossClaimed(vesting));
    }

    /**
     * @notice Add multiple vesting schedules. Refer to addVestingSchedule for indevidual argument reference.
     * @param schedules Array of schedules with max 30 elements.
     */
    function addVestingSchedules(AddVestingScheduleInput[] calldata schedules) public onlyOwner {
        require(schedules.length <= 30, MAX_ADD_LIMIT);
        require(schedules.length > 0, NO_SHEDULES_TO_ADD);

        for (uint256 idx = 0; idx < schedules.length; ++idx) {
            addVestingSchedule(
                schedules[idx].recipient,
                schedules[idx].startTime,
                schedules[idx].amount,
                schedules[idx].durationInWeeks,
                schedules[idx].delayInWeeks,
                schedules[idx].taxRate100,
                schedules[idx].delayType,
                schedules[idx].totalClaimed,
                schedules[idx].totalTaxClaimed
            );
        }
    }

    /**
     * @notice Get the vesting schedlue couunt per recipient.
     * @param _recipient recipient for vesting schedules.
     * @return uint256 count
     */
    function getVestingCount(address _recipient) public view returns (uint256) {
        return vestingIds[_recipient];
    }

    /**
     * @notice Calculate vesting claims of all schedules for recipient.
     * @param _recipient recipient for vesting schedules.
     * @return VestedTokens vested token amount and tax.
     */
    function calculateTotalVestingClaim(address _recipient) public view returns (VestedTokens memory) {
        uint256 vestingCount = vestingIds[_recipient];
        require(vestingCount > 0, NO_ACTIVE_VESTINGS);

        uint256 totalAmountVested;
        uint256 vestedTax;

        for (uint256 _vestingId = 0; _vestingId < vestingCount; ++_vestingId) {
            VestedTokens memory vested = calculateVestingClaim(_recipient, _vestingId);

            totalAmountVested += vested.amount;
            vestedTax += vested.tax;
        }

        return VestedTokens({amount: totalAmountVested, tax: vestedTax});
    }

    /**
     * @notice Calculate vesting claim per vesting schedule.
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @return VestedTokens vested token amount and tax.
     */
    function calculateVestingClaim(address _recipient, uint256 _vestingId) public view returns (VestedTokens memory) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];
        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        return _calculateVestingClaim(vestingSchedule);
    }

    /**
     * @notice Calculate vesting claim per vesting schedule.
     * @param vestingSchedule vesting schedule to calculate the vested amount.
     * @return VestedTokens vested token amount and tax.
     */
    function _calculateVestingClaim(VestingSchedule storage vestingSchedule)
        internal
        view
        returns (VestedTokens memory)
    {
        uint256 grossAmountVested = _calculateVestingClaimAtTime(vestingSchedule, currentTime());
        uint256 tax = calculateTax(grossAmountVested, vestingSchedule.taxRate100);

        return VestedTokens({amount: grossAmountVested - tax, tax: tax});
    }

    /**
     * @notice Calculate the vesting claim at the time for a scedule.
     * @param vestingSchedule vesting schedule to calculate the vested amount.
     * @param _currentTime time to calculate the vesting on.
     * @return uint256 vested gross token amount.
     */
    function _calculateVestingClaimAtTime(VestingSchedule storage vestingSchedule, uint256 _currentTime)
        internal
        view
        returns (uint256)
    {
        uint256 effectiveCurrentTime = vestingSchedule.terminationTime == 0
            ? _currentTime
            : Math.min(_currentTime, vestingSchedule.terminationTime);

        if (effectiveCurrentTime < vestingSchedule.startTime) {
            return 0;
        }

        uint256 elapsedTime = effectiveCurrentTime - vestingSchedule.startTime;
        uint256 elapsedTimeInWeeks = elapsedTime / SECONDS_PER_WEEK;

        // in both Cliff and Delay, nothing can be vested until the delay period
        if (elapsedTimeInWeeks < vestingSchedule.delayInWeeks) {
            return 0;
        }

        // Cliifs are vested during the delay, Delays are added to the duration
        uint256 effectiveDuration = vestingSchedule.delayType == DelayType.Delay
            ? vestingSchedule.durationInWeeks + vestingSchedule.delayInWeeks
            : vestingSchedule.durationInWeeks;

        if (elapsedTimeInWeeks >= effectiveDuration) {
            uint256 remainingVesting = vestingSchedule.amount - grossClaimed(vestingSchedule);

            return remainingVesting;
        } else {
            // Cliifs are vested during the delay, Delays are added to the duration
            uint16 claimableWeeks = vestingSchedule.delayType == DelayType.Delay
                ? uint16(elapsedTimeInWeeks - vestingSchedule.delayInWeeks)
                : uint16(elapsedTimeInWeeks);

            uint256 amountVestedPerWeek = vestingSchedule.amount / vestingSchedule.durationInWeeks;
            uint256 claimableAmount = claimableWeeks * amountVestedPerWeek;

            // This happens if the shedule was already partially vested when its added.
            if (grossClaimed(vestingSchedule) > claimableAmount) {
                return 0;
            }

            uint256 amountVested = claimableAmount - grossClaimed(vestingSchedule);

            return amountVested;
        }
    }

    /**
     * @notice Claim vested tokens and send to recipient's address.
     *         msg.sender is the recipient.
     * @dev    Need to have atleast 1 active vesting, and vest at leat 1 token to be successful.
     */
    function claimVestedTokens() external {
        require(!paused(), "claimVestedTokens() is not enabled");

        uint256 vestingCount = vestingIds[msg.sender];
        require(vestingCount > 0, NO_ACTIVE_VESTINGS);

        uint256 totalAmountVested;
        uint256 vestedTax;

        for (uint256 _vestingId = 0; _vestingId < vestingCount; ++_vestingId) {
            VestingSchedule storage vestingSchedule = vestingSchedules[msg.sender][_vestingId];

            VestedTokens memory tokensVested = _calculateVestingClaim(vestingSchedule);

            vestingSchedule.totalClaimed = uint256(vestingSchedule.totalClaimed + tokensVested.amount);
            vestingSchedule.totalTaxClaimed = uint256(vestingSchedule.totalTaxClaimed + tokensVested.tax);

            totalAmountVested += tokensVested.amount;
            vestedTax += tokensVested.tax;
        }

        require(token.balanceOf(address(this)) >= totalAmountVested, NO_TOKENS_VESTED);

        totalCollectedTax += vestedTax;
        totalAllocatedAmount -= totalAmountVested;

        token.safeTransfer(msg.sender, totalAmountVested);
        emit VestingTokensClaimed(msg.sender, vestingCount, totalAmountVested, vestedTax);
    }

    /**
     * @notice Terminate vesting shedule by recipient and vestingId.
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @param _terminationTime time the shedule would terminate at.
     *
     * @dev Terminating time should be after start date and the last date vesing is claimed.
     */
    function terminateVestingSchedule(
        address _recipient,
        uint256 _vestingId,
        uint256 _terminationTime
    ) external onlyOwner {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];

        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        uint256 lastVestedTime = _calculateLastVestedTimestamp(vestingSchedule);

        require(_terminationTime >= lastVestedTime, TERMINATION_TIME_BEFORE_LAST_CLAIM);
        require(_terminationTime >= vestingSchedule.startTime, TERMINATION_TIME_BEFORE_START_TIME);

        uint256 grossAmountToBeVested = _calculateVestingClaimAtTime(vestingSchedule, _terminationTime);

        uint256 amountIneligibleForVesting = vestingSchedule.amount -
            (grossClaimed(vestingSchedule) + grossAmountToBeVested);

        vestingSchedule.terminationTime = _terminationTime;

        totalAllocatedAmount -= amountIneligibleForVesting;
        emit VestingRemoved(_recipient, _vestingId, grossAmountToBeVested, amountIneligibleForVesting);
    }

    function _calculateLastVestedTimestamp(VestingSchedule storage vestingSchedule) internal view returns (uint256) {
        if (vestingSchedule.totalClaimed == 0) {
            return vestingSchedule.startTime;
        }

        uint256 amountVestedPerWeek = vestingSchedule.amount / vestingSchedule.durationInWeeks;
        uint256 weeksClaimed = grossClaimed(vestingSchedule) / amountVestedPerWeek;

        uint256 effectiveDelayInWeeks = vestingSchedule.delayType == DelayType.Delay ? vestingSchedule.delayInWeeks : 0;
        return vestingSchedule.startTime + effectiveDelayInWeeks + (weeksClaimed * SECONDS_PER_WEEK);
    }

    function currentTime() public view virtual returns (uint256) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp;
    }

    /**
     * @notice Calculate tokens vested per-week, for a schedule by vestingId
     * @param _recipient recipient for vesting schedules.
     * @param _vestingId vesting schedule id (incrementing numnber based on count).
     * @return VestedTokens vested tokens and tax per week.
     */
    function tokensVestedPerWeek(address _recipient, uint256 _vestingId) public view returns (VestedTokens memory) {
        VestingSchedule storage vestingSchedule = vestingSchedules[_recipient][_vestingId];
        require(vestingSchedule.startTime > 0, INVALID_VESTING_ID);

        uint256 gross = vestingSchedule.amount / vestingSchedule.durationInWeeks;
        uint256 tax = (gross * vestingSchedule.taxRate100) / 10000;
        return VestedTokens({amount: gross - tax, tax: tax});
    }

    /**
     * @dev Calculate the gross amount including both claimed and tax.
     * @param vestingSchedule vesting schedule to calculate the gross claimed amount
     */
    function grossClaimed(VestingSchedule memory vestingSchedule) internal pure returns (uint256) {
        return vestingSchedule.totalClaimed + vestingSchedule.totalTaxClaimed;
    }

    /**
     * @dev Calcualte tax for gross amount.
     * @param gross gross amount to be claimed
     * @param taxRate100 Percentage tax rate * 100
     */
    function calculateTax(uint256 gross, uint256 taxRate100) internal pure returns (uint256) {
        return (gross * taxRate100) / 10000;
    }

    /**
     * @notice Withdraw tax collected in the contract.
     * @param recipient recipient for vesting schedules.
     */
    function withdrawTax(address recipient) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);

        uint256 balance = token.balanceOf(address(this));

        require(totalCollectedTax <= (balance - totalAllocatedAmount), INSUFFICIENT_TOKEN_BALANCE);

        uint256 taxClaimable = totalCollectedTax;
        totalCollectedTax = 0;
        totalAllocatedAmount -= taxClaimable;

        token.safeTransfer(recipient, taxClaimable);
        emit TaxWithdrawn(recipient, taxClaimable);
    }

    /**
     * @notice Withdraw tokens that are not allocated for a vesting schedule.
     * @param recipient recipient for vesting schedules.
     */
    function withdrawUnAllocatedToken(address recipient) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);

        uint256 balance = token.balanceOf(address(this));
        uint256 unAllocatedAmount = balance - totalAllocatedAmount;

        require(unAllocatedAmount > 0, INSUFFICIENT_TOKEN_BALANCE);

        token.safeTransfer(recipient, unAllocatedAmount);
        emit TokenWithdrawn(recipient, unAllocatedAmount);
    }

    /**
     * @notice WARNING! withdraw tokens remaining in the contract. Used for migrating contracts.
     * @param recipient recipient for vesting schedules.
     * @param amount amount to withdraw from the contract.
     */
    function withdrawToken(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), INVALID_TOKEN);
        uint256 balance = token.balanceOf(address(this));
        require(amount <= balance, INSUFFICIENT_TOKEN_BALANCE);
        token.safeTransfer(recipient, amount);
        emit TokenWithdrawn(recipient, amount);
    }

    /**
     * @notice Propose a new owner of the contract.
     * @param _proposedOwner The proposed new owner of the contract.
     */
    function proposeOwner(address _proposedOwner) external onlyOwner {
        require(msg.sender != _proposedOwner, ERROR_CALLER_ALREADY_OWNER);
        proposedOwner = _proposedOwner;
    }

    /**
     * @notice Claim ownership by calling the function as the proposed owner.
     */
    function claimOwnership() external {
        require(address(proposedOwner) != address(0), INVALID_MULTISIG);
        require(msg.sender == proposedOwner, ERROR_NOT_PROPOSED_OWNER);

        emit OwnershipTransferred(owner(), proposedOwner);
        _transferOwnership(proposedOwner);
        proposedOwner = address(0);
    }

    /**
     * @notice Pause the claiming process
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the claiming process
     */
    function unpause() external onlyOwner {
        _unpause();
    }
}