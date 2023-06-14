/**
 *Submitted for verification at Etherscan.io on 2023-06-14
*/

// SPDX-License-Identifier: MIT

//   _________      __      __ 
//  /   _____/____ /  \    /  \
//  \_____  \\__  \\   \/\/   /
//  /        \/ __ \\        / 
// /_______  (____  /\__/\  /  
//         \/     \/      \/.FINANCE 
// 
//  00110001 00110000 00110011 00101100 00111001 00110000 00110000 00101100 00110000 00110000 00110000 00100000 00101101 00100000 01000011 
//  01100001 01101110 00100000 01111001 01101111 01110101 00100000 01100110 01101001 01100111 01110101 01110010 01100101 00100000 01101111 
//  01110101 01110100 00100000 01110100 01101000 01100101 00100000 01100011 01101111 01100100 01100101 00111111 00001010 01010111 01101000 
//  01100001 01110100 00100111 01110011 00100000 01100010 01100101 01101000 01101001 01101110 01100100 00100000 01110100 01101000 01101001 
//  01110011 00100000 01101110 01110101 01101101 01100010 01100101 01110010 00100000 00111111 00100000 00001010 01001100 01100101 01110100 
//  00100000 01110100 01101000 01100101 00100000 01100111 01100001 01101101 01100101 00100000 01100010 01100101 01100111 01101001 01101110 00101110 00100000 
//
//
// www.saw.finance
// https://twitter.com/SawToken?t=d325GtdsIxpd4sG-1Ai-2w&s=09
// https://t.me/Saw_Token
// 
// The intention with SAW is to provide an environment not only beneficial to the holder but also to all communities.

pragma solidity 0.8.13;

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
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


contract SAW is IERC20, Ownable {

    address private WETH;

    string private constant _name = "SAW";
    string private constant _symbol = "SAW";
    uint8 private constant _decimals = 9;
    
    uint256 _totalSupply = 103900000 * (10 ** _decimals);
    uint256 maxWallet = _totalSupply / 50; // 2%
    uint256 maxTransaction = _totalSupply / 50; // 2%
    uint256 public swapThreshold = _totalSupply / 1000; // Starting at 0.1%

    uint256 public maxBuy = _totalSupply / 50; // 2%
    bool public maxBuyEnabled = true;

    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) public isFeeExempt;
    mapping (address => bool) public isWalletExempt;
    mapping (address => bool) public isTxExempt;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    uint[3] taxesCollected = [0, 0, 0];

    uint256 public launchedAt;
    address public liquidityPool = DEAD;

    // All fees are in basis points (100 = 1%)
    uint256 private buyMkt = 200;
    uint256 private sellMkt = 200;
    uint256 private buyLP = 200;
    uint256 private sellLP = 200;
    uint256 private buyDev = 100;
    uint256 private sellDev = 100;

    uint256 _baseBuyFee = buyMkt + buyLP + buyDev;
    uint256 _baseSellFee = sellMkt + sellLP + sellDev;

    IDEXRouter public router;
    address public pair;
    address public factory;
    address public marketingWallet = payable(0x7aB22Cb0299Eab1e488db575D1C8E9b49AE05c87);
    address public devWallet = payable(0x7aB22Cb0299Eab1e488db575D1C8E9b49AE05c87);

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingOpen = false;

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            
        WETH = router.WETH();
        
        pair = IDEXFactory(router.factory()).createPair(WETH, address(this));
        
        _allowances[address(this)][address(router)] = type(uint256).max;

        isFeeExempt[owner()] = true;
        isFeeExempt[marketingWallet] = true;
        isFeeExempt[address(this)] = true;
        isWalletExempt[owner()] = true;
        isWalletExempt[marketingWallet] = true;
        isWalletExempt[DEAD] = true;
        isTxExempt[owner()] = true;
        isTxExempt[marketingWallet] = true;
        isTxExempt[DEAD] = true;

        _balances[owner()] = _totalSupply;
    
        emit Transfer(address(0), owner(), _totalSupply);
    }

    receive() external payable { }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsWalletExempt(address holder, bool exempt) external onlyOwner {
        isWalletExempt[holder] = exempt;
    }

    function changeIsTxExempt(address holder, bool exempt) external onlyOwner {
        isTxExempt[holder] = exempt;
    }

    function launchSequence(uint hold) external onlyOwner {
	    require(launchedAt == 0, "Already launched");
        launchedAt = block.number + hold;
        tradingOpen = true;
    }

    function toggleTrade(bool _switch) external onlyOwner {
	    tradingOpen = _switch;
    }

    function toggleMaxBuy(bool _switch) external onlyOwner {
	    maxBuyEnabled = _switch;
    }

    function changeMaxBuyAmount(uint _amt) external onlyOwner {
	    require(_amt >= (_totalSupply / 200), "Must be at least 0.5%");
	    maxBuy = _amt;
    }

    function changeMaxWallet(uint _amt) external onlyOwner {
        require(_amt >= (_totalSupply / 50), "Must be at least 2%");
        maxWallet = _amt;
    }

    function changeMaxTransaction(uint _amt) external onlyOwner {
        require(_amt >= (_totalSupply / 100), "Must be at least 1%");
        maxTransaction = _amt;
    }

    function setMarketingWallet(address payable newMarketingWallet) external onlyOwner {
        marketingWallet = payable(newMarketingWallet);
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
	    devWallet = payable(newDevWallet);
    }

    function setLiquidityPool(address newLiquidityPool) external onlyOwner {
        liquidityPool = newLiquidityPool;
    }

    function changeSwapBackSettings(bool enableSwapBack, uint256 newSwapBackLimit) external onlyOwner {
        swapAndLiquifyEnabled  = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - balanceOf(DEAD) - balanceOf(ZERO);
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
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

    function addTaxCollected(uint mkt, uint lp, uint dev) internal {
        taxesCollected[0] += mkt;
        taxesCollected[1] += lp;
	    taxesCollected[2] += dev;
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
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount < maxTransaction || isTxExempt[sender], "Exceeds Transaction Limit");

        if(recipient != pair) {
            uint256 recipientBalance = _balances[recipient];
            require(recipientBalance + amount < maxWallet || isWalletExempt[recipient]);
        }

	    if(sender == pair && maxBuyEnabled) { require(amount <= maxBuy || isTxExempt[recipient], "Exceeds Max Buy"); }
        if(sender != owner() && recipient != owner()) { require(tradingOpen || isFeeExempt[sender], "Trading not active"); }
        if(inSwapAndLiquify){ return _basicTransfer(sender, recipient, amount); }
    	if(sender != pair && recipient != pair) { return _basicTransfer(sender, recipient, amount); }
        if(msg.sender != pair && !inSwapAndLiquify && swapAndLiquifyEnabled && _balances[address(this)] >= swapThreshold){ swapBack(); }
    	if(sender == pair && block.number < launchedAt) { recipient = DEAD; }

        _balances[sender] = _balances[sender] - amount;
        
        uint256 finalAmount = !isFeeExempt[sender] && !isFeeExempt[recipient] ? takeFee(sender, recipient, amount) : amount;

        _balances[recipient] = _balances[recipient] + finalAmount;

        emit Transfer(sender, recipient, finalAmount);
        return true;
    }  

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        
        uint256 mktTaxB = amount * buyMkt / 10000;
	    uint256 mktTaxS = amount * sellMkt / 10000;
        uint256 lpTaxB = amount * buyLP / 10000;
	    uint256 lpTaxS = amount * sellLP / 10000;
	    uint256 devB = amount * buyDev / 10000;
	    uint256 devS = amount * sellDev / 10000;
        uint256 taxToGet;

	    if(sender == pair && recipient != address(pair) && !isFeeExempt[recipient]) {
            taxToGet = mktTaxB + lpTaxB + devB;
	        addTaxCollected(mktTaxB, lpTaxB, devB);
	    }

	    if(!inSwapAndLiquify && sender != pair && tradingOpen) {
	        taxToGet = mktTaxS + lpTaxS + devS;
	        addTaxCollected(mktTaxS, lpTaxS, devS);
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

    function updateBuyFees(uint256 newBuyMktFee, uint256 newBuyLpFee, uint256 newBuyDev) public onlyOwner {
	    require(newBuyMktFee + newBuyLpFee + newBuyDev <= 1000, "Fees Too High");
	    buyMkt = newBuyMktFee;
	    buyLP = newBuyLpFee;
        buyDev = newBuyDev;
    }
    
    function updateSellFees(uint256 newSellMktFee,uint256 newSellLpFee, uint256 newSellDev) public onlyOwner {
	    require(newSellMktFee + newSellLpFee + newSellDev <= 1000, "Fees Too High");
	    sellMkt = newSellMktFee;
	    sellLP = newSellLpFee;
	    sellDev = newSellDev;
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
        uint256 mktShare = taxesCollected[0];
        uint256 lpShare = taxesCollected[1];
	    uint256 devShare = taxesCollected[2];
        uint256 tokensForLiquidity = lpShare / 2;  
        uint256 amountToSwap = tokenBalance - tokensForLiquidity;

        swapTokensForETH(amountToSwap);

        uint256 totalETHBalance = address(this).balance;
        uint256 ETHForMkt = totalETHBalance * mktShare / _totalCollected;
        uint256 ETHForLiquidity = totalETHBalance * lpShare / _totalCollected / 2;
	    uint256 ETHForDev = totalETHBalance * devShare/ _totalCollected;
      
        if (totalETHBalance > 0) {
            payable(marketingWallet).transfer(ETHForMkt);
        }
  
        if (tokensForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ETHForLiquidity);
        }
	
	    if (ETHForDev > 0) {
	        payable(devWallet).transfer(ETHForDev);
        }

	    delete taxesCollected;
    }

    function manualSwapBack() external onlyOwner {
        swapBack();
    }

    function clearStuckETH() external onlyOwner {
        uint256 contractETHBalance = address(this).balance;
        if(contractETHBalance > 0) { 
            payable(marketingWallet).transfer(contractETHBalance);
    	}
    }

    function clearStuckTokens(address contractAddress) external onlyOwner {
        IERC20 erc20Token = IERC20(contractAddress);
        uint256 balance = erc20Token.balanceOf(address(this));
        erc20Token.transfer(marketingWallet, balance);
    }

    function massDistributeTokens(address[] calldata _airdropAddresses, uint amtPerAddress) external onlyOwner {
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
	        IERC20(address(this)).transfer(_airdropAddresses[i], amtPerAddress);
        }
    }

    function distributeTokensByAmount(address[] calldata _airdropAddresses, uint[] calldata _airdropAmounts) external onlyOwner {
	    for (uint i = 0; i < _airdropAddresses.length; i++) {
	        IERC20(address(this)).transfer(_airdropAddresses[i], _airdropAmounts[i]);
        }
    }
}