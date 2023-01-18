// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';

import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library FeesMath {
    using FinMath for uint256;
    using FinMath for uint24;
    using FinMath for int24;

    // @dev External function used in engine
    function computePremiumAndFee(
        Order storage o,
        PriceData memory p,
        int24 premiumBps,
        IConfig config,
        uint8 minPremiumFeeDiscountPerc
    ) public view returns (int256 premium, uint256 premiumFee) {
        uint256 notional = o.amount.wmul(p.price);
        premium = premiumBps.bps(notional);
        int256 fee = config.premiumFeeBps().bps(premium);
        int256 _minPremiumFee = int256(
            (config.getAmounts().minPremiumFee *
                uint256((minPremiumFeeDiscountPerc))) / 100
        );
        premiumFee = uint256((fee > _minPremiumFee) ? fee : _minPremiumFee);
    }

    // @dev External function used in engine.
    function traderFees(
        Order storage o,
        PriceData memory p,
        IConfig config
    ) external view returns (uint256) {
        uint256 notional = o.amount.wmul(p.price);
        int256 fee = config.traderFeeBps().bps(int256(notional));
        return uint256(fee);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040

library FinMath {
    int256 public constant BPS = 10**4; // basis points [TODO: move to 10**4]
    uint256 constant WAD = 10**18;
    uint256 constant RAY = 10**27;
    uint256 constant LIMIT = 2**255;

    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728792003956564819967;
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256) {
        require(x < 2**255);
        int256 y = int256(x);
        return (y * bp) / BPS;
    }

    function bps(uint256 bp, uint256 x) internal pure returns (uint256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return res;
    }

    function bps(uint256 bp, int256 x) internal pure returns (int256) {
        require(bp < LIMIT); // cast overflow check
        return bps(int256(bp), x);
    }

    function bps(int256 bp, int256 x) internal pure returns (int256) {
        return (x * bp) / BPS;
    }

    function ibps(uint256 bp, uint256 x) internal pure returns (int256) {
        uint256 UBPS = uint256(BPS);
        uint256 res = (x * bp) / UBPS;
        require(res < LIMIT); // cast overflow check
        return int256(res);
    }

    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int256 x) internal pure returns (uint256) {
        if (x < 0) return uint256(-x);
        if (x >= 0) return uint256(x);
    }

    // function bps(uint64 bp, uint256 x) internal pure returns (uint256) {
    //     return (x * bp) / uint256(BPS);
    // }

    // @notice Bring the number up to the BPS decimal format for further calculations
    // @param x number to convert
    // @return value in BPS case
    function bps(uint256 x) internal pure returns (uint256) {
        return mul(x, uint256(BPS));
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int256 a) internal pure returns (uint256) {
        return (a >= 0) ? uint256(a) : 0;
    }

    // @param x The multiplicand as a signed 59.18-decimal fixed-point number.
    // @param y The multiplier as a signed 59.18-decimal fixed-point number.
    // @return result The result as a signed 59.18-decimal fixed-point number.
    // https://github.com/paulrberg/prb-math/blob/v1.0.3/contracts/PRBMathCommon.sol - license WTFPL
    function mul(int256 x, int256 y) internal pure returns (int256 result) {
        require(x > MIN_SD59x18);
        require(y > MIN_SD59x18);

        unchecked {
            uint256 ax;
            uint256 ay;
            ax = x < 0 ? uint256(-x) : uint256(x);
            ay = y < 0 ? uint256(-y) : uint256(y);

            uint256 resultUnsigned = mul(ax, ay);
            require(resultUnsigned <= uint256(MAX_SD59x18));

            uint256 sx;
            uint256 sy;
            assembly {
                sx := sgt(x, sub(0, 1))
                sy := sgt(y, sub(0, 1))
            }
            result = sx ^ sy == 1
                ? -int256(resultUnsigned)
                : int256(resultUnsigned);
        }
    }

    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x, 'fin-math-add-overflow');
    }

    function isub(uint256 x, uint256 y) internal pure returns (int256 z) {
        require(x < LIMIT && y < LIMIT, 'fin-math-cast-overflow');
        return int256(x) - int256(y);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, 'fin-math-sub-underflow');
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, 'fin-math-mul-overflow');
    }

    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x, 'fin-math-iadd-overflow');
        require(y <= 0 || z >= x, 'fin-math-iadd-overflow');
    }

    function add(int256 x, uint256 y) internal pure returns (int256 z) {
        require(y < LIMIT, 'fin-math-cast-overflow');
        z = x + int256(y);
        // require(y >= 0 || z <= x, "fin-math-iadd-overflow");
        // require(y <= 0 || z >= x, "fin-math-iadd-overflow");
    }

    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x >= y ? x : y;
    }

    function imin(int256 x, int256 y) internal pure returns (int256 z) {
        return x <= y ? x : y;
    }

    function imax(int256 x, int256 y) internal pure returns (int256 z) {
        return x >= y ? x : y;
    }

    //@dev rounds to zero if x*y < WAD / 2
    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    //@notice Multiply two Wads and return a new Wad with the correct level
    // of precision. A Wad is a decimal number with 18 digits of precision
    // that is being represented as an integer.
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = add(mul(x, y), int256(WAD) / 2) / int256(WAD);
    }

    //rounds to zero if x*y < WAD / 2
    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    //@notice Divide two Wads and return a new Wad with the correct level of precision.
    //@dev rounds to zero if x*y < WAD / 2
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    //rounds to zero if x*y < RAY / 2
    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint256 x, uint256 n) internal pure returns (uint256 z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

pragma solidity ^0.8.17;

struct Match {
    int8 pos; // If maker is short = true
    int24 premiumBps; // In percent of the amount
    uint24 frPerYear;
    uint24 fmfrPerYear; // The fair market funding rate when the match was done
    uint256 maker; // maker vault token-id
    uint256 trader; // trader vault token-id
    uint256 amount;
    uint256 start; // timestamp of the match starting
    uint256 entryPrice;
    uint256 collateralM; // Maker  collateral
    uint256 collateralT; // Trader collateral
    uint8 minPremiumFeeDiscountPerc;    // To track what perc of minPreomiumFee to pay, used when the order is split
}

struct Order {
    bool canceled;
    int8 pos;
    address owner; // trader address
    uint256 tokenId;
    uint256 matchId; // trader selected matchid
    uint256 amount;
    uint256 collateral;
    uint256 collateralAdd;
    // NOTE: Used to apply the check for the Oracle Latency Protection
    uint256 timestamp;
    // NOTE: In this case, we give trader the max full control on the price for matching: no assumption it is symmetric and we do not compute any percentage so introducing some approximations, the trader writes the desired prices
    uint256 slippageMinPrice;
    uint256 slippageMaxPrice;
    uint256 maxTimestamp;
}

struct CloseOrder {
    uint256 matchId;
    uint256 timestamp;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

struct PriceData {
    // wad
    uint256 price;
    uint256 timestamp;
}

interface IOracle {
    event NewValue(uint256 value, uint256 timestamp);

    function setPrice(uint256 _value) external;

    function decimals() external view returns (uint8);

    function getPrice() external view returns (PriceData memory);
}

pragma solidity ^0.8.17;

struct Bips {
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 makerFRFeeBps; // 4 decimals (bips)
}

struct Amounts {
    uint64 bufferTrader;
    uint64 bufferMaker;
    uint128 minPremiumFee;
    uint128 orderMinAmount;
}

struct Leverage {
    // NOTE: Like in PerpV2, we have 2 max leverages: one for when the position is opened and the other for the position ongoing
    uint24 maxLeverageOpen;
    uint24 maxLeverageOngoing;
    uint24 minGuaranteedLeverage;
    uint256 s;
    uint256 b;
    uint256 f0;
    // NOTE: Example 180 days
    uint256 maxTimeGuarantee;
    // NOTE: In case the above is measured in days then it is 365 days
    uint256 FRTemporalBasis;
    // NOTE: Fair Market FR
    // NOTE: Atm we do not support negative FR
}

interface IConfig {
    function fmfrPerYear() external view returns (uint24);

    function premiumFeeBps() external view returns (uint24);

    function openInterestCap() external view returns (uint24);

    function frPerYearModulo() external view returns (uint24);

    function minFRPerYear() external view returns (uint24);

    function traderFeeBps() external view returns (uint24);

    function bufferTraderBps() external view returns (uint24);

    function bufferMakerBps() external view returns (uint24);

    function makerFRFeeBps() external view returns (uint24);

    function bufferTrader() external view returns (uint64);

    function bufferMaker() external view returns (uint64);

    function getLeverage() external view returns (Leverage memory);

    function getBips() external view returns (Bips memory);

    function getAmounts() external view returns (Amounts memory);

    function setLeverage(Leverage calldata leverage) external;

    function setBips(Bips calldata) external;

    function setAmounts(Amounts calldata) external;

    function initialize(address owner) external;
}