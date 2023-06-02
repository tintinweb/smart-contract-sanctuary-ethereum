// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ========================== BackedAsset.sol ==========================
// ====================================================================

/**
 * @title Backed Asset
 * @dev Representation of an on-chain investment on Backed Finance
 */

import "../Stabilizer/Stabilizer.sol";
import "../Oracle/ChainlinkPricer.sol";

contract BackedAsset is Stabilizer {
    // Variables
    IERC20Metadata private immutable token;
    address private immutable token_oracle; // Oracle to fetch price token / base
    address private immutable mint_address;
    address private immutable redeem_address;

    // Zero value will avoid to check StalePrice.
    uint256 private constant TOKEN_FREQUENCY = 0;

    constructor(
        string memory _name,
        address _sweep_address,
        address _usdx_address,
        address _token_address,
        address _mint_address,
        address _redeem_address,
        address _token_oracle_address,
        address _borrower
    )
        Stabilizer(
            _name,
            _sweep_address,
            _usdx_address,
            _borrower
        )
    {
        token = IERC20Metadata(_token_address);
        mint_address = _mint_address;
        redeem_address = _redeem_address;
        token_oracle = _token_oracle_address;
    }

    /* ========== Views ========== */

    /**
     * @notice Current Value of investment.
     * @return total with 6 decimal to be compatible with dollar coins.
     */
    function currentValue() public view override returns (uint256) {
        return assetValue() + super.currentValue();
    }

    /**
     * @notice Asset Value of investment.
     * @return the Returns the value of the investment in the USD coin
     * @dev the price is obtained from Chainlink
     */
    function assetValue() public view returns (uint256) {
        uint256 token_balance = token.balanceOf(address(this));
        (int256 price, uint8 decimals) = ChainlinkPricer.getLatestPrice(
            token_oracle,
            amm().sequencer(),
            TOKEN_FREQUENCY
        );

        uint256 usdx_amount = (token_balance *
            uint256(price) *
            10 ** usdx.decimals()) / (10 ** (token.decimals() + decimals));

        return usdx_amount;
    }

    /* ========== Actions ========== */

    /**
     * @notice Invest.
     * @param _usdx_amount Amount of usdx to be swapped for token.
     * @dev Swap from usdx to token.
     */
    function invest(
        uint256 _usdx_amount
    ) external onlyBorrower whenNotPaused validAmount(_usdx_amount) {
        _invest(_usdx_amount, 0);
    }

    /**
     * @notice Divest.
     * @param _usdx_amount Amount to be divested.
     * @dev Swap from the token to usdx.
     */
    function divest(
        uint256 _usdx_amount
    ) external onlyBorrower validAmount(_usdx_amount) {
        _divest(_usdx_amount);
    }

    /**
     * @notice Liquidate
     */
    function liquidate() external {
        _liquidate(address(token));
    }

    /* ========== Internals ========== */

    function _invest(uint256 _usdx_amount, uint256) internal override {
        (uint256 usdx_balance, ) = _balances();
        if(usdx_balance < _usdx_amount) _usdx_amount = usdx_balance;

        TransferHelper.safeTransfer(address(usdx), mint_address, _usdx_amount);

        emit Invested(_usdx_amount, 0);
    }

    function _divest(uint256 _usdx_amount) internal override {
        (int256 price, uint8 decimals) = ChainlinkPricer.getLatestPrice(
            token_oracle,
            amm().sequencer(),
            TOKEN_FREQUENCY
        );

        uint256 token_amount = (_usdx_amount *
            (10 ** (token.decimals() + decimals))) /
            (uint256(price) * 10 ** usdx.decimals());

        uint256 token_balance = token.balanceOf(address(this));
        if(token_balance < token_amount) token_amount = token_balance;

        TransferHelper.safeTransfer(address(token), redeem_address, token_amount);

        emit Divested(_usdx_amount, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/extensions/IERC20Metadata.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface IAMM {
    function swapExactInput(
        address _tokenA,
        address _tokenB,
        uint256 _amountIn,
        uint256 _amountOutMin
    ) external returns (uint256);

    function buySweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function sellSweep(address _token, uint256 _amountIn, uint256 _amountOutMin)
        external
        returns (uint256);

    function sequencer() external view returns(address);

    function poolFee() external view returns(uint24);

    function getTWAPrice() external view returns (uint256 amountOut);

    function getPrice() external view returns (uint256 amountOut);

    function tokenToUSD(uint256 tokenAmount) external view returns (uint256 usdAmount);

    function USDtoToken(uint256 usdAmount) external view returns (uint256 tokenAmount);

}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

// ==========================================================
// ====================== Owned ========================
// ==========================================================

import "../Sweep/ISweep.sol";

contract Owned {
    address public immutable sweep_address;
    ISweep public immutable SWEEP;

    // Errors
    error NotGovernance();
    error NotMultisig();
    error ZeroAddressDetected();

    constructor(address _sweep_address) {
        if(_sweep_address == address(0)) revert ZeroAddressDetected();

        sweep_address = _sweep_address;
        SWEEP = ISweep(_sweep_address);
    }

    modifier onlyGov() {
        if (msg.sender != SWEEP.owner()) revert NotGovernance();
        _;
    }

    modifier onlyMultisig() {
        if (msg.sender != SWEEP.fast_multisig())
            revert NotMultisig();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library ChainlinkPricer {
    // Errors
    error AddressZeroDetected();
    error GracePeriodNotOver();
    error SequencerDown();
    error InvalidPrice();
    error StalePrice();

    /**
     * Returns the latest price
     */
    function getLatestPrice(
        address priceFeed,
        address sequencerFeed,
        uint256 frequency
    ) internal view returns (int256 price, uint8 decimals) {
        decimals = AggregatorV3Interface(priceFeed).decimals();
        if (address(sequencerFeed) != address(0)) checkUptime(sequencerFeed);

        (
            uint256 roundId,
            int256 _price,
            ,
            uint256 updatedAt,

        ) = AggregatorV3Interface(priceFeed).latestRoundData();

        if (_price <= 0 || roundId == 0) revert InvalidPrice();
        if (updatedAt == 0 || updatedAt == 0) revert InvalidPrice();
        if (frequency > 0 && (block.timestamp - updatedAt > frequency))
            revert StalePrice();
        price = _price;
    }

    function checkUptime(address sequencerFeed) internal view {
        (, int256 answer, uint256 startedAt, , ) = AggregatorV3Interface(
            sequencerFeed
        ).latestRoundData();
        // answer == 0: Sequencer is up
        // answer == 1: Sequencer is down
        if (answer > 0) revert SequencerDown();
        if (block.timestamp - startedAt <= 1 hours) revert GracePeriodNotOver();
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

// ====================================================================
// ====================== Stabilizer.sol ==============================
// ====================================================================

/**
 * @title Stabilizer
 * @dev Implementation:
 * Allows to take debt by minting sweep and repaying by burning sweep
 * Allows to buy and sell sweep in an AMM
 * Allows auto invest according the borrower configuration
 * Allows auto repays by the balancer to control sweep price
 * Allow liquidate the Asset when is defaulted
 * Repayments made by burning sweep
 * EquityRatio = Junior / (Junior + Senior)
 */

import "../Sweep/ISweep.sol";
import "../AMM/IAMM.sol";
import "../Common/Owned.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

contract Stabilizer is Owned, Pausable {
    using Math for uint256;
    
    // Variables
    string public name;
    address public borrower;
    int256 public min_equity_ratio; // Minimum Equity Ratio. 10000 is 1%
    uint256 public sweep_borrowed;
    uint256 public loan_limit;

    uint256 public call_time;
    uint256 public call_delay; // 86400 is 1 day
    uint256 public call_amount;

    uint256 public spread_fee; // 10000 is 1%
    uint256 public spread_date;
    uint256 public liquidator_discount; // 10000 is 1%
    string public link;

    int256 public auto_invest_min_ratio; // 10000 is 1%
    uint256 public auto_invest_min_amount;
    bool public auto_invest;

    bool public settings_enabled;

    // Tokens
    IERC20Metadata public usdx;

    // Constants for various precisions
    uint256 private constant DAY_SECONDS = 60 * 60 * 24; // seconds of Day
    uint256 private constant TIME_ONE_YEAR = 365 * DAY_SECONDS; // seconds of Year
    uint256 private constant PRECISION = 1e6;
    uint256 private constant ORACLE_FREQUENCY = 1 days;

    /* ========== Events ========== */

    event Borrowed(uint256 indexed sweep_amount);
    event Repaid(uint256 indexed sweep_amount);
    event Withdrawn(address indexed token, uint256 indexed amount);
    event PayFee(uint256 indexed sweep_amount);
    event Bought(uint256 indexed sweep_amount);
    event Sold(uint256 indexed sweep_amount);
    event BoughtSWEEP(uint256 indexed sweep_amount);
    event SoldSWEEP(uint256 indexed usdx_amount);
    event LoanLimitChanged(uint256 loan_limit);
    event Proposed(address indexed borrower);
    event Rejected(address indexed borrower);

    event Invested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Divested(uint256 indexed usdx_amount, uint256 indexed sweep_amount);
    event Liquidated(address indexed user);

    event AutoCalled(uint256 indexed sweep_amount);
    event AutoInvested(uint256 indexed sweep_amount);
    event CallCancelled(uint256 indexed sweep_amount);

    event ConfigurationChanged(
        int256 indexed min_equity_ratio,
        uint256 indexed spread_fee,
        uint256 loan_limit,
        uint256 liquidator_discount,
        uint256 call_delay,
        int256 auto_invest_min_ratio,
        uint256 auto_invest_min_amount,
        bool auto_invest,
        string url_link
    );

    /* ========== Errors ========== */
    error NotBorrower();
    error NotBalancer();
    error SettingsDisabled();
    error OverZero();
    error InvalidMinter();
    error NotEnoughBalance();
    error EquityRatioExcessed();
    error InvalidToken();
    error SpreadNotEnough();
    error NotDefaulted();
    error ZeroPrice();
    error NotAutoInvest();
    error NotAutoInvestMinAmount();
    error NotAutoInvestMinRatio();

    /* ========== Modifies ========== */
    modifier onlyBorrower() {
        if (msg.sender != borrower) revert NotBorrower();
        _;
    }

    modifier onlyBalancer() {
        if (msg.sender != SWEEP.balancer()) revert NotBalancer();
        _;
    }

    modifier onlySettingsEnabled() {
        if (!settings_enabled) revert SettingsDisabled();
        _;
    }

    modifier validAddress(address _addr) {
        if (_addr == address(0)) revert ZeroAddressDetected();
        _;
    }

    modifier validAmount(uint256 _amount) {
        if (_amount == 0) revert OverZero();
        _;
    }

    constructor(
        string memory _name,
        address _sweep_address,
        address _usdx_address,
        address _borrower
    ) Owned(_sweep_address) {
        if(_borrower == address(0)) revert ZeroAddressDetected();
        name = _name;
        usdx = IERC20Metadata(_usdx_address);
        borrower = _borrower;
        settings_enabled = true;
    }

    /* ========== Views ========== */

    /**
     * @notice Defaulted
     * @return bool that tells if stabilizer is in default.
     */
    function isDefaulted() public view returns (bool) {
        return
            (call_delay > 0 && call_amount > 0 && block.timestamp > call_time) ||
            (sweep_borrowed > 0 && getEquityRatio() < min_equity_ratio);
    }

    /**
     * @notice Get Equity Ratio
     * @return the current equity ratio based in the internal storage.
     * @dev this value have a precision of 6 decimals.
     */
    function getEquityRatio() public view returns (int256) {
        return _calculateEquityRatio(0, 0);
    }

    /**
     * @notice Get Spread Amount
     * fee = borrow_amount * spread_ratio * (time / time_per_year)
     * @return uint256 calculated spread amount.
     */
    function accruedFee() public view returns (uint256) {
        if (sweep_borrowed > 0) {
            uint256 period = block.timestamp - spread_date;
            return
                (sweep_borrowed * spread_fee * period) /
                (TIME_ONE_YEAR * PRECISION);
        }

        return 0;
    }

    /**
     * @notice Get Debt Amount
     * debt = borrow_amount + spread fee
     * @return uint256 calculated debt amount.
     */
    function getDebt() external view returns (uint256) {
        return sweep_borrowed + accruedFee();
    }

    /**
     * @notice Get Current Value
     * value = sweep balance + usdx balance
     * @return uint256.
     */
    function currentValue() public view virtual returns (uint256) {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 sweep_balance_in_usd = SWEEP.convertToUSD(sweep_balance);

        return (amm().tokenToUSD(usdx_balance) + sweep_balance_in_usd);
    }

    /**
     * @notice Get AMM from Sweep
     * @return address.
     */
    function amm() public view virtual returns (IAMM) {
        return IAMM(ISweep(sweep_address).amm());
    }

    /**
     * @notice Get Junior Tranche Value
     * @return int256 calculated junior tranche amount.
     */
    function getJuniorTrancheValue() external view returns (int256) {
        uint256 senior_tranche_in_usd = SWEEP.convertToUSD(sweep_borrowed);
        uint256 total_value = currentValue();

        return int256(total_value) - int256(senior_tranche_in_usd);
    }

    /**
     * @notice Returns the SWEEP required to liquidate the stabilizer
     * @return uint256
     */
    function getLiquidationValue() public view returns (uint256) {
        return
            accruedFee() + SWEEP.convertToSWEEP(
                (currentValue() * (1e6 - liquidator_discount)) / PRECISION
            );
    }

    /* ========== Settings ========== */
    /**
     * @notice Pause
     * @dev Stops investment actions.
     */
    function pause() external onlyMultisig {
        _pause();
    }

    function unpause() external onlyMultisig {
        _unpause();
    }

    /**
     * @notice Configure intial settings
     * @param _min_equity_ratio The minimum equity ratio can be negative.
     * @param _spread_fee The fee that the protocol will get for providing the loan when the stabilizer takes debt
     * @param _loan_limit How much debt a Stabilizer can take in SWEEP.
     * @param _liquidator_discount A percentage that will be discounted in favor to the liquidator when the stabilizer is liquidated
     * @param _call_delay Time in seconds after AutoCall until the Stabilizer gets defaulted if the debt is not paid in that period
     * @param _auto_invest_min_ratio Minimum equity ratio that should be kept to allow the execution of an auto invest
     * @param _auto_invest_min_amount Minimum amount to be invested to allow the execution of an auto invest
     * @param _auto_invest Represents if an auto invest execution is allowed or not
     * @param _link A URL link to a Web page that describes the borrower and the asset
     * @dev Sets the initial configuration of the Stabilizer.
     * This configuration will be analyzed by the protocol and if accepted,
     * used to include the Stabilizer in the minter's whitelist of Sweep.
     */
    function configure(
        int256 _min_equity_ratio,
        uint256 _spread_fee,
        uint256 _loan_limit,
        uint256 _liquidator_discount,
        uint256 _call_delay,
        int256 _auto_invest_min_ratio,
        uint256 _auto_invest_min_amount,
        bool _auto_invest,
        string calldata _link
    ) external onlyBorrower onlySettingsEnabled {
        min_equity_ratio = _min_equity_ratio;
        spread_fee = _spread_fee;
        loan_limit = _loan_limit;
        liquidator_discount = _liquidator_discount;
        call_delay = _call_delay;
        auto_invest_min_ratio = _auto_invest_min_ratio;
        auto_invest_min_amount = _auto_invest_min_amount;
        auto_invest = _auto_invest;
        link = _link;

        emit ConfigurationChanged(
            _min_equity_ratio,
            _spread_fee,
            _loan_limit,
            _liquidator_discount,
            _call_delay,
            _auto_invest_min_ratio,
            _auto_invest_min_amount,
            _auto_invest,
            _link
        );
    }

    /**
     * @notice Changes the account that control the global configuration to the protocol/governance admin
     * @dev after disable settings by admin
     * the protocol will evaluate adding the stabilizer to the minter list.
     */
    function propose() external onlyBorrower {
        settings_enabled = false;

        emit Proposed(borrower);
    }

    /**
     * @notice Changes the account that control the global configuration to the borrower
     * @dev after enable settings for the borrower
     * he/she should edit the values to align to the protocol requirements
     */
    function reject() external onlyGov {
        settings_enabled = true;

        emit Rejected(borrower);
    }

    /* ========== Actions ========== */

    /**
     * @notice Borrows Sweep
     * Asks the stabilizer to mint a certain amount of sweep token.
     * @param _sweep_amount.
     * @dev Increases the sweep_borrowed (senior tranche).
     */
    function borrow(
        uint256 _sweep_amount
    ) external onlyBorrower whenNotPaused validAmount(_sweep_amount) {
        if (!SWEEP.isValidMinter(address(this))) revert InvalidMinter();

        uint256 sweep_available = loan_limit - sweep_borrowed;
        if (sweep_available < _sweep_amount) revert NotEnoughBalance();

        int256 current_equity_ratio = _calculateEquityRatio(_sweep_amount, 0);
        if (current_equity_ratio < min_equity_ratio)
            revert EquityRatioExcessed();

        _borrow(_sweep_amount);
    }

    /**
     * @notice Repays Sweep
     * Burns the sweep_amount to reduce the debt (senior tranche).
     * @param _sweep_amount Amount to be burnt by Sweep.
     * @dev Decreases the sweep borrowed.
     */
    function repay(uint256 _sweep_amount) external onlyBorrower {
        _repay(_sweep_amount);
    }

    /**
     * @notice Pay the spread to the treasury
     */
    function payFee() external onlyBorrower {
        uint256 spread_amount = accruedFee();
        spread_date = block.timestamp;

        uint256 sweep_balance = SWEEP.balanceOf(address(this));

        if (spread_amount > sweep_balance) revert SpreadNotEnough();

        if (spread_amount > 0) {
            TransferHelper.safeTransfer(
                sweep_address,
                SWEEP.treasury(),
                spread_amount
            );

            emit PayFee(spread_amount);
        }
    }

    /**
     * @notice Set Loan Limit.
     * @param _new_loan_limit.
     * @dev How much debt an Stabilizer can take in SWEEP.
     */
    function setLoanLimit(uint256 _new_loan_limit) external onlyBalancer {
        loan_limit = _new_loan_limit;

        emit LoanLimitChanged(_new_loan_limit);
    }

    /**
     * @notice Auto Call.
     * @param sweep_amount to repay.
     * @dev Strategy:
     * 1) repays debt with SWEEP balance
     * 2) repays remaining debt by divesting
     * 3) repays remaining debt by buying on SWEEP in the AMM
     */
    function autoCall(uint256 sweep_amount, uint256 price, uint256 slippage) external onlyBalancer {
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 repay_amount = sweep_amount.min(sweep_borrowed);

        if (call_delay > 0) {
            call_time = block.timestamp + call_delay;
            call_amount = repay_amount;
        }

        if (sweep_balance < repay_amount) {
            uint256 missing_sweep = repay_amount - sweep_balance;
            uint256 missing_usdx = amm().USDtoToken(SWEEP.convertToUSD(missing_sweep));

            if (missing_usdx > usdx_balance) {
                _divest(missing_usdx - usdx_balance);
            }

            if (usdx.balanceOf(address(this)) > 0) {
                uint256 missing_usd = amm().tokenToUSD(missing_usdx);
                uint256 sweepAmount = missing_usd.mulDiv(10 ** SWEEP.decimals(), price);
                uint256 minAmountOut = sweepAmount * (PRECISION - slippage) / PRECISION;
                _buy(missing_usdx, minAmountOut);
            }
        }

        if (SWEEP.balanceOf(address(this)) > 0 && repay_amount > 0 ) {
            _repay(repay_amount);
        }

        emit AutoCalled(sweep_amount);
    }

    /**
     * @notice Cancel Call
     * @dev Cancels the auto call request by clearing variables for an asset 
     * that has a call_delay: meaning that it does not autorepay.
     */
    function cancelCall() external onlyBalancer {
        emit CallCancelled(call_amount);
        call_amount = 0;
        call_time = 0;
    }

    /**
     * @notice Auto Invest.
     * @param sweep_amount to mint.
     */
    function autoInvest(uint256 sweep_amount, uint256 price, uint256 slippage) external onlyBalancer {
        uint256 sweep_limit = SWEEP.minters(address(this)).max_amount;
        uint256 sweep_available = sweep_limit - sweep_borrowed;
        sweep_amount = sweep_amount.min(sweep_available);
        int256 current_equity_ratio = _calculateEquityRatio(sweep_amount, 0);
        
        if(!auto_invest) revert NotAutoInvest();
        if(sweep_amount < auto_invest_min_amount) revert NotAutoInvestMinAmount();
        if(current_equity_ratio < auto_invest_min_ratio) revert NotAutoInvestMinRatio();

        _borrow(sweep_amount);

        uint256 usdAmount = sweep_amount.mulDiv(price, 10 ** SWEEP.decimals());
        uint256 minAmountOut = amm().USDtoToken(usdAmount) * (PRECISION - slippage) / PRECISION;
        uint256 usdx_amount = _sell(sweep_amount, minAmountOut);

        _invest(usdx_amount, 0);

        emit AutoInvested(sweep_amount);
    }

    /**
     * @notice Buy
     * Buys sweep_amount from the stabilizer's balance to the AMM (swaps USDX to SWEEP).
     * @param _usdx_amount Amount to be changed in the AMM.
     * @param _amountOutMin Minimum amount out.
     * @dev Increases the sweep balance and decrease usdx balance.
     */
    function buySweepOnAMM(
        uint256 _usdx_amount,
        uint256 _amountOutMin
    ) external onlyBorrower whenNotPaused returns (uint256 sweep_amount) {
        sweep_amount = _buy(_usdx_amount, _amountOutMin);

        emit Bought(sweep_amount);
    }

    /**
     * @notice Sell Sweep
     * Sells sweep_amount from the stabilizer's balance to the AMM (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @param _amountOutMin Minimum amount out.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function sellSweepOnAMM(
        uint256 _sweep_amount,
        uint256 _amountOutMin
    ) external onlyBorrower whenNotPaused returns (uint256 usdx_amount) {
        usdx_amount = _sell(_sweep_amount, _amountOutMin);

        emit Sold(_sweep_amount);
    }

    /**
     * @notice Buy Sweep with Stabilizer
     * Buys sweep_amount from the stabilizer's balance to the Borrower (swaps USDX to SWEEP).
     * @param _usdx_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapUsdxToSweep(
        uint256 _usdx_amount
    ) external onlyBorrower whenNotPaused validAmount(_usdx_amount) {
        uint256 sweep_amount = SWEEP.convertToSWEEP(amm().tokenToUSD(_usdx_amount));
        uint256 sweep_balance = SWEEP.balanceOf(address(this));
        if (sweep_amount > sweep_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            address(usdx),
            msg.sender,
            address(this),
            _usdx_amount
        );
        TransferHelper.safeTransfer(sweep_address, msg.sender, sweep_amount);

        emit BoughtSWEEP(sweep_amount);
    }

    /**
     * @notice Sell Sweep with Stabilizer
     * Sells sweep_amount to the stabilizer (swaps SWEEP to USDX).
     * @param _sweep_amount.
     * @dev Decreases the sweep balance and increase usdx balance
     */
    function swapSweepToUsdx(
        uint256 _sweep_amount
    ) external onlyBorrower whenNotPaused validAmount(_sweep_amount) {
        uint256 usdx_amount = amm().USDtoToken(SWEEP.convertToUSD(_sweep_amount));
        uint256 usdx_balance = usdx.balanceOf(address(this));

        if (usdx_amount > usdx_balance) revert NotEnoughBalance();

        TransferHelper.safeTransferFrom(
            sweep_address,
            msg.sender,
            address(this),
            _sweep_amount
        );
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_amount);

        emit SoldSWEEP(usdx_amount);
    }

    /**
     * @notice Withdraw SWEEP
     * Takes out sweep balance if the new equity ratio is higher than the minimum equity ratio.
     * @param _token.
     * @param _amount.
     * @dev Decreases the sweep balance.
     */
    function withdraw(
        address _token,
        uint256 _amount
    ) external onlyBorrower whenNotPaused validAmount(_amount) {
        if (_token != sweep_address && _token != address(usdx))
            revert InvalidToken();

        if (_amount > IERC20Metadata(_token).balanceOf(address(this)))
            revert NotEnoughBalance();

        if (sweep_borrowed > 0) {
            uint256 usd_amount = _token == sweep_address ?
                SWEEP.convertToUSD(_amount) : amm().tokenToUSD(_amount);
            int256 current_equity_ratio = _calculateEquityRatio(0, usd_amount);
            if (current_equity_ratio < min_equity_ratio)
                revert EquityRatioExcessed();
        }

        TransferHelper.safeTransfer(_token, msg.sender, _amount);

        emit Withdrawn(_token, _amount);
    }

    /* ========== Internals ========== */

    /**
     * @notice Invest To Asset.
     */
    function _invest(
        uint256 _usdx_amount,
        uint256 _sweep_amount
    ) internal virtual {}

    /**
     * @notice Divest From Asset.
     */
    function _divest(uint256 _amount) internal virtual {}

    /**
     * @notice Liquidates
     * A liquidator repays the debt in sweep and gets the same value
     * of the assets that the stabilizer holds at a discount
     */
    function _liquidate(address token) internal {
        if (!isDefaulted()) revert NotDefaulted();
        address self = address(this);

        uint256 sweep_to_liquidate = getLiquidationValue();
        (uint256 usdx_balance, uint256 sweep_balance) = _balances();
        uint256 token_balance = IERC20Metadata(token).balanceOf(self);
        // Gives all the assets to the liquidator first
        TransferHelper.safeTransfer(sweep_address, msg.sender, sweep_balance);
        TransferHelper.safeTransfer(address(usdx), msg.sender, usdx_balance);
        TransferHelper.safeTransfer(token, msg.sender, token_balance);

        // Takes SWEEP from the liquidator and repays as much debt as it can
        TransferHelper.safeTransferFrom(
            sweep_address,
            msg.sender,
            self,
            sweep_to_liquidate
        );

        _repay(sweep_to_liquidate);

        emit Liquidated(msg.sender);
    }

    function _buy(
        uint256 _usdx_amount,
        uint256 _amountOutMin
    ) internal returns (uint256) {
        uint256 usdx_balance = usdx.balanceOf(address(this));
        _usdx_amount = _usdx_amount.min(usdx_balance);

        if (_usdx_amount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(address(usdx), SWEEP.amm(), _usdx_amount);
        uint256 sweep_amount = amm().buySweep(
            address(usdx),
            _usdx_amount,
            _amountOutMin
        );

        return sweep_amount;
    }

    function _sell(
        uint256 _sweep_amount,
        uint256 _amountOutMin
    ) internal returns (uint256) {
        uint256 sweep_balance = SWEEP.balanceOf(address(this));
        _sweep_amount = _sweep_amount.min(sweep_balance);

        if (_sweep_amount == 0) revert NotEnoughBalance();

        TransferHelper.safeApprove(sweep_address, SWEEP.amm(), _sweep_amount);
        uint256 usdx_amount = amm().sellSweep(
            address(usdx),
            _sweep_amount,
            _amountOutMin
        );

        return usdx_amount;
    }

    function _borrow(uint256 _sweep_amount) internal {
        uint256 spread_amount = accruedFee();
        SWEEP.minter_mint(address(this), _sweep_amount);
        sweep_borrowed += _sweep_amount;
        spread_date = block.timestamp;

        if (spread_amount > 0) {
            TransferHelper.safeTransfer(
                sweep_address,
                SWEEP.treasury(),
                spread_amount
            );
            emit PayFee(spread_amount);
        }

        emit Borrowed(_sweep_amount);
    }

    function _repay(uint256 _sweep_amount) internal {
        uint256 sweep_balance = SWEEP.balanceOf(address(this));
        _sweep_amount = _sweep_amount.min(sweep_balance);

        if (_sweep_amount == 0) revert NotEnoughBalance();

        call_amount = (call_amount > _sweep_amount)
            ? call_amount - _sweep_amount
            : 0;

        if (call_delay > 0 && call_amount == 0) call_time = 0;

        uint256 spread_amount = accruedFee();
        spread_date = block.timestamp;

        uint256 sweep_amount = _sweep_amount - spread_amount;
        if (sweep_borrowed < sweep_amount) {
            sweep_amount = sweep_borrowed;
            sweep_borrowed = 0;
        } else {
            sweep_borrowed -= sweep_amount;
        }

        TransferHelper.safeTransfer(
            sweep_address,
            SWEEP.treasury(),
            spread_amount
        );

        TransferHelper.safeApprove(sweep_address, address(this), sweep_amount);
        SWEEP.minter_burn_from(sweep_amount);

        emit Repaid(sweep_amount);
    }

    /**
     * @notice Calculate Equity Ratio
     * Calculated the equity ratio based on the internal storage.
     * @param _sweep_delta Variation of SWEEP to recalculate the new equity ratio.
     * @param _usd_delta Variation of USD to recalculate the new equity ratio.
     * @return the new equity ratio used to control the Mint and Withdraw functions.
     * @dev Current Equity Ratio percentage has a precision of 4 decimals.
     */
    function _calculateEquityRatio(
        uint256 _sweep_delta,
        uint256 _usd_delta
    ) internal view returns (int256) {
        uint256 current_value = currentValue();
        uint256 sweep_delta_in_usd = SWEEP.convertToUSD(_sweep_delta);
        uint256 total_value = current_value + sweep_delta_in_usd - _usd_delta;

        if (total_value == 0) return 0;

        uint256 senior_tranche_in_usd = SWEEP.convertToUSD(
            sweep_borrowed + _sweep_delta
        );

        // 1e6 is decimals of the percentage result
        int256 current_equity_ratio = ((int256(total_value) -
            int256(senior_tranche_in_usd)) * 1e6) / int256(total_value);

        if (current_equity_ratio < -1e6) current_equity_ratio = -1e6;

        return current_equity_ratio;
    }

    /**
     * @notice Get Balances of the usdx and SWEEP.
     **/
    function _balances()
        internal
        view
        returns (uint256 usdx_balance, uint256 sweep_balance)
    {
        usdx_balance = usdx.balanceOf(address(this));
        sweep_balance = SWEEP.balanceOf(address(this));
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

interface ISweep {
    struct Minter {
        uint256 max_amount;
        uint256 minted_amount;
        bool is_listed;
        bool is_enabled;
    }

    function DEFAULT_ADMIN_ADDRESS() external view returns (address);

    function balancer() external view returns (address);

    function treasury() external view returns (address);

    function collateral_agency() external view returns (address);

    function allowance(address holder, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isValidMinter(address) external view returns (bool);

    function amm() external view returns (address);

    function amm_price() external view returns (uint256);

    function twa_price() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function name() external view returns (string memory);

    function owner() external view returns (address);
    
    function fast_multisig() external view returns (address);

    function minter_burn_from(uint256 amount) external;

    function minter_mint(address m_address, uint256 m_amount) external;

    function minters(address m_address) external returns (Minter memory);

    function minter_addresses(uint256 index) external view returns (address);

    function getMinters() external view returns(address[] memory);

    function target_price() external view returns (uint256);

    function interest_rate() external view returns (int256);

    function period_time() external view returns (uint256);

    function step_value() external view returns (int256);

    function arb_spread() external view returns (uint256);

    function setInterestRate(int256 new_interest_rate) external;

    function setTargetPrice(uint256 current_target_price, uint256 next_target_price) external;    

    function startNewPeriod() external;

    function setUniswapOracle(address uniswap_oracle_address) external;

    function setTimelock(address new_timelock) external;

    function symbol() external view returns (string memory);

    function timelock_address() external view returns (address);

    function totalSupply() external view returns (uint256);

    function convertToUSD(uint256 amount) external view returns (uint256);

    function convertToSWEEP(uint256 amount) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}