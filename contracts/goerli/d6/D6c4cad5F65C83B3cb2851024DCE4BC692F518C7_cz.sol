/**
 *Submitted for verification at Etherscan.io on 2022-10-27
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// SPDX-License-Identifier: MIT

/**
This one for the goat, Changpeng Zhao.
$CZ
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

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);
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

/////////////////////////////////////FUN STARTS/////////////////////////////

contract cz is ERC20, Ownable {

    // Declare variables

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWalletAmount;

    IDexRouter public dexRouter;
    address public lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    address operationsAddress;
    address devAddress;
    address burnAddress;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    mapping (address => bool) public boughtEarly;
    uint256 public botsCaught;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    // Declare fee variables
    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyDevFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellDevFee;
    uint256 public sellBurnFee;

    uint256 public sellTotalFeesEarly;
    uint256 public sellOperationsFeeEarly;
    uint256 public sellLiquidityFeeEarly;
    uint256 public sellDevFeeEarly;
    uint256 public sellBurnFeeEarly;

    uint256 public tokensForOperations;
    uint256 public tokensForLiquidity;
    uint256 public tokensForDev;
    uint256 public tokensForBurn;

    /******************/

    // exlcude from fees and max transaction amount
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public _isExcludedMaxTransactionAmount;

    //BuyMap and manual bots
    mapping (address => uint256) public _buyMap;
    mapping(address => bool) public bots;

    // store addresses that a automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping (address => bool) public automatedMarketMakerPairs;

    constructor() ERC20("Changpeng Zhao", "CZ") {

        // Set owner
        address newOwner = msg.sender;

        // Set uniswap router
        IDexRouter _dexRouter = IDexRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        dexRouter = _dexRouter;

        // Set burn address
        burnAddress = 0x000000000000000000000000000000000000dEaD;

        // Create pair
        lpPair = IDexFactory(_dexRouter.factory()).createPair(address(this), _dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        // Set Supply
        uint256 totalSupply = 5 * 1e12 * 1e18;

        // Set Limits
        maxBuyAmount = totalSupply * 2 / 100;
        maxSellAmount = totalSupply * 2 / 100;
        maxWalletAmount = totalSupply * 2 / 100;
        swapTokensAtAmount = totalSupply * 5 / 10000;

        // Set Fees
        buyOperationsFee = 2;
        buyLiquidityFee = 2;
        buyDevFee = 2;
        buyBurnFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee + buyBurnFee;

        sellOperationsFee = 2;
        sellLiquidityFee = 2;
        sellDevFee = 2;
        sellBurnFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee + sellBurnFee;

        sellOperationsFeeEarly = 20;
        sellLiquidityFeeEarly = 0;
        sellDevFeeEarly = 60;
        sellBurnFeeEarly = 0;
        sellTotalFeesEarly = sellOperationsFeeEarly + sellLiquidityFeeEarly + sellDevFeeEarly + sellBurnFeeEarly;

        // Set exclusions
        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);

        // Set wallets that will receive fees
        operationsAddress = address(newOwner);
        devAddress = address(newOwner);

        // Start everything
        _createInitialSupply(newOwner, totalSupply);
        transferOwnership(newOwner);
    }

    // This is so the contract can receive eth and tokens
    receive() external payable {}

    // Enable people to trade the token
    function enableTrading(uint256 deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + deadBlocks;
    }

    // Remove limits after token is stable, these limits being transfer delay, max wallet and max tx.
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
    }

    // Disable Transfer delay - cannot be reenabled, this is so people can't buy with contract and automatically send the tokens to another wallet.
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    // Update the max buy amount
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max buy amount lower than 0.2%");
        maxBuyAmount = newNum * (10**18);
    }

    // Update the max sell amount
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max sell amount lower than 0.2%");
        maxSellAmount = newNum * (10**18);
    }

    // Update the max wallet amount
    function updateMaxWalletAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 3 / 1000)/1e18, "Cannot set max wallet amount lower than 0.3%");
        maxWalletAmount = newNum * (10**18);
    }

    // Change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
  	    require(newAmount >= totalSupply() * 1 / 100000, "Swap amount cannot be lower than 0.001% total supply.");
  	    require(newAmount <= totalSupply() * 1 / 1000, "Swap amount cannot be higher than 0.1% total supply.");
  	    swapTokensAtAmount = newAmount;
  	}

    // Exclude addresses from being limited by the max transaction from the inside.
    function _excludeFromMaxTransaction(address updAds, bool isExcluded) private {
        _isExcludedMaxTransactionAmount[updAds] = isExcluded;
    }


    // Exclude addresses from being limited by the max transaction from the outside.
    function excludeFromMaxTransaction(address updAds, bool isEx) external onlyOwner {
        if(!isEx){
            require(updAds != lpPair, "Cannot remove uniswap pair from max txn");
        }
        _isExcludedMaxTransactionAmount[updAds] = isEx;
    }

    // This is to set a new item in the automatedMarketMakerPairs array.
    function setAutomatedMarketMakerPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from automatedMarketMakerPairs");

        _setAutomatedMarketMakerPair(pair, value);
    }

    // This is to set the value of a special address in the automatedMarketMakerPairs array
    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;

        _excludeFromMaxTransaction(pair, value);

    }

    //Update the buy fees
    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee, uint256 _burnFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyDevFee = _devFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee + buyBurnFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    // Update the sell fees
    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee, uint256 _burnFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellDevFee = _devFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee + sellBurnFee;
        require(sellTotalFees <= 30, "Must keep fees at 30% or less");
    }

    // Update the sell early fees
    function updateSellFeesEarly(uint256 _operationsFee, uint256 _liquidityFee, uint256 _devFee, uint256 _burnFee) external onlyOwner {
        sellOperationsFeeEarly = _operationsFee;
        sellLiquidityFeeEarly = _liquidityFee;
        sellDevFeeEarly = _devFee;
        sellBurnFeeEarly = _burnFee;
        sellTotalFeesEarly = sellOperationsFeeEarly + sellLiquidityFeeEarly + sellDevFeeEarly + sellBurnFeeEarly;
        require(sellTotalFeesEarly <= 80, "Must keep fees at 80% or less");
    }

    // This is for when you want to have taxes return to a mean after a certain period of time or something.
    function returnToNormalTax() external onlyOwner {
        sellOperationsFee = 20;
        sellLiquidityFee = 0;
        sellDevFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellDevFee + sellBurnFee;
        require(sellTotalFees <= 30, "Must keep fees at 30% or less");

        buyOperationsFee = 20;
        buyLiquidityFee = 0;
        buyDevFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyDevFee + buyBurnFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");

        sellOperationsFeeEarly = 0;
        sellLiquidityFeeEarly = 0;
        sellDevFeeEarly = 0;
        sellBurnFeeEarly = 0;
        sellTotalFeesEarly = sellOperationsFeeEarly + sellLiquidityFeeEarly + sellDevFeeEarly + sellBurnFeeEarly;
        require(sellTotalFeesEarly <= 80, "Must keep fees at 80% or less");
    }

    // Exclude an address from paying fees
    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    // Main token functions
    function _transfer(address from, address to, uint256 amount) internal override {

        require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(!tradingActive){
            require(_isExcludedFromFees[from] || _isExcludedFromFees[to], "Trading is not active.");
        }

        if(blockForPenaltyEnd > 0){
            require(!boughtEarly[from] || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
        }

        if(limitsInEffect){
            if (from != owner() && to != owner() && to != address(0) && to != address(0xdead) && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]){

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.
                if (transferDelayEnabled){
                    if (to != address(dexRouter) && to != address(lpPair)){
                        require(_holderLastTransferTimestamp[tx.origin] < block.number - 2 && _holderLastTransferTimestamp[to] < block.number - 2, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferTimestamp[tx.origin] = block.number;
                        _holderLastTransferTimestamp[to] = block.number;
                    }
                }

                //when buy
                if (automatedMarketMakerPairs[from] && !_isExcludedMaxTransactionAmount[to]) {
                        require(amount <= maxBuyAmount, "Buy transfer amount exceeds the max buy.");
                        require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]){
                    require(amount + balanceOf(to) <= maxWalletAmount, "Cannot Exceed max wallet");
                }
            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        bool canSwap = contractTokenBalance >= swapTokensAtAmount;

        if(canSwap && swapEnabled && !swapping && !automatedMarketMakerPairs[from] && !_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
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
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){

                if(!boughtEarly[to]){
                    boughtEarly[to] = true;
                    botsCaught += 1;
                }

                fees = amount * 99 / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){

                if(_buyMap[from] != 0 && ((_buyMap[from] + (24 * 1 hours)) >= block.timestamp)) {
                    fees = amount * sellTotalFeesEarly / 100;
                    tokensForLiquidity += fees * sellLiquidityFeeEarly / sellTotalFeesEarly;
                    tokensForOperations += fees * sellOperationsFeeEarly / sellTotalFeesEarly;
                    tokensForDev += fees * sellDevFeeEarly / sellTotalFeesEarly;
                    tokensForBurn += fees * sellBurnFeeEarly / sellTotalFeesEarly;
                }

                fees = amount * sellTotalFees / 100;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForDev += fees * sellDevFee / sellTotalFees;
                tokensForBurn += fees * sellBurnFee / sellTotalFees;

            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {

                if (_buyMap[to] == 0) {
                    _buyMap[to] = block.timestamp;
                }

        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForDev += fees * buyDevFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
            }

        	amount -= fees;
        }

        super._transfer(from, to, amount);
    }

    // Blacklist an address
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    // Unblacklist an address
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    // Check if the buy went through before the allowed block
    function earlyBuyPenaltyInEffect() public view returns (bool){
        return block.number < blockForPenaltyEnd;
    }

    // Function to swap erc20 tokens for eth
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

    // Function to add liquidity to the token
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(dexRouter), tokenAmount);

        // add the liquidity
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0xdead),
            block.timestamp
        );
    }

    // Function used for transfering fees
    function swapBack() private {

        if(tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn) {
            _burn(address(this), tokensForBurn);
        }
        tokensForBurn = 0;

        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = tokensForLiquidity + tokensForOperations + tokensForDev;

        if(contractBalance == 0 || totalTokensToSwap == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        bool success;

        // Halve the amount of liquidity tokens
        uint256 liquidityTokens = contractBalance * tokensForLiquidity / totalTokensToSwap / 2;

        swapTokensForEth(contractBalance - liquidityTokens);

        uint256 ethBalance = address(this).balance;
        uint256 ethForLiquidity = ethBalance;

        uint256 ethForOperations = ethBalance * tokensForOperations / (totalTokensToSwap - (tokensForLiquidity/2));
        uint256 ethForDev = ethBalance * tokensForDev / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForOperations + ethForDev;

        tokensForLiquidity = 0;
        tokensForOperations = 0;
        tokensForDev = 0;
        tokensForBurn = 0;

        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(devAddress).call{value: ethForDev}("");

        (success,) = address(operationsAddress).call{value: address(this).balance}("");
    }

    // Withdraw stuck ERC Tokens In Contract
    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    // Withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    // Set the wallet that will receive the operations fees
    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
        operationsAddress = payable(_operationsAddress);
    }

    // Set the wallet that will receive the dev fees
    function setDevAddress(address _devAddress) external onlyOwner {
        require(_devAddress != address(0), "_devAddress address cannot be 0");
        devAddress = payable(_devAddress);
    }

    // Force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
    }

    // Buyback and burn function, first send eth to the contract
    function buyBackAndBurn(address _tokenToBuy, uint256 _amountEth) public onlyOwner {

        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = _tokenToBuy;

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{ value: (_amountEth) }(5, path, address(this), block.timestamp + 15);

        uint256 amountOfTokensBought = IERC20(_tokenToBuy).balanceOf(address(this));

        IERC20(_tokenToBuy).transfer(burnAddress, amountOfTokensBought);

   }
}