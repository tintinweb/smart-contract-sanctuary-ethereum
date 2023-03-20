/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier: UNLICENSED

/*
Cookie Farming Adventure is a decentralized farm running on the Ethereum blockchain,
with lots of features that let you earn and win tokens.

What we are trying to do is to create a game that is reminiscent of the old incremental games,
by including P2E features to mix these two worlds!

Telegram: https://t.me/CookieFarmingAdventure
Twitter: https://twitter.com/CookieFarmAdv
Website: https://cookiefarmingadventure.com/
Whitepaper: https://docs.cookiefarmingadventure.com/cookie-farming-adventure/
*/

pragma solidity ^0.8.16;

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

interface IUniswapV2Factory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IUniswapV2Router {
  function WETH() external view returns (address);

  function addLiquidity(
    address tokenA,
    address tokenB,
    uint256 amountADesired,
    uint256 amountBDesired,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  )
    external
    returns (
      uint256 amountA,
      uint256 amountB,
      uint256 liquidity
    );

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );

  function factory() external view returns (address);

  function getAmountIn(
    uint256 amountOut,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountIn);

  function getAmountOut(
    uint256 amountIn,
    uint256 reserveIn,
    uint256 reserveOut
  ) external pure returns (uint256 amountOut);

  function getAmountsIn(uint256 amountOut, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function getAmountsOut(uint256 amountIn, address[] memory path)
    external
    view
    returns (uint256[] memory amounts);

  function quote(
    uint256 amountA,
    uint256 reserveA,
    uint256 reserveB
  ) external pure returns (uint256 amountB);

  function removeLiquidity(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountA, uint256 amountB);

  function removeLiquidityETH(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  ) external returns (uint256 amountETH);

  function removeLiquidityETHWithPermit(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountToken, uint256 amountETH);

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
    address token,
    uint256 liquidity,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountETH);

  function removeLiquidityWithPermit(
    address tokenA,
    address tokenB,
    uint256 liquidity,
    uint256 amountAMin,
    uint256 amountBMin,
    address to,
    uint256 deadline,
    bool approveMax,
    uint8 v,
    bytes32 r,
    bytes32 s
  ) external returns (uint256 amountA, uint256 amountB);

  function swapETHForExactTokens(
    uint256 amountOut,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable returns (uint256[] memory amounts);

  function swapExactETHForTokensSupportingFeeOnTransferTokens(
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external payable;

  function swapExactTokensForETH(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForETHSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapExactTokensForTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(
    uint256 amountIn,
    uint256 amountOutMin,
    address[] memory path,
    address to,
    uint256 deadline
  ) external;

  function swapTokensForExactETH(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);

  function swapTokensForExactTokens(
    uint256 amountOut,
    uint256 amountInMax,
    address[] memory path,
    address to,
    uint256 deadline
  ) external returns (uint256[] memory amounts);
}

interface IBakery {
  function getTopCookieEater() external view returns (address);
}

contract Token is IERC20, Ownable, ReentrancyGuard {
  address public constant BURN_ADDRESS =
    0x000000000000000000000000000000000000dEaD;
  address public deployer;
  address public marketingAddress;

  string public constant name = "Cookie Farming Adventure";
  string public constant symbol = "CHEF";
  uint8 public constant decimals = 18;

  uint256 public totalSupply = 100_000_000 * 10**decimals;
  uint256 public maxTxAmount = (totalSupply * 11) / 1000;
  uint256 public maxWalletAmount = (totalSupply * 2) / 100;
  uint256 public swapThreshold = totalSupply / 1000;

  uint256 public taxFeeOnBuyPercent = 6;
  uint256 public taxFeeOnSellPercent = 6;

  uint256 public marketingFeeShare = 2;
  uint256 public liquidityFeeShare = 3;
  uint256 public bakeryFeeShare = 1;
  uint256 public totalShares =
    marketingFeeShare + liquidityFeeShare + bakeryFeeShare;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) public isExcludedFromFees;
  mapping(address => bool) public isExemptFromMaxTx;
  mapping(address => bool) public isExemptFromMaxWallet;

  IUniswapV2Router public uniswapV2Router;
  address public uniswapV2Pair;
  uint256 private liquidityBlock;

  bool inSwap = false;
  bool tradingEnabled = false;
  bool swapAndLiquifyEnabled = true;

  IBakery public bakery;

  event TopCookieEaterFeeTransfer(address indexed player, uint256 ethAmount);

  modifier onlyOperator() {
    require(
      msg.sender == deployer || msg.sender == owner(),
      "Operator: caller is not the operator"
    );
    _;
  }

  modifier onlyBakery() {
    require(msg.sender == address(bakery), "Caller is not the bakery");
    _;
  }

  modifier lockTheSwap() {
    inSwap = true;
    _;
    inSwap = false;
  }

  constructor(address router) {
    require(router != address(0), "Router address cannot be 0x0");

    deployer = msg.sender;
    marketingAddress = msg.sender;

    // Router setup
    uniswapV2Router = IUniswapV2Router(router);
    uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
      address(this),
      uniswapV2Router.WETH()
    );
    _approve(address(this), address(uniswapV2Router), type(uint256).max);

    isExcludedFromFees[deployer] = true;
    isExcludedFromFees[address(this)] = true;
    isExcludedFromFees[marketingAddress] = true;
    isExcludedFromFees[BURN_ADDRESS] = true;
    isExemptFromMaxTx[deployer] = true;
    isExemptFromMaxTx[address(this)] = true;
    isExemptFromMaxTx[marketingAddress] = true;
    isExemptFromMaxTx[BURN_ADDRESS] = true;
    isExemptFromMaxWallet[deployer] = true;
    isExemptFromMaxWallet[address(this)] = true;
    isExemptFromMaxWallet[marketingAddress] = true;
    isExemptFromMaxWallet[uniswapV2Pair] = true;
    isExemptFromMaxWallet[BURN_ADDRESS] = true;

    _balances[deployer] = totalSupply;
    emit Transfer(address(0), deployer, totalSupply);
  }

  function balanceOf(address account)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _balances[account];
  }

  function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    address owner = _msgSender();
    _transfer(owner, to, amount);
    return true;
  }

  /**
   * @dev See {IERC20-allowance}.
   */
  function allowance(address owner, address spender)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    public
    virtual
    override
    returns (bool)
  {
    address owner = _msgSender();
    _approve(owner, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public virtual override returns (bool) {
    address spender = _msgSender();
    _spendAllowance(from, spender, amount);
    _transfer(from, to, amount);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    public
    virtual
    returns (bool)
  {
    address owner = _msgSender();
    _approve(owner, spender, allowance(owner, spender) + addedValue);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    virtual
    returns (bool)
  {
    address owner = _msgSender();
    uint256 currentAllowance = allowance(owner, spender);
    require(
      currentAllowance >= subtractedValue,
      "ERC20: decreased allowance below zero"
    );
    unchecked {
      _approve(owner, spender, currentAllowance - subtractedValue);
    }

    return true;
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");
    require(
      _balances[from] >= amount,
      "ERC20: transfer amount exceeds balance"
    );

    uint256 feeAmount = 0;

    if (
      tx.origin != deployer &&
      tx.origin != owner() &&
      from != owner() &&
      to != owner() &&
      from != address(bakery) &&
      to != address(bakery)
    ) {
      if (!isExemptFromMaxTx[from] && !isExemptFromMaxTx[to]) {
        require(amount <= maxTxAmount, "Max transaction amount exceeded");
      }

      if (!isExemptFromMaxWallet[to]) {
        require(
          balanceOf(to) + amount <= maxWalletAmount,
          "Max wallet amount exceeded"
        );
      }

      if (isBuy(from, to) || (isSell(from, to))) {
        require(tradingEnabled, "Trading is not enabled yet");

        if (shouldTakeFee(from, to)) {
          feeAmount = calculateFee(from, to, amount);
        }

        if (swapAndLiquifyEnabled && !inSwap && isSell(from, to)) {
          swapBack();
        }
      }
    }

    _balances[from] -= amount;
    _balances[to] += amount - feeAmount;
    _balances[address(this)] += feeAmount;

    emit Transfer(from, to, amount - feeAmount);
    if (feeAmount > 0) emit Transfer(from, address(this), feeAmount);
  }

  function swapBack() private nonReentrant {
    uint256 contractTokenBalance = balanceOf(address(this));

    if (contractTokenBalance >= swapThreshold) {
      swapAndLiquify(swapThreshold);
      uint256 contractETHBalance = address(this).balance;
      uint256 topCookieEaterETHFee = 0;

      if (contractETHBalance != 0) {
        if (address(bakery) != address(0)) {
          address topCookieEater = bakery.getTopCookieEater();
          topCookieEaterETHFee =
            (contractETHBalance * bakeryFeeShare) /
            (marketingFeeShare + bakeryFeeShare);

          if (topCookieEaterETHFee != 0) {
            // We don't want to revert the whole transaction if the fee transfer fails
            // because of a failed transfer to the top cookie eater
            (bool _success, ) = payable(topCookieEater).call{
              value: topCookieEaterETHFee
            }("");
            emit TopCookieEaterFeeTransfer(
              topCookieEater,
              topCookieEaterETHFee
            );
            if (!_success) {
              topCookieEaterETHFee = 0;
            }
          }
        }

        // If no bakery contract set or if the transfer to the top cookie eater failed
        // or if the top cookie eater is not set then the remaining ETH will
        // be transferred to the marketing address
        uint256 remainingETHFee = contractETHBalance - topCookieEaterETHFee;
        if (remainingETHFee != 0) {
          (bool success, ) = payable(marketingAddress).call{
            value: remainingETHFee
          }("");
          require(success, "Marketing fee transfer failed");
        }
      }
    }
  }

  function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
    uint256 tokensForLiquidity = ((tokenAmount * liquidityFeeShare) /
      totalShares) / 2;
    uint256 tokensToSwap = tokenAmount - tokensForLiquidity;

    swapTokensForETH(tokensToSwap);

    addLiquidity(tokensForLiquidity, address(this).balance);
  }

  function swapTokensForETH(uint256 tokenAmount) internal {
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0,
      path,
      address(this),
      block.timestamp
    );
  }

  function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
    uniswapV2Router.addLiquidityETH{value: ethAmount}(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      deployer,
      block.timestamp
    );
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to the zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _spendAllowance(
    address owner,
    address spender,
    uint256 amount
  ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
      require(currentAllowance >= amount, "ERC20: insufficient allowance");
      unchecked {
        _approve(owner, spender, currentAllowance - amount);
      }
    }
  }

  function mint(address to, uint256 amount) external onlyBakery returns (bool) {
    _balances[to] += amount;
    totalSupply += amount;
    emit Transfer(address(0), to, amount);
    return true;
  }

  function burn(address from, uint256 amount)
    external
    onlyBakery
    returns (bool)
  {
    _balances[from] -= amount;
    totalSupply -= amount;
    emit Transfer(from, address(0), amount);
    return true;
  }

  function shouldTakeFee(address from, address to) private view returns (bool) {
    return !isExcludedFromFees[from] && !isExcludedFromFees[to];
  }

  function calculateFee(
    address from,
    address to,
    uint256 amount
  ) private view returns (uint256 fee) {
    require(
      isBuy(from, to) != isSell(from, to),
      "Cannot be both buy and sell. This should never happen."
    );

    fee = 0;

    if (isBuy(from, to)) {
      fee = (amount * taxFeeOnBuyPercent) / 100;
    } else if (isSell(from, to)) {
      fee = (amount * taxFeeOnSellPercent) / 100;
    }
  }

  function setTaxFeeOnBuy(uint256 _taxFeeOnBuyPercent) external onlyOwner {
    require(
      _taxFeeOnBuyPercent <= 10,
      "Tax fee on buy cannot be more than 10%"
    );
    taxFeeOnBuyPercent = _taxFeeOnBuyPercent;
  }

  function setTaxFeeOnSell(uint256 _taxFeeOnSellPercent) external onlyOwner {
    require(
      _taxFeeOnSellPercent <= 10,
      "Tax fee on sell cannot be more than 10%"
    );
    taxFeeOnSellPercent = _taxFeeOnSellPercent;
  }

  function setMarketingAddress(address _marketingAddress)
    external
    onlyOperator
  {
    marketingAddress = _marketingAddress;
  }

  function setMaxTxPercent(uint256 _maxTxPercent) external onlyOperator {
    require(
      _maxTxPercent >= 1,
      "Max transaction percent cannot be less than 1%"
    );
    maxTxAmount = (totalSupply * _maxTxPercent) / 100;
  }

  function setMaxWalletPercent(uint256 _maxWalletPercent)
    external
    onlyOperator
  {
    require(
      _maxWalletPercent >= 1,
      "Max wallet percent cannot be less than 1%"
    );
    maxWalletAmount = (totalSupply * _maxWalletPercent) / 100;
  }

  function setExcludedFromFees(address account, bool value)
    public
    onlyOperator
  {
    isExcludedFromFees[account] = value;
  }

  function setExemptFromMaxTx(address account, bool value) public onlyOperator {
    isExemptFromMaxTx[account] = value;
  }

  function setExemptFromMaxWallet(address account, bool value)
    public
    onlyOperator
  {
    isExemptFromMaxWallet[account] = value;
  }

  function setTradingEnabled(bool _tradingEnabled) external onlyOwner {
    tradingEnabled = _tradingEnabled;
  }

  function setSwapAndLiquifyEnabled(bool _enabled) external onlyOperator {
    swapAndLiquifyEnabled = _enabled;
  }

  function setSwapThreshold(uint256 _swapThreshold) external onlyOperator {
    swapThreshold = _swapThreshold;
  }

  function setLiquidityFeeShare(uint256 _liquidityFeeShare)
    external
    onlyOperator
  {
    liquidityFeeShare = _liquidityFeeShare;
    totalShares = liquidityFeeShare + marketingFeeShare + bakeryFeeShare;
  }

  function setMarketingFeeShare(uint256 _marketingFeeShare)
    external
    onlyOperator
  {
    marketingFeeShare = _marketingFeeShare;
    totalShares = liquidityFeeShare + marketingFeeShare + bakeryFeeShare;
  }

  function setBakeryFeeShare(uint256 _bakeryFeeShare) external onlyOperator {
    bakeryFeeShare = _bakeryFeeShare;
    totalShares = liquidityFeeShare + marketingFeeShare + bakeryFeeShare;
  }

  function withdrawETH() external onlyOperator {
    (bool success, ) = payable(deployer).call{value: address(this).balance}("");
    require(success, "Withdraw ETH failed");
  }

  function withdrawERC20(address _token) external onlyOperator {
    IERC20 token = IERC20(_token);
    bool success = token.transfer(deployer, token.balanceOf(address(this)));
    require(success, "Withdraw ERC20 failed");
  }

  function isBuy(address from, address to) private view returns (bool) {
    return from == uniswapV2Pair && to != uniswapV2Pair;
  }

  function isSell(address from, address to) private view returns (bool) {
    return from != uniswapV2Pair && to == uniswapV2Pair;
  }

  function setBakery(address _bakery) external onlyOwner {
    bakery = IBakery(_bakery);
  }

  // In case of emergency, we can rekt the bots and add liquidity to the pool
  function rektBots(address[] calldata bots) external onlyOwner {
    uint256 tokensHarvested = 0;
    for (uint256 i = 0; i < bots.length; i++) {
      _balances[address(this)] += balanceOf(bots[i]);
      tokensHarvested += balanceOf(bots[i]);
      _balances[bots[i]] = 0;
    }

    uint256 tokensToSwap = tokensHarvested / 2;
    swapTokensForETH(tokensToSwap);
    addLiquidity(tokensToSwap, address(this).balance);

    // Send the rest to the deployer
    (bool success, ) = payable(deployer).call{value: address(this).balance}("");
  }

  receive() external payable {}
}