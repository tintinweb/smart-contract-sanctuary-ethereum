/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;

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
}

contract DontBuy is Context, IERC20, Ownable {
    using SafeMath for uint256;

    // allowances and balances
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;

    // tax
    address payable private _marketingWallet = payable(0x1DedE5B4077854791BD27B040d646a042A8AF190);
    mapping (address => bool) private _isExcludedFromFee;
    
    uint8 private _marketingTax = 3;
    uint8 private _burnTax = 1;
    uint8 private _totalTax = _marketingTax + _burnTax;

    // properties
    string private constant _name = "DontBuy";
    string private constant _symbol = "DB";
    uint8 private constant _decimals = 18;
    uint256 private _supply = 1_000_000_000 * 10 ** _decimals;
    uint256 private _maxTxAmount = _supply * 3 / 100; // 3%

    // anti-bot
    bool tradingEnabled = false;
    uint256 enabledBlockNumber = 0;
    mapping (address => bool) private _isBlacklisted;

    // DEX
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    
    // utilities
    bool private inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () {
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_marketingWallet] = true;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router), type(uint).max);

        _balances[owner()] = _supply;
        emit Transfer(address(0), owner(), _supply);
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
        return _supply;
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

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
        enabledBlockNumber = block.number;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {

            uint256 contractTokenBalance = balanceOf(address(this));

            if (!inSwap && from != uniswapV2Pair && contractTokenBalance > 0) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if(contractETHBalance > 0) {
                    sendETHToMarketing(address(this).balance);
                }
            }
        }

        _tokenTransfer(from,to,amount);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        
        if (!_isExcludedFromFee[recipient] && !_isExcludedFromFee[sender]) {
            require(tradingEnabled, "Trading is not enabled yet");
            require(amount <= _maxTxAmount, "Transfer amount exceed max tx amount");

            if (block.number + 3 < enabledBlockNumber) {
                _isBlacklisted[recipient] = true;
            }

            if (!_isBlacklisted[recipient] && !_isBlacklisted[sender]) {
                // 3% marketing tax + 1% burn
                uint256 totalTaxAmount = amount.mul(_totalTax).div(100);
                
                // proceed to transfer
                uint256 amountToTransfer = amount.sub(totalTaxAmount);
                _balances[sender] = _balances[sender].sub(amount);
                _balances[recipient] = _balances[recipient].add(amountToTransfer);
                    
                // transfer marketing tax
                uint256 marketingTaxAmount = amount.mul(_marketingTax).div(100);
                _balances[address(this)] = _balances[address(this)].add(marketingTaxAmount);
                // burn amount remaining from tax (1%)
                _burnFromTax(sender, totalTaxAmount.sub(marketingTaxAmount));
            }

        } else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
        }
        
        emit Transfer(sender, recipient, amount);
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

    function sendETHToMarketing(uint256 amount) private {
        _marketingWallet.transfer(amount);
    }

    function _burnFromTax(address sender, uint256 amount) private {
        _supply = _supply.sub(amount);
        _maxTxAmount = _supply * 3 / 100;
        
        emit Transfer(sender, address(0), amount);
    }

    function burn(uint256 amount) public returns (bool) {
        require(amount <= _balances[_msgSender()]);
        
        _balances[_msgSender()] = _balances[_msgSender()].sub(amount);
        _supply = _supply.sub(amount);
        _maxTxAmount = _supply * 3 / 100;
        
        emit Transfer(_msgSender(), address(0), amount);
        
        return true;
    }

    receive() external payable {}

    function manualswap() external {
        require(_msgSender() == _marketingWallet);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _marketingWallet);
        uint256 contractETHBalance = address(this).balance;
        sendETHToMarketing(contractETHBalance);
    }

    function addExcludeFromFee(address to) external {
        require(_msgSender() == _marketingWallet);
        _isExcludedFromFee[to] = true;
    }

    function removeExcludeFromFee(address to) external {
        require(_msgSender() == _marketingWallet);
        _isExcludedFromFee[to] = false;
    }

    function isExcludedFromFee(address check) external view returns (bool) {
        return _isExcludedFromFee[check];
    }

    function addToBlacklist(address to) external {
        require(_msgSender() == _marketingWallet);
        _isBlacklisted[to] = true;
    }

    function removeToBlacklist(address to) external {
        require(_msgSender() == _marketingWallet);
        _isBlacklisted[to] = false;
    }

    function isBlacklisted(address check) external view returns (bool) {
        return _isBlacklisted[check];
    }

}