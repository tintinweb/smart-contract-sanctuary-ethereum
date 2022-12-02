// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;


struct Decimals {
    uint8 amount;
    uint8 premium;
    uint8 fr;
    uint8 feesPerc;
    uint8 oracle;
    uint8 collateral;
    uint8 leverage;
}

pragma solidity ^0.8.15;

import "./Decimals.sol";

library LeverageMath {
    struct Data {
        // NOTE: Like in PerpV2, we have 2 max leverages: one for when the position is opened and the other for the position ongoing
        uint256 maxLeverageOpen;
        uint256 maxLeverageOngoing;
        uint256 minGuaranteedLeverage;
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

    function getMaxLeverage(
        Data storage leverage,
        uint256 fr,
        uint256 timeElapsed,
        uint256 fmfr,
        Decimals memory decimals
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
                    ((10**(decimals.leverage) *
                        leverage.s *
                        leverage.FRTemporalBasis *
                        leverage.b) /
                        ((leverage.maxTimeGuarantee - timeElapsed) *
                            (fmfr - fr + leverage.f0))),
                    leverage.minGuaranteedLeverage
                ),
                leverage.maxLeverageOpen
            );
        // maxLeverage = (fr >= fmfr) ? type(uint256).max : (minRequiredMargin * timeToExpiry / (totTime * (fmfr - fr)));
    }

    function getLeverage(
        uint256 amount,
        uint256 collateral,
        uint256 currentPrice,
        int256 realizedPnL,
        Decimals memory decimals
    ) external pure returns (uint256 leverage) {
        uint256 collateral_plus_realizedPnL;
        if (realizedPnL >= 0) {
            collateral_plus_realizedPnL = collateral + uint256(realizedPnL);
        } else {
            if (uint256(-realizedPnL) >= collateral) return type(uint256).max;
            collateral_plus_realizedPnL = collateral - uint256(-realizedPnL);
        }
        if (collateral_plus_realizedPnL == 0) return type(uint256).max;

        int8 exp = int8(decimals.amount) +
            int8(decimals.oracle) -
            int8(decimals.collateral) -
            int8(decimals.leverage);
        if (exp >= 0) {
            leverage =
                (amount * currentPrice) /
                ((collateral_plus_realizedPnL) * 10**(uint8(exp)));
        } else {
            leverage =
                (amount * currentPrice * 10**(uint8(-exp))) /
                (collateral_plus_realizedPnL);
        }
    }
}