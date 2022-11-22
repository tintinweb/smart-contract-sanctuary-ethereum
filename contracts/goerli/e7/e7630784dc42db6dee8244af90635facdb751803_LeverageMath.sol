pragma solidity ^0.8.15;

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
        uint256 fmfr
    ) public view returns (uint256 maxLeverage_1e6) {
        // console.log("[_getMaxLeverage()] fr >= fmfr --> ", fr >= fmfr);
        // console.log("[_getMaxLeverage()] timeElapsed >= leverage.maxTimeGuarantee --> ", timeElapsed >= leverage.maxTimeGuarantee);
        maxLeverage_1e6 = ((fr >= fmfr) ||
            (timeElapsed >= leverage.maxTimeGuarantee))
            ? (timeElapsed == 0)
                ? leverage.maxLeverageOpen
                : leverage.maxLeverageOngoing
            : _min(
                _max(
                    ((1e6 *
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
        int256 unrealizedPnL,
        uint256 currentPrice
    ) external pure returns (uint256 leverage_1e6) {
        int256 _deltaCollateral = int256(collateral) + unrealizedPnL;
        if (_deltaCollateral <= 0) {
            // NOTE: Leverage of zero is impossible so it is used as spcial value meaning all the collateral is virtually gone atm
            // NOTE: It is virtually gone since this is unrealizedPnL
            return 0;
        }
        leverage_1e6 = (amount * currentPrice * 1e6) / (collateral * 1e18);
    }
}