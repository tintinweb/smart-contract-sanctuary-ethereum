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

import "../interfaces/IConvertiblesDVLens.sol";
import "../interfaces/IConvertibleBondBox.sol";
import "../../src/contracts/external/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @dev View functions only - for front-end use
 */

contract ConvertiblesDVLens is IConvertiblesDVLens {
    struct DecimalPair {
        uint256 tranche;
        uint256 stable;
    }

    struct CollateralBalance {
        uint256 safe;
        uint256 risk;
    }

    struct StagingBalances {
        uint256 safeTranche;
        uint256 riskTranche;
        uint256 safeSlip;
        uint256 riskSlip;
        uint256 stablesBorrow;
        uint256 stablesLend;
        uint256 stablesTotal;
    }

    function viewStagingStatsIBO(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataIBO memory)
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond
        ) = fetchElasticStack(_stagingBox);
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox))
        );
        uint256 stableBalance = _stagingBox.stableToken().balanceOf(
            address(_stagingBox)
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_stagingBox.safeTranche())).decimals(),
            ERC20(address(_stagingBox.stableToken())).decimals()
        );

        StagingDataIBO memory data = StagingDataIBO(
            NumFixedPoint(
                _stagingBox.lendSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.borrowSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
                decimals.tranche
            ),
            NumFixedPoint(
                _stagingBox.riskTranche().balanceOf(address(_stagingBox)),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                (simTrancheCollateral.safe + simTrancheCollateral.risk),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable)
        );

        return data;
    }

    function viewStagingStatsActive(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataActive memory)
    {
        (
            IConvertibleBondBox convertibleBondBox,
            IBondController bond
        ) = fetchElasticStack(_stagingBox);
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox))
        );
        CollateralBalance memory simSlipCollateral = calcTrancheCollateral(
            convertibleBondBox,
            bond,
            convertibleBondBox.safeSlip().balanceOf(address(_stagingBox)),
            convertibleBondBox.riskSlip().balanceOf(address(_stagingBox))
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_stagingBox.safeTranche())).decimals(),
            ERC20(address(_stagingBox.stableToken())).decimals()
        );

        StagingBalances memory SB_Balances = StagingBalances(
            _stagingBox.safeTranche().balanceOf(address(_stagingBox)),
            _stagingBox.riskTranche().balanceOf(address(_stagingBox)),
            _stagingBox.convertibleBondBox().safeSlip().balanceOf(
                address(_stagingBox)
            ),
            _stagingBox.convertibleBondBox().riskSlip().balanceOf(
                address(_stagingBox)
            ),
            _stagingBox.s_reinitLendAmount(),
            _stagingBox.stableToken().balanceOf(address(_stagingBox)) -
                _stagingBox.s_reinitLendAmount(),
            _stagingBox.stableToken().balanceOf(address(_stagingBox))
        );

        StagingDataActive memory data = StagingDataActive(
            NumFixedPoint(
                _stagingBox.lendSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(
                _stagingBox.borrowSlip().totalSupply(),
                decimals.stable
            ),
            NumFixedPoint(SB_Balances.safeTranche, decimals.tranche),
            NumFixedPoint(SB_Balances.riskTranche, decimals.tranche),
            NumFixedPoint(SB_Balances.safeSlip, decimals.tranche),
            NumFixedPoint(SB_Balances.riskSlip, decimals.tranche),
            NumFixedPoint(SB_Balances.stablesBorrow, decimals.stable),
            NumFixedPoint(SB_Balances.stablesLend, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(simSlipCollateral.safe, decimals.tranche),
            NumFixedPoint(simSlipCollateral.risk, decimals.tranche),
            NumFixedPoint(
                ((simTrancheCollateral.safe +
                    simTrancheCollateral.risk +
                    simSlipCollateral.risk) *
                    10**decimals.stable +
                    _stagingBox.s_reinitLendAmount() *
                    10**decimals.tranche),
                decimals.tranche + decimals.stable
            ),
            NumFixedPoint(
                (SB_Balances.stablesLend) +
                    (SB_Balances.safeSlip *
                        convertibleBondBox.currentPrice() *
                        (10**decimals.stable)) /
                    convertibleBondBox.s_priceGranularity() /
                    (10**decimals.tranche),
                decimals.stable
            )
        );
        return data;
    }

    function viewCBBStatsActive(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataActive memory)
    {
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            _convertibleBondBox,
            _convertibleBondBox.bond(),
            _convertibleBondBox.safeTranche().balanceOf(
                address(_convertibleBondBox)
            ),
            _convertibleBondBox.riskTranche().balanceOf(
                address(_convertibleBondBox)
            )
        );
        uint256 stableBalance = _convertibleBondBox.stableToken().balanceOf(
            address(_convertibleBondBox)
        );

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_convertibleBondBox.safeTranche())).decimals(),
            ERC20(address(_convertibleBondBox.stableToken())).decimals()
        );

        CBBDataActive memory data = CBBDataActive(
            NumFixedPoint(
                _convertibleBondBox.safeSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.s_repaidSafeSlips(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.safeTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                _convertibleBondBox.currentPrice(),
                _convertibleBondBox.s_priceGranularity()
            ),
            NumFixedPoint(simTrancheCollateral.risk, decimals.tranche),
            NumFixedPoint(
                (simTrancheCollateral.safe *
                    (10**decimals.stable) +
                    stableBalance *
                    (10**decimals.tranche)),
                decimals.tranche + decimals.stable
            )
        );

        return data;
    }

    function viewCBBStatsMature(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataMature memory)
    {
        CollateralBalance memory simTrancheCollateral = calcTrancheCollateral(
            _convertibleBondBox,
            _convertibleBondBox.bond(),
            _convertibleBondBox.safeTranche().balanceOf(
                address(_convertibleBondBox)
            ),
            _convertibleBondBox.riskTranche().balanceOf(
                address(_convertibleBondBox)
            )
        );
        uint256 stableBalance = _convertibleBondBox.stableToken().balanceOf(
            address(_convertibleBondBox)
        );

        uint256 riskTrancheBalance = _convertibleBondBox
            .riskTranche()
            .balanceOf(address(_convertibleBondBox));

        uint256 zPenaltyTrancheCollateral = ((riskTrancheBalance -
            _convertibleBondBox.riskSlip().totalSupply()) *
            simTrancheCollateral.risk) / riskTrancheBalance;

        DecimalPair memory decimals = DecimalPair(
            ERC20(address(_convertibleBondBox.safeTranche())).decimals(),
            ERC20(address(_convertibleBondBox.stableToken())).decimals()
        );

        CBBDataMature memory data = CBBDataMature(
            NumFixedPoint(
                _convertibleBondBox.safeSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.s_repaidSafeSlips(),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.safeTranche().balanceOf(
                    address(_convertibleBondBox)
                ),
                decimals.tranche
            ),
            NumFixedPoint(
                _convertibleBondBox.riskSlip().totalSupply(),
                decimals.tranche
            ),
            NumFixedPoint(
                (riskTrancheBalance -
                    _convertibleBondBox.riskSlip().totalSupply()),
                decimals.tranche
            ),
            NumFixedPoint(stableBalance, decimals.stable),
            NumFixedPoint(simTrancheCollateral.safe, decimals.tranche),
            NumFixedPoint(
                (_convertibleBondBox.riskSlip().totalSupply() *
                    simTrancheCollateral.risk) / riskTrancheBalance,
                decimals.tranche
            ),
            NumFixedPoint(zPenaltyTrancheCollateral, decimals.tranche),
            NumFixedPoint(
                _convertibleBondBox.currentPrice(),
                _convertibleBondBox.s_priceGranularity()
            ),
            NumFixedPoint(
                simTrancheCollateral.risk - zPenaltyTrancheCollateral,
                decimals.tranche
            ),
            NumFixedPoint(
                (simTrancheCollateral.safe + zPenaltyTrancheCollateral) *
                    10**decimals.stable +
                    stableBalance *
                    10**decimals.tranche,
                decimals.stable + decimals.tranche
            )
        );

        return data;
    }

    function calcTrancheCollateral(
        IConvertibleBondBox convertibleBondBox,
        IBondController bond,
        uint256 safeTrancheAmount,
        uint256 riskTrancheAmount
    ) internal view returns (CollateralBalance memory) {
        uint256 riskTrancheCollateral = 0;
        uint256 safeTrancheCollateral = 0;

        uint256 collateralBalance = convertibleBondBox
            .collateralToken()
            .balanceOf(address(bond));

        if (collateralBalance > 0) {
            if (bond.isMature()) {
                riskTrancheCollateral = convertibleBondBox
                    .collateralToken()
                    .balanceOf(address(convertibleBondBox.riskTranche()));

                safeTrancheCollateral = convertibleBondBox
                    .collateralToken()
                    .balanceOf(address(convertibleBondBox.safeTranche()));
            } else {
                for (
                    uint256 i = 0;
                    i < bond.trancheCount() - 1 && collateralBalance > 0;
                    i++
                ) {
                    (ITranche tranche, ) = bond.tranches(i);
                    uint256 amount = Math.min(
                        tranche.totalSupply(),
                        collateralBalance
                    );
                    collateralBalance -= amount;

                    if (i == convertibleBondBox.trancheIndex()) {
                        safeTrancheCollateral = amount;
                    }
                }

                riskTrancheCollateral = collateralBalance;
            }

            safeTrancheCollateral =
                (safeTrancheCollateral * safeTrancheAmount) /
                convertibleBondBox.safeTranche().totalSupply();

            riskTrancheCollateral =
                (riskTrancheCollateral * riskTrancheAmount) /
                convertibleBondBox.riskTranche().totalSupply();
        }

        CollateralBalance memory collateral = CollateralBalance(
            safeTrancheCollateral,
            riskTrancheCollateral
        );

        return collateral;
    }

    function fetchElasticStack(IStagingBox _stagingBox)
        internal
        view
        returns (IConvertibleBondBox, IBondController)
    {
        IConvertibleBondBox convertibleBondBox = _stagingBox
            .convertibleBondBox();
        IBondController bond = convertibleBondBox.bond();
        return (convertibleBondBox, bond);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    function init(string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
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
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import "../interfaces/IStagingBox.sol";
import "../interfaces/IConvertibleBondBox.sol";

struct NumFixedPoint {
    uint256 value;
    uint256 decimals;
}

struct StagingDataIBO {
    NumFixedPoint lendSlipSupply;
    NumFixedPoint borrowSlipSupply;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct StagingDataActive {
    NumFixedPoint lendSlipSupply;
    NumFixedPoint borrowSlipSupply;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint safeSlipBalance;
    NumFixedPoint riskSlipBalance;
    NumFixedPoint stableTokenBalanceBorrow;
    NumFixedPoint stableTokenBalanceLend;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint safeSlipCollateral;
    NumFixedPoint riskSlipCollateral;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct CBBDataActive {
    NumFixedPoint safeSlipSupply;
    NumFixedPoint riskSlipSupply;
    NumFixedPoint repaidSafeSlips;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint currentPrice;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

struct CBBDataMature {
    NumFixedPoint safeSlipSupply;
    NumFixedPoint riskSlipSupply;
    NumFixedPoint repaidSafeSlips;
    NumFixedPoint safeTrancheBalance;
    NumFixedPoint riskTrancheBalance;
    NumFixedPoint zPenaltyTrancheBalance;
    NumFixedPoint stableTokenBalance;
    NumFixedPoint safeTrancheCollateral;
    NumFixedPoint riskTrancheCollateral;
    NumFixedPoint zPenaltyTrancheCollateral;
    NumFixedPoint currentPrice;
    NumFixedPoint tvlBorrow;
    NumFixedPoint tvlLend;
}

interface IConvertiblesDVLens {
    /**
     * @dev provides the stats for Staging Box in IBO period
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewStagingStatsIBO(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataIBO memory);

    /**
     * @dev provides the stats for StagingBox after the IBO is completed
     * @param _stagingBox The staging box tied to the Convertible Bond
     * Requirements:
     */

    function viewStagingStatsActive(IStagingBox _stagingBox)
        external
        view
        returns (StagingDataActive memory);

    /**
     * @dev provides the stats for CBB after IBO
     * @param _convertibleBondBox The CBB being queried
     * Requirements:
     */

    function viewCBBStatsActive(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataActive memory);

    /**
     * @dev provides the stats for CBB after maturity
     * @param _convertibleBondBox The CBB being queried
     * Requirements:
     */

    function viewCBBStatsMature(IConvertibleBondBox _convertibleBondBox)
        external
        view
        returns (CBBDataMature memory);
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