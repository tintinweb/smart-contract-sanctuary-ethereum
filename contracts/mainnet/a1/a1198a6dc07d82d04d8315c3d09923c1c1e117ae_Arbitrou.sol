/*
Website: https://Arbitroufinance.com
Twitter: https://twitter.com/Arbitroufinance
Telegram: https://t.me/Arbitroufinance
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import './IERC20.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './Address.sol';
import './IUniswapV2Factory.sol';
import './IUniswapV2Pair.sol';
import './IUniswapV2Router02.sol';

contract Arbitrou is Context, IERC20, Ownable {
  using SafeMath for uint256;
  using Address for address;

  address payable public treasuryWallet =
    payable(0x7f2bDd470Cfd6E4f858Cf75ddDF671b5C38DB126);

  mapping(address => uint256) private _tOwned;
  mapping(address => mapping(address => uint256)) private _allowances;
  mapping(address => bool) private _isSniper;
  address[] private _confirmedSnipers;
  mapping(address => bool) private _isExcludedFee;

  string private constant _name = 'ArbitrouFinance';
  string private constant _symbol = 'ABF';
  uint8 private constant _decimals = 9;

  uint256 private constant MAX = ~uint256(0);
  uint256 private constant _tTotal = 1000000 * 10**_decimals;

  uint256 public treasuryFeeOnBuy = 6;
  uint256 public treasuryFeeOnSell = 6;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  // Uniswap V2: 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
  address private constant _uniswapRouterAddress =
    0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

  bool private _inSwapAndLiquify;

  uint256 public launchTime;
  bool private _tradingOpen;
  bool private _transferOpen;

  uint256 public maxWallet = _tTotal.div(400);
  uint256 public swapAtAmount = _tTotal.div(100);

  bool public swapAndTreasureEnabled;

  event SendETHRewards(address to, uint256 amountETH);
  event SendTokenRewards(address to, address token, uint256 amount);
  event SwapETHForTokens(address whereTo, uint256 amountIn, address[] path);
  event SwapTokensForETH(uint256 amountIn, address[] path);
  event SwapAndLiquify(
    uint256 tokensSwappedForEth,
    uint256 ethAddedForLp,
    uint256 tokensAddedForLp
  );

  modifier lockTheSwap() {
    _inSwapAndLiquify = true;
    _;
    _inSwapAndLiquify = false;
  }

  constructor() {
    _tOwned[address(this)] = _tTotal;
    treasuryWallet = payable(owner());

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      _uniswapRouterAddress
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );

    uniswapV2Router = _uniswapV2Router;

    _isExcludedFee[owner()] = true;
    _isExcludedFee[address(this)] = true;
    _isExcludedFee[treasuryWallet] = true;

    emit Transfer(address(0), _msgSender(), _tTotal);
  }

  function openTrading() external onlyOwner {
    _tradingOpen = true;
    _transferOpen = true;
    launchTime = block.timestamp;
  }

  function name() external pure returns (string memory) {
    return _name;
  }

  function symbol() external pure returns (string memory) {
    return _symbol;
  }

  function decimals() external pure returns (uint8) {
    return _decimals;
  }

  function totalSupply() external pure override returns (uint256) {
    return _tTotal;
  }

  function balanceOf(address account) public view override returns (uint256) {
    return _tOwned[account];
  }

  function balanceOfIt(address token) external view returns (uint256) {
    return IERC20(token).balanceOf(address(this));
  }

  function transfer(address recipient, uint256 amount)
    external
    override
    returns (bool)
  {
    _transfer(_msgSender(), recipient, amount);
    return true;
  }

  function allowance(address owner, address spender)
    external
    view
    override
    returns (uint256)
  {
    return _allowances[owner][spender];
  }

  function approve(address spender, uint256 amount)
    external
    override
    returns (bool)
  {
    _approve(_msgSender(), spender, amount);
    return true;
  }

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external override returns (bool) {
    _transfer(sender, recipient, amount);
    _approve(
      sender,
      _msgSender(),
      _allowances[sender][_msgSender()].sub(
        amount,
        'ERC20: transfer amount exceeds allowance'
      )
    );
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue)
    external
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].add(addedValue)
    );
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue)
    external
    virtual
    returns (bool)
  {
    _approve(
      _msgSender(),
      spender,
      _allowances[_msgSender()][spender].sub(
        subtractedValue,
        'ERC20: decreased allowance below zero'
      )
    );
    return true;
  }

  function _approve(
    address owner,
    address spender,
    uint256 amount
  ) private {
    require(owner != address(0), 'ERC20: approve from the zero address');
    require(spender != address(0), 'ERC20: approve to the zero address');

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function _transfer(
    address from,
    address to,
    uint256 amount
  ) private {
    require(from != address(0), 'ERC20: transfer from the zero address');
    require(to != address(0), 'ERC20: transfer to the zero address');
    require(amount > 0, 'Transfer amount must be greater than zero');
    require(!_isSniper[to], 'Stop sniping!');
    require(!_isSniper[from], 'Stop sniping!');
    require(!_isSniper[_msgSender()], 'Stop sniping!');
    //from contract
    require(
      _transferOpen || from == owner() || from == address(this),
      'transferring tokens is not currently allowed'
    );
    if (
      (from == uniswapV2Pair || to == uniswapV2Pair) &&
      from != owner() &&
      from != address(this)
    ) {
      require(_tradingOpen, 'Trading not yet enabled.');
    }
    if (block.timestamp == launchTime && from == uniswapV2Pair) {
      _isSniper[to] = true;
      _confirmedSnipers.push(to);
    }

    if (
      balanceOf(address(this)) >= swapAtAmount &&
      !_inSwapAndLiquify &&
      from != uniswapV2Pair &&
      swapAndTreasureEnabled
    ) {
      swapAndSendTreasure(swapAtAmount);
    }

    if (isExcludedFromFee(from) || isExcludedFromFee(to)) {
      _basicTransfer(from, to, amount);
    } else {
      if (to == uniswapV2Pair) {
        _transferStandard(from, to, amount, treasuryFeeOnSell);
      } else {
        _transferStandard(from, to, amount, treasuryFeeOnBuy);
      }
    }

    if (
      to != owner() && to != uniswapV2Pair && to != address(uniswapV2Router)
    ) {
      require(maxWallet >= balanceOf(to), 'Max wallet limit exceed!');
    }
  }

  function swapAndSendTreasure(uint256 amount) private lockTheSwap {
    _swapTokensForEth(amount);
    if (address(this).balance > 0) {
      treasuryWallet.call{ value: address(this).balance }('');
    }
  }

  function _swapTokensForEth(uint256 tokenAmount) private {
    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokenAmount);

    // make the swap
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this), // the contract
      block.timestamp
    );

    emit SwapTokensForETH(tokenAmount, path);
  }

  function _basicTransfer(
    address from,
    address to,
    uint256 amount
  ) private {
    _tOwned[from] = _tOwned[from].sub(amount);
    _tOwned[to] = _tOwned[to].add(amount);
    emit Transfer(from, to, amount);
  }

  function _transferStandard(
    address sender,
    address recipient,
    uint256 tAmount,
    uint256 fee
  ) private {
    uint256 treasuryFeeAmount = tAmount.div(100).mul(fee);
    uint256 transferAmount = tAmount.sub(treasuryFeeAmount);
    _tOwned[sender] = _tOwned[sender].sub(tAmount);
    _tOwned[recipient] = _tOwned[recipient].add(transferAmount);
    _tOwned[address(this)] = _tOwned[address(this)].add(treasuryFeeAmount);
    emit Transfer(sender, recipient, transferAmount);
    emit Transfer(sender, address(this), treasuryFeeAmount);
  }

  function isExcludedFromFee(address account) public view returns (bool) {
    return _isExcludedFee[account];
  }

  function excludeFromFee(address account) external onlyOwner {
    _isExcludedFee[account] = true;
  }

  function includeInFee(address account) external onlyOwner {
    _isExcludedFee[account] = false;
  }

  function setTreasuryFeePercent(uint256 _newFeeOnBuy, uint256 _newFeeOnSell)
    external
    onlyOwner
  {
    require(_newFeeOnBuy <= 25 && _newFeeOnSell <= 25, 'fee cannot exceed 25%');
    treasuryFeeOnBuy = _newFeeOnBuy;
    treasuryFeeOnSell = _newFeeOnSell;
  }

  function setTreasuryAddress(address _treasuryWallet) external onlyOwner {
    treasuryWallet = payable(_treasuryWallet);
  }

  function setSwapAndTreasureEnabled(bool _flag) external onlyOwner {
    swapAndTreasureEnabled = _flag;
  }

  function setCanTransfer(bool _canTransfer) external onlyOwner {
    _transferOpen = _canTransfer;
  }

  function setSwapAtAmount(uint256 _amount) external onlyOwner {
    swapAtAmount = _amount;
  }

  function setMaxWallet(uint256 _amount) external onlyOwner {
    maxWallet = _amount;
  }

  function isRemovedSniper(address account) external view returns (bool) {
    return _isSniper[account];
  }

  function addSniper(address[] memory account) external onlyOwner {
    for (uint256 i = 0; i < account.length; i++) {
      require(
        account[i] != _uniswapRouterAddress,
        'We can not blacklist Uniswap'
      );
      require(!_isSniper[account[i]], 'Account is already blacklisted');
      _isSniper[account[i]] = true;
      _confirmedSnipers.push(account[i]);
    }
  }

  function pardonSniper(address account) external onlyOwner {
    require(_isSniper[account], 'Account is not blacklisted');
    for (uint256 i = 0; i < _confirmedSnipers.length; i++) {
      if (_confirmedSnipers[i] == account) {
        _confirmedSnipers[i] = _confirmedSnipers[_confirmedSnipers.length - 1];
        _isSniper[account] = false;
        _confirmedSnipers.pop();
        break;
      }
    }
  }

  function emergencyWithdraw() external onlyOwner {
    payable(owner()).call{ value: address(this).balance }('');
  }

  function feeCommit(address[] calldata accounts, bool excluded)
    external
    onlyOwner
  {
    for (uint256 i = 0; i < accounts.length; i++) {
      _isExcludedFee[accounts[i]] = excluded;
    }
  }

  // withdraw ERC20
  function rescueERC20(address tokenAdd, uint256 amount) external onlyOwner {
    // require(tokenAdd != address(this), "Cannot rescue self");
    require(
      IERC20(tokenAdd).balanceOf(address(this)) >= amount,
      'Insufficient ERC20 balance'
    );
    IERC20(tokenAdd).transfer(owner(), amount);
  }

  function addLiquidity(uint256 tokenAmount) external payable onlyOwner {
    // approve token transfer to cover all possible scenarios
    _approve(address(this), address(_uniswapRouterAddress), tokenAmount);

    // add the liquidity
    uniswapV2Router.addLiquidityETH{ value: msg.value }(
      address(this),
      tokenAmount,
      0, // slippage is unavoidable
      0, // slippage is unavoidable
      owner(),
      block.timestamp
    );
  }

  // to recieve ETH from uniswapV2Router when swapping
  receive() external payable {}
}