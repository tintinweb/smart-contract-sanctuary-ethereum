// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IFeeHandler.sol";

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

    function getAmountsIn(
        uint256 amountOut,
        address[] calldata path
    ) external pure returns(uint256[] memory);

    function getAmountsOut(
        uint256 amountIn,
        address[] calldata path
    ) external pure returns(uint256[] memory);
}

contract FeeHandler is IFeeHandler {
    /*
        Marketplace tax,
        Hunting tax,
        Damage for legions,
        Summon fee,
        14 Days Hunting Supplies Discounted Fee,
        28 Days Hunting Supplies Discounted Fee
    */
    address constant BUSD = 0x07de306FF27a2B630B1141956844eB1552B956B5;
    address constant BLST = 0xd8344cc7fEbce19C2182988Ad219cF3553664356;
    uint[6] fees = [1500,250,100,18,13,24];
    address legion;
    IDEXRouter public router;
    modifier onlyLegion() {
        require(msg.sender == legion); _;
    }
    constructor() {
        legion = msg.sender;
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    }
    function getFee(uint8 _index) external view override returns (uint) {
        return fees[_index];
    }
    function setFee(uint _fee, uint8 _index) external override onlyLegion {
        require(_index>=0 && _index<6, "Unknown fee type");
        fees[_index] = _fee;
    }

    function getSummoningPrice(uint256 _amount) external view override returns(uint256) {
        uint256 UsdValue = fees[3];
        uint256 amountIn;
        if(_amount==1) {
            amountIn = UsdValue*10**6;
        } else if(_amount==10) {
            amountIn = UsdValue*10*99*10**4;
        } else if(_amount==50) {
            amountIn = UsdValue*50*98*10**4;
        } else if(_amount==100) {
            amountIn = UsdValue*100*97*10**4;
        } else if(_amount==150) {
            amountIn = UsdValue*150*95*10**4;
        } else {
            amountIn = UsdValue*_amount*10**6;
        }
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(amountIn, path)[1];
    }
    function getTrainingCost(uint256 _count) external view override returns(uint256) {
        if(_count==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_count*(10**6)/2, path)[1];
    }
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==0) return 0;
        if(_supply==7) {
            return getBLSTAmount(7*_warriorCount);
        } else if(_supply==14) {
            return getBLSTAmount(fees[4]*_warriorCount);
        } else if (_supply==28) {
            return getBLSTAmount(fees[5]*_warriorCount);
        } else {
            return getBLSTAmount(_supply*_warriorCount);
        }
    }

    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view override returns(uint256) {
        if(_supply==7) {
            return 7*_warriorCount*10000;
        } else if(_supply==14) {
            return fees[4]*_warriorCount*10000;
        } else if (_supply==28) {
            return fees[5]*_warriorCount*10000;
        } else {
            return _supply*_warriorCount*10000;
        }
    }

    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view override returns(uint256) {
        if(_warriorCount==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut((_remainingHunts*_warriorCount)*10**6+_warriorCount*10**6/2, path)[1];
    }
    function getBLSTAmountFromUSD(uint256 _usd) external view override returns(uint256) {
        return getBLSTAmount(_usd);
    }
    function getUSDAmountInBLST(uint256 _blst) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTAmount(uint256 _usd) internal view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_usd*10**6, path)[1];
    }
    function getUSDAmountFromBLST(uint256 _blst) external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BLST;
        path[1] = BUSD;
        return router.getAmountsOut(_blst, path)[1];
    }
    function getBLSTReward(uint256 _reward) external view override returns(uint256) {
        if(_reward==0) return 0;
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(_reward*10**2, path)[1];
    }
    function getExecuteAmount() external view override returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(fees[3]*10**6*2/10, path)[1]; // 20% will return back to player
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
    function getSummoningPrice(uint256 _amount) external view returns(uint256);
    function getTrainingCost(uint256 _count) external view returns(uint256);
    function getBLSTAmountFromUSD(uint256 _usd) external view returns(uint256);
    function getSupplyCost(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getSupplyCostInUSD(uint256 _warriorCount, uint256 _supply) external view returns(uint256);
    function getCostForAddingWarrior(uint256 _warriorCount, uint256 _remainingHunts) external view returns(uint256);
    function getBLSTReward(uint256 _reward) external view returns(uint256);
    function getExecuteAmount() external view returns(uint256);
    function getUSDAmountInBLST(uint256 _blst) external view returns(uint256);
    function getUSDAmountFromBLST(uint256 _blst) external view returns(uint256);
}