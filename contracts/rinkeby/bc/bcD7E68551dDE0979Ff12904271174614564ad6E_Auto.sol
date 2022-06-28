// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '../interfaces/IERC20.sol';
import '../interfaces/IDelegate.sol';
import '../interfaces/IPlatform.sol';


contract Auto {
    uint256 public allowance;
    constructor(address tomi, address stableCoinAddress, uint amountTomiPool, uint amountStablePool, address delegateAddress, 
        address lpAddress, bool buyTomi, uint256 amountUSwap, address wethAddress, address sushiRouter, address tomiPlatform) {

        address tomiAddress = tomi;
        address stableCoinAddressLocal = stableCoinAddress;
        uint256 totalTransaferUsd = 1;
        uint256 amountStablePoolLocal = amountStablePool;
        uint256 amountUSwapLocal = amountUSwap;
        uint256 amountTomiPoolLocal = amountTomiPool;
        address delegateAddressLocal = delegateAddress;
        address lpAddressLocal = lpAddress;

        allowance = IERC20(stableCoinAddressLocal).allowance(msg.sender, address(this));
        // IERC20(stableCoinAddressLocal).transferFrom(msg.sender, address(this), totalTransaferUsd);
        
        // uint256 amountApprove = 99999999999999999999999;
        // if(amountTomiPoolLocal > 0) {
        //     IERC20(tomiAddress).transferFrom(msg.sender, address(this), amountTomiPoolLocal);

        //     IERC20(tomiAddress).approve(delegateAddressLocal, amountApprove);
        //     IERC20(stableCoinAddressLocal).approve(delegateAddressLocal, amountApprove);

        //     // TO DO: check number of LP return
        //     ITomiDelegate(delegateAddressLocal).addLiquidity(tomiAddress, stableCoinAddressLocal, amountTomiPoolLocal, amountStablePoolLocal, 0, 0, block.timestamp + 3 hours);
        // }


        // address[] memory pathStableCointoWeth = new address[](2);
        // pathStableCointoWeth[0] = stableCoinAddressLocal;
        // pathStableCointoWeth[1] = wethAddress;

        // address[] memory pathWethToStableCoin = new address[](2);
        // pathWethToStableCoin[0] = wethAddress;
        // pathWethToStableCoin[1] = stableCoinAddressLocal;
        // // Swap
        // if(buyTomi) {

        //     // swap on Tomi
        //     IERC20(stableCoinAddressLocal).approve(tomiPlatform, amountApprove);
        //     ITomiPlatform(tomiPlatform).swapExactTokensForTokens(amountUSwapLocal, 0, pathStableCointoWeth, address(this), block.timestamp + 3 hours);
        //     uint256 balanceWeth = IERC20(wethAddress).balanceOf(address(this));

        //     IERC20(wethAddress).approve(sushiRouter, amountApprove);
        //     ITomiDelegate(sushiRouter).swapExactTokensForTokens(balanceWeth, 0, pathWethToStableCoin, address(this), block.timestamp + 3 hours);
        // } else {
        //     // swap on sushi first
        //     IERC20(stableCoinAddressLocal).approve(sushiRouter, amountApprove);
        //     ITomiDelegate(sushiRouter).swapExactTokensForTokens(amountUSwapLocal, 0, pathStableCointoWeth, address(this), block.timestamp + 3 hours);

        //     uint256 balanceWeth = IERC20(wethAddress).balanceOf(address(this));
        //     IERC20(wethAddress).approve(tomiPlatform, amountApprove);
        //     ITomiPlatform(tomiPlatform).swapExactTokensForTokens(balanceWeth, 0, pathWethToStableCoin, address(this), block.timestamp + 3 hours);

        // }
        
        
        // // Remove Liquidity
        // uint256 balanceLp = IERC20(lpAddressLocal).balanceOf(address(this));
        // if (balanceLp > 0) {
        //      ITomiDelegate(delegateAddressLocal).removeLiquidity(tomiAddress, stableCoinAddressLocal, balanceLp, 0, 0, block.timestamp + 3 hours);
        // }

        
        // uint256 balanceTomi = IERC20(tomiAddress).balanceOf(address(this));
        // uint256 balanceStableCoin = IERC20(stableCoinAddressLocal).balanceOf(address(this));

        // if(balanceTomi > 0) {
        //     IERC20(tomiAddress).transfer(msg.sender, balanceTomi);
        // }
        // // // return to owner
        
        // require(balanceStableCoin > (amountStablePoolLocal + amountUSwapLocal), "This trans will lose money"); 
        // IERC20(stableCoinAddressLocal).transfer(msg.sender, balanceStableCoin);
       
        // address payable addr = payable(address(msg.sender));
        // selfdestruct(addr);
    }
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface ITomiDelegate {

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline) external returns (
            uint256 _amountA,
            uint256 _amountB
    );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.6;

interface ITomiPlatform {
    event AddLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event RemoveLiquidity(
        address indexed player,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );
    event SwapToken(
        address indexed receiver,
        address indexed fromToken,
        address indexed toToken,
        uint256 inAmount,
        uint256 outAmount
    );

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 deadline
    )
        external
        returns (
            uint256 _amountA,
            uint256 _amountB,
            uint256 _liquidity
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}