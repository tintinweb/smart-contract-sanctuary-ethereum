/**
 *Submitted for verification at Etherscan.io on 2021-03-11
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


interface IUniswapV2Router02 {
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

interface IArbMemory {
	function setUint(uint256 id_, uint256 val_) external;
	function getUint(uint256 id_, uint256 val_) external returns (uint256 num_);
}

// 
interface IERC20 {
	function approve(address spender, uint256 amount) external returns (bool);
	function balanceOf(address account) external view returns (uint256);
}

contract Uniswap {

	IArbMemory constant public arbMemory = IArbMemory(address(0xb5bEf49e11220fddFe7Dfc34298A90948bb9A4b4));

	function getTokenForETH(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
	{
		amountIn_ = arbMemory.getUint(getId_, amountIn_);
		require (address(this).balance >= amountIn_, "in amount is greater balance");
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactETHForTokens{value: amountIn_}
		(
			amountOutMin_, 
			path_, 
			address(this), 
			block.timestamp
		);
		arbMemory.setUint(setId_, _amounts[_amounts.length - 1]);
	}
	
	function getETHForToken(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
	{
		IERC20 token = IERC20(path_[0]);
		amountIn_ = arbMemory.getUint(getId_, amountIn_);
		require (token.balanceOf(address(this)) >= amountIn_, "in amount is greater balance");
		token.approve(address(IUniswapV2Router02(router_)), amountIn_);
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactTokensForETH
		(
			amountIn_,
			amountOutMin_,
			path_,
			address(this),
			block.timestamp
		);
		arbMemory.setUint(setId_, _amounts[_amounts.length - 1]);
	}
	
	function getTokenForToken(
		address router_,
		uint256 amountIn_,
		uint256 amountOutMin_,
		address[] calldata path_,
		uint256 getId_,
		uint256 setId_
	)
		external 
		returns (uint256)
	{
		IERC20 token = IERC20(path_[0]);
		amountIn_ = arbMemory.getUint(getId_, amountIn_);
		require (token.balanceOf(address(this)) >= amountIn_, "in amount is greater balance");
		token.approve(address(IUniswapV2Router02(router_)), amountIn_);
		uint[] memory _amounts = IUniswapV2Router02(router_).swapExactTokensForTokens(
			amountIn_,
			amountOutMin_, 
			path_,
			address(this),
			block.timestamp
		);
		arbMemory.setUint(setId_, _amounts[_amounts.length - 1]);
	}

}