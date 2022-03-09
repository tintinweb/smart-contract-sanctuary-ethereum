// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./IFeeHandler.sol";

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

    function getSummoningPrice() external view returns(uint256) {
        address[] memory path = new address[](2);
        path[0] = BUSD;
        path[1] = BLST;
        return router.getAmountsOut(fees[3]*10**6, path)[1];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IFeeHandler {
    function getFee(uint8 _index) external view returns(uint);
    function setFee(uint _fee, uint8 _index) external;
}