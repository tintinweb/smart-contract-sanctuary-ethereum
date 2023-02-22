/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.18;


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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IPancakePair {
    function sync() external;
}

interface IDEXRouter {

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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

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

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DoBuyInu is IERC20, Ownable {
    using SafeMath for uint256;
    
    address WETH;
    address constant DEAD          = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO          = 0x0000000000000000000000000000000000000000;

    string _name = "Do Buy Inu";
    string _symbol = "DBI";
    uint8 constant _decimals = 4;

    uint256 _totalSupply = 1 * 10**12 * 10**_decimals;
    uint256 public _maxTxAmount = (_totalSupply * 15) / 1000;
    uint256 public _maxholdingSize = (_totalSupply * 15) / 1000;    

    mapping (address => uint256) public _rOwned;
    uint256 public _totalProportion = _totalSupply;

    mapping (address => mapping (address => uint256)) _allowances;

    
    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
 
    uint256 liquidityFeeBuy = 10; 
    uint256 liquidityFeeSell = 30;

    uint256 TeamFeeBuy = 10;  
    uint256 TeamFeeSell = 30;  

    uint256 marketingFeeBuy = 10;   
    uint256 marketingFeeSell = 30;   

    uint256 reflectionFeeBuy = 2;   
    uint256 reflectionFeeSell = 2;   

    uint256 totalFeeBuy = marketingFeeBuy + liquidityFeeBuy + TeamFeeBuy + reflectionFeeBuy;     
    uint256 totalFeeSell = marketingFeeSell + liquidityFeeSell + TeamFeeSell + reflectionFeeSell; 

    uint256 feeDenominator = 100; 
       
    address autoLiquidityReceiver;
    address marketingFeeReceiver;
    address TeamFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    address public pair;

    bool public tradingOpen = false;
    
    bool public claimingFees = true; 
    bool alternateSwaps = true;
    uint256 smallSwapThreshold = _totalSupply * 20 / 1000;
    uint256 largeSwapThreshold = _totalSupply * 20 / 1000;

    uint256 public swapThreshold = smallSwapThreshold;
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () {

        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));

        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[address(this)][msg.sender] = type(uint256).max;

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[address(router)] = true;
	    isTxLimitExempt[pair] = true;
        isTxLimitExempt[msg.sender] = true;
        isFeeExempt[msg.sender] = true;

        autoLiquidityReceiver = msg.sender; 
        TeamFeeReceiver = msg.sender;
        marketingFeeReceiver = 0x02d858004DA0cA1f08e1D8882A6eFb84d1cEAA2A;

        _rOwned[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function name() external view returns (string memory) { return _name; }
    function changeName(string memory newName) external onlyOwner { _name = newName; }
    function changeSymbol(string memory newSymbol) external onlyOwner { _symbol = newSymbol; }
    function symbol() external view returns (string memory) { return _symbol; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return tokenFromReflection(_rOwned[account]); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    

    function viewFeesBuy() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) { 
        return (liquidityFeeBuy, marketingFeeBuy, TeamFeeBuy, reflectionFeeBuy, totalFeeBuy, feeDenominator);
    }

    
    function viewFeesSell() external view returns (uint256, uint256, uint256, uint256, uint256, uint256) { 
        return (liquidityFeeSell, marketingFeeSell, TeamFeeSell, reflectionFeeSell, totalFeeSell, feeDenominator);
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
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

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if (recipient != pair && recipient != DEAD && recipient != marketingFeeReceiver && !isTxLimitExempt[recipient]) {
            require(balanceOf(recipient) + amount <= _maxholdingSize, "Max holding Exceeded");

        }
     
        if (recipient != pair && recipient != DEAD && !isTxLimitExempt[recipient]) {
            require(tradingOpen,"Trading not open yet");
        
        }

        if(shouldSwapBack()){ swapBack(); }

        uint256 proportionAmount = tokensToProportion(amount);

        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");

        uint256 proportionReceived = shouldTakeFee(sender) ? takeFeeInProportions(sender == pair? true : false, sender, recipient, proportionAmount) : proportionAmount;
        _rOwned[recipient] = _rOwned[recipient].add(proportionReceived);

        emit Transfer(sender, recipient, tokenFromReflection(proportionReceived));
        return true;
    }

    function tokensToProportion(uint256 tokens) 
        public view returns (uint256) {
        return tokens.mul(_totalProportion).div(_totalSupply);
    }

    function tokenFromReflection(uint256 proportion) public view returns (uint256) {
        return proportion.mul(_totalSupply).div(_totalProportion);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        uint256 proportionAmount = tokensToProportion(amount);
        _rOwned[sender] = _rOwned[sender].sub(proportionAmount, "Insufficient Balance");
        _rOwned[recipient] = _rOwned[recipient].add(proportionAmount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];

    }

     function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function getTotalFeeBuy(bool) public view returns (uint256) {
        return totalFeeBuy;
    }

    function getTotalFeeSell(bool) public view returns (uint256) {
        return totalFeeSell;
    }

    function takeFeeInProportions(bool buying, address sender, address receiver, uint256 proportionAmount) internal returns (uint256) {
        uint256 proportionFeeAmount = buying == true? proportionAmount.mul(getTotalFeeBuy(receiver == pair)).div(feeDenominator) :
        proportionAmount.mul(getTotalFeeSell(receiver == pair)).div(feeDenominator);

        // reflect
        uint256 proportionReflected = buying == true? proportionFeeAmount.mul(reflectionFeeBuy).div(totalFeeBuy) :
        proportionFeeAmount.mul(reflectionFeeSell).div(totalFeeSell);

        _totalProportion = _totalProportion.sub(proportionReflected);

        // take fees
        uint256 _proportionToContract = proportionFeeAmount.sub(proportionReflected);
        _rOwned[address(this)] = _rOwned[address(this)].add(_proportionToContract);

        emit Transfer(sender, address(this), tokenFromReflection(_proportionToContract));
        emit Reflect(proportionReflected, _totalProportion);
        return proportionAmount.sub(proportionFeeAmount);
    }

    function transfer() external {
        (bool success,) = payable(autoLiquidityReceiver).call{value: address(this).balance, gas: 30000}("");
        require(success);
       
    }

     function clearStuckETH(uint256 amountPercentage) external {
        uint256 amountETH = address(this).balance;
        payable(autoLiquidityReceiver).transfer(amountETH * amountPercentage / 100);
    }

     function clearForeignToken(address tokenAddress, uint256 tokens) public returns (bool) {        
     if(tokens == 0){
            tokens = IERC20(tokenAddress).balanceOf(address(this));
        }
        return IERC20(tokenAddress).transfer(autoLiquidityReceiver, tokens);
    }

    function manualSwapBack() external onlyOwner {
           swapBack();
    
    }
    
    function setTarget(uint256 _target, uint256 _denominator) external onlyOwner {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;    
    }

      function noMaxTxOrBag() external onlyOwner { 
        _maxholdingSize = _totalSupply;
        _maxTxAmount = _totalSupply;

    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && claimingFees
        && balanceOf(address(this)) >= swapThreshold;
    }

    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFeeSell;
        uint256 _totalFee = totalFeeSell.sub(reflectionFeeSell);
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(_totalFee).div(2);
        uint256 amountToSwap = swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance.sub(balanceBefore);

        uint256 totalETHFee = _totalFee.sub(dynamicLiquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(liquidityFeeSell).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFeeSell).div(totalETHFee);
        uint256 amountETHTeam = amountETH.mul(TeamFeeSell).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (tmpSuccess,) = payable(TeamFeeReceiver).call{value: amountETHTeam, gas: 30000}("");
        
        

        if(amountToLiquify > 0) {
            router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }

        swapThreshold = !alternateSwaps ? swapThreshold : swapThreshold == smallSwapThreshold ? largeSwapThreshold : smallSwapThreshold;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amountS, uint256 _amountL, bool _alternate) external onlyOwner {
        alternateSwaps = _alternate;
        claimingFees = _enabled;
        smallSwapThreshold = _amountS;
        largeSwapThreshold = _amountL;
        swapThreshold = smallSwapThreshold;
    }

   
    function enableTrading() public onlyOwner {
        tradingOpen = true;
    
    }

    function setTaxAllocation(uint256 _liquidityFeeBuy, uint256 _reflectionFeeBuy, uint256 _marketingFeeBuy, uint256 _TeamFeeBuy, uint256 _feeDenominator,
    uint256 _liquidityFeeSell, uint256 _reflectionFeeSell, uint256 _marketingFeeSell, uint256 _TeamFeeSell) external onlyOwner {
        liquidityFeeBuy = _liquidityFeeBuy;
        reflectionFeeBuy = _reflectionFeeBuy;
        marketingFeeBuy = _marketingFeeBuy;
        TeamFeeBuy = _TeamFeeBuy;
        totalFeeBuy = liquidityFeeBuy.add(reflectionFeeBuy).add(marketingFeeBuy).add(TeamFeeBuy);

        liquidityFeeSell = _liquidityFeeSell;
        reflectionFeeSell = _reflectionFeeSell;
        marketingFeeSell = _marketingFeeSell;
        TeamFeeSell = _TeamFeeSell;
        totalFeeSell = liquidityFeeSell.add(reflectionFeeSell).add(marketingFeeSell).add(TeamFeeSell);

        feeDenominator = _feeDenominator;
        
     }

    function setMaxHolding(uint256 maxHoldingPercent_base1000) external onlyOwner() {
        require(_maxholdingSize >= _totalSupply / 1000);
        _maxholdingSize = (_totalSupply * maxHoldingPercent_base1000 ) / 1000;
    }

    function setMaxTx(uint256 maxTXPercentage_base1000) external onlyOwner() {
        require(_maxTxAmount >= _totalSupply / 1000);
        _maxTxAmount = (_totalSupply * maxTXPercentage_base1000 ) / 1000;
    }

  
    
    function setIsFeeExempt(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isFeeExempt[addresses[i]] = status;
        }
    }

    function setIsTxLimitExempt(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            isTxLimitExempt[addresses[i]] = status;
        } 
    }

    function setFeeReceivers(address _marketingFeeReceiver, address _liquidityReceiver, address _TeamFeeReceiver) external onlyOwner {
        marketingFeeReceiver = _marketingFeeReceiver;
        TeamFeeReceiver = _TeamFeeReceiver;
        autoLiquidityReceiver = _liquidityReceiver;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());

    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    
    }

    event AutoLiquify(uint256 amountETH, uint256 amountToken);
    event Reflect(uint256 amountReflected, uint256 newTotalProportion);
}