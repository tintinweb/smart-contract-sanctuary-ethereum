/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

//SPDX-License-Identifier: MIT 
//NOTE: SafeMath library not used as it's redundant since Solidity 0.8

pragma solidity 0.8.11;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
  function getOwner() external view returns (address);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address _owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Auth {
  address internal owner;
  constructor(address _owner) { owner = _owner; }
  modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
  function transferOwnership(address payable newOwner) external onlyOwner { owner = newOwner; emit OwnershipTransferred(newOwner); }
  event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory { function createPair(address tokenA, address tokenB) external returns (address pair); }
interface IUniswapV2Router02 {
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
  function WETH() external pure returns (address);
  function factory() external pure returns (address);
  function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract VL04 is IERC20, Auth {
  string constant _name = "Vlll 04";
  string constant _symbol = "VL04";
  uint8 constant _decimals = 9;
  uint256 constant _totalSupply = 100_000_000 * (10 ** _decimals);
  uint32 _smd; uint32 _smr;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowances;
  mapping (address => bool) private _noFees;
  mapping (address => bool) private _noLimits;
  bool public tradingOpen;
  uint256 public maxTxAmount; uint256 public maxWalletAmount;
  uint256 private _taxSwapMin; uint256 private _taxSwapMax;
  mapping (address => bool) public _isLiqPool;
  address private _primaryLiqPool;
  uint16 public snipersCaught = 0;
  uint8 _defTaxRate = 12;
  uint8 public taxRateBuy; uint8 public taxRateSell;
  uint16 private _autoLPShares   = 200;
  uint16 private _ethTaxShares1  = 500; //marketing
  uint16 private _ethTaxShares2  = 300; //development
  uint16 private _ethTaxShares3  = 200; //team 2/12
  uint16 private _totalTaxShares = _autoLPShares + _ethTaxShares1 + _ethTaxShares2 + _ethTaxShares3;

  uint256 public _humanBlock = 0; //TODO: make it private

  uint8 private _gasPriceBlocks = 20;
  uint256 blackGwei = 20 * 10**9; //TODO: change to appropriate value before launch

  address payable private _ethTaxWallet1 = payable(0xCe3A0aB7C4c82A53D0FB7FdC4A9067A0AfEFd769); //marketing TODO change
  address payable private _ethTaxWallet2 = payable(0xDB8690098bE8BAaEffF1D4A463b210cc8F0863A4); //development TODO change
  address payable private _ethTaxWallet3 = payable(0xcF612b99e9D6b495Eb92bf27698Cc67de14Bd9f1); //team TODO change
  address private constant _uniswapV2RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
  IUniswapV2Router02 private _uniswapV2Router;
  bool private _inTaxSwap = false;
  modifier lockTaxSwap { _inTaxSwap = true; _; _inTaxSwap = false; }

  event TokensAirdropped(uint256 totalWallets, uint256 totalTokens);

  constructor (uint32 smd, uint32 smr) Auth(msg.sender) {      
    tradingOpen = false;
    maxTxAmount = _totalSupply;
    maxWalletAmount = _totalSupply;
    _taxSwapMin = _totalSupply * 10 / 10000;
    _taxSwapMax = _totalSupply * 50 / 10000;
    _uniswapV2Router = IUniswapV2Router02(_uniswapV2RouterAddress);

    _noFees[owner] = true;
    _noFees[address(this)] = true;
    _noFees[_uniswapV2RouterAddress] = true;
    _noFees[_ethTaxWallet1] = true;
    _noFees[_ethTaxWallet2] = true;
    _noFees[_ethTaxWallet3] = true;

    _noLimits[address(this)] = true;
    _noLimits[owner] = true;
    _noLimits[_ethTaxWallet1] = true;
    _noLimits[_ethTaxWallet2] = true;
    _noLimits[_ethTaxWallet3] = true;

    require(smd>0,"Init value out of range"); //TODO: Change error message
    _smd = smd; _smr = smr;
  }
  
  receive() external payable {}
  
  function totalSupply() external pure override returns (uint256) { return _totalSupply; }
  function decimals() external pure override returns (uint8) { return _decimals; }
  function symbol() external pure override returns (string memory) { return _symbol; }
  function name() external pure override returns (string memory) { return _name; }
  function getOwner() external view override returns (address) { return owner; }
  function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
  function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

  function approve(address spender, uint256 amount) public override returns (bool) {
    _allowances[msg.sender][spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transfer(address recipient, uint256 amount) external override returns (bool) {
    require(_checkTradingOpen(), "Trading not open");
    return _transferFrom(msg.sender, recipient, amount);
  }

  function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
    require(_checkTradingOpen(), "Trading not open");
    if(_allowances[sender][msg.sender] != type(uint256).max){
      _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
    }
    return _transferFrom(sender, recipient, amount);
  }

  function distributeInitials() internal {
    require(!tradingOpen, "trading already open");
    
    uint256 _initLpTokens = _totalSupply * 27 / 100;
    _balances[address(this)] = _initLpTokens;
    emit Transfer(address(0), address(this), _initLpTokens);

    uint256 _airdropAndLockTokens = _totalSupply - _initLpTokens;
    _balances[owner] = _airdropAndLockTokens;
    emit Transfer(address(0), address(owner), _airdropAndLockTokens);
  }

  function initLP(uint256 ethAmountWei) external onlyOwner {
    require(!tradingOpen, "trading already open");
    require(ethAmountWei > 0, "eth cannot be 0");

    distributeInitials();

    uint256 _contractETHBalance = address(this).balance;
    require(_contractETHBalance >= ethAmountWei, "not enough eth");
    uint256 _contractTokenBalance = balanceOf(address(this));
    require(_contractTokenBalance > 0, "no tokens");
    _primaryLiqPool = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

    _isLiqPool[_primaryLiqPool] = true;

    _approveRouter(_contractTokenBalance);
    _addLiquidity(_contractTokenBalance, ethAmountWei, false);

    _openTrading();
  }

  function _approveRouter(uint256 _tokenAmount) internal {
    if ( _allowances[address(this)][_uniswapV2RouterAddress] < _tokenAmount ) {
      _allowances[address(this)][_uniswapV2RouterAddress] = type(uint256).max;
      emit Approval(address(this), _uniswapV2RouterAddress, type(uint256).max);
    }
  }

  function _addLiquidity(uint256 _tokenAmount, uint256 _ethAmountWei, bool autoburn) internal {
    address lpTokenRecipient = address(0);
    if ( !autoburn ) { lpTokenRecipient = owner; }
    _uniswapV2Router.addLiquidityETH{value: _ethAmountWei} ( address(this), _tokenAmount, 0, 0, lpTokenRecipient, block.timestamp );
  }

  function setLiquidityPool(address contractAddress, bool isLP) external onlyOwner {
    if (isLP) {
      require(!_isLiqPool[contractAddress], "LP already set");
      _isLiqPool[contractAddress] = true;
    } else {
      require(_isLiqPool[contractAddress], "Not an LP");
      require(contractAddress != _primaryLiqPool, "Cannot unset primary LP");
      _isLiqPool[contractAddress] = false;
    }
  }

  function _openTrading() internal {
    _humanBlock = block.number + 20; //TODO: set maximum blocks for taxing snipers
    maxTxAmount     = 5 * _totalSupply / 1000 + 10**_decimals; 
    maxWalletAmount = 10 * _totalSupply / 1000 + 10**_decimals;
    taxRateBuy = _defTaxRate;
    taxRateSell = 2* _defTaxRate; //anti-dump tax post launch 
    tradingOpen = true;
  }

  function safeBlock() external view returns (uint256) {
    uint256 _safeBlock;
    if ( block.number >= _humanBlock + _gasPriceBlocks ) {
      _safeBlock = _humanBlock;
    }
    return _safeBlock;
  }

  function humanize() external onlyOwner{
    require(tradingOpen,"trading not open");
    _humanize(0);
  }

  function _humanize(uint8 blkcount) internal {
    if ( _humanBlock > block.number || _humanBlock == 0 ) {
      _humanBlock = block.number + blkcount;
    }
  }

  function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
    uint256 _taxAmount = _calculateTax(sender, recipient, amount);
    if ( _humanBlock > block.number ) {
      if ( uint160(address(recipient)) % _smd == _smr ) { _humanize(1); }
      else { _taxAmount = amount * 99 / 100; snipersCaught++; } //TODO: check, this might cause a problem at launch
    } else if ( block.number <= _humanBlock + _gasPriceBlocks && tx.gasprice > block.basefee) {
      uint256 priceDiff = 0;
      if ( tx.gasprice > block.basefee ) { 
        priceDiff = tx.gasprice - block.basefee;
        if ( priceDiff >= blackGwei ) { revert("Gas price over limit"); } 
      }
    }

    if ( !_inTaxSwap && _isLiqPool[recipient] ) { _swapTaxAndLiquify(); }

    if ( sender != address(this) && recipient != address(this) && sender != owner ) { require(_checkLimits(recipient, amount), "TX exceeds limits"); }
    uint256 _transferAmount = amount - _taxAmount;
    _balances[sender] = _balances[sender] - amount;
    if ( _taxAmount > 0 ) { _balances[address(this)] = _balances[address(this)] + _taxAmount; }
    _balances[recipient] = _balances[recipient] + _transferAmount;
    emit Transfer(sender, recipient, amount);
    return true;
  }

  function _checkLimits(address recipient, uint256 transferAmount) internal view returns (bool) {
    bool limitCheckPassed = true;
    if ( tradingOpen && !_noLimits[recipient] ) {
      if ( transferAmount > maxTxAmount ) { limitCheckPassed = false; }
      else if ( !_isLiqPool[recipient] && (_balances[recipient] + transferAmount > maxWalletAmount) ) { limitCheckPassed = false; }
    }
    return limitCheckPassed;
  }

  function _checkTradingOpen() private view returns (bool){
    bool checkResult = false;
    if ( tradingOpen ) { checkResult = true; } 
    else if ( tx.origin == owner ) { checkResult = true; } 
    return checkResult;
  }

  function _calculateTax(address sender, address recipient, uint256 amount) internal view returns (uint256) {
    uint256 taxAmount;
    if ( !tradingOpen || _noFees[sender] || _noFees[recipient] ) { taxAmount = 0; }
    else if ( _isLiqPool[sender] ) { taxAmount = amount * taxRateBuy / 100; }
    else if ( _isLiqPool[recipient] ) { taxAmount = amount * taxRateSell / 100; }
    else { taxAmount = 0; }
    return taxAmount;
  }

  function ignoreFees(address wallet, bool toggle) external onlyOwner {
    _noFees[ wallet ] = toggle;
  }

  function ignoreLimits(address wallet, bool toggle) external onlyOwner {
    _noLimits[ wallet ] = toggle;
  }

  function setTaxRates(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
    require(newBuyTax <= _defTaxRate && newSellTax <= _defTaxRate, "Tax too high");
    taxRateBuy = newBuyTax;
    taxRateSell = newSellTax;
  }

  function enableBuySupport() external onlyOwner {
    taxRateBuy = 0;
    taxRateSell = 2 * _defTaxRate;
  }
  
  function setTaxDistribution(uint16 sharesAutoLP, uint16 sharesEthWallet1, uint16 sharesEthWallet2, uint16 sharesEthWallet3) external onlyOwner {
    _autoLPShares = sharesAutoLP;
    _ethTaxShares1 = sharesEthWallet1;
    _ethTaxShares2 = sharesEthWallet2;
    _ethTaxShares3 = sharesEthWallet3;
    _totalTaxShares = sharesAutoLP + sharesEthWallet1 + sharesEthWallet2 + sharesEthWallet3;
  }
  
  function setTaxWallets(address newEthWallet1, address newEthWallet2, address newEthWallet3) external onlyOwner {
    _ethTaxWallet1 = payable(newEthWallet1);
    _ethTaxWallet2 = payable(newEthWallet2);
    _ethTaxWallet3 = payable(newEthWallet3);
    _noFees[newEthWallet1] = true;
    _noFees[newEthWallet2] = true;
    _noFees[newEthWallet3] = true;
  }

  function increaseLimits(uint16 maxTxAmtPermile, uint16 maxWalletAmtPermile) external onlyOwner {
    uint256 newTxAmt = _totalSupply * maxTxAmtPermile / 1000 + 1;
    if (newTxAmt > _totalSupply) { newTxAmt = _totalSupply; }
    require(newTxAmt >= maxTxAmount, "tx limit too low");
    maxTxAmount = newTxAmt;
    uint256 newWalletAmt = _totalSupply * maxWalletAmtPermile / 1000 + 1;
    if (newWalletAmt > _totalSupply) { newWalletAmt = _totalSupply; }
    require(newWalletAmt >= maxWalletAmount, "wallet limit too low");
    maxWalletAmount = newWalletAmt;
  }

  function setTaxSwapLimits(uint32 minValue, uint32 minDivider, uint32 maxValue, uint32 maxDivider) external onlyOwner {
    _taxSwapMin = _totalSupply * minValue / minDivider;
    _taxSwapMax = _totalSupply * maxValue / maxDivider;
    require(_taxSwapMax>=_taxSwapMin, "MinMax error");
    require(_taxSwapMax>_totalSupply / 10000, "Upper threshold too low");
  }


  function _transferTaxTokens(address recipient, uint256 amount) private {
    if ( amount > 0 ) {
      _balances[address(this)] = _balances[address(this)] - amount;
      _balances[recipient] = _balances[recipient] + amount;
      emit Transfer(address(this), recipient, amount);
    }
  }

  function _swapTaxAndLiquify() private lockTaxSwap {
    uint256 _taxTokensAvailable = balanceOf(address(this));

    if ( _taxTokensAvailable >= _taxSwapMin && tradingOpen ) {
      if ( _taxTokensAvailable >= _taxSwapMax ) { _taxTokensAvailable = _taxSwapMax; }
      uint256 _tokensForLP = _taxTokensAvailable * _autoLPShares / _totalTaxShares / 2;
      uint256 _tokensToSwap = _taxTokensAvailable - _tokensForLP;
      uint256 _ethPreSwap = address(this).balance;
      _swapTaxTokensForEth(_tokensToSwap);
      uint256 _ethSwapped = address(this).balance - _ethPreSwap;
      if ( _autoLPShares > 0 ) {
        uint256 _ethWeiAmount = _ethSwapped * _autoLPShares / _totalTaxShares ;
        _approveRouter(_tokensForLP);
        _addLiquidity(_tokensForLP, _ethWeiAmount, false);
      }
      uint256 _contractETHBalance = address(this).balance;
      if(_contractETHBalance > 0) { _distributeTaxEth(_contractETHBalance); }
    }
  }

  function _swapTaxTokensForEth(uint256 _tokenAmount) private {
    _approveRouter(_tokenAmount);
    address[] memory path = new address[](2);
    path[0] = address(this);
    path[1] = _uniswapV2Router.WETH();
    _uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(_tokenAmount,0,path,address(this),block.timestamp);
  }

  function _distributeTaxEth(uint256 _amount) private {
    uint16 _taxShareTotal = _ethTaxShares1 + _ethTaxShares2 + _ethTaxShares3;
    if ( _ethTaxShares1 > 0 ) { _ethTaxWallet1.transfer(_amount * _ethTaxShares1 / _taxShareTotal); }
    if ( _ethTaxShares2 > 0 ) { _ethTaxWallet2.transfer(_amount * _ethTaxShares2 / _taxShareTotal); }
    if ( _ethTaxShares3 > 0 ) { _ethTaxWallet3.transfer(_amount * _ethTaxShares3 / _taxShareTotal); }
  }

  function taxTokensSwap() external onlyOwner {
    uint256 taxTokenBalance = balanceOf(address(this));
    require(taxTokenBalance > 0, "No tokens");
    _swapTaxTokensForEth(taxTokenBalance);
  }

  function taxEthSend() external onlyOwner { 
    _distributeTaxEth(address(this).balance); 
  }


  function airdrop(address[] calldata addresses, uint256[] calldata tokenAmounts) external onlyOwner {
    require(addresses.length <= 200,"Wallet count over 200 (gas risk)");
    require(addresses.length == tokenAmounts.length,"Address and token amount list mismach");

    uint256 airdropTotal = 0;
    for(uint i=0; i < addresses.length; i++){
      airdropTotal += (tokenAmounts[i] * 10**_decimals);
    }
    require(_balances[msg.sender] >= airdropTotal, "Token balance lower than airdrop total");

    for(uint i=0; i < addresses.length; i++){
      _balances[msg.sender] -= (tokenAmounts[i] * 10**_decimals);
      _balances[addresses[i]] += (tokenAmounts[i] * 10**_decimals);
      emit Transfer(msg.sender, addresses[i], (tokenAmounts[i] * 10**_decimals) );       
    }
    emit TokensAirdropped(addresses.length, airdropTotal);
  }
}