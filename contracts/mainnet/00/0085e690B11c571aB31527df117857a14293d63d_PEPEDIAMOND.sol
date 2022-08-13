/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT                                                                               
// The second most memeable token on ethereum
//https://t.me/PEPEDIAMONDERC
/*                            .-----.
                            /7  .  (
                           /   .-.  \
                          /   /   \  \
                         / `  )   (   )
                        / `   )   ).  \
                      .'  _.   \_/  . |
     .--.           .' _.' )`.        |
    (    `---...._.'   `---.'_)    ..  \
     \            `----....___    `. \  |
      `.           _ ----- _   `._  )/  |
        `.       /"  \   /"  \`.  `._   |
          `.    ((O)` ) ((O)` ) `.   `._\
            `-- '`---'   `---' )  `.    `-.
               /                  ` \      `-.
             .'                      `.       `.
            /                     `  ` `.       `-.
     .--.   \ ===._____.======. `    `   `. .___.--`     .''''.
    ' .` `-. `.                )`. `   ` ` \          .' . '  8)
   (8  .  ` `-.`.               ( .  ` `  .`\      .'  '    ' /
    \  `. `    `-.               ) ` .   ` ` \  .'   ' .  '  /
     \ ` `.  ` . \`.    .--.     |  ` ) `   .``/   '  // .  /
      `.  ``. .   \ \   .-- `.  (  ` /_   ` . / ' .  '/   .'
        `. ` \  `  \ \  '-.   `-'  .'  `-.  `   .  .'/  .'
          \ `.`.  ` \ \    ) /`._.`       `.  ` .  .'  /
    LGB    |  `.`. . \ \  (.'               `.   .'  .'
        __/  .. \ \ ` ) \                     \.' .. \__
 .-._.-'     '"  ) .-'   `.                   (  '"     `-._.--.
(_________.-====' / .' /\_)`--..__________..-- `====-. _________)
                 (.'(.'
*/                     
pragma solidity 0.8.15;

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

interface IDexRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
}

interface IDexFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract PEPEDIAMOND is ERC20, Ownable {

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address public communityAddress;
    address public devAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active

    bool public tradingActive = false;
    bool public swapEnabled = false;

    uint256 public buyTotalFees;
    uint256 public buyCommunityFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellCommunityFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBurnFee;

    uint256 public constant FEE_DIVISOR = 10000;

    uint256 public tokensForCommunity;
    uint256 public tokensForLiquidity;

    uint256 public lpWithdrawRequestTimestamp;
    uint256 public lpWithdrawRequestDuration = 30 days;
    bool public lpWithdrawRequestPending;
    uint256 public lpPercToWithDraw;

    uint256 public percentForLPBurn = 25; // 25 = .25%
    bool public lpBurnEnabled = false;
    uint256 public lpBurnFrequency = 360000 seconds;
    uint256 public lastLpBurnTime;
    
    uint256 public manualBurnFrequency = 1 seconds;
    uint256 public lastManualLpBurnTime;
    
    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    event EnabledTrading();

    event ExcludeFromFees(address indexed account, bool isExcluded);

    event UpdatedMaxBuyAmount(uint256 newAmount);

    event UpdatedMaxSellAmount(uint256 newAmount);

    event UpdatedMaxWalletAmount(uint256 newAmount);

    event UpdatedCommunityAddress(address indexed newWallet);

    event UpdatedDevAddress(address indexed newWallet);

    event OwnerForcedSwapBack(uint256 timestamp);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event AutoBurnLP(uint256 indexed tokensBurned);

    event ManualBurnLP(uint256 indexed tokensBurned);

    event TransferForeignToken(address token, uint256 amount);

    event RequestedLPWithdraw();
    
    event WithdrewLPForMigration();

    event CanceledLpWithdrawRequest();

    constructor() ERC20("PEPEDIAMOND", "PEPED") payable {
        
        address newOwner = msg.sender; // can leave alone if owner is deployer.
        address _dexRouter;

        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 4){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 56){
            _dexRouter = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BNB Chain: PCS V2
        } else if(block.chainid == 97){
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BNB Chain: PCS V2
        } else if(block.chainid == 42161){
            _dexRouter = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506; // Arbitrum: SushiSwap
        } else {
            revert("Chain not configured");
        }

        // initialize router
        dexRouter = IDexRouter(_dexRouter);
        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 10 * 1e9 * (10 ** decimals());
        
        swapTokensAtAmount = totalSupply * 25 / 100000;

        buyCommunityFee = 100;
        buyLiquidityFee = 100;
        buyBurnFee = 50;
        buyTotalFees = buyCommunityFee + buyLiquidityFee + buyBurnFee;

        sellCommunityFee = 450;
        sellLiquidityFee = 500;
        sellBurnFee = 50;
        sellTotalFees = sellCommunityFee + sellLiquidityFee + sellBurnFee;

        communityAddress = address(msg.sender);
        devAddress = address(msg.sender);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(communityAddress), true);
        excludeFromFees(address(dexRouter), true);

        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    receive() external payable {}
    
    function enableTrading() external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        emit EnabledTrading();
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}
    
    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }

    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function updateBuyFees(uint256 _communityFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        buyCommunityFee = _communityFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyCommunityFee + buyLiquidityFee + buyBurnFee;
    }

    function updateSellFees(uint256 _communityFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        sellCommunityFee = _communityFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellCommunityFee + sellLiquidityFee + sellBurnFee;
    }

    function massExcludeFromFees(address[] calldata accounts, bool excluded) external onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++){
            _isExcludedFromFees[accounts[i]] = excluded;
            emit ExcludeFromFees(accounts[i], excluded);
        }
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(address from, address to, uint256 amount) internal override {

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");
        
        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        
        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
            swapping = true;
            swapBack();
            swapping = false;
        }

        if(!swapping && automatedMarketMakerPairs[to] && lpBurnEnabled && block.timestamp >= lastLpBurnTime + lpBurnFrequency && !_isExcludedFromFees[from]){
            autoBurnLiquidityPairTokens();
        }

        bool takeFee = true;
        // if any account belongs to _isExcludedFromFee account then remove the fee
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }
        
        uint256 fees = 0;
        uint256 tokensToBurn = 0;

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // on sell
           if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / FEE_DIVISOR;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForCommunity += fees * sellCommunityFee / sellTotalFees;
                tokensToBurn = fees * sellBurnFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / FEE_DIVISOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForCommunity += fees * buyCommunityFee / buyTotalFees;
                tokensToBurn = fees * buyBurnFee / buyTotalFees;
            }
            
            if(fees > 0){    
                super._transfer(from, address(this), fees);
                if(tokensToBurn > 0){
                    super._transfer(address(this), address(0xdead), tokensToBurn);
                }
            }
        	
        	amount -= fees;
        }

        super._transfer(from, to, amount);
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
    
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    function swapBack() private {

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForCommunity;
        
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

        uint256 ethForCommunity = ethBalance * tokensForCommunity / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForCommunity;
            
        tokensForLiquidity = 0;
        tokensForCommunity = 0;
       
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(communityAddress).call{value: address(this).balance}("");
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require((_token != address(this) && _token != address(lpPair)) || !tradingActive, "Can't withdraw native tokens or LP while trading is active");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setCommunityAddress(address _communityAddress) external onlyOwner {
        require(_communityAddress != address(0), "_communityAddress address cannot be 0");
        communityAddress = payable(_communityAddress);
        emit UpdatedCommunityAddress(_communityAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function setAutoLPBurnSettings(uint256 _frequencyInSeconds, uint256 _percent, bool _Enabled) external onlyOwner {
        require(_frequencyInSeconds >= 600, "cannot set buyback more often than every 10 minutes");
        require(_percent <= 1000 && _percent >= 0, "Must set auto LP burn percent between 0% and 10%");
        lpBurnFrequency = _frequencyInSeconds;
        percentForLPBurn = _percent;
        lpBurnEnabled = _Enabled;
    }
    
    function autoBurnLiquidityPairTokens() internal {
        
        lastLpBurnTime = block.timestamp;
        
        lastManualLpBurnTime = block.timestamp;
        uint256 lpBalance = IERC20(lpPair).balanceOf(address(this));
        uint256 tokenBalance = balanceOf(address(this));
        uint256 lpAmount = lpBalance * percentForLPBurn / 10000;
        uint256 initialEthBalance = address(this).balance;

        // approve token transfer to cover all possible scenarios
        IERC20(lpPair).approve(address(dexRouter), lpAmount);

        // remove the liquidity
        dexRouter.removeLiquidityETH(
            address(this),
            lpAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        uint256 deltaTokenBalance = balanceOf(address(this)) - tokenBalance;
        if(deltaTokenBalance > 0){
            super._transfer(address(this), address(0xdead), deltaTokenBalance);
        }

        uint256 deltaEthBalance = address(this).balance - initialEthBalance;

        if(deltaEthBalance > 0){
            buyBackTokens(deltaEthBalance);
        }

        emit AutoBurnLP(lpAmount);
    }

    function manualBurnLiquidityPairTokens(uint256 percent) external onlyOwner {
        require(percent <=2000, "May not burn more than 20% of contract's LP at a time");
        require(lastManualLpBurnTime <= block.timestamp - manualBurnFrequency, "Burn too soon");
        lastManualLpBurnTime = block.timestamp;
        uint256 lpBalance = IERC20(lpPair).balanceOf(address(this));
        uint256 tokenBalance = balanceOf(address(this));
        uint256 lpAmount = lpBalance * percent / 10000;
        uint256 initialEthBalance = address(this).balance;

        // approve token transfer to cover all possible scenarios
        IERC20(lpPair).approve(address(dexRouter), lpAmount);

        // remove the liquidity
        dexRouter.removeLiquidityETH(
            address(this),
            lpAmount,
            1, // slippage is unavoidable
            1, // slippage is unavoidable
            address(this),
            block.timestamp
        );

        uint256 deltaTokenBalance = balanceOf(address(this)) - tokenBalance;
        if(deltaTokenBalance > 0){
            super._transfer(address(this), address(0xdead), deltaTokenBalance);
        }

        uint256 deltaEthBalance = address(this).balance - initialEthBalance;

        if(deltaEthBalance > 0){
            buyBackTokens(deltaEthBalance);
        }

        emit ManualBurnLP(lpAmount);
    }

    function buyBackTokens(uint256 amountInWei) internal {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0,
            path,
            address(0xdead),
            block.timestamp
        );
    }

    function requestToWithdrawLP(uint256 percToWithdraw) external onlyOwner {
        require(!lpWithdrawRequestPending, "Cannot request again until first request is over.");
        require(percToWithdraw <= 100 && percToWithdraw > 0, "Need to set between 1-100%");
        lpWithdrawRequestTimestamp = block.timestamp;
        lpWithdrawRequestPending = true;
        lpPercToWithDraw = percToWithdraw;
        emit RequestedLPWithdraw();
    }

    function nextAvailableLpWithdrawDate() public view returns (uint256){
        if(lpWithdrawRequestPending){
            return lpWithdrawRequestTimestamp + lpWithdrawRequestDuration;
        }
        else {
            return 0;  // 0 means no open requests
        }
    }

    function withdrawRequestedLP() external onlyOwner {
        require(block.timestamp >= nextAvailableLpWithdrawDate() && nextAvailableLpWithdrawDate() > 0, "Must request and wait.");
        lpWithdrawRequestTimestamp = 0;
        lpWithdrawRequestPending = false;

        uint256 amtToWithdraw = IERC20(address(lpPair)).balanceOf(address(this)) * lpPercToWithDraw / 100;
        
        lpPercToWithDraw = 0;

        IERC20(lpPair).transfer(msg.sender, amtToWithdraw);
    }

    function cancelLPWithdrawRequest() external onlyOwner {
        lpWithdrawRequestPending = false;
        lpPercToWithDraw = 0;
        lpWithdrawRequestTimestamp = 0;
        emit CanceledLpWithdrawRequest();
    }
}