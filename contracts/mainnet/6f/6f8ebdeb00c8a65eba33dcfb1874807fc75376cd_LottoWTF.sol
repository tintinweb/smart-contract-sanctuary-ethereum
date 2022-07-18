/**
 *Submitted for verification at Etherscan.io on 2022-07-18
*/

/*

Lotto.WTF - Every 12 hours the lottery tax is raffled off to one lucky winner / holder. 

*/

// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.7;

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

abstract contract Auth {
    address internal owner;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
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

interface InterfaceLP {
    function sync() external;
}

contract LottoWTF is ERC20, Auth {
    using SafeMath for uint256;

    address WETH;
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "Lotto.WTF";
    string constant _symbol = "Lotto";
    uint8 constant _decimals = 4; 

    uint256 _totalSupply = 1 * 10**6 * 10**_decimals;

    uint256 public _maxTxAmount = _totalSupply.mul(1).div(100); // 1%
    uint256 public _maxWalletToken = _totalSupply.mul(2).div(100); // 2%

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    bool public blacklistMode = true;
    mapping (address => bool) public isblacklisted;

    bool public launchMode = true;
    mapping (address => bool) public islaunched;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;

    uint256 public liquidityFee    = 2;
    uint256 public marketingFee    = 4;
    uint256 public devFee          = 1;
    uint256 public lottoFee        = 2; 
    uint256 public burnFee         = 0;
    uint256 public totalFee        = lottoFee + marketingFee + liquidityFee + devFee + burnFee;
    uint256 public feeDenominator  = 100;

    uint256 public sellMultiplier  = 100; 

    address public autoLiquidityReceiver;
    address public marketingFeeReceiver;
    address private devFeeReceiver;
    address private lottoFeeReceiver;
    address public burnFeeReceiver;

    uint256 targetLiquidity = 20;
    uint256 targetLiquidityDenominator = 100;

    IDEXRouter public router;
    InterfaceLP private pairContract;
    address public pair;
    
    bool public TradingOpen = false;    

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply * 2 / 1000; 
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        WETH = router.WETH();
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        pairContract = InterfaceLP(pair);
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[msg.sender] = true;
        isFeeExempt[devFeeReceiver] = true;
        isFeeExempt[marketingFeeReceiver] = true;
    
        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[devFeeReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[address(this)] = true;

        
        autoLiquidityReceiver = msg.sender;
        marketingFeeReceiver = 0x699AbF42A65F78eCa758F4c28D4eD50cdA821fa1;
        devFeeReceiver = 0x3faB7A710FfeF5427E366e16a1c6982e480c5d90;
        lottoFeeReceiver = 0xCfe6455Abb22fB799645594AbbF63d670Bea3cAb;
        burnFeeReceiver = DEAD; 

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
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

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

        function setMaxWalletPercent(uint256 maxWallPercent) external onlyOwner() {
        require(_maxWalletToken >= _totalSupply / 1000);
        _maxWalletToken = (_totalSupply * maxWallPercent ) / 100;
                
    }

    function SetMaxTxPercent(uint256 maxTXPercent) external onlyOwner() {
        require(_maxTxAmount >= _totalSupply / 1000); //anti honeypot no less than .1%
        _maxTxAmount = (_totalSupply * maxTXPercent ) / 1000;
    }

    
    function setTxLimitAbsolute(uint256 amount) external authorized {
        require(_maxTxAmount >= _totalSupply / 1000);
        _maxTxAmount = amount;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(TradingOpen,"Trading not open yet");

        }
           
            // blacklist
        if(blacklistMode){
            require(!isblacklisted[sender],"blacklisted");    
        }

        if (!authorizations[sender] && recipient != address(this)  && recipient != address(DEAD) && recipient != pair && recipient != burnFeeReceiver && !isTxLimitExempt[recipient]){
            uint256 heldTokens = balanceOf(recipient);
            require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");}

        // Checks max transaction limit
        checkTxLimit(sender, amount); 

        if(shouldSwapBack()){ swapBack(); }
                    
         //Exchange tokens
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = (!shouldTakeFee(sender) || !shouldTakeFee(recipient)) ? amount : takeFee(sender, amount,(recipient == pair),recipient);
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

    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender], "TX Limit Exceeded");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function takeFee(address sender, uint256 amount, bool isSell, address receiver) internal returns (uint256) {
        
        uint256 multiplier = isSell ? sellMultiplier : 100;
        if(launchMode && !islaunched[receiver] && !isSell){
            multiplier = 900;
        }

        uint256 feeAmount = amount.mul(totalFee).mul(multiplier).div(feeDenominator * 100);
        uint256 burnTokens = feeAmount.mul(burnFee).div(totalFee);
        uint256 contractTokens = feeAmount.sub(burnTokens);

        _balances[address(this)] = _balances[address(this)].add(contractTokens);
        _balances[burnFeeReceiver] = _balances[burnFeeReceiver].add(burnTokens);
        emit Transfer(sender, address(this), contractTokens);
        
        if(burnTokens > 0){
            emit Transfer(sender, burnFeeReceiver, burnTokens);    
        }

        return amount.sub(feeAmount);
    }

    function shouldSwapBack() internal view returns (bool) {
        return msg.sender != pair
        && !inSwap
        && swapEnabled
        && _balances[address(this)] >= swapThreshold;
    }

    function ClearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(msg.sender).transfer(amountETH * amountPercentage / 100);
    }

    function ClearStuckToken(address tokenAddress, uint256 tokens) public onlyOwner returns (bool) {
     if(tokens == 0){
            tokens = ERC20(tokenAddress).balanceOf(address(this));
        }
        return ERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function set_sell_multiplier(uint256 _multiplier) external authorized{
        require(totalFee.mul(sellMultiplier).div(100) < 50, "Sell Tax cannot be more than 50%"); //antihoneypot
        sellMultiplier = _multiplier;        
    }

    // switch Trading
    function EnableTrading() public onlyOwner {
        TradingOpen = true;
    }

    
    function swapBack() internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = swapThreshold.mul(dynamicLiquidityFee).div(totalFee).div(2);
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

        uint256 totalETHFee = totalFee.sub(dynamicLiquidityFee.div(2));
        
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHlotto = amountETH.mul(lottoFee).div(totalETHFee);
        uint256 amountETHdev = amountETH.mul(devFee).div(totalETHFee);

        (bool tmpSuccess,) = payable(marketingFeeReceiver).call{value: amountETHMarketing}("");
        (tmpSuccess,) = payable(devFeeReceiver).call{value: amountETHdev}("");
        (tmpSuccess,) = payable(lottoFeeReceiver).call{value: amountETHlotto}("");
        
        tmpSuccess = false;

        if(amountToLiquify > 0){
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
    }

    function enable_blacklist(bool _status) public onlyOwner {
        blacklistMode = _status;
    }

    function enable_launch(bool _status) public onlyOwner {
        launchMode = _status;

    }

    function manage_blacklist(address[] calldata addresses, bool status) public authorized {
        for (uint256 i; i < addresses.length; ++i) {
            isblacklisted[addresses[i]] = status;
        }
    }

    function manage_launch(address[] calldata addresses, bool status) public onlyOwner {
        for (uint256 i; i < addresses.length; ++i) {
            islaunched[addresses[i]] = status;
        }
    }

    function setIsFeeExempt(address holder, bool exempt) external authorized {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setFees(uint256 _liquidityFee, uint256 _lottoFee, uint256 _marketingFee, uint256 _devFee, uint256 _burnFee, uint256 _feeDenominator) external authorized {
        liquidityFee = _liquidityFee;
        lottoFee = _lottoFee;
        marketingFee = _marketingFee;
        devFee = _devFee;
        burnFee = _burnFee;
        totalFee = _liquidityFee.add(_lottoFee).add(_marketingFee).add(_devFee).add(_burnFee);
        feeDenominator = _feeDenominator;
        require(totalFee < feeDenominator/2, "Fees cannot be more than 50%"); //antihoneypot
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _devFeeReceiver, address _burnFeeReceiver, address _lottoFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        devFeeReceiver = _devFeeReceiver;
        burnFeeReceiver = _burnFeeReceiver;
        lottoFeeReceiver = _lottoFeeReceiver;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }

    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
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


    function BurnLPTokens(uint256 percent_base10000) public onlyOwner returns (bool){
        require(percent_base10000 <= 1000, "May not nuke more than 10% of tokens in LP");
    
        uint256 lp_tokens = this.balanceOf(pair);
        uint256 lp_burn = lp_tokens.mul(percent_base10000).div(10000);
        
        if (lp_burn > 0){
            _basicTransfer(pair,DEAD,lp_burn);
            pairContract.sync();
            return true;
        }
        
        return false;
 }


event AutoLiquify(uint256 amountETH, uint256 amountTokens);

}