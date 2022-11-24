// SPDX-License-Identifier: AGPL-3.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/math/Math.sol";

import {IERC20, BaseStrategy} from "BaseStrategy.sol";
import "interfaces/IVault.sol";
import {Comet, CometStructs, CometRewards} from "interfaces/CompoundV3.sol";

contract Strategy is BaseStrategy {
    // TODO: add rewards
    Comet public immutable cToken;
    uint256 private SECONDS_PER_YEAR = 365 days;

    constructor(
        address _vault,
        string memory _name,
        Comet _cToken
    ) BaseStrategy(_vault, _name) {
        cToken = _cToken;
        require(cToken.baseToken() == IVault(vault).asset());
    }

    function _maxWithdraw(
        address owner
    ) internal view override returns (uint256) {
        // TODO: may not be accurate due to unaccrued balance in cToken
        return
            Math.min(IERC20(asset).balanceOf(address(cToken)), _totalAssets());
    }

    function _freeFunds(
        uint256 _amount
    ) internal returns (uint256 _amountFreed) {
        uint256 _idleAmount = balanceOfAsset();
        if (_amount <= _idleAmount) {
            // we have enough idle assets for the vault to take
            _amountFreed = _amount;
        } else {
            // NOTE: we need the balance updated
            cToken.accrueAccount(address(this));
            // We need to take from Aave enough to reach _amount
            // Balance of
            // We run with 'unchecked' as we are safe from underflow
            unchecked {
                _withdrawFromComet(
                    Math.min(_amount - _idleAmount, balanceOfCToken())
                );
            }
            _amountFreed = balanceOfAsset();
        }
    }

    function _withdraw(
        uint256 amount,
        address receiver,
        address owner
    ) internal override returns (uint256) {
        return _freeFunds(amount);
    }

    function _totalAssets() internal view override returns (uint256) {
        return balanceOfAsset() + balanceOfCToken();
    }

    function _invest() internal override {
        uint256 _availableToInvest = balanceOfAsset();
        _depositToComet(_availableToInvest);
    }

    function _withdrawFromComet(uint256 _amount) internal {
        cToken.withdraw(address(asset), _amount);
    }

    function _depositToComet(uint256 _amount) internal {
        Comet _cToken = cToken;
        _checkAllowance(address(_cToken), asset, _amount);
        _cToken.supply(address(asset), _amount);
    }

    function _checkAllowance(
        address _contract,
        address _token,
        uint256 _amount
    ) internal {
        if (IERC20(_token).allowance(address(this), _contract) < _amount) {
            IERC20(_token).approve(_contract, 0);
            IERC20(_token).approve(_contract, _amount);
        }
    }

    function balanceOfCToken() internal view returns (uint256) {
        return IERC20(cToken).balanceOf(address(this));
    }

    function balanceOfAsset() internal view returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
    }

    function aprAfterDebtChange(int256 delta) external view returns (uint256) {
        uint256 borrows = cToken.totalBorrow();
        uint256 supply = cToken.totalSupply();

        uint256 newUtilization = (borrows * 1e18) /
            uint256(int256(supply) + delta);
        uint256 newSupplyRate = cToken.getSupplyRate(newUtilization) *
            SECONDS_PER_YEAR;
        return newSupplyRate;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.14;

interface IVault {
    struct StrategyParams {
        uint256 activation;
        uint256 last_report;
        uint256 current_debt;
        uint256 max_debt;
    }

    function asset() external view returns (address _asset);

    function decimals() external view returns (uint256);

    // HashMap that records all the strategies that are allowed to receive assets from the vault
    function strategies(
        address _strategy
    ) external view returns (StrategyParams memory _params);

    // Current assets held in the vault contract. Replacing balanceOf(this) to avoid price_per_share manipulation
    function total_idle() external view returns (uint256);

    function update_debt(
        address strategy,
        uint256 target_debt
    ) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity 0.8.14;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IVault.sol";

abstract contract BaseStrategy {
    address public vault;
    address public immutable asset;
    string public name;

    constructor(address _vault, string memory _name) {
        vault = _vault;
        name = _name;
        asset = IVault(vault).asset();
    }

    function maxDeposit(
        address receiver
    ) public view virtual returns (uint256 maxAssets) {
        maxAssets = type(uint256).max;
    }

    function convertToAssets(uint256 shares) public view returns (uint256) {
        // 1:1
        return shares;
    }

    function convertToShares(uint256 assets) public view returns (uint256) {
        // 1:1
        return assets;
    }

    function totalAssets() public view returns (uint256) {
        return _totalAssets();
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (owner == vault) {
            return _totalAssets();
        }
        return 0;
    }

    function deposit(
        uint256 assets,
        address receiver
    ) public returns (uint256) {
        require(msg.sender == vault && msg.sender == receiver, "not owner");

        // transfer and invest
        IERC20(asset).transferFrom(vault, address(this), assets);
        _invest();
        return assets;
    }

    function maxWithdraw(address owner) public view returns (uint256) {
        return _maxWithdraw(owner);
    }

    function _maxWithdraw(
        address owner
    ) internal view virtual returns (uint256 withdraw_amount) {}

    function withdraw(
        uint256 amount,
        address receiver,
        address owner
    ) public returns (uint256) {
        require(msg.sender == vault && msg.sender == receiver, "not owner");
        require(amount <= maxWithdraw(vault), "withdraw more than max");

        uint256 amount_withdrawn = _withdraw(amount, receiver, owner);
        IERC20(asset).transfer(receiver, amount_withdrawn);
        return amount_withdrawn;
    }

    function _withdraw(
        uint256 amount,
        address receiver,
        address owner
    ) internal virtual returns (uint256 withdraw_amount) {}

    function _invest() internal virtual {}

    function _totalAssets() internal view virtual returns (uint256) {
        return IERC20(asset).balanceOf(address(this));
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
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    function getAssetInfoByAddress(
        address asset
    ) external view returns (CometStructs.AssetInfo memory);

    function getAssetInfo(
        uint8 i
    ) external view returns (CometStructs.AssetInfo memory);

    function borrowBalanceOf(address account) external view returns (uint256);

    function getPrice(address priceFeed) external view returns (uint128);

    function userBasic(
        address
    ) external view returns (CometStructs.UserBasic memory);

    function totalsBasic()
        external
        view
        returns (CometStructs.TotalsBasic memory);

    function userCollateral(
        address,
        address
    ) external view returns (CometStructs.UserCollateral memory);

    function baseTokenPriceFeed() external view returns (address);

    function numAssets() external view returns (uint8);

    function getUtilization() external view returns (uint);

    function baseTrackingSupplySpeed() external view returns (uint);

    function baseTrackingBorrowSpeed() external view returns (uint);

    function totalSupply() external view override returns (uint256);

    function totalBorrow() external view returns (uint256);

    function baseIndexScale() external pure returns (uint64);

    function baseTrackingAccrued(
        address account
    ) external view returns (uint64);

    function totalsCollateral(
        address asset
    ) external view returns (CometStructs.TotalsCollateral memory);

    function baseMinForRewards() external view returns (uint256);

    function baseToken() external view returns (address);

    function accrueAccount(address account) external;

    function isLiquidatable(address _address) external view returns (bool);

    function baseBorrowMin() external view returns (uint256);
}

interface CometRewards {
    function getRewardOwed(
        address comet,
        address account
    ) external returns (CometStructs.RewardOwed memory);

    function claim(address comet, address src, bool shouldAccrue) external;

    function rewardsClaimed(
        address comet,
        address account
    ) external view returns (uint256);

    function rewardConfig(
        address comet
    ) external view returns (CometStructs.RewardConfig memory);
}