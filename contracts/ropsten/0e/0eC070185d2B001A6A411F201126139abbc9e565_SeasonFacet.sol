/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./Sun.sol";
import "../../../interfaces/IOracle.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibIncentive.sol";

/**
 * @author Publius
 * @title Season holds the sunrise function and handles all logic for Season changes.
 **/
contract SeasonFacet is Sun {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event Sunrise(uint256 indexed season);
    event Incentivization(address indexed account, uint256 beans, uint256 incentive, uint256 feeInBnb);
    event SeasonSnapshot(uint32 indexed season, uint256 price, uint256 supply, uint256 stalk, uint256 seeds, uint256 podIndex, uint256 harvestableIndex);

    /**
     * Sunrise
     **/

    function sunrise() external {
        require(!paused(), "Season: Paused.");
        require(seasonTime() > season(), "Season: Still current Season.");

        (Decimal.D256 memory beanPrice, Decimal.D256 memory usdcPrice) = IOracle(address(this)).capture();
        uint256 price = beanPrice.mul(1e18).div(usdcPrice).asUint256();

        stepSeason();
        decrementWithdrawSeasons();
        snapshotSeason(price);
        stepWeather(price, s.f.soil);
        uint256 increase = stepSun(beanPrice, usdcPrice);
        stepSilo(increase);
        incentivize(msg.sender, beanPrice.mul(1e18).asUint256());

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

    function snapshotSeason(uint256 price) private {
        s.season.timestamp = block.timestamp;
        emit SeasonSnapshot(s.season.current, price, bean().totalSupply(), s.s.stalk, s.s.seeds, s.f.pods, s.f.harvestable);
    }

    function incentivize(address account, uint256 price) private {
        uint256 rewardMultiplier = s.season.rewardMultiplier;
        if (rewardMultiplier > 100) rewardMultiplier = 100;
        uint256 incentive = LibIncentive.fracExp(rewardMultiplier * 1e18, 100, incentiveTime(), 1); // calculation incentive for sunrise
        uint256 feeInEth = (tx.gasprice) * (s.season.costSunrice); // calculation Transaction Fee (in bnb)
        uint256 amount = (feeInEth / price + 1) + incentive; // feeInEth/price - Transaction Fee (in topcorn)
        mintToAccount(account, amount);
        emit Incentivization(account, amount, incentive, feeInEth);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./Weather.sol";

/**
 * @author Publius
 * @title Sun
 **/
contract Sun is Weather {
    using SafeMath for uint256;
    using Decimal for Decimal.D256;

    event SupplyIncrease(uint256 indexed season, uint256 price, uint256 newHarvestable, uint256 newSilo, int256 newSoil);
    event SupplyDecrease(uint256 indexed season, uint256 price, int256 newSoil);
    event SupplyNeutral(uint256 indexed season, int256 newSoil);

    /**
     * Internal
     **/

    // Sun

    function stepSun(Decimal.D256 memory beanPrice, Decimal.D256 memory usdcPrice) internal returns (uint256) {
        (uint256 eth_reserve, uint256 bean_reserve) = lockedReserves();

        uint256 currentBeans = sqrt(bean_reserve.mul(eth_reserve).mul(1e18).div(beanPrice.mul(1e18).asUint256()));
        uint256 targetBeans = sqrt(bean_reserve.mul(eth_reserve).mul(1e18).div(usdcPrice.mul(1e18).asUint256()));

        uint256 price = beanPrice.mul(1e18).div(usdcPrice).asUint256();
        uint256 newSilo;

        if (currentBeans < targetBeans) {
            newSilo = growSupply(targetBeans.sub(currentBeans), price);
        } else if (currentBeans > targetBeans) {
            shrinkSupply(currentBeans.sub(targetBeans), price);
        } else {
            int256 newSoil = setSoil(0);
            emit SupplyNeutral(season(), newSoil);
        }
        s.w.startSoil = s.f.soil;
        return newSilo;
    }

    function shrinkSupply(uint256 beans, uint256 price) private {
        int256 newSoil = setSoil(beans);
        emit SupplyDecrease(season(), price, newSoil);
    }

    function growSupply(uint256 beans, uint256 price) private returns (uint256) {
        (uint256 newHarvestable, uint256 newSilo) = increaseSupply(beans);
        int256 newSoil = setSoil(getMinSoil(newHarvestable));
        emit SupplyIncrease(season(), price, newHarvestable, newSilo, newSoil);
        return newSilo;
    }

    // (BNB, beans)
    function lockedReserves() public view returns (uint256, uint256) {
        (uint256 ethReserve, uint256 beanReserve) = reserves();
        uint256 lp = pair().totalSupply();
        if (lp == 0) return (0, 0);
        uint256 lockedLP = s.lp.deposited.add(s.lp.withdrawn);
        ethReserve = ethReserve.mul(lockedLP).div(lp);
        beanReserve = beanReserve.mul(lockedLP).div(lp);
        return (ethReserve, beanReserve);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../libraries/Decimal.sol";

/**
 * @author Publius
 * @title Oracle Interface
 **/
interface IOracle {
    function capture() external returns (Decimal.D256 memory, Decimal.D256 memory);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/pancake/IPancakePair.sol";
import "./LibAppStorage.sol";
import "./LibSafeMath32.sol";
import "../interfaces/IBean.sol";

/**
 * @author Publius
 * @title Check Library verifies Farmer's balances are correct.
 **/
library LibCheck {
    using SafeMath for uint256;

    function beanBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IBean(s.c.bean).balanceOf(address(this)) >= s.f.harvestable.sub(s.f.harvested).add(s.bean.deposited).add(s.bean.withdrawn), "Check: Popcorn balance fail.");
    }

    function lpBalanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited.add(s.lp.withdrawn), "Check: LP balance fail.");
    }

    function balanceCheck() internal view {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(IBean(s.c.bean).balanceOf(address(this)) >= s.f.harvestable.sub(s.f.harvested).add(s.bean.deposited).add(s.bean.withdrawn), "Check: Popcorn balance fail.");
        require(IPancakePair(s.c.pair).balanceOf(address(this)) >= s.lp.deposited.add(s.lp.withdrawn), "Check: LP balance fail.");
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/**
 * @author Publius
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../../../libraries/Decimal.sol";
import "../../../libraries/LibMarket.sol";
import "./Silo.sol";

/**
 * @author Publius
 * @title Weather
 **/
contract Weather is Silo {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;
    using Decimal for Decimal.D256;

    event WeatherChange(uint256 indexed season, uint256 caseId, int8 change);
    event SeasonOfPlenty(uint256 indexed season, uint256 eth, uint256 harvestable);

    /**
     * Getters
     **/

    // Weather

    function weather() public view returns (Storage.Weather memory) {
        return s.w;
    }

    function rain() public view returns (Storage.Rain memory) {
        return s.r;
    }

    function yield() public view returns (uint32) {
        return s.w.yield;
    }

    // Reserves

    // (BNB, beans)
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
        if (bean().totalSupply() == 0) {
            s.w.yield = 1;
            return;
        }

        // Calculate Pod Rate
        Decimal.D256 memory podRate = Decimal.ratio(s.f.pods.sub(s.f.harvestable), bean().totalSupply());

        // Calculate Delta Soil Demand
        uint256 dsoil = s.w.startSoil.sub(endSoil);

        Decimal.D256 memory deltaPodDemand;

        // If Sow'd all Soil
        if (s.w.nextSowTime < type(uint32).max) {
            if (
                s.w.lastSowTime == type(uint32).max || // Didn't Sow all last Season
                s.w.nextSowTime < 300 || // Sow'd all instantly this Season
                (s.w.lastSowTime > C.getSteadySowTime() && s.w.nextSowTime < s.w.lastSowTime.sub(C.getSteadySowTime())) // Sow'd all faster
            ) deltaPodDemand = Decimal.from(1e18);
            else if (s.w.nextSowTime <= s.w.lastSowTime.add(C.getSteadySowTime()))
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

        emit WeatherChange(season(), caseId, change);
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
        } else if (season() >= s.r.start.add(s.season.withdrawSeasons - 1)) {
            if (s.r.roots > 0) sop();
        }
    }

    function sop() private {
        (uint256 newBeans, uint256 newEth) = calculateSopBeansAndEth();
        if (newEth <= s.s.roots.div(1e20) || (s.sop.base > 0 && newBeans.mul(s.sop.base).div(s.sop.weth).div(s.r.roots) == 0)) return;

        mintToSilo(newBeans);
        uint256 ethBought = LibMarket.sellToWETH(newBeans, 0);
        uint256 newHarvestable = 0;
        if (s.f.harvestable < s.r.pods) {
            newHarvestable = s.r.pods - s.f.harvestable;
            mintToHarvestable(newHarvestable);
        }
        if (ethBought == 0) return;
        rewardEther(ethBought);
        emit SeasonOfPlenty(season(), ethBought, newHarvestable);
    }

    function calculateSopBeansAndEth() private view returns (uint256, uint256) {
        (uint256 ethBeanPool, uint256 beansBeanPool) = reserves();
        (uint256 ethUSDCPool, uint256 usdcUSDCPool) = pegReserves();

        uint256 newBeans = sqrt(ethBeanPool.mul(beansBeanPool).mul(usdcUSDCPool).div(ethUSDCPool));
        if (newBeans <= beansBeanPool) return (0, 0);
        uint256 beans = newBeans - beansBeanPool;
        beans = beans.mul(10000).div(9985).add(1);

        uint256 beansWithFee = beans.mul(9975);
        uint256 numerator = beansWithFee.mul(ethBeanPool);
        uint256 denominator = beansBeanPool.mul(10000).add(beansWithFee);
        uint256 eth = numerator / denominator;

        return (beans, eth);
    }

    /**
     * Shed
     **/

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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title Decimal
 * @author dYdX
 *
 * Library that defines a fixed-point number with 18 decimal places.
 */
library Decimal {
    using SafeMath for uint256;

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
        return D256({value: a.mul(BASE)});
    }

    function ratio(uint256 a, uint256 b) internal pure returns (D256 memory) {
        return D256({value: getPartial(a, BASE, b)});
    }

    // ============ Self Functions ============

    function add(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value.add(b.mul(BASE))});
    }

    function sub(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE))});
    }

    function sub(
        D256 memory self,
        uint256 b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.mul(BASE), reason)});
    }

    function mul(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value.mul(b)});
    }

    function div(D256 memory self, uint256 b) internal pure returns (D256 memory) {
        return D256({value: self.value.div(b)});
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
        return D256({value: self.value.add(b.value)});
    }

    function sub(D256 memory self, D256 memory b) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value)});
    }

    function sub(
        D256 memory self,
        D256 memory b,
        string memory reason
    ) internal pure returns (D256 memory) {
        return D256({value: self.value.sub(b.value, reason)});
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
        return self.value.div(BASE);
    }

    // ============ Core Methods ============

    function getPartial(
        uint256 target,
        uint256 numerator,
        uint256 denominator
    ) private pure returns (uint256) {
        return target.mul(numerator).div(denominator);
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/IBean.sol";
import "../interfaces/IWETH.sol";
import "./LibAppStorage.sol";
import "./LibClaim.sol";

/**
 * @author Publius
 * @title Market Library handles swapping, addinga and removing LP on Pancake for Farmer.
 **/
library LibMarket {
    event BeanAllocation(address indexed account, uint256 beans);

    struct DiamondStorage {
        address bean;
        address weth;
        address router;
    }

    struct AddLiquidity {
        uint256 beanAmount;
        uint256 minBeanAmount;
        uint256 minEthAmount;
    }

    using SafeMath for uint256;

    bytes32 private constant MARKET_STORAGE_POSITION = keccak256("diamond.standard.market.storage");

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = MARKET_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function initMarket(
        address bean,
        address weth,
        address router
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        ds.bean = bean;
        ds.weth = weth;
        ds.router = router;
    }

    /**
     * Swap
     **/

    function buy(uint256 buyBeanAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyBeanAmount, msg.value, msg.sender);
    }

    function buyAndDeposit(uint256 buyBeanAmount) internal returns (uint256 amount) {
        (, amount) = _buy(buyBeanAmount, msg.value, address(this));
    }

    function buyExactTokensToWallet(
        uint256 buyBeanAmount,
        address to,
        bool toWallet
    ) internal returns (uint256 amount) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) amount = buyExactTokens(buyBeanAmount, to);
        else {
            amount = buyExactTokens(buyBeanAmount, address(this));
            s.a[to].wrappedBeans = s.a[to].wrappedBeans.add(amount);
        }
    }

    function buyExactTokens(uint256 buyBeanAmount, address to) internal returns (uint256 amount) {
        (uint256 ethAmount, uint256 beanAmount) = _buyExactTokens(buyBeanAmount, msg.value, to);
        allocateEthRefund(msg.value, ethAmount, false);
        return beanAmount;
    }

    function buyAndSow(uint256 buyBeanAmount, uint256 buyEthAmount) internal returns (uint256 amount) {
        if (buyBeanAmount == 0) {
            allocateEthRefund(msg.value, 0, false);
            return 0;
        }
        (uint256 ethAmount, uint256 beanAmount) = _buyExactTokensWETH(buyBeanAmount, buyEthAmount, address(this));
        allocateEthRefund(msg.value, ethAmount, false);
        amount = beanAmount;
    }

    function sellToWETH(uint256 sellBeanAmount, uint256 minBuyEthAmount) internal returns (uint256 amount) {
        (, uint256 outAmount) = _sell(sellBeanAmount, minBuyEthAmount, address(this));
        return outAmount;
    }

    /**
     *  Liquidity
     **/

    function removeLiquidity(
        uint256 liqudity,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) internal returns (uint256 beanAmount, uint256 ethAmount) {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).removeLiquidityETH(ds.bean, liqudity, minBeanAmount, minEthAmount, msg.sender, block.timestamp);
    }

    function removeLiquidityWithBeanAllocation(
        uint256 liqudity,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) internal returns (uint256 beanAmount, uint256 ethAmount) {
        DiamondStorage storage ds = diamondStorage();
        (beanAmount, ethAmount) = IPancakeRouter02(ds.router).removeLiquidity(ds.bean, ds.weth, liqudity, minBeanAmount, minEthAmount, address(this), block.timestamp);
        allocateEthRefund(ethAmount, 0, true);
    }

    function addAndDepositLiquidity(AddLiquidity calldata al) internal returns (uint256) {
        allocateBeans(al.beanAmount);
        (, uint256 liquidity) = addLiquidity(al);
        return liquidity;
    }

    function addLiquidity(AddLiquidity calldata al) internal returns (uint256, uint256) {
        (uint256 beansDeposited, uint256 ethDeposited, uint256 liquidity) = _addLiquidity(msg.value, al.beanAmount, al.minEthAmount, al.minBeanAmount);
        allocateEthRefund(msg.value, ethDeposited, false);
        allocateBeanRefund(al.beanAmount, beansDeposited);
        return (beansDeposited, liquidity);
    }

    function swapAndAddLiquidity(
        uint256 buyBeanAmount,
        uint256 buyEthAmount,
        LibMarket.AddLiquidity calldata al
    ) internal returns (uint256) {
        uint256 boughtLP;
        if (buyBeanAmount > 0) boughtLP = LibMarket.buyBeansAndAddLiquidity(buyBeanAmount, al);
        else if (buyEthAmount > 0) boughtLP = LibMarket.buyEthAndAddLiquidity(buyEthAmount, al);
        else boughtLP = LibMarket.addAndDepositLiquidity(al);
        return boughtLP;
    }

    // al.buyBeanAmount is the amount of beans the user wants to add to LP
    // buyBeanAmount is the amount of beans the person bought to contribute to LP. Note that
    // buyBean amount will AT BEST be equal to al.buyBeanAmount because of slippage.
    // Otherwise, it will almost always be less than al.buyBean amount
    function buyBeansAndAddLiquidity(uint256 buyBeanAmount, AddLiquidity calldata al) internal returns (uint256 liquidity) {
        DiamondStorage storage ds = diamondStorage();
        IWETH(ds.weth).deposit{value: msg.value}();

        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyBeanAmount, path);
        (uint256 ethSold, uint256 beans) = _buyWithWETH(buyBeanAmount, amounts[0], address(this));

        // If beans bought does not cover the amount of money to move to LP
        if (al.beanAmount > buyBeanAmount) {
            uint256 newBeanAmount = al.beanAmount - buyBeanAmount;
            allocateBeans(newBeanAmount);
            beans = beans.add(newBeanAmount);
        }
        uint256 ethAdded;
        (beans, ethAdded, liquidity) = _addLiquidityWETH(msg.value.sub(ethSold), beans, al.minEthAmount, al.minBeanAmount);

        allocateBeanRefund(al.beanAmount, beans);
        allocateEthRefund(msg.value, ethAdded.add(ethSold), true);
        return liquidity;
    }

    // This function is called when user sends more value of POPCORN than BNB to LP.
    // Value of POPCORN is converted to equivalent value of BNB.
    function buyEthAndAddLiquidity(uint256 buyWethAmount, AddLiquidity calldata al) internal returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        uint256 sellBeans = _amountIn(buyWethAmount);
        allocateBeans(al.beanAmount.add(sellBeans));
        (uint256 beansSold, uint256 wethBought) = _sell(sellBeans, buyWethAmount, address(this));
        if (msg.value > 0) IWETH(ds.weth).deposit{value: msg.value}();
        (uint256 beans, uint256 ethAdded, uint256 liquidity) = _addLiquidityWETH(msg.value.add(wethBought), al.beanAmount, al.minEthAmount, al.minBeanAmount);

        allocateBeanRefund(al.beanAmount.add(sellBeans), beans.add(beansSold));
        allocateEthRefund(msg.value.add(wethBought), ethAdded, true);
        return liquidity;
    }

    /**
     *  Shed
     **/

    function _sell(
        uint256 sellBeanAmount,
        uint256 minBuyEthAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.bean;
        path[1] = ds.weth;
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(sellBeanAmount, minBuyEthAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buy(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactETHForTokens{value: ethAmount}(beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokens(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapETHForExactTokens{value: ethAmount}(beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _buyExactTokensWETH(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) private returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;
        IWETH(ds.weth).deposit{value: ethAmount}();
        uint256[] memory amounts = IPancakeRouter02(ds.router).swapTokensForExactTokens(beanAmount, ethAmount, path, to, block.timestamp);
        IWETH(ds.weth).withdraw(ethAmount - amounts[0]);
        return (amounts[0], amounts[1]);
    }

    function _buyWithWETH(
        uint256 beanAmount,
        uint256 ethAmount,
        address to
    ) internal returns (uint256 inAmount, uint256 outAmount) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.weth;
        path[1] = ds.bean;

        uint256[] memory amounts = IPancakeRouter02(ds.router).swapExactTokensForTokens(ethAmount, beanAmount, path, to, block.timestamp);
        return (amounts[0], amounts[1]);
    }

    function _addLiquidity(
        uint256 ethAmount,
        uint256 beanAmount,
        uint256 minEthAmount,
        uint256 minBeanAmount
    )
        private
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidityETH{value: ethAmount}(ds.bean, beanAmount, minBeanAmount, minEthAmount, address(this), block.timestamp);
    }

    function _addLiquidityWETH(
        uint256 wethAmount,
        uint256 beanAmount,
        uint256 minWethAmount,
        uint256 minBeanAmount
    )
        internal
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        DiamondStorage storage ds = diamondStorage();
        return IPancakeRouter02(ds.router).addLiquidity(ds.bean, ds.weth, beanAmount, wethAmount, minBeanAmount, minWethAmount, address(this), block.timestamp);
    }

    function _amountIn(uint256 buyWethAmount) internal view returns (uint256) {
        DiamondStorage storage ds = diamondStorage();
        address[] memory path = new address[](2);
        path[0] = ds.bean;
        path[1] = ds.weth;
        uint256[] memory amounts = IPancakeRouter02(ds.router).getAmountsIn(buyWethAmount, path);
        return amounts[0];
    }

    function allocateBeansToWallet(
        uint256 amount,
        address to,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) LibMarket.allocateBeansTo(amount, to);
        else {
            LibMarket.allocateBeansTo(amount, address(this));
            s.a[to].wrappedBeans = s.a[to].wrappedBeans.add(amount);
        }
    }

    function transferBeans(
        address to,
        uint256 amount,
        bool toWallet
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (toWallet) IBean(s.c.bean).transferFrom(msg.sender, to, amount);
        else {
            IBean(s.c.bean).transferFrom(msg.sender, address(this), amount);
            s.a[to].wrappedBeans = s.a[to].wrappedBeans.add(amount);
        }
    }

    function allocateBeans(uint256 amount) internal {
        allocateBeansTo(amount, address(this));
    }

    function allocateBeansTo(uint256 amount, address to) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 wrappedBeans = s.a[msg.sender].wrappedBeans;
        uint256 remainingBeans = amount;
        if (wrappedBeans > 0) {
            if (remainingBeans > wrappedBeans) {
                s.a[msg.sender].wrappedBeans = 0;
                remainingBeans = remainingBeans - wrappedBeans;
            } else {
                s.a[msg.sender].wrappedBeans = wrappedBeans - remainingBeans;
                remainingBeans = 0;
            }
            uint256 fromWrappedBeans = amount - remainingBeans;
            emit BeanAllocation(msg.sender, fromWrappedBeans);
            if (to != address(this)) IBean(s.c.bean).transfer(to, fromWrappedBeans);
        }
        if (remainingBeans > 0) IBean(s.c.bean).transferFrom(msg.sender, to, remainingBeans);
    }

    // Allocate Popcorn Refund stores the Popcorn refund amount in the state to be refunded at the end of the transaction.
    function allocateBeanRefund(uint256 inputAmount, uint256 amount) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (s.refundStatus % 2 == 1) {
                s.refundStatus += 1;
                s.beanRefundAmount = inputAmount - amount;
            } else s.beanRefundAmount = s.beanRefundAmount.add(inputAmount - amount);
        }
    }

    // Allocate BNB Refund stores the BNB refund amount in the state to be refunded at the end of the transaction.
    function allocateEthRefund(
        uint256 inputAmount,
        uint256 amount,
        bool weth
    ) internal {
        if (inputAmount > amount) {
            AppStorage storage s = LibAppStorage.diamondStorage();
            if (weth) IWETH(s.c.weth).withdraw(inputAmount - amount);
            if (s.refundStatus < 3) {
                s.refundStatus += 2;
                s.ethRefundAmount = inputAmount - amount;
            } else s.ethRefundAmount = s.ethRefundAmount.add(inputAmount - amount);
        }
    }

    function claimRefund(LibClaim.Claim calldata c) internal {
        // The only case that a Claim triggers an BNB refund is
        // if the farmer claims LP, removes the LP and wraps the underlying Beans
        if (c.convertLP && !c.toWallet && c.lpWithdrawals.length > 0) refund();
    }

    function refund() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        // If Refund state = 1 -> No refund
        // If Refund state is even -> Refund Beans
        // if Refund state > 2 -> Refund BNB

        uint256 rs = s.refundStatus;
        if (rs > 1) {
            if (rs > 2) {
                (bool success, ) = msg.sender.call{value: s.ethRefundAmount}("");
                require(success, "Market: Refund failed.");
                rs -= 2;
                s.ethRefundAmount = 1;
            }
            if (rs == 2) {
                IBean(s.c.bean).transfer(msg.sender, s.beanRefundAmount);
                s.beanRefundAmount = 1;
            }
            s.refundStatus = 1;
        }
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./Life.sol";
import "../../../libraries/LibInternal.sol";

/**
 * @author Publius
 * @title Silo
 **/
contract Silo is Life {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;
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
        rewardBeans(amount);
    }

    function rewardBeans(uint256 amount) private {
        if (s.s.stalk == 0 || amount == 0) return;
        s.s.stalk = s.s.stalk.add(amount.mul(C.getStalkPerBean()));
        s.si.beans = s.si.beans.add(amount);
        s.bean.deposited = s.bean.deposited.add(amount);
        s.s.seeds = s.s.seeds.add(amount.mul(C.getSeedsPerBean()));
    }

    // Season of Plenty

    function rewardEther(uint256 amount) internal {
        uint256 base;
        if (s.sop.base == 0) {
            base = amount.mul(BIG_BASE);
            s.sop.base = BURN_BASE;
        } else base = amount.mul(s.sop.base).div(s.sop.weth);

        // Award ether to claimed stalk holders
        uint256 basePerStalk = base.div(s.r.roots);
        base = basePerStalk.mul(s.r.roots);
        s.sops[s.r.start] = s.sops[s.r.start].add(basePerStalk);

        // Update total state
        s.sop.weth = s.sop.weth.add(amount);
        s.sop.base = s.sop.base.add(base);
        if (base > 0) s.sop.last = s.r.start;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

import { IPancakeRouter01 } from "./IPancakeRouter01.sol";

/**
 * @author Stanislav
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title Popcorn Interface
 **/
abstract contract IBean is IERC20 {
    function burn(uint256 amount) public virtual;

    function burnFrom(address account, uint256 amount) public virtual;

    function mint(address account, uint256 amount) public virtual returns (bool);
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title WETH Interface
 **/
interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../farm/AppStorage.sol";

/**
 * @author Publius
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LibCheck.sol";
import "./LibInternal.sol";
import "./LibMarket.sol";
import "./LibAppStorage.sol";
import "./LibSafeMath32.sol";
import "../interfaces/IWETH.sol";

/**
 * @author Publius
 * @title Claim Library handles claiming Popcorn and LP withdrawals, harvesting plots and claiming Ether.
 **/
library LibClaim {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;

    event BeanClaim(address indexed account, uint32[] withdrawals, uint256 beans);
    event LPClaim(address indexed account, uint32[] withdrawals, uint256 lp);
    event BnbClaim(address indexed account, uint256 bnb);
    event Harvest(address indexed account, uint256[] plots, uint256 beans);
    event PodListingCancelled(address indexed account, uint256 indexed index);

    struct Claim {
        uint32[] beanWithdrawals;
        uint32[] lpWithdrawals;
        uint256[] plots;
        bool claimBnb;
        bool convertLP;
        uint256 minBeanAmount;
        uint256 minEthAmount;
        bool toWallet;
    }

    function claim(Claim calldata c) public returns (uint256 beansClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (c.beanWithdrawals.length > 0) beansClaimed = beansClaimed.add(claimBeans(c.beanWithdrawals));
        if (c.plots.length > 0) beansClaimed = beansClaimed.add(harvest(c.plots));
        if (c.lpWithdrawals.length > 0) {
            if (c.convertLP) {
                if (!c.toWallet) beansClaimed = beansClaimed.add(removeClaimLPAndWrapBeans(c.lpWithdrawals, c.minBeanAmount, c.minEthAmount));
                else removeAndClaimLP(c.lpWithdrawals, c.minBeanAmount, c.minEthAmount);
            } else claimLP(c.lpWithdrawals);
        }
        if (c.claimBnb) claimBnb();

        if (beansClaimed > 0) {
            if (c.toWallet) IBean(s.c.bean).transfer(msg.sender, beansClaimed);
            else s.a[msg.sender].wrappedBeans = s.a[msg.sender].wrappedBeans.add(beansClaimed);
        }
    }

    // Claim Beans

    function claimBeans(uint32[] calldata withdrawals) public returns (uint256 beansClaimed) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            beansClaimed = beansClaimed.add(claimBeanWithdrawal(msg.sender, withdrawals[i]));
        }
        emit BeanClaim(msg.sender, withdrawals, beansClaimed);
    }

    function claimBeanWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].bean.withdrawals[_s];
        require(amount > 0, "Claim: Popcorn withdrawal is empty.");
        delete s.a[account].bean.withdrawals[_s];
        s.bean.withdrawn = s.bean.withdrawn.sub(amount);
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
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) public returns (uint256 beans) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (beans, ) = LibMarket.removeLiquidity(lpClaimd, minBeanAmount, minEthAmount);
    }

    function removeClaimLPAndWrapBeans(
        uint32[] calldata withdrawals,
        uint256 minBeanAmount,
        uint256 minEthAmount
    ) private returns (uint256 beans) {
        uint256 lpClaimd = _claimLP(withdrawals);
        (beans, ) = LibMarket.removeLiquidityWithBeanAllocation(lpClaimd, minBeanAmount, minEthAmount);
    }

    function _claimLP(uint32[] calldata withdrawals) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 lpClaimd = 0;
        for (uint256 i; i < withdrawals.length; i++) {
            require(withdrawals[i] <= s.season.current, "Claim: Withdrawal not recievable.");
            lpClaimd = lpClaimd.add(claimLPWithdrawal(msg.sender, withdrawals[i]));
        }
        emit LPClaim(msg.sender, withdrawals, lpClaimd);
        return lpClaimd;
    }

    function claimLPWithdrawal(address account, uint32 _s) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 amount = s.a[account].lp.withdrawals[_s];
        require(amount > 0, "Claim: LP withdrawal is empty.");
        delete s.a[account].lp.withdrawals[_s];
        s.lp.withdrawn = s.lp.withdrawn.sub(amount);
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
        uint256 eth = s.a[account].sop.base.mul(s.sop.weth).div(s.sop.base);
        s.sop.weth = s.sop.weth.sub(eth);
        s.sop.base = s.sop.base.sub(s.a[account].sop.base);
        s.a[account].sop.base = 0;
        IWETH(s.c.weth).withdraw(eth);
        (bool success, ) = account.call{value: eth}("");
        require(success, "WETH: BNB transfer failed");
        return eth;
    }

    // Harvest

    function harvest(uint256[] calldata plots) public returns (uint256 beansHarvested) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        for (uint256 i; i < plots.length; i++) {
            require(plots[i] < s.f.harvestable, "Claim: Plot not harvestable.");
            require(s.a[msg.sender].field.plots[plots[i]] > 0, "Claim: Plot not harvestable.");
            uint256 harvested = harvestPlot(msg.sender, plots[i]);
            beansHarvested = beansHarvested.add(harvested);
        }
        require(s.f.harvestable.sub(s.f.harvested) >= beansHarvested, "Claim: Not enough Harvestable.");
        s.f.harvested = s.f.harvested.add(beansHarvested);
        emit Harvest(msg.sender, plots, beansHarvested);
    }

    function harvestPlot(address account, uint256 plotId) private returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 pods = s.a[account].field.plots[plotId];
        require(pods > 0, "Claim: Plot is empty.");
        uint256 harvestablePods = s.f.harvestable.sub(plotId);
        delete s.a[account].field.plots[plotId];
        if (s.podListings[plotId] > 0) {
            cancelPodListing(plotId);
        }
        if (harvestablePods >= pods) return pods;
        s.a[account].field.plots[plotId.add(harvestablePods)] = pods.sub(harvestablePods);
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
 * @author Stanislav
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "../interfaces/IDiamondCut.sol";

/**
 * @author Publius
 * @title App Storage defines the state object for Farmer.
 **/
contract Account {
    // Field stores a Farmer's Plots and Pod allowances.
    struct Field {
        mapping(uint256 => uint256) plots; // A Farmer's Plots. Maps from Plot index to Pod amount.
        mapping(address => uint256) podAllowances; // An allowance mapping for Pods similar to that of the ERC-20 standard. Maps from spender address to allowance amount.
    }

    // Asset Silo is a struct that stores Deposits and Seeds per Deposit, and formerly stored Withdrawals.
    // Asset Silo currently stores Unripe Bean and Unripe LP Deposits.
    struct AssetSilo {
        mapping(uint32 => uint256) withdrawals;
        mapping(uint32 => uint256) deposits;
        mapping(uint32 => uint256) depositSeeds;
    }

    // Deposit represents a Deposit in the Silo of a given Token at a given Season.
    // Stored as two uint128 state variables to save gas.
    struct Deposit {
        uint128 amount;
        uint128 bdv;
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
        AssetSilo bean;
        AssetSilo lp;
        Silo s; // A Farmer's Silo storage.
        uint32 votedUntil; // Delete on second deploy
        uint32 lastUpdate; // The Season in which the Farmer last updated their Silo.
        uint32 lastSop; // The last Season that a SOP occured at the time the Farmer last updated their Silo.
        uint32 lastRain; // The last Season that it started Raining at the time the Farmer last updated their Silo.
        uint32 lastSIs;
        uint32 proposedUntil; // Delete on second deploy
        SeasonOfPlenty sop; // A Farmer's Season Of Plenty storage.
        uint256 roots; // A Farmer's Root balance.
        uint256 wrappedBeans;
        mapping(address => mapping(uint32 => Deposit)) deposits;  // A Farmer's Silo Deposits stored as a map from Token address to Season of Deposit to Deposit.
        mapping(address => mapping(uint32 => uint256)) withdrawals;  // A Farmer's Withdrawals from the Silo stored as a map from Token address to Season the Withdrawal becomes Claimable to Withdrawn amount of Tokens.
    }
}

contract Storage {
    // Contracts stored the contract addresses of various important contracts to Beanstalk.
    struct Contracts {
        address bean;
        address pair;
        address pegPair;
        address weth;
    }

    // Field stores global Field balances.
    struct Field {
        uint256 soil; // The number of Soil currently available.
        uint256 pods; // The pod index; the total number of Pods ever minted.
        uint256 harvested; // The harvested index; the total number of Pods that have ever been Harvested.
        uint256 harvestable; // The harvestable index; the total number of Pods that have ever been Harvestable. Included previously Harvested Beans.
    }

    // Governance
    // Delete on second deploy
    struct Bip {
        address proposer;
        uint32 start;
        uint32 period;
        bool executed;
        int256 pauseOrUnpause;
        uint128 timestamp;
        uint256 roots;
        uint256 endTotalRoots;
    }

    struct DiamondCut {
        IDiamondCut.FacetCut[] diamondCut;
        address initAddress;
        bytes initData;
    }

    struct Governance {
        uint32[] activeBips;
        uint32 bipIndex;
        mapping(uint32 => DiamondCut) diamondCuts;
        mapping(uint32 => mapping(address => bool)) voted;
        mapping(uint32 => Bip) bips;
    }

    // Silo
    struct AssetSilo {
        uint256 deposited; // The total number of a given Token currently Deposited in the Silo.
        uint256 withdrawn; // The total number of a given Token currently Withdrawn From the Silo but not Claimed.
    }

    struct IncreaseSilo {
        uint256 beans;
    }

    struct V1IncreaseSilo {
        uint256 beans;
        uint256 stalk;
        uint256 roots;
    }

    struct SeasonOfPlenty {
        uint256 weth;
        uint256 base;
        uint32 last;
    }

    struct Silo {
        uint256 stalk;
        uint256 seeds;
        uint256 roots;
    }

    // Oracle stores global level Oracle balances.
    // Currently the oracle refers to the time weighted average price calculated from the Bean:weth - usdc:weth.
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
        uint32 current; // The current Season in Beanstalk.
        uint32 sis;
        uint8 withdrawSeasons; // The number of seasons required to Withdraw a Deposit.
        uint256 start; // The timestamp of the Beanstalk deployment rounded down to the nearest hour.
        uint256 period; // The length of each season in Beanstalk.
        uint256 timestamp; // The timestamp of the start of the current Season.
        uint256 rewardMultiplier;
        uint256 maxTimeMultiplier;
        uint256 costSunrice;
    }

    // Weather stores global level Weather balances.
    struct Weather {
        uint256 startSoil; // The number of Soil at the start of the current Season.
        uint256 lastDSoil; // Delta Soil; the number of Soil purchased last Season.
        uint32 lastSowTime; // The number of seconds it took for all but at most 1 Soil to sell out last Season.
        uint32 nextSowTime; // The number of seconds it took for all but at most 1 Soil to sell out this Season
        uint32 yield; // Weather; the interest rate for sowing Beans in Soil.
    }

    // Fundraiser stores Fundraiser data for a given Fundraiser.
    struct Fundraiser {
        address payee; // The address to be paid after the Fundraiser has been fully funded.
        address token; // The token address that used to raise funds for the Fundraiser.
        uint256 total; // The total number of Tokens that need to be raised to complete the Fundraiser.
        uint256 remaining; // The remaining number of Tokens that need to to complete the Fundraiser.
        uint256 start; // The timestamp at which the Fundraiser started (Fundraisers cannot be started and funded in the same block).
    }

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        bytes4 selector; // The encoded BDV function selector for the Token.
        uint32 seeds; // The Seeds Per BDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per BDV that the Silo mints in exchange for Depositing this Token.
    }
}

struct AppStorage {
    uint8 index; // The index of the Bean token in the Bean:Eth Uniswap v2 pool
    int8[32] cases; // The 24 Weather cases (array has 32 items, but caseId = 3 (mod 4) are not cases).
    bool paused; // True if Beanstalk is Paused.
    uint128 pausedAt; // The timestamp at which Beanstalk was last paused. 
    Storage.Season season; // The Season storage struct found above.
    Storage.Contracts c;
    Storage.Field f; // The Field storage struct found above.
    Storage.Governance g; // The Governance storage struct found above.
    Storage.Oracle o; // The Oracle storage struct found above.
    Storage.Rain r; // The Rain storage struct found above.
    Storage.Silo s; // The Silo storage struct found above.
    uint256 reentrantStatus; // An intra-transaction state variable to protect against reentrance
    Storage.Weather w; // The Weather storage struct found above.
    Storage.AssetSilo bean;
    Storage.AssetSilo lp;
    Storage.IncreaseSilo si;
    Storage.SeasonOfPlenty sop;
    Storage.V1IncreaseSilo v1SI;
    uint256 unclaimedRoots;
    uint256 v2SIBeans;
    mapping(uint32 => uint256) sops; // A mapping from Season to Plenty Per Root (PPR) in that Season. Plenty Per Root is 0 if a Season of Plenty did not occur.
    mapping(address => Account.State) a; // A mapping from Farmer address to Account state.
    uint32 bip0Start;
    uint32 hotFix3Start;
    mapping(uint32 => Storage.Fundraiser) fundraisers; // A mapping from Fundraiser Id to Fundraiser storage.
    uint32 fundraiserIndex; // The number of Fundraisers that have occured.
    mapping(uint256 => bytes32) podListings; // A mapping from Plot Index to the hash of the Pod Listing.
    mapping(bytes32 => uint256) podOrders; // A mapping from the hash of a Pod Order to the amount of Pods that the Pod Order is still willing to buy.
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss;  // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    // These refund variables are intra-transaction state varables use to store refund amounts
    uint256 refundStatus;
    uint256 beanRefundAmount;
    uint256 ethRefundAmount;
    uint8 pegIndex; // The index of the BUSD token in the BUSD:BNB PancakeSwap v2 pool
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

/**
 * @author Publius
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

pragma solidity >=0.8.0 <0.9.0;

/**
 * @author Publius
 * @title LibSafeMath32 is a uint32 variation of Open Zeppelin's Safe Math library.
 **/
library LibSafeMath32 {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        uint32 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint32 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint32 a, uint32 b) internal pure returns (bool, uint32) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) return 0;
        uint32 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint32 a, uint32 b) internal pure returns (uint32) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint32 a,
        uint32 b,
        string memory errorMessage
    ) internal pure returns (uint32) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

/**
 * @author Stanislav
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../../interfaces/pancake/IPancakePair.sol";
import "../../AppStorage.sol";
import "../../ReentrancyGuard.sol";
import "../../../C.sol";
import "../../../interfaces/IBean.sol";
import "../../../libraries/LibSafeMath32.sol";

/**
 * @author Publius
 * @title Life
 **/
contract Life is ReentrancyGuard {
    using SafeMath for uint256;
    using LibSafeMath32 for uint32;

    /**
     * Getters
     **/

    // Contracts

    function bean() public view returns (IBean) {
        return IBean(s.c.bean);
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

    function withdrawSeasons() public view returns (uint8) {
        return s.season.withdrawSeasons;
    }

    function seasonTime() public view virtual returns (uint32) {
        if (block.timestamp < s.season.start) return 0;
        if (s.season.period == 0) return type(uint32).max;
        return uint32((block.timestamp - s.season.start) / s.season.period); // Note: SafeMath is redundant here.
    }

    function incentiveTime() internal view returns (uint256) {
        uint256 timestamp = block.timestamp.sub(s.season.start.add(s.season.period.mul(season())));
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
            uint256 notHarvestable = s.f.pods - s.f.harvestable; // Note: SafeMath is redundant here.
            newHarvestable = newSupply.mul(C.getHarvestPercentage()).div(1e18);
            newHarvestable = newHarvestable > notHarvestable ? notHarvestable : newHarvestable;
            mintToHarvestable(newHarvestable);
        }

        if (s.s.seeds == 0 && s.s.stalk == 0) return (newHarvestable, 0);
        siloReward = newSupply.sub(newHarvestable);
        if (siloReward > 0) {
            mintToSilo(siloReward);
        }
        return (newHarvestable, siloReward);
    }

    function mintToSilo(uint256 amount) internal {
        if (amount > 0) {
            bean().mint(address(this), amount);
        }
    }

    function mintToHarvestable(uint256 amount) internal {
        bean().mint(address(this), amount);
        s.f.harvestable = s.f.harvestable.add(amount);
    }

    function mintToAccount(address account, uint256 amount) internal {
        bean().mint(account, amount);
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
        minSoil = amount.mul(100).div(100 + s.w.yield);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;
import "../libraries/LibInternal.sol";
import "./AppStorage.sol";

/**
 * @author Farmer Farms
 * @title Variation of Oepn Zeppelins reentrant guard to include Silo Update
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

pragma solidity >=0.8.0 <0.9.0;
pragma abicoder v2;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/IBean.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
 * @title C holds the contracts for Farmer.
 **/
library C {
    using Decimal for Decimal.D256;
    using SafeMath for uint256;

    // Constants
    uint256 private constant PERCENT_BASE = 1e18; // BSC

    // Chain
    uint256 private constant CHAIN_ID = 56; // BSC

    // Season
    uint256 private constant CURRENT_SEASON_PERIOD = 3600; // 1 hour
    uint256 private constant REWARD_MULTIPLIER = 1;
    uint256 private constant MAX_TIME_MULTIPLIER = 300; // seconds

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

    // Governance
    uint32 private constant GOVERNANCE_PERIOD = 168; // 168 seasons = 7 days
    uint32 private constant GOVERNANCE_EMERGENCY_PERIOD = 86400; // 1 day
    uint256 private constant GOVERNANCE_PASS_THRESHOLD = 5e17; // 1/2
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR = 2; // 2/3
    uint256 private constant GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR = 3; // 2/3
    uint32 private constant GOVERNANCE_EXPIRATION = 24; // 24 seasons = 1 day
    uint256 private constant GOVERNANCE_PROPOSAL_THRESHOLD = 0.001e18; // 0.1%
    uint256 private constant BASE_COMMIT_INCENTIVE = 100e6; // 100 beans
    uint256 private constant MAX_PROPOSITIONS = 5;

    // Silo
    uint256 private constant BASE_ADVANCE_INCENTIVE = 100e6; // 100 beans
    uint32 private constant WITHDRAW_TIME = 25; // 24 + 1 seasons
    uint256 private constant SEEDS_PER_BEAN = 2;
    uint256 private constant SEEDS_PER_LP_BEAN = 4;
    uint256 private constant STALK_PER_BEAN = 10000;
    uint256 private constant ROOTS_BASE = 1e12;

    // Field
    uint256 private constant MAX_SOIL_DENOMINATOR = 4; // 25%
    uint256 private constant COMPLEX_WEATHER_DENOMINATOR = 1000; // 0.1%

    // Bsc contracts
    address private constant FACTORY = address(0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f);
    address private constant ROUTER = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address private constant PEG_PAIR = address(0x8CAd25b511cEeFF2F20FeA5825A6993113Aa8211);
    address private constant BUSD_TOKEN = address(0xf76D4a441E4ba86A923ce32B89AFF89dBccAA075);

    /**
     * Getters
     **/

    function getSeasonPeriod() internal pure returns (uint256) {
        return CURRENT_SEASON_PERIOD;
    }

    function getGovernancePeriod() internal pure returns (uint32) {
        return GOVERNANCE_PERIOD;
    }

    function getGovernanceEmergencyPeriod() internal pure returns (uint32) {
        return GOVERNANCE_EMERGENCY_PERIOD;
    }

    function getGovernanceExpiration() internal pure returns (uint32) {
        return GOVERNANCE_EXPIRATION;
    }

    function getGovernancePassThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PASS_THRESHOLD});
    }

    function getGovernanceEmergencyThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.ratio(GOVERNANCE_EMERGENCY_THRESHOLD_NUMERATOR, GOVERNANCE_EMERGENCY_THRESHOLD_DEMONINATOR);
    }

    function getGovernanceProposalThreshold() internal pure returns (Decimal.D256 memory) {
        return Decimal.D256({value: GOVERNANCE_PROPOSAL_THRESHOLD});
    }

    function getAdvanceIncentive() internal pure returns (uint256) {
        return BASE_ADVANCE_INCENTIVE;
    }

    function getCommitIncentive() internal pure returns (uint256) {
        return BASE_COMMIT_INCENTIVE;
    }

    function getSiloWithdrawSeasons() internal pure returns (uint32) {
        return WITHDRAW_TIME;
    }

    function getComplexWeatherDenominator() internal pure returns (uint256) {
        return COMPLEX_WEATHER_DENOMINATOR;
    }

    function getMaxSoilDenominator() internal pure returns (uint256) {
        return MAX_SOIL_DENOMINATOR;
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

    function getMaxPropositions() internal pure returns (uint256) {
        return MAX_PROPOSITIONS;
    }

    function getSeedsPerBean() internal pure returns (uint256) {
        return SEEDS_PER_BEAN;
    }

    function getSeedsPerLPBean() internal pure returns (uint256) {
        return SEEDS_PER_LP_BEAN;
    }

    function getStalkPerBean() internal pure returns (uint256) {
        return STALK_PER_BEAN;
    }

    function getStalkPerLPSeed() internal pure returns (uint256) {
        return STALK_PER_BEAN / SEEDS_PER_LP_BEAN;
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