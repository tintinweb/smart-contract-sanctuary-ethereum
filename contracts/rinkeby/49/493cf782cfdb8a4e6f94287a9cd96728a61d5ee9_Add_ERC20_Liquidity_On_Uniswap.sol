/**
 *Submitted for verification at Etherscan.io on 2022-03-21
*/

// File @uniswap/v2-core/contracts/interfaces/[email protected]

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File @uniswap/v2-periphery/contracts/interfaces/[email protected]

pragma solidity >=0.6.2;

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


// File contracts/Add_ERC20_Liquidity_On_Uniswap.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract Add_ERC20_Liquidity_On_Uniswap {

    IUniswapV2Router02 private uniswapRouter;
    IERC20 private token;

    event liquidityAdded(address _tokenAddress, uint _tokenAmountDeposited, uint _etherAmountDeposited, uint _liquidityTokensMinted);

    constructor(address _routerAddress) {
       uniswapRouter = IUniswapV2Router02(_routerAddress);
    }

    // This function, when called for first time for an erc20 token which is not listed on uniswap,
    // will create its pair with WETH and will add the provided lquidity to the pool
    // If token is already listed on Uniswap it will add liquidity to token along with equivalent Ether
    function addTokenLiquidityOnUniswap(address _tokenAddress, uint _desiredTokenAmount, uint _minTokenAmount, uint _minEthAmount, uint _deadline) public payable {
        require(_tokenAddress != address(0), 'token address is not valid');
        token = IERC20(_tokenAddress);
        uint __minTokenAmount = _minTokenAmount * 10 ** token.decimals();
        uint __desiredTokenAmount = _desiredTokenAmount * 10 ** token.decimals();
        require(token.transferFrom(msg.sender, address(this), __desiredTokenAmount), 'transfer of tokens failed');
        require(token.approve(address(uniswapRouter), __desiredTokenAmount), 'approve failed.');
        (uint _depositedTokenAmount, uint _depositedEtherAmount, uint _mintedLiquidTokenAmount) = uniswapRouter.addLiquidityETH{ value: msg.value }(_tokenAddress, __desiredTokenAmount, __minTokenAmount, _minEthAmount, msg.sender, _deadline);
        if (__desiredTokenAmount > _depositedTokenAmount) {
            token.transfer(msg.sender, __desiredTokenAmount - _depositedTokenAmount);
        }
        if ( msg.value > _depositedEtherAmount ) {
            payable(msg.sender).transfer( msg.value - _depositedEtherAmount );
        }
        emit liquidityAdded(_tokenAddress, _depositedTokenAmount, _depositedEtherAmount, _mintedLiquidTokenAmount);
    }

    receive() external payable {

    }

}