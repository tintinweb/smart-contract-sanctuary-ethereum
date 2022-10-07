/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Sun.sol";
import "../../../interfaces/IOracle.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibIncentive.sol";

/**
 * @title Season holds the sunrise function and handles all logic for Season changes.
 **/
contract SeasonFacet is Sun {
    using Decimal for Decimal.D256;

    event Sunrise(uint256 indexed season);
    event Incentivization(address indexed account, uint256 topcorns, uint256 incentive, uint256 feeInBnb);
    event SeasonSnapshot(uint32 indexed season, uint256 price, uint256 supply, uint256 stalk, uint256 seeds, uint256 podIndex, uint256 harvestableIndex, uint256 totalLiquidityUSD);

    /**
     * Sunrise
     **/

    function sunrise() external {
        require(!paused(), "Season: Paused.");
        require(seasonTime() > season(), "Season: Still current Season.");

        (Decimal.D256 memory topcornPrice, Decimal.D256 memory busdPrice) = IOracle(address(this)).capture();
        uint256 price = topcornPrice.mul(1e18).div(busdPrice).asUint256();

        (uint256 bnbReserve, uint256 topcornsReserve) = reserves();
        uint256 priceBNB = (Decimal.from(1).div(busdPrice)).mul(1e18).asUint256();
        uint256 _totalLiquidityUSD = (topcornsReserve * price + bnbReserve * priceBNB) / 1e18;
        stepSeason();
        decrementWithdrawSeasons();
        snapshotSeason(price, _totalLiquidityUSD);
        stepWeather(price, s.f.soil);
        uint256 increase = stepSun(topcornPrice, busdPrice);
        stepSilo(increase);
        incentivize(msg.sender);

        LibCheck.balanceCheck();

        emit Sunrise(season());
    }

    function stepSeason() private {
        s.season.current += 1;
    }

    function decrementWithdrawSeasons() internal {
        uint256 withdrawSeasons = s.season.withdrawSeasons;
        if ((withdrawSeasons > 13 && s.season.current % 84 == 0) || (withdrawSeasons > 5 && s.season.current % 168 == 0)) {
            s.season.withdrawSeasons -= 1;
        }
    }

    function snapshotSeason(uint256 price, uint256 _totalLiquidityUSD) private {
        s.season.timestamp = block.timestamp;
        emit SeasonSnapshot(s.season.current, price, topcorn().totalSupply(), s.s.stalk, s.s.seeds, s.f.pods, s.f.harvestable, _totalLiquidityUSD);
    }

    function incentivize(address account) private {
        uint256 rewardMultiplier = s.season.rewardMultiplier;
        if (rewardMultiplier > 100) rewardMultiplier = 100;
        uint256 incentive = LibIncentive.fracExp(rewardMultiplier * 1e18, 100, incentiveTime(), 1); // calculation incentive for sunrise
        uint256 feeInBnb = (tx.gasprice) * (s.season.costSunrice); // calculation Transaction Fee (in bnb)
        uint256 amount = 1e17;
        mintToAccount(account, amount);
        emit Incentivization(account, amount, incentive, feeInBnb);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Weather.sol";
import "../../../libraries/LibMath.sol";

/**
 * @title Sun
 **/
contract Sun is Weather {
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed season, uint256 price, uint256 newHarvestable, uint256 newSilo, int256 newSoil);
    event SupplyDecrease(uint256 indexed season, uint256 price, int256 newSoil);
    event SupplyNeutral(uint256 indexed season, int256 newSoil);

    /**
     * Internal
     **/

    // Sun

    function stepSun(Decimal.D256 memory topcornPrice, Decimal.D256 memory busdPrice) internal returns (uint256) {
        (uint256 bnb_reserve, uint256 topcorn_reserve) = lockedReserves();

        uint256 currentTopcorns = LibMath.sqrt((topcorn_reserve * (bnb_reserve) * 1e18) / (topcornPrice.mul(1e18).asUint256()));
        uint256 targetTopcorns = LibMath.sqrt((topcorn_reserve * (bnb_reserve) * 1e18) / (busdPrice.mul(1e18).asUint256()));

        uint256 price = topcornPrice.mul(1e18).div(busdPrice).asUint256();
        uint256 newSilo;

        if (currentTopcorns < targetTopcorns) {
            // > 1$
            newSilo = growSupply(targetTopcorns - currentTopcorns, price);
        } else if (currentTopcorns > targetTopcorns) {
            // < 1$
            shrinkSupply(currentTopcorns - targetTopcorns, price);
        } else {
            // == 1$
            int256 newSoil = setSoil(0);
            emit SupplyNeutral(season(), newSoil);
        }
        s.w.startSoil = s.f.soil;
        return newSilo;
    }

    function shrinkSupply(uint256 topcorns, uint256 price) private {
        int256 newSoil = setSoil(topcorns);
        emit SupplyDecrease(season(), price, newSoil);
    }

    function growSupply(uint256 topcorns, uint256 price) private returns (uint256) {
        (uint256 newHarvestable, uint256 newSilo) = increaseSupply(topcorns);
        int256 newSoil = setSoil(getMinSoil(newHarvestable));
        emit SupplyIncrease(season(), price, newHarvestable, newSilo, newSoil);
        return newSilo;
    }

    // (BNB, topcorns)
    function lockedReserves() public view returns (uint256, uint256) {
        (uint256 bnbReserve, uint256 topcornReserve) = reserves();
        uint256 lp = pair().totalSupply();
        if (lp == 0) return (0, 0);
        uint256 lockedLP = s.lp.deposited + s.lp.withdrawn;
        bnbReserve = (bnbReserve * lockedLP) / lp;
        topcornReserve = (topcornReserve * lockedLP) / lp;
        return (bnbReserve, topcornReserve);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../libraries/Decimal.sol";

/**
 * @title Oracle Interface
 **/
interface IOracle {
    function capture() external returns (Decimal.D256 memory, Decimal.D256 memory);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakePair.sol";
import "./LibAppStorage.sol";
import "../interfaces/ITopcorn.sol";

/**
 * @title Check Library verifies Farmer's balances are correct.
 **/
library LibCheck {
    function topcornBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(ITopcorn(s.c.topcorn).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.topcorn.deposited + s.topcorn.withdrawn, "Check: TopCorn balance fail.");
    }

    function lpBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }

    function balanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(ITopcorn(s.c.topcorn).balanceOf(address(this)) >= s.f.harvestable - s.f.harvested + s.topcorn.deposited + s.topcorn.withdrawn, "Check: TopCorn balance fail.");
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited + s.lp.withdrawn, "Check: LP balance fail.");
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

/**
 * @title Incentive Library calculates the exponential incentive rewards efficiently.
 **/
library LibIncentive {
    /// @notice fracExp estimates an exponential expression in the form: k * (1 + 1/q) ^ N.
    /// We use a binomial expansion to estimate the exponent to avoid running into integer overflow issues.
    /// @param k - the principle amount
    /// @param q - the base of the fraction being exponentiated
    /// @param n - the exponent
    /// @param x - the excess # of times to run the iteration.
    /// @return s - the solution to the exponential equation
    function fracExp(
        uint256 k,
        uint256 q,
        uint256 n,
        uint256 x
    ) internal pure returns (uint256 s) {
        // The upper bound in which the binomial expansion is expected to converge
        // Upon testing with a limit of n <= 300, x = 2, k = 100, q = 100 (parameters Farmer currently uses)
        // we found this p optimizes for gas and error
        uint256 p = log_two(n) + 1 + (x * n) / q;
        // Solution for binomial expansion in Solidity.
        // Motivation: https://ethereum.stackexchange.com/questions/10425
        uint256 N = 1;
        uint256 B = 1;
        for (uint256 i; i < p; ++i) {
            s += (k * N) / B / (q**i);
            N = N * (n - i);
            B = B * (i + 1);
        }
    }

    /// @notice log_two calculates the log2 solution in a gas efficient manner
    /// Motivation: https://ethereum.stackexchange.com/questions/8086
    /// @param x - the base to calculate log2 of
    function log_two(uint256 x) private pure returns (uint256 y) {
        assembly {
            let arg := x
            x := sub(x, 1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m, 0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m, 0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m, 0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m, 0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m, 0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m, 0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m, 0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m, 0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m, sub(255, a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../libraries/Decimal.sol";
import "../../../libraries/LibMarket.sol";
import "../../../libraries/LibMath.sol";
import "./Silo.sol";

/**
 * @title Weather
 **/
contract Weather is Silo {
    using Decimal for Decimal.D256;

    event WeatherChange(uint256 indexed season, uint256 caseId, int8 change, uint32 currentYield);
    event SeasonOfPlenty(uint256 indexed season, uint256 bnb, uint256 harvestable);
    event PodRateSnapshot(uint256 indexed season, uint256 podRate);

    /**
     * Getters
     **/

    // Weather

    function weather() external view returns (Storage.Weather memory) {
        return s.w;
    }

    function rain() external view returns (Storage.Rain memory) {
        return s.r;
    }

    function yield() public view returns (uint32) {
        return s.w.yield;
    }

    // Reserves

    // (BNB, topcorns)
    function reserves() public view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair().getReserves();
        return s.index == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    // (BNB, BUSD)
    function pegReserves() public view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pegPair().getReserves();
        return s.pegIndex == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    /**
     * Internal
     **/

    function stepWeather(uint256 int_price, uint256 endSoil) internal {
        if (topcorn().totalSupply() == 0) {
            s.w.yield = 1;
            return;
        }

        // Calculate Pod Rate
        Decimal.D256 memory podRate = Decimal.ratio(s.f.pods - s.f.harvestable, topcorn().totalSupply());

        // Calculate Delta Soil Demand
        uint256 dsoil = s.w.startSoil - endSoil;

        Decimal.D256 memory deltaPodDemand;

        // If Sow'd all Soil
        if (s.w.nextSowTime < type(uint32).max) {
            if (
                s.w.lastSowTime == type(uint32).max || // Didn't Sow all last Season
                s.w.nextSowTime < 300 || // Sow'd all instantly this Season
                (s.w.lastSowTime > C.getSteadySowTime() && s.w.nextSowTime < s.w.lastSowTime - C.getSteadySowTime()) // Sow'd all faster
            ) deltaPodDemand = Decimal.from(1e18);
            else if (s.w.nextSowTime <= s.w.lastSowTime + C.getSteadySowTime())
                // Sow'd all in same time
                deltaPodDemand = Decimal.one();
            else deltaPodDemand = Decimal.zero();
            s.w.lastSowTime = s.w.nextSowTime;
            s.w.nextSowTime = type(uint32).max;
            // If soil didn't sell out
        } else {
            uint256 lastDSoil = s.w.lastDSoil;
            if (dsoil == 0)
                deltaPodDemand = Decimal.zero(); // If no one sow'd
            else if (lastDSoil == 0)
                deltaPodDemand = Decimal.from(1e18); // If no one sow'd last Season
            else deltaPodDemand = Decimal.ratio(dsoil, lastDSoil);
            if (s.w.lastSowTime != type(uint32).max) s.w.lastSowTime = type(uint32).max;
        }

        // Calculate Weather Case
        uint8 caseId = 0;

        // Evaluate Pod Rate
        if (podRate.greaterThanOrEqualTo(C.getUpperBoundPodRate())) caseId = 24;
        else if (podRate.greaterThanOrEqualTo(C.getOptimalPodRate())) caseId = 16;
        else if (podRate.greaterThanOrEqualTo(C.getLowerBoundPodRate())) caseId = 8;

        // Evaluate Price
        if (int_price > 1e18 || (int_price == 1e18 && podRate.lessThanOrEqualTo(C.getOptimalPodRate()))) caseId += 4;

        // Evaluate Delta Soil Demand
        if (deltaPodDemand.greaterThanOrEqualTo(C.getUpperBoundDPD())) caseId += 2;
        else if (deltaPodDemand.greaterThanOrEqualTo(C.getLowerBoundDPD())) caseId += 1;

        s.w.lastDSoil = dsoil;

        emit PodRateSnapshot(season(), podRate.mul(1e18).asUint256());
        changeWeather(caseId);
        handleRain(caseId);
    }

    function changeWeather(uint256 caseId) private {
        int8 change = s.cases[caseId];
        if (change < 0) {
            if (yield() <= (uint32(uint8(-change)))) {
                // if (change < 0 && yield() <= uint32(-change)),
                // then 0 <= yield() <= type(int8).max because change is an int8.
                // Thus, downcasting yield() to an int8 will not cause overflow.
                change = 1 - int8(int32(yield()));
                s.w.yield = 1;
            } else s.w.yield = yield() - (uint32(uint8(-change)));
        }
        if (change > 0) {
            s.w.yield = yield() + (uint32(uint8(change)));
        }

        emit WeatherChange(season(), caseId, change, s.w.yield);
    }

    function handleRain(uint256 caseId) internal {
        if (caseId < 4 || caseId > 7) {
            if (s.r.raining) s.r.raining = false;
            return;
        } else if (!s.r.raining) {
            s.r.raining = true;
            s.sops[season()] = s.sops[s.r.start];
            s.r.start = season();
            s.r.pods = s.f.pods;
            s.r.roots = s.s.roots;
        } else if (season() >= s.r.start + (s.season.withdrawSeasons - 1)) {
            if (s.r.roots > 0) sop();
        }
    }

    function sop() private {
        (uint256 newTopcorns, uint256 newBNB) = calculateSopTopcornsAndBNB();
        if (newBNB <= s.s.roots / 1e32 || (s.sop.base > 0 && (newTopcorns * s.sop.base) / s.sop.wbnb / s.r.roots == 0)) return;

        mintToSilo(newTopcorns);
        uint256 bnbBought = LibMarket.sellToWBNB(newTopcorns, 0);
        uint256 newHarvestable = 0;
        if (s.f.harvestable < s.r.pods) {
            newHarvestable = s.r.pods - s.f.harvestable;
            mintToHarvestable(newHarvestable);
        }
        if (bnbBought == 0) return;
        rewardBNB(bnbBought);
        emit SeasonOfPlenty(season(), bnbBought, newHarvestable);
    }

    function calculateSopTopcornsAndBNB() private view returns (uint256, uint256) {
        (uint256 bnbTopcornPool, uint256 topcornsTopcornPool) = reserves();
        (uint256 bnbBUSDPool, uint256 busdBUSDPool) = pegReserves();

        uint256 newTopcorns = LibMath.sqrt((bnbTopcornPool * topcornsTopcornPool * busdBUSDPool) / bnbBUSDPool);
        if (newTopcorns <= topcornsTopcornPool) return (0, 0);
        uint256 topcorns = newTopcorns - topcornsTopcornPool;
        topcorns = (topcorns * 100000) / 99875 + 1;

        uint256 topcornsWithFee = topcorns * 9975;
        uint256 numerator = topcornsWithFee * bnbTopcornPool;
        uint256 denominator = topcornsTopcornPool * 10000 + topcornsWithFee;
        uint256 bnb = numerator / denominator;

        return (topcorns, bnb);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

library LibMath {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    // ============ Constants ============

    uint256 constant BASE = 10**18;

    // ============ Structs ============

    struct D256 {
        uint256 value;
    }

    // ============ Static Functions ============

    function zero() internal pure returns (D256 memory) {
        return D256({value: 0});
    }

    function one() internal pure returns (D256 memory) {
        return D256({value: BASE});
    }

    function from(uint256 a) internal pure returns (D256 memory) {
        return D256({value: a * (BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b * (BASE))});
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b * (BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b * BASE, reason);
        return D256({value: self.value - (b * (BASE))});
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value * (b)});
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value / (b)});
    }

    function pow(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        if (b == 0) {
            return one();
        }

        D256 memory temp = D256({value: self.value});
        for (uint256 i = 1; i < b; i++) {
            temp = mul(temp, self);
        }

        return temp;
    }

    function add(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value + (b.value)});
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value - (b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        require(self.value >= b.value, reason);
        return D256({value: self.value - (b.value)});
    }

    function mul(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, b.value, BASE)});
    }

    function div(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: getPartial(self.value, BASE, b.value)});
    }

    function equals(D256 memory self, D256 memory b) internal pure returns (bool) {
        return self.value == b.value;
    }

    function greaterThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 2;
    }

    function lessThan(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) == 0;
    }

    function greaterThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) > 0;
    }

    function lessThanOrEqualTo(D256 memory self, D256 memory b) internal pure returns (bool) {
        return compareTo(self, b) < 2;
    }

    function isZero(D256 memory self) internal pure returns (bool) {
        return self.value == 0;
    }

    function asUint256(D256 memory self) internal pure returns (uint256) {
        return self.value / (BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return (target * (numerator)) / (denominator);
    }

    function compareTo(D256 memory a, D256 memory b) private pure returns (uint256) {
        if (a.value == b.value) {
            return 1;
        }
        return a.value > b.value ? 2 : 0;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/ITopcorn.sol";
import "../interfaces/IWBNB.sol";
import "./LibAppStorage.sol";
import "./LibClaim.sol";

/**
 * @title Market Library handles swapping, addinga and removing LP on Pancake for Farmer.
 **/
library LibMarket {
    event TopcornAllocation(address indexed account, uint256 topcorns);

    struct DiamondStorage {
        address topcorn;
        address wbnb;
        address router;
    }

    struct AddLiquidity {
        uint256 topcornAmount;
        uint256 minTopcornAmount;
        uint256 minBNBAmount;
    }

    bytes32 private constant MARKET_STORAGE_POSITION = keccak256("diamond.standard.market.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initMarket(
        address topcorn,
        address wbnb,
        address router
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.topcorn = topcorn;
        ds.wbnb = wbnb;
        ds.router = router;
    }

    /**
     * Swap
     **/

    function buy(uint256 buyTopcornAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyTopcornAmount, msg.value, msg.sender);
    }

    function buyAndDeposit(uint256 buyTopcornAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyTopcornAmount, msg.value, address(this));
    }

    function buyExactTokensToWallet(
        uint256 buyTopcornAmount,
        address to,
        bool toWallet
    ) internal returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) amount = buyExactTokens(buyTopcornAmount, to);
        else {
            amount = buyExactTokens(buyTopcornAmount, address(this));
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function buyExactTokens(uint256 buyTopcornAmount, address to) internal returns (uint256 amount) {
        (uint256 BNBAmount, uint256 topcornAmount) = _buyExactTokens(buyTopcornAmount, msg.value, to);
        allocateBNBRefund(msg.value, BNBAmount, false);
        return topcornAmount;
    }

    function buyAndSow(uint256 buyTopcornAmount, uint256 buyBNBAmount) internal returns (uint256 amount) {
        if (buyTopcornAmount == 0) {
            allocateBNBRefund(msg.value, 0, false);
            return 0;
        }
        (uint256 bnbAmount, uint256 topcornAmount) = _buyExactTokensWBNB(buyTopcornAmount, buyBNBAmount, address(this));
        allocateBNBRefund(msg.value, bnbAmount, false);
        amount = topcornAmount;
    }

    function sellToWBNB(uint256 sellTopcornAmount, uint256 minBuyBNBAmount) internal returns (uint256 amount) {
        (, uint256 outAmount) = _sell(sellTopcornAmount, minBuyBNBAmount, address(this));
        return outAmount;
    }

    /**
     *  Liquidity
     **/

    function removeLiquidity(
        uint256 liqudity,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) internal returns (uint256 topcornAmount, uint256 bnbAmount) {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).removeLiquidityETH(ds.topcorn, liqudity, minTopcornAmount, minBNBAmount, msg.sender, block.timestamp);
    }

    function removeLiquidityWithTopcornAllocation(
        uint256 liqudity,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) internal returns (uint256 topcornAmount, uint256 bnbAmount) {
        DiamondStorage storage ds = diamondStorage();
        (topcornAmount, bnbAmount) = IPancakeRouter02(ds.router).removeLiquidity(ds.topcorn, ds.wbnb, liqudity, minTopcornAmount, minBNBAmount, address(this), block.timestamp);
        allocateBNBRefund(bnbAmount, 0, true);
    }

    function addAndDepositLiquidity(AddLiquidity calldata al) internal returns (uint256) {
        allocateTopcorns(al.topcornAmount);
        (, uint256 liquidity) = addLiquidity(al);
        return liquidity;
    }

    function addLiquidity(AddLiquidity calldata al) internal returns (uint256, uint256) {
        (uint256 topcornsDeposited, uint256 bnbDeposited, uint256 liquidity) = _addLiquidity(msg.value, al.topcornAmount, al.minBNBAmount, al.minTopcornAmount);
        allocateBNBRefund(msg.value, bnbDeposited, false);
        allocateTopcornRefund(al.topcornAmount, topcornsDeposited);
        return (topcornsDeposited, liquidity);
    }

    function swapAndAddLiquidity(
        uint256 buyTopcornAmount,
        uint256 buyBNBAmount,
        LibMarket.AddLiquidity calldata al
    ) internal returns (uint256) {
        uint256 boughtLP;
        if (buyTopcornAmount > 0) boughtLP = LibMarket.buyTopcornsAndAddLiquidity(buyTopcornAmount, al);
        else if (buyBNBAmount > 0) boughtLP = LibMarket.buyBNBAndAddLiquidity(buyBNBAmount, al);
        else boughtLP = LibMarket.addAndDepositLiquidity(al);
        return boughtLP;
    }

    // al.buyTopcornAmount is the amount of topcorns the user wants to add to LP
    // buyTopcornAmount is the amount of topcorns the person bought to contribute to LP. Note that
    // buyTopcorn amount will AT BEST be equal to al.buyTopcornAmount because of slippage.
    // Otherwise, it will almost always be less than al.buyTopcorn amount
    function buyTopcornsAndAddLiquidity(uint256 buyTopcornAmount, AddLiquidity calldata al) internal returns (uint256 liquidity) {
        DiamondStorage storage ds = diamondStorage();
        IWBNB(ds.wbnb).deposit{value: msg.value}();

        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyTopcornAmount, path);
        (uint256 bnbSold, uint256 topcorns) = _buyWithWBNB(buyTopcornAmount, amounts[0], address(this));

        // If topcorns bought does not cover the amount of money to move to LP
        if (al.topcornAmount > buyTopcornAmount) {
            uint256 newTopcornAmount = al.topcornAmount - buyTopcornAmount;
            allocateTopcorns(newTopcornAmount);
            topcorns = topcorns + newTopcornAmount;
        }
        uint256 bnbAdded;
        (topcorns, bnbAdded, liquidity) = _addLiquidityWBNB(msg.value - bnbSold, topcorns, al.minBNBAmount, al.minTopcornAmount);

        allocateTopcornRefund(al.topcornAmount, topcorns);
        allocateBNBRefund(msg.value, bnbAdded + bnbSold, true);
        return liquidity;
    }

    // This function is called when user sends more value of TopCorn than BNB to LP.
    // Value of TopCorn is converted to equivalent value of BNB.
    function buyBNBAndAddLiquidity(uint256 buyWbnbAmount, AddLiquidity calldata al) internal returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        uint256 sellTopcorns = _amountIn(buyWbnbAmount);
        allocateTopcorns(al.topcornAmount + sellTopcorns);
        (uint256 topcornsSold, uint256 wbnbBought) = _sell(sellTopcorns, buyWbnbAmount, address(this));
        if (msg.value > 0) IWBNB(ds.wbnb).deposit{value: msg.value}();
        (uint256 topcorns, uint256 bnbAdded, uint256 liquidity) = _addLiquidityWBNB(msg.value + wbnbBought, al.topcornAmount, al.minBNBAmount, al.minTopcornAmount);

        allocateTopcornRefund(al.topcornAmount + sellTopcorns, topcorns + topcornsSold);
        allocateBNBRefund(msg.value + wbnbBought, bnbAdded, true);
        return liquidity;
    }

    /**
     *  Shed
     **/

    function _sell(
        uint256 sellTopcornAmount,
        uint256 minBuyBNBAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.topcorn;
        path[1] = ds.wbnb;
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(sellTopcornAmount, minBuyBNBAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buy(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactETHForTokens{value: bnbAmount}(topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokens(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapETHForExactTokens{value: bnbAmount}(topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokensWBNB(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;
        IWBNB(ds.wbnb).deposit{value: bnbAmount}();
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapTokensForExactTokens(topcornAmount, bnbAmount, path, to, block.timestamp);
        IWBNB(ds.wbnb).withdraw(bnbAmount - amounts[0]);
        return (amounts[0], amounts[1]);
    }

    function _buyWithWBNB(
        uint256 topcornAmount,
        uint256 bnbAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.wbnb;
        path[1] = ds.topcorn;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(bnbAmount, topcornAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _addLiquidity(
        uint256 bnbAmount,
        uint256 topcornAmount,
        uint256 minBNBAmount,
        uint256 minTopcornAmount
    )
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidityETH{value: bnbAmount}(ds.topcorn, topcornAmount, minTopcornAmount, minBNBAmount, address(this), block.timestamp);
    }

    function _addLiquidityWBNB(
        uint256 wbnbAmount,
        uint256 topcornAmount,
        uint256 minWBNBAmount,
        uint256 minTopcornAmount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidity(ds.topcorn, ds.wbnb, topcornAmount, wbnbAmount, minTopcornAmount, minWBNBAmount, address(this), block.timestamp);
    }

    function _amountIn(uint256 buyWBNBAmount) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.topcorn;
        path[1] = ds.wbnb;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyWBNBAmount, path);
        return amounts[0];
    }

    function allocateTopcornsToWallet(
        uint256 amount,
        address to,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) LibMarket.allocateTopcornsTo(amount, to);
        else {
            LibMarket.allocateTopcornsTo(amount, address(this));
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function transferTopcorns(
        address to,
        uint256 amount,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) ITopcorn(s.c.topcorn).transferFrom(msg.sender, to, amount);
        else {
            ITopcorn(s.c.topcorn).transferFrom(msg.sender, address(this), amount);
            s.a[to].wrappedTopcorns = s.a[to].wrappedTopcorns + amount;
        }
    }

    function allocateTopcorns(uint256 amount) internal {
        allocateTopcornsTo(amount, address(this));
    }

    function allocateTopcornsTo(uint256 amount, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 wrappedTopcorns = s.a[msg.sender].wrappedTopcorns;
        uint256 remainingTopcorns = amount;
        if (wrappedTopcorns > 0) {
            if (remainingTopcorns > wrappedTopcorns) {
                s.a[msg.sender].wrappedTopcorns = 0;
                remainingTopcorns = remainingTopcorns - wrappedTopcorns;
            } else {
                s.a[msg.sender].wrappedTopcorns = wrappedTopcorns - remainingTopcorns;
                remainingTopcorns = 0;
            }
            uint256 fromWrappedTopcorns = amount - remainingTopcorns;
            emit TopcornAllocation(msg.sender, fromWrappedTopcorns);
            if (to != address(this)) ITopcorn(s.c.topcorn).transfer(to, fromWrappedTopcorns);
        }
        if (remainingTopcorns > 0) ITopcorn(s.c.topcorn).transferFrom(msg.sender, to, remainingTopcorns);
    }

    // Allocate TopCorn Refund stores the TopCorn refund amount in the state to be refunded at the end of the transaction.
    function allocateTopcornRefund(uint256 inputAmount, uint256 amount) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (s.refundStatus % 2 == 1) {
                s.refundStatus += 1;
                s.topcornRefundAmount = inputAmount - amount;
            } else s.topcornRefundAmount = s.topcornRefundAmount + (inputAmount - amount);
        }
    }

    // Allocate BNB Refund stores the BNB refund amount in the state to be refunded at the end of the transaction.
    function allocateBNBRefund(
        uint256 inputAmount,
        uint256 amount,
        bool wbnb
    ) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (wbnb) IWBNB(s.c.wbnb).withdraw(inputAmount - amount);
            if (s.refundStatus < 3) {
                s.refundStatus += 2;
                s.bnbRefundAmount = inputAmount - amount;
            } else s.bnbRefundAmount = s.bnbRefundAmount + (inputAmount - amount);
        }
    }

    function claimRefund(LibClaim.Claim calldata c) internal {
        // The only case that a Claim triggers an BNB refund is
        // if the farmer claims LP, removes the LP and wraps the underlying Topcorns
        if (c.convertLP && !c.toWallet && c.lpWithdrawals.length > 0) refund();
    }

    function refund() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // If Refund state = 1 -> No refund
        // If Refund state is even -> Refund Topcorns
        // if Refund state > 2 -> Refund BNB

        uint256 rs = s.refundStatus;
        if (rs > 1) {
            if (rs > 2) {
                (bool success, ) = msg.sender.call{value: s.bnbRefundAmount}("");
                require(success, "Market: Refund failed.");
                rs -= 2;
                s.bnbRefundAmount = 1;
            }
            if (rs == 2) {
                ITopcorn(s.c.topcorn).transfer(msg.sender, s.topcornRefundAmount);
                s.topcornRefundAmount = 1;
            }
            s.refundStatus = 1;
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./Life.sol";
import "../../../libraries/LibInternal.sol";

/**
 * @title Silo
 **/
contract Silo is Life {
    using Decimal for Decimal.D256;

    uint256 private constant BASE = 1e12;
    uint256 private constant BURN_BASE = 1e20;
    uint256 private constant BIG_BASE = 1e24;

    /**
     * Getters
     **/

    function seasonOfPlenty(uint32 _s) external view returns (uint256) {
        return s.sops[_s];
    }

    function paused() public view returns (bool) {
        return s.paused;
    }

    /**
     * Internal
     **/

    // Silo

    function stepSilo(uint256 amount) internal {
        rewardTopcorns(amount);
    }

    function rewardTopcorns(uint256 amount) private {
        if (s.s.stalk == 0 || amount == 0) return;
        s.s.stalk = s.s.stalk + (amount * C.getStalkPerTopcorn());
        s.s.topcorns = s.s.topcorns + amount;
        s.topcorn.deposited = s.topcorn.deposited + amount;
        s.s.seeds = s.s.seeds + (amount * C.getSeedsPerTopcorn());
    }

    // Season of Plenty

    function rewardBNB(uint256 amount) internal {
        uint256 base;
        if (s.sop.base == 0) {
            base = amount * BIG_BASE;
            s.sop.base = BURN_BASE;
        } else base = (amount * s.sop.base) / s.sop.wbnb;

        // Award bnb to claimed stalk holders
        uint256 basePerStalk = base / s.r.roots;
        base = basePerStalk * s.r.roots;
        s.sops[s.r.start] = s.sops[s.r.start] + basePerStalk;

        // Update total state
        s.sop.wbnb = s.sop.wbnb + amount;
        s.sop.base = s.sop.base + base;
        if (base > 0) s.sop.last = s.r.start;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import { IPancakeRouter01 } from "./IPancakeRouter01.sol";

/**
 * @title Pancake Router02 Interface
 **/
interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title TopCorn Interface
 **/
abstract contract ITopcorn is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

    function mint(address account, uint256 amount) public virtual returns (bool);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title WBNB Interface
 **/
interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../farm/AppStorage.sol";

/**
 * @title App Storage Library allows libaries to access Farmer's state.
 **/
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity =0.8.16;

import "./LibCheck.sol";
import "./LibInternal.sol";
import "./LibMarket.sol";
import "./LibAppStorage.sol";
import "../interfaces/IWBNB.sol";

/**
 * @title Claim Library handles claiming TopCorn and LP withdrawals, harvesting plots and claiming BNB.
 **/
library LibClaim {
    event TopcornClaim(address indexed account, uint32[] withdrawals, uint256 topcorns);
    event LPClaim(address indexed account, uint32[] withdrawals, uint256 lp);
    event BnbClaim(address indexed account, uint256 bnb);
    event Harvest(address indexed account, uint256[] plots, uint256 topcorns);
    event PodListingCancelled(address indexed account, uint256 indexed index);

    struct Claim {
        uint32[] topcornWithdrawals;
        uint32[] lpWithdrawals;
        uint256[] plots;
        bool claimBnb;
        bool convertLP;
        uint256 minTopcornAmount;
        uint256 minBNBAmount;
        bool toWallet;
    }

    function claim(Claim calldata c) public returns (uint256 topcornsClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (c.topcornWithdrawals.length > 0) topcornsClaimed = topcornsClaimed + claimTopcorns(c.topcornWithdrawals);
        if (c.plots.length > 0) topcornsClaimed = topcornsClaimed + harvest(c.plots);
        if (c.lpWithdrawals.length > 0) {
            if (c.convertLP) {
                if (!c.toWallet) topcornsClaimed = topcornsClaimed + removeClaimLPAndWrapTopcorns(c.lpWithdrawals, c.minTopcornAmount, c.minBNBAmount);
                else removeAndClaimLP(c.lpWithdrawals, c.minTopcornAmount, c.minBNBAmount);
            } else claimLP(c.lpWithdrawals);
        }
        if (c.claimBnb) claimBnb();

        if (topcornsClaimed > 0) {
            if (c.toWallet) ITopcorn(s.c.topcorn).transfer(msg.sender, topcornsClaimed);
            else s.a[msg.sender].wrappedTopcorns = s.a[msg.sender].wrappedTopcorns + topcornsClaimed;
        }
    }

    // Claim Topcorns

    function claimTopcorns(uint32[] calldata withdrawals) public returns (uint256 topcornsClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            topcornsClaimed = topcornsClaimed + claimTopcornWithdrawal(msg.sender, withdrawals[i]);
        }
        emit TopcornClaim(msg.sender, withdrawals, topcornsClaimed);
    }

    function claimTopcornWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].topcorn.withdrawals[_s];
        require(amount > 0, "Claim: TopCorn withdrawal is empty.");
        delete s.a[account].topcorn.withdrawals[_s];
        s.topcorn.withdrawn = s.topcorn.withdrawn - amount;
        return amount;
    }

    // Claim LP

    function claimLP(uint32[] calldata withdrawals) public {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimed = _claimLP(withdrawals);
        IPancakePair(s.c.pair).transfer(msg.sender, lpClaimed);
    }

    function removeAndClaimLP(
        uint32[] calldata withdrawals,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) public returns (uint256 topcorns) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (topcorns, ) = LibMarket.removeLiquidity(lpClaimd, minTopcornAmount, minBNBAmount);
    }

    function removeClaimLPAndWrapTopcorns(
        uint32[] calldata withdrawals,
        uint256 minTopcornAmount,
        uint256 minBNBAmount
    ) private returns (uint256 topcorns) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (topcorns, ) = LibMarket.removeLiquidityWithTopcornAllocation(lpClaimd, minTopcornAmount, minBNBAmount);
    }

    function _claimLP(uint32[] calldata withdrawals) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimd = 0;
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            lpClaimd = lpClaimd + claimLPWithdrawal(msg.sender, withdrawals[i]);
        }
        emit LPClaim(msg.sender, withdrawals, lpClaimd);
        return lpClaimd;
    }

    function claimLPWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].lp.withdrawals[_s];
        require(amount > 0, "Claim: LP withdrawal is empty.");
        delete s.a[account].lp.withdrawals[_s];
        s.lp.withdrawn = s.lp.withdrawn - amount;
        return amount;
    }

    // Season of Plenty

    function claimBnb() public {
        LibInternal.updateSilo(msg.sender);
        uint256 bnb = claimPlenty(msg.sender);
        emit BnbClaim(msg.sender, bnb);
    }

    function claimPlenty(address account) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (s.sop.base == 0) return 0;
        uint256 bnb = (s.a[account].sop.base * s.sop.wbnb) / s.sop.base;
        s.sop.wbnb = s.sop.wbnb - bnb;
        s.sop.base = s.sop.base - s.a[account].sop.base;
        s.a[account].sop.base = 0;
        IWBNB(s.c.wbnb).withdraw(bnb);
        (bool success, ) = account.call{value: bnb}("");
        require(success, "WBNB: bnb transfer failed");
        return bnb;
    }

    // Harvest

    function harvest(uint256[] calldata plots) public returns (uint256 topcornsHarvested) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < plots.length; i++) {
            require(plots[i] < s.f.harvestable, "Claim: Plot not harvestable.");
            require(s.a[msg.sender].field.plots[plots[i]] > 0, "Claim: Plot not harvestable.");
            uint256 harvested = harvestPlot(msg.sender, plots[i]);
            topcornsHarvested = topcornsHarvested + harvested;
        }
        require(s.f.harvestable - s.f.harvested >= topcornsHarvested, "Claim: Not enough Harvestable.");
        s.f.harvested = s.f.harvested + topcornsHarvested;
        emit Harvest(msg.sender, plots, topcornsHarvested);
    }

    function harvestPlot(address account, uint256 plotId) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 pods = s.a[account].field.plots[plotId];
        require(pods > 0, "Claim: Plot is empty.");
        uint256 harvestablePods = s.f.harvestable - plotId;
        delete s.a[account].field.plots[plotId];
        if (s.podListings[plotId] > 0) {
            cancelPodListing(plotId);
        }
        if (harvestablePods >= pods) return pods;
        s.a[account].field.plots[plotId + harvestablePods] = pods - harvestablePods;
        return harvestablePods;
    }

    function cancelPodListing(uint256 index) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.podListings[index];
        emit PodListingCancelled(msg.sender, index);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/**
 * @title Pancake Router01 Interface
 **/
interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/IDiamondCut.sol";

/**
 * @title App Storage defines the state object for Farmer.
 **/
contract Account {
    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and stored Withdrawals.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount;
        uint128 tdv;
    }

    // Silo stores Silo-related balances
    struct Silo {
        uint256 stalk; // Balance of the Farmer's normal Stalk.
        uint256 seeds; // Balance of the Farmer's normal Seeds.
    }

    // Season Of Plenty stores Season of Plenty (SOP) related balances
    struct SeasonOfPlenty {
        uint256 base;
        uint256 roots; // The number of Roots a Farmer had when it started Raining.
        uint256 basePerRoot;
    }

    // The Account level State stores all of the Farmer's balances in the contract.
    struct State {
        Field field; // A Farmer's Field storage.
        AssetSilo topcorn;
        AssetSilo lp;
        Silo s; // A Farmer's Silo storage. 
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedTopcorns;
        mapping(address => mapping(uint32 => Deposit)) deposits;  // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals;  // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
    }
}

contract Storage {
    // Contracts stored the contract addresses of various important contracts to Farm.
    struct Contracts {
        address topcorn;
        address pair;
        address pegPair;
        address wbnb;
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Topcorns.
    }

    // Silo
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    struct SeasonOfPlenty {
        uint256 wbnb;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
        uint256 topcorns;
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average price calculated from the Topcorn:BNB - usd:BNB.
    struct Oracle {
        bool initialized;  // True if the Oracle has been initialzed. It needs to be initialized on Deployment and re-initialized each Unpause.
        uint256 cumulative;
        uint256 pegCumulative;
        uint32 timestamp;  // The timestamp of the start of the current Season.
        uint32 pegTimestamp;
    }

    // Rain stores global level Rain balances. (Rain is when P > 1, Pod rate Excessively Low).
    struct Rain {
        uint32 start;
        bool raining;
        uint256 pods; // The number of Pods when it last started Raining.
        uint256 roots; // The number of Roots when it last started Raining.
    }

    // Sesaon stores global level Season balances.
    struct Season {
        // The first storage slot in Season is filled with a variety of somewhat unrelated storage variables.
        // Given that they are all smaller numbers, they are stored together for gas efficient read/write operations. 
        // Apologies if this makes it confusing :(
        uint32 current; // The current Season in Farm.
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint256 start; // The timestamp of the Farm deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Farm.
        uint256 timestamp; // The timestamp of the start of the current Season.
        uint256 rewardMultiplier; // Multiplier for incentivize 
        uint256 maxTimeMultiplier; // Multiplier for incentivize 
        uint256 costSunrice; // For Incentivize, gas limit per function call sunrise()
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Topcorns in Soil.
    }
}

struct AppStorage {
    uint8 index; // The index of the Topcorn token in the Topcorn:BNB Pancakeswap v2 pool
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Farm is Paused.
    uint128 pausedAt; // The timestamp at which Farm was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c;
    Storage.Field f; // The Field storage struct found above.
    Storage.Oracle o; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance
    Storage.Weather w; // The Weather storage struct found above.
    Storage.AssetSilo topcorn;
    Storage.AssetSilo lp;
    Storage.SeasonOfPlenty sop;
    mapping(uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.
    mapping(address => Account.State) a; // A mapping from Farmer address to Account state.
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    // These refund variables are intra-transaction state varables use to store refund amounts
    uint256 refundStatus;
    uint256 topcornRefundAmount;
    uint256 bnbRefundAmount;
    uint8 pegIndex; // The index of the BUSD token in the BUSD:BNB PancakeSwap v2 pool
}

// SPDX-License-Identifier: MIT
pragma solidity = 0.8.16;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

/**
 * @title Internal Library handles gas efficient function calls between facets.
 **/

interface ISiloUpdate {
    function updateSilo(address account) external payable;
}

library LibInternal {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint16 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint16 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        address[] facetAddresses;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function updateSilo(address account) internal {
        DiamondStorage storage ds = diamondStorage();
        address facet = ds.selectorToFacetAndPosition[ISiloUpdate.updateSilo.selector].facetAddress;
        bytes memory myFunctionCall = abi.encodeWithSelector(ISiloUpdate.updateSilo.selector, account);
        (bool success, ) = address(facet).delegatecall(myFunctionCall);
        require(success, "Silo: updateSilo failed.");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

/**
 * @title Pancake Pair Interface
 **/
interface IPancakePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../interfaces/pancake/IPancakePair.sol";
import "../../AppStorage.sol";
import "../../ReentrancyGuard.sol";
import "../../../C.sol";
import "../../../interfaces/ITopcorn.sol";

/**
 * @title Life
 **/
contract Life is ReentrancyGuard {
    /**
     * Getters
     **/

    // Contracts

    function topcorn() public view returns (ITopcorn) {
        return ITopcorn(s.c.topcorn);
    }

    function pair() public view returns (IPancakePair) {
        return IPancakePair(s.c.pair);
    }

    function pegPair() public view returns (IPancakePair) {
        return IPancakePair(s.c.pegPair);
    }

    // Time

    function time() external view returns (Storage.Season memory) {
        return s.season;
    }

    function season() public view returns (uint32) {
        return s.season.current;
    }

    function withdrawSeasons() external view returns (uint8) {
        return s.season.withdrawSeasons;
    }

    function seasonTime() public view virtual returns (uint32) {
        if (block.timestamp < s.season.start) return 0;
        if (s.season.period == 0) return type(uint32).max;
        return uint32((block.timestamp - s.season.start) / s.season.period);
    }

    function incentiveTime() internal view returns (uint256) {
        uint256 timestamp = block.timestamp - (s.season.start + (s.season.period * season()));
        uint256 maxTime = s.season.maxTimeMultiplier;
        if (maxTime > 100) maxTime = 100;
        if (timestamp > maxTime) timestamp = maxTime;
        return timestamp;
    }

    /**
     * Internal
     **/
    function increaseSupply(uint256 newSupply) internal returns (uint256, uint256) {
        (uint256 newHarvestable, uint256 siloReward) = (0, 0);

        if (s.f.harvestable < s.f.pods) {
            uint256 notHarvestable = s.f.pods - s.f.harvestable;
            newHarvestable = (newSupply * C.getHarvestPercentage()) / 1e18;
            newHarvestable = newHarvestable > notHarvestable ? notHarvestable : newHarvestable;
            mintToHarvestable(newHarvestable);
        }

        if (s.s.seeds == 0 && s.s.stalk == 0) return (newHarvestable, 0);
        siloReward = newSupply - newHarvestable;
        if (siloReward > 0) {
            mintToSilo(siloReward);
        }
        return (newHarvestable, siloReward);
    }

    function mintToSilo(uint256 amount) internal {
        if (amount > 0) {
            topcorn().mint(address(this), amount);
        }
    }

    function mintToHarvestable(uint256 amount) internal {
        topcorn().mint(address(this), amount);
        s.f.harvestable = s.f.harvestable + amount;
    }

    function mintToAccount(address account, uint256 amount) internal {
        topcorn().mint(account, amount);
    }

    /**
     * Soil
     **/

    function setSoil(uint256 amount) internal returns (int256) {
        int256 soil = int256(s.f.soil);
        s.f.soil = amount;
        return int256(amount) - soil;
    }

    function getMinSoil(uint256 amount) internal view returns (uint256 minSoil) {
        minSoil = (amount * 100) / (100 + s.w.yield);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.16;

import "../libraries/LibInternal.sol";
import "./AppStorage.sol";

/**
 * @title Variation of Open Zeppelins reentrant guard to include Silo Update
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts%2Fsecurity%2FReentrancyGuard.sol
 **/
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    AppStorage internal s;

    modifier updateSilo() {
        LibInternal.updateSilo(msg.sender);
        _;
    }
    
    modifier updateSiloNonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        LibInternal.updateSilo(msg.sender);
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(s.reentrantStatus != _ENTERED, "ReentrancyGuard: reentrant call");
        s.reentrantStatus = _ENTERED;
        _;
        s.reentrantStatus = _NOT_ENTERED;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/ITopcorn.sol";
import "./libraries/Decimal.sol";

/**
 * @title C holds the contracts for Farmer.
 **/
library C {
    using Decimal for Decimal.D256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18; // BSC

    // Chain
    uint256 private constant CHAIN_ID = 56; // BSC

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant REWARD_MULTIPLIER = 1;
    uint256 private constant MAX_TIME_MULTIPLIER = 100; // seconds

    // Sun
    uint256 private constant HARVESET_PERCENTAGE = 0.5e18; // 50%

    // Weather
    uint256 private constant POD_RATE_LOWER_BOUND = 0.05e18; // 5%
    uint256 private constant OPTIMAL_POD_RATE = 0.15e18; // 15%
    uint256 private constant POD_RATE_UPPER_BOUND = 0.25e18; // 25%

    uint256 private constant DELTA_POD_DEMAND_LOWER_BOUND = 0.95e18; // 95%
    uint256 private constant DELTA_POD_DEMAND_UPPER_BOUND = 1.05e18; // 105%

    uint32 private constant STEADY_SOW_TIME = 60; // 1 minute
    uint256 private constant RAIN_TIME = 24; // 24 seasons = 1 day

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e18; // 100 topcorn
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_TOPCORN = 2;
    uint256 private constant SEEDS_PER_LP_TOPCORN = 4;
    uint256 private constant STALK_PER_TOPCORN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Bsc contracts
    address private constant FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant PEG_PAIR = address(0x28cee28a7C4b4022AC92685C07d2f33Ab1A0e122);
    address private constant BUSD_TOKEN = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984);

    /**
     * Getters
     **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getHarvestPercentage() internal pure returns (uint256) {
        return HARVESET_PERCENTAGE;
    }

    function getChainId() internal pure returns (uint256) {
        return CHAIN_ID;
    }

    function getOptimalPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(OPTIMAL_POD_RATE, PERCENT_BASE);
    }

    function getUpperBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundPodRate() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(POD_RATE_LOWER_BOUND, PERCENT_BASE);
    }

    function getUpperBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_UPPER_BOUND, PERCENT_BASE);
    }

    function getLowerBoundDPD() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(DELTA_POD_DEMAND_LOWER_BOUND, PERCENT_BASE);
    }

    function getSteadySowTime() internal pure returns (uint32) {
        return STEADY_SOW_TIME;
    }

    function getRainTime() internal pure returns (uint256) {
        return RAIN_TIME;
    }

    function getSeedsPerTopcorn() internal pure returns (uint256) {
        return SEEDS_PER_TOPCORN;
    }

    function getSeedsPerLP() internal pure returns (uint256) {
        return SEEDS_PER_LP_TOPCORN;
    }

    function getStalkPerTopcorn() internal pure returns (uint256) {
        return STALK_PER_TOPCORN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
        return STALK_PER_TOPCORN / SEEDS_PER_LP_TOPCORN;
    }

    function getRootsBase() internal pure returns (uint256) {
        return ROOTS_BASE;
    }

    function getFactory() internal pure returns (address) {
        return FACTORY;
    }

    function getRouter() internal pure returns (address) {
        return ROUTER;
    }

    function getPegPair() internal pure returns (address) {
        return PEG_PAIR;
    }

    function getRewardMultiplier() internal pure returns (uint256) {
        return REWARD_MULTIPLIER;
    }

    function getMaxTimeMultiplier() internal pure returns (uint256) {
        return MAX_TIME_MULTIPLIER;
    }

    function getBUSD() internal pure returns (address) {
        return BUSD_TOKEN;
    }
}