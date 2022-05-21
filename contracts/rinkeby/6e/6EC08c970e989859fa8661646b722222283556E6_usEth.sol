//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface ILido is IERC20 {
  function submit(address _referral) external payable returns (uint256 StETH);
  function withdraw(uint256 _amount, bytes32 _pubkeyHash) external; // wont be available until post-merge
  function sharesOf(address _owner) external returns (uint balance);
}

interface IWEth is IERC20 {
  function withdraw(uint256 wad) external;
  function deposit() external payable;
}

interface IAave {
  function deposit(address asset,uint256 amount,address onBehalfOf,uint16 referralCode) external;
  function borrow(address asset,uint256 amount,uint256 interestRateMode,uint16 referralCode,address onBehalfOf) external;
  function repay(address asset,uint256 amount,uint256 rateMode,address onBehalfOf) external returns (uint256);
  function withdraw(address asset,uint256 amount,address to) external returns (uint256);
  function getUserAccountData(address user) external view returns (uint256 totalCollateralETH, uint256 totalDebtETH, uint256 availableBorrowsETH, uint256 currentLiquidationThreshold, uint256 ltv, uint256 healthFactor);
}

interface EACAggregatorProxy {
  function latestAnswer() external view returns (int256);
}

interface ICurve {
  function exchange(int128 i,int128 j,uint256 dx,uint256 min_dy) external;
}

contract usEth is ERC20, ReentrancyGuard {
  mapping(address => uint256) public staked;
  mapping(address => uint256) public poolShares;
  uint256 public totalShares;
  address private lidoAddress;
  address private aaveAddress;
  address private chainlinkAddress;
  address private uniswapAddress;
  address private curveAddress;
  address private usdcAddress;
  address private wethAddress;
  address private astethAddress;
  address private ausdcAddress;
  address public usEthDaoAddress;
  address private stakerAddress = 0x0000000000000000000000000000000000005aFE;

  constructor(address _lidoAddress, address _aaveAddress, address _chainlinkAddress, address _uniswapAddress, address _curveAddress, address _usdcAddress, address _wethAddress, address _astethAddress, address _ausdcAddress, address _usEthDaoAddress) ERC20("USD  Ether", "usETH") {
    lidoAddress = _lidoAddress;
    aaveAddress = _aaveAddress;
    chainlinkAddress = _chainlinkAddress;
    uniswapAddress = _uniswapAddress;
    curveAddress = _curveAddress;
    usdcAddress = _usdcAddress;
    wethAddress = _wethAddress;
    astethAddress = _astethAddress;
    ausdcAddress = _ausdcAddress;
    usEthDaoAddress = _usEthDaoAddress;
    _mint(stakerAddress, 1 ether);
    totalShares = 1 ether;
    poolShares[stakerAddress] = 1 ether;
    staked[stakerAddress] = 1 ether;
  }

  function swap(address _tokenIn, address _tokenOut, uint256 _amountIn) internal returns (uint256) {
    uint24 poolFee = 3000; // reduce to 500 for usdc-eth?
    ISwapRouter.ExactInputSingleParams memory params =
      ISwapRouter.ExactInputSingleParams({
        tokenIn: _tokenIn,
        tokenOut: _tokenOut,
        fee: poolFee,
        recipient: address(this),
        deadline: block.timestamp,
        amountIn: _amountIn,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0
      });
    uint256 amountOut = ISwapRouter(uniswapAddress).exactInputSingle(params);
    return amountOut;
  }

  /*
  1. Convert ETH > stETH
  2. Deposit stETH > Aave
  3. Borrow wETH
  4. Sell wETH for USDC
  5. Deposit USDC > Aave
  6. Repeat so borrow ETH matches deposited stETH
  */
  function deposit() payable public nonReentrant returns (uint256) {
    ILido(lidoAddress).submit{value: msg.value}(usEthDaoAddress);
    uint256 lidoBalance = ILido(lidoAddress).balanceOf(address(this));
    ILido(lidoAddress).approve(aaveAddress, lidoBalance-1); // leave 1 wei to save gas
    IAave(aaveAddress).deposit(lidoAddress,lidoBalance-1,address(this),0);
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 borrowAmount = msg.value * 6 / 10; // 70% collateral to loan - 75% liquidation
    uint256 secondBorrow = msg.value - borrowAmount; // leaves 30% remaining
    IAave(aaveAddress).borrow(wethAddress,borrowAmount,2,0,address(this));
    uint256 approveAllAtOnce = borrowAmount * 2;
    IWEth(wethAddress).approve(uniswapAddress,approveAllAtOnce);
    uint256 usdcBack = swap(wethAddress,usdcAddress,borrowAmount);
    IERC20(usdcAddress).approve(aaveAddress,approveAllAtOnce);
    IAave(aaveAddress).deposit(usdcAddress,usdcBack-1,address(this),0);
    IAave(aaveAddress).borrow(wethAddress,secondBorrow,2,0,address(this));
    uint256 usdcBackAgain = swap(wethAddress,usdcAddress,secondBorrow); // already approved
    uint256 usdcBalance = ILido(usdcAddress).balanceOf(address(this));
    IAave(aaveAddress).deposit(usdcAddress,usdcBalance-1,address(this),0);
    uint256 amountToMint = msg.value * ethDollarPrice;
    uint256 usdcTotal = usdcBack + usdcBackAgain;
    uint usdcNormalised = usdcTotal * 10e11;
    if (usdcNormalised < amountToMint) amountToMint = usdcNormalised;
    _mint(msg.sender, amountToMint);
    return amountToMint;
  }

  /*
    Deposit: 1ETH = $2000
    Collateral 1 stETH & 2000 USDC
    Borrowed 1 WETH

    Withdraw $1000
    Collateral 0.5 stETH & 1000USDC
    Borrowed 0.5ETH
  */
  function withdraw(uint256 _amount) public nonReentrant {
    uint256 supply = totalSupply();
    uint256 maxWithdrawPerTransaction = supply / 2;
    require(_amount < maxWithdrawPerTransaction, "Exceeds maximum withdrawal per transaction");
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    _burn(msg.sender, _amount);
    uint256 usdcOut = _amount / 10e11;
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 lidoOut = _amount / ethDollarPrice;

    // USDC side
    IAave(aaveAddress).withdraw(usdcAddress,usdcOut,address(this));
    IERC20(usdcAddress).approve(uniswapAddress,usdcOut);
    uint256 wethBack = swap(usdcAddress,wethAddress,usdcOut);
    IWEth(wethAddress).approve(aaveAddress,wethBack);
    IAave(aaveAddress).repay(wethAddress,wethBack,2,address(this));

    // stETH side
    IAave(aaveAddress).withdraw(lidoAddress,lidoOut,address(this));
    IERC20(lidoAddress).approve(uniswapAddress,lidoOut);
    uint256 minLidoBack = lidoOut * 9 / 10;
    ILido(lidoAddress).approve(curveAddress,lidoOut);
    ICurve(curveAddress).exchange(1,0,lidoOut,minLidoBack); // returns ETH
    if (address(this).balance < wethBack) wethBack = address(this).balance;
    (bool success, ) = msg.sender.call{value: wethBack}("");
    require(success, "ETH transfer on withdrawal failed");
  }

  /*
    As price of ETH fluctuates our collateral could become skewed.
    Ideally we want to keep a balanced amount of stETH and USDC
  */
  function rebalance() public nonReentrant {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    uint256 astethBalance = IERC20(astethAddress).balanceOf(address(this));
    uint256 ausdcBalance = IERC20(ausdcAddress).balanceOf(address(this));
    uint256 astethNormalised = astethBalance * ethDollarPrice;
    uint256 ausdcNormalised = ausdcBalance  * 10e11;

    if (astethNormalised * 9 > ausdcNormalised * 10) { // rebalance @ ~10% to avoid frequent MEV sandwich
      uint256 diffNormalised = astethNormalised - ausdcNormalised;
      uint diff = diffNormalised / ethDollarPrice / 2;
      IAave(aaveAddress).withdraw(lidoAddress,diff,address(this));
      uint256 lidoBalance = IERC20(lidoAddress).balanceOf(address(this));
      uint256 minLidoBack = lidoBalance * 9 / 10;
      ILido(lidoAddress).approve(curveAddress,lidoBalance);
      ICurve(curveAddress).exchange(1,0,lidoBalance,minLidoBack);
      uint256 ethBalance = address(this).balance;
      IWEth(wethAddress).deposit{value:ethBalance}();
      uint256 halfWeth = ethBalance / 2;
      swap(wethAddress,usdcAddress,halfWeth);
      uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));
      IERC20(usdcAddress).approve(aaveAddress,usdcBalance);
      IAave(aaveAddress).deposit(usdcAddress,usdcBalance,address(this),0);
      IWEth(wethAddress).approve(aaveAddress,halfWeth);
      IAave(aaveAddress).repay(wethAddress,halfWeth,2,address(this));
    }

    if (ausdcNormalised * 9 > astethNormalised * 10) {
      uint256 diffNormalised = ausdcNormalised - astethNormalised;
      uint qtrDiff = diffNormalised / 10e11 / 4;
      IAave(aaveAddress).withdraw(usdcAddress,qtrDiff,address(this));
      IERC20(usdcAddress).approve(uniswapAddress,qtrDiff);
      swap(usdcAddress,wethAddress,qtrDiff);
      uint256 wethBalance = IERC20(wethAddress).balanceOf(address(this));
      IWEth(wethAddress).withdraw(wethBalance);
      ILido(lidoAddress).submit{value: wethBalance}(usEthDaoAddress);
      uint256 stEthBalance = ILido(lidoAddress).balanceOf(address(this));
      ILido(lidoAddress).approve(aaveAddress, stEthBalance);
      IAave(aaveAddress).deposit(lidoAddress,stEthBalance,address(this),0);
      IAave(aaveAddress).borrow(wethAddress,stEthBalance,2,0,address(this));
      swap(wethAddress,usdcAddress,stEthBalance); // already approved
      uint256 usdcBalance = IERC20(usdcAddress).balanceOf(address(this));
      IERC20(usdcAddress).approve(aaveAddress,usdcBalance);
      IAave(aaveAddress).deposit(usdcAddress,usdcBalance,address(this),0);
    }
  }

  function stake(uint256 _amount) public nonReentrant {
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares; // 1 ether used to avoid integer underflow
    require(pricePerShare > 0, "pricePerShare too low");
    uint256 sharesToPurchase = _amount * 1 ether / pricePerShare;
    totalShares += sharesToPurchase;
    _transfer(msg.sender,stakerAddress,_amount);
    poolShares[msg.sender] += sharesToPurchase;
    staked[msg.sender] += _amount;
  }

  function unstake(uint256 _amount) public nonReentrant {
    require(_amount > 0, "Amount to unstake must be greater than zero");
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares;
    require(pricePerShare > 0, "pricePerShare too low");
    uint256 sharesToSell = _amount * 1 ether / pricePerShare;
    require(poolShares[msg.sender] >= sharesToSell, "Not enough poolShares to unstake");
    uint256 stakingBalance = stakingBalanceOf(msg.sender);
    if (stakingBalance > staked[msg.sender]) {
      uint256 capitalGains = stakingBalance - staked[msg.sender];
      uint256 percentageWithdrawal = 1 ether * _amount / staked[msg.sender];
      uint256 adjustedGains = capitalGains / percentageWithdrawal / 1 ether;
      distributeRewards(adjustedGains); // ditribute governance token on usd gains
    }
    totalShares -= sharesToSell;
    poolShares[msg.sender] -= sharesToSell;
    staked[msg.sender] -= _amount;
    _transfer(stakerAddress,msg.sender,_amount);
  }


  function distributeRewards(uint256 _commission) internal {
    uint256 govTokenSupply = IERC20(usEthDaoAddress).balanceOf(address(this));
    if (govTokenSupply < 1 ether) return;
    if (msg.sender == usEthDaoAddress) return;
    uint256 diminishingSupplyFactor =  govTokenSupply * 100 / 400000000 ether; // assumes 400m used allocation for stakers
    uint256 govTokenDistro = _commission * diminishingSupplyFactor ;
    if (govTokenDistro > 0) IERC20(usEthDaoAddress).transfer(msg.sender,govTokenDistro);
  }

 function stakingBalanceOf(address _user) public view returns (uint256) {
    uint256 pricePerShare = balanceOf(stakerAddress) * 1 ether / totalShares;
    uint256 stakingBalance = poolShares[_user] *  pricePerShare / 1 ether;
    return stakingBalance;
  }

  function calculateRewards() public nonReentrant {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    uint256 supply = totalSupply();
    if (usdTVL > supply) {
      uint256 profit = usdTVL - supply;
      uint256 fee = profit / 10;
      uint256 remaining = profit - fee;
       _mint(usEthDaoAddress, fee);
      _mint(stakerAddress, remaining);
    }
  }

  function tvl() public view returns (uint256) {
    int256 ethPriceInt = EACAggregatorProxy(chainlinkAddress).latestAnswer();
    uint256 ethDollarPrice = uint256(ethPriceInt) / 10e7;
    (uint256 totalCollateralETH,,,,,) = IAave(aaveAddress).getUserAccountData(address(this));
    uint256 usdTVL = totalCollateralETH * ethDollarPrice;
    return usdTVL;
  }

  function publicBurn(uint256 _amount) public {
    _burn(msg.sender, _amount);
    require(balanceOf(msg.sender) >= _amount, "Not enough usETH balance");
  }


  fallback() external payable {}
  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
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

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
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

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
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

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}