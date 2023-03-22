/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT

/*
website: https://travelclubcrypto.com/
telegram: https://t.me/travelclubcryptollc
*/

pragma solidity 0.8.19;

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

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
}

contract Ownable is Context {
    address private _owner;
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract TCC is IERC20, Ownable {
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Travel Club Crypto";
    string private constant _symbol = "$TCC";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private constant _totalSupply = 100000000 * 10**18;               // 100 million
    uint256 public constant maxWalletAmount = _totalSupply * 2 / 100;         // 2%
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isWhitelisted;
    uint8 public buyTax = 5;
    uint8 public sellTax = 10;
    uint8 public lpRatio = 5;
    uint8 public marketingRatio = 7;
    uint8 public devRatio = 3;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public constant marketingWallet = payable(0xEE34626fE0373934C242C183a272DEF5Bb148Ae8);
    address public constant devWallet = payable(0xb5e8aAa4389EE162612887522Cb38f695f6bb92f);
    bool private tradingIsOpen = false;

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IFactory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[devWallet] = true;
        _isExcludedFromFee[deadWallet] = true;
        _isExcludedFromMaxWalletLimit[owner()] = true;
        _isExcludedFromMaxWalletLimit[address(uniswapV2Router)] = true;
        _isExcludedFromMaxWalletLimit[uniswapV2Pair] = true;
        _isExcludedFromMaxWalletLimit[address(this)] = true;
        _isExcludedFromMaxWalletLimit[marketingWallet] = true;
        _isExcludedFromMaxWalletLimit[devWallet] = true;
        _isExcludedFromMaxWalletLimit[deadWallet] = true;
        _isWhitelisted[owner()] = true;
        balances[owner()] = _totalSupply;
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable {} // so the contract can receive eth

    function openTrading() external onlyOwner {
        require(!tradingIsOpen, "trading is already open");   
        tradingIsOpen = true;
    }

    function setFees(uint8 newBuyTax, uint8 newSellTax) external onlyOwner {
        require(newBuyTax <= 10 && newSellTax <= 10, "fees must be <=10%");
        require(newBuyTax != buyTax || newSellTax != sellTax, "new fees cannot be the same as old fees");
        buyTax = newBuyTax;
        sellTax = newSellTax;
    }

    function addWhitelist(address newAddress) external onlyOwner {
        require(!_isWhitelisted[newAddress], "address already added");
        _isWhitelisted[newAddress] = true;
    }

    function setRatios(uint8 newLpRatio, uint8 newMarketingRatio, uint8 newDevRatio) external onlyOwner {
        require(newLpRatio + newMarketingRatio + newDevRatio == buyTax + sellTax, "ratios must add up to total tax");
        lpRatio = newLpRatio;
        marketingRatio = newMarketingRatio;
        devRatio = newDevRatio;
    }

    function excludeFromMaxWalletLimit(address account) external onlyOwner {
        require(!_isExcludedFromMaxWalletLimit[account], "address is already excluded from max wallet");
        _isExcludedFromMaxWalletLimit[account] = true;
    }

    function excludeFromFees(address account) external onlyOwner {
        require(!_isExcludedFromFee[account], "address is already excluded from fees");
        _isExcludedFromFee[account] = true;
    }

    function withdrawStuckETH() external onlyOwner {
        require(address(this).balance > 0, "cannot send more than contract balance");
        (bool success,) = address(owner()).call{value: address(this).balance}("");
        require(success, "error withdrawing ETH from contract");
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        require(amount <= _allowances[sender][msg.sender], "ERC20: transfer amount exceeds allowance.");
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(msg.sender,spender,_allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[msg.sender][spender], "ERC20: decreased allownace below zero.");
        _approve(msg.sender,spender,_allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address");
        require(to != address(0), "cannot transfer to the zero address");
        require(amount > 0, "transfer amount must be greater than zero");
        require(amount <= balanceOf(from), "cannot transfer more than balance"); 
        require(tradingIsOpen || _isWhitelisted[to] || _isWhitelisted[from], "trading is not open yet");
        require(_isExcludedFromMaxWalletLimit[to] || balanceOf(to) + amount <= maxWalletAmount, "cannot exceed maxWalletAmount");
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            balances[from] -= amount;
            balances[to] += amount;
            emit Transfer(from, to, amount);
        } else {
            balances[from] -= amount;
            if (from == uniswapV2Pair) { // buy
                if (buyTax > 0) { 
                    balances[address(this)] += amount * buyTax / 100;
                    emit Transfer(from, address(this), amount * buyTax / 100);
                }
                balances[to] += amount - (amount * buyTax / 100);
                emit Transfer(from, to, amount - (amount * buyTax / 100));
            } else { // sell
                if (sellTax > 0) {
                    balances[address(this)] += amount * sellTax / 100;         
                    emit Transfer(from, address(this), amount * sellTax / 100); 
                    if (balanceOf(address(this)) > _totalSupply / 4000) { // .025% threshold for swapping
                        uint256 tokensForLp = balanceOf(address(this)) * lpRatio / (lpRatio + marketingRatio + devRatio) / 2;
                        _swapTokensForETH(balanceOf(address(this)) - tokensForLp);
                        bool success = false;
                        if (lpRatio > 0) { 
                            _addLiquidity(tokensForLp, address(this).balance * lpRatio / (lpRatio + marketingRatio + devRatio), deadWallet); 
                        }
                        if (marketingRatio > 0) { 
                            (success,) = marketingWallet.call{value: address(this).balance * marketingRatio / (marketingRatio + devRatio), gas: 30000}(""); 
                        }
                        if (devRatio > 0) { 
                            (success,) = devWallet.call{value: address(this).balance, gas: 30000}(""); 
                        }
                    }
                }
                balances[to] += amount - (amount * sellTax / 100);
                emit Transfer(from, to, amount - (amount * sellTax / 100));
            }
        }
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function _addLiquidity(uint256 tokenAmount, uint256 ethAmount, address lpRecipient) private {
		_approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this), tokenAmount, 0, 0, lpRecipient, block.timestamp);
    }
}