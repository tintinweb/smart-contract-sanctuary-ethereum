/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: NONE

/**

Token Name: Shōrai no Kyori
Symbol: DISTANCE
Supply: 1,000,000,000,000,000,000 Quintillion
Max Buy at Launch: 5,000,000,000,000,000 0.5% of supply

4.5% Tax
Tokenomics: 0.5% auto-liquidity, 0.5% burn, 3.5% project wallet

Telegram: https://t.me/DISTANCETOKEN
Twitter: https://twitter.com/DistanceERC20

*/
pragma solidity ^0.8.4;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
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

contract SmartContract is Context, IERC20, Ownable {

    using SafeMath for uint256;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;

    string private constant _name = unicode"Shōrai no Kyori";
    string private constant _symbol = "DISTANCE";
    uint8 private constant _decimals = 9;

    uint256 public buyAutoBurnFee = 50;
    uint256 public buyAutoLiquidityFee = 50;
    uint256 public buyMarketingFee = 350;
    uint256 public totalBuyFees = buyAutoBurnFee + buyAutoLiquidityFee + buyMarketingFee;

    uint256 public sellAutoBurnFee = 50;
    uint256 public sellAutoLiquidityFee = 50;
    uint256 public sellMarketingFee = 350;
    uint256 public totalSellFees = sellAutoBurnFee + sellAutoLiquidityFee + sellMarketingFee;

    uint256 public tokensForAutoBurn;
    uint256 public tokensForAutoLiquidity;
    uint256 public tokensForMarketing;
    uint16 public masterTaxDivisor = 10000;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public pairAddress;
    
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    uint256 private constant _tTotal = 1000000000000000000 * 10**9;
    uint256 private maxWalletAmount = 5000000000000001 * 10**9;
    uint256 private maxTxAmount = 5000000000000001 * 10**9;
    address payable private feeAddrWallet;

    event MaxWalletAmountUpdated(uint maxWalletAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
  
    constructor () {
        require(!tradingOpen,"trading is already open");
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        pairAddress = IUniswapV2Factory(_uniswapV2Router.factory()).getPair(address(this), _uniswapV2Router.WETH());
        feeAddrWallet = payable(0x3e56075f49e38E0E2C4B43de5688ee4b23565539); 
        _tOwned[owner()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[feeAddrWallet] = true;
        uint256 _buyAutoBurnFee = 50;
        uint256 _buyAutoLiquidityFee = 50;
        uint256 _buyMarketingFee = 3500;
        uint256 _sellAutoBurnFee = 50;
        uint256 _sellAutoLiquidityFee = 50;
        uint256 _sellMarketingFee = 350;
        buyAutoBurnFee = _buyAutoBurnFee;
        buyAutoLiquidityFee = _buyAutoLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        totalBuyFees = buyAutoBurnFee + buyAutoLiquidityFee + buyMarketingFee;
        sellAutoBurnFee = _sellAutoBurnFee;
        sellAutoLiquidityFee = _sellAutoLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        totalSellFees = sellAutoBurnFee + sellAutoLiquidityFee + sellMarketingFee;
        swapEnabled = true;
        maxTxAmount = 5000000000000001 * 10**9;
        maxWalletAmount = 5000000000000001 * 10**9;
        tradingOpen = true;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) { return _name; }
    function symbol() public pure returns (string memory) { return _symbol; }
    function decimals() public pure returns (uint8) { return _decimals; }
    function totalSupply() public pure override returns (uint256) { return _tTotal; }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
    function transfer(address recipient, uint256 amount) public override returns (bool) { _transfer(_msgSender(), recipient, amount); return true; }
    function allowance(address owner, address spender) public view override returns (uint256) { return _allowances[owner][spender]; }
    function approve(address spender, uint256 amount) public override returns (bool) { _approve(_msgSender(), spender, amount); return true; }

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
            block.timestamp
        );
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        _tOwned[sender] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(sender, recipient, amount) : amount;
        _tOwned[recipient] += amountReceived;
        emit Transfer(sender, recipient, amountReceived);
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        if(from == uniswapV2Pair && totalBuyFees > 0 ) { 
            tokensForAutoBurn = amount * buyAutoBurnFee / masterTaxDivisor;
            tokensForAutoLiquidity = amount * buyAutoLiquidityFee / masterTaxDivisor;
            tokensForMarketing = amount * buyMarketingFee / masterTaxDivisor;    
        } else if (to == uniswapV2Pair  && totalSellFees > 0 ) { 
            tokensForAutoBurn = amount * sellAutoBurnFee / masterTaxDivisor;
            tokensForAutoLiquidity = amount * sellAutoLiquidityFee / masterTaxDivisor;
            tokensForMarketing = amount * sellMarketingFee / masterTaxDivisor;        
        }
        _tOwned[DEAD] += tokensForAutoBurn;
        emit Transfer(from, DEAD, tokensForAutoBurn);
        _tOwned[pairAddress] += tokensForAutoLiquidity;
        emit Transfer(from, pairAddress, tokensForAutoLiquidity);
        _tOwned[address(this)] += tokensForMarketing;
        emit Transfer(from, address(this), tokensForMarketing);
        uint256 feeAmount = tokensForAutoBurn + tokensForMarketing + tokensForAutoLiquidity;
        return amount - feeAmount;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function SetWalletandTxtAmount(uint256 _maxTxAmount, uint256 _maxWalletSize) external onlyOwner{
        maxTxAmount = _maxTxAmount * 10 **_decimals;
        maxWalletAmount = _maxWalletSize * 10 **_decimals;
    }

    function updateBuyFees(uint256 _buyAutoBurnFee, uint256 _buyAutoLiquidityFee, uint256 _buyMarketingFee) external onlyOwner {
        buyAutoBurnFee = _buyAutoBurnFee;
        buyAutoLiquidityFee = _buyAutoLiquidityFee;
        buyMarketingFee = _buyMarketingFee;
        totalBuyFees = buyAutoBurnFee + buyAutoLiquidityFee + buyMarketingFee;
        require(totalBuyFees <= 20, "Must keep fees at 20% or less");
    }
    
    function updateSellFees(uint256 _sellAutoBurnFee, uint256 _sellAutoLiquidityFee, uint256 _sellMarketingFee) external onlyOwner {
        sellAutoBurnFee = _sellAutoBurnFee;
        sellAutoLiquidityFee = _sellAutoLiquidityFee;
        sellMarketingFee = _sellMarketingFee;
        totalSellFees = sellAutoBurnFee + sellAutoLiquidityFee + sellMarketingFee;
        require(totalSellFees <= 20, "Must keep fees at 20% or less");
    }

    function sendETHToFee(uint256 amount) private {
        feeAddrWallet.transfer(amount);
    } 

    receive() external payable{
    }
}