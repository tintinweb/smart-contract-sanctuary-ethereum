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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';

import '@dex/perp/interfaces/IConfig.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint256;
    using FinMath for int256;
    using PnLMath for Match;

    // TODO: move min/max to be used from FinMath
    function _min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a >= b) ? a : b;
    }

    // @dev External function.
    function isOverLeveraged(
        Match storage m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        return
            isOverLeveraged_(m, priceData, config, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        PriceData calldata priceData,
        IConfig config,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Leverage memory leverage = config.getLeverage();
        uint256 timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >
            (
                isMaker
                    ? getMaxLeverage(
                        config,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    // @dev Internal function
    function getMaxLeverage(
        IConfig config,
        uint256 fr,
        uint256 timeElapsed
    ) public view returns (uint256 maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        Leverage memory leverage = config.getLeverage();
        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= config.fmfrPerYear()) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (config.fmfrPerYear() - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    // @dev Internal function
    // NOTE: For leverage, notional depends on entryPrice while accruedFR is transformed into collateral using currentPrice
    // Reasons
    // LP Pool risk is connected to Makers' Leverage
    // (even though we have a separate check for liquidation, we use leverage to control collateral withdrawal)
    // so higher leverage --> LP Pool risk increases
    // Makers' are implicitly always long market for the accruedFR component
    // NOTE: The `overrideAmount` is used in `join()` since we split after having done a bunch of checks so the `m.amount` is not the correct one in that case
    function getLeverage(
        Match memory m,
        PriceData calldata priceData,
        bool isMaker,
        uint256 overrideAmount,
        uint8 collateralDecimals
    ) public view returns (uint256 leverage) {
        // NOTE: This is correct almost always with the exception of the levarge computation
        // for the maker when they submit an order which is not picked yet and
        // as a consquence we to do not have an entryPrice yet so we use currentPrice
        uint256 notional = (10**(collateralDecimals))
            .wmul((overrideAmount > 0) ? overrideAmount : m.amount)
            .wmul(
                (isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice
            );
        uint256 realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint256 collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint256).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional.bps() / collateral_plus_realizedPnL;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/perp/interfaces/IConfig.sol';
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int256;
    using FinMath for uint256;

    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(
        uint256 amount,
        int256 dp,
        uint256 collateralDecimals
    ) internal pure returns (int256 gl) {
        gl = int256(10**(collateralDecimals)).wmul(int256(amount)).wmul(dp); // Maker's GL
    }

    function pnl(
        Match memory m,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice,
        uint256 makerFRFee,
        uint8 collateralDecimals
    )
        public
        pure
        returns (
            int256 pnlM,
            int256 pnlT,
            uint256 FRfee
        )
    {
        require(timestamp > m.start, 'engine/wrong_timestamp');
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint256 aFR = _accruedFR(
            timestamp.sub(m.start),
            m.frPerYear,
            m.amount,
            exitPrice,
            collateralDecimals
        );

        // NOTE: `m.pos` is the Maker Position
        int256 mgl = (((m.pos == POS_SHORT) ? int256(-1) : int256(1)) *
            _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int256(aFR);
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int256(FRfee);
    }

    function makerFRfees(uint256 makerFRFee, uint256 fundingRate)
        internal
        pure
        returns (uint256)
    {
        return makerFRFee.bps(fundingRate);
    }

    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint256) {
        if (m.start == 0) return 0;
        uint256 deltaT = block.timestamp.sub(m.start);
        return
            _accruedFR(
                deltaT,
                m.frPerYear,
                m.amount,
                priceData.price,
                collateralDecimals
            );
    }

    function _accruedFR(
        uint256 deltaT,
        uint256 frPerYear,
        uint256 amount,
        uint256 price,
        uint8 collateralDecimals
    ) public pure returns (uint256) {
        return
            (10**(collateralDecimals))
                .mul(frPerYear)
                .bps(deltaT)
                .wmul(amount)
                .wmul(price) / (3600 * 24 * 365);
    }

    // TODO: move return value to a threshold numerical one and add the threshold on config
    function isLiquidatable(
        Match storage m,
        uint256 tokenId,
        uint256 price,
        IConfig config,
        uint8 collateralDecimals
    ) external view returns (bool) {
        // check if the match has not previously been deleted
        if (m.maker == 0) return false;
        if (tokenId == m.maker) {
            (int256 pnlM, , ) = pnl(
                m,
                tokenId,
                block.timestamp,
                price,
                0,
                collateralDecimals
            ); // TODO: add makerFee
            int256 bufferMaker = config.bufferMakerBps().ibps(m.collateralM);
            return
                int256(m.collateralM) + pnlM - bufferMaker <
                int256(config.bufferMaker());
        } else if (tokenId == m.trader) {
            (, int256 pnlT, ) = pnl(
                m,
                tokenId,
                block.timestamp,
                price,
                0,
                collateralDecimals
            ); // TODO: add maker fee
            int256 bufferTrader = config.bufferTraderBps().ibps(m.collateralT);
            return
                int256(m.collateralT) + pnlT - bufferTrader <
                int256(config.bufferTrader());
        } else {
            return false;
        }
    }
}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

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