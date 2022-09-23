// SPDX-License-Identifier: MIT

/*

Token Name: Cardano Hard Fork
Ticker: ADA2.0
Supply: 1B

https://t.me/ADA2ERC20

*/

pragma solidity ^0.8.12;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner)
    public 
    virtual 
    onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB)  external view returns (address pair);
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

contract ADA2 is Context, IERC20, Ownable {

    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;


    string private constant _name = "Cardano Hard Fork";
    string private constant _symbol = unicode"ADA2.0";
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 1000000000 * 10**_decimals;

    uint16 public masterTaxDivisor = 100;

    uint256 public buyAutoLiquidityFee = 1;
    uint256 public buyMarketingFee = 3;
    uint256 public totalBuyFees = buyAutoLiquidityFee + buyMarketingFee;

    uint256 public sellAutoLiquidityFee = 1;
    uint256 public sellMarketingFee = 5;
    uint256 public totalSellFees =  sellAutoLiquidityFee + sellMarketingFee;

    uint256 private maxTxAmount = 100000000 * 10**_decimals; 
    uint256 private maxWalletAmount = 200000000 * 10**_decimals; 
    

    uint256 public tokensForAutoLiquidity;
    uint256 public tokensForAutoBurn;  
    uint256 public tokensForMarketing;
    
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public pairAddress;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;

    address payable private adminWallet;

    event MaxWalletAmountUpdated(uint maxWalletAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
  
    constructor () {
        require(!tradingOpen);
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        
        _tOwned[owner()] = _totalSupply;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[address(uniswapV2Router)] = true;
        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[adminWallet] = true;
    
        adminWallet = payable(0xA57F796fc42781f836192163E84Bf3B9ba517e58);

        uint256 _buyAutoLiquidityFee = 1;
        uint256 _buyMarketingFee = 3;
        uint256 _sellAutoLiquidityFee = 1;
        uint256 _sellMarketingFee = 5;

        maxTxAmount = 100000000 * 10** _decimals;
        maxWalletAmount = 200000000 * 10** _decimals;

        buyAutoLiquidityFee = _buyAutoLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        totalBuyFees = buyAutoLiquidityFee + buyMarketingFee;
        
        sellAutoLiquidityFee = _sellAutoLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        totalSellFees = sellAutoLiquidityFee + sellMarketingFee; 
        
        tradingOpen = false;
        swapEnabled = false;
        
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        emit Transfer(address(0), owner(), _totalSupply);
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

    function totalSupply() public view override returns (uint256) { 
        return _totalSupply; 
    }

    function balanceOf(address account) public view override returns (uint256) { 
        return _tOwned[account];
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

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
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
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");    
        
        require(tradingOpen || _isExcludedFromFee[from] || _isExcludedFromFee[to], "Trading not enabled yet");

        if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to]) {
                require(amount <= maxTxAmount, "Exceeds the _maxTxAmount.");
                require(balanceOf(to) + amount <= maxWalletAmount, "Exceeds the maxWalletSize.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
            if (!inSwap && from != uniswapV2Pair && swapEnabled && contractTokenBalance>0) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
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
            block.timestamp);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        _tOwned[sender] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(sender, recipient, amount) : amount;
        _tOwned[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        if(from == uniswapV2Pair && totalBuyFees > 0 ) { 
            tokensForAutoLiquidity = amount * buyAutoLiquidityFee / masterTaxDivisor;        
            tokensForMarketing = amount * buyMarketingFee / masterTaxDivisor;    
        } else if (to == uniswapV2Pair  && totalSellFees > 0 ) { 
            tokensForAutoLiquidity = amount * sellAutoLiquidityFee / masterTaxDivisor;
            tokensForMarketing = amount * sellMarketingFee / masterTaxDivisor;        
        }
        _tOwned[pairAddress] += tokensForAutoLiquidity;
        emit Transfer(from, pairAddress, tokensForAutoLiquidity);
                       
        _tOwned[address(this)] += tokensForMarketing;
        emit Transfer(from, address(this), tokensForMarketing);

        uint256 feeAmount = tokensForAutoLiquidity + tokensForMarketing;
        return amount - feeAmount;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function updatetWalletandTxtAmount(uint256 _maxTxAmount, uint256 _maxWalletSize) external onlyOwner{
        maxTxAmount = _maxTxAmount * 10 **_decimals;
        maxWalletAmount = _maxWalletSize * 10 **_decimals;
    }

    function updateTxAmount(uint256 _maxTxAmount) external onlyOwner {
        maxTxAmount = _maxTxAmount * 10 **_decimals;
    }

    function updateMaxWallet(uint256 _maxWalletSize) external onlyOwner {
        maxWalletAmount = _maxWalletSize * 10 **_decimals;
    }

    function removeLimits() external onlyOwner{
        maxTxAmount = _totalSupply;
        maxWalletAmount = _totalSupply;
    }
    
    function changeBuyFee(uint256 _newBuyLiquidityFee, uint256 _newBuyMarketingFee)
    public onlyOwner returns (bool)
    {
        require((_newBuyLiquidityFee + _newBuyMarketingFee) <= 20, "ERC20: total buy tax must not be greater than 20");
        buyAutoLiquidityFee = _newBuyLiquidityFee;
        buyMarketingFee = _newBuyMarketingFee;
        totalBuyFees = buyAutoLiquidityFee +  buyMarketingFee;
        return true;
    }
    
    function changeSellFee(uint256 _newSellLiquidityFee, uint256 _newSellMarketingFee)
    public onlyOwner returns (bool)
    {
        require((_newSellLiquidityFee + _newSellMarketingFee) <= 20, "ERC20: total sell tax must not be greater than 20");
        sellAutoLiquidityFee = _newSellLiquidityFee;
        sellMarketingFee = _newSellMarketingFee;
        totalSellFees = sellAutoLiquidityFee +  sellMarketingFee;
        return true;
    }

    function openTrading() external onlyOwner {
        tradingOpen = true;
        swapEnabled = true;  
    }

    function sendETHToFee(uint256 amount) private {
        adminWallet.transfer(amount);
    } 

    receive() external payable{
    }
}