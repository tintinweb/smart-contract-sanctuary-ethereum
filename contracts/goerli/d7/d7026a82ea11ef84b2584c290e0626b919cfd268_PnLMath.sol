// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Percentage using BPS
// https://stackoverflow.com/questions/3730019/why-not-use-double-or-float-to-represent-currency/3730040#3730040

library FinMath {
    int256 public constant BPS = 10 ** 4; // basis points [TODO: move to 10**4]
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;
    uint256 constant LIMIT = 2 ** 255;

    int256 internal constant MAX_SD59x18 =
        57896044618658097711785492504343953926634992332820282019728792003956564819967;
    int256 internal constant MIN_SD59x18 =
        -57896044618658097711785492504343953926634992332820282019728792003956564819968;

    // @notice Calculate percentage using BPS precision
    // @param bps input in base points
    // @param x the number we want to calculate percentage
    // @return the % of the x including fixed-point arithimetic
    function bps(int256 bp, uint256 x) internal pure returns (int256) {
        require(x < 2 ** 255);
        int256 y = int256(x);
        require((y * bp) >= BPS);
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
        return int(res);
    }


    // @notice somethimes we need to print int but cast them to uint befor
    function inv(int x) internal pure returns(uint) {
        if(x < 0) return uint(-x);
        if(x >=0) return uint(x);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import '@dex/lib/Structs.sol';
import '@dex/lib/PnLMath.sol';
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library LeverageMath {
    using FinMath for uint256;
    using FinMath for int256;
    using PnLMath for Match;
    struct Data {
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

    function _min(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a <= b) ? a : b;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256 res) {
        res = (a >= b) ? a : b;
    }

    function isOverLeveraged(
        Match storage m,
        LeverageMath.Data storage leverage,
        PriceData calldata priceData,
        uint256 fmfr,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        Match memory _m = m;
        return isOverLeveraged_(_m, leverage, priceData, fmfr, isMaker, collateralDecimals);
    }

    function isOverLeveraged_(
        Match memory m,
        LeverageMath.Data storage leverage,
        PriceData calldata priceData,
        uint256 fmfr,
        bool isMaker,
        uint8 collateralDecimals
    ) public view returns (bool) {
        uint256 timeElapsed = m.start == 0 ? 0 : block.timestamp - m.start;
        return
            getLeverage(m, priceData, isMaker, 0, collateralDecimals) >=
            (
                isMaker
                    ? getMaxLeverage(
                        leverage,
                        m.frPerYear,
                        timeElapsed == 0
                            ? block.timestamp - priceData.timestamp
                            : timeElapsed,
                        fmfr
                    )
                    : timeElapsed == 0
                    ? leverage.maxLeverageOpen
                    : leverage.maxLeverageOngoing
            );
    }

    function getMaxLeverage(
        Data storage leverage,
        uint256 fr,
        uint256 timeElapsed,
        uint256 fmfr
    ) public view returns (uint256 maxLeverage) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);

        // NOTE: Expecting time elapsed in days
        timeElapsed = timeElapsed / 86400;
        maxLeverage = ((fr >= fmfr) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((leverage.s * leverage.FRTemporalBasis * leverage.b)
                        .bps() /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (fmfr - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

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
        uint256 notional = ((overrideAmount > 0) ? overrideAmount : m.amount) *
            ((isMaker && (m.trader == 0)) ? priceData.price : m.entryPrice);

        uint256 realizedPnL = m.accruedFR(priceData, collateralDecimals);
        uint256 collateral_plus_realizedPnL = (isMaker)
            ? m.collateralM + realizedPnL
            : m.collateralT - _min(m.collateralT, realizedPnL);
        if (collateral_plus_realizedPnL == 0) return type(uint256).max;

        // TODO: this is a simplification when removing the decimals lib,
        //       need to check and move to FinMath lib
        leverage = notional / (collateral_plus_realizedPnL * 10 ** 12);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import './Positions.sol';
import '@dex/lib/LeverageMath.sol';
import '@dex/lib/Structs.sol';
import '@dex/lib/FinMath.sol';
import {PriceData} from '@dex/oracles/interfaces/IOracle.sol';

library PnLMath {
    using FinMath for uint24;
    using FinMath for int256;
    using FinMath for uint256;




    // NOTE: Need to move this computation out of `pnl()` to avoid the stack too deep issue in it
    function _gl(uint256 amount, int256 dp, uint256 collateralDecimals) internal pure returns(int256 gl) {
        gl = int256(10**(collateralDecimals)).wmul(int256(amount)).wmul(dp);       // Maker's GL        
    }

    function pnl(
        Match storage m,
        uint256 tokenId,
        uint256 timestamp,
        uint256 exitPrice,
        uint256 makerFRFee,
        uint8 collateralDecimals
    ) public view returns (int pnlM, int pnlT, uint256 FRfee) {
        require(timestamp > m.start, "engine/wrong_timestamp");
        require(
            (tokenId == m.maker) || (tokenId == m.trader),
            'engine/invalid-tokenId'
        );
        // uint deltaT = timestamp.sub(m.start);
        // int deltaP = exitPrice.isub(m.entryPrice);
        // int delt = (m.pos == POS_SHORT) ? -deltaP : deltaP;

        // NOTE: FR is seen from the perspective of the maker and it is >= 0 always by construction
        uint256 aFR = _accruedFR(timestamp.sub(m.start), m.frPerYear, m.amount, exitPrice, collateralDecimals);

        // NOTE: `m.pos` is the Maker Position
        int mgl = (((m.pos == POS_SHORT) ? int(-1) : int(1)) * _gl(m.amount, exitPrice.isub(m.entryPrice), collateralDecimals));

        // NOTE: Before deducting FR Fees, the 2 PnLs need to be symmetrical
        pnlM = mgl + int256(aFR); 
        pnlT = -pnlM;

        // NOTE: After the FR fees, no more symmetry
        FRfee = makerFRfees(makerFRFee, aFR);
        pnlM -= int256(FRfee);
    }

    function makerFRfees(uint256 makerFRFee, uint256 fundingRate) internal pure returns (uint256) {
        return makerFRFee.bps(fundingRate);
    }


    function accruedFR(
        Match memory m,
        PriceData memory priceData,
        uint8 collateralDecimals
    ) public view returns (uint256) {
        if (m.start == 0) return 0;
        uint256 deltaT = block.timestamp.sub(m.start);
        return _accruedFR(deltaT, m.frPerYear, m.amount, priceData.price, collateralDecimals);
    }

    function _accruedFR(
        uint256 deltaT,
        uint256 frPerYear,
        uint256 amount,
        uint256 price,
        uint8 collateralDecimals
    ) public pure returns (uint256) {
        return
            (10**(collateralDecimals)).mul(frPerYear).bps(deltaT).wmul(amount).wmul(price) / (3600 * 24 * 365);
    }

    function isLiquidatable(
        Match storage m,
        uint256 tokenId,
        uint256 price,
        Config calldata config,
        uint8 collateralDecimals
    ) external view returns (bool) {
        // check if the match has not previously been deleted
        if (m.maker == 0) return false;
        if (tokenId == m.maker) {
            (int pnlM, , ) = pnl(m, tokenId, block.timestamp, price, 0, collateralDecimals); // TODO: add makerFee
            int256 bufferMaker = config.bufferMakerBps.ibps(m.collateralM);
            return int256(m.collateralM) + pnlM - bufferMaker < config.liqBuffM;
        } else if (tokenId == m.trader) {
            (, int pnlT,) = pnl(m, tokenId, block.timestamp, price, 0, collateralDecimals); // TODO: add maker fee
            int256 bufferTrader = config.bufferTraderBps.ibps(m.collateralT);
            return int256(m.collateralT) + pnlT - bufferTrader < config.liqBuffT;
        } else {
            return false;
        }
    }

}

pragma solidity ^0.8.17;

int8 constant POS_SHORT = -1;
int8 constant POS_NEUTRAL = 0;
int8 constant POS_LONG = 1;

pragma solidity ^0.8.17;

// TODO: add minPremiumFee
struct Config {
    uint24 fmfrPerYear; // 4 decimals (bips)
    uint24 frPerYearModulo; // 4 decimals (bips)
    uint24 minFRPerYear; // 4 decimals (bips)
    uint24 openInterestCap; // 4 decimals (bips)
    uint24 premiumFeeBps; // % of the premium that protocol collects
    uint24 traderFeeBps; // 4 decimals (bips)
    uint24 bufferTraderBps;
    uint24 bufferMakerBps;
    uint64 bufferTrader;
    uint64 bufferMaker;
    uint128 minMakerFee; // minimum fee protocol collects from maker
    uint128 minPremiumFee;
    uint128 orderMinAmount;
    int liqBuffM;
    int liqBuffT;
}

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