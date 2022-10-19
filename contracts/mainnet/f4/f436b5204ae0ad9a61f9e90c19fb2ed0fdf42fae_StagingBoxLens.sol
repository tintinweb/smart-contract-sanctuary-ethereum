// SPDX-License-Identifier: GPL-3.0-or-later

import "./IRebasingERC20.sol";
import "./IButtonWrapper.sol";

// Interface definition for the ButtonToken ERC20 wrapper contract
interface IButtonToken is IButtonWrapper, IRebasingERC20 {
    /// @dev The reference to the oracle which feeds in the
    ///      price of the underlying token.
    function oracle() external view returns (address);

    /// @dev Most recent price recorded from the oracle.
    function lastPrice() external view returns (uint256);

    /// @dev Update reference to the oracle contract and resets price.
    /// @param oracle_ The address of the new oracle.
    function updateOracle(address oracle_) external;

    /// @dev Log to record changes to the oracle.
    /// @param oracle The address of the new oracle.
    event OracleUpdated(address oracle);

    /// @dev Contract initializer
    function initialize(
        address underlying_,
        string memory name_,
        string memory symbol_,
        address oracle_
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

// Interface definition for ButtonWrapper contract, which wraps an
// underlying ERC20 token into a new ERC20 with different characteristics.
// NOTE: "uAmount" => underlying token (wrapped) amount and
//       "amount" => wrapper token amount
interface IButtonWrapper {
    //--------------------------------------------------------------------------
    // ButtonWrapper write methods

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mint(uint256 amount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to mint.
    /// @return The amount of underlying tokens deposited.
    function mintFor(address to, uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burn(uint256 amount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param amount The amount of wrapper tokens to burn.
    /// @return The amount of underlying tokens withdrawn.
    function burnTo(address to, uint256 amount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of underlying tokens withdrawn.
    function burnAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of underlying tokens withdrawn.
    function burnAllTo(address to) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function deposit(uint256 uAmount) external returns (uint256);

    /// @notice Transfers underlying tokens from {msg.sender} to the contract and
    ///         mints wrapper tokens to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to deposit.
    /// @return The amount of wrapper tokens mint.
    function depositFor(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdraw(uint256 uAmount) external returns (uint256);

    /// @notice Burns wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back to the specified beneficiary.
    /// @param to The beneficiary account.
    /// @param uAmount The amount of underlying tokens to withdraw.
    /// @return The amount of wrapper tokens burnt.
    function withdrawTo(address to, uint256 uAmount) external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAll() external returns (uint256);

    /// @notice Burns all wrapper tokens from {msg.sender} and transfers
    ///         the underlying tokens back.
    /// @param to The beneficiary account.
    /// @return The amount of wrapper tokens burnt.
    function withdrawAllTo(address to) external returns (uint256);

    //--------------------------------------------------------------------------
    // ButtonWrapper view methods

    /// @return The address of the underlying token.
    function underlying() external view returns (address);

    /// @return The total underlying tokens held by the wrapper contract.
    function totalUnderlying() external view returns (uint256);

    /// @param who The account address.
    /// @return The underlying token balance of the account.
    function balanceOfUnderlying(address who) external view returns (uint256);

    /// @param uAmount The amount of underlying tokens.
    /// @return The amount of wrapper tokens exchangeable.
    function underlyingToWrapper(uint256 uAmount) external view returns (uint256);

    /// @param amount The amount of wrapper tokens.
    /// @return The amount of underlying tokens exchangeable.
    function wrapperToUnderlying(uint256 amount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

// Interface definition for Rebasing ERC20 tokens which have a "elastic" external
// balance and "fixed" internal balance. Each user's external balance is
// represented as a product of a "scalar" and the user's internal balance.
//
// From time to time the "Rebase" event updates scaler,
// which increases/decreases all user balances proportionally.
//
// The standard ERC-20 methods are denominated in the elastic balance
//
interface IRebasingERC20 is IERC20, IERC20Metadata {
    /// @notice Returns the fixed balance of the specified address.
    /// @param who The address to query.
    function scaledBalanceOf(address who) external view returns (uint256);

    /// @notice Returns the total fixed supply.
    function scaledTotalSupply() external view returns (uint256);

    /// @notice Transfer all of the sender's balance to a specified address.
    /// @param to The address to transfer to.
    /// @return True on success, false otherwise.
    function transferAll(address to) external returns (bool);

    /// @notice Transfer all balance tokens from one address to another.
    /// @param from The address to send tokens from.
    /// @param to The address to transfer to.
    function transferAllFrom(address from, address to) external returns (bool);

    /// @notice Triggers the next rebase, if applicable.
    function rebase() external;

    /// @notice Event emitted when the balance scalar is updated.
    /// @param epoch The number of rebases since inception.
    /// @param newScalar The new scalar.
    event Rebase(uint256 indexed epoch, uint256 newScalar);
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
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
        // Using an algorithm similar to the msb computation, we are able to compute `result = 2**(k/2)` which is a
        // good first approximation of `sqrt(a)` with at least 1 correct bit.
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./ITranche.sol";

struct TrancheData {
    ITranche token;
    uint256 ratio;
}

/**
 * @dev Controller for a ButtonTranche bond system
 */
interface IBondController {
    event Deposit(address from, uint256 amount, uint256 feeBps);
    event Mature(address caller);
    event RedeemMature(address user, address tranche, uint256 amount);
    event Redeem(address user, uint256[] amounts);
    event FeeUpdate(uint256 newFee);

    function collateralToken() external view returns (address);

    function tranches(uint256 i) external view returns (ITranche token, uint256 ratio);

    function trancheCount() external view returns (uint256 count);

    function feeBps() external view returns (uint256 fee);

    function maturityDate() external view returns (uint256 maturityDate);

    function isMature() external view returns (bool isMature);

    function creationDate() external view returns (uint256 creationDate);

    function totalDebt() external view returns (uint256 totalDebt);

    /**
     * @dev Deposit `amount` tokens from `msg.sender`, get tranche tokens in return
     * Requirements:
     *  - `msg.sender` must have `approved` `amount` collateral tokens to this contract
     */
    function deposit(uint256 amount) external;

    /**
     * @dev Matures the bond. Disables deposits,
     * fixes the redemption ratio, and distributes collateral to redemption pools
     * Redeems any fees collected from deposits, sending redeemed funds to the contract owner
     * Requirements:
     *  - The bond is not already mature
     *  - One of:
     *      - `msg.sender` is owner
     *      - `maturityDate` has passed
     */
    function mature() external;

    /**
     * @dev Redeems some tranche tokens
     * Requirements:
     *  - The bond is mature
     *  - `msg.sender` owns at least `amount` tranche tokens from address `tranche`
     *  - `tranche` must be a valid tranche token on this bond
     */
    function redeemMature(address tranche, uint256 amount) external;

    /**
     * @dev Redeems a slice of tranche tokens from all tranches.
     *  Returns collateral to the user proportionally to the amount of debt they are removing
     * Requirements
     *  - The bond is not mature
     *  - The number of `amounts` is the same as the number of tranches
     *  - The `amounts` are in equivalent ratio to the tranche order
     */
    function redeem(uint256[] memory amounts) external;

    /**
     * @dev Updates the fee taken on deposit to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */
    function setFee(uint256 newFeeBps) external;
}

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";

/**
 * @dev ERC20 token to represent a single tranche for a ButtonTranche bond
 *
 */
interface ITranche is IERC20 {
    /**
     * @dev returns the BondController address which owns this Tranche contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function bond() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically creating tokens upon deposit
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner (bond controller). Used to
     *  manage bonds, specifically burning tokens upon redemption
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from` and return the proportional
     * value of the collateral token to `to`
     * @param from The address to burn tokens from
     * @param to The address to send collateral back to
     * @param amount The amount of tokens to burn
     */
    function redeem(
        address from,
        address to,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBoxLens.sol";
import "../interfaces/IConvertibleBondBox.sol";
import "@buttonwood-protocol/button-wrappers/contracts/interfaces/IButtonToken.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract StagingBoxLens is IStagingBoxLens {
    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewTransmitReInitBool(IStagingBox _stagingBox)
        public
        view
        returns (bool)
    {
        bool isLend = false;

        uint256 stableBalance = _stagingBox.stableToken().balanceOf(
            address(_stagingBox)
        );
        uint256 safeTrancheBalance = _stagingBox.safeTranche().balanceOf(
            address(_stagingBox)
        );
        uint256 expectedStableLoan = (safeTrancheBalance *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        //if excess borrowDemand, call lend
        if (expectedStableLoan >= stableBalance) {
            isLend = true;
        }

        return isLend;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewSimpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw
    ) public view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate rebase token qty w wrapperfunction
        uint256 buttonAmount = wrapper.underlyingToWrapper(_amountRaw);

        //calculate safeTranche (borrowSlip amount) amount with tranche ratio & CDR
        uint256 bondCollateralBalance = wrapper.balanceOf(address(bond));

        uint256 bondDebt = bond.totalDebt();

        if (bondDebt == 0) {
            bondDebt = buttonAmount;
            bondCollateralBalance = buttonAmount;
        }

        uint256 safeTrancheAmount = (buttonAmount *
            convertibleBondBox.safeRatio() *
            bondDebt) /
            bondCollateralBalance /
            convertibleBondBox.s_trancheGranularity();

        //calculate stabletoken amount w/ safeTrancheAmount & initialPrice
        uint256 stableLoanAmount = (safeTrancheAmount *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return (stableLoanAmount, safeTrancheAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewSimpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) public view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        uint256 safeTrancheAmount = (_borrowSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        uint256 riskTrancheAmount = (safeTrancheAmount *
            convertibleBondBox.riskRatio()) / convertibleBondBox.safeRatio();

        //calculate total amount of tranche tokens by dividing by safeRatio
        uint256 trancheTotal = safeTrancheAmount + riskTrancheAmount;

        //multiply with CDR to get btn token amount
        uint256 buttonAmount = 0;
        if (bond.totalDebt() > 0) {
            if (!bond.isMature()) {
                buttonAmount =
                    (trancheTotal *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(bond)
                        )) /
                    bond.totalDebt();
            } else {
                buttonAmount =
                    (safeTrancheAmount *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(convertibleBondBox.safeTranche())
                        )) /
                    convertibleBondBox.safeTranche().totalSupply();
                buttonAmount +=
                    (riskTrancheAmount *
                        convertibleBondBox.collateralToken().balanceOf(
                            address(convertibleBondBox.riskTranche())
                        )) /
                    convertibleBondBox.riskTranche().totalSupply();
            }
        }

        //calculate underlying with ButtonTokenWrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewWithdrawLendSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256) {
        return _lendSlipAmount;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewRedeemBorrowSlipForRiskSlip(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256) {
        uint256 loanAmount = _borrowSlipAmount;

        uint256 riskSlipAmount = (loanAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.riskRatio() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.safeRatio() /
            _stagingBox.stableDecimals();

        return (riskSlipAmount, loanAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256) {
        uint256 safeSlipAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return (safeSlipAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) public view returns (uint256, uint256) {
        //calculate lendSlips to safeSlips w/ initialPrice
        uint256 safeSlipsAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return _safeSlipsForStablesWithFees(_stagingBox, safeSlipsAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemSafeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) public view returns (uint256, uint256) {
        return _safeSlipsForStablesWithFees(_stagingBox, _safeSlipAmount);
    }

    function _safeSlipsForStablesWithFees(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256, uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 feeSlip = (_safeSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        uint256 stableAmount = _safeSlipsForStables(
            _stagingBox,
            _safeSlipAmount - feeSlip
        );
        uint256 feeAmount = _safeSlipsForStables(_stagingBox, feeSlip);

        return (stableAmount, feeAmount);
    }

    function _safeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //calculate safeSlips to stables via math for CBB redeemStable
        uint256 cbbStableBalance = _stagingBox.stableToken().balanceOf(
            address(convertibleBondBox)
        );

        uint256 stableAmount = 0;

        if (convertibleBondBox.s_repaidSafeSlips() > 0) {
            stableAmount =
                (_safeSlipAmount * cbbStableBalance) /
                convertibleBondBox.s_repaidSafeSlips();
        }

        return stableAmount;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemLendSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        //calculate lendSlips to safeSlips w/ initialPrice
        uint256 safeSlipsAmount = (_lendSlipAmount *
            _stagingBox.priceGranularity() *
            _stagingBox.trancheDecimals()) /
            _stagingBox.initialPrice() /
            _stagingBox.stableDecimals();

        return _safeSlipRedeemUnwrapWithFees(_stagingBox, safeSlipsAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemSafeSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return _safeSlipRedeemUnwrapWithFees(_stagingBox, _safeSlipAmount);
    }

    function _safeSlipRedeemUnwrapWithFees(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 feeSlip = (_safeSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        (
            uint256 underlyingAmount,
            uint256 buttonAmount
        ) = _safeSlipRedeemUnwrap(_stagingBox, _safeSlipAmount - feeSlip);

        (uint256 underlyingFee, uint256 buttonFee) = _safeSlipRedeemUnwrap(
            _stagingBox,
            feeSlip
        );

        return (underlyingAmount, buttonAmount, underlyingFee, buttonFee);
    }

    function _safeSlipRedeemUnwrap(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) internal view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //safeSlips = safeTranches
        //calculate safe tranches to rebasing collateral via balance of safeTranche address
        uint256 buttonAmount = (wrapper.balanceOf(
            address(_stagingBox.safeTranche())
        ) * _safeSlipAmount) / _stagingBox.safeTranche().totalSupply();

        //calculate penalty riskTranche
        uint256 penaltyTrancheTotal = _stagingBox.riskTranche().balanceOf(
            address(convertibleBondBox)
        ) - IERC20(_stagingBox.riskSlipAddress()).totalSupply();

        uint256 penaltyTrancheRedeemable = (_safeSlipAmount *
            penaltyTrancheTotal) /
            (IERC20(_stagingBox.safeSlipAddress()).totalSupply() -
                convertibleBondBox.s_repaidSafeSlips());

        //calculate rebasing collateral redeemable for riskTranche penalty
        //total the rebasing collateral
        buttonAmount +=
            (wrapper.balanceOf(address(_stagingBox.riskTranche())) *
                penaltyTrancheRedeemable) /
            _stagingBox.riskTranche().totalSupply();

        //convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRedeemRiskSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        //subtract fees
        uint256 feeSlip = (_riskSlipAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        (
            uint256 underlyingAmount,
            uint256 buttonAmount
        ) = _redeemRiskSlipForTranches(_stagingBox, _riskSlipAmount - feeSlip);
        (uint256 underlyingFee, uint256 buttonFee) = _redeemRiskSlipForTranches(
            _stagingBox,
            feeSlip
        );

        return (underlyingAmount, buttonAmount, underlyingFee, buttonFee);
    }

    function _redeemRiskSlipForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    ) internal view returns (uint256, uint256) {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate riskSlip to riskTranche - penalty
        uint256 riskTrancheAmount = _riskSlipAmount -
            (_riskSlipAmount * convertibleBondBox.penalty()) /
            convertibleBondBox.s_penaltyGranularity();
        //calculate rebasing collateral redeemable for riskTranche - penalty via tranche balance
        uint256 buttonAmount = (wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        ) * riskTrancheAmount) / _stagingBox.riskTranche().totalSupply();
        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);
        // return both
        return (underlyingAmount, buttonAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //minus fees
        uint256 stableFees = (_stableAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //calculate safeTranches for stables w/ current price
        uint256 safeTranchePayout = (_stableAmount *
            convertibleBondBox.s_priceGranularity() *
            convertibleBondBox.trancheDecimals()) /
            convertibleBondBox.currentPrice() /
            convertibleBondBox.stableDecimals();

        uint256 riskTranchePayout = (safeTranchePayout *
            convertibleBondBox.riskRatio()) / convertibleBondBox.safeRatio();

        //get collateral balance for rebasing collateral output
        uint256 collateralBalance = wrapper.balanceOf(address(bond));
        uint256 buttonAmount = (safeTranchePayout *
            convertibleBondBox.s_trancheGranularity() *
            collateralBalance) /
            convertibleBondBox.safeRatio() /
            bond.totalDebt();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, _stableAmount, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //riskTranche payout = riskSlipAmount
        uint256 riskTranchePayout = _riskSlipAmount;
        uint256 safeTranchePayout = (riskTranchePayout *
            _stagingBox.safeRatio()) / _stagingBox.riskRatio();

        //calculate repayment cost
        uint256 stablesOwed = (safeTranchePayout *
            convertibleBondBox.currentPrice() *
            convertibleBondBox.stableDecimals()) /
            convertibleBondBox.s_priceGranularity() /
            convertibleBondBox.trancheDecimals();

        //calculate stable Fees
        uint256 stableFees = (stablesOwed * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //get collateral balance for rebasing collateral output
        uint256 collateralBalance = wrapper.balanceOf(address(bond));
        uint256 buttonAmount = (safeTranchePayout *
            convertibleBondBox.s_trancheGranularity() *
            collateralBalance) /
            convertibleBondBox.safeRatio() /
            bond.totalDebt();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, stablesOwed, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //calculate fees
        uint256 stableFees = (_stableAmount * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //calculate tranches
        uint256 safeTranchepayout = (_stableAmount *
            convertibleBondBox.trancheDecimals()) /
            convertibleBondBox.stableDecimals();

        uint256 riskTranchePayout = (safeTranchepayout *
            _stagingBox.riskRatio()) / _stagingBox.safeRatio();

        //get collateral balance for safeTranche rebasing collateral output
        uint256 collateralBalanceSafe = wrapper.balanceOf(
            address(_stagingBox.safeTranche())
        );
        uint256 buttonAmount = (safeTranchepayout * collateralBalanceSafe) /
            convertibleBondBox.safeTranche().totalSupply();

        //get collateral balance for riskTranche rebasing collateral output
        uint256 collateralBalanceRisk = wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        );
        buttonAmount +=
            (riskTranchePayout * collateralBalanceRisk) /
            convertibleBondBox.riskTranche().totalSupply();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, _stableAmount, stableFees, riskTranchePayout);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewRepayMaxAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            IConvertibleBondBox convertibleBondBox,
            ,
            IButtonToken wrapper,

        ) = fetchElasticStack(_stagingBox);

        //Calculate tranches
        //riskTranche payout = riskSlipAmount
        uint256 safeTranchePayout = (_riskSlipAmount *
            _stagingBox.safeRatio()) / _stagingBox.riskRatio();

        uint256 stablesOwed = (safeTranchePayout *
            _stagingBox.stableDecimals()) / _stagingBox.trancheDecimals();

        //calculate stable Fees
        uint256 stableFees = (stablesOwed * convertibleBondBox.feeBps()) /
            convertibleBondBox.BPS();

        //get collateral balance for safeTranche rebasing collateral output
        uint256 buttonAmount = (safeTranchePayout *
            wrapper.balanceOf(address(_stagingBox.safeTranche()))) /
            convertibleBondBox.safeTranche().totalSupply();

        //get collateral balance for riskTranche rebasing collateral output
        uint256 collateralBalanceRisk = wrapper.balanceOf(
            address(_stagingBox.riskTranche())
        );

        buttonAmount +=
            (_riskSlipAmount * collateralBalanceRisk) /
            convertibleBondBox.riskTranche().totalSupply();

        // convert rebasing collateral to collateralToken qty via wrapper
        uint256 underlyingAmount = wrapper.wrapperToUnderlying(buttonAmount);

        // return both
        return (underlyingAmount, stablesOwed, stableFees, _riskSlipAmount);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */
    function viewMaxRedeemBorrowSlip(IStagingBox _stagingBox, address _account)
        public
        view
        returns (uint256)
    {
        uint256 userBorrowSlip = _stagingBox.borrowSlip().balanceOf(_account);
        return Math.min(userBorrowSlip, _stagingBox.s_reinitLendAmount());
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);
        uint256 sb_safeSlips = convertibleBondBox.safeSlip().balanceOf(
            address(_stagingBox)
        );

        uint256 maxRedeemableLendSlips = (sb_safeSlips *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, maxRedeemableLendSlips);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 sb_safeSlips = convertibleBondBox.safeSlip().balanceOf(
            address(_stagingBox)
        );

        uint256 maxRedeemableLendSlips = (Math.min(
            sb_safeSlips,
            convertibleBondBox.s_repaidSafeSlips()
        ) *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, maxRedeemableLendSlips);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemSafeSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userSafeSlip = convertibleBondBox.safeSlip().balanceOf(
            _account
        );

        return Math.min(userSafeSlip, convertibleBondBox.s_repaidSafeSlips());
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxWithdrawLendSlips(IStagingBox _stagingBox, address _account)
        public
        view
        returns (uint256)
    {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 maxWithdrawableLendSlips = userLendSlip;

        if (convertibleBondBox.s_startDate() > 0) {
            uint256 withdrawableStables = _stagingBox.stableToken().balanceOf(
                address(_stagingBox)
            ) - _stagingBox.s_reinitLendAmount();

            maxWithdrawableLendSlips = Math.min(
                userLendSlip,
                withdrawableStables
            );
        }

        return maxWithdrawableLendSlips;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxWithdrawBorrowSlips(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );

        uint256 userBorrowSlip = _stagingBox.borrowSlip().balanceOf(_account);

        uint256 maxWithdrawableBorrowSlip = userBorrowSlip;

        if (convertibleBondBox.s_startDate() > 0) {
            uint256 withdrawableSafeTranche = _stagingBox
                .safeTranche()
                .balanceOf(address(_stagingBox));

            uint256 withdrawableSafeTrancheToBorrowSlip = (withdrawableSafeTranche *
                    _stagingBox.initialPrice() *
                    _stagingBox.stableDecimals()) /
                    _stagingBox.priceGranularity() /
                    _stagingBox.trancheDecimals();

            maxWithdrawableBorrowSlip = Math.min(
                userBorrowSlip,
                withdrawableSafeTrancheToBorrowSlip
            );
        }

        return maxWithdrawableBorrowSlip;
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemSafeSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userSafeSlip = convertibleBondBox.safeSlip().balanceOf(
            _account
        );

        uint256 cbbSafeTrancheBalance = convertibleBondBox
            .safeTranche()
            .balanceOf(address(convertibleBondBox));

        return Math.min(userSafeSlip, cbbSafeTrancheBalance);
    }

    /**
     * @inheritdoc IStagingBoxLens
     */

    function viewMaxRedeemLendSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) public view returns (uint256) {
        (IConvertibleBondBox convertibleBondBox, , , ) = fetchElasticStack(
            _stagingBox
        );
        uint256 userLendSlip = _stagingBox.lendSlip().balanceOf(_account);

        uint256 cbbSafeTrancheBalance = convertibleBondBox
            .safeTranche()
            .balanceOf(address(convertibleBondBox));

        uint256 cbbSafeTrancheToLendSlip = (cbbSafeTrancheBalance *
            _stagingBox.initialPrice() *
            _stagingBox.stableDecimals()) /
            _stagingBox.priceGranularity() /
            _stagingBox.trancheDecimals();

        return Math.min(userLendSlip, cbbSafeTrancheToLendSlip);
    }

    function fetchElasticStack(IStagingBox _stagingBox)
        internal
        view
        returns (
            IConvertibleBondBox,
            IBondController,
            IButtonToken,
            IERC20
        )
    {
        IConvertibleBondBox convertibleBondBox = _stagingBox
            .convertibleBondBox();
        IBondController bond = convertibleBondBox.bond();
        IButtonToken wrapper = IButtonToken(bond.collateralToken());
        IERC20 underlying = IERC20(wrapper.underlying());

        return (convertibleBondBox, bond, wrapper, underlying);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.13;

import "../../utils/ICBBImmutableArgs.sol";

/**
 * @dev Convertible Bond Box for a ButtonTranche bond
 */

interface IConvertibleBondBox is ICBBImmutableArgs {
    event Lend(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event Borrow(
        address caller,
        address borrower,
        address lender,
        uint256 stableAmount,
        uint256 price
    );
    event RedeemStable(address caller, uint256 safeSlipAmount, uint256 price);
    event RedeemSafeTranche(address caller, uint256 safeSlipAmount);
    event RedeemRiskTranche(address caller, uint256 riskSlipAmount);
    event Repay(
        address caller,
        uint256 stablesPaid,
        uint256 riskTranchePayout,
        uint256 price
    );
    event Initialized(address owner);
    event ReInitialized(uint256 initialPrice, uint256 timestamp);
    event FeeUpdate(uint256 newFee);

    error PenaltyTooHigh(uint256 given, uint256 maxPenalty);
    error BondIsMature(uint256 currentTime, uint256 maturity);
    error InitialPriceTooHigh(uint256 given, uint256 maxPrice);
    error InitialPriceIsZero(uint256 given, uint256 maxPrice);
    error ConvertibleBondBoxNotStarted(uint256 given, uint256 minStartDate);
    error BondNotMatureYet(uint256 maturityDate, uint256 currentTime);
    error MinimumInput(uint256 input, uint256 reqInput);
    error FeeTooLarge(uint256 input, uint256 maximum);

    //Need to add getters for state variables

    /**
     * @dev Sets startdate to be block.timestamp, sets initialPrice, and takes initial atomic deposit
     * @param _initialPrice the initialPrice for the CBB
     * Requirements:
     *  - `msg.sender` is owner
     */

    function reinitialize(uint256 _initialPrice) external;

    /**
     * @dev Lends StableTokens for SafeSlips when provided with matching borrow collateral
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _stableAmount The amount of StableTokens to lend
     * Requirements:
     *  - `msg.sender` must have `approved` `_stableAmount` stable tokens to this contract
        - CBB must be reinitialized
     */

    function lend(
        address _borrower,
        address _lender,
        uint256 _stableAmount
    ) external;

    /**
     * @dev Borrows with tranches of CollateralTokens when provided with a matching amount of StableTokens
     * Collateral tokens get tranched and any non-convertible bond box tranches get sent back to borrower 
     * @param _borrower The address to send the RiskSlip and StableTokens to 
     * @param _lender The address to send the SafeSlips to 
     * @param _safeTrancheAmount The amount of SafeTranche being borrowed against
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of tranches of tokens to this contract
        - CBB must be reinitialized
        - must be enough stable tokens inside convertible bond box to borrow 
     */

    function borrow(
        address _borrower,
        address _lender,
        uint256 _safeTrancheAmount
    ) external;

    /**
     * @dev returns time-weighted current price for SafeSlip, with final price as $1.00 at maturity
     */

    function currentPrice() external view returns (uint256);

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _stableAmount The amount of stable-Tokens to repay with
     * Requirements:
     *  - `msg.sender` must have `approved` `stableAmount` of stable tokens to this contract
     */

    function repay(uint256 _stableAmount) external;

    /**
     * @dev allows repayment of loan in exchange for proportional amount of SafeTranche and Z-tranche
     * @param _riskSlipAmount The amount of riskSlips to be repaid
     * Requirements:
     *  - `msg.sender` must have `approved` appropriate amount of stable tokens to this contract
     */

    function repayMax(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for SafeTranches
     * @param _safeSlipAmount The amount of safe-slips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `safeSlipAmount` of SafeSlip tokens to this contract
     */

    function redeemSafeTranche(uint256 _safeSlipAmount) external;

    /**
     * @dev allows borrower to redeem RiskSlips for tranches (i.e. default)
     * @param _riskSlipAmount The amount of RiskSlips to redeem
     * Requirements:
     *  - can only be called after Bond is Mature
     *  - `msg.sender` must have `approved` `_riskSlipAmount` of RiskSlip tokens to this contract
     */

    function redeemRiskTranche(uint256 _riskSlipAmount) external;

    /**
     * @dev allows lender to redeem SafeSlips for StableTokens
     * @param _safeSlipAmount The amount of SafeSlips to redeem
     * Requirements:
     *  - `msg.sender` must have `approved` `safeSlipAmount` of safe-Slip tokens to this contract
     *  - can only be called when StableTokens are present inside CBB
     */

    function redeemStable(uint256 _safeSlipAmount) external;

    /**
     * @dev Updates the fee taken on redeem/repay to the given new fee
     *
     * Requirements
     * - `msg.sender` has admin role
     * - `newFeeBps` is in range [0, 50]
     */

    function setFee(uint256 newFeeBps) external;

    /**
     * @dev Gets the start date
     */
    function s_startDate() external view returns (uint256);

    /**
     * @dev Gets the total repaid safe slips to date
     */
    function s_repaidSafeSlips() external view returns (uint256);

    /**
     * @dev Gets the tranche granularity constant
     */
    function s_trancheGranularity() external view returns (uint256);

    /**
     * @dev Gets the penalty granularity constant
     */
    function s_penaltyGranularity() external view returns (uint256);

    /**
     * @dev Gets the price granularity constant
     */
    function s_priceGranularity() external view returns (uint256);

    /**
     * @dev Gets the fee basis points
     */
    function feeBps() external view returns (uint256);

    /**
     * @dev Gets the basis points denominator constant. AKA a fee granularity constant
     */
    function BPS() external view returns (uint256);

    /**
     * @dev Gets the max fee basis points constant.
     */
    function maxFeeBPS() external view returns (uint256);

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Gets the initialPrice of SafeSlip.
     */
    function s_initialPrice() external view returns (uint256);
}

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev ERC20 token to represent a single slip for a bond box
 *
 */
interface ISlip is IERC20 {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev returns the bond box address which owns this slip contract
     *  It should have admin permissions to call mint, burn, and redeem functions
     */
    function boxOwner() external view returns (address);

    /**
     * @dev Mint `amount` tokens to `to`
     *  Only callable by the owner.
     * @param to the address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) external;

    /**
     * @dev Burn `amount` tokens from `from`'s balance
     *  Only callable by the owner.
     * @param from The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address from, uint256 amount) external;

    /**
     * @dev allows owner to transfer ownership to a new owner. Implemented so that factory can transfer minting/burning ability to CBB after deployment
     * @param newOwner The address of the CBB
     */
    function changeOwner(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../../utils/ISBImmutableArgs.sol";

interface IStagingBox is ISBImmutableArgs {
    event LendDeposit(address lender, uint256 lendAmount);
    event BorrowDeposit(address borrower, uint256 safeTrancheAmount);
    event LendWithdrawal(address lender, uint256 lendSlipAmount);
    event BorrowWithdrawal(address borrower, uint256 borrowSlipAmount);
    event RedeemBorrowSlip(address caller, uint256 borrowSlipAmount);
    event RedeemLendSlip(address caller, uint256 lendSlipAmount);
    event Initialized(address owner);

    error InitialPriceTooHigh(uint256 given, uint256 maxPrice);
    error InitialPriceIsZero(uint256 given, uint256 maxPrice);
    error WithdrawAmountTooHigh(uint256 requestAmount, uint256 maxAmount);
    error CBBReinitialized(bool state, bool requiredState);

    function s_reinitLendAmount() external view returns (uint256);

    /**
     * @dev Deposits collateral for BorrowSlips
     * @param _borrower The recipent address of the BorrowSlips
     * @param _borrowAmount The amount of stableTokens to be borrowed
     * Requirements:
     *  - `msg.sender` must have `approved` `stableAmount` stable tokens to this contract
     */

    function depositBorrow(address _borrower, uint256 _borrowAmount) external;

    /**
     * @dev deposit _lendAmount of stable-tokens for LendSlips
     * @param _lender The recipent address of the LenderSlips
     * @param _lendAmount The amount of stable tokens to deposit
     * Requirements:
     *  - `msg.sender` must have `approved` `stableAmount` stable tokens to this contract
     */

    function depositLend(address _lender, uint256 _lendAmount) external;

    /**
     * @dev Burns BorrowSlips for Collateral
     * @param _borrowSlipAmount The amount of borrowSlips to withdraw
     * Requirements:
     */

    function withdrawBorrow(uint256 _borrowSlipAmount) external;

    /**
     * @dev burns LendSlips for Stables
     * @param _lendSlipAmount The amount of stable tokens to withdraw
     * Requirements:
     * - Cannot withdraw more than s_reinitLendAmount after reinitialization
     */

    function withdrawLend(uint256 _lendSlipAmount) external;

    /**
     * @dev Exchanges BorrowSlips for RiskSlips + Stablecoin loan
     * @param _borrowSlipAmount amount of BorrowSlips to redeem RiskSlips and USDT with
     * Requirements:
     */

    function redeemBorrowSlip(uint256 _borrowSlipAmount) external;

    /**
     * @dev Exchanges lendSlips for safeSlips
     * @param _lendSlipAmount amount of LendSlips to redeem SafeSlips with
     * Requirements:
     */

    function redeemLendSlip(uint256 _lendSlipAmount) external;

    /**
     * @dev Transmits the the Reinitialization to the CBB
     * @param _lendOrBorrow boolean to indicate whether to initial deposit should be a 'borrow' or a 'lend'
     * Requirements:
     * - StagingBox must be the owner of the CBB to call this function
     * - Change owner of CBB to be the SB prior to calling this function if not already done
     */

    function transmitReInit(bool _lendOrBorrow) external;

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external;

    /**
     * @dev Transfers ownership of the CBB contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferCBBOwnership(address newOwner) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBox.sol";

interface IStagingBoxLens {
    /**
     * @dev provides the bool for limiting factor for the staging box reinit
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewTransmitReInitBool(IStagingBox _stagingBox)
        external
        view
        returns (bool);

    /**
     * @dev provides amount of stableTokens expected in return for a given collateral amount
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _amountRaw The amount of unwrapped tokens to be used as collateral
     * Requirements:
     */

    function viewSimpleWrapTrancheBorrow(
        IStagingBox _stagingBox,
        uint256 _amountRaw
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of raw collateral tokens expected in return for withdrawing borrowslips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _borrowSlipAmount The amount of borrowSlips to be withdrawn
     * Requirements:
     * - for A-Z convertible only
     */

    function viewSimpleWithdrawBorrowUnwrap(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of stable tokens expected in return for withdrawing lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be withdrawn
     * Requirements:
     */

    function viewWithdrawLendSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256);

    /**
     * @dev provides amount of riskSlips and stableToken loan in return for borrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _borrowSlipAmount The amount of borrowSlips to be redeemed
     * Requirements:
     */

    function viewRedeemBorrowSlipForRiskSlip(
        IStagingBox _stagingBox,
        uint256 _borrowSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of safeSlips expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256);

    /**
     * @dev provides amount of stableTokens expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of stableTokens expected in return for redeeming safeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _safeSlipAmount The amount of safeSlips to be redeemed
     * Requirements:
     */

    function viewRedeemSafeSlipsForStables(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    ) external view returns (uint256, uint256);

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming lendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _lendSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemLendSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _lendSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming safeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _safeSlipAmount The amount of lendSlips to be redeemed
     * Requirements:
     */

    function viewRedeemSafeSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _safeSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for redeeming riskSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _riskSlipAmount The amount of riskSlips to be redeemed
     * Requirements:
     */

    function viewRedeemRiskSlipsForTranches(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of stables
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stables being repaid
     * Requirements:
     *      - Only for prior to maturity
     *      - Only for bonds with A/Z tranches
     */

    function viewRepayAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of RiskSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     *      - Only for prior to maturity
     *      - Only for bonds with A/Z tranches
     */

    function viewRepayMaxAndUnwrapSimple(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of StableTokens (after maturity)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _stableAmount The amount of stables being repaid
     * Requirements:
     *      - Only for after maturity
     
     */

    function viewRepayAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _stableAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides amount of raw collateral tokens expected in return for repaying an exact amount of RiskSlips (after maturity)
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _riskSlipAmount The amount of stables being repaid
     * Requirements:
     *      - Only for after maturity
     */

    function viewRepayMaxAndUnwrapMature(
        IStagingBox _stagingBox,
        uint256 _riskSlipAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev provides maximum input param for a user redeeming BorrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemBorrowSlip(IStagingBox _stagingBox, address _account)
        external
        view
        returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming LendSlips for SafeSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForSafeSlip(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming LendSlips for StableTokens
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming SafeSlips for StableTokens
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemSafeSlipForStables(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user withdrawing LendSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxWithdrawLendSlips(IStagingBox _stagingBox, address _account)
        external
        view
        returns (uint256);

    /**
     * @dev provides maximum input param for a user withdrawing BorrowSlips
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxWithdrawBorrowSlips(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming SafeSlips for tranches
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemSafeSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);

    /**
     * @dev provides maximum input param for a user redeeming lend slips for tranches
     * @param _stagingBox The staging box tied to the Convertible Bond
     * @param _account The address of the user
     * Requirements:
     */

    function viewMaxRedeemLendSlipForTranches(
        IStagingBox _stagingBox,
        address _account
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/ISlip.sol";
import "@buttonwood-protocol/tranche/contracts/interfaces/IBondController.sol";

interface ICBBImmutableArgs {
    /**
     * @notice The bond that holds the tranches
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The underlying buttonwood bond
     */
    function bond() external pure returns (IBondController);

    /**
     * @notice The safeSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeSlip Slip object
     */
    function safeSlip() external pure returns (ISlip);

    /**
     * @notice The riskSlip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskSlip Slip object
     */
    function riskSlip() external pure returns (ISlip);

    /**
     * @notice penalty for zslips
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The penalty ratio
     */
    function penalty() external pure returns (uint256);

    /**
     * @notice The rebasing collateral token used to make bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The rebasing collateral token object
     */
    function collateralToken() external pure returns (IERC20);

    /**
     * @notice The stable token used to buy bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The stable token object
     */
    function stableToken() external pure returns (IERC20);

    /**
     * @notice The tranche index used to pick a safe tranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The index representing the tranche
     */
    function trancheIndex() external pure returns (uint256);

    /**
     * @notice The maturity date of the underlying buttonwood bond
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The timestamp for the bond maturity
     */

    function maturityDate() external pure returns (uint256);

    /**
     * @notice The safeTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeTranche tranche object
     */

    function safeTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the safeTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the safeTranche
     */

    function safeRatio() external pure returns (uint256);

    /**
     * @notice The riskTranche of the Convertible Bond Box
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskTranche tranche object
     */

    function riskTranche() external pure returns (ITranche);

    /**
     * @notice The tranche ratio of the riskTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the riskTranche
     */

    function riskRatio() external pure returns (uint256);

    /**
     * @notice The decimals of tranche-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of tranche-tokens
     */

    function trancheDecimals() external pure returns (uint256);

    /**
     * @notice The decimals of stable-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of stable-tokens
     */

    function stableDecimals() external pure returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../src/interfaces/IConvertibleBondBox.sol";

interface ISBImmutableArgs {
    /**
     * @notice the lend slip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The lend slip object
     */
    function lendSlip() external pure returns (ISlip);

    /**
     * @notice the borrow slip object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The borrowSlip object
     */
    function borrowSlip() external pure returns (ISlip);

    /**
     * @notice The convertible bond box object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The convertible bond box object
     */
    function convertibleBondBox() external pure returns (IConvertibleBondBox);

    /**
     * @notice The cnnvertible bond box object
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The convertible bond box object
     */
    function initialPrice() external pure returns (uint256);

    /**
     * @notice The stable token used to buy bonds
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The stable token object
     */

    function stableToken() external pure returns (IERC20);

    /**
     * @notice The safeTranche of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The safeTranche object
     */

    function safeTranche() external pure returns (ITranche);

    /**
     * @notice The address of the safeslip of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The address of the safeslip of the CBB
     */

    function safeSlipAddress() external pure returns (address);

    /**
     * @notice The tranche ratio of the safeTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the safeTranche of the CBB
     */

    function safeRatio() external pure returns (uint256);

    /**
     * @notice The riskTranche of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The riskTranche tranche object
     */

    function riskTranche() external pure returns (ITranche);

    /**
     * @notice The address of the riskSlip of the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The address of the riskSlip of the CBB
     */

    function riskSlipAddress() external pure returns (address);

    /**
     * @notice The tranche ratio of the riskTranche
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The tranche ratio of the riskTranche of the CBB
     */

    function riskRatio() external pure returns (uint256);

    /**
     * @notice The price granularity on the CBB
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The price granularity on the CBB
     */

    function priceGranularity() external pure returns (uint256);

    /**
     * @notice The decimals of tranche-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of tranche-tokens
     */

    function trancheDecimals() external pure returns (uint256);

    /**
     * @notice The decimals of stable-tokens
     * @dev using ClonesWithImmutableArgs pattern here to save gas
     * @dev https://github.com/wighawag/clones-with-immutable-args
     * @return The decimals of stable-tokens
     */

    function stableDecimals() external pure returns (uint256);
}