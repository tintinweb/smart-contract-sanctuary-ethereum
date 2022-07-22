/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

/**
   ______   __        __                                                ______                     
 /      \ |  \      |  \                                              |      \                    
|  $$$$$$\| $$____   \$$  _______   ______   _______    ______         \$$$$$$ _______   __    __ 
| $$   \$$| $$    \ |  \ /       \ |      \ |       \  |      \         | $$  |       \ |  \  |  \
| $$      | $$$$$$$\| $$|  $$$$$$$  \$$$$$$\| $$$$$$$\  \$$$$$$\        | $$  | $$$$$$$\| $$  | $$
| $$   __ | $$  | $$| $$ \$$    \  /      $$| $$  | $$ /      $$        | $$  | $$  | $$| $$  | $$
| $$__/  \| $$  | $$| $$ _\$$$$$$\|  $$$$$$$| $$  | $$|  $$$$$$$       _| $$_ | $$  | $$| $$__/ $$
 \$$    $$| $$  | $$| $$|       $$ \$$    $$| $$  | $$ \$$    $$      |   $$ \| $$  | $$ \$$    $$
  \$$$$$$  \$$   \$$ \$$ \$$$$$$$   \$$$$$$$ \$$   \$$  \$$$$$$$       \$$$$$$ \$$   \$$  \$$$$$$ 
                                                                                                  


  Tg: t.me/ChisanaInu                                                                                              

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
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
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
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

contract Chisana is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress;
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Chisana Inu";
    string constant _symbol = "CINU";
    uint8 constant _decimals = 9;

    uint256 _totalSupply = 1 * 10**6 * (10 ** _decimals); // 1 Million

    mapping(address => uint256) _balances;
    mapping(address => mapping (address => uint256)) _allowances;

    address public marketingFeeReceiver = 0x1BCAe0CA52aA37F492e3d553cb4a24C54EAf4E6c;

    IDEXRouter public router;
    address public pair;

    struct user {
        uint256 firstBuy;
        uint256 lastTradeTime;
    }

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;
    mapping(address => bool) public isBot;
    mapping(address => user) public tradeData;

    uint256 liquidityFee = 1;
    uint256 marketingFee = 5;
    uint256 totalFee = liquidityFee + marketingFee;
    uint256 feeDenominator = 100;

    bool inSwap;
    bool public swapEnabled = true;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    uint256 public maxWalletAmount = (_totalSupply * 100) / 30000; //3% of Total Supply  
    uint256 public maxSellTransactionAmount = (_totalSupply * 100) / 500000; //0.5% of Total Supply
    uint256 public swapThreshold = (_totalSupply * 500) / 100000; //0.5% of Total Supply
    uint256 public sellCooldownSeconds = 86400;//86400; //1 Day
    uint256 public sellPercent = 50; //0.5%

    bool private sellLimited = true;
    bool private p2pLimited = true;

    uint256 public startTime;

    modifier checkLimit(address sender, address recipient, uint256 amount) {
        if(!isTxLimitExempt[sender] && recipient == pair) {
            require(sold[sender][getCurrentDay()] + amount <= getUserSellLimit(sender), "Cannot sell or transfer more than limit.");
        }
        _;
    }
    mapping(address => mapping(uint256 => uint256)) public sold;

    constructor () Ownable(msg.sender) {
    
            routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(router.WETH(), address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[_owner] = true;
        isFeeExempt[0x1BCAe0CA52aA37F492e3d553cb4a24C54EAf4E6c] = true;
        
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[0x1BCAe0CA52aA37F492e3d553cb4a24C54EAf4E6c] = true;
        isTxLimitExempt[DEAD] = true;

        startTime = block.timestamp;

        _balances[_owner] = _totalSupply;
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function getCurrentDay() public view returns (uint256) {
        return minZero(block.timestamp, startTime).div(sellCooldownSeconds);
    }

    function getCirculatingSupply() public view returns (uint256) {
        return
            (_totalSupply - _balances[DEAD]);
    }

    function getUserSellLimitMultiplier(address sender) internal view returns (uint256) {
        uint multiplier;

        if(tradeData[sender].lastTradeTime == 0) {
            multiplier = ((block.timestamp - tradeData[sender].firstBuy) / sellCooldownSeconds).mul(1000);
        } else {
            multiplier = ((block.timestamp - tradeData[sender].lastTradeTime) / sellCooldownSeconds).mul(1000);
        }

        return multiplier < 1000 ? 1000 : multiplier;
    }

    function getUserSellLimit(address sender) public view returns (uint256) {
        uint256 calc = getUserSellLimitMultiplier(sender).div(1000);
        uint256 calc2 = calc.mul(sellPercent);

        return getCirculatingSupply().mul(calc2).div(10000);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal checkLimit(sender, recipient, amount) returns (bool) {
        require(!isBot[sender], "Bot Address");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(recipient != pair && sender != pair && recipient != DEAD && p2pLimited){
            require(isFeeExempt[recipient] || isFeeExempt[sender] || isTxLimitExempt[recipient] || isTxLimitExempt[sender], "P2P not allowed");
        }

        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= maxWalletAmount, "Transfer amount exceeds the bag size.");
        }

         if(!isTxLimitExempt[recipient] && sender == pair) {
            tradeData[recipient].firstBuy = block.timestamp;
        }

        if(!isTxLimitExempt[sender] && recipient == pair) {
            tradeData[sender].lastTradeTime = block.timestamp;
            sold[sender][getCurrentDay()] = sold[sender][getCurrentDay()].add(amount);
        }
        
        if(shouldSwapBack()){ swapBack(); } 

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
       
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = amount.mul(totalFee).div(feeDenominator);
        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);
        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 contractTokenBalance = swapThreshold;
        uint256 amountToLiquify = contractTokenBalance.mul(liquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);

        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                marketingFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }
    }

    function buyTokens(uint256 amount, address to) internal swapping {
        address[] memory path = new address[](2);
        path[0] = router.WETH();
        path[1] = address(this);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
    }

    function clearStuckBalance() external onlyOwner {
        payable(marketingFeeReceiver).transfer(address(this).balance);
    }

    function clearStuckTokens(address _tokenAddr, address _to, uint256 _amount) external onlyOwner {
        require(ERC20(_tokenAddr).transfer(_to, _amount), "Transfer failed");
    }

    function setWalletLimit(uint256 amountPercent) external onlyOwner {
        maxWalletAmount = (_totalSupply * amountPercent ) / 1000;
    }

    function isBots(address botAddress, bool status) external onlyOwner {      
        isBot[botAddress] = status;
    }

    function addBots(address[] calldata botAddress, bool status) external onlyOwner {
        for (uint256 i = 0; i < botAddress.length; i++) {
             isBot[botAddress[i]] = status;
        }      
    }

     function setFees(uint256 _LiquidityFee, uint256 _MarketingFee) external onlyOwner {
        marketingFee = _MarketingFee;
        liquidityFee = _LiquidityFee;
        totalFee = liquidityFee + marketingFee;

        require(totalFee <= 25, "Must keep fees at 25% or less");
    }
  
    function setContractLimits(bool sellLimited_, bool p2pLimited_) external onlyOwner {
        sellLimited = sellLimited_;
        p2pLimited = p2pLimited_;
    }
    
    function viewContractLimits() external view returns (bool isSellLimited, bool isP2PLimited){
        return(sellLimited,p2pLimited);
    }

    function setADMSettings(uint256 sellCooldownSeconds_, uint256 maxSellTransactionAmount_, uint256 sellPercent_) external onlyOwner {
        sellCooldownSeconds = sellCooldownSeconds_;
        maxSellTransactionAmount = maxSellTransactionAmount_;
        sellPercent = sellPercent_;
    }

    function viewADMSettings() external view returns (uint sellCooldownSecs, uint maxSellTransactionAmt, uint256 sellPercentAmt){
        return(sellCooldownSeconds,maxSellTransactionAmount,sellPercent);
    }

    function minZero(uint a, uint b) private pure returns(uint) {
        if (a > b) {
           return a - b; 
        } else {
           return 0;    
        }    
    } 

    event AutoLiquify(uint256 amountETH, uint256 amountBEE);

}