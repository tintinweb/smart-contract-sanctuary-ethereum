/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

interface IBaseV1Pair {
  function stable() external view returns(bool);
  function token0() external view returns(address);
  function token1() external view returns(address);
}
interface ISolidly {
  struct route {
      address from;
      address to;
      bool stable;
  }

  function wftm() external pure returns (address);

  function addLiquidity(
      address tokenA,
      address tokenB,
      bool stable,
      uint amountADesired,
      uint amountBDesired,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB, uint liquidity);

  function addLiquidityFTM(
      address token,
      bool stable,
      uint amountTokenDesired,
      uint amountTokenMin,
      uint amountETHMin,
      address to,
      uint deadline
  ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

  function removeLiquidity(
      address tokenA,
      address tokenB,
      bool stable,
      uint liquidity,
      uint amountAMin,
      uint amountBMin,
      address to,
      uint deadline
  ) external returns (uint amountA, uint amountB);

  function swapExactTokensForTokensSimple(
      uint amountIn,
      uint amountOutMin,
      address tokenFrom,
      address tokenTo,
      bool stable,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactTokensForTokens(
      uint amountIn,
      uint amountOutMin,
      route[] calldata routes,
      address to,
      uint deadline
  ) external returns (uint[] memory amounts);

  function swapExactFTMForTokens(uint amountOutMin, route[] calldata path, address to, uint deadline)
      external
      payable
      returns (uint[] memory amounts);

  function swapExactTokensForFTM(uint amountIn, uint amountOutMin, route[] calldata path, address to, uint deadline)
      external
      returns (uint[] memory amounts);

  function getAmountsOut(uint amountIn, route[] calldata path) external view returns (uint[] memory amounts);
}
pragma solidity ^0.8.0;



// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)



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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)




// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}



contract TreasuryConverter is Ownable {

  address public WETH;
  address public dexRouter;
  address public treasury;

  constructor(address _dexRouter, address _treasury)
  {
    dexRouter = _dexRouter;
    treasury = _treasury;
    WETH = ISolidly(dexRouter).wftm();
  }

  // parse LD tokens and convert tokens to WETH
  // return WETH value amount
  function getLDInETH(address _LD, uint _amount, bool stable) external view returns(uint){
    address tokenABuy = IBaseV1Pair(_LD).token0();
    address tokenBBuy = IBaseV1Pair(_LD).token1();

    address _WETH = WETH;

    uint tokenAAmount = tokenABuy == _WETH
    ? _amount
    : getRate(tokenABuy, _WETH, _amount, stable);

    uint tokenBAmount = tokenBBuy == _WETH
    ? _amount :
    getRate(tokenBBuy, _WETH, _amount, stable);

    return tokenAAmount + tokenBAmount;
  }

  // get rate between 2 tokens
  function getRate(address _from, address _to, uint amount, bool stable) private view returns(uint) {
    ISolidly.route[] memory routes = new ISolidly.route[](1);
    routes[0].from = _from;
    routes[0].to = _to;
    routes[0].stable = stable;

    uint256[] memory res = ISolidly(dexRouter).getAmountsOut(amount, routes);
    return res[1];
  }

  // trade LD token
  // sell LD A, swap tokens, buy LD B
  function tradeLD(address from, address to, uint amount) external {
    // sell LD
    address tokenASell = IBaseV1Pair(from).token0();
    address tokenBSell = IBaseV1Pair(from).token1();

    sellLD(
      from,
      amount,
      tokenASell,
      tokenBSell,
      IBaseV1Pair(from).stable()
    );

    address tokenABuy = IBaseV1Pair(to).token0();
    address tokenBBuy = IBaseV1Pair(to).token1();

    // trade
    swapSellTokenForBuyLD(
      tokenASell,
      tokenBSell,
      tokenABuy,
      tokenBBuy
    );

    // Buy LD
    buyLD(
      tokenABuy,
      tokenBBuy,
      IBaseV1Pair(to).stable(),
      IERC20(tokenABuy).balanceOf(address(this)),
      IERC20(tokenBBuy).balanceOf(address(this)),
      treasury
    );

    // transfer remains
    transferRemains(tokenASell, treasury);
    transferRemains(tokenBSell, treasury);
    transferRemains(tokenABuy, treasury);
    transferRemains(tokenBBuy, treasury);
  }

  // trade not LD token
  function tradeToken(address from, address to, uint amount) private {
    if(from == to){
      return;
    }
    else if(from == WETH || to == WETH){
      tradeTokenDirectly(from, to, amount);
    }else{
      tradeTokenViaWETH(from, to, amount);
    }
  }

  function tradeTokenDirectly(address from, address to, uint amount) private {
    IERC20(from).approve(dexRouter, amount);

    ISolidly.route[] memory routes = new ISolidly.route[](1);
    routes[0].from = from;
    routes[0].to = to;
    routes[0].stable = false;

    ISolidly(dexRouter).swapExactTokensForTokens(
        amount,
        1,
        routes,
        address(this),
        block.timestamp + 15 minutes
    );
  }

  function tradeTokenViaWETH(address from, address to, uint amount) private {
    IERC20(from).approve(dexRouter, amount);

    ISolidly.route[] memory routes = new ISolidly.route[](2);
    routes[0].from = from;
    routes[0].to = WETH;
    routes[0].stable = false;

    routes[1].from = WETH;
    routes[1].to = to;
    routes[1].stable = false;

    ISolidly(dexRouter).swapExactTokensForTokens(
        amount,
        1,
        routes,
        address(this),
        block.timestamp + 15 minutes
    );
  }

  // helper for sell LD token
  function sellLD(
    address LDToken,
    uint LDAmount,
    address tokenA,
    address tokenB,
    bool stable
    )
    private
  {
    IERC20(LDToken).approve(dexRouter, LDAmount);

    ISolidly(dexRouter).removeLiquidity(
      tokenA,
      tokenB,
      stable,
      LDAmount,
      1,
      1,
      address(this),
      block.timestamp + 15 minutes
    );
  }

  // helper for buy LD token
  function buyLD(
    address tokenA,
    address tokenB,
    bool stable,
    uint amountA,
    uint amountB,
    address to
    )
    private
  {
    // approve token transfer
    IERC20(tokenA).approve(dexRouter, amountA);
    IERC20(tokenB).approve(dexRouter, amountB);
    // add the liquidity
    ISolidly(dexRouter).addLiquidity(
      tokenA,
      tokenB,
      stable,
      amountA,
      amountB,
      1,
      1,
      to,
      block.timestamp + 15 minutes
    );
  }

  // trade tokens
  function swapSellTokenForBuyLD(
    address tokenASell,
    address tokenBSell,
    address tokenABuy,
    address tokenBBuy
    )
    internal
  {
    tradeToken(tokenASell, tokenABuy, IERC20(tokenASell).balanceOf(address(this)));
    tradeToken(tokenBSell, tokenBBuy, IERC20(tokenBSell).balanceOf(address(this)));
  }


  // helper for transfer remains if there is remains
  function transferRemains(address token, address to) private {
    uint amount = IERC20(token).balanceOf(address(this));
    if(amount > 0)
      IERC20(token).transfer(to, amount);
  }
}