// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

import "IUniswapV2DMTransact.sol";
import "IUniswapV2Router02.sol";
import "IUniswapV2Pair.sol";
import "IERC20.sol";


contract UniswapV2DMTransact is IUniswapV2DMTransact {

    IUniswapV2Router02 public immutable router02;

    constructor(address _router02) public {
        router02 = IUniswapV2Router02(_router02);
    }

    function getFactory() external view override returns (address factory) {
        factory = router02.factory();
        return factory;
    }

    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) public view returns (uint[] memory amountIn) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountIn = router02.getAmountsIn(amountOut, path);
        return amountIn;
    }
    

    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) public view returns (uint[] memory amountOut) {
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amountOut = router02.getAmountsOut(amountIn, path);
        return amountOut;
    }

    function swapETHForExactTokens(uint amountOut, address tokenOut) external payable returns (uint[] memory amounts) {
        
        address[] memory path = new address[](2);
        path[0] = router02.WETH();
        path[1] = tokenOut;
        amounts = router02.swapETHForExactTokens{value: msg.value}(amountOut, path, msg.sender, block.timestamp);
        return amounts;
      
    }

    function swapExactETHForTokens(address tokenOut, uint amountOutMin) external payable returns (uint[] memory amounts) {
        address[] memory path = new address[](2);
        path[0] = router02.WETH();
        path[1] = tokenOut;
        amounts = router02.swapExactETHForTokens{value: msg.value}(amountOutMin, path, msg.sender, block.timestamp);
        return amounts;
      
    }

    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address tokenIn) public returns (uint[] memory amounts) {
        IERC20 ERC20 = IERC20(tokenIn);
        require(ERC20.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        require(ERC20.approve(address(router02), amountIn), 'approve failed.');
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router02.WETH();
        amounts = router02.swapExactTokensForETH(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        return amounts;
    }

    function swapTokensForExactETH(uint amountIn, uint amountOut, address tokenIn) public returns (uint[] memory amounts) {
        IERC20 ERC20 = IERC20(tokenIn);
        require(ERC20.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        require(ERC20.approve(address(router02), amountIn), 'approve failed.');
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = router02.WETH();
        uint amountInMax = 10**21;
        amounts = router02.swapTokensForExactETH(amountOut, amountInMax, path, msg.sender, block.timestamp);
        return amounts;
    }

    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address tokenIn, address tokenOut) public returns (uint[] memory amounts) {
        IERC20 ERC20 = IERC20(tokenIn);
        require(ERC20.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        require(ERC20.approve(address(router02), amountIn), 'approve failed.');
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amounts = router02.swapExactTokensForTokens(amountIn, amountOutMin, path, msg.sender, block.timestamp);
        return amounts;
    }

    function swapTokensForExactTokens(uint amountIn, uint amountInMax, uint amountOut, address tokenIn, address tokenOut) public returns (uint[] memory amounts) {
        IERC20 ERC20 = IERC20(tokenIn);
        require(ERC20.transferFrom(msg.sender, address(this), amountIn), 'transferFrom failed.');
        require(ERC20.approve(address(router02), amountIn), 'approve failed.');
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        amounts = router02.swapTokensForExactTokens(amountOut, amountInMax, path, msg.sender, block.timestamp);
        return amounts;
    }


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;


interface IUniswapV2DMTransact {

    
    function getFactory() external view returns (address factory);
    function getAmountIn(uint amountOut, address tokenIn, address tokenOut) external view returns (uint[] memory amountIn);
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint[] memory amountOut);
    function swapETHForExactTokens(uint amountOut, address tokenOut) external payable returns (uint[] memory amounts);
    function swapExactETHForTokens(address tokenOut, uint amountOutMin) external payable returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address tokenIn) external returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountIn, uint amountOut, address tokenIn) external returns (uint[] memory amounts);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address tokenIn, address tokenOut) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountIn, uint amountInMax, uint amountOut, address tokenIn, address tokenOut) external returns (uint[] memory amounts);

}

pragma solidity >=0.6.2;

import "IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);
  function increaseApproval(address spender, uint256 subtractedValue) external;
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function deposit() external payable;
  function withdraw(uint256 value) external;
}