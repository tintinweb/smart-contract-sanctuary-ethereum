/**
 *Submitted for verification at Etherscan.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/** HEAVEN IMPACT ETH
Official TG: https://t.me/HeavenImpactERC
Official Twitter: https://twitter.com/HeavenImpactBSC
Official Website: https://www.heavenimpact.com/
*/

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

abstract contract Auth {
    address internal owner;

    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!Owner"); _;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
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

contract HeavenImpactETH is IBEP20, Auth {

    address private WETH;

    string private constant _name = "Heaven Impact ETH";
    string private constant _symbol = "HIM";
    uint8 private constant _decimals = 9;
    
    uint256 _totalSupply = 10 * 10**6 * (10 ** _decimals);
    uint256 maxTx = 1 * 10**5 * (10 ** _decimals);
    uint256 maxWallet = 3 * 10**5 * (10 ** _decimals);

    uint256 public swapThreshold = 1 * 10**4 * (10 ** _decimals); // Starting at 10k

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private bots;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isTxLimitExempt;
    mapping (address => bool) public isWltExempt;
    mapping (address => bool) public isXferTaxExempt;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint[3] taxesCollected = [0, 0, 0];

    uint256 public launchedAt;
    address private liquidityPool = DEAD;

    uint256 private buyMkt = 3;
    uint256 private sellMkt = 2;
    uint256 private ecoFee = 1;
    uint256 private lpFee = 1;
    uint256 private ecoXfer = 10;
    uint256 private mktXfer = 10;
    uint256 private preLaunch = 0;

    uint256 _baseBuyFee = buyMkt + ecoFee;
    uint256 _baseSellFee = sellMkt + ecoFee + lpFee;

    uint256 private _moderateBuyImpact = 1;
    uint256 private _severeBuyImpact = 3;
    uint256 private _extremeBuyImpact = 5;

    uint256 private _moderateBuyDisc = 1;
    uint256 private _severeBuyDisc = 2;
    uint256 private _extremeBuyDisc = 3;

    uint256 private _moderateSellImpact = 1;
    uint256 private _severeSellImpact = 3;
    uint256 private _extremeSellImpact = 5;

    uint256 private _moderateSellFee = 1;
    uint256 private _severeSellFee = 2;
    uint256 private _extremeSellFee = 3;

    uint256 private _maxBuyAmount = 300000 * (10 ** _decimals);  // 3%
    uint256 private _maxSellAmount = 100000 * (10 ** _decimals); // 1%

    IDEXRouter public router;
    address public pair;
    address public factory;
    address public marketingWallet = payable(0x74E6B16189Ffd088ffFb3Fb63a13Cf13457E303C);
    address public ecosystemWallet = payable(0x7f3b67Ea68eEdA4a3c05eAe17F04095b7dc7FA33);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor (address _owner) Auth(_owner) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[_owner] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[ecosystemWallet] = true;

        isTxLimitExempt[_owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;
        isTxLimitExempt[marketingWallet] = true;
        isTxLimitExempt[ecosystemWallet] = true;  

	    isWltExempt[_owner] = true;
    	isWltExempt[DEAD] = true;
    	isWltExempt[ZERO] = true;
    	isWltExempt[marketingWallet] = true;
        isWltExempt[ecosystemWallet] = true; 

	    isXferTaxExempt[_owner] = true;
    	isXferTaxExempt[DEAD] = true;
    	isXferTaxExempt[ZERO] = true;
    	isXferTaxExempt[marketingWallet] = true;
        isXferTaxExempt[ecosystemWallet] = true; 

        _balances[_owner] = _totalSupply;
    
        emit Transfer(address(0), _owner, _totalSupply);
    }

    receive() external payable { }

    function setBots(address[] memory bots_) external onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function preLaunchSequence() external onlyOwner {
    	require(preLaunch == 0, "Already launched");
    	tradingOpen = true;
    	preLaunch = 1;
    }

    function endPrelaunch() external onlyOwner {
    	require(preLaunch == 1);
    	tradingOpen = false;
    	preLaunch = 2;
    }

    function fullLaunch() external onlyOwner {
    	require(preLaunch == 2);
        launchedAt = block.number;
        tradingOpen = true;
    	preLaunch = 3;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }
    
    function changeIsWltExempt(address holder, bool exempt) external onlyOwner {
        isWltExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(address holder, bool exempt) external onlyOwner {      
        isTxLimitExempt[holder] = exempt;
    }

    function changeIsXferTaxExempt(address holder, bool exempt) external onlyOwner {
	isXferTaxExempt[holder] = exempt;
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        maxTx = newLimit;
    }

    function changeWalletLimit(uint256 newLimit) external onlyOwner {
        maxWallet  = newLimit;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setLiquidityPool(address newLiquidityPool) external onlyOwner {
        liquidityPool = newLiquidityPool;
    }

    function setEcosystemWallet(address payable newEcosystemWallet) external onlyOwner {
        ecosystemWallet = newEcosystemWallet;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function delBot(address notbot) external onlyOwner {
        bots[notbot] = false;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function maxTransaction() external view returns (uint256) {return maxTx; }
    function maxWalletAmt() external view returns (uint256) {return maxWallet; }
    function baseBuyFee() external view returns (uint256) {return _baseBuyFee; }
    function baseSellFee() external view returns (uint256) {return _baseSellFee; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function addTaxCollected(uint eco, uint mkt, uint lp) internal {
        taxesCollected[0] += eco;
        taxesCollected[1] += mkt;
        taxesCollected[2] += lp;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "BEP20: transfer to/from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!bots[sender] && !bots[recipient], "Bots are not allowed to trade");
        require(amount <= maxTx || isTxLimitExempt[sender], "Exceeds Tx Limit");

        if (sender != owner && recipient != owner) require(tradingOpen, "Trading not active");

        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }

        if(!isWltExempt[recipient] && recipient != pair) require(_balances[recipient] + amount <= maxWallet, "Exceeds Wallet limit");

    	if(sender != pair && recipient != pair && isXferTaxExempt[sender]) { return _basicTransfer(sender, recipient, amount); }

        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }

        _balances[sender] = _balances[sender] - amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient] + finalAmount;

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }    

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 ecoTax = amount * ecoFee / 100;
        uint256 mktTax;
        uint256 lpTax = amount * lpFee / 100;
        uint256 taxToGet;

	if(sender == pair && recipient != address(pair) && !isFeeExempt[recipient]) {

        if (_maxBuyAmount > 0) {
            require(amount <= _maxBuyAmount, "Amount exceeds max buy");
            }

        if (amount >= balanceOf(pair) * _extremeBuyImpact / 100) {
            taxToGet = amount * (ecoFee + buyMkt - _extremeBuyDisc) / 100;
		    mktTax = taxToGet - ecoTax;
        } else if (amount >= balanceOf(pair) * _severeBuyImpact / 100) {
            taxToGet = amount * (ecoFee + buyMkt - _severeBuyDisc) / 100;
            mktTax = taxToGet - ecoTax;
        } else if (amount >= balanceOf(pair) * _moderateBuyImpact / 100) {
            taxToGet = amount * (ecoFee + buyMkt - _moderateBuyDisc) / 100;
		    mktTax = taxToGet - ecoTax;
        } else {
            taxToGet = amount * (ecoFee + buyMkt) / 100;
		    mktTax = taxToGet - ecoTax;
        }
            addTaxCollected(ecoTax, mktTax, 0);

	}

	if(!inSwapAndLiquify && sender != pair && tradingOpen) {

        if (_maxSellAmount > 0) {
            require(amount <= _maxSellAmount, "Amount exceeds max sell");
            }

            if (amount >= balanceOf(pair) * _extremeSellImpact / 100) {
            	taxToGet = amount * (ecoFee + lpFee + sellMkt + _extremeSellFee) / 100;
            	mktTax = taxToGet - ecoTax - lpTax;
            } else if (amount >= balanceOf(pair) * _severeSellImpact / 100) {
            	taxToGet = amount * (ecoFee + lpFee + sellMkt + _severeSellFee) / 100;
            	mktTax = taxToGet - ecoTax - lpTax;
            } else if (amount >= balanceOf(pair) * _moderateSellImpact / 100) {
            	taxToGet = amount * (ecoFee + lpFee + sellMkt + _moderateSellFee) / 100;
            	mktTax = taxToGet - ecoTax - lpTax;
            } else {
            	taxToGet = amount * (ecoFee + lpFee + sellMkt) / 100;
            	mktTax = taxToGet - ecoTax - lpTax;
            }
        	addTaxCollected(ecoTax, mktTax, lpTax);
		}

	if(sender != pair && recipient != pair && !isXferTaxExempt[sender]) {
		ecoTax = amount * ecoXfer / 100;
		mktTax = amount * mktXfer / 100;
		taxToGet = ecoTax + mktTax;
		addTaxCollected(ecoTax, mktTax, 0);
		}

        _balances[address(this)] = _balances[address(this)] + taxToGet;
        emit Transfer(sender, address(this), taxToGet);

        return amount - taxToGet;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }  

    function updateBaseFees(uint256 newEcoFee, uint256 newBuyMktFee, uint256 newSellMktFee, uint256 newLpFee) public onlyOwner {
	    require(newEcoFee <= 5 && newBuyMktFee <= 5 && newSellMktFee <= 5 && newLpFee <= 5, "Fees Too High");
	    ecoFee = newEcoFee;
	    buyMkt = newBuyMktFee;
	    sellMkt = newSellMktFee;
	    lpFee = newLpFee;
    }

    function updateBuyDynamics(uint256 moderateBuyImpact, uint256 severeBuyImpact, uint256 extremeBuyImpact) public onlyOwner {
        _moderateBuyImpact = moderateBuyImpact;
        _severeBuyImpact = severeBuyImpact;
        _extremeBuyImpact = extremeBuyImpact;
    }

    function updateDynamicBuyDiscounts(uint256 moderateBuyDisc, uint256 severeBuyDisc, uint256 extremeBuyDisc) public onlyOwner {
        _moderateBuyDisc = moderateBuyDisc;
        _severeBuyDisc = severeBuyDisc;
        _extremeBuyDisc = extremeBuyDisc;
    }

    function updateSellDynamics(uint256 moderateSellImpact, uint256 severeSellImpact, uint256 extremeSellImpact) public onlyOwner {
        _moderateSellImpact = moderateSellImpact;
        _severeSellImpact = severeSellImpact;
        _extremeSellImpact = extremeSellImpact;
    }

    function updateDynamicSellFees(uint256 moderateSellFee, uint256 severeSellFee, uint256 extremeSellFee) public onlyOwner {
	require(moderateSellFee <= 8 && severeSellFee <= 9 && extremeSellFee <= 10, "Fees must be less than 25");
        _moderateSellFee = moderateSellFee;
        _severeSellFee = severeSellFee;
        _extremeSellFee = extremeSellFee;
    }

    function updateXferFees(uint256 _newEcoXfer, uint256 _newMktXfer) public onlyOwner {
	require(_newEcoXfer <= 10 && _newMktXfer <= 10, "Fees must be less than 25");
	ecoXfer = _newEcoXfer;
	mktXfer = _newMktXfer;
    }

    function swapTokensForETH(uint256 tokenAmount) private {

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        approve(address(this), tokenAmount);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityPool,
            block.timestamp
        );
    }

    function swapBack() internal lockTheSwap {
    
        uint256 tokenBalance = _balances[address(this)];
        uint256 _totalCollected = taxesCollected[0] + taxesCollected[1] + taxesCollected[2];
        uint256 ecoShare = taxesCollected[0];
        uint256 mktShare = taxesCollected[1];
        uint256 lpShare = taxesCollected[2];
        uint256 tokensForLiquidity = lpShare / 2;  
        uint256 amountToSwap = tokenBalance - tokensForLiquidity;

        swapTokensForETH(amountToSwap);

        uint256 totalBNBBalance = address(this).balance;
        uint256 BNBForEco = totalBNBBalance * ecoShare / _totalCollected;
        uint256 BNBForMkt = totalBNBBalance * mktShare / _totalCollected;
        uint256 BNBForLiquidity = totalBNBBalance * lpShare / _totalCollected / 2;
      
        if (totalBNBBalance > 0){
            payable(marketingWallet).transfer(BNBForMkt);
        }

          if (totalBNBBalance > 0){
            payable(ecosystemWallet).transfer(BNBForEco);
        }
  
        if (tokensForLiquidity > 0){
            addLiquidity(tokensForLiquidity, BNBForLiquidity);
        }

	delete taxesCollected;
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckBNB() external onlyOwner {
        uint256 contractBNBBalance = address(this).balance;
    	uint256 contractTokenBalance = _balances[address(this)];
        if(contractBNBBalance > 0) {          
            payable(marketingWallet).transfer(contractBNBBalance);
        }
	if(contractTokenBalance > 0) {
	    payable(marketingWallet).transfer(contractTokenBalance);
        }
    }

    function renounceOwnership() public virtual onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));

    }
}