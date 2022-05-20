/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

/*
🔥 🔥 Zhanshi ($ZHAN) 🔥🔥

💎 Zhanshi ($ZHAN) 💎 brings a healthy 🔥 tax which will make the token hyper deflationary. 

The burn will be a true burn and actually remove the tokens from the total tokens reducing the total supply with every sell.
Since there are not many decimals after the token amount, the price has no choice but to rise.
  

🟢Buys: 3% Marketing
🔴Sells: 8% Burn/Marketing

Twitter - www.twitter.com/zhanshitoken
Website - http://zhanshitoken.com
*/

pragma solidity 0.8.9;

// SPDX-License-Identifier: Unlicensed

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
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
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
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract Zhanshi is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balance;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isBlacklisted;

    uint256 private _totalSupply = 1000 * 1e3;
    uint256 public _totalBurned;

    string private _name = "Zhanshi";
    string private _symbol = "ZHAN";
    uint8 private _decimals = 3;
    
    address payable public zhanWallet = payable(0xAF038d131fa44B450DF8d5b6ba2078f9D426f16B);
    address payable public deployWallet = payable(0x46f4Bf397D4Ed499FF399795C4CD14EAb75C03AF);


    uint256 private burnBuyTax = 1;
    uint256 public burnSellTax = 1;
    uint256 private burnTax;
    uint256 private _liquidityMarketingFee;

    uint256 public _liquidityMarketingBuyFee = 1;
    uint256 private _liquidityMarketingSellFee = 1;

    uint256 private _previousBurnTax = burnTax;
    uint256 private _previousLiquidityMarketingFee = _liquidityMarketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    
    uint256 public _maxTxAmount = 20 * 1e3;
    bool public burnMode = true;
    uint256 public swapThresh = 5 * 1e2;
    

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event NAME(string _name);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor () {
        _balance[_msgSender()] = _totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router = _uniswapV2Router;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[zhanWallet] = true;
        _isExcludedFromFee[deployWallet] = true;


        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }
 
    function MaxTxAmount(uint256 maxTxAmount) external {
        require(_msgSender() == deployWallet);
        require(maxTxAmount > 20 * 1e3);
        _maxTxAmount = maxTxAmount * 1e3;
    }

    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external {
        require(_msgSender() == deployWallet);
        swapThresh = SwapThresholdAmount * 1e3;
    }
    
    function claimETH (address walletaddress) external {
        require(_msgSender() == deployWallet);
        payable(walletaddress).transfer(address(this).balance);
    }
    
    function clearStuckBalance (address payable walletaddress) external {
        require(_msgSender() == deployWallet);
        walletaddress.transfer(address(this).balance);
    }
    
    function blacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = true;
    }
    
    function removeFromBlacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = false;
    }
    
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    
     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burning(address _account, uint _amount) private {  
        require( _amount <= balanceOf(_account));
        _balance[_account] = _balance[_account].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _projectSupport(uint _amount) private {
        _balance[address(this)] = _balance[address(this)].add(_amount);
    }
    
    function removeAllFee() private {
        if(burnTax == 0 && _liquidityMarketingFee == 0) return;
        
        _previousBurnTax = burnTax;
        _previousLiquidityMarketingFee = _liquidityMarketingFee;
        
        burnTax = 0;
        _liquidityMarketingFee = 0;
    }
    
    function restoreAllFee() private {
        burnTax = _previousBurnTax;
        _liquidityMarketingFee = _previousLiquidityMarketingFee;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to]);
        if(! _isExcludedFromFee[to] && ! _isExcludedFromFee[from]) {
        burnTax = burnBuyTax;
        _liquidityMarketingFee = _liquidityMarketingBuyFee;
        }

        if(from != owner() && to != owner() && ! _isExcludedFromFee[to] && ! _isExcludedFromFee[from]){
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));        
        if(contractTokenBalance >= _maxTxAmount){
            contractTokenBalance = _maxTxAmount;
        }
        
        bool overMinTokenBalance = contractTokenBalance >= swapThresh;
        if (overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = swapThresh;
            swapAndLiquify(contractTokenBalance);
        }

        bool takeFee = true;        
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
            burnTax = burnSellTax;
            _liquidityMarketingFee = _liquidityMarketingSellFee;
        }

        _tokenTransfer(from,to,amount,takeFee);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {        

        if(!takeFee) removeAllFee();

        uint256 tokensToBurn = amount.mul(burnTax).div(100);
        uint256 projectSupport = amount.mul(_liquidityMarketingFee).div(100);
        uint256 amountPreBurn = amount.sub(tokensToBurn);
        uint256 amountTransferred = amount.sub(projectSupport).sub(tokensToBurn);

        burning(sender, tokensToBurn);
        _projectSupport(projectSupport);        
        _balance[sender] = _balance[sender].sub(amountPreBurn);
        _balance[recipient] = _balance[recipient].add(amountTransferred);

        if(burnMode && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            burning(uniswapV2Pair, tokensToBurn);
        }
        
        emit Transfer(sender, recipient, amountTransferred);
        
        if(!takeFee) restoreAllFee();
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        uint256 toSwap = contractTokenBalance;
        swapTokensForEth(toSwap);
        payable(zhanWallet).transfer(address(this).balance);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
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
            address(this),
            block.timestamp
        );
    }


}