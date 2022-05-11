/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT                                                                               
                                                    
pragma solidity 0.8.13;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _createInitialSupply(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ILpPair {
    function sync() external;
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract FaithToken is ERC20, Ownable {

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    uint256 public lastBurnTimestamp;

    address public marketingAddress;
    address public developmentAddress;
    address public futureOwnerAddress;
    address public constant DEAD = address(0xdead);

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    address[] public earlyBuyers;
    uint256 public botsCaught;

    mapping (address => uint256) public firstTokenReceiptTimestamp;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    bool private gasLimitActive = true;
    uint256 private gasPriceMax = 350 * 1 gwei;

    uint256 public buyTotalFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevelopmentFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevelopmentFee;
    uint256 public sellBurnFee;

    uint256 public sellTotalFeesEarly;
    uint256 public sellMarketingFeeEarly;
    uint256 public sellLiquidityFeeEarly;
    uint256 public sellDevelopmentFeeEarly;
    uint256 public sellBurnFeeEarly;

    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDevelopment;
    uint256 public tokensForBurn;

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event RemovedLimits();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedMarketingAddress(address indexed newWallet);

    event UpdatedDevelopmentAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("Faith Token", "FAI") payable {
        
        address newOwner = msg.sender; // can leave alone if owner is deployer.

        // initialize router
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        uint256 totalSupply = 10 * 1e12 * 1e18;
        
        maxBuyAmount = totalSupply * 5 / 1000;
        maxSellAmount = totalSupply * 5 / 1000;
        maxWallet = totalSupply * 15 / 1000;
        swapTokensAtAmount = totalSupply * 5 / 10000;

        buyMarketingFee = 5;
        buyLiquidityFee = 2;
        buyDevelopmentFee = 3;
        buyBurnFee = 3;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevelopmentFee + buyBurnFee;

        sellMarketingFee = 5;
        sellLiquidityFee = 2;
        sellDevelopmentFee = 3;
        sellBurnFee = 3;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevelopmentFee + sellBurnFee;

        sellMarketingFeeEarly = 5;
        sellLiquidityFeeEarly = 7;
        sellDevelopmentFeeEarly = 4;
        sellBurnFeeEarly = 4;
        sellTotalFeesEarly = sellMarketingFeeEarly + sellLiquidityFeeEarly + sellDevelopmentFeeEarly + sellBurnFeeEarly;

        marketingAddress = address(0xf6Ec18a039e9e4C6728a2506A28ce89ED00de7dd);
        futureOwnerAddress = address(0x40e567762d1eDB90094AAb813D9C95013e74544e);
        developmentAddress = address(0x68551F8ABF7b0e872573f953fdd262305eC4CEB9);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(futureOwnerAddress, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(marketingAddress), true);
        _excludeFromMaxTransaction(0x33d4cC8716Beb13F814F538Ad3b2de3b036f5e2A, true); // PinkLock Address for Token Locking.

        excludeFromFees(newOwner, true);
        excludeFromFees(futureOwnerAddress, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(marketingAddress), true);

        _createInitialSupply(DEAD, totalSupply * 50 / 100);
        _createInitialSupply(address(this), totalSupply * 245 / 1000);
        _createInitialSupply(address(0x85bde96D098c338b4b3DCa8Cae84c4B3bb900B01), totalSupply * 5 / 1000);
        _createInitialSupply(futureOwnerAddress, totalSupply * 25 / 100);

        transferOwnership(newOwner);
    }

    receive() external payable {}

    function setGasPriceMax(uint256 gas) external onlyOwner {
        require(gas >= 200);
        gasPriceMax = gas * 1 gwei;
    }
    
    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        gasLimitActive = false;
        transferDelayEnabled = false;
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWallet = totalSupply();
        emit RemovedLimits();
    }

    function getEarlyBuyers() external view returns (address[] memory){
        return earlyBuyers;
    }

    function removeBoughtEarly(address wallet) external onlyOwner {
        boughtEarly[wallet] = false;
    }

    function emergencyUpdateRouter(address router) external onlyOwner {
        require(!tradingActive, "Cannot update after trading is functional");
        dexRouter = IDexRouter(router);
    }
    
    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set max buy amount lower than 0.5%");
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 5 / 1000)/1e18, "Cannot set max sell amount lower than 0.5%");
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() /100)/1e18, "Cannot set max wallet amount lower than 1%");
        maxWallet = newNum * (10**18);
        emit UpdatedMaxWalletAmount(maxWallet);
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}
    
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
        emit MaxTransactionExclusion(updAds, isExcluded);
    }

    function airdropToWallets(address[] calldata wallets, uint256[] calldata amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 300, "Can only airdrop 300 wallets per txn due to gas limits");
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            if(firstTokenReceiptTimestamp[wallet] == 0){
                firstTokenReceiptTimestamp[wallet] = block.timestamp;
            }
            super._transfer(msg.sender, wallet, amount);
        }
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        _excludeFromMaxTransaction(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _developmentFee, uint256 _burnFee) external onlyOwner {
        buyMarketingFee = _marketingFee;
        buyLiquidityFee = _liquidityFee;
        buyDevelopmentFee = _developmentFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyMarketingFee + buyLiquidityFee + buyDevelopmentFee;
        require(buyTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateSellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _developmentFee, uint256 _burnFee) external onlyOwner {
        sellMarketingFee = _marketingFee;
        sellLiquidityFee = _liquidityFee;
        sellDevelopmentFee = _developmentFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellMarketingFee + sellLiquidityFee + sellDevelopmentFee + sellBurnFee;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function updateEarlySellFees(uint256 _marketingFee, uint256 _liquidityFee, uint256 _developmentFee, uint256 _burnFee) external onlyOwner {
        sellMarketingFeeEarly = _marketingFee;
        sellLiquidityFeeEarly = _liquidityFee;
        sellDevelopmentFeeEarly = _developmentFee;
        sellBurnFeeEarly = _burnFee;
        sellTotalFeesEarly = sellMarketingFeeEarly + sellLiquidityFeeEarly + sellDevelopmentFeeEarly + sellBurnFeeEarly;
        require(sellTotalFees <= 20, "Must keep fees at 20% or less");
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if(firstTokenReceiptTimestamp[to] == 0){
            firstTokenReceiptTimestamp[to] = block.timestamp;
        }

        // protects in future staking scenarios if another contract tries to transfer 0 tokens.
        if(amount == 0){
            super._transfer(from, to, 0);
            return;
        }
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(!earlyBuyPenaltyInEffect() && tradingActive){
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }
        
        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){

                // only use to prevent sniper buys in the first blocks.
                if (gasLimitActive && automatedMarketMakerPairs[from]) {
                    require(tx.gasprice <= gasPriceMax, "Gas price exceeds limit.");
                }

                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferBlock[tx.origin] < block.number && _holderLastTransferBlock[to] < block.number, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferBlock[tx.origin] = block.number;
                        _holderLastTransferBlock[to] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                    require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                    require(amount + balanceOf(to) <= maxWallet, "Max Wallet exceeded");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Max Wallet exceeded");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && automatedMarketMakerPairs[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if((earlyBuyPenaltyInEffect() || (amount >= maxBuyAmount - .9 ether && blockForPenaltyEnd + 4 >= block.number)) && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && !_isExcludedFromFees[to] && buyTotalFees > 0){
                
                if(!earlyBuyPenaltyInEffect()){
                    maxBuyAmount -= 1;
                }

                if(!boughtEarly[to]){
                    boughtEarly[to] = true;
                    botsCaught += 1;
                    earlyBuyers.push(to);
                    emit CaughtEarlyBuyer(to);
                }

                fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                tokensForDevelopment += fees * buyDevelopmentFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }
            // on sell (within 24 hours)
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                // early sell
                if(firstTokenReceiptTimestamp[from] + 24 hours >= block.timestamp){
                    fees = amount * sellTotalFeesEarly / 100;
                    tokensForLiquidity += fees * sellLiquidityFeeEarly / sellTotalFeesEarly;
                    tokensForMarketing += fees * sellMarketingFeeEarly / sellTotalFeesEarly;
                    tokensForDevelopment += fees * sellDevelopmentFeeEarly / sellTotalFeesEarly;
                    tokensForBurn += fees * sellBurnFeeEarly / sellTotalFeesEarly;
                } else {
                    fees = amount * sellTotalFees / 100;
                    tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                    tokensForMarketing += fees * sellMarketingFee / sellTotalFees;
                    tokensForDevelopment += fees * sellDevelopmentFee / sellTotalFees;
                    tokensForBurn += fees * sellBurnFee / sellTotalFees;
                }
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForMarketing += fees * buyMarketingFee / buyTotalFees;
                tokensForDevelopment += fees * buyDevelopmentFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    function swapTokensForEth(uint256 tokenAmount) private {

        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        _approve(address(this), address(dexRouter), tokenAmount);

        // make the swap
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function getCurrentBlock() external view returns (uint256) {
        return block.number;
    }

    function getCurrentTimestamp() external view returns (uint256) {
        return block.timestamp;
    }
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            DEAD,
            block.timestamp
        );
    }

    function swapBack() private {

        if(tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn) {
            _transfer(address(this), DEAD, tokensForBurn);
        }
        tokensForBurn = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDevelopment;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 10){
            contractBalance = swapTokensAtAmount * 10;
        }

        bool success;
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        
        swapTokensForEth(contractBalance - liquidityTokens); 
        
        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForDevelopment = ethBalance * tokensForDevelopment / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForMarketing + ethForDevelopment;
            
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDevelopment = 0;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(developmentAddress).call{value: ethForDevelopment}("");

        (success,) = address(marketingAddress).call{value: address(this).balance}("");
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this) || !tradingActive, "Can't withdraw native tokens while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setMarketingAddress(address _marketingAddress) external onlyOwner {
        require(_marketingAddress != address(0), "address cannot be 0");
        marketingAddress = payable(_marketingAddress);
        emit UpdatedMarketingAddress(_marketingAddress);
    }
    
    function setDevelopmentAddress(address _developmentAddress) external onlyOwner {
        require(_developmentAddress != address(0), "address cannot be 0");
        developmentAddress = payable(_developmentAddress);
        emit UpdatedDevelopmentAddress(_developmentAddress);
    }
    
    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function launchWithoutAirdrop(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 10, "Cannot make penalty blocks more than 10");

        //standard enable trading
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);
   
        // add the liquidity

        require(address(this).balance > 0, "Must have ETH on contract to launch");

        require(balanceOf(address(this)) > 0, "Must have Tokens on contract to launch");

        _approve(address(this), address(dexRouter), balanceOf(address(this)));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            futureOwnerAddress,
            block.timestamp
        );

        if(balanceOf(msg.sender) > 0){
            super._transfer(msg.sender, futureOwnerAddress, balanceOf(msg.sender));
        }
    }
}