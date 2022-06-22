//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.9;

import "./Treasury.sol";
import "./ERC20.sol";
import "./Ownable.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IUniswapV2Router02.sol";

contract CryptoIsDead is ERC20, Ownable, Treasury {
  uint256 private constant ONE_HOUR = 60 * 60;
  uint256 private constant PERCENT_DENOMENATOR = 1000;
  address private constant DEAD = address(0xdead);

  uint256 public biggestBuyRewardPercentage = (PERCENT_DENOMENATOR * 57) / 100; // 38%
  mapping(uint256 => address) public biggestBuyer;
  mapping(uint256 => uint256) public biggestBuyerAmount;
  mapping(uint256 => uint256) public biggestBuyerPaid;

  address private _lpReceiver;

  mapping(address => bool) private _isTaxExcluded;

  uint256 public maxWalletBalance = 20000000 * 10**18;  // 2% of total supply
  uint256 public maxSellTxAmount = 5000000 * 10**18;    // 0.5% of total supply

  uint256 public taxLp = (PERCENT_DENOMENATOR * 1) / 100; // 2%
  uint256 public taxBuyer = (PERCENT_DENOMENATOR * 7) / 100; // 5%
  uint256 public taxLpSell = (PERCENT_DENOMENATOR * 1) / 100; // 2%
  uint256 public taxSeller = (PERCENT_DENOMENATOR * 7) / 100; // 5%
  uint256 private _totalTax;
  uint256 private _totalTaxSell;
  bool private _taxesOff;

  uint256 private _liquifyRate = (PERCENT_DENOMENATOR * 1) / 100; // 1%
  uint256 public launchTime;
  uint256 private _launchBlock;

  IUniswapV2Router02 public uniswapV2Router;
  address public uniswapV2Pair;

  mapping(address => bool) private _isBot;

  bool private _swapEnabled = true;
  bool private _swapping = false;

  modifier swapLock() {
    _swapping = true;
    _;
    _swapping = false;
  }

  constructor() ERC20('CRYPTO IS DEAD', 'DEAD') {
    _mint(address(this), 1_000_000_000 * 10**18);

    IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
      0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
    );
    uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
      address(this),
      _uniswapV2Router.WETH()
    );
    uniswapV2Router = _uniswapV2Router;
    _setTotalTax();
    _isTaxExcluded[address(this)] = true;
    _isTaxExcluded[msg.sender] = true;
  }

  // _percent: 1 == 0.1%, 1000 = 100%
  function launch(uint16 _percent) external payable onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'must be between 0-100%');
    require(launchTime == 0, 'already launched');
    require(_percent == 0 || msg.value > 0, 'need ETH for initial LP');

    uint256 _lpSupply = (totalSupply() * _percent) / PERCENT_DENOMENATOR;
    uint256 _leftover = totalSupply() - _lpSupply;
    if (_lpSupply > 0) {
      _addLp(_lpSupply, msg.value);
    }
    if (_leftover > 0) {
      _transfer(address(this), owner(), _leftover);
    }
    launchTime = block.timestamp;
    _launchBlock = block.number;
  }

    function _transfer(
    address sender,
    address recipient,
    uint256 amount
  ) internal virtual override {
    bool _isOwner = sender == owner() || recipient == owner();
    uint256 contractTokenBalance = balanceOf(address(this));
    
    bool _isBuy = sender == uniswapV2Pair &&
      recipient != address(uniswapV2Router);
    bool _isSell = recipient == uniswapV2Pair;
    uint256 _hourAfterLaunch = getHour();

    require(balanceOf(address(recipient)) + amount <= maxWalletBalance, "Balance is exceeding maxWalletBalance");

    if (_isBuy) {
      if (block.number <= _launchBlock + 2) {
        _isBot[recipient] = true;
      } else if (amount > biggestBuyerAmount[_hourAfterLaunch]) {
        biggestBuyer[_hourAfterLaunch] = recipient;
        biggestBuyerAmount[_hourAfterLaunch] = amount;
      }
    } else {
      require(!_isBot[recipient], 'Stop botting!');
      require(!_isBot[sender], 'Stop botting!');
      require(!_isBot[_msgSender()], 'Stop botting!');
    }

    _checkAndPayBiggestBuyer(_hourAfterLaunch);

    uint256 _minSwap = (balanceOf(uniswapV2Pair) * _liquifyRate) /
      PERCENT_DENOMENATOR;
    bool _overMin = contractTokenBalance >= _minSwap;
    if (
      _swapEnabled &&
      !_swapping &&
      !_isOwner &&
      _overMin &&
      launchTime != 0 &&
      sender != uniswapV2Pair
    ) {
      _swap(_minSwap);
    }

   uint256 tax = 0;
    if (
      launchTime != 0 &&
      _isBuy &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      tax = (amount * _totalTax) / PERCENT_DENOMENATOR;
      if (tax > 0) {
        super._transfer(sender, address(this), tax);
      }
    }

    else if (
      launchTime != 0 &&
      _isSell &&
      !_taxesOff &&
      !(_isTaxExcluded[sender] || _isTaxExcluded[recipient])
    ) {
      require(amount <= maxSellTxAmount, "Amount is exceeding max sell amount");
      tax = (amount * _totalTaxSell) / PERCENT_DENOMENATOR;
      if (tax > 0) {
        super._transfer(sender, address(this), tax);
      }
    }

    super._transfer(sender, recipient, amount - tax);

  }

  function _swap(uint256 _amountToSwap) private swapLock {
    uint256 balBefore = address(this).balance;
    uint256 liquidityTokens = (_amountToSwap * taxLp) / _totalTax / 2;
    uint256 tokensToSwap = _amountToSwap - liquidityTokens;

    // generate the uniswap pair path of token -> weth
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = uniswapV2Router.WETH();

    _approve(address(this), address(uniswapV2Router), tokensToSwap);
    uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokensToSwap,
      0,
      path,
      address(this),
      block.timestamp
    );

    uint256 balToProcess = address(this).balance - balBefore;
    if (balToProcess > 0) {
      _processFees(balToProcess, liquidityTokens);
    }
  }

  function _addLp(uint256 tokenAmount, uint256 ethAmount) private {
    _approve(address(this), address(uniswapV2Router), tokenAmount);
    uniswapV2Router.addLiquidityETH{ value: ethAmount }(
      address(this),
      tokenAmount,
      0,
      0,
      _lpReceiver == address(0) ? owner() : _lpReceiver,
      block.timestamp
    );
  }

  function _processFees(uint256 amountETH, uint256 amountLpTokens) private {
    uint256 lpETH = (amountETH * taxLp) / _totalTax;
    if (amountLpTokens > 0) {
      _addLp(amountLpTokens, lpETH);
    }
  }

  function _checkAndPayBiggestBuyer(uint256 _currentHour) private {
    uint256 _prevHour = _currentHour - 1;
    if (
      _currentHour > 1 &&
      biggestBuyerAmount[_prevHour] > 0 &&
      biggestBuyerPaid[_prevHour] == 0
    ) {
      uint256 _before = address(this).balance;
      if (_before > 0) {
        uint256 _buyerAmount = (_before * biggestBuyRewardPercentage) /
          PERCENT_DENOMENATOR;
        biggestBuyerPaid[_prevHour] = _buyerAmount;
        payable(biggestBuyer[_prevHour]).call{ value: _buyerAmount }('');
        require(
          address(this).balance >= _before - _buyerAmount,
          'too much ser'
        );
      }
    }
  }

  function payBiggestBuyer(uint256 _hour) external onlyOwner {
    _checkAndPayBiggestBuyer(_hour);
  }

  // starts at 1 and increments forever every hour after launch
  function getHour() public view returns (uint256) {
    uint256 secondsSinceLaunch = block.timestamp - launchTime;
    return 1 + (secondsSinceLaunch / ONE_HOUR);
  }

  function isBotBlacklisted(address account) external view returns (bool) {
    return _isBot[account];
  }

  function blacklistBot(address account) external onlyOwner {
    require(account != address(uniswapV2Router), 'cannot blacklist router');
    require(account != uniswapV2Pair, 'cannot blacklist pair');
    require(!_isBot[account], 'user is already blacklisted');
    _isBot[account] = true;
  }

  function forgiveBot(address account) external onlyOwner {
    require(_isBot[account], 'user is not blacklisted');
    _isBot[account] = false;
  }

  function _setTotalTax() private {
    _totalTax = taxLp + taxBuyer;
    require(
      _totalTax <= (PERCENT_DENOMENATOR * 25) / 100,
      'tax cannot be above 25%'
    );
  }

  function _setTotalTaxSell() private {
      _totalTaxSell = taxLpSell + taxSeller;
      require(
          _totalTaxSell <= (PERCENT_DENOMENATOR * 25) / 100,
          'tax cannot be above 25%'
      );
  }

  function setBuyTaxes(uint256 _taxlp, uint256 _taxBuyer) external onlyOwner {
    taxLp = _taxlp;
    taxBuyer = _taxBuyer;
    _setTotalTax();
  }

  function setSellTaxes(uint256 _taxlp, uint256 _taxSeller) external onlyOwner {
    taxLpSell = _taxlp;
    taxSeller = _taxSeller;
    _setTotalTaxSell();
  }

  function setLpReceiver(address _wallet) external onlyOwner {
    _lpReceiver = _wallet;
  }

  function setLiquifyRate(uint256 _rate) external onlyOwner {
    require(_rate <= PERCENT_DENOMENATOR / 10, 'cannot be more than 10%');
    _liquifyRate = _rate;
  }

  function setIsTaxExcluded(address _wallet, bool _isExcluded)
    external
    onlyOwner
  {
    _isTaxExcluded[_wallet] = _isExcluded;
  }

  function setTaxesOff(bool _taxOff) external onlyOwner {
    _taxesOff = _taxOff;
  }

  function setSwapEnabled(bool _enabled) external onlyOwner {
    _swapEnabled = _enabled;
  }

  function setBiggestBuyRewardPercentage(uint256 _percent) external onlyOwner {
    require(_percent <= PERCENT_DENOMENATOR, 'cannot be more than 100%');
    biggestBuyRewardPercentage = _percent;
  }

}