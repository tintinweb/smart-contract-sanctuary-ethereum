// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

interface IUniswap {
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom( address from, address to, uint256 amount ) external returns (bool);
}

contract TestAddLiquidity {

    address internal constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Ropsten
    address internal constant token_ADDRESS = 0x0A1acab1280d878f868E0c84fA1976f1DDc1974D;


    IUniswap public uniswap;
    IERC20 public token;

    constructor() public {
        uniswap = IUniswap(UNISWAP_ROUTER_ADDRESS);
        token = IERC20(token_ADDRESS);
    }

    
    function addLiq() external payable {
     
        token.transferFrom(token_ADDRESS, address(this), msg.value);

        token.approve(UNISWAP_ROUTER_ADDRESS, msg.value);

        uniswap.addLiquidityETH{ value: msg.value }(
            token_ADDRESS,
            msg.value,
            1,
            1,
            address(this),
            block.timestamp
        );
    }
      
}