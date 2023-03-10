/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

pragma solidity =0.8.0;
pragma abicoder v2;

// UNISWAP V2
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

interface IUniswapV2Router is IUniswapV2Router01 {
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


// UNISWAP V3
interface IMulticall {
	function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);
}

interface IMulticallExtended is IMulticall {
	function multicall(uint256 deadline, bytes[] calldata data) external payable returns (bytes[] memory results);

	function multicall(bytes32 previousBlockhash, bytes[] calldata data)
		external
		payable
		returns (bytes[] memory results);
}

interface ISelfPermit {
	function selfPermit(
		address token,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitIfNecessary(
		address token,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitAllowed(
		address token,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;

	function selfPermitAllowedIfNecessary(
		address token,
		uint256 nonce,
		uint256 expiry,
		uint8 v,
		bytes32 r,
		bytes32 s
	) external payable;
}

interface IApproveAndCall {
	enum ApprovalType {NOT_REQUIRED, MAX, MAX_MINUS_ONE, ZERO_THEN_MAX, ZERO_THEN_MAX_MINUS_ONE}

	function getApprovalType(address token, uint256 amount) external returns (ApprovalType);

	function approveMax(address token) external payable;

	function approveMaxMinusOne(address token) external payable;

	function approveZeroThenMax(address token) external payable;

	function approveZeroThenMaxMinusOne(address token) external payable;

	function callPositionManager(bytes memory data) external payable returns (bytes memory result);

	struct MintParams {
		address token0;
		address token1;
		uint24 fee;
		int24 tickLower;
		int24 tickUpper;
		uint256 amount0Min;
		uint256 amount1Min;
		address recipient;
	}

	function mint(MintParams calldata params) external payable returns (bytes memory result);

	struct IncreaseLiquidityParams {
		address token0;
		address token1;
		uint256 tokenId;
		uint256 amount0Min;
		uint256 amount1Min;
	}

	function increaseLiquidity(IncreaseLiquidityParams calldata params) external payable returns (bytes memory result);
}

interface IUniswapV3SwapCallback {
	function uniswapV3SwapCallback(
		int256 amount0Delta,
		int256 amount1Delta,
		bytes calldata data
	) external;
}

interface IV3SwapRouter is IUniswapV3SwapCallback {
	struct ExactInputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
		uint160 sqrtPriceLimitX96;
	}

	function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

	struct ExactInputParams {
		bytes path;
		address recipient;
		uint256 amountIn;
		uint256 amountOutMinimum;
	}

	function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

	struct ExactOutputSingleParams {
		address tokenIn;
		address tokenOut;
		uint24 fee;
		address recipient;
		uint256 amountOut;
		uint256 amountInMaximum;
		uint160 sqrtPriceLimitX96;
	}

	function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

	struct ExactOutputParams {
		bytes path;
		address recipient;
		uint256 amountOut;
		uint256 amountInMaximum;
	}

	function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

interface IV2SwapRouter {
	function swapExactTokensForTokens(
		uint256 amountIn,
		uint256 amountOutMin,
		address[] calldata path,
		address to
	) external payable returns (uint256 amountOut);

	function swapTokensForExactTokens(
		uint256 amountOut,
		uint256 amountInMax,
		address[] calldata path,
		address to
	) external payable returns (uint256 amountIn);
}

interface ISwapRouter02 is IV2SwapRouter, IV3SwapRouter, IApproveAndCall, IMulticallExtended, ISelfPermit {

}

interface IPeripheryPayments {
	function unwrapWETH9(uint256 amountMinimum, address recipient) external payable;

	function refundETH() external payable;

	function sweepToken(
		address token,
		uint256 amountMinimum,
		address recipient
	) external payable;
}


// UTILS
interface IERC20 {
	event Transfer(address indexed from, address indexed to, uint256 value);

	event Approval(address indexed owner, address indexed spender, uint256 value);

	function totalSupply() external view returns (uint256);

	function balanceOf(address account) external view returns (uint256);

	function transfer(address to, uint256 amount) external returns (bool);

	function allowance(address owner, address spender) external view returns (uint256);

	function approve(address spender, uint256 amount) external returns (bool);

	function transferFrom(
		address from,
		address to,
		uint256 amount
	) external returns (bool);
}

abstract contract Context {
	function _msgSender() internal view virtual returns (address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns (bytes calldata) {
		return msg.data;
	}
}

abstract contract Owned is Context
{
	event OwnershipTransfered(address indexed previousOwner, address indexed newOwner);
	
	address private _owner;

	/**
	* @dev Initializes the contract, setting owner.
	*/
	constructor()
	{
		_setOwner(msg.sender);
	}

	/**
	* @dev Returns the address of the current owner.
	*/
	function owner() public view returns (address)
	{ return _owner; }

	/**
	* @dev Transfers owner permissions to a new account (`newOwner`).
	* Can only be called by owner.
	*/
	function setOwner(address newOwner) external onlyOwner
	{
		require(newOwner != address(0), "Owned: new owner can't be zero address");
		_setOwner(newOwner);
	}

	/**
	* @dev Throws if called by any account other than the owner.
	*/
	modifier onlyOwner()
	{
		require(_msgSender() == _owner, "Owned: caller is not the owner");
		_;
	}

	/**
	* @dev Transfers owner permissions to a new account (`newOwner`).
	* Internal function without access restriction.
	*/
	function _setOwner(address newOwner) internal
	{
		address oldOwner = _owner;
		_owner = newOwner;
		emit OwnershipTransfered(oldOwner, newOwner);
	}
}

contract UniswapProxy is Owned
{
	uint256 MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
	// address public WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
	address public WETH = 0xcd48a86666D2a79e027D82cA6Adf853357c70d02; // ROPSTEN

	address u2address = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
	IUniswapV2Router u2router = IUniswapV2Router(u2address);

	address u3address = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
	ISwapRouter02 u3router = ISwapRouter02(u3address);

	receive() external payable {}

	// transfer all ETH of this contract to owner
	function withdrawETH() external onlyOwner
	{
		require(address(this).balance > 0, "Can't transfer 0 ETH");
		payable(owner()).transfer(address(this).balance);
	}

	// transfer all token_address tokens of this contract to owner
	function withdrawToken(address token_address) external onlyOwner
	{
		IERC20 token = IERC20(token_address);
		require(token.balanceOf(address(this)) > 0, "Can't transfer 0 tokens");

		token.transfer(owner(), token.balanceOf(address(this)));
	}

	// transfer specific tokens of this contract to a specific address
	function withdraw(address token_address, address recipient, uint256 amount) external onlyOwner
	{
		if(token_address == WETH)
		{
			payable(recipient).transfer(amount);
			return;
		}

		IERC20 token = IERC20(token_address);
		token.transfer(recipient, amount);
	}

	function _checkAndApprove(address token_address, address approval_address, uint256 amount) internal
	{
		IERC20 token = IERC20(token_address); // the token we are trading

		require(token.balanceOf(address(this)) >= amount, "Not enough balance"); // check if there's enough balance of the token

		if(token.allowance(address(this), approval_address) < amount) // check if uniswap (approval_address) does not have enough allowance
			token.approve(approval_address, MAX_INT); // approve uniswap (approval_address) to spend this contract's tokens
	}

	// UNISWAP v2

	// function v2ETHforExactTokens(address token_address, uint amount_in_max, uint amount_out, address to, uint deadline) external onlyOwner
	// {
	// 	require(address(this).balance >= amount_in_max, "Not enough ETH balance for swap");

	// 	address[] memory path = new address[](2);
	// 	path[0] = WETH;
	// 	path[1] = token_address;

	// 	u2router.swapETHForExactTokens{value:amount_in_max}(amount_out, path, to, deadline);
	// }

	// function v2ExactTokensForETH(address token_address, uint amount_in, uint amount_out_min, address to, uint deadline) external onlyOwner
	// {
	// 	_checkAndApprove(token_address, u2address, amount_in);

	// 	address[] memory path = new address[](2);
	// 	path[0] = token_address;
	// 	path[1] = WETH;

	// 	u2router.swapExactTokensForETH(amount_in, amount_out_min, path, to, deadline);
	// }

	// function v2TokensForExactTokens(address token_in, address token_out, uint amount_in_max, uint amount_out, address to, uint deadline) external onlyOwner
	// {
	// 	_checkAndApprove(token_in, u2address, amount_in_max);

	// 	address[] memory path = new address[](2);
	// 	path[0] = token_in;
	// 	path[1] = token_out;

	// 	u2router.swapTokensForExactTokens(amount_out, amount_in_max, path, to, deadline);
	// }

	// function v2ExactTokensForTokens(address token_in, address token_out, uint amount_in, uint amount_out_min, address to, uint deadline) external onlyOwner
	// {
	// 	_checkAndApprove(token_in, u2address, amount_in);

	// 	address[] memory path = new address[](2);
	// 	path[0] = token_in;
	// 	path[1] = token_out;

	// 	u2router.swapExactTokensForTokens(amount_in, amount_out_min, path, to, deadline);
	// }

	// // UNISWAP v3

	// function v3ExactOutput(address token_in, address token_out, uint amount_in_max, uint amount_out, uint24 fee, address to, uint deadline) external onlyOwner
	// {
	// 	uint value = token_in == WETH ? amount_in_max : 0;
	// 	require(address(this).balance >= value, "not enough balance");

	// 	if(token_in != WETH) // approve uniswap to use input token, if it's not ETH
	// 		_checkAndApprove(token_in, u3address, amount_in_max);

	// 	IV3SwapRouter.ExactOutputSingleParams memory params = 
	// 		IV3SwapRouter.ExactOutputSingleParams({
	// 			tokenIn: token_in,
	// 			tokenOut: token_out,
	// 			amountInMaximum: amount_in_max,
	// 			amountOut: amount_out,
	// 			fee: fee,
	// 			recipient: token_out == WETH ? u3address : to,
	// 			sqrtPriceLimitX96: 0
	// 		});
		
	// 	bytes[] memory data = new bytes[]((token_in == WETH || token_out == WETH) ? 2 : 1); // no need for refund/unwrapping when not trading ETH
	// 	data[0] = abi.encodeWithSelector(IV3SwapRouter.exactOutputSingle.selector, params);

	// 	if(params.tokenIn == WETH) // if input token is ETH, add refundETH to be called after swap
	// 	{
	// 		data[1] = abi.encodeWithSelector(IPeripheryPayments.refundETH.selector);
	// 	}
	// 	else if(params.tokenOut == WETH) // if output token is ETH, send WETH from swap to router and then unwrapWETH to a 'to' address;
	// 	{ 
	// 		data[1] = abi.encodeWithSelector(IPeripheryPayments.unwrapWETH9.selector, 0, to);
	// 	}

	// 	u3router.multicall{value:value}(deadline, data);
	// }

	// function v3ExactInput(address token_in, address token_out, uint amount_in, uint amount_out_min, uint24 fee, address to, uint deadline) external onlyOwner
	// {
	// 	uint value = token_in == WETH ? amount_in : 0;
	// 	require(address(this).balance >= value, "not enough balance");

	// 	if(token_in != WETH) // approve uniswap to use input token, if it's not ETH
	// 		_checkAndApprove(token_in, u3address, amount_in);

	// 	IV3SwapRouter.ExactInputSingleParams memory params = 
	// 		IV3SwapRouter.ExactInputSingleParams({
	// 			tokenIn: token_in,
	// 			tokenOut: token_out,
	// 			fee: fee,
	// 			recipient: token_out == WETH ? u3address : to,
	// 			amountIn: amount_in,
	// 			amountOutMinimum: amount_out_min,
	// 			sqrtPriceLimitX96: 0
	// 		});

	// 	bytes[] memory data = new bytes[](token_out == WETH ? 2 : 1); // no need for unwrapping, if WETH is not output token
	// 	data[0] = abi.encodeWithSelector(IV3SwapRouter.exactInputSingle.selector, params);

	// 	if(token_out == WETH) // if output token is ETH, unwrapWETH to a 'to' address;
	// 	{
	// 		data[1] = abi.encodeWithSelector(IPeripheryPayments.unwrapWETH9.selector, 0, to);
	// 	}

	// 	u3router.multicall{value:value}(deadline, data);
	// }
}