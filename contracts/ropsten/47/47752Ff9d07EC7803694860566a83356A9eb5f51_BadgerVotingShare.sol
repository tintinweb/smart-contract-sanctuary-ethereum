// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "ISett.sol";
import "IGeyser.sol";
import "IUniswapV2Pair.sol";
import "ICToken.sol";
import "IBridgePool.sol";
import "ICurvePool.sol";
import "ICurveToken.sol";

contract BadgerVotingShare {
    IERC20 constant badger = IERC20(0x3472A5A71965499acd81997a54BBA8D852C6E53d);
    ISett constant sett_badger =
        ISett(0x19D97D8fA813EE2f51aD4B4e04EA08bAf4DFfC28);
    IGeyser constant geyser_badger =
        IGeyser(0xa9429271a28F8543eFFfa136994c0839E7d7bF77);
    ISett constant rem_badger = ISett(0x6aF7377b5009d7d154F36FE9e235aE1DA27Aea22);

    //Badger is token1
    IUniswapV2Pair constant badger_wBTC_UniV2 =
        IUniswapV2Pair(0xcD7989894bc033581532D2cd88Da5db0A4b12859);
    ISett constant sett_badger_wBTC_UniV2 =
        ISett(0x235c9e24D3FB2FAFd58a2E49D454Fdcd2DBf7FF1);
    IGeyser constant geyser_badger_wBTC_UniV2 =
        IGeyser(0xA207D69Ea6Fb967E54baA8639c408c31767Ba62D);

    //Badger is token1
    IUniswapV2Pair constant badger_wBTC_SLP =
        IUniswapV2Pair(0x110492b31c59716AC47337E616804E3E3AdC0b4a);
    ISett constant sett_badger_wBTC_SLP =
        ISett(0x1862A18181346EBd9EdAf800804f89190DeF24a5);
    IGeyser constant geyser_badger_wBTC_SLP =
        IGeyser(0xB5b654efBA23596Ed49FAdE44F7e67E23D6712e7); 

    // Rari pool - fBADGER-22
    ICToken constant fBADGER =
        ICToken(0x6780B4681aa8efE530d075897B3a4ff6cA5ed807);

    IBridgePool constant aBADGER = IBridgePool(0x43298F9f91a4545dF64748e78a2c777c580573d6);

    ICurvePool constant badger_wBTC_crv_pool =
        ICurvePool(0x50f3752289e1456BfA505afd37B241bca23e685d);
    ICurveToken constant badger_wBTC_crv_token = 
        ICurveToken(0x137469B55D1f15651BA46A89D0588e97dD0B6562);
    ISett constant sett_badger_wBTC_crv =
        ISett(0xeC1c717A3b02582A4Aa2275260C583095536b613);

    function decimals() external pure returns (uint8) {
        return uint8(18);
    }

    function name() external pure returns (string memory) {
        return "Badger Voting Share";
    }

    function symbol() external pure returns (string memory) {
        return "Badger VS";
    }

    function totalSupply() external view returns (uint256) {
        return badger.totalSupply();
    }

    function uniswapBalanceOf(address _voter) external view returns(uint256) {
        return _uniswapBalanceOf(_voter);
    }
    function sushiswapBalanceOf(address _voter) external view returns(uint256) {
        return _sushiswapBalanceOf(_voter);
    }
    function badgerBalanceOf(address _voter) external view returns(uint256) {
        return _badgerBalanceOf(_voter);
    }
    function rariBalanceOf(address _voter) external view returns(uint256) {
        return _rariBalanceOf(_voter);
    }
    function remBadgerBalanceOf(address _voter) external view returns(uint256) {
        return _remBadgerBalanceOf(_voter);
    }
    function acrossBalanceOf(address _voter) external view returns(uint256) {
        return _acrossBalanceOf(_voter);
    }
    function curveBalanceOf(address _voter) external view returns(uint256) {
        return _curveBalanceOf(_voter);
    }

    /*
        The voter can have Badger in Uniswap in 3 configurations:
         * Staked bUni-V2 in Geyser
         * Unstaked bUni-V2 (same as staked Uni-V2 in Sett)
         * Unstaked Uni-V2
        The top two correspond to more than 1 Uni-V2, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much BADGER it corresponds to using the pool's reserves.
    */
    function _uniswapBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bUniV2PricePerShare = sett_badger_wBTC_UniV2
            .getPricePerFullShare();
        (, uint112 reserve1, ) = badger_wBTC_UniV2.getReserves();
        uint256 totalUniBalance = badger_wBTC_UniV2.balanceOf(_voter) +
            (sett_badger_wBTC_UniV2.balanceOf(_voter) * bUniV2PricePerShare) /
            1e18 +
            (geyser_badger_wBTC_UniV2.totalStakedFor(_voter) *
                bUniV2PricePerShare) /
            1e18;
        return (totalUniBalance * reserve1) / badger_wBTC_UniV2.totalSupply();
    }

    /*
        The voter can have Badger in Sushi in 3 configurations:
         * Staked SLP in Geyser
         * Unstaked SLP (same as staked SLP in Sett)
         * Unstaked SLP
        The top two correspond to more than 1 SLP, so they are multiplied by pricePerFullShare.
        After adding all 3 balances we calculate how much BADGER it corresponds to using the pool's reserves.
    */
    function _sushiswapBalanceOf(address _voter)
        internal
        view
        returns (uint256)
    {
        uint256 bSLPPricePerShare = sett_badger_wBTC_SLP.getPricePerFullShare();
        (, uint112 reserve1, ) = badger_wBTC_SLP.getReserves();
        uint256 totalSLPBalance = badger_wBTC_SLP.balanceOf(_voter) +
            (sett_badger_wBTC_SLP.balanceOf(_voter) * bSLPPricePerShare) /
            1e18 +
            (geyser_badger_wBTC_SLP.totalStakedFor(_voter) *
                bSLPPricePerShare) /
            1e18;
        return (totalSLPBalance * reserve1) / badger_wBTC_SLP.totalSupply();
    }

    /*
        The voter can have Badger in Curve in 2 configurations:
         * Curve LP in vault
         * Curve LP in wallet
        Vaults have an additional PPFS that we need to take into account
        After adding the 2 balances we calculate how much BADGER it corresponds to using the pool's reserves.
    */
    function _curveBalanceOf(address _voter)
        internal
        view
        returns (uint256)
    {
        // coin 0 is BADGER
        uint256 bCrvPricePerShare = sett_badger_wBTC_crv.getPricePerFullShare();
        uint256 poolBadgerBalance = badger_wBTC_crv_pool.balances(0);
        uint256 voterLpBalance = badger_wBTC_crv_token.balanceOf(_voter) +
            (sett_badger_wBTC_crv.balanceOf(_voter) * bCrvPricePerShare) /
            1e18;
        return voterLpBalance * poolBadgerBalance / badger_wBTC_crv_token.totalSupply();
    }

    /*
        The voter can have regular Badger in 3 configurations as well:
         * Staked bBadger in Geyser
         * Unstaked bBadger (same as staked Badger in Sett)
         * Unstaked Badger
    */
    function _badgerBalanceOf(address _voter) internal view returns (uint256) {
        uint256 bBadgerPricePerShare = sett_badger.getPricePerFullShare();
        return
            badger.balanceOf(_voter) +
            (sett_badger.balanceOf(_voter) * bBadgerPricePerShare) /
            1e18 +
            (geyser_badger.totalStakedFor(_voter) * bBadgerPricePerShare) /
            1e18;
    }

    /*
        The voter can also have remBADGER
    */
    function _remBadgerBalanceOf(address _voter) internal view returns (uint256) {
        uint256 remBadgerPricePerShare = rem_badger.getPricePerFullShare();
        return (rem_badger.balanceOf(_voter) * remBadgerPricePerShare) / 1e18;
    }

    /*
        The voter may have deposited BADGER into the rari pool:
         * check current rate
         * balanceOf fBadger
    */
    function _rariBalanceOf(address _voter) internal view returns (uint256) {
        uint256 rate = fBADGER.exchangeRateStored();
        return (fBADGER.balanceOf(_voter) * rate) / 1e18;
    }

    /*
        The voter may have deposited BADGER into the across pool:
    */
    function _acrossBalanceOf(address _voter) internal view returns (uint256) {
        int256 numerator = int256(aBADGER.liquidReserves()) + int256(aBADGER.utilizedReserves()) - int256(aBADGER.undistributedLpFees());
        uint256 exchangeRateCurrent = (uint256(numerator) * 1e18) / aBADGER.totalSupply();
        
        return exchangeRateCurrent * aBADGER.balanceOf(_voter) / 1e18;
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return
            _badgerBalanceOf(_voter) +
            _uniswapBalanceOf(_voter) +
            _sushiswapBalanceOf(_voter) +
            _rariBalanceOf(_voter) +
            _remBadgerBalanceOf(_voter) +
            _acrossBalanceOf(_voter);
    }

    constructor() {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISett {
    function totalSupply() external view returns (uint256);

    function balance() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function deposit(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGeyser {
    function totalStakedFor(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IUniswapV2Pair {
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICToken {
    function balanceOf(address owner) external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBridgePool {
    function liquidReserves() external view returns (uint256);
    function utilizedReserves() external view returns (uint256);
    function undistributedLpFees() external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function addLiquidity(uint256 l1TokenAmount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurvePool {
    function balances(uint256) external pure returns (uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 deadline) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurveToken {
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}