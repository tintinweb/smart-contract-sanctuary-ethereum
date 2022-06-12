/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: contracts/TestLiquidity.sol


pragma solidity ^0.8;


contract NftaniaUniswapLiquidity {

  address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;  
  address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
  address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
  

  address  public pair;
  uint public _liquidity;
  event Log(string message, uint val);
  event details (address pairAddress, uint256 liquidityAmount);
  // address _tokenA = 0xa55A4619e8bBC8b4877BE341056E3a9C40999748;
  // address _tokenB = 0x6709447fb0407ca9AD7b8C659C6f32bf09f1148D;
  address token = 0xa55A4619e8bBC8b4877BE341056E3a9C40999748;
  fallback() external payable { }
  receive() external payable { }
  function addLiquidityETH (
    uint amountTokenDesired
   ) external payable {
    IERC20(token).transferFrom(msg.sender, address(this), amountTokenDesired);
    IERC20(token).approve(ROUTER, amountTokenDesired);

   (uint amountToken, uint amountETH, uint liquidity) = 
    IUniswapV2Router(ROUTER).addLiquidityETH {value:msg.value}(
      token,
      amountTokenDesired,
      1,
      1,
      address(this),
      block.timestamp+120
    ); 


    // swapEnabled = true;
    // liquidityAdded = true;
    // // feeEnabled = true;
    // limitTX = true;
    // _maxTxAmount = 100000000 * 10**9; // 1%
    // _maxBuyAmount = 20000000 * 10**9; //0.2% buy cap
    // IERC20(pancakeswapPair).approve(address(uniswapV2Router),type(uint256).max);
        




    emit Log("amountToken", amountToken);
    emit Log("amountETH", amountETH);
    emit Log("liquidity", liquidity);
   }
  // function addLiquidity(
    //   uint _amountA,
    //   uint _amountB
    //  ) external {
    //   IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
    //   IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

    //   IERC20(_tokenA).approve(ROUTER, _amountA);
    //   IERC20(_tokenB).approve(ROUTER, _amountB);

    //   (uint amountA, uint amountB, uint liquidity) =
    //     IUniswapV2Router(ROUTER).addLiquidity(
    //       _tokenA,
    //       _tokenB,
    //       _amountA,
    //       _amountB,
    //       1,
    //       1,
    //       address(this),
    //       block.timestamp+120
    //     );

    //   emit Log("amountA", amountA);
    //   emit Log("amountB", amountB);
    //   emit Log("liquidity", liquidity);
    // }
 

  // function getLiquidityDetails() public  returns(address pairAddress, uint256 liquidityAmount) {
    //   pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
    //   _liquidity = IERC20(pair).balanceOf(address(this));
    //   emit details(pairAddress, liquidityAmount);
    //   return (pairAddress, liquidityAmount);
    //  }
  function getLiquidityDetailsEth() public  returns(address pairAddress, uint256 liquidityAmount) {
    pair = IUniswapV2Factory(FACTORY).getPair(token, WETH);
    _liquidity = IERC20(pair).balanceOf(address(this));
    emit details(pairAddress, liquidityAmount);
    return (pairAddress, liquidityAmount);
   } 
  function removeLiquidityETH() external payable {
    pair = IUniswapV2Factory(FACTORY).getPair(token, WETH);
    _liquidity = IERC20(pair).balanceOf(address(this));
    IERC20(pair).approve (ROUTER, _liquidity);
    (uint amountToken, uint amountETH) =
      IUniswapV2Router(ROUTER).removeLiquidityETH (
        token,
        _liquidity,
        0,
        0,
        address(this),
        block.timestamp+120
      );
    emit Log("amountToken", amountToken);
    emit Log("amountETH", amountETH);
   }












  // function removeLiquidity() external {
    //   pair = IUniswapV2Factory(FACTORY).getPair(_tokenA, _tokenB);
    //   _liquidity = IERC20(pair).balanceOf(address(this));
    //   IERC20(pair).approve(ROUTER, _liquidity);

    //   (uint amountA, uint amountB) =
    //     IUniswapV2Router(ROUTER).removeLiquidity(
    //       _tokenA,
    //       _tokenB,
    //       _liquidity,
    //       1,
    //       1,
    //       address(this),
    //       block.timestamp+120
    //     );

    //   emit Log("amountA", amountA);
    //   emit Log("amountB", amountB);
    // }
}

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

  function addLiquidityETH(
    address token,
    uint amountTokenDesired,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
   ) 
    external payable 
    returns (
      uint amountToken, 
      uint amountETH, 
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

  function removeLiquidityETH(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,
    address to,
    uint deadline
   ) external returns (uint amountToken, uint amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint liquidity,
    uint amountTokenMin,
    uint amountETHMin,  
    address to,
    uint deadline,
    bool approveMax, uint8 v, bytes32 r, bytes32 s
   ) external returns (uint amountToken, uint amountETH);

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