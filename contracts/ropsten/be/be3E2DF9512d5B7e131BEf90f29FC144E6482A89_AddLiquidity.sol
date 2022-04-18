//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.4;
import "./interfaces/Uniswap.sol";
import "./interfaces/ERC20.sol";

contract AddLiquidity {
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event NewAmountA(uint256 amount);
    event NewAmountB(uint256 amount);
    event NewLiquidity(uint256 value);


    function addLiquidity(
        address _tokenA,
        address _tokenB,
        uint256 _amountA,
        uint256 _amountB
    ) public {
        ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        ERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);
        
        ERC20(_tokenA).approve(ROUTER, _amountA);
        ERC20(_tokenB).approve(ROUTER, _amountB);

        (uint256 newAmountA, uint256 newAmountB, uint256 newLiquidity) = 
        IUniswapV2Router(ROUTER).addLiquidity(_tokenA, _tokenB, _amountA, _amountB, 0, 0, address(this), block.timestamp);

        emit NewAmountA(newAmountA);
        emit NewAmountB(newAmountB);
        emit NewLiquidity(newLiquidity);

    }

    function addLiquidityEth(
        address _tokenA,
        uint256 _amountA
    ) public payable {
        ERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        ERC20(_tokenA).approve(ROUTER, _amountA);

        (uint256 newAmountA, uint256 newAmountB, uint256 newLiquidity) = 
        IUniswapV2Router(ROUTER).addLiquidityETH{value: msg.value}(_tokenA, _amountA, 0, 0, msg.sender, block.timestamp);

        emit NewAmountA(newAmountA);
        emit NewAmountB(newAmountB);
        emit NewLiquidity(newLiquidity);

    }

    constructor () payable {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IUniswapV2Router {
  function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    returns (uint[] memory amounts);

  function swapExactTokensForTokens(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForETH(
    uint amountIn,
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactETHForTokens(
    uint amountOutMin,
    address[] calldata path,
    address to,
    uint deadline
  ) external payable returns (uint[] memory amounts);

  function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint amountADesired,
    uint amountBDesired,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  )
    external
    returns (
      uint amountA,
      uint amountB,
      uint liquidity
    );

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint liquidity,
    uint amountAMin,
    uint amountBMin,
    address to,
    uint deadline
  ) external returns (uint amountA, uint amountB);
}

interface IUniswapV2Pair {
  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (
      uint112 reserve0,
      uint112 reserve1,
      uint32 blockTimestampLast
    );

  function swap(
    uint amount0Out,
    uint amount1Out,
    address to,
    bytes calldata data
  ) external;
}

interface IUniswapV2Factory {
  function getPair(address token0, address token1) external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


interface ERC20{
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) external view returns(uint256 balance);
    function allowance(address _owner, address _spender) external view returns(uint256 remaining);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

}