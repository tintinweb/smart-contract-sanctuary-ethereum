// SPDX-License-Identifier: MIT
/**

XENVAULT is a token which implements a reward scheme to buyers and holders.

By buying 2000 tokens or paying 200 tokens or 0.01 ETH, you become the "Key Holder".

If no one else buy/pay before timer runs out, the prize will be sent to Key Holder when anyone buy/sell/pay.

After claiming the prize, the Key Holder will be reset until someone buys/pays again.

== Tokenomics ==
Ticker: XENVAULT
Name: Xen Vault
Total Supply: 1,000,000
Max Tx: 10,000
Max Wallet: 20,000
Tax: 4%/4%

== How to Play ==
Buy 2,000 XENVAULT Tokens or more on Uniswap
or
Pay 200 XENVAULT Tokens via XENVAULT DApp
or
Pay 0.01 ETH via XENVAULT DApp

== Game mechanism formula ==
Action                              | Time Increase                           | Pool Increase
Buy 2000 XENVAULT tokens on Uniswap | 60000 / (2000 x 0.07 * 0.9) = 476 sec   | 2000 x 0.07 x 0.09 = 126 XENVAULT
Pay 200 XENVAULT tokens             | 60000 / (200 * 0.9) = 333 sec           | 200 x 0.9 = 180 XENVAULT
Pay 0.01 ETH                        | 60000 / 1000 = 60 sec                   | 1000 XENVAULT

Max Cap of timer: 10800 sec

== Features ==
Timer countdown increases inverse proportionally according to amount bought/paid
90% of tax/fee goes to prize pool
Prize pool is ever-increasing until a winner takes 50% as prize

== Links ==
Telegram: https://t.me/xenvault
Website: https://xenvault.co
Twitter: https://twitter.com/xenvault

**/
pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

}

contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

contract XenVault is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private bots;
    address payable private _taxWallet;


    uint256 private _preventSwapBefore=30;
    uint256 private _buyCount=0;

    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 1_000_000 * 10**_decimals;
    string private constant _name = "XEN VAULT";
    string private constant _symbol = "XENVAULT";
    uint256 private _buyTax=2;
    uint256 private _sellTax=5;
    uint256 public _maxTxAmount = 15_000 * 10**_decimals;
    uint256 public _maxWalletSize = 30_000 * 10**_decimals;
    uint256 private _minTaxSwap=10_000 * 10 ** _decimals;
    uint256 private _taxSwapAmount=10_000* 10 **_decimals;
    uint256 constant keyEthPrice=0.01 ether;

    address private _keyHolder = address(0x0);
    uint256 public keyMinBuy = 2_000 * 10 ** _decimals;
    uint256 public keyPrice = 200 * 10 ** _decimals;
    uint256 private _claimTime=0;
    uint256 private _prizePool=0;
    uint256 public constant _timerMax=10800;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen=false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint _maxTxAmount);
    event PrizeClaimed(address _winner, uint256 amount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        uint256 taxAmount=amount.mul(7).div(100);
        if (from != owner() && to != owner()) {
            require(!bots[from] && !bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] ) {
                require(amount <= _maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                taxAmount = amount.mul(_buyTax).div(100);
                _buyCount++;

                if(hasPreviousWinner()){
                  claimPrize();
                }
                // buying more than 2000 tokens to become Key Holder
                if(amount>=keyMinBuy){
                  // 90% goes to prize pool
                  addTimer(to,taxAmount.mul(9).div(10));
                }
            }else if(to==uniswapV2Pair && ! _isExcludedFromFee[from]){
                taxAmount = amount.mul(_sellTax).div(100);
            }

            uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance>=_minTaxSwap && _buyCount>=_preventSwapBefore) {
                swapTokensForEth(_taxSwapAmount>amount?amount:_taxSwapAmount);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        _balances[from]=_balances[from].sub(amount);
        _balances[to]=_balances[to].add(amount.sub(taxAmount));
        emit Transfer(from, to, amount.sub(taxAmount));
        if(taxAmount>0){
          _balances[address(this)]=_balances[address(this)].add(taxAmount);
          emit Transfer(from, address(this),taxAmount);
        }
    }

    function payTokensForTheKey() external{
      require(_balances[_msgSender()]>=keyPrice,"Insufficient balance");
      require(_keyHolder!=_msgSender(),"You already are the key holder");
      if(hasPreviousWinner()){
        claimPrize();
      }

      _balances[_msgSender()]=_balances[_msgSender()].sub(keyPrice);
      _balances[address(this)]=_balances[address(this)].add(keyPrice);
      emit Transfer(_msgSender(),address(this),keyPrice);
      addTimer(_msgSender(),keyPrice.mul(9).div(10));
    }

    function payEthForTheKey() external payable{
      require(msg.value >=keyEthPrice);
      require(_keyHolder!=_msgSender(),"You already are the key holder");
      if(hasPreviousWinner()){
        claimPrize();
      }
      addTimer(_msgSender(),1000*10**_decimals);
    }

    function addTimer(address holder, uint256 amount) private{
      _keyHolder=holder;
      if(_claimTime==0){
        _claimTime=block.timestamp;
      }
      _claimTime=_claimTime.add(getTimeIncrease(amount));
      if(_claimTime>block.timestamp+_timerMax){
        _claimTime=block.timestamp+_timerMax;
      }
      _prizePool=_prizePool.add(amount);
    }

    function getTimeIncrease(uint256 amount) public pure returns (uint256){
      amount=amount.div(10**_decimals);
      return amount>0?60000/amount:0;
    }

    function getClaimTime() public view returns (uint256){
      return _claimTime;
    }

    function getKeyHolder() public view returns (address){
      return _keyHolder;
    }

    function hasPreviousWinner() public view returns (bool){
      return _claimTime>0&&block.timestamp>=_claimTime && _keyHolder!=address(0x0);
    }

    function claimPrize() public {
      require(block.timestamp>=_claimTime,"Please wait until the timer runs out");
      require(_keyHolder!=address(0x0),"No key holder now");
      uint256 prize=_prizePool.div(2);
      _balances[_keyHolder]=_balances[_keyHolder].add(prize);
      emit Transfer(address(0x0),_keyHolder,prize);
      emit PrizeClaimed(_keyHolder, prize);
      _keyHolder=address(0x0);
      _claimTime=0;
      _prizePool=_prizePool.sub(prize);
    }

    function getPrizePool() public view returns (uint256){
      return _prizePool;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function delBots(address[] memory notbot) public onlyOwner {
      for (uint i = 0; i < notbot.length; i++) {
          bots[notbot[i]] = false;
      }
    }

    function openTrading() external onlyOwner() {
        require(!tradingOpen,"trading is already open");
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
    }


    receive() external payable {}

    function manualswap() external {
        require(_msgSender() == _taxWallet);
        swapTokensForEth(balanceOf(address(this)));
    }

    function manualsend() external {
        require(_msgSender() == _taxWallet);
        sendETHToFee(address(this).balance);
    }
}