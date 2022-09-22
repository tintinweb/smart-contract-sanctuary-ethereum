/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./ConvertSilo.sol";
import "../../../libraries/LibConvert.sol";
import "../../../libraries/LibInternal.sol";
import "../../../libraries/LibClaim.sol";

/**
 * @author Publius
 * @title Silo handles depositing and withdrawing Topcorns and LP, and updating the Silo.
 **/
contract ConvertFacet is ConvertSilo {
    function convertDepositedTopcorns(
        uint256 topcorns,
        uint256 minLP,
        uint32[] memory crates,
        uint256[] memory amounts
    ) external updateSiloNonReentrant {
        LibInternal.updateSilo(msg.sender);
        (uint256 lp, uint256 topcornsConverted) = LibConvert.sellToPegAndAddLiquidity(topcorns, minLP);
        (uint256 topcornsRemoved, uint256 stalkRemoved) = _withdrawTopcornsForConvert(crates, amounts, topcornsConverted);
        require(topcornsRemoved == topcornsConverted, "Silo: Wrong Topcorns removed.");
        uint32 _s = uint32(stalkRemoved / (topcornsConverted * C.getSeedsPerLP()));
        _s = getDepositSeason(_s);

        _depositLP(lp, topcornsConverted, _s);
        LibCheck.balanceCheck();
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function convertDepositedLP(
        uint256 lp,
        uint256 minTopcorns,
        uint32[] memory crates,
        uint256[] memory amounts
    ) external updateSiloNonReentrant {
        LibInternal.updateSilo(msg.sender);
        (uint256 topcorns, uint256 lpConverted) = LibConvert.removeLPAndBuyToPeg(lp, minTopcorns);
        (uint256 lpRemoved, uint256 stalkRemoved) = _withdrawLPForConvert(crates, amounts, lpConverted);
        require(lpRemoved == lpConverted, "Silo: Wrong LP removed.");
        uint32 _s = uint32(stalkRemoved / (topcorns * C.getSeedsPerTopcorn()));
        _s = getDepositSeason(_s);
        _depositTopcorns(topcorns, _s);
        LibCheck.balanceCheck();
        LibSilo.updateBalanceOfRainStalk(msg.sender);
    }

    function claimConvertAddAndDepositLP(
        uint256 lp,
        LibMarket.AddLiquidity calldata al,
        uint32[] memory crates,
        uint256[] memory amounts,
        LibClaim.Claim calldata claim
    ) external payable updateSiloNonReentrant {
        LibClaim.claim(claim);
        _convertAddAndDepositLP(lp, al, crates, amounts);
    }

    function convertAddAndDepositLP(
        uint256 lp,
        LibMarket.AddLiquidity calldata al,
        uint32[] memory crates,
        uint256[] memory amounts
    ) external payable updateSiloNonReentrant {
        _convertAddAndDepositLP(lp, al, crates, amounts);
    }

    function lpToPeg() external view returns (uint256 lp) {
        return LibConvert.lpToPeg();
    }

    function topcornsToPeg() external view returns (uint256 topcorns) {
        (uint256 bnbReserve, uint256 topcornReserve) = reserves();
        return LibConvert.topcornsToPeg(bnbReserve, topcornReserve);
    }

    function getDepositSeason(uint32 _s) internal view returns (uint32) {
        uint32 __s = season();
        if (_s >= __s) _s = __s - 1;
        return uint32(__s - _s);
    }

        function testFunc() external pure returns (uint256 lp) {
        return 2;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../../libraries/Silo/LibSilo.sol";
import "../../ReentrancyGuard.sol";
import "../../../libraries/Silo/LibTopcornSilo.sol";
import "../../../libraries/Silo/LibLPSilo.sol";
import "../../../libraries/LibCheck.sol";
import "../../../libraries/LibMarket.sol";
import "../../../C.sol";
import "../../../libraries/LibTopcornBnb.sol";

/**
 * @author Publius
 * @title TopCorn Silo
 **/
contract ConvertSilo is ReentrancyGuard {
    event LPDeposit(address indexed account, uint256 season, uint256 lp, uint256 seeds);
    event LPRemove(address indexed account, uint32[] crates, uint256[] crateLP, uint256 lp);
    event TopcornRemove(address indexed account, uint32[] crates, uint256[] crateTopcorns, uint256 topcorns);

    struct WithdrawState {
        uint256 newLP;
        uint256 topcornsAdded;
        uint256 topcornsTransferred;
        uint256 topcornsRemoved;
        uint256 stalkRemoved;
        uint256 i;
    }

    function _convertAddAndDepositLP(
        uint256 lp,
        LibMarket.AddLiquidity calldata al,
        uint32[] memory crates,
        uint256[] memory amounts
    ) internal {
        WithdrawState memory w;
        if (topcorn().balanceOf(address(this)) < al.topcornAmount) {
            w.topcornsTransferred = al.topcornAmount - s.topcorn.deposited;
            topcorn().transferFrom(msg.sender, address(this), w.topcornsTransferred);
        }
        (w.topcornsAdded, w.newLP) = LibMarket.addLiquidity(al); // w.topcornsAdded is topcorns added to LP
        require(w.newLP > 0, "Silo: No LP added.");
        (w.topcornsRemoved, w.stalkRemoved) = _withdrawTopcornsForConvert(crates, amounts, w.topcornsAdded); // w.topcornsRemoved is topcorns removed from Silo
        require(w.topcornsAdded >= w.topcornsRemoved, "Silo: Removed too many Topcorns.");
        uint256 amountFromWallet = w.topcornsAdded - w.topcornsRemoved;

        if (amountFromWallet < w.topcornsTransferred) {
            topcorn().transfer(msg.sender, w.topcornsTransferred - amountFromWallet);
        } else if (w.topcornsTransferred < amountFromWallet) {
            uint256 transferAmount = amountFromWallet - w.topcornsTransferred;
            LibMarket.allocateTopcorns(transferAmount);
        }

        require(LibTopcornBnb.lpToLPTopcorns(lp + w.newLP) > 0, "Silo: No LP Topcorns.");
        w.i = w.stalkRemoved / (LibTopcornBnb.lpToLPTopcorns(lp + w.newLP));
        uint32 depositSeason = season() - uint32(w.i / C.getSeedsPerLP());

        if (lp > 0) pair().transferFrom(msg.sender, address(this), lp);

        lp = lp + w.newLP;
        _depositLP(lp, LibTopcornBnb.lpToLPTopcorns(lp), depositSeason);
        LibSilo.updateBalanceOfRainStalk(msg.sender);
        LibMarket.refund();
        LibCheck.balanceCheck();
    }

    /**
     * Internal LP
     **/
    function _depositLP(
        uint256 amount,
        uint256 lpb,
        uint32 _s
    ) internal {
        require(lpb > 0, "Silo: No Topcorns under LP.");
        LibLPSilo.incrementDepositedLP(amount);
        uint256 seeds = lpb * C.getSeedsPerLP();
        if (season() == _s) LibSilo.depositSiloAssets(msg.sender, seeds, lpb * C.getStalkPerTopcorn());
        else LibSilo.depositSiloAssets(msg.sender, seeds, (lpb * C.getStalkPerTopcorn()) + (uint256(season() - _s) * (seeds)));

        LibLPSilo.addLPDeposit(msg.sender, _s, amount, lpb * (C.getSeedsPerLP()));
    }

    function _withdrawLPForConvert(
        uint32[] memory crates,
        uint256[] memory amounts,
        uint256 maxLP
    ) internal returns (uint256 lpRemoved, uint256 stalkRemoved) {
        require(crates.length == amounts.length, "Silo: Crates, amounts are diff lengths.");
        uint256 seedsRemoved;
        uint256 depositLP;
        uint256 depositSeeds;
        uint256 i = 0;
        while ((i < crates.length) && (lpRemoved < maxLP)) {
            if (lpRemoved + amounts[i] < maxLP) (depositLP, depositSeeds) = LibLPSilo.removeLPDeposit(msg.sender, crates[i], amounts[i]);
            else (depositLP, depositSeeds) = LibLPSilo.removeLPDeposit(msg.sender, crates[i], maxLP - lpRemoved);
            lpRemoved = lpRemoved + depositLP;
            seedsRemoved = seedsRemoved + depositSeeds;
            stalkRemoved = stalkRemoved + (depositSeeds * (C.getStalkPerLPSeed()) + (LibSilo.stalkReward(depositSeeds, season() - crates[i])));
            i++;
        }
        if (i > 0) amounts[i - 1] = depositLP;
        while (i < crates.length) {
            amounts[i] = 0;
            i++;
        }
        LibLPSilo.decrementDepositedLP(lpRemoved);
        LibSilo.withdrawSiloAssets(msg.sender, seedsRemoved, stalkRemoved);
        stalkRemoved = stalkRemoved - (seedsRemoved * C.getStalkPerLPSeed());
        emit LPRemove(msg.sender, crates, amounts, lpRemoved);
    }

    /**
     * Internal TopCorn
     **/

    function _depositTopcorns(uint256 amount, uint32 _s) internal {
        require(amount > 0, "Silo: No topcorns.");
        LibTopcornSilo.incrementDepositedTopcorns(amount);
        uint256 stalk = amount * C.getStalkPerTopcorn();
        uint256 seeds = amount * C.getSeedsPerTopcorn();
        if (_s < season()) stalk = stalk + (LibSilo.stalkReward(seeds, season() - _s));
        LibSilo.depositSiloAssets(msg.sender, seeds, stalk);
        LibTopcornSilo.addTopcornDeposit(msg.sender, _s, amount);
    }

    function _withdrawTopcornsForConvert(
        uint32[] memory crates,
        uint256[] memory amounts,
        uint256 maxTopcorns
    ) internal returns (uint256 topcornsRemoved, uint256 stalkRemoved) {
        require(crates.length == amounts.length, "Silo: Crates, amounts are diff lengths.");
        uint256 crateTopcorns;
        uint256 i = 0;
        while ((i < crates.length) && (topcornsRemoved < maxTopcorns)) {
            if (topcornsRemoved + amounts[i] < maxTopcorns) crateTopcorns = LibTopcornSilo.removeTopcornDeposit(msg.sender, crates[i], amounts[i]);
            else crateTopcorns = LibTopcornSilo.removeTopcornDeposit(msg.sender, crates[i], maxTopcorns - topcornsRemoved);
            topcornsRemoved = topcornsRemoved + crateTopcorns;
            stalkRemoved = stalkRemoved + (crateTopcorns * C.getStalkPerTopcorn() + (LibSilo.stalkReward(crateTopcorns * C.getSeedsPerTopcorn(), season() - crates[i])));
            i++;
        }
        if (i > 0) amounts[i - 1] = crateTopcorns;
        while (i < crates.length) {
            amounts[i] = 0;
            i++;
        }
        LibTopcornSilo.decrementDepositedTopcorns(topcornsRemoved);
        LibSilo.withdrawSiloAssets(msg.sender, topcornsRemoved * C.getSeedsPerTopcorn(), stalkRemoved);
        stalkRemoved = stalkRemoved - (topcornsRemoved * C.getStalkPerTopcorn());
        emit TopcornRemove(msg.sender, crates, amounts, topcornsRemoved);
        return (topcornsRemoved, stalkRemoved);
    }

    function reserves() internal view returns (uint256, uint256) {
        (uint112 reserve0, uint112 reserve1, ) = pair().getReserves();
        return s.index == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    function pair() internal view returns (IPancakePair) {
        return IPancakePair(s.c.pair);
    }

    function topcorn() internal view returns (ITopcorn) {
        return ITopcorn(s.c.topcorn);
    }

    function season() internal view returns (uint32) {
        return s.season.current;
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/pancake/IPancakePair.sol";
import "../interfaces/ITopcorn.sol";
import "../interfaces/IWBNB.sol";
import "./LibMarket.sol";
import "./LibAppStorage.sol";
import "./LibMath.sol";

/**
 * @author Publius
 * @title Lib Convert
 **/
library LibConvert {
    function sellToPegAndAddLiquidity(uint256 topcorns, uint256 minLP) internal returns (uint256 lp, uint256 topcornsConverted) {
        (uint256 bnbReserve, uint256 topcornReserve) = reserves();
        uint256 maxSellTopcorns = topcornsToPeg(bnbReserve, topcornReserve);
        require(maxSellTopcorns > 0, "Convert: P must be > 1.");
        uint256 sellTopcorns = calculateSwapInAmount(topcornReserve, topcorns);
        if (sellTopcorns > maxSellTopcorns) sellTopcorns = maxSellTopcorns;

        (uint256 TopcornsSold, uint256 wbnbBought) = LibMarket._sell(sellTopcorns, 1, address(this));
        (topcornsConverted, , lp) = LibMarket._addLiquidityWBNB(wbnbBought, topcorns - TopcornsSold, 1, 1);
        require(lp >= minLP, "Convert: Not enough LP.");
        topcornsConverted = topcornsConverted + TopcornsSold;
    }

    function removeLPAndBuyToPeg(uint256 lp, uint256 minTopcorns) internal returns (uint256 topcorns, uint256 lpConverted) {
        lpConverted = lpToPeg();
        require(lpConverted > 0, "Convert: P must be < 1.");
        if (lpConverted > lp) lpConverted = lp;

        (uint256 topcornsRemoved, uint256 bnbRemoved) = removeLiquidityToFarm(lpConverted);
        (, uint256 boughtTopcorns) = LibMarket._buyWithWBNB(1, bnbRemoved, address(this));
        topcorns = topcornsRemoved + boughtTopcorns;
        require(topcorns >= minTopcorns, "Convert: Not enough Topcorns.");
    }

    function removeLiquidityToFarm(uint256 liquidity) private returns (uint256 topcornAmount, uint256 bnbAmount) {
        LibMarket.DiamondStorage storage ds = LibMarket.diamondStorage();
        (topcornAmount, bnbAmount) = IPancakeRouter02(ds.router).removeLiquidity(ds.topcorn, ds.wbnb, liquidity, 1, 1, address(this), block.timestamp);
    }

    function topcornsToPeg(uint256 bnbTopcornPool, uint256 topcornsTopcornPool) internal view returns (uint256 topcorns) {
        (uint256 bnbBUSDPool, uint256 busdBUSDPool) = pegReserves();

        uint256 newTopcorns = LibMath.sqrt((bnbTopcornPool * topcornsTopcornPool * busdBUSDPool) / bnbBUSDPool);
        if (newTopcorns <= topcornsTopcornPool) return 0;
        topcorns = newTopcorns - topcornsTopcornPool;
        topcorns = (topcorns * 100000) / 99875;
    }

    /// @notice lpToPeg solves for the maximum amount ofDeposited  LP that can be converted into Deposited Topcorns
    /// @return lp - the quantity of LP that can be removed such that the bnb recieved
    /// from removing the LP is the exact amount to buy the TopCorn price back to its peg.
    function lpToPeg() internal view returns (uint256 lp) {
        /*
         * lpToPeg solves for the quantity of LP that can be removed such that the bnb recieved from removing the LP
         * is the exact amount to buy the Topcorn price back to its peg.
         * If the Topcorn price is the Topcorn:BNB Pancake V2 Pair is > $1, it will return 0
         * lpToPeg solves the follow system of equations for lp:
         *   lp = bnb * totalLP / e
         *   f * bnb = sqrt((e - bnb) * (b - topcorns) * y/x) - (e - bnb)
         * such that
         *   e / b = (e - bnb) / (b - topcorns)
         * given
         *   e, b - the BNB, Topcorn reserves in the BNB:Topcorn Pancake V2 Pair
         *   y, x - the BNB, USDC reserves in the BNB:USDC Pancake V2 Pair
         *   f - is the inverse of the 1 sided fee on Pancake (1 / 0.99875)
         *   totaLP is the total supply of LP tokens
         * where
         *   bnb, topcorns are the assets returned from removing lp liquidity token from the BNB:Topcorn Pancake V2 Pair
         *
         * The solution can be reduced to:
         *   lp = bnb * totalLP / e
         *   bnb = e (c - 1) / (c + f - 1)
         * such that
         *   c = sqrt((y * b) / (x * e))
         *
         *   0.99875 = 1 - 0.125%
         */

        (uint256 e, uint256 b) = reserves();
        (uint256 y, uint256 x) = pegReserves();
        uint256 c = LibMath.sqrt((y * b * 1e18) / (x * e)) * 1e9;
        if (c <= 1e18) return 0;
        uint256 num = e * (c - 1e18);
        uint256 denom = c - 1251564455569461; // 0.1251564455569461 ~= f - 1 = (1 / 0.99875 - 1)
        uint256 bnb = num / denom;
        return (bnb * totalLP()) / e;
    }

    /**
     * Shed
     **/

    function calculateSwapInAmount(uint256 reserveIn, uint256 amountIn) private pure returns (uint256) {
        return (LibMath.sqrt(reserveIn * (amountIn * 399000000 + reserveIn * 399000625)) - (reserveIn * 19975)) / 19950;
    }

    function totalLP() private view returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return IPancakePair(s.c.pair).totalSupply();
    }

    // (BNB, topcorns)
    function reserves() private view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(s.c.pair).getReserves();
        return s.index == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }

    // (BNB, BUSD)
    function pegReserves() private view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        (uint112 reserve0, uint112 reserve1, ) = IPancakePair(s.c.pegPair).getReserves();
        return s.pegIndex == 0 ? (reserve1, reserve0) : (reserve0, reserve1);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

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
 * @author Publius
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

    /// @notice Internal function that handles the business logic of the removal of pods from a specified account's plot.
    /// @param account address of the account to remove pods from
    /// @param findIndex pod index for find in plotsIndexes
    /// @param newIndex new pod index if replace
    /// @param flag delete/replace index (delete - 0, replace - 1)
    function _removeIndex(
        address account,
        uint256 findIndex,
        uint256 newIndex,
        bool flag
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 curIndex;
        uint256 nextIndex;

        uint256 countPod = s.countPods[account];
        require(countPod != 0, "No plots for account");

        curIndex = s.firstPods[account];
        if (countPod == 1) {
            require(curIndex == findIndex, "Not found plot");
            if (flag) {
                s.firstPods[account] = newIndex;
            } else {
                s.countPods[account]--;
                s.firstPods[account] = 0;
            }
        } else {
            nextIndex = s.plotsIndexes[account][curIndex];
            if (curIndex == findIndex) {
                // if begin
                if (flag) {
                    s.firstPods[account] = newIndex;
                    s.plotsIndexes[account][newIndex] = nextIndex;
                } else {
                    s.firstPods[account] = nextIndex;
                    s.countPods[account]--;
                }
            } else {
                // if end
                uint256 iter = 0;
                while (iter < countPod - 2 && nextIndex != findIndex) {
                    // find id
                    iter++;
                    curIndex = s.plotsIndexes[account][curIndex];
                    nextIndex = s.plotsIndexes[account][curIndex];
                }
                require(nextIndex == findIndex, "Not found plot");
                if (flag) {
                    s.plotsIndexes[account][curIndex] = newIndex;
                    s.plotsIndexes[account][newIndex] = s.plotsIndexes[account][nextIndex];
                } else {
                    s.countPods[account]--;
                    s.plotsIndexes[account][curIndex] = s.plotsIndexes[account][nextIndex];
                }
            }
            delete s.plotsIndexes[account][findIndex];
        }
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
        if (harvestablePods >= pods) {
            _removeIndex(account, plotId, 0, false);
            return pods;
        }
        _removeIndex(account, plotId, plotId + harvestablePods, true);
        s.a[account].field.plots[plotId + harvestablePods] = pods - harvestablePods;
        return harvestablePods;
    }

    function cancelPodListing(uint256 index) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        delete s.podListings[index];
        emit PodListingCancelled(msg.sender, index);
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../C.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib Silo
 **/
library LibSilo {
    using Decimal for Decimal.D256;

    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);

    /**
     * Silo
     **/

    function depositSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        incrementBalanceOfStalk(account, stalk);
        incrementBalanceOfSeeds(account, seeds);
    }

    function withdrawSiloAssets(
        address account,
        uint256 seeds,
        uint256 stalk
    ) internal {
        decrementBalanceOfStalk(account, stalk);
        decrementBalanceOfSeeds(account, seeds);
    }

    function incrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds + seeds;
        s.a[account].s.seeds = s.a[account].s.seeds + seeds;
    }

    function incrementBalanceOfStalk(address account, uint256 stalk) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 roots;
        if (s.s.roots == 0) roots = stalk * C.getRootsBase();
        else roots = (s.s.roots * stalk) / s.s.stalk;

        s.s.stalk = s.s.stalk + stalk;
        s.a[account].s.stalk = s.a[account].s.stalk + stalk;

        s.s.roots = s.s.roots + roots;
        s.a[account].roots = s.a[account].roots + roots;
    }

    function decrementBalanceOfSeeds(address account, uint256 seeds) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.s.seeds = s.s.seeds - seeds;
        s.a[account].s.seeds = s.a[account].s.seeds - seeds;
    }

    function decrementBalanceOfStalk(address account, uint256 stalk) private {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (stalk == 0) return;
        uint256 roots = (s.a[account].roots * stalk - 1) / s.a[account].s.stalk + 1;

        s.s.stalk = s.s.stalk - stalk;
        s.a[account].s.stalk = s.a[account].s.stalk - stalk;

        s.s.roots = s.s.roots - roots;
        s.a[account].roots = s.a[account].roots - roots;
    }

    function updateBalanceOfRainStalk(address account) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        if (!s.r.raining) return;
        if (s.a[account].roots < s.a[account].sop.roots) {
            s.r.roots = s.r.roots - (s.a[account].sop.roots - s.a[account].roots);
            s.a[account].sop.roots = s.a[account].roots;
        }
    }

    function stalkReward(uint256 seeds, uint32 seasons) internal pure returns (uint256) {
        return seeds * seasons;
    }

    function season() internal view returns (uint32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.season.current;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity = 0.8.16;

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

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib TopCorn Silo
 **/
library LibTopcornSilo {
    event TopcornDeposit(address indexed account, uint256 season, uint256 topcorns);

    function addTopcornDeposit(
        address account,
        uint32 _s,
        uint256 amount
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].topcorn.deposits[_s] += amount;
        emit TopcornDeposit(account, _s, amount);
    }

    function removeTopcornDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) internal returns (uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(id <= s.season.current, "Silo: Future crate.");
        uint256 crateAmount = s.a[account].topcorn.deposits[id];
        require(crateAmount >= amount, "Silo: Crate balance too low.");
        require(crateAmount > 0, "Silo: Crate empty.");
        s.a[account].topcorn.deposits[id] -= amount;
        return amount;
    }

    function incrementDepositedTopcorns(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.topcorn.deposited = s.topcorn.deposited + amount;
    }

    function decrementDepositedTopcorns(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.topcorn.deposited = s.topcorn.deposited - amount;
    }
}

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "../../interfaces/pancake/IPancakePair.sol";
import "../LibAppStorage.sol";

/**
 * @author Publius
 * @title Lib LP Silo
 **/
library LibLPSilo {

    event LPDeposit(address indexed account, uint256 season, uint256 lp, uint256 seeds);

    function incrementDepositedLP(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.lp.deposited = s.lp.deposited + amount;
    }

    function decrementDepositedLP(uint256 amount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.lp.deposited = s.lp.deposited - amount;
    }

    function addLPDeposit(
        address account,
        uint32 _s,
        uint256 amount,
        uint256 seeds
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.a[account].lp.deposits[_s] += amount;
        s.a[account].lp.depositSeeds[_s] += seeds;
        emit LPDeposit(msg.sender, _s, amount, seeds);
    }

    function removeLPDeposit(
        address account,
        uint32 id,
        uint256 amount
    ) internal returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(id <= s.season.current, "Silo: Future crate.");
        (uint256 crateAmount, uint256 crateBase) = lpDeposit(account, id);
        require(crateAmount >= amount, "Silo: Crate balance too low.");
        require(crateAmount > 0, "Silo: Crate empty.");
        if (amount < crateAmount) {
            uint256 base = (amount * crateBase) / crateAmount;
            s.a[account].lp.deposits[id] -= amount;
            s.a[account].lp.depositSeeds[id] -= base;
            return (amount, base);
        } else {
            delete s.a[account].lp.deposits[id];
            delete s.a[account].lp.depositSeeds[id];
            return (crateAmount, crateBase);
        }
    }

    function lpDeposit(address account, uint32 id) private view returns (uint256, uint256) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.a[account].lp.deposits[id], s.a[account].lp.depositSeeds[id]);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "../interfaces/pancake/IPancakePair.sol";
import "./LibAppStorage.sol";
import "../interfaces/ITopcorn.sol";

/**
 * @author Publius
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

import "../interfaces/pancake/IPancakeRouter02.sol";
import "../interfaces/ITopcorn.sol";
import "../interfaces/IWBNB.sol";
import "./LibAppStorage.sol";
import "./LibClaim.sol";

/**
 * @author Publius
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

import "./interfaces/pancake/IPancakePair.sol";
import "./interfaces/ITopcorn.sol";
import "./libraries/Decimal.sol";

/**
 * @author Publius
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
    address private constant PEG_PAIR = address(0x4E99615101cCBB83A462dC4DE2bc1362EF1365e5);
    address private constant BUSD_TOKEN = address(0x1f9840a85d5aF5bf1D1762F925BDADdC4201F984); // uniswap token

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

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity = 0.8.16;

import "./LibAppStorage.sol";
import "./PancakeOracleLibrary.sol";
import "./LibMath.sol";

/**
 * @author Publius
 * @title Lib TopCorn BNB V2 Silo
 **/
library LibTopcornBnb {
    uint256 private constant TWO_TO_THE_112 = 2**112;

    function lpToLPTopcorns(uint256 amount) internal view returns (uint256 topcorns) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (uint112 reserve0, uint112 reserve1, uint32 lastTimestamp) = IPancakePair(s.c.pair).getReserves();

        uint256 topcornReserve;

        // Check the last timestamp in the Pancake Pair to see if anyone has interacted with the pair this block.
        // If so, use current Season TWAP to calculate TopCorn Reserves for flash loan protection
        // If not, we can use the current reserves with the assurance that there is no active flash loan
        if (lastTimestamp == uint32(block.timestamp % 2**32)) topcornReserve = twapTopcornReserve(reserve0, reserve1, lastTimestamp);
        else topcornReserve = s.index == 0 ? reserve0 : reserve1;
        topcorns = (amount * topcornReserve * 2) / (IPancakePair(s.c.pair).totalSupply());
    }

    function twapTopcornReserve(
        uint112 reserve0,
        uint112 reserve1,
        uint32 lastTimestamp
    ) internal view returns (uint256 topcorns) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        (uint256 price0Cumulative, uint256 price1Cumulative, uint32 blockTimestamp) = PancakeOracleLibrary.currentCumulativePricesWithReserves(s.c.pair, reserve0, reserve1, lastTimestamp);
        uint256 priceCumulative = s.index == 0 ? price0Cumulative : price1Cumulative;
        uint32 deltaTimestamp = uint32(blockTimestamp - s.o.timestamp);
        require(deltaTimestamp > 0, "Silo: Oracle same Season");
        uint256 price = (priceCumulative - s.o.cumulative) / deltaTimestamp;
        price = price / (TWO_TO_THE_112);
        topcorns = LibMath.sqrt((uint256(reserve0) * (uint256(reserve1))) / price);
    }
}

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;

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

pragma solidity = 0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
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
 * @author Publius
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

    // SiloSettings stores the settings for each Token that has been Whitelisted into the Silo.
    // A Token is considered whitelisted in the Silo if there exists a non-zero SiloSettings selector.
    struct SiloSettings {
        bytes4 selector; // The encoded TDV function selector for the Token.
        uint32 seeds; // The Seeds Per TDV that the Silo mints in exchange for Depositing this Token.
        uint32 stalk; // The Stalk Per TDV that the Silo mints in exchange for Depositing this Token.
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
    mapping(address => Storage.AssetSilo) siloBalances; // A mapping from Token address to Silo Balance storage (amount deposited and withdrawn).
    mapping(address => Storage.SiloSettings) ss;  // A mapping from Token address to Silo Settings for each Whitelisted Token. If a non-zero storage exists, a Token is whitelisted.
    // These refund variables are intra-transaction state varables use to store refund amounts
    uint256 refundStatus;
    uint256 topcornRefundAmount;
    uint256 bnbRefundAmount;
    uint8 pegIndex; // The index of the BUSD token in the BUSD:BNB PancakeSwap v2 pool

    mapping(address => mapping(uint256 => uint256))  plotsIndexes; // output index plots for user
    mapping(address => uint256) firstPods; // begin plot for user
    mapping(address => uint256) countPods; // count plots for user
    
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity = 0.8.16;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @author Publius
 * @title WBNB Interface
 **/
interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
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

/*
 SPDX-License-Identifier: MIT
*/

pragma solidity >=0.5.16;

import '../interfaces/pancake/IPancakePair.sol';
import "@uniswap/lib/contracts/libraries/FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library PancakeOracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2**32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(address pair)
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IPancakePair(pair).getReserves();
        return currentCumulativePricesWithReserves(pair, reserve0, reserve1, blockTimestampLast);
    }

    function currentCumulativePricesWithReserves(
        address pair,
        uint112 reserve0,
        uint112 reserve1,
        uint32 blockTimestampLast
    )
        internal
        view
        returns (
            uint256 price0Cumulative,
            uint256 price1Cumulative,
            uint32 blockTimestamp
        )
    {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IPancakePair(pair).price0CumulativeLast();
        price1Cumulative = IPancakePair(pair).price1CumulativeLast();

        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

import './Babylonian.sol';

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint private constant Q112 = uint(1) << RESOLUTION;
    uint private constant Q224 = Q112 << RESOLUTION;

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function div(uq112x112 memory self, uint112 x) internal pure returns (uq112x112 memory) {
        require(x != 0, 'FixedPoint: DIV_BY_ZERO');
        return uq112x112(self._x / uint224(x));
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint y) internal pure returns (uq144x112 memory) {
        uint z;
        require(y == 0 || (z = uint(self._x) * y) / y == uint(self._x), "FixedPoint: MULTIPLICATION_OVERFLOW");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // equivalent to encode(numerator).div(denominator)
    function fraction(uint112 numerator, uint112 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint: DIV_BY_ZERO");
        return uq112x112((uint224(numerator) << RESOLUTION) / denominator);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // take the reciprocal of a UQ112x112
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint: ZERO_RECIPROCAL');
        return uq112x112(uint224(Q224 / self._x));
    }

    // square root of a UQ112x112
    function sqrt(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(Babylonian.sqrt(uint256(self._x)) << 56));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.4.0;

// computes square roots using the babylonian method
// https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method
library Babylonian {
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}