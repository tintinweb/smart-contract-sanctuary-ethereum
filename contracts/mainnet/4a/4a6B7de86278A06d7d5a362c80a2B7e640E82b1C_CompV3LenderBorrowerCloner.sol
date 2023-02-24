/**
 *Submitted for verification at Etherscan.io on 2023-02-24
*/

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.15;
pragma experimental ABIEncoderV2;

// File: Address.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// File: IERC20.sol

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: IERC20Extended.sol

interface IERC20Extended {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// File: IUniswapV3SwapCallback.sol

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}
// File: Math.sol

// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

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

// File: draft-IERC20Permit.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

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

// File: CompoundV3.sol

library CometStructs {
  struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
  }

  struct UserBasic {
    int104 principal;
    uint64 baseTrackingIndex;
    uint64 baseTrackingAccrued;
    uint16 assetsIn;
    uint8 _reserved;
  }

  struct TotalsBasic {
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
  }

  struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
  }

  struct RewardOwed {
    address token;
    uint owed;
  }

  struct TotalsCollateral {
    uint128 totalSupplyAsset;
    uint128 _reserved;
  }

  struct RewardConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpscale;
    }
}

interface Comet is IERC20 {
  function baseScale() external view returns (uint);
  function supply(address asset, uint amount) external;
  function supplyTo(address to, address asset, uint amount) external;
  function withdraw(address asset, uint amount) external;

  function getSupplyRate(uint utilization) external view returns (uint);
  function getBorrowRate(uint utilization) external view returns (uint);

  function getAssetInfoByAddress(address asset) external view returns (CometStructs.AssetInfo memory);
  function getAssetInfo(uint8 i) external view returns (CometStructs.AssetInfo memory);

  function borrowBalanceOf(address account) external view returns (uint256);

  function getPrice(address priceFeed) external view returns (uint128);

  function userBasic(address) external view returns (CometStructs.UserBasic memory);
  function totalsBasic() external view returns (CometStructs.TotalsBasic memory);
  function userCollateral(address, address) external view returns (CometStructs.UserCollateral memory);

  function baseTokenPriceFeed() external view returns (address);

  function numAssets() external view returns (uint8);

  function getUtilization() external view returns (uint);

  function baseTrackingSupplySpeed() external view returns (uint);
  function baseTrackingBorrowSpeed() external view returns (uint);

  function totalSupply() override external view returns (uint256);
  function totalBorrow() external view returns (uint256);

  function baseIndexScale() external pure returns (uint64);
  function baseTrackingAccrued(address account) external view returns (uint64);

  function totalsCollateral(address asset) external view returns (CometStructs.TotalsCollateral memory);

  function baseMinForRewards() external view returns (uint256);
  function baseToken() external view returns (address);

  function accrueAccount(address account) external;
  
  function isLiquidatable(address _address) external view returns(bool);
  function baseBorrowMin() external view returns(uint256);
}

interface CometRewards {
  function getRewardOwed(address comet, address account) external returns (CometStructs.RewardOwed memory);
  function claim(address comet, address src, bool shouldAccrue) external;

  function rewardsClaimed(address comet, address account) external view returns(uint256);
  function rewardConfig(address comet) external view returns (CometStructs.RewardConfig memory);
}
// File: IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: ISwapRouter.sol

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params)
        external
        payable
        returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params)
        external
        payable
        returns (uint256 amountIn);

    // Taken from https://soliditydeveloper.com/uniswap3
    // Manually added to the interface
    function refundETH() external payable;
}
// File: IVault.sol

interface IVault is IERC20 {
    function token() external view returns (address);

    function decimals() external view returns (uint256);

    function deposit() external;

    function pricePerShare() external view returns (uint256);

    function withdraw() external returns (uint256);

    function withdraw(uint256 amount) external returns (uint256);

    function withdraw(
        uint256 amount,
        address account,
        uint256 maxLoss
    ) external returns (uint256);

    function availableDepositLimit() external view returns (uint256);

    function governance() external view returns (address);
}

// File: SafeERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

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

// File: ERC20.sol

// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: IStrategy.sol

interface IStrategy {
    function name() external view returns (string memory);

    function vault() external view returns (IVault);

    function want() external view returns (IERC20);

    function strategist() external view returns (address);

    function keeper() external view returns (address);

    function depositer() external view returns (address);

    function baseToken() external view returns (address);

    function estimatedTotalAssets() external view returns (uint256);
}
// File: BaseStrategy.sol

struct StrategyParams {
    uint256 performanceFee;
    uint256 activation;
    uint256 debtRatio;
    uint256 minDebtPerHarvest;
    uint256 maxDebtPerHarvest;
    uint256 lastReport;
    uint256 totalDebt;
    uint256 totalGain;
    uint256 totalLoss;
}

interface VaultAPI is IERC20 {
    function name() external view returns (string calldata);

    function symbol() external view returns (string calldata);

    function decimals() external view returns (uint256);

    function apiVersion() external pure returns (string memory);

    function permit(
        address owner,
        address spender,
        uint256 amount,
        uint256 expiry,
        bytes calldata signature
    ) external returns (bool);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function deposit() external returns (uint256);

    function deposit(uint256 amount) external returns (uint256);

    function deposit(uint256 amount, address recipient) external returns (uint256);

    // NOTE: Vyper produces multiple signatures for a given function with "default" args
    function withdraw() external returns (uint256);

    function withdraw(uint256 maxShares) external returns (uint256);

    function withdraw(uint256 maxShares, address recipient) external returns (uint256);

    function token() external view returns (address);

    function strategies(address _strategy) external view returns (StrategyParams memory);

    function pricePerShare() external view returns (uint256);

    function totalAssets() external view returns (uint256);

    function depositLimit() external view returns (uint256);

    function maxAvailableShares() external view returns (uint256);

    /**
     * View how much the Vault would increase this Strategy's borrow limit,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function creditAvailable() external view returns (uint256);

    /**
     * View how much the Vault would like to pull back from the Strategy,
     * based on its present performance (since its last report). Can be used to
     * determine expectedReturn in your Strategy.
     */
    function debtOutstanding() external view returns (uint256);

    /**
     * View how much the Vault expect this Strategy to return at the current
     * block, based on its present performance (since its last report). Can be
     * used to determine expectedReturn in your Strategy.
     */
    function expectedReturn() external view returns (uint256);

    /**
     * This is the main contact point where the Strategy interacts with the
     * Vault. It is critical that this call is handled as intended by the
     * Strategy. Therefore, this function will be called by BaseStrategy to
     * make sure the integration is correct.
     */
    function report(
        uint256 _gain,
        uint256 _loss,
        uint256 _debtPayment
    ) external returns (uint256);

    /**
     * This function should only be used in the scenario where the Strategy is
     * being retired but no migration of the positions are possible, or in the
     * extreme scenario that the Strategy needs to be put into "Emergency Exit"
     * mode in order for it to exit as quickly as possible. The latter scenario
     * could be for any reason that is considered "critical" that the Strategy
     * exits its position as fast as possible, such as a sudden change in
     * market conditions leading to losses, or an imminent failure in an
     * external dependency.
     */
    function revokeStrategy() external;

    /**
     * View the governance address of the Vault to assert privileged functions
     * can only be called by governance. The Strategy serves the Vault, so it
     * is subject to governance defined by the Vault.
     */
    function governance() external view returns (address);

    /**
     * View the management address of the Vault to assert privileged functions
     * can only be called by management. The Strategy serves the Vault, so it
     * is subject to management defined by the Vault.
     */
    function management() external view returns (address);

    /**
     * View the guardian address of the Vault to assert privileged functions
     * can only be called by guardian. The Strategy serves the Vault, so it
     * is subject to guardian defined by the Vault.
     */
    function guardian() external view returns (address);
}

/**
 * This interface is here for the keeper bot to use.
 */
interface StrategyAPI {
    function name() external view returns (string memory);

    function vault() external view returns (address);

    function want() external view returns (address);

    function apiVersion() external pure returns (string memory);

    function keeper() external view returns (address);

    function isActive() external view returns (bool);

    function delegatedAssets() external view returns (uint256);

    function estimatedTotalAssets() external view returns (uint256);

    function tendTrigger(uint256 callCost) external view returns (bool);

    function tend() external;

    function harvestTrigger(uint256 callCost) external view returns (bool);

    function harvest() external;

    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);
}

interface HealthCheck {
    function check(
        uint256 profit,
        uint256 loss,
        uint256 debtPayment,
        uint256 debtOutstanding,
        uint256 totalDebt
    ) external view returns (bool);
}

interface IBaseFee {
    function isCurrentBaseFeeAcceptable() external view returns (bool);
}

/**
 * @title Yearn Base Strategy
 * @author yearn.finance
 * @notice
 *  BaseStrategy implements all of the required functionality to interoperate
 *  closely with the Vault contract. This contract should be inherited and the
 *  abstract methods implemented to adapt the Strategy to the particular needs
 *  it has to create a return.
 *
 *  Of special interest is the relationship between `harvest()` and
 *  `vault.report()'. `harvest()` may be called simply because enough time has
 *  elapsed since the last report, and not because any funds need to be moved
 *  or positions adjusted. This is critical so that the Vault may maintain an
 *  accurate picture of the Strategy's performance. See  `vault.report()`,
 *  `harvest()`, and `harvestTrigger()` for further details.
 */

abstract contract BaseStrategy {
    using SafeERC20 for IERC20;
    string public metadataURI;

    // health checks
    bool public doHealthCheck;
    address public healthCheck;

    /**
     * @notice
     *  Used to track which version of `StrategyAPI` this Strategy
     *  implements.
     * @dev The Strategy's version must match the Vault's `API_VERSION`.
     * @return A string which holds the current API version of this contract.
     */
    function apiVersion() public pure returns (string memory) {
        return "0.4.5";
    }

    /**
     * @notice This Strategy's name.
     * @dev
     *  You can use this field to manage the "version" of this Strategy, e.g.
     *  `StrategySomethingOrOtherV1`. However, "API Version" is managed by
     *  `apiVersion()` function above.
     * @return This Strategy's name.
     */
    function name() external view virtual returns (string memory);

    /**
     * @notice
     *  The amount (priced in want) of the total assets managed by this strategy should not count
     *  towards Yearn's TVL calculations.
     * @dev
     *  You can override this field to set it to a non-zero value if some of the assets of this
     *  Strategy is somehow delegated inside another part of of Yearn's ecosystem e.g. another Vault.
     *  Note that this value must be strictly less than or equal to the amount provided by
     *  `estimatedTotalAssets()` below, as the TVL calc will be total assets minus delegated assets.
     *  Also note that this value is used to determine the total assets under management by this
     *  strategy, for the purposes of computing the management fee in `Vault`
     * @return
     *  The amount of assets this strategy manages that should not be included in Yearn's Total Value
     *  Locked (TVL) calculation across it's ecosystem.
     */
    function delegatedAssets() external view virtual returns (uint256) {
        return 0;
    }

    VaultAPI public vault;
    address public strategist;
    address public rewards;
    address public keeper;

    IERC20 public want;

    // So indexers can keep track of this
    event Harvested(uint256 profit, uint256 loss, uint256 debtPayment, uint256 debtOutstanding);

    event UpdatedStrategist(address newStrategist);

    event UpdatedKeeper(address newKeeper);

    event UpdatedRewards(address rewards);

    event UpdatedMinReportDelay(uint256 delay);

    event UpdatedMaxReportDelay(uint256 delay);

    event UpdatedBaseFeeOracle(address baseFeeOracle);

    event UpdatedCreditThreshold(uint256 creditThreshold);

    event ForcedHarvestTrigger(bool triggerState);

    event EmergencyExitEnabled();

    event UpdatedMetadataURI(string metadataURI);

    event SetHealthCheck(address);
    event SetDoHealthCheck(bool);

    // The minimum number of seconds between harvest calls. See
    // `setMinReportDelay()` for more details.
    uint256 public minReportDelay;

    // The maximum number of seconds between harvest calls. See
    // `setMaxReportDelay()` for more details.
    uint256 public maxReportDelay;

    // See note on `setEmergencyExit()`.
    bool public emergencyExit;

    // See note on `isBaseFeeOracleAcceptable()`.
    address public baseFeeOracle;

    // See note on `setCreditThreshold()`
    uint256 public creditThreshold;

    // See note on `setForceHarvestTriggerOnce`
    bool public forceHarvestTriggerOnce;

    // modifiers
    modifier onlyAuthorized() {
        _onlyAuthorized();
        _;
    }

    modifier onlyEmergencyAuthorized() {
        _onlyEmergencyAuthorized();
        _;
    }

    modifier onlyStrategist() {
        _onlyStrategist();
        _;
    }

    modifier onlyGovernance() {
        _onlyGovernance();
        _;
    }

    modifier onlyRewarder() {
        _onlyRewarder();
        _;
    }

    modifier onlyKeepers() {
        _onlyKeepers();
        _;
    }

    modifier onlyVaultManagers() {
        _onlyVaultManagers();
        _;
    }

    function _onlyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance());
    }

    function _onlyEmergencyAuthorized() internal {
        require(msg.sender == strategist || msg.sender == governance() || msg.sender == vault.guardian() || msg.sender == vault.management());
    }

    function _onlyStrategist() internal {
        require(msg.sender == strategist);
    }

    function _onlyGovernance() internal {
        require(msg.sender == governance());
    }

    function _onlyRewarder() internal {
        require(msg.sender == governance() || msg.sender == strategist);
    }

    function _onlyKeepers() internal {
        require(
            msg.sender == keeper ||
                msg.sender == strategist ||
                msg.sender == governance() ||
                msg.sender == vault.guardian() ||
                msg.sender == vault.management()
        );
    }

    function _onlyVaultManagers() internal {
        require(msg.sender == vault.management() || msg.sender == governance());
    }

    constructor(address _vault) {
        _initialize(_vault, msg.sender, msg.sender, msg.sender);
    }

    /**
     * @notice
     *  Initializes the Strategy, this is called only once, when the
     *  contract is deployed.
     * @dev `_vault` should implement `VaultAPI`.
     * @param _vault The address of the Vault responsible for this Strategy.
     * @param _strategist The address to assign as `strategist`.
     * The strategist is able to change the reward address
     * @param _rewards  The address to use for pulling rewards.
     * @param _keeper The adddress of the _keeper. _keeper
     * can harvest and tend a strategy.
     */
    function _initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) internal {
        require(address(want) == address(0), "Strategy already initialized");

        vault = VaultAPI(_vault);
        want = IERC20(vault.token());
        want.safeApprove(_vault, type(uint256).max); // Give Vault unlimited access (might save gas)
        strategist = _strategist;
        rewards = _rewards;
        keeper = _keeper;

        // initialize variables
        maxReportDelay = 30 days;
        creditThreshold = 1_000_000 * 10**vault.decimals(); // set this high by default so we don't get tons of false triggers if not changed

        vault.approve(rewards, type(uint256).max); // Allow rewards to be pulled
    }

    function setHealthCheck(address _healthCheck) external onlyVaultManagers {
        emit SetHealthCheck(_healthCheck);
        healthCheck = _healthCheck;
    }

    function setDoHealthCheck(bool _doHealthCheck) external onlyVaultManagers {
        emit SetDoHealthCheck(_doHealthCheck);
        doHealthCheck = _doHealthCheck;
    }

    /**
     * @notice
     *  Used to change `strategist`.
     *
     *  This may only be called by governance or the existing strategist.
     * @param _strategist The new address to assign as `strategist`.
     */
    function setStrategist(address _strategist) external onlyAuthorized {
        require(_strategist != address(0));
        strategist = _strategist;
        emit UpdatedStrategist(_strategist);
    }

    /**
     * @notice
     *  Used to change `keeper`.
     *
     *  `keeper` is the only address that may call `tend()` or `harvest()`,
     *  other than `governance()` or `strategist`. However, unlike
     *  `governance()` or `strategist`, `keeper` may *only* call `tend()`
     *  and `harvest()`, and no other authorized functions, following the
     *  principle of least privilege.
     *
     *  This may only be called by governance or the strategist.
     * @param _keeper The new address to assign as `keeper`.
     */
    function setKeeper(address _keeper) external onlyAuthorized {
        require(_keeper != address(0));
        keeper = _keeper;
        emit UpdatedKeeper(_keeper);
    }

    /**
     * @notice
     *  Used to change `rewards`. EOA or smart contract which has the permission
     *  to pull rewards from the vault.
     *
     *  This may only be called by the strategist.
     * @param _rewards The address to use for pulling rewards.
     */
    function setRewards(address _rewards) external onlyRewarder {
        require(_rewards != address(0));
        vault.approve(rewards, 0);
        rewards = _rewards;
        vault.approve(rewards, type(uint256).max);
        emit UpdatedRewards(_rewards);
    }

    /**
     * @notice
     *  Used to change `minReportDelay`. `minReportDelay` is the minimum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the minimum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The minimum number of seconds to wait between harvests.
     */
    function setMinReportDelay(uint256 _delay) external onlyAuthorized {
        minReportDelay = _delay;
        emit UpdatedMinReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to change `maxReportDelay`. `maxReportDelay` is the maximum number
     *  of blocks that should pass for `harvest()` to be called.
     *
     *  For external keepers (such as the Keep3r network), this is the maximum
     *  time between jobs to wait. (see `harvestTrigger()`
     *  for more details.)
     *
     *  This may only be called by governance or the strategist.
     * @param _delay The maximum number of seconds to wait between harvests.
     */
    function setMaxReportDelay(uint256 _delay) external onlyAuthorized {
        maxReportDelay = _delay;
        emit UpdatedMaxReportDelay(_delay);
    }

    /**
     * @notice
     *  Used to ensure that any significant credit a strategy has from the
     *  vault will be automatically harvested.
     *
     *  This may only be called by governance or management.
     * @param _creditThreshold The number of want tokens that will
     *  automatically trigger a harvest.
     */
    function setCreditThreshold(uint256 _creditThreshold) external onlyVaultManagers {
        creditThreshold = _creditThreshold;
        emit UpdatedCreditThreshold(_creditThreshold);
    }

    /**
     * @notice
     *  Used to automatically trigger a harvest by our keepers. Can be
     *  useful if gas prices are too high now, and we want to harvest
     *  later once prices have lowered.
     *
     *  This may only be called by governance or management.
     * @param _forceHarvestTriggerOnce Value of true tells keepers to harvest
     *  our strategy
     */
    function setForceHarvestTriggerOnce(bool _forceHarvestTriggerOnce) external onlyVaultManagers {
        forceHarvestTriggerOnce = _forceHarvestTriggerOnce;
        emit ForcedHarvestTrigger(_forceHarvestTriggerOnce);
    }

    /**
     * @notice
     *  Used to set our baseFeeOracle, which checks the network's current base
     *  fee price to determine whether it is an optimal time to harvest or tend.
     *
     *  This may only be called by governance or management.
     * @param _baseFeeOracle Address of our baseFeeOracle
     */
    function setBaseFeeOracle(address _baseFeeOracle) external onlyVaultManagers {
        baseFeeOracle = _baseFeeOracle;
        emit UpdatedBaseFeeOracle(_baseFeeOracle);
    }

    /**
     * @notice
     *  Used to change `metadataURI`. `metadataURI` is used to store the URI
     * of the file describing the strategy.
     *
     *  This may only be called by governance or the strategist.
     * @param _metadataURI The URI that describe the strategy.
     */
    function setMetadataURI(string calldata _metadataURI) external onlyAuthorized {
        metadataURI = _metadataURI;
        emit UpdatedMetadataURI(_metadataURI);
    }

    /**
     * Resolve governance address from Vault contract, used to make assertions
     * on protected functions in the Strategy.
     */
    function governance() internal view returns (address) {
        return vault.governance();
    }

    /**
     * @notice
     *  Provide an accurate conversion from `_amtInWei` (denominated in wei)
     *  to `want` (using the native decimal characteristics of `want`).
     * @dev
     *  Care must be taken when working with decimals to assure that the conversion
     *  is compatible. As an example:
     *
     *      given 1e17 wei (0.1 ETH) as input, and want is USDC (6 decimals),
     *      with USDC/ETH = 1800, this should give back 1800000000 (180 USDC)
     *
     * @param _amtInWei The amount (in wei/1e-18 ETH) to convert to `want`
     * @return The amount in `want` of `_amtInEth` converted to `want`
     **/
    function ethToWant(uint256 _amtInWei) public view virtual returns (uint256);

    /**
     * @notice
     *  Provide an accurate estimate for the total amount of assets
     *  (principle + return) that this Strategy is currently managing,
     *  denominated in terms of `want` tokens.
     *
     *  This total should be "realizable" e.g. the total value that could
     *  *actually* be obtained from this Strategy if it were to divest its
     *  entire position based on current on-chain conditions.
     * @dev
     *  Care must be taken in using this function, since it relies on external
     *  systems, which could be manipulated by the attacker to give an inflated
     *  (or reduced) value produced by this function, based on current on-chain
     *  conditions (e.g. this function is possible to influence through
     *  flashloan attacks, oracle manipulations, or other DeFi attack
     *  mechanisms).
     *
     *  It is up to governance to use this function to correctly order this
     *  Strategy relative to its peers in the withdrawal queue to minimize
     *  losses for the Vault based on sudden withdrawals. This value should be
     *  higher than the total debt of the Strategy and higher than its expected
     *  value to be "safe".
     * @return The estimated total assets in this Strategy.
     */
    function estimatedTotalAssets() public view virtual returns (uint256);

    /*
     * @notice
     *  Provide an indication of whether this strategy is currently "active"
     *  in that it is managing an active position, or will manage a position in
     *  the future. This should correlate to `harvest()` activity, so that Harvest
     *  events can be tracked externally by indexing agents.
     * @return True if the strategy is actively managing a position.
     */
    function isActive() public view returns (bool) {
        return vault.strategies(address(this)).debtRatio > 0 || estimatedTotalAssets() > 0;
    }

    /**
     * Perform any Strategy unwinding or other calls necessary to capture the
     * "free return" this Strategy has generated since the last time its core
     * position(s) were adjusted. Examples include unwrapping extra rewards.
     * This call is only used during "normal operation" of a Strategy, and
     * should be optimized to minimize losses as much as possible.
     *
     * This method returns any realized profits and/or realized losses
     * incurred, and should return the total amounts of profits/losses/debt
     * payments (in `want` tokens) for the Vault's accounting (e.g.
     * `want.balanceOf(this) >= _debtPayment + _profit`).
     *
     * `_debtOutstanding` will be 0 if the Strategy is not past the configured
     * debt limit, otherwise its value will be how far past the debt limit
     * the Strategy is. The Strategy's debt limit is configured in the Vault.
     *
     * NOTE: `_debtPayment` should be less than or equal to `_debtOutstanding`.
     *       It is okay for it to be less than `_debtOutstanding`, as that
     *       should only used as a guide for how much is left to pay back.
     *       Payments should be made to minimize loss from slippage, debt,
     *       withdrawal fees, etc.
     *
     * See `vault.debtOutstanding()`.
     */
    function prepareReturn(uint256 _debtOutstanding)
        internal
        virtual
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        );

    /**
     * Perform any adjustments to the core position(s) of this Strategy given
     * what change the Vault made in the "investable capital" available to the
     * Strategy. Note that all "free capital" in the Strategy after the report
     * was made is available for reinvestment. Also note that this number
     * could be 0, and you should handle that scenario accordingly.
     *
     * See comments regarding `_debtOutstanding` on `prepareReturn()`.
     */
    function adjustPosition(uint256 _debtOutstanding) internal virtual;

    /**
     * Liquidate up to `_amountNeeded` of `want` of this strategy's positions,
     * irregardless of slippage. Any excess will be re-invested with `adjustPosition()`.
     * This function should return the amount of `want` tokens made available by the
     * liquidation. If there is a difference between them, `_loss` indicates whether the
     * difference is due to a realized loss, or if there is some other sitution at play
     * (e.g. locked funds) where the amount made available is less than what is needed.
     *
     * NOTE: The invariant `_liquidatedAmount + _loss <= _amountNeeded` should always be maintained
     */
    function liquidatePosition(uint256 _amountNeeded) internal virtual returns (uint256 _liquidatedAmount, uint256 _loss);

    /**
     * Liquidate everything and returns the amount that got freed.
     * This function is used during emergency exit instead of `prepareReturn()` to
     * liquidate all of the Strategy's positions back to the Vault.
     */

    function liquidateAllPositions() internal virtual returns (uint256 _amountFreed);

    /**
     * @notice
     *  Provide a signal to the keeper that `tend()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `tend()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `tend()` is not called
     *  shortly, then this can return `true` even if the keeper might be
     *  "at a loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `harvestTrigger()` should never return `true` at the same
     *  time.
     * @param callCostInWei The keeper's estimated gas cost to call `tend()` (in wei).
     * @return `true` if `tend()` should be called, `false` otherwise.
     */
    function tendTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // We usually don't need tend, but if there are positions that need
        // active maintainence, overriding this function is how you would
        // signal for that.
        // If your implementation uses the cost of the call in want, you can
        // use uint256 callCost = ethToWant(callCostInWei);
        // It is highly suggested to use the baseFeeOracle here as well.

        return false;
    }

    /**
     * @notice
     *  Adjust the Strategy's position. The purpose of tending isn't to
     *  realize gains, but to maximize yield by reinvesting any returns.
     *
     *  See comments on `adjustPosition()`.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     */
    function tend() external onlyKeepers {
        // Don't take profits with this call, but adjust for better gains
        adjustPosition(vault.debtOutstanding());
    }

    /**
     * @notice
     *  Provide a signal to the keeper that `harvest()` should be called. The
     *  keeper will provide the estimated gas cost that they would pay to call
     *  `harvest()`, and this function should use that estimate to make a
     *  determination if calling it is "worth it" for the keeper. This is not
     *  the only consideration into issuing this trigger, for example if the
     *  position would be negatively affected if `harvest()` is not called
     *  shortly, then this can return `true` even if the keeper might be "at a
     *  loss" (keepers are always reimbursed by Yearn).
     * @dev
     *  `callCostInWei` must be priced in terms of `wei` (1e-18 ETH).
     *
     *  This call and `tendTrigger` should never return `true` at the
     *  same time.
     *
     *  See `maxReportDelay`, `creditThreshold` to adjust the
     *  strategist-controlled parameters that will influence whether this call
     *  returns `true` or not. These parameters will be used in conjunction
     *  with the parameters reported to the Vault (see `params`) to determine
     *  if calling `harvest()` is merited.
     *
     *  This trigger also checks the network's base fee to avoid harvesting during
     *  times of high network congestion.
     *
     *  Consider use of super.harvestTrigger() in any override to build on top
     *  of this logic instead of replacing it. For example, if using `minReportDelay`.
     *
     *  It is expected that an external system will check `harvestTrigger()`.
     *  This could be a script run off a desktop or cloud bot (e.g.
     *  https://github.com/iearn-finance/yearn-vaults/blob/main/scripts/keep.py),
     *  or via an integration with the Keep3r network (e.g.
     *  https://github.com/Macarse/GenericKeep3rV2/blob/master/contracts/keep3r/GenericKeep3rV2.sol).
     * @param callCostInWei The keeper's estimated gas cost to call `harvest()` (in wei).
     * @return `true` if `harvest()` should be called, `false` otherwise.
     */
    function harvestTrigger(uint256 callCostInWei) public view virtual returns (bool) {
        // Should not trigger if strategy is not active (no assets or no debtRatio)
        if (!isActive()) return false;

        // check if the base fee gas price is higher than we allow. if it is, block harvests.
        if (!isBaseFeeAcceptable()) return false;

        // trigger if we want to manually harvest, but only if our gas price is acceptable
        if (forceHarvestTriggerOnce) return true;

        // Should trigger if hasn't been called in a while
        StrategyParams memory params = vault.strategies(address(this));
        if ((block.timestamp - params.lastReport) >= maxReportDelay) return true;

        // harvest our credit if it's above our threshold or return false
        return (vault.creditAvailable() > creditThreshold);
    }

    /**
     * @notice
     *  Check if the current network base fee is below our external target. If
     *  not, then harvestTrigger will return false.
     * @return `true` if `harvest()` should be allowed, `false` otherwise.
     */
    function isBaseFeeAcceptable() public view returns (bool) {
        if (baseFeeOracle == address(0)) return true;
        else return IBaseFee(baseFeeOracle).isCurrentBaseFeeAcceptable();
    }

    /**
     * @notice
     *  Harvests the Strategy, recognizing any profits or losses and adjusting
     *  the Strategy's position.
     *
     *  In the rare case the Strategy is in emergency shutdown, this will exit
     *  the Strategy's position.
     *
     *  This may only be called by governance, the strategist, or the keeper.
     * @dev
     *  When `harvest()` is called, the Strategy reports to the Vault (via
     *  `vault.report()`), so in some cases `harvest()` must be called in order
     *  to take in profits, to borrow newly available funds from the Vault, or
     *  otherwise adjust its position. In other cases `harvest()` must be
     *  called to report to the Vault on the Strategy's position, especially if
     *  any losses have occurred.
     */
    function harvest() external onlyKeepers {
        uint256 profit = 0;
        uint256 loss = 0;
        uint256 debtOutstanding = vault.debtOutstanding();
        uint256 debtPayment = 0;
        if (emergencyExit) {
            // Free up as much capital as possible
            uint256 amountFreed = liquidateAllPositions();
            if (amountFreed < debtOutstanding) {
                loss = debtOutstanding - amountFreed;
            } else if (amountFreed > debtOutstanding) {
                profit = amountFreed - debtOutstanding;
            }
            debtPayment = debtOutstanding - loss;
        } else {
            // Free up returns for Vault to pull
            (profit, loss, debtPayment) = prepareReturn(debtOutstanding);
        }

        // we're done harvesting, so reset our trigger if we used it
        forceHarvestTriggerOnce = false;
        emit ForcedHarvestTrigger(false);

        // Allow Vault to take up to the "harvested" balance of this contract,
        // which is the amount it has earned since the last time it reported to
        // the Vault.
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;
        debtOutstanding = vault.report(profit, loss, debtPayment);

        // Check if free returns are left, and re-invest them
        adjustPosition(debtOutstanding);

        // call healthCheck contract
        if (doHealthCheck && healthCheck != address(0)) {
            require(HealthCheck(healthCheck).check(profit, loss, debtPayment, debtOutstanding, totalDebt), "!healthcheck");
        } else {
            emit SetDoHealthCheck(true);
            doHealthCheck = true;
        }

        emit Harvested(profit, loss, debtPayment, debtOutstanding);
    }

    /**
     * @notice
     *  Withdraws `_amountNeeded` to `vault`.
     *
     *  This may only be called by the Vault.
     * @param _amountNeeded How much `want` to withdraw.
     * @return _loss Any realized losses
     */
    function withdraw(uint256 _amountNeeded) external returns (uint256 _loss) {
        require(msg.sender == address(vault), "!vault");
        // Liquidate as much as possible to `want`, up to `_amountNeeded`
        uint256 amountFreed;
        (amountFreed, _loss) = liquidatePosition(_amountNeeded);
        // Send it directly back (NOTE: Using `msg.sender` saves some gas here)
        want.safeTransfer(msg.sender, amountFreed);
        // NOTE: Reinvest anything leftover on next `tend`/`harvest`
    }

    /**
     * Do anything necessary to prepare this Strategy for migration, such as
     * transferring any reserve or LP tokens, CDPs, or other tokens or stores of
     * value.
     */
    function prepareMigration(address _newStrategy) internal virtual;

    /**
     * @notice
     *  Transfers all `want` from this Strategy to `_newStrategy`.
     *
     *  This may only be called by the Vault.
     * @dev
     * The new Strategy's Vault must be the same as this Strategy's Vault.
     *  The migration process should be carefully performed to make sure all
     * the assets are migrated to the new address, which should have never
     * interacted with the vault before.
     * @param _newStrategy The Strategy to migrate to.
     */
    function migrate(address _newStrategy) external {
        require(msg.sender == address(vault));
        require(BaseStrategy(_newStrategy).vault() == vault);
        prepareMigration(_newStrategy);
        want.safeTransfer(_newStrategy, want.balanceOf(address(this)));
    }

    /**
     * @notice
     *  Activates emergency exit. Once activated, the Strategy will exit its
     *  position upon the next harvest, depositing all funds into the Vault as
     *  quickly as is reasonable given on-chain conditions.
     *
     *  This may only be called by governance or the strategist.
     * @dev
     *  See `vault.setEmergencyShutdown()` and `harvest()` for further details.
     */
    function setEmergencyExit() external onlyEmergencyAuthorized {
        emergencyExit = true;
        if (vault.strategies(address(this)).debtRatio != 0) {
            vault.revokeStrategy();
        }

        emit EmergencyExitEnabled();
    }

    /**
     * Override this to add all tokens/tokenized positions this contract
     * manages on a *persistent* basis (e.g. not just for swapping back to
     * want ephemerally).
     *
     * NOTE: Do *not* include `want`, already included in `sweep` below.
     *
     * Example:
     * ```
     *    function protectedTokens() internal override view returns (address[] memory) {
     *      address[] memory protected = new address[](3);
     *      protected[0] = tokenA;
     *      protected[1] = tokenB;
     *      protected[2] = tokenC;
     *      return protected;
     *    }
     * ```
     */
    function protectedTokens() internal view virtual returns (address[] memory);

    /**
     * @notice
     *  Removes tokens from this Strategy that are not the type of tokens
     *  managed by this Strategy. This may be used in case of accidentally
     *  sending the wrong kind of token to this Strategy.
     *
     *  Tokens will be sent to `governance()`.
     *
     *  This will fail if an attempt is made to sweep `want`, or any tokens
     *  that are protected by this Strategy.
     *
     *  This may only be called by governance.
     * @dev
     *  Implement `protectedTokens()` to specify any additional tokens that
     *  should be protected from sweeping in addition to `want`.
     * @param _token The token to transfer out of this vault.
     */
    function sweep(address _token) external onlyGovernance {
        require(_token != address(want), "!want");
        require(_token != address(vault), "!shares");

        address[] memory _protectedTokens = protectedTokens();
        for (uint256 i; i < _protectedTokens.length; i++) require(_token != _protectedTokens[i], "!protected");

        IERC20(_token).safeTransfer(governance(), IERC20(_token).balanceOf(address(this)));
    }
}

abstract contract BaseStrategyInitializable is BaseStrategy {
    bool public isOriginal = true;
    event Cloned(address indexed clone);

    constructor(address _vault) BaseStrategy(_vault) {}

    function initialize(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) external virtual {
        _initialize(_vault, _strategist, _rewards, _keeper);
    }

    function clone(address _vault) external returns (address) {
        return clone(_vault, msg.sender, msg.sender, msg.sender);
    }

    function clone(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper
    ) public returns (address newStrategy) {
        require(isOriginal, "!clone");
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newStrategy := create(0, clone_code, 0x37)
        }

        BaseStrategyInitializable(newStrategy).initialize(_vault, _strategist, _rewards, _keeper);

        emit Cloned(newStrategy);
    }
}

// File: Depositer.sol

/********************
 *  Depositer contract for the Compound V3 lender borrower. The same address cannot both borrow and lend the base token, so
 *      the base strategy will supply collateral and borrow the base token, then this contract will deposit that token back into compound.
 *   Made by @Schlagonia
 *   https://github.com/Schlagonia/CompoundV3-Lender-Borrower
 *
 ********************* */

contract Depositer {
    using SafeERC20 for IERC20;
    using Address for address;

    //Used for cloning
    bool public original = true;

    //Used for Comp apr calculations
    uint64 internal constant DAYS_PER_YEAR = 365;
    uint64 internal constant SECONDS_PER_DAY = 60 * 60 * 24;
    uint64 internal constant SECONDS_PER_YEAR = 365 days;
    
    // price feeds for the reward apr calculation, can be updated manually if needed
    address public rewardTokenPriceFeed;
    address public baseTokenPriceFeed;

    // scaler used in reward apr calculations
    uint256 internal SCALER;
    
    // This is the address of the main V3 pool
    Comet public comet;
    // This is the token we will be borrowing/supplying
    IERC20 public baseToken;
    // The contract to get Comp rewards from
    CometRewards public constant rewardsContract = 
        CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40); 

    IStrategy public strategy;

    //The reward Token
    address internal constant comp = 
        0xc00e94Cb662C3520282E6f5717214004A7f26888;

    modifier onlyGovernance() {
        checkGovernance();
        _;
    }

    modifier onlyStrategy() {
        checkStrategy();
        _;
    }

    function checkGovernance() internal view {
        require(msg.sender == strategy.vault().governance(), "!authorized");
    }

    function checkStrategy() internal view {
        require(msg.sender == address(strategy), "!authorized");
    }

    constructor(address _comet) {
        _initialize(_comet);
    }

    event Cloned(address indexed clone);

    function cloneDepositer(
        address _comet
    ) external returns (address newDepositer) {
        require(original, "!original");
        newDepositer = _clone(_comet);
    }

    function _clone(address _comet) internal returns (address newDepositer) {
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(address(this));

        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(clone_code, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(add(clone_code, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            newDepositer := create(0, clone_code, 0x37)
        }

        Depositer(newDepositer).initialize(_comet);
        emit Cloned(newDepositer);
    }

    function initialize(address _comet) external {
        _initialize(_comet);
    }

    function _initialize(address _comet) internal {
        require(address(comet) == address(0), "!initiliazd");
        comet = Comet(_comet);
        baseToken = IERC20(comet.baseToken());

        baseToken.safeApprove(_comet, type(uint256).max);

        //For APR calculations
        uint256 BASE_MANTISSA = comet.baseScale();
        uint256 BASE_INDEX_SCALE = comet.baseIndexScale();
        
        // this is needed for reward apr calculations based on decimals of want
        // we scale rewards per second to the base token decimals and diff between comp decimals and the index scale
        SCALER = BASE_MANTISSA * 1e18 / BASE_INDEX_SCALE;

        // default to the base token feed given
        baseTokenPriceFeed = comet.baseTokenPriceFeed();
        // default to the COMP/USD feed
        rewardTokenPriceFeed = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
    }

    function setStrategy(address _strategy) external {
        // Can only set the strategy once
        require(address(strategy) == address(0), "set");

        strategy = IStrategy(_strategy);

        // make sure it has the same base token
        require(address(baseToken) == strategy.baseToken(), "!base");
        // Make sure this contract is set as the depositer
        require(address(this) == address(strategy.depositer()), "!depositer");
    }

    function setPriceFeeds(address _baseTokenPriceFeed, address _rewardTokenPriceFeed) external onlyGovernance {
        // just check the call doesnt revert. We dont care about the amount returned 
        comet.getPrice(_baseTokenPriceFeed);
        comet.getPrice(_rewardTokenPriceFeed);
        baseTokenPriceFeed = _baseTokenPriceFeed;
        rewardTokenPriceFeed = _rewardTokenPriceFeed;
    }
    
    function cometBalance() external view returns (uint256){
        return comet.balanceOf(address(this));
    }

    // Non-view function to accrue account for the most accurate accounting
    function accruedCometBalance() public returns(uint256) {
        comet.accrueAccount(address(this));
        return comet.balanceOf(address(this));
    }

    function withdraw(uint256 _amount) external onlyStrategy {
        if (_amount == 0) return;
        IERC20 _baseToken = baseToken;

        comet.withdraw(address(_baseToken), _amount);

        uint256 balance = _baseToken.balanceOf(address(this));
        require(balance >= _amount, "!bal");
        _baseToken.safeTransfer(address(strategy), balance);
    }

    function deposit() external onlyStrategy {
        IERC20 _baseToken = baseToken;
        // msg.sender has been checked to be strategy
        uint256 _amount = _baseToken.balanceOf(msg.sender);
        if (_amount == 0) return;
        
        _baseToken.safeTransferFrom(msg.sender, address(this), _amount);
        comet.supply(address(_baseToken), _amount);
    }

    function claimRewards() external onlyStrategy {
        rewardsContract.claim(address(comet), address(this), true);

        uint256 compBal = IERC20(comp).balanceOf(address(this));

        if(compBal > 0) {
            IERC20(comp).safeTransfer(address(strategy), compBal);
        }
    }

    // ----------------- COMET VIEW FUNCTIONS -----------------

    // We put these in the depositer contract to save byte code in the main strategy \\

    /*
    * Gets the amount of reward tokens due to this contract and the base strategy
    */
    function getRewardsOwed() external view returns (uint256) {
        CometStructs.RewardConfig memory config = rewardsContract.rewardConfig(address(comet));
        uint256 accrued = comet.baseTrackingAccrued(address(this)) + comet.baseTrackingAccrued(address(strategy));
        if (config.shouldUpscale) {
            accrued *= config.rescaleFactor;
        } else {
            accrued /= config.rescaleFactor;
        }
        uint256 claimed = 
            rewardsContract.rewardsClaimed(address(comet), address(this)) + 
                rewardsContract.rewardsClaimed(address(comet), address(strategy));

        return accrued > claimed ? accrued - claimed : 0;
    }

    function getNetBorrowApr(uint256 newAmount) public view returns(uint256 netApr) {
        uint256 newUtilization = (comet.totalBorrow() + newAmount) * 1e18 / (comet.totalSupply() + newAmount);
        uint256 borrowApr = getBorrowApr(newUtilization);
        uint256 supplyApr = getSupplyApr(newUtilization);
        // supply rate can be higher than borrow when utilization is very high
        netApr = borrowApr > supplyApr ? borrowApr - supplyApr : 0;
    }

    /*
    * Get the current supply APR in Compound III
    */
    function getSupplyApr(uint256 newUtilization) public view returns (uint) {
        unchecked {   
            return comet.getSupplyRate(
                     newUtilization // New utilization 
                        ) * SECONDS_PER_YEAR;
        }
    }

    /*
    * Get the current borrow APR in Compound III
    */
    function getBorrowApr(uint256 newUtilization) public view returns (uint256) {
        unchecked {
            return comet.getBorrowRate(
                     newUtilization // New utilization
                            ) * SECONDS_PER_YEAR;  
        }
    }

    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        unchecked {
            return getRewardAprForBorrowBase(newAmount) + getRewardAprForSupplyBase(newAmount);
        }
    }
    
    /*
    * Get the current reward for supplying APR in Compound III
    * @param newAmount The new amount we will be supplying
    * @return The reward APR in USD as a decimal scaled up by 1e18
    */
    function getRewardAprForSupplyBase(uint256 newAmount) public view returns (uint) {
        Comet _comet = comet;
        unchecked {
            uint256 rewardToSuppliersPerDay =  _comet.baseTrackingSupplySpeed() * SECONDS_PER_DAY * SCALER;
            if(rewardToSuppliersPerDay == 0) return 0;
            return (_comet.getPrice(rewardTokenPriceFeed) * 
                        rewardToSuppliersPerDay / 
                            ((_comet.totalSupply() + newAmount) * 
                                _comet.getPrice(baseTokenPriceFeed))) * 
                                    DAYS_PER_YEAR;
        }
    }

    /*
    * Get the current reward for borrowing APR in Compound III
    * @param newAmount The new amount we will be borrowing
    * @return The reward APR in USD as a decimal scaled up by 1e18
    */
    function getRewardAprForBorrowBase(uint256 newAmount) public view returns (uint256) {
        // borrowBaseRewardApr = (rewardTokenPriceInUsd * rewardToBorrowersPerDay / (baseTokenTotalBorrow * baseTokenPriceInUsd)) * DAYS_PER_YEAR;
        Comet _comet = comet;
        unchecked {
            uint256 rewardToBorrowersPerDay =  _comet.baseTrackingBorrowSpeed() * SECONDS_PER_DAY * SCALER;
            if(rewardToBorrowersPerDay == 0) return 0;
            return (_comet.getPrice(rewardTokenPriceFeed) * 
                        rewardToBorrowersPerDay / 
                            ((_comet.totalBorrow() + newAmount) * 
                                _comet.getPrice(baseTokenPriceFeed))) * 
                                    DAYS_PER_YEAR;
        }
    }

    function manualWithdraw() external onlyGovernance {
        // Withdraw everything we have
        comet.withdraw(address(baseToken), accruedCometBalance());
        // Transfer the full balance to Gov
        baseToken.safeTransfer(
            strategy.vault().governance(), 
            baseToken.balanceOf(address(this))
        );
    }
}
// File: Strategy.sol

interface IBaseFeeGlobal {
    function basefee_global() external view returns (uint256);
}

interface IDepositer{
    function deposit() external;
    function setStrategy() external;
    function claimRewards() external;
    function getRewardsOwed() external view returns (uint256);
    function accruedCometBalance() external returns (uint256);
    function getNetBorrowApr(uint256) external view returns (uint256);
    function getNetRewardApr(uint256) external view returns(uint256);
    function withdraw(uint256 _amount) external;
    function baseToken() external view returns(IERC20);
    function cometBalance() external view returns(uint256);
}
 
/********************
 *   Strategy to farm the rewards on Compound V3 by providing any of the possible collateral assets and then borrowing the base token
 *      The base token is then deposited back into compound through a seperate Depositer contract. Borrowing and supply rewards are harvested.
 *   Made by @Schlagonia
 *   https://github.com/Schlagonia/CompoundV3-Lender-Borrower
 *
 ********************* */

contract Strategy is BaseStrategy {
    using SafeERC20 for IERC20;
    using Address for address;

    // if set to true, the strategy will not try to repay debt by selling rewards or want
    bool public leaveDebtBehind;

    // This is the address of the main V3 pool
    Comet public comet;
    // This is the token we will be borrowing/supplying
    address public baseToken;
    // The contract to get Comp rewards from
    CometRewards public constant rewardsContract = 
        CometRewards(0x1B0e765F6224C21223AeA2af16c1C46E38885a40); 
    
    // The Contract that will deposit the baseToken back into Compound
    IDepositer public depositer;

    // The reward Token
    address internal constant comp = 
        0xc00e94Cb662C3520282E6f5717214004A7f26888;
    // The reference token
    address internal constant weth = 
        0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // Uniswap v3 router
    ISwapRouter internal constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    // Fees for the Uni V3 pools
    mapping (address => mapping (address => uint24)) public uniFees;

    // mapping of price feeds. Cheaper and management can customize if needed
    mapping (address => address) public priceFeeds;

    // NOTE: LTV = Loan-To-Value = debt/collateral
    // Target LTV: ratio up to which which we will borrow up to liquidation threshold
    uint16 public targetLTVMultiplier = 7_000;

    // Warning LTV: ratio at which we will repay
    uint16 public warningLTVMultiplier = 8_000; // 80% of liquidation LTV

    // support
    uint16 internal constant MAX_BPS = 10_000; // 100%
    //Thresholds
    uint256 internal minThreshold;
    uint256 public minToSell;
    uint256 public maxGasPriceToTend;
    
    string internal strategyName;

    constructor(
        address _vault,
        address _comet,
        uint24 _ethToWantFee,
        address _depositer,
        string memory _strategyName
    ) BaseStrategy(_vault) {
        _initializeThis(_comet, _ethToWantFee, _depositer, _strategyName);
    }

    // ----------------- PUBLIC VIEW FUNCTIONS -----------------

    function name() external view override returns (string memory) {
        return strategyName;
    }

    // ----------------- SETTERS -----------------
    // we put all together to save contract bytecode (!)
    function setStrategyParams(
        uint16 _targetLTVMultiplier,
        uint16 _warningLTVMultiplier,
        uint256 _minToSell,
        bool _leaveDebtBehind,
        uint256 _maxGasPriceToTend
    ) external onlyAuthorized {
        require(
            _warningLTVMultiplier <= 9_000 &&
                _targetLTVMultiplier < _warningLTVMultiplier
        );
        targetLTVMultiplier = _targetLTVMultiplier;
        warningLTVMultiplier = _warningLTVMultiplier;
        minToSell = _minToSell;
        leaveDebtBehind = _leaveDebtBehind;
        maxGasPriceToTend = _maxGasPriceToTend;
    }

    function setPriceFeed(address token, address priceFeed) external onlyAuthorized {
        // just check it doesnt revert
        comet.getPrice(priceFeed);
        priceFeeds[token] = priceFeed;
    }

    function setFees(
        uint24 _compToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToWantFee
    ) external onlyAuthorized {
        _setFees(_compToEthFee, _ethToBaseFee, _ethToWantFee);
    }

    function _setFees(
        uint24 _compToEthFee,
        uint24 _ethToBaseFee,
        uint24 _ethToWantFee
    ) internal {
        address _weth = weth;
        uniFees[address(want)][_weth] = _ethToWantFee;
        uniFees[_weth][address(want)] = _ethToWantFee;
        
        uniFees[comp][_weth] = _compToEthFee;
        uniFees[_weth][comp] = _compToEthFee;

        uniFees[baseToken][_weth] = _ethToBaseFee;
        uniFees[_weth][baseToken] = _ethToBaseFee;
    }

    function _initializeThis(
        address _comet,
        uint24 _ethToWantFee, 
        address _depositer,
        string memory _strategyName
    ) internal {
        // Make sure we only initialize one time
        require(address(comet) == address(0));
        comet = Comet(_comet);

        //Get the baseToken we wil borrow and the min
        baseToken = comet.baseToken();
        minThreshold = comet.baseBorrowMin();

        depositer = IDepositer(_depositer);
        require(baseToken == address(depositer.baseToken()), "!base");

        // to supply want as collateral
        want.safeApprove(_comet, type(uint256).max);
        // to repay debt
        IERC20(baseToken).safeApprove(_comet, type(uint256).max);
        // for depositer to pull funds to deposit
        IERC20(baseToken).safeApprove(_depositer, type(uint256).max);
        // to sell reward tokens
        IERC20(comp).safeApprove(address(router), type(uint256).max);

        //Default to .3% pool for comp/eth and to .05% pool for eth/baseToken
        _setFees(3000, 500, _ethToWantFee);

        // set default price feeds
        priceFeeds[baseToken] = comet.baseTokenPriceFeed();
        // default to COMP/USD
        priceFeeds[comp] = 0xdbd020CAeF83eFd542f4De03e3cF0C28A4428bd5;
        // default to given feed for want
        priceFeeds[address(want)] = comet.getAssetInfoByAddress(address(want)).priceFeed;

        strategyName = _strategyName;

        // Set health check to health.ychad.eth
        healthCheck = 0xDDCea799fF1699e98EDF118e0629A974Df7DF012;
    }

    function initialize(
        address _vault,
        address _comet,
        uint24 _ethToWantFee,
        address _depositer,
        string memory _strategyName
    ) external {
        _initialize(_vault,  msg.sender,  msg.sender,  msg.sender);
        _initializeThis(_comet, _ethToWantFee, _depositer, _strategyName);
    }

    // ----------------- MAIN STRATEGY FUNCTIONS -----------------

    function estimatedTotalAssets() public view override returns (uint256) {
        //Returns the amount of want and collateral supplied plus an estimation of the rewards we are owed
        // minus the difference in amount supplied and amount borrowed of the base token
        //This needs to account for rewards in order to not show an inaccurate loss for harvestTrigger, but should not be relied upon.
        return
            balanceOfWant() + // balance of want
                balanceOfCollateral() + // asset suplied as collateral
                    rewardsInWant() - //expected rewards amount
                        baseTokenOwedInWant(); // liabilities
    }

    function prepareReturn(uint256 _debtOutstanding)
        internal
        override
        returns (
            uint256 _profit,
            uint256 _loss,
            uint256 _debtPayment
        )
    {
        uint256 totalDebt = vault.strategies(address(this)).totalDebt;

        // 1. claim rewards, 2. even baseToken deposits and borrows 3. sell remainder of rewards to want.
        // This will accrue this account as well as the depositer so all future calls are accurate
        _claimAndSellRewards();
 
        //base token owed should be 0 here but we count it just in case
        uint256 totalAssetsAfterProfit = 
            balanceOfWant() + 
                balanceOfCollateral() -
                    baseTokenOwedInWant();

        if (totalDebt > totalAssetsAfterProfit) {
            // we have losses
            _loss = totalDebt - totalAssetsAfterProfit;
        } else {
            // we have profit
            _profit = totalAssetsAfterProfit - totalDebt;
        }

        (uint256 _amountFreed, ) = liquidatePosition(_debtOutstanding + _profit);

        _debtPayment = Math.min(_debtOutstanding, _amountFreed);
        //Adjust profit in case we had any losses from liquidatePosition
        _profit = _amountFreed - _debtPayment;   
    }

    function adjustPosition(uint256 _debtOutstanding) internal override {
        // cache comet for all future calls
        Comet _comet = comet;
        // Accrue account for accurate balances for tend calls
        _comet.accrueAccount(address(this));

        // If the cost to borrow > rewards rate we will pull out all funds to not report a loss
        if(getNetBorrowApr(0) > getNetRewardApr(0)) {
            // Liquidate everything so not to report a loss
            liquidatePosition(balanceOfCollateral() + balanceOfWant());
            // Return since we dont want to do anything else
            return;
        }

        uint256 wantBalance = balanceOfWant();
        address _want = address(want);
        // if we have enough want to deposit more, we do
        // NOTE: we do not skip the rest of the function if we don't as it may need to repay or take on more debt
        if (wantBalance > _debtOutstanding) {
            _supply(
                _want,
                Math.min(
                    wantBalance - _debtOutstanding, 
                    //Check supply cap wont be reached for want
                    uint256(_comet.getAssetInfoByAddress(_want).supplyCap) - uint256(_comet.totalsCollateral(_want).totalSupplyAsset)
            ));
        }

        // NOTE: debt + collateral calcs are done in USD
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), _want);

        // if there is no want deposited into compound, don't do anything
        // this means no debt is borrowed from compound too
        if (collateralInUsd == 0) {
            return;
        }
        
        // cache baseToken to save a couple of sLoads in normal behavior
        address _baseToken = baseToken;

        // convert debt to USD
        uint256 debtInUsd = _toUsd(balanceOfDebt(), _baseToken);

        // LTV numbers are always in 1e18
        uint256 currentLTV = debtInUsd * 1e18 / collateralInUsd;
        uint256 targetLTV = _getTargetLTV(); // 70% under default liquidation Threshold

        // decide in which range we are and act accordingly:
        // SUBOPTIMAL(borrow) (e.g. from 0 to 70% liqLTV)
        // HEALTHY(do nothing) (e.g. from 70% to 80% liqLTV)
        // UNHEALTHY(repay) (e.g. from 80% to 100% liqLTV)

        if (targetLTV > currentLTV) {
            // SUBOPTIMAL RATIO: our current Loan-to-Value is lower than what we want
            // AND costs are lower than our max acceptable costs

            // we need to take on more debt
            uint256 targetDebtUsd =
                collateralInUsd * targetLTV / 1e18;

            uint256 amountToBorrowUsd = targetDebtUsd - debtInUsd; // safe bc we checked ratios
            // convert to BaseToken
            uint256 amountToBorrowBT = _fromUsd(amountToBorrowUsd, _baseToken);

            uint256 currentProtocolDebt = _comet.totalBorrow();
            uint256 maxProtocolDebt = _comet.totalSupply();
            // cap the amount of debt we are taking according to what is available from Compound
            if (currentProtocolDebt + amountToBorrowBT > maxProtocolDebt) {
                // Can't underflow because it's checked in the previous if condition
                amountToBorrowUsd = _toUsd(maxProtocolDebt - currentProtocolDebt, _baseToken);
            }

            // We want to make sure that the reward apr > borrow apr so we dont reprot a loss
            // Borrowing will cause the borrow apr to go up and the rewards apr to go down
            if(
                getNetBorrowApr(amountToBorrowBT) > 
                getNetRewardApr(amountToBorrowBT)
            ) {
                // If we would push it over the limit dont borrow anything
                amountToBorrowBT = 0;
            }

            // Need to have at least the min set by comet
            if (balanceOfDebt() + amountToBorrowBT > minThreshold) {
                _withdraw(baseToken, amountToBorrowBT);
            }

        } else if (currentLTV > _getWarningLTV()) {
            // UNHEALTHY RATIO
            // we repay debt to set it to targetLTV
            uint256 targetDebtUsd = targetLTV * collateralInUsd / 1e18;
            
            // Withdraw the difference from the Depositer
            _withdrawFromDepositer(_fromUsd(debtInUsd - targetDebtUsd, _baseToken)); // we withdraw from BaseToken depositer
            _repayTokenDebt(); // we repay the BaseToken debt with compound
        }

        if (balanceOfBaseToken() > 0) {
            depositer.deposit();
        }
    }

    function liquidateAllPositions()
        internal
        override
        returns (uint256 _amountFreed)
    {
        (_amountFreed, ) = liquidatePosition(balanceOfCollateral() + balanceOfWant());
    }

    function liquidatePosition(uint256 _amountNeeded)
        internal
        override
        returns (uint256 _liquidatedAmount, uint256 _loss)
    {
        uint256 balance = balanceOfWant();
        // if we have enough want to take care of the liquidatePosition without actually liquidating positons
        if (balance >= _amountNeeded) {
            return (_amountNeeded, 0);
        }
        // NOTE: amountNeeded is in want
        // NOTE: repayment amount is in BaseToken
        // NOTE: collateral and debt calcs are done in USD

        uint256 needed = _amountNeeded - balance;
        // Accrue account for accurate balances
        comet.accrueAccount(address(this));
        // We first repay whatever we need to repay to keep healthy ratios
        _withdrawFromDepositer(_calculateAmountToRepay(needed)); 
        // we repay the BaseToken debt with the amount withdrawn from the vault
        _repayTokenDebt();
        // Withdraw as much as we can up to the amount needed while maintaning a health ltv
        _withdraw(address(want), Math.min(needed, _maxWithdrawal()));
        // it will return the free amount of want
        balance = balanceOfWant();
        // we check if we withdrew less than expected, we have not more baseToken left AND should harvest or buy BaseToken with want (potentially realising losses)
        if (
            _amountNeeded > balance && // if we didn't get enough
            balanceOfDebt() > 0 && // still some debt remaining
            balanceOfBaseToken() + balanceOfDepositer() == 0 && // but no capital to repay
            !leaveDebtBehind // if set to true, the strategy will not try to repay debt by selling want
        ) {
            // using this part of code may result in losses but it is necessary to unlock full collateral in case of wind down
            // This should only occur when depleting the strategy so we want to swap the full amount of our debt
            // we buy BaseToken first with available rewards then with Want
            _buyBaseToken();

            // we repay debt to actually unlock collateral
            // after this, balanceOfDebt should be 0
            _repayTokenDebt();

            // then we try withdraw once more
            // still withdraw with target LTV since management can potentially save any left over manually 
            _withdraw(address(want), _maxWithdrawal());
            // re-update the balance
            balance = balanceOfWant();
        }

        if (_amountNeeded > balance) {
            _liquidatedAmount = balance;
            _loss = _amountNeeded - balance;
        } else {
            _liquidatedAmount = _amountNeeded;
        }
    }

    // manualWithdrawAndRepayDebt should be called previous to migration in order
    // to pay back any outstanding debt before migration
    function prepareMigration(address _newStrategy) internal override {
        // still check max withdraw in case of dust borrow balances
        _withdraw(address(want), _maxWithdrawal());
        
        uint256 baseBalance = balanceOfBaseToken();
        if(baseBalance > 0) {
            IERC20(baseToken).safeTransfer(_newStrategy, baseBalance);
        }
    }

    function tendTrigger(uint256 callCost) public view override returns (bool) {
        if (harvestTrigger(callCost)) {
            // harvest takes priority
            return false;
        }
    
        // if we are in danger of being liquidated tend no matter what
        if(comet.isLiquidatable(address(this))) return true;

        // we adjust position if:
        // 1. LTV ratios are not in the HEALTHY range (either we take on more debt or repay debt)
        // 2. costs are acceptable
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), address(want));

        // Nothing to rebalance if we do not have collateral locked
        if (collateralInUsd == 0) return false;

        uint256 currentLTV = _toUsd(balanceOfDebt(), baseToken) * 1e18 / collateralInUsd;
        uint256 targetLTV = _getTargetLTV();
        
        // Check if we are over our warning LTV
        if (currentLTV >  _getWarningLTV()) {
            // We have a higher tolerance for gas cost here since we are closer to liquidation
            return IBaseFeeGlobal(0xf8d0Ec04e94296773cE20eFbeeA82e76220cD549)
                        .basefee_global() <= maxGasPriceToTend;
        }
        
        if (// WE NEED TO TAKE ON MORE DEBT (we need a 10p.p (1000bps) difference)
            (currentLTV < targetLTV && targetLTV - currentLTV > 1e17) || 
                (getNetBorrowApr(0) > getNetRewardApr(0)) // UNHEALTHY BORROWING COSTS
        ) {
            return isBaseFeeAcceptable();
        }

        return false;
    }

    // ----------------- INTERNAL FUNCTIONS SUPPORT -----------------

    function _withdrawFromDepositer(uint256 _amountBT) internal {
        uint256 balancePrior = balanceOfBaseToken();
        // Only withdraw what we dont already have free
        _amountBT = balancePrior >= _amountBT ? 0 : _amountBT - balancePrior;
        if (_amountBT == 0) return;

        // Make sure we have enough balance. This accrues the account first.
        _amountBT =
            Math.min(
                _amountBT,
                depositer.accruedCometBalance()
            );
        // need to check liquidity of the comet
        _amountBT =
            Math.min(
                _amountBT,
                IERC20(baseToken).balanceOf(address(comet))
            );

        depositer.withdraw(_amountBT);
    }

    /*
    * Supply an asset that this contract holds to Compound III
    * This is used both to supply collateral as well as the baseToken
    */
    function _supply(address asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.supply(asset, amount);
    }

    /*
    * Withdraws an asset from Compound III to this contract
    * for both collateral and borrowing baseToken
    */
    function _withdraw(address asset, uint256 amount) internal {
        if (amount == 0) return;
        comet.withdraw(asset, amount);
    }

    function _repayTokenDebt() internal {
        // we cannot pay more than loose balance or more than we owe
        _supply(baseToken, Math.min(balanceOfBaseToken(), balanceOfDebt()));
    }

    function _maxWithdrawal() internal view returns (uint256) {
        uint256 collateralInUsd = _toUsd(balanceOfCollateral(), address(want));
        uint256 debtInUsd = _toUsd(balanceOfDebt(), baseToken);

        // If there is no debt we can withdraw everything
        if(debtInUsd == 0) return balanceOfCollateral();

        // What we need to maintain a health LTV
        uint256 neededCollateralUsd = debtInUsd * 1e18 / _getTargetLTV();
        // We need more collateral so we cant withdraw anything
        if (neededCollateralUsd > collateralInUsd) {
            return 0;
        }
        // Return the difference in terms of want
        return
            _fromUsd(collateralInUsd - neededCollateralUsd, address(want));
    }

    function _calculateAmountToRepay(uint256 amount)
        internal
        view
        returns (uint256)
    {
        if (amount == 0) return 0;
        uint256 collateral = balanceOfCollateral();
        // to unlock all collateral we must repay all the debt
        if(amount >= collateral) return balanceOfDebt();
        
        // we check if the collateral that we are withdrawing leaves us in a risky range, we then take action
        uint256 newCollateralUsd = _toUsd(collateral - amount, address(want));

        uint256 targetDebtUsd = newCollateralUsd * _getTargetLTV() / 1e18;
        uint256 targetDebt = _fromUsd(targetDebtUsd, baseToken);
        uint256 currentDebt = balanceOfDebt();
        // Repay only if our target debt is lower than our current debt
        return targetDebt < currentDebt ? currentDebt - targetDebt : 0;
    }

    // ----------------- INTERNAL CALCS -----------------

    // Returns the _amount of _token in terms of USD, i.e 1e8
    function _toUsd(uint256 _amount, address _token) internal view returns(uint256) {
        if(_amount == 0) return _amount;
        // usd price is returned as 1e8
        unchecked {
            return _amount * getCompoundPrice(_token) / (10 ** IERC20Extended(_token).decimals());
        }
    }

    // Returns the _amount of usd (1e8) in terms of _token
    function _fromUsd(uint256 _amount, address _token) internal view returns(uint256) {
        if(_amount == 0) return _amount;
        unchecked {
            return _amount * (10 ** IERC20Extended(_token).decimals()) / getCompoundPrice(_token);
        }
    }

    function balanceOfWant() public view returns (uint256) {
        return want.balanceOf(address(this));
    }

    function balanceOfCollateral() public view returns (uint256) {
        return uint256(comet.userCollateral(address(this), address(want)).balance);
    }

    function balanceOfBaseToken() public view returns(uint256) {
        return IERC20(baseToken).balanceOf(address(this));
    }

    function balanceOfDepositer() public view returns(uint256) {
        return depositer.cometBalance();
    }

    function balanceOfDebt() public view returns (uint256) {
        return comet.borrowBalanceOf(address(this));
    }

    // Returns the negative position of base token. i.e. borrowed - supplied
    // if supplied is higher it will return 0
    function baseTokenOwedBalance() public view returns(uint256) {
        uint256 supplied = balanceOfDepositer();
        uint256 borrowed = balanceOfDebt();
        uint256 loose = balanceOfBaseToken();
        
        // If they are the same or supply > debt return 0
        if(supplied + loose >= borrowed) return 0;

        unchecked {
            return borrowed - supplied - loose;
        }
    }

    function baseTokenOwedInWant() internal view returns(uint256) {
        return _fromUsd(_toUsd(baseTokenOwedBalance(), baseToken), address(want));
    }

    function rewardsInWant() public view returns(uint256) {
        // underreport by 10% for safety
        return _fromUsd(_toUsd(depositer.getRewardsOwed(), comp), address(want)) * 9_000 / MAX_BPS;
    }

    // We put the logic for these APR functions in the depositer contract to save byte code in the main strategy \\
    function getNetBorrowApr(uint256 newAmount) public view returns(uint256) {
        return depositer.getNetBorrowApr(newAmount);
    }

    function getNetRewardApr(uint256 newAmount) public view returns (uint256) {
        return depositer.getNetRewardApr(newAmount);
    }

    /*
    * Get the liquidation collateral factor for an asset
    */
    function getLiquidateCollateralFactor() public view returns (uint256) {
        return uint256(comet.getAssetInfoByAddress(address(want)).liquidateCollateralFactor);
    }

    /*
    * Get the price feed address for an asset
    */
    function getPriceFeedAddress(address asset) internal view returns (address priceFeed) {
        priceFeed = priceFeeds[asset];
        if(priceFeed == address(0)) {
            priceFeed = comet.getAssetInfoByAddress(asset).priceFeed;
        }
    }

    /*
    * Get the current price of an asset from the protocol's persepctive
    */
    function getCompoundPrice(address asset) internal view returns (uint256 price) {
        price = comet.getPrice(getPriceFeedAddress(asset));
        // If weth is base token we need to scale response to e18
        if(price == 1e8 && asset == weth) price = 1e18; 
    }

    // External function used to easisly calculate the current LTV of the strat
    function getCurrentLTV() external view returns(uint256) {
        unchecked {
            return _toUsd(balanceOfDebt(), baseToken) * 1e18 / _toUsd(balanceOfCollateral(), address(want));
        }
    }

    function _getTargetLTV()
        internal
        view
        returns (uint256)
    {
        unchecked {
            return
                getLiquidateCollateralFactor() * targetLTVMultiplier / MAX_BPS;
        }
    }

    function _getWarningLTV()
        internal
        view
        returns (uint256)
    {
        unchecked{
            return
                getLiquidateCollateralFactor() * warningLTVMultiplier / MAX_BPS;
        }
    }

    // ----------------- HARVEST / TOKEN CONVERSIONS -----------------

    function claimRewards() external onlyKeepers {
        _claimRewards();
    }

    function _claimRewards() internal {
        rewardsContract.claim(address(comet), address(this), true);
        // Pull rewards from depositer even if not incentivised to accrue the account
        depositer.claimRewards();   
    }

    function _claimAndSellRewards() internal {
        _claimRewards();

        address _comp = comp;

        uint256 compBalance = IERC20(_comp).balanceOf(address(this));

        if(compBalance <= minToSell) return;

        uint256 baseNeeded = baseTokenOwedBalance();

        if(baseNeeded > 0) {
            address _baseToken = baseToken;
            // We estimate how much we will need in order to get the amount of base
            // Accounts for slippage and diff from oracle price, just to assure no horrible sandwhich
            uint256 maxComp = _fromUsd(_toUsd(baseNeeded, _baseToken), _comp) * 10_500 / MAX_BPS;
            if(maxComp < compBalance) {
                // If we have enough swap and exact amount out
                _swapFrom(_comp, _baseToken, baseNeeded, maxComp);
            } else {
                // if not swap everything we have
                _swapTo(_comp, _baseToken, compBalance);
            }
        }
        
        compBalance = IERC20(_comp).balanceOf(address(this));
        // Anything over the amount to cover debt is profit
        if(compBalance > minToSell) {
            _swapTo(_comp, address(want), compBalance);
        }
    }

    // This should only ever get called when withdrawing all funds from the strategy if there is debt left over.
    // It will first try and sell rewards for the needed amount of base token. then will swap want
    // Using this in a normal withdraw can cause it to be sandwhiched which is why we use rewards first
    function _buyBaseToken() internal {
        // We should be able to get the needed amount from rewards tokens. 
        // We first try that before swapping want and reporting losses.
        _claimAndSellRewards();

        uint256 baseStillOwed = baseTokenOwedBalance();
        // Check if our debt balance is still greater than our base token balance
        if(baseStillOwed > 0) {
            // Need to account for both slippage and diff in the oracle price.
            // Should be only swapping very small amounts so its just to make sure there is no massive sandwhich
            uint256 maxWantBalance = _fromUsd(_toUsd(baseStillOwed, baseToken), address(want)) * 10_500 / MAX_BPS;
            // Under 10 can cause rounding errors from token conversions, no need to swap that small amount  
            if (maxWantBalance <= 10) return;

            // This should rarely if ever happen so we approve only what is needed
            IERC20(address(want)).safeApprove(address(router), 0);
            IERC20(address(want)).safeApprove(address(router), maxWantBalance);
            _swapFrom(address(want), baseToken, baseStillOwed, maxWantBalance);   
        }
    }

    function _swapTo(
        address _from, 
        address _to, 
        uint256 _amountFrom
    ) internal {
        if(_from == weth || _to == weth) {
            ISwapRouter.ExactInputSingleParams memory params =
                ISwapRouter.ExactInputSingleParams(
                    _from, // tokenIn
                    _to, // tokenOut
                    uniFees[_from][_to], // from-eth fee
                    address(this), // recipient
                    block.timestamp, // deadline
                    _amountFrom, // amountIn
                    0, // amountOut
                    0 // sqrtPriceLimitX96
                );

            router.exactInputSingle(params);
        } else {
            bytes memory path =
                abi.encodePacked(
                    _from, // from-ETH
                    uniFees[_from][weth],
                    weth, // ETH-to
                    uniFees[weth][_to],
                    _to
                );

            router.exactInput(
                ISwapRouter.ExactInputParams(
                    path,
                    address(this),
                    block.timestamp,
                    _amountFrom,
                    0
                )
            );
        }
    }

    function _swapFrom(
        address _from, 
        address _to, 
        uint256 _amountTo, 
        uint256 _maxAmountFrom
    ) internal {
        if(_from == weth || _to == weth) {
            ISwapRouter.ExactOutputSingleParams memory params =
                ISwapRouter.ExactOutputSingleParams(
                    _from, // tokenIn
                    _to, // tokenOut
                    uniFees[_from][_to], // want-eth fee
                    address(this), // recipient
                    block.timestamp, // deadline
                    _amountTo, // amountOut
                    _maxAmountFrom, // amountIn
                    0 // sqrtPriceLimitX96
                );

            router.exactOutputSingle(params);
        } else {
            bytes memory path =
                abi.encodePacked(
                    _to, 
                    uniFees[weth][_to],// to-ETH
                    weth, 
                    uniFees[_from][weth], // ETH-from
                    _from
                    );

            router.exactOutput(
                ISwapRouter.ExactOutputParams(
                    path,
                    address(this),
                    block.timestamp,
                    _amountTo, //How much we want out
                    _maxAmountFrom
                )
            );
        }
    }

    function ethToWant(uint256 _amtInWei)
        public
        view
        override
        returns (uint256)
    {
        return _fromUsd(_toUsd(_amtInWei, weth), address(want));
    }

    function protectedTokens()
        internal
        view
        override
        returns (address[] memory)
    {}
    
    //Manual function available to management to withdraw from vault and repay debt
    function manualWithdrawAndRepayDebt(uint256 _amount) external onlyAuthorized {
        if(_amount > 0) {
            depositer.withdraw(_amount);
        }
        _repayTokenDebt();
    }
}
// File: CompV3LenderBorrowerCloner.sol

contract CompV3LenderBorrowerCloner {
    address public immutable originalDepositer;
    address public immutable originalStrategy;

    event Cloned(address indexed depositer, address indexed strategy);
    event Deployed(address indexed depositer, address indexed strategy);

    constructor(
        address _vault,
        address _comet,
        uint24 _ethToWantFee,
        string memory _strategyName
    ) {
        Depositer _depositer = new Depositer(_comet);
        Strategy _strategy = new Strategy(_vault, _comet, _ethToWantFee, address(_depositer), _strategyName);

        originalDepositer = address(_depositer);
        originalStrategy = address(_strategy);

        emit Deployed(originalDepositer, originalStrategy);

        _depositer.setStrategy(originalStrategy);

        Strategy(_strategy).setStrategyParams(
            7_000, // targetLTVMultiplier (default: 7_000)
            8_000, // warningLTVMultiplier default: 8_000
            1e10, // min rewards to sell
            false, // leave debt behind (default: false)
            40 * 1e9 // max base fee to perform non-emergency tends (default: 40 gwei)
        );

        Strategy(_strategy).setRewards(msg.sender);
        Strategy(_strategy).setKeeper(msg.sender);
        Strategy(_strategy).setStrategist(msg.sender);
    }

    function name() external pure returns (string memory) {
        return "[email protected]";
    }

    function cloneCompV3LenderBorrower(
        address _vault,
        address _strategist,
        address _rewards,
        address _keeper,
        address _comet,
        uint24 _ethToWantFee,
        string memory _strategyName
    ) external returns (address newDepositer, address newStrategy) {
        newDepositer = Depositer(originalDepositer).cloneDepositer(_comet);
        // Copied from https://github.com/optionality/clone-factory/blob/master/contracts/CloneFactory.sol
        bytes20 addressBytes = bytes20(originalStrategy);
        assembly {
            // EIP-1167 bytecode
            let clone_code := mload(0x40)
            mstore(
                clone_code,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone_code, 0x14), addressBytes)
            mstore(
                add(clone_code, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            newStrategy := create(0, clone_code, 0x37)
        }

        Strategy(newStrategy).initialize(_vault, _comet, _ethToWantFee, newDepositer, _strategyName);

        Depositer(newDepositer).setStrategy(newStrategy);
        
        Strategy(newStrategy).setStrategyParams(
            7_000, // targetLTVMultiplier (default: 7_000)
            8_000, // warningLTVMultiplier default: 8_000
            1e10, // min rewards to sell
            false, // leave debt behind (default: false)
            40 * 1e9 // max base fee to perform non-emergency tends (default: 40 gwei)
        );

        Strategy(newStrategy).setKeeper(_keeper);
        Strategy(newStrategy).setRewards(_rewards);
        Strategy(newStrategy).setStrategist(_strategist);

        emit Cloned(newDepositer, newStrategy);
    }
}