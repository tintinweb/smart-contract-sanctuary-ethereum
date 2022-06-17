/**
 *Submitted for verification at Etherscan.io on 2022-06-16
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

// File: contracts/NftaniaAddLiquidity.sol



// Make Allowance for this contract to spend the tokens amount immediately after deployment
pragma solidity ^0.8;


contract NftaniaAddLiquidity {
    address private constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;  
    address private constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    address private token;
    address public beneficiary;
    address public pairAddress;
  
    event LiquidityAdded(uint amountToken, uint amountETH, uint256 amountliquidity, uint256 totalLiquidity, address pairAddress);
    event LiquidityDetails(address pairAddress, uint256 amountETH);

    fallback() external payable {} // used in the beneficiary contract
    receive()  external payable {} // used in the beneficiary contract
  
    function addLiquidityETH (address _token, uint tokenAmount, uint EthAmount, address _beneficiary ) external payable 
        returns (uint amountToken, uint amountETH, uint amountliquidity, uint totalLiquidity, address _pairAddress) {
        token = _token;
        beneficiary = _beneficiary;
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount); // add tokens to liquidty creation contract        
        IERC20(token).approve(ROUTER, tokenAmount);                         // approve router contract to spend tokens 

        (amountToken, amountETH, amountliquidity) = 
        IUniswapV2Router(ROUTER).addLiquidityETH {value:EthAmount} (
          token,              // token Address
          tokenAmount,        // tokens amount to be added
          0,                  // min tokens to be added
          0,                  // min tokens to be added
          beneficiary,      // liquidity tokens recieving address
          block.timestamp+120 // Deadline for liquidty addition
        ); 

        pairAddress = IUniswapV2Factory(FACTORY).getPair(token, WETH);
        totalLiquidity = IERC20(pairAddress).balanceOf(beneficiary);
        emit LiquidityAdded(amountToken, amountETH, amountliquidity, totalLiquidity, pairAddress);
        return (amountToken, amountETH, amountliquidity, totalLiquidity, pairAddress);
    }
}

interface IUniswapV2Router {
    function getAmountsOut(uint amountIn, address[] memory path)
    external
    view
    returns (uint[] memory amounts);

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