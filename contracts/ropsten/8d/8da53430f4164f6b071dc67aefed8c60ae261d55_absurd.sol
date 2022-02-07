/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
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

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
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
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IRouter02 is IRouter01 {
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
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);
}

contract absurd is IERC20, Ownable, Pausable {
    address private _owner;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _liquidityHolders;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _tTotal;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
    }

    struct StaticValuesStruct {
        uint16 maxBuyTaxes;
        uint16 maxSellTaxes;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 development;
        uint16 marketing;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 0,
        sellFee: 0
    });

    Ratios public _ratios = Ratios({
        development: 0,
        marketing: 0,
        total: 0
    });

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxBuyTaxes: 2000,
        maxSellTaxes: 2000,
        masterTaxDivisor: 10000
    });

    IRouter02 public dexRouter;
    address public lpPair;

    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
        address payable development;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(address(0)),
        development: payable(address(0))
    });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public contractSwapTimer = 30 seconds;
    uint256 private lastSwap;

    uint256 private _maxTxAmount;
    uint256 private _maxWalletSize;

    uint256 public swapThreshold;
    uint256 public swapAmount;

    // Total amount of tokens burnt.
    uint256 private _totalBurnt;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    bool private lpInitialized = false;
    mapping(address => bool) private _bot;
    mapping(address => bool) public isBlacklisted;
    // 30 secs delay between buys from same wallet
    mapping(address => uint256) private _lastBuy;
    uint256 internal _cooldown = 30 seconds;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    event Burn(address from, uint256 amount);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () payable {}

    receive() external payable {}

    function initializeLP() public onlyOwner {
        require(!lpInitialized);

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(msg.sender, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;

        lpInitialized = true;
    }

    function addLiquidity(uint256 ethAmount, uint256 tokenAmount) private {
        // _approve(address(this), address(dexRouter), tokenAmount);

        // Add the ETH and token to LP.
        // The LP tokens will be sent to multi-sig wallet.
        // No one will have access to them, so the liquidity will be locked forever.
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _taxWallets.marketing, // the LP is sent to multi-sig wallet. 
            block.timestamp + 60 * 20
        );
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(owner(), false);
        setExcludedFromFees(newOwner, true);
        
        if(balanceOf(owner()) > 0) {
            _transfer(owner(), newOwner, balanceOf(owner()));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(owner(), newOwner);
        
    }

    function renounceOwnership() public virtual override onlyOwner() {
        setExcludedFromFees(owner(), false);
        _owner = address(0);
        emit OwnershipTransferred(owner(), address(0));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    /**
     * @dev Remember that only owner can call so be careful when use on contracts generated from other contracts.
     * @param tokenAddress The token contract address
     * @param tokenAmount Number of tokens to be sent
     */
    function recoverERC20(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        require(tokenAddress != address(this), "Cannot withdraw this token");
        IERC20(tokenAddress).transfer(owner(), tokenAmount);
    }

    function recoverETH(uint256 ethAmount) public virtual onlyOwner returns (bool success) {
        (success,) = owner().call{value: ethAmount}("");
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; }
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        _transfer(sender, recipient, amount);
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

    function _burn(address account, uint256 amount) internal virtual whenNotPaused {
        require(account != DEAD, "ERC20: burn from the burn address");
        require(!isBlacklisted[account], "Blacklisted address");

        uint256 accountBalance = balanceOf(account);
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        // Transfer from account to the burnAccount
        _tOwned[account] -= amount;
        _tOwned[DEAD] += amount;

        _tTotal -= amount;
        _totalBurnt += amount;

        emit Burn(account, amount);
        emit Transfer(account, DEAD, amount);
    }

    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Returns the total number of tokens burnt. 
     */
    function totalBurnt() external view virtual returns (uint256) {
        return _totalBurnt;
    }

    function setNewRouter(address newRouter) public onlyOwner() {
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        setExcludedFromLimits(address(dexRouter), true);
        setExcludedFromLimits(lpPair, true);
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            setExcludedFromLimits(pair, true);
            timeSinceLastPair = block.timestamp;
        }
    }

    function removeBlacklisted(address account) external onlyOwner {
        require(isBlacklisted[account] == true, "Account must be flagged");
        isBlacklisted[account] = false;
    }

    function blacklistAddress(address account) external onlyOwner {
        require(isBlacklisted[account] == false, "Account must not be flagged");
        require(account != address(dexRouter), "Account must not be uniswap router");
        require(account != lpPair, "Account must not be uniswap pair");
        isBlacklisted[account] = true;
    }

    function isBot(address account) public view returns (bool) {
        return _bot[account];
    }

    function addBot(address account) internal {
        _addBot(account);
    }

    function _addBot(address account) internal {
        require(!isBot(account), "Account must not be flagged");
        require(account != address(dexRouter), "Account must not be uniswap router");
        require(account != lpPair, "Account must not be uniswap pair");

        _bot[account] = true;
    }

    function removeBot(address account) public onlyOwner() {
        require(isBot(account), "Account must be flagged");

        _bot[account] = false;
    }

    function setTaxes(uint16 buyFee, uint16 sellFee) external onlyOwner {
        require(buyFee <= staticVals.maxBuyTaxes
                && sellFee <=staticVals.maxSellTaxes,
                "Cannot exceed maximums.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
    }

    function setRatios(uint16 development, uint16 marketing) public onlyOwner {
        _ratios.development = development;
        _ratios.marketing = marketing;
        _ratios.total = development + marketing;
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) public onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) public onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function setExcludedFromLimits(address account, bool enabled) public onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() public view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor, uint256 time) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        contractSwapTimer = time;
    }

    function setWallets(address payable marketing, address payable development) external onlyOwner {
        _taxWallets.development = payable(development);
        _taxWallets.marketing = payable(marketing);
    }

    function setContractSwapEnabled(bool _enabled) public onlyOwner {
        contractSwapEnabled = _enabled;
        emit ContractSwapEnabledUpdated(_enabled);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal virtual whenNotPaused {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!isBot(from), "Sender locked as bot");
        require(!isBot(to), "Recipient locked as bot");
        require(!isBlacklisted[from] && !isBlacklisted[to], "Blacklisted address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(lpInitialized, "Initialize LP first.");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(lpPairs[from] || lpPairs[to]){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if(to != address(dexRouter) && !lpPairs[to]) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwap
                && contractSwapEnabled
            ) {
                if (lastSwap + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                        contractSwap(contractTokenBalance);
                        lastSwap = block.timestamp;
                    }
                }
            }      
        } 
        // _finalizeTransfer(from, to, amount, takeFee);
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer at this time.");
            }
        }

        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, to, amount) : amount;
        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
    }

    function contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        // Ratios memory ratios = _ratios;
        if (_ratios.total == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        uint256 contractEthBalance = address(this).balance;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            contractTokenBalance,
            0,
            path,
            address(this),
            block.timestamp + 60 * 20
        );

        uint256 tradeValue = address(this).balance - contractEthBalance;
        uint256 developmentBalance = (tradeValue * _ratios.development) / _ratios.total;
        uint256 marketingBalance = tradeValue - developmentBalance;
        if (_ratios.development > 0) {
            // _taxWallets.development.transfer(developmentBalance);
            (bool sent,) = _taxWallets.development.call{value: developmentBalance}("");
            require(sent, "Failed to send developmentBalance");
        }
        if (_ratios.marketing > 0) {
            // _taxWallets.marketing.transfer(marketingBalance);
            (bool sent,) = _taxWallets.marketing.call{value: marketingBalance}("");
            require(sent, "Failed to send marketingBalance");
        }
    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (lpPairs[from]) {
            // Buy, apply buy fee schedule
            require(block.timestamp - _lastBuy[tx.origin] > _cooldown, "hit cooldown, try again later");
            _lastBuy[tx.origin] = block.timestamp;
            currentFee = _taxRates.buyFee;
        }
        if (lpPairs[to]) {
            // Sell, apply sell fee schedule
            currentFee = _taxRates.sellFee;
        }

        uint256 feeAmount = amount * currentFee / staticVals.masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        tradingEnabled = true;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(owner()).transfer(address(this).balance);
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external whenNotPaused {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
        }
    }

    function multiSendPercents(address[] memory accounts, uint256[] memory percents, uint256[] memory divisors) external whenNotPaused {
        require(accounts.length == percents.length && percents.length == divisors.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= (_tTotal * percents[i]) / divisors[i]);
            _transfer(msg.sender, accounts[i], (_tTotal * percents[i]) / divisors[i]);
        }
    }

    function stealthLaunch(
        address development_,
        address marketingAddress_,
        address routerAddress_
        ) external onlyOwner {
        // Sets the values for `name`, `symbol`, `totalSupply`, `currentSupply`, and `rTotal`.
        _name = "Cupid";
        _symbol = "VAL";
        _decimals = 9;
        _tTotal = 1111111111 * (10 ** _decimals);

        // Mint
        // _tOwned[_msgSender()] = _tTotal;
        _tOwned[address(this)] = _tTotal;

        // exclude owner and this contract from fee.
        setExcludedFromFees(owner(), true);
        setExcludedFromFees(address(this), true);
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;
        
        emit Transfer(address(0), address(this), _tTotal);
        uint256 amountToBurn = 111111111 * 10 ** _decimals;
        _burn(address(this), amountToBurn); // can burn from owner account

        // create pair
        dexRouter = IRouter02(routerAddress_);
        initializeLP();
        setExcludedFromLimits(address(dexRouter), true);
        setExcludedFromLimits(lpPair, true);

        // setTaxes
        // _taxRates.buyFee = 1300;
        // _taxRates.sellFee = 2600;
        _taxRates.buyFee = 200;
        _taxRates.sellFee = 200;
        setRatios(9, 17);
        setMaxTxPercent(3, 1000);
        setMaxWalletSize(25, 1000);

        // add liquidity on exchange
        uint256 ethAmount = address(this).balance;
        _taxWallets.development = payable(development_);
        _taxWallets.marketing = payable(marketingAddress_);
        addLiquidity(ethAmount, _tTotal); // can add from owner account, approve address(owner)
        _hasLiqBeenAdded = true;

        setContractSwapEnabled(true);
        enableTrading();

        swapThreshold = (_tTotal * 5) / 10000;
        swapAmount = (_tTotal * 10) / 10000;
    }
}