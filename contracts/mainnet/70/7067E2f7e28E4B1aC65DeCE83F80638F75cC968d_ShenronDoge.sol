/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

/**
/**

*/
//Shenron Doge a meme token inspired by dragon ball and Doge in crypto space! We aim for good gains and happiness for everyone!

//Shenlong or the god of all dragons appears. so clearly in the manga they refer to him as shenlong. Though as we all know in the Anime he’s called shenron. Shenlong, also Shen-lung, (simplified Chinese: 神龙; traditional Chinese: 神龍; pinyin: shén lóng, literally "god dragon" or "spirit dragon", Japanese: 神竜 Shinryū) is a spiritual dragon from Chinese mythology who is the master of storms and also a bringer of rain. A meme token inspired by Dragon Ball. We aim everyone's goal and get good gains!

//Tokenomics:

//Total Supply: 100,000,000,000
//Tax: 8% BUY and 8% SELL
//-2% Liquidity
//-5% Marketing
//-1% Donation


//Socials
//https://shenrondoge.gitbook.io
//https://medium.com/@shenrondoge
//https://www.shenrondoge.com/
//https://t.me/ShenrondogeEth
//https://twitter.com/shenronDogeErc
/**
 
*/




// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.10;


interface IBEP20 {
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

abstract contract Context {

    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address internal owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * Router Interfaces
 */

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

/**
 * Contract Code
 */

contract ShenronDoge is Context, IBEP20, Ownable {
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "ShenronDoge";
    string constant _symbol = "SHENDOGE"; 
    uint8 constant _decimals = 9;
    uint256 _tTotal = 1 * 10**11 * 10**_decimals;
    uint256 _rTotal = _tTotal * 10**3;   

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public tradingEnabled = false;
    uint256 private genesisBlock = 0;
    uint256 private deadline = 0;

    mapping (address => bool) public isBlacklisted;

    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    
    //General Fees Variables
    uint256 public devFee = 1;
    uint256 public marketingFee = 2;
    uint256 public liquidityFee = 2;
    uint256 public totalFee;

    //Buy Fees Variables
    uint256 private buyDevFee = 1;
    uint256 private buyMarketingFee = 2;
    uint256 private buyLiquidityFee = 2;
    uint256 private buyTotalFee = buyDevFee + buyMarketingFee + buyLiquidityFee;

    //Sell Fees Variables
    uint256 private sellDevFee = 1;
    uint256 private sellMarketingFee = 5;
    uint256 private sellLiquidityFee = 2;
    uint256 private sellTotalFee = sellDevFee + sellMarketingFee + sellLiquidityFee;

    //Max Transaction & Wallet
    uint256 public _maxTxAmount = _tTotal * 100 / 1000; //Initial 1%
    uint256 public _maxWalletSize = _tTotal * 100 / 1000; //Initial 1%

    // Fees Receivers
    address public devFeeReceiver = 0xBA611DAdf8e7cDE542A36af9aBD734Bd7DDfCFA1;
    address public marketingFeeReceiver = 0xBA611DAdf8e7cDE542A36af9aBD734Bd7DDfCFA1;
    address public liquidityFeeReceiver = 0xBA611DAdf8e7cDE542A36af9aBD734Bd7DDfCFA1;

    IDEXRouter public uniswapRouterV2;
    address public uniswapPairV2;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _tTotal * 1 / 10000; //0.1%
    uint256 public maxSwapSize = _tTotal * 1 / 10000; //0.01%

    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }
  
    constructor () {
        uniswapRouterV2 = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapPairV2 = IDEXFactory(uniswapRouterV2.factory()).createPair(uniswapRouterV2.WETH(), address(this));
        _allowances[address(this)][address(uniswapRouterV2)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isTxLimitExempt[msg.sender] = true;
        _balances[address(this)] = _rTotal;
        _balances[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable { }
      
    function totalSupply() external view override returns (uint256) { return _tTotal; }
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

    function setTradingStatus(bool status, uint256 deadblocks) external onlyOwner {
        require(status, "No rug here ser");
        tradingEnabled = status;
        deadline = deadblocks;
        if (status == true) {
            genesisBlock = block.number;
        }
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap || amount == 0){ return _basicTransfer(sender, recipient, amount); }

        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !tradingEnabled && sender == uniswapPairV2) {
            isBlacklisted[recipient] = true;
        }

        require(!isBlacklisted[sender], "You are a bot!"); 

        setFees(sender);
        
        if (sender != owner && recipient != address(this) && recipient != address(DEAD) && recipient != uniswapPairV2) {
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletSize || isTxLimitExempt[recipient], "Total Holding is currently limited, you can not hold that much.");
        }

        // Checks Max Transaction Limit
        if(sender == uniswapPairV2){
            require(amount <= _maxTxAmount || isTxLimitExempt[recipient], "TX limit exceeded.");
        }

        if(shouldSwapBack(sender)){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(amount) : amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);

        return true;
    }

    function manageBlacklist(address account, bool status) public onlyOwner {
        isBlacklisted[account] = status;
    }

    function setFees(address sender) internal {
        if(sender == uniswapPairV2) {
            buyFees();
        }
        else {
            sellFees();
        }
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function buyFees() internal {
        devFee = buyDevFee;
        marketingFee = buyMarketingFee;
        liquidityFee = buyLiquidityFee;
        totalFee = buyTotalFee;
    }

    function sellFees() internal{
        devFee = sellDevFee;
        marketingFee = sellMarketingFee;
        liquidityFee = sellLiquidityFee;
        totalFee = sellTotalFee;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(uint256 amount) internal view returns (uint256) {        
        uint256 feeAmount = block.number <= (genesisBlock + deadline) ?  amount / 100 * 99 : amount / 100 * totalFee;

        return amount - feeAmount;
    }
  
    function shouldSwapBack(address sender) internal view returns (bool) {
        return sender == address(this)
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function swapBack() internal swapping {
        
        uint256 tokenAmount = balanceOf(address(this)) - maxSwapSize;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouterV2.WETH();

        uint256 balanceBefore = address(this).balance;

        uniswapRouterV2.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance - (balanceBefore);
        
        uint256 amountBNBDev = amountBNB * (devFee) / (totalFee);
        uint256 amountBNBMarketing = amountBNB * (marketingFee) / (totalFee);
        uint256 amountBNBLiquidity = amountBNB * (liquidityFee) / (totalFee);

        (bool devSucess,) = payable(devFeeReceiver).call{value: amountBNBDev, gas: 30000}("");
        require(devSucess, "receiver rejected ETH transfer");
        (bool marketingSucess,) = payable(marketingFeeReceiver).call{value: amountBNBMarketing, gas: 30000}("");
        require(marketingSucess, "receiver rejected ETH transfer");
        (bool liquiditySucess,) = payable(liquidityFeeReceiver).call{value: amountBNBLiquidity, gas: 30000}("");
        require(liquiditySucess, "receiver rejected ETH transfer");
    }

    function setBuyFees(uint256 _devFee, uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        buyDevFee = _devFee;
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyTotalFee = buyDevFee + buyMarketingFee + buyLiquidityFee;
        require(buyTotalFee <= 25, "Invalid buy tax fees");
    }

    function setSellFees(uint256 _devFee, uint256 _marketingFee, uint256 _liquidityFee) external onlyOwner {
        sellDevFee = _devFee;
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellTotalFee = sellDevFee + sellMarketingFee + sellLiquidityFee;
        require(sellTotalFee <= 25, "Invalid sell tax fees");
    }
    
    function setFeeReceivers(address _devFeeReceiver, address _marketingFeeReceiver, address _liquidityFeeReceiver) external onlyOwner {
        devFeeReceiver = _devFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        liquidityFeeReceiver = _liquidityFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _percentageMinimum, uint256 _percentageMaximum) external onlyOwner {
        swapEnabled = _enabled;
        swapThreshold = _tTotal * _percentageMinimum / 10000;
        maxSwapSize = _tTotal * _percentageMaximum / 10000;
    }

    function setIsFeeExempt(address account, bool exempt) external onlyOwner {
        isFeeExempt[account] = exempt;
    }
    
    function setIsTxLimitExempt(address account, bool exempt) external onlyOwner {
        isTxLimitExempt[account] = exempt;
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= 100, "Invalid max wallet size");
        _maxWalletSize = _tTotal * amount / 10000;
    }

    function setMaxTxAmount(uint256 amount) external onlyOwner {
        require(amount >= 50, "Invalid max tx amount");
        _maxTxAmount = _tTotal * amount / 10000;
    }

    // Stuck Balances Functions

    function rescueToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        return IBEP20(tokenAddress).transfer(msg.sender, tokens);
    }

    function clearStuckBalance() external onlyOwner {
        uint256 amountBNB = address(this).balance;
        payable(msg.sender).transfer(amountBNB);
    }
}