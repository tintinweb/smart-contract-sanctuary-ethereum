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

import '@dex/lib/SafeCast.sol';
// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040
// Ranges:
// int(x): -2^(x-1) to [2^(x-1)]-1
// uint(x): 0 to [2^(x)]-1

// @notice Simple multiplication with native overflow protection for uint when
// using solidity above 0.8.17.
library FinMath {
    using SafeCast for uint256;
    using SafeCast for int256;

    // Bps
    int256 public constant iBPS = 10**4; // basis points [TODO: move to 10**4]
    uint256 public constant uBPS = 10**4; // basis points [TODO: move to 10**4]

    // Fixed Point arithimetic
    uint256 constant WAD = 10**18;
    int256 constant iWAD = 10**18;
    uint256 constant LIMIT = 2**255;

    int256 internal constant iMAX_128 = 0x100000000000000000000000000000000; // 2^128
    int256 internal constant iMIN_128 = -0x100000000000000000000000000000000; // 2^128
    uint256 internal constant uMAX_128 = 0x100000000000000000000000000000000; // 2^128

    // --- SIGNED CAST FREE

    function mul(int256 x, int256 y) internal pure returns (int256 z) {
        z =  x * y;
    }
    function div(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a / b;
    }
    function sub(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a - b;
    }
    function add(int256 a, int256 b) internal pure returns (int256 z) {
        z =  a + b;
    }

    // --- UNSIGNED CAST FREE

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a / b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256 z) {
        z =  a - b;
    }

    // --- MIXED TYPES SAFE CAST

    function add(uint256 x, int256 y) internal pure returns (uint256 z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x - (-y).u256() : x + y.u256();
    }
    function add(int256 x, uint256 y) internal pure returns (int256 z) {
        z = x + y.i256();
    }
    function sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        bool flip = y < 0 ? true : false;
        z = flip ? x + (-y).u256() : x - y.u256();
    }
    function isub(uint256 x, uint256 y) internal pure returns (int256 z) {
        int256 x1 = x.i256();
        int256 y1 = y.i256();
        z = x1 - y1;
    }

    // --- FIXED POINT [1e18 precision]

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function wmul(int256 x, int256 y) internal pure returns (int256 z) {
        z = add(mul(x, y), int256(WAD) / 2) / iWAD;
    }
    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }


    // --- FIXED POINT BPS [1e4 precision]

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256 z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = (mul(x.i256(), bp)) / iBPS;
    }

    function bps(uint256 bp, uint256 x) internal pure returns (uint256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / uBPS;
    }

    function bps(uint256 bp, int256 x) internal pure returns (int256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = mul(x, bp.i256()) / iBPS;
    }

    function bps(int256 bp, int256 x) internal pure returns (int256 z) {
        require(bp < iMAX_128, 'bps-x-overflow');
        z = mul(x, bp) / iBPS;
    }

    function ibps(uint256 bp, uint256 x) internal pure returns (int256 z) {
        require(bp < uMAX_128, 'bps-x-overflow');
        z = (mul(x, bp) / uBPS).i256();
    }

    // @dev Transform to BPS precision
    function bps(uint256 x) internal pure returns (uint256) {
        return mul(x, uBPS);
    }

    // @notice Return the positive number of an int256 or zero if it was negative
    // @parame x the number we want to normalize
    // @return zero or a positive number
    function pos(int256 a) internal pure returns (uint256) {
        return (a >= 0) ? uint256(a) : 0;
    }

    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int256 x) internal pure returns (uint256 z) {
        z = x < 0 ? uint256(-x) : uint256(x);
    }


    // --- MINIMUM and MAXIMUM

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

}

// SPDX-License-Identifier: GPL-2.0-or-later
// Uniswap lib
pragma solidity 0.8.17;

// @title Safe casting methods
// @notice Contains methods for safely casting between types
library SafeCast {
    // @notice Cast a uint256 to a uint160, revert on overflow
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u160(uint256 y) internal pure returns (uint160 z) {
        require((z = uint160(y)) == y, 'cast-u160');
    }

    // @notice Cast a int256 to a int128, revert on overflow or underflow
    // @param y The int256 to be downcasted
    // @return z The downcasted integer, now type int128
    function i128(int256 y) internal pure returns (int128 z) {
        require((z = int128(y)) == y, 'cast-i128');
    }

    // @notice Cast a uint256 to a int256, revert on overflow
    // @param y The uint256 to be casted
    // @return z The casted integer, now type int256
    function i256(uint256 y) internal pure returns (int256 z) {
        require(y < 2**255, 'cast-i256');
        z = int256(y);
    }

    // @notice Cast an int256, check if it's not negative
    // @param y The uint256 to be downcasted
    // @return z The downcasted integer, now type uint160
    function u256(int256 y) internal pure returns (uint256 z) {
        require(y >= 0, 'cast-u256');
        z = uint256(y);
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
    bool close;  // A close request for this match is pending
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
    uint256 bufferTrader;
    uint256 bufferMaker;
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

    function bufferTrader() external view returns (uint256);

    function bufferMaker() external view returns (uint256);

    function getLeverage() external view returns (Leverage memory);

    function getBips() external view returns (Bips memory);

    function getAmounts() external view returns (Amounts memory);

    function setLeverage(Leverage calldata leverage) external;

    function setBips(Bips calldata) external;

    function setAmounts(Amounts calldata) external;

    function initialize(address owner) external;
}