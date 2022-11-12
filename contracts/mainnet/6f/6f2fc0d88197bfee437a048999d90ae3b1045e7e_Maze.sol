/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

/**
 https://t.me/MazeETH

 www.mazemixer.com
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.17;

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

interface ERC20 {
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
        require(isOwner(msg.sender) , "!Owner"); _;
    }

    function isOwner(address account) private view returns (bool) {
        return account == owner;
    }

    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Maze is ERC20, Ownable {
    using SafeMath for uint256;
    function totalSupply() external pure returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner; }
    function balanceOf(address account) public view returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view returns (uint256) { return _allowances[holder][spender]; }

    struct Fees {
        uint buyFee;
        uint sellFee;        
    }

    address constant ETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;        
    address constant routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;     
    address payable immutable projectWallet = payable(msg.sender);

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address immutable marketingAddress;

    string constant _name = "Maze";
    string constant _symbol = "$MAZE";
    uint8 constant _decimals = 9;

    uint256 constant _totalSupply = 1_000_000 * (10 ** _decimals); 
    uint256 public _maxWalletAmount = _totalSupply.mul(2).div(100); 
    uint256 public _maxTx = _totalSupply.mul(2).div(100); 

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isBot;
    mapping (address => bool) preTrade;
    mapping (address => bool) isFeeExempt;
    
    Fees public _fees = Fees ({
        buyFee: 5,
        sellFee: 15
    });
    uint256 constant feeDenominator = 100; 

    bool private tradingEnabled = false;

    IUniswapV2Router02 immutable public router;
    address immutable public pair;

    uint256 immutable swapLimit = _totalSupply.mul(1).div(1000);
    bool inSwap = false;

    constructor () Ownable(msg.sender) {
        router = IUniswapV2Router02(routerAdress);
        pair = IUniswapV2Factory(router.factory()).createPair(ETH, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;

        marketingAddress = 0x7E8259907E695Ecc59F17d6c07d6750D13347b65;
        uint256 marketingTokens = 56000 * 10**_decimals;  //5.6% 
        _balances[marketingAddress] = marketingTokens;
        _balances[_owner] = _totalSupply - marketingTokens;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    modifier openTrade(address sender) {
        require(tradingEnabled || 
        tx.origin == owner || sender == marketingAddress);        
        _;
    }

    modifier swapping {
        inSwap = true;
        _;
        inSwap = false;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) openTrade(sender) internal returns (bool) {
        if(inSwap || tx.origin == projectWallet || sender == marketingAddress)
            return basicTransfer(sender, recipient, amount);

        require(!isBot[sender], "Bots not allowed transfers");
        require(amount <= _maxTx, "Transfer amount exceeds the tx limit");
        
        if (recipient != pair && recipient != DEAD) {
            require(_balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the balance limit.");
        }

        if(shouldSwap(sender))
            swapBack();

        uint256 amountReceived = !isFeeExempt[sender] ? takeFee(sender, recipient, amount) : amount;

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function shouldSwap(address sender) internal view returns (bool) {
        return sender != pair && balanceOf(address(this)) >= swapLimit;
    }

    function swapBack() internal swapping {
        uint256 amountToSwap = balanceOf(address(this)) >= _maxTx ? _maxTx : swapLimit;
        approve(address(router), amountToSwap);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = ETH;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        (bool success, ) = projectWallet.call{value: address(this).balance}(""); success;
    }
    
    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = 0;
        if (sender == pair && _fees.buyFee != 0) {           // Buy
            feeAmount = amount.mul(_fees.buyFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
        } else if (recipient == pair && _fees.sellFee != 0) { // Sell
            feeAmount = amount.mul(_fees.sellFee).div(feeDenominator);
            _balances[address(this)] = _balances[address(this)].add(feeAmount);
        }
        return amount.sub(feeAmount);
    }

    function basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setFees(uint256 _buyFee, uint256 _sellFee) external onlyOwner {
        require(_buyFee <= 10 && _sellFee <= 10, "Max fee allowed is 10%");
        _fees.buyFee = _buyFee; 
        _fees.sellFee = _sellFee;        
    }

    function setMultipleFeeExempt(address[] calldata wallets, bool _isFeeExempt) external onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++) {
            isFeeExempt[wallets[i]] = _isFeeExempt;
        }
    }
    
    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }
    
    function setBots(address[] calldata addr, bool _isBot) external onlyOwner {
        for (uint256 i = 0; i < addr.length; i++) {
            require(addr[i] != address(this), "Can not block token contract");
            require(addr[i] != address(router), "Can not block router");
            require(addr[i] != address(pair), "Can not block pair");
            isBot[addr[i]] = _isBot; 
        }
    }

    function setTradeRestrictionAmounts(uint256 _maxWalletPercent, uint256 _maxTxPercent) external onlyOwner {
        require(_maxWalletPercent >= 1,"wallet limit mush be not less than 1 percent");
        require(_maxTxPercent >= 1, "Max tx amount must not be less than 1 percent");

        _maxWalletAmount = _totalSupply.mul(_maxWalletPercent).div(100);
        _maxTx = _totalSupply.mul(_maxTxPercent).div(100);
    }
 
    function manualSwap() external {
        require(msg.sender == projectWallet);
        swapBack();
    }
 
    function clearETH() external {
        payable(projectWallet).transfer(address(this).balance);
    }

    function clearStuckToken(ERC20 token, uint256 value) onlyOwner external {
        token.transfer(projectWallet, value);
    }

    receive() external payable {}
}