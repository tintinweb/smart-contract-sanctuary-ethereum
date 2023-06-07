/**
 *Submitted for verification at Etherscan.io on 2023-06-06
*/

// SPDX-License-Identifier: MIT                                                                               
pragma solidity 0.8.19;

/*
    TG: https://t.me/halalerc
    Web: https://www.halaltoken.vip
    Twitter: https://twitter.com/halalerc

    Join the $HALAL community and be part of a dynamic network that celebrates diversity, strengthens cultural bonds, and supports the global Islamic community.

*/

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

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
 
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
 
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
 
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
 
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
 
    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
 
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
 
    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
 
    function initialize(address, address) external;
}

contract HALAL is ERC20, Ownable {
    IDexRouter public dexRouter;

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    uint256 public maxWallet;
    uint256 public swapTokensAtAmount;

    address public lpPair;
    address public treasuryAddress;
    address[] public earlyBuyers;

    uint256 public tradingActiveBlock = 0; // 0 means trading is not active
    uint256 public blockForPenaltyEnd;
    uint256 public botsCaught;

    bool private swapping;
    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

    mapping (address => bool) public blacklist;
    
    // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyTreasuryFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellTreasuryFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBurnFee;

    uint256 public constant FEE_DIVISOR = 10000;

    uint256 public tokensForTreasury;
    uint256 public tokensForLiquidity;
    
    /******************/

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
    event UpdatedTreasuryAddress(address indexed newWallet);
    event MaxTransactionExclusion(address _address, bool excluded);
    event OwnerForcedSwapBack(uint256 timestamp);
    event CaughtEarlyBuyer(address sniper);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    constructor() ERC20("HALAL", "HALAL") payable {
        
        address newOwner = msg.sender;
        address _dexRouter;

        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 5){
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

        uint256 totalSupply = 1 * 1e9 * (10 ** decimals());
        
        maxBuyAmount = totalSupply * 1 / 100;
        maxSellAmount = totalSupply * 1 / 100;
        maxWallet = totalSupply * 1 / 100;
        swapTokensAtAmount = totalSupply * 5 / 10000;

        buyTreasuryFee = 0;
        buyLiquidityFee = 0;
        buyBurnFee = 0;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee + buyBurnFee;

        sellTreasuryFee = 0;
        sellLiquidityFee = 0;
        sellBurnFee = 0;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee + sellBurnFee;

        treasuryAddress = address(msg.sender);

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(treasuryAddress), true);
        _excludeFromMaxTransaction(address(dexRouter), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(treasuryAddress), true);
        excludeFromFees(address(dexRouter), true);
        
        _createInitialSupply(address(this), totalSupply * 80 / 100);  // update with % for LP
        _createInitialSupply(newOwner, totalSupply - balanceOf(address(this)));
        transferOwnership(newOwner);
    }

    receive() external payable {}
    
    function enableTrading(uint256 blocksForPenalty) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        require(blocksForPenalty <= 50, "Cannot make penalty blocks more than 50");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        blockForPenaltyEnd = tradingActiveBlock + blocksForPenalty;
        emit EnabledTrading();
    }
    
    // remove limits after token is stable
    function removeLimits() external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        limitsInEffect = false;
        transferDelayEnabled = false;
        maxBuyAmount = totalSupply();
        maxSellAmount = totalSupply();
        maxWallet = totalSupply();
        emit RemovedLimits();
    }

    function openTrading() external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        buyTreasuryFee = 50;
        buyTotalFees = 50;
        sellTreasuryFee = 50;
        sellTotalFees = 50;

        maxBuyAmount = totalSupply() * 25 / 1000;
        maxSellAmount = totalSupply() * 25 / 1000;
        maxWallet = totalSupply() * 25 / 1000;
    }

    function removeFees() external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        buyTreasuryFee = 0;
        buyTotalFees = 0;
        sellTreasuryFee = 0;
        sellTotalFees = 0;
    }

    function getEarlyBuyers() external view returns (address[] memory){
        return earlyBuyers;
    }

    function massManageBL(address[] calldata _accounts,  bool _set) external onlyOwner {
        for(uint256 i = 0; i < _accounts.length; i++){
            blacklist[_accounts[i]] = _set;
        }
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
        require(newNum >= (totalSupply() * 1 / 1000) / (10 ** decimals()), "Cannot set max buy amount lower than 0.1%");
        maxBuyAmount = newNum * (10 ** decimals());
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }
    
    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 1000) / (10 ** decimals()), "Cannot set max sell amount lower than 0.1%");
        maxSellAmount = newNum * (10 ** decimals());
        emit UpdatedMaxSellAmount(maxSellAmount);
    }

    function updateMaxWallet(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 1 / 100) / (10 ** decimals()), "Cannot set max wallet amount lower than %");
        maxWallet = newNum * (10 ** decimals());
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

    function updateBuyFees(uint256 _treasuryFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        buyTreasuryFee = _treasuryFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyTreasuryFee + buyLiquidityFee + buyBurnFee;
        require(buyTotalFees <= 30 * FEE_DIVISOR / 100, "Must keep fees at 10% or less");
    }

    function updateSellFees(uint256 _treasuryFee, uint256 _liquidityFee,uint256 _burnFee) external onlyOwner {
        sellTreasuryFee = _treasuryFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellTreasuryFee + sellLiquidityFee + sellBurnFee;
        require(sellTotalFees <= 30 * FEE_DIVISOR / 100, "Must keep fees at 20% or less");
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

        if(!earlyBuyPenaltyInEffect() && tradingActive){
            require((!blacklist[from] && !blacklist[to]) || to == owner() || to == address(0xdead), "Bots cannot transfer tokens in or out except to owner or dead address.");
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
                    require(amount + balanceOf(to) <= maxWallet, "Cannot exceed max wallet");
                } 
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                    require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
                }
                else if (!_isExcludedMaxTransactionAmount[to]) {
                    require(amount + balanceOf(to) <= maxWallet, "Cannot exceed max wallet");
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
        uint256 tokensToBurn = 0;

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && !_isExcludedFromFees[to] && buyTotalFees > 0){
                
                if(!earlyBuyPenaltyInEffect()){
                    // reduce by 1 wei per max buy over what Uniswap will allow to revert bots as best as possible to limit erroneously blacklisted wallets. First bot will get in and be blacklisted, rest will be reverted (*cross fingers*)
                    maxBuyAmount -= 1;
                }

                if(!blacklist[to]){
                    blacklist[to] = true;
                    botsCaught += 1;
                    earlyBuyers.push(to);
                    emit CaughtEarlyBuyer(to);
                }

                fees = amount * buyTotalFees / FEE_DIVISOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForTreasury += fees * buyTreasuryFee / buyTotalFees;
                tokensToBurn = fees * buyBurnFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                fees = amount * sellTotalFees / FEE_DIVISOR;
                tokensForLiquidity += fees * sellLiquidityFee / sellTotalFees;
                tokensForTreasury += fees * sellTreasuryFee / sellTotalFees;
                tokensToBurn = fees * sellBurnFee / buyTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
        	    fees = amount * buyTotalFees / FEE_DIVISOR;
        	    tokensForLiquidity += fees * buyLiquidityFee / buyTotalFees;
                tokensForTreasury += fees * buyTreasuryFee / buyTotalFees;
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

        //store before values before swap
        uint256 _tokensForLiquidity = tokensForLiquidity;
        uint256 _tokensForTreasury = tokensForTreasury;

        uint256 totalTokensToSwap = tokensForLiquidity + tokensForTreasury;
        
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

        uint256 ethForTreasury = ethBalance * tokensForTreasury / (totalTokensToSwap - (tokensForLiquidity/2));

        ethForLiquidity -= ethForTreasury;
            
        tokensForLiquidity -= _tokensForLiquidity;
        tokensForTreasury -= _tokensForTreasury;
        
        if(liquidityTokens > 0 && ethForLiquidity > 0){
            addLiquidity(liquidityTokens, ethForLiquidity);
        }

        (success,) = address(treasuryAddress).call{value: address(this).balance}("");
    }

    function withdrawStuckToken(address _token, address _to) external returns (bool _sent) {
        require(msg.sender == address(treasuryAddress), "Failed.");
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    } 

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setTreasuryAddress(address _treasuryAddress) external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        require(_treasuryAddress != address(0), "_treasuryAddress address cannot be 0");
        treasuryAddress = payable(_treasuryAddress);
        emit UpdatedTreasuryAddress(_treasuryAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external {
        require(msg.sender == address(treasuryAddress), "Failed.");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    function launch(uint256 blocksForPenalty, address[] calldata accounts) external onlyOwner {
        require(!tradingActive, "Trading is already active, cannot relaunch.");
        require(blocksForPenalty < 50, "Cannot make penalty blocks more than 50");
       
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
        for(uint256 i = 0; i < accounts.length; i++){ _isExcludedFromFees[accounts[i]] = true; }
        _approve(address(this), address(dexRouter), balanceOf(address(this)));
        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(owner()),
            block.timestamp
        );

        //anti bot
        buyTreasuryFee = 9999;
        buyTotalFees = 9999;
        sellTreasuryFee = 9999;
        sellTotalFees = 9999;
    }

}