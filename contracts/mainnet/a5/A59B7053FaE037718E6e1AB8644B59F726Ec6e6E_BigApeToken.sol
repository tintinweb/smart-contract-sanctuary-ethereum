/**
 *Submitted for verification at Etherscan.io on 2022-10-20
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];
                set._values[toDeleteIndex] = lastValue;
                set._indexes[lastValue] = valueIndex;
            }

            set._values.pop();

            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }


    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract BigApeToken is ERC20, Ownable {

    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private walletsOutstanding;
    mapping(address => uint256) public totalAmount;
    mapping(address => uint256) public unlockedAmount;
    mapping(address => uint256) public lastUnlock;
    mapping(address => uint256) public firstUnlockOffset;
    mapping(address => uint256) public totalUnlockDuration;
    mapping(address => uint256) public unlockFrequency;
    mapping(address => uint256) public firstUnlockPercent;
    mapping(address => bool) public unlockedFirst;

    mapping(address => bool) public isAuthorized;
    
    modifier onlyAuthorized(){
        require(isAuthorized[msg.sender], "Not authorized");
        _;
    }

    event VestingTokens(address indexed wallet, uint256 amount);

    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;

    IDexRouter public immutable dexRouter;
    address public immutable lpPair;

    bool private swapping;
    uint256 public swapTokensAtAmount;

    TokenPresale public tokenPresale;

    address operationsAddress;

    uint256 public tradingActiveBlock;
    uint256 public tradingActiveTs;
    uint256 public blockForPenaltyEnd;

    bool public limitsInEffect = true;
    bool public tradingActive = false;
    bool public swapEnabled = false;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferTimestamp; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public buyTotalFees;
    uint256 public buyOperationsFee;
    uint256 public buyLiquidityFee;
    uint256 public buyBurnFee;

    uint256 public sellTotalFees;
    uint256 public sellOperationsFee;
    uint256 public sellLiquidityFee;
    uint256 public sellBurnFee;

    uint256 public tokensForOperations;
    uint256 public tokensForBurn;

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

    event UpdatedOperationsAddress(address indexed newWallet);

    event MaxTransactionExclusion(address _address, bool excluded);

    event BuyBackTriggered(uint256 amount);

    event OwnerForcedSwapBack(uint256 timestamp);

    event CaughtEarlyBuyer(address sniper);

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiquidity
    );

    event TransferForeignToken(address token, uint256 amount);

    constructor() ERC20("Big Ape Token", "BAT") {
    
        address newOwner = msg.sender; // can leave alone if owner is deployer.
        address _dexRouter;

        // automatically detect router/desired stablecoin
        if(block.chainid == 1){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH: Uniswap V2
        } else if(block.chainid == 5){
            _dexRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // Goerli ETH: Uniswap V2
        } else if(block.chainid == 97){
            _dexRouter = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Testnet: PCS V2
        } else {
            revert("Chain not configured");
        }

        dexRouter = IDexRouter(_dexRouter);

        tokenPresale = new TokenPresale();

        // create pair
        lpPair = IDexFactory(dexRouter.factory()).createPair(address(this), dexRouter.WETH());
        _excludeFromMaxTransaction(address(lpPair), true);
        _setAutomatedMarketMakerPair(address(lpPair), true);

        uint256 totalSupply = 1 * 1e9 * 1e18;

        maxBuyAmount = totalSupply * 25 / 10000;
        maxSellAmount = totalSupply * 25 / 10000;
        swapTokensAtAmount = totalSupply * 1 / 10000; 

        buyOperationsFee = 3;
        buyLiquidityFee = 1;
        buyBurnFee = 1;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyBurnFee;

        sellOperationsFee = 3;
        sellLiquidityFee = 2;
        sellBurnFee = 1;
        sellTotalFees = sellOperationsFee + sellLiquidityFee+ sellBurnFee;

        _excludeFromMaxTransaction(newOwner, true);
        _excludeFromMaxTransaction(address(this), true);
        _excludeFromMaxTransaction(address(0xdead), true);
        _excludeFromMaxTransaction(address(dexRouter), true);
        _excludeFromMaxTransaction(address(tokenPresale), true);

        excludeFromFees(newOwner, true);
        excludeFromFees(address(this), true);
        excludeFromFees(address(0xdead), true);
        excludeFromFees(address(dexRouter), true);
        excludeFromFees(address(tokenPresale), true);

        operationsAddress = address(newOwner);
        
        isAuthorized[newOwner] = true;
        isAuthorized[address(tokenPresale)] = true;

        _createInitialSupply(address(tokenPresale), totalSupply * 11 / 100);
        _createInitialSupply(newOwner, totalSupply - balanceOf(address(tokenPresale)));
        transferOwnership(newOwner);
        tokenPresale.transferOwnership(newOwner);
    }

    receive() external payable {}

    function enableTrading(uint256 deadBlocks) external onlyOwner {
        require(!tradingActive, "Cannot reenable trading");
        require(deadBlocks <= 7, "Cannot set more than 7 deadblocks");
        tradingActive = true;
        swapEnabled = true;
        tradingActiveBlock = block.number;
        tradingActiveTs = block.timestamp;
        blockForPenaltyEnd = tradingActiveBlock + deadBlocks;
        emit EnabledTrading();
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        transferDelayEnabled = false;
        emit RemovedLimits();
    }

    function setAuthorized(address account, bool authorized) external onlyOwner {
        isAuthorized[account] = authorized;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }
    
    function updateMaxBuyAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max buy amount lower than 0.2%");
        maxBuyAmount = newNum * (10**18);
        emit UpdatedMaxBuyAmount(maxBuyAmount);
    }

    function updateMaxSellAmount(uint256 newNum) external onlyOwner {
        require(newNum >= (totalSupply() * 2 / 1000)/1e18, "Cannot set max sell amount lower than 0.2%");
        maxSellAmount = newNum * (10**18);
        emit UpdatedMaxSellAmount(maxSellAmount);
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

    function airdropToWallets(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 600, "Can only airdrop 600 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
        }
    }

    function airdropToWalletsWithVesting(address[] memory wallets, uint256[] memory amountsInTokens) external onlyOwner {
        require(!tradingActive, "Cannot vest after trading is enabled");
        require(wallets.length == amountsInTokens.length, "arrays must be the same length");
        require(wallets.length < 300, "Can only airdrop 300 wallets per txn due to gas limits"); // allows for airdrop + launch at the same exact time, reducing delays and reducing sniper input.
        for(uint256 i = 0; i < wallets.length; i++){
            address wallet = wallets[i];
            uint256 amount = amountsInTokens[i];
            super._transfer(msg.sender, wallet, amount);
            vestTeamTokens(wallet, 90 days);
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

    function updateBuyFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        buyOperationsFee = _operationsFee;
        buyLiquidityFee = _liquidityFee;
        buyBurnFee = _burnFee;
        buyTotalFees = buyOperationsFee + buyLiquidityFee + buyBurnFee;
        require(buyTotalFees <= 15, "Must keep fees at 15% or less");
    }

    function updateSellFees(uint256 _operationsFee, uint256 _liquidityFee, uint256 _burnFee) external onlyOwner {
        sellOperationsFee = _operationsFee;
        sellLiquidityFee = _liquidityFee;
        sellBurnFee = _burnFee;
        sellTotalFees = sellOperationsFee + sellLiquidityFee + sellBurnFee;
        require(sellTotalFees <= 15, "Must keep fees at 15% or less");
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

        if(walletsOutstanding.contains(from)){
            (uint256 unlockableAmount, ) = currentUnlockableAmount(from);
            if(unlockableAmount > 0){
                unlockTokens(from);
            }
            require(amount <= currentSellableAmount(from), "Cannot send vesting tokens");
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
                }
                //when sell
                else if (automatedMarketMakerPairs[to] && !_isExcludedMaxTransactionAmount[from]) {
                        require(amount <= maxSellAmount, "Sell transfer amount exceeds the max sell.");
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
        uint256 tokensForLiquidity;
        address liquidityReceiver;

        // only take fees on buys/sells, do not take on wallet transfers
        if(takeFee){
            // bot/sniper penalty.
            if(earlyBuyPenaltyInEffect() && automatedMarketMakerPairs[from] && !automatedMarketMakerPairs[to] && buyTotalFees > 0){
                liquidityReceiver = from;

                fees = amount * 99 / 100;
        	    tokensForLiquidity = fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }

            // on sell
            else if (automatedMarketMakerPairs[to] && sellTotalFees > 0){
                liquidityReceiver = to;
                fees = amount * sellTotalFees / 100;
                tokensForLiquidity = fees * sellLiquidityFee / sellTotalFees;
                tokensForOperations += fees * sellOperationsFee / sellTotalFees;
                tokensForBurn += fees * sellBurnFee / sellTotalFees;
            }

            // on buy
            else if(automatedMarketMakerPairs[from] && buyTotalFees > 0) {
                liquidityReceiver = from;
        	    fees = amount * buyTotalFees / 100;
        	    tokensForLiquidity = fees * buyLiquidityFee / buyTotalFees;
                tokensForOperations += fees * buyOperationsFee / buyTotalFees;
                tokensForBurn += fees * buyBurnFee / buyTotalFees;
            }

            if(fees > 0){
                super._transfer(from, address(this), fees);
                if(tokensForLiquidity > 0){
                    super._transfer(address(this), liquidityReceiver, tokensForLiquidity);
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
            address(operationsAddress),
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
            address(0xdead),
            block.timestamp
        );
    }

    function swapBack() private {

        if(tokensForBurn > 0 && balanceOf(address(this)) >= tokensForBurn) {
            super._transfer(address(this), address(0xdead),tokensForBurn);
        }
        tokensForBurn = 0;

        uint256 contractBalance = balanceOf(address(this));

        if(contractBalance == 0) {return;}

        if(contractBalance > swapTokensAtAmount * 20){
            contractBalance = swapTokensAtAmount * 20;
        }

        swapTokensForEth(contractBalance);

        tokensForOperations = balanceOf(address(this));
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function setOperationsAddress(address _operationsAddress) external onlyOwner {
        require(_operationsAddress != address(0), "_operationsAddress address cannot be 0");
        operationsAddress = payable(_operationsAddress);
    }

    // force Swap back if slippage issues.
    function forceSwapBack() external onlyOwner {
        require(balanceOf(address(this)) >= swapTokensAtAmount, "Can only swap when token amount is at or higher than restriction");
        swapping = true;
        swapBack();
        swapping = false;
        emit OwnerForcedSwapBack(block.timestamp);
    }

    // useful for buybacks or to reunlock any ETH on the contract in a way that helps holders.
    function buyBackTokens(uint256 amountInWei) external onlyOwner {
        require(amountInWei <= 10 ether, "May not buy more than 10 ETH in a single buy to reduce sandwich attacks");

        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

        // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amountInWei}(
            0, // accept any amount of Ethereum
            path,
            address(0xdead),
            block.timestamp
        );
        emit BuyBackTriggered(amountInWei);
    }

    // vesting functions

    function vestTokens(
        address wallets,     
        uint256 amountsWithDecimals, 
        uint256 totalDurationInSeconds, 
        uint256 timeBeforeFirstUnlock, 
        uint256 firstUnlockInitialPercent,
        uint256 unlockFrequencys) 
    external onlyAuthorized {
        
        require(unlockFrequencys > 0 && totalDurationInSeconds % unlockFrequencys == 0, "Unlock frequency set incorrectly");
        require(!tradingActive, "Cannot vest wallets after trading is activated");
        address wallet = wallets;
        uint256 amount = amountsWithDecimals;
        require(balanceOf(wallet) >= amount, "Cannot vest tokens not held");
        totalAmount[wallet] += amount;
        totalUnlockDuration[wallet] = totalDurationInSeconds;
        firstUnlockPercent[wallet] = firstUnlockInitialPercent;
        if(unlockFrequency[wallet] == 0){
            unlockFrequency[wallet] = unlockFrequencys;
        }
        if(lastUnlock[wallet] == 0){
            lastUnlock[wallet] = block.timestamp;
            firstUnlockOffset[wallet] = timeBeforeFirstUnlock;
        }
        emit VestingTokens(wallet, amount);
        if(!walletsOutstanding.contains(wallet)){
            walletsOutstanding.add(wallet);
        }
    }

    function vestTeamTokens(address wallet, uint256 totalDurationInSeconds) internal {
        totalAmount[wallet] = balanceOf(wallet);
        totalUnlockDuration[wallet] = totalDurationInSeconds;
        unlockFrequency[wallet] = totalDurationInSeconds;
        lastUnlock[wallet] = block.timestamp;
        emit VestingTokens(wallet, totalAmount[wallet]);
        if(!walletsOutstanding.contains(wallet)){
            walletsOutstanding.add(wallet);
        }
    }

    function currentUnlockableAmount(address wallet) public view returns (uint256 amountToUnlock, uint256 unlockPeriods){
        // use tradingActive timestamp instead of lastUnlock if last unlock prior to trading active
        uint256 lastUnlockTs;
        if(lastUnlock[wallet] < tradingActiveTs){
            lastUnlockTs = tradingActiveTs + firstUnlockOffset[wallet];
        } else {
            if(!unlockedFirst[wallet]){
                lastUnlockTs = lastUnlock[wallet] + firstUnlockOffset[wallet];
            } else {
                lastUnlockTs = lastUnlock[wallet];
            }
        }

        if(lastUnlockTs > block.timestamp || lastUnlock[wallet] == 0 || tradingActiveTs == 0) return (0,0);

        // firstUnlockPerc granted during first unlock
        if(!unlockedFirst[wallet]){
            amountToUnlock = totalAmount[wallet] * firstUnlockPercent[wallet] / 10000;
        }

        unlockPeriods = (block.timestamp - lastUnlockTs) / unlockFrequency[wallet];

        if((totalUnlockDuration[wallet]/unlockFrequency[wallet]) == 0){
            amountToUnlock = totalAmount[wallet] - unlockedAmount[wallet];
        } else {
            amountToUnlock += unlockPeriods * totalAmount[wallet] / (totalUnlockDuration[wallet]/unlockFrequency[wallet]);
        }
        if(amountToUnlock > totalAmount[wallet] - unlockedAmount[wallet] || totalUnlockDuration[wallet] + lastUnlockTs < block.timestamp){
            amountToUnlock = totalAmount[wallet] - unlockedAmount[wallet];
        }
    }

    function currentSellableAmount(address wallet) public view returns (uint256 sellableAmount){
        (uint256 unlockableAmount,) = currentUnlockableAmount(wallet);
        if(walletsOutstanding.contains(wallet)){
            sellableAmount = balanceOf(wallet) + unlockedAmount[wallet] + unlockableAmount - totalAmount[wallet] ;
        } else {
            sellableAmount = balanceOf(wallet);
        }
    }

    function unlockTokens(address wallet) internal {
        (uint256 amountToUnlock, uint256 unlockPeriods) = currentUnlockableAmount(wallet);
        if(!unlockedFirst[wallet]){
            unlockedFirst[wallet] = true;
        }
        lastUnlock[wallet] += unlockPeriods * unlockFrequency[wallet];
        unlockedAmount[wallet] += amountToUnlock; // prevent reentrancy
        require(amountToUnlock > 0, "Cannot unlock 0");
        require(walletsOutstanding.contains(wallet), "Wallet cannot unlock");
        if(totalAmount[wallet] <= unlockedAmount[wallet]){
            walletsOutstanding.remove(wallet);
        }
    }

    function isVestingWallet(address account) external view returns (bool){
        return walletsOutstanding.contains(account);
    }

    function getNextUnlock(address wallet) external view returns (uint256){
        uint256 lastUnlockTs;
        if(tradingActiveTs == 0){
            return 0;
        }
        if(lastUnlock[wallet] < tradingActiveTs){
            lastUnlockTs = tradingActiveTs + firstUnlockOffset[wallet];
        } else {
            if(!unlockedFirst[wallet]){
                lastUnlockTs = lastUnlock[wallet] + firstUnlockOffset[wallet];
            } else {
                lastUnlockTs = lastUnlock[wallet];
            }
        }

        return (lastUnlockTs + unlockFrequency[wallet]);
    }
}

interface IBigApeToken {
     function vestTokens(
        address wallets,     
        uint256 amountsWithDecimals, 
        uint256 totalDurationInSeconds, 
        uint256 timeBeforeFirstUnlock, 
        uint256 firstUnlockInitialPercent,
        uint256 unlockFrequencys) 
    external;
}

contract TokenPresale is Ownable {
    
    mapping (address => bool) public walletWhitelisted;
    mapping (address => uint256) public purchasedAmount;
    uint256 public tokensPerEth;
    uint256 public maxEthAmount;
    uint256 public minEthAmount;
    uint256 public totalEthCap;
    uint256 public totalPurchasedAmount;
    bool public isInitialized = false;
    bool public isWhitelistPresale = false;
    BigApeToken public immutable tokenAddress;

    event TokensBought(uint256 tokenAmount, uint256 indexed ethAmount, address indexed sender);
    
    constructor() {
        tokenAddress = BigApeToken(payable(msg.sender));
        tokensPerEth = 22000000 * (10 ** 18);
        maxEthAmount = .3 ether;
        minEthAmount = .1 ether;
        totalEthCap = 5 ether;
    }
    
    receive() external payable {
        buyTokens();
    }

    function finalizePresale() external onlyOwner {
        if(IERC20(tokenAddress).balanceOf(address(this)) > 0){
            IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
        }
        if(address(this).balance > 0){
            (bool success,) = msg.sender.call{value: address(this).balance}("");
            require(success, "Withdrawal was not successful");
        }
        isInitialized = false;
    }
    
    function buyTokens() payable public {
        require(isInitialized, "Private sale not active");
        if(isWhitelistPresale){
            require(walletWhitelisted[msg.sender], "User is not whitelisted");
        }
        require(msg.value > 0, "Must send ETH to get tokens");
        require(msg.value % minEthAmount == 0, "Must buy in increments of Minimum ETH Amount (0.1)");
        require(msg.value + purchasedAmount[msg.sender] <= maxEthAmount, "Cannot buy more than MaxETH Amount");
        require(msg.value + totalPurchasedAmount <= totalEthCap, "No more tokens available for presale");
        
        purchasedAmount[msg.sender] += msg.value;
        totalPurchasedAmount += msg.value;
        
        uint256 tokenAmount = (msg.value * tokensPerEth) / 1 ether;
        
        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(address(this)) >= tokenAmount, "Not enough tokens on contract to send");
        token.transfer(msg.sender, tokenAmount);
        IBigApeToken(address(tokenAddress)).vestTokens(msg.sender, tokenAmount, 10 days, 0, 0, 2 days);
        emit TokensBought(tokenAmount, msg.value, msg.sender);
    }
    
    function initialize() external onlyOwner {
        require(!isInitialized, "May not initialize contract again");
        // Exclude the pair from fees so that users don't get taxed when selling.
        isInitialized = true;
    }

    function updateMinEthAmount(uint256 newAmt) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        minEthAmount = newAmt;
        require(maxEthAmount >= minEthAmount, "can't set the max lower than the min");
    }
    
    function updateMaxEthAmount(uint256 newAmt) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        maxEthAmount = newAmt;
        require(maxEthAmount >= minEthAmount, "can't set the max lower than the min");
    }
    
    function updateTotalCap(uint256 newCap) external onlyOwner{
        require(!isInitialized, "can't change the rules after presale starts");
        totalEthCap = newCap;
    }
    
    function setWhiteListPresale(bool isWhitelist) external onlyOwner {
        isWhitelistPresale = isWhitelist;
    }
    
    // only use in case of emergency or after presale is over
    function emergencyWithdrawTokens() external onlyOwner {
        IERC20(tokenAddress).transfer(msg.sender, IERC20(tokenAddress).balanceOf(address(this)));
    }
    
    function whitelistWallet(address wallet, bool value) public onlyOwner {
        walletWhitelisted[wallet] = value;
    }
    
    function whitelistWallets(address[] memory wallets) public onlyOwner {
        for(uint256 i = 0; i < wallets.length; i++){
            whitelistWallet(wallets[i], true);
        }
    }
    
    // owner can withdraw ETH after people get tokens
    function withdrawETH() external onlyOwner {
        (bool success,) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdrawal was not successful");
    }
}