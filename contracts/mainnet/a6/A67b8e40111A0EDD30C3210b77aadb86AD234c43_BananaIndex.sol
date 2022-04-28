/**
 *Submitted for verification at Etherscan.io on 2022-04-27
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

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

interface IFactoryV2 {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function sync() external;
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
    function swapExactETHForTokens(
        uint amountOutMin, 
        address[] calldata path, 
        address to, uint deadline
    ) external payable returns (uint[] memory amounts);
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
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ag, bool _ab, bool _algo) external;
    function setGasPriceLimit(uint256 gas) external;
    function removeSniper(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function transfer(address sender) external;
    function setBlacklistEnabled(address account, bool enabled) external;
    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external;
    function getInitializers() external view returns (string memory, string memory, uint256, uint8);
}

interface Cashier {
    function setRewardsProperties(uint256 _minPeriod, uint256 _minReflection) external;
    function tally(address user, uint256 amount) external;
    function load() external payable;
    function cashout(uint256 gas) external;
    function giveMeWelfarePlease(address hobo) external;
    function getTotalDistributed() external view returns(uint256);
    function getUserInfo(address user) external view returns(string memory, string memory, string memory, string memory);
    function getUserRealizedRewards(address user) external view returns (uint256);
    function getPendingRewards(address user) external view returns (uint256);
    function initialize() external;
}

contract AirDropper {
    address public TOKEN;
    BananaIndex public IF_TOKEN;
    uint256 decimals;
    mapping (address => User) users;
    uint256 totalNeededTokens;

    uint256 public claimDelay = 24 hours;
    bool public delayedClaimEnabled = true;

    struct User {
        uint256 claimableTokens;
        uint256 lastClaimTime;
        uint256 claimDailyLimit;
    }

    constructor (address token, uint256 _decimals) {
        decimals = _decimals;
        TOKEN = token;
        IF_TOKEN = BananaIndex(payable(token));
    }

    modifier onlyToken() {
        require(TOKEN == msg.sender || address(this) == msg.sender, "Ownable: caller is not the token.");
        _;
    }

    function getTotalNeededTokens() public view returns (uint256) {
        return totalNeededTokens;
    }

    function getClaimableTokens(address account) external view returns (uint256) {
        return users[account].claimableTokens;
    }

    function getSecondsUntilNextClaim(address account) external view returns (uint256) {
        uint256 lastClaim = users[account].lastClaimTime;
        if (lastClaim + claimDelay < block.timestamp) {
            return 0;
        } else {
            return ((lastClaim + claimDelay) - block.timestamp);
        }
    }

    function setClaimDelay(uint256 time) external onlyToken {
        require(time <= 24 hours, "Cannot set higher than 24hrs.");
        claimDelay = time;
    }

    function disableDelayedClaim() external onlyToken {
        delayedClaimEnabled = false;
    }

    function setUserToDrop(address account, uint256 tokens) public onlyToken {
        require(users[account].claimableTokens == 0, "User already set.");
        tokens *= (10**decimals);
        users[account].claimableTokens = tokens;
        users[account].lastClaimTime = 0;
        users[account].claimDailyLimit = tokens / 20;
        totalNeededTokens += tokens;
    }

    function multiSet(address[] calldata accounts, uint256[] calldata tokens) external onlyToken {
        for(uint256 i = 0; i < accounts.length; i++){
            setUserToDrop(accounts[i], tokens[i]);
        }
    }

    function withdrawDailyTokens(address account) external {
        uint256 timestamp = block.timestamp;
        User memory user = users[account];
        require(user.claimableTokens > 0, "No tokens available to claim.");
        uint256 amount;
        if (delayedClaimEnabled) {
            require(user.lastClaimTime + claimDelay <= timestamp, "Cannot claim again yet.");
            if (user.claimableTokens > user.claimDailyLimit) {
                amount = user.claimDailyLimit;
            } else {
                amount = users[account].claimableTokens;
            }
            users[account].lastClaimTime = timestamp;
        } else {
            amount = users[account].claimableTokens;
        }
        users[account].claimableTokens -= amount;
        totalNeededTokens -= amount;
        IF_TOKEN._basicTransfer(address(this), account, amount);
    }

    function depositTokens() external  onlyToken{
        address owner = IF_TOKEN.getOwner();
        uint256 needed = getTotalNeededTokens() - IF_TOKEN.balanceOf(address(this));
        IF_TOKEN._basicTransfer(owner, address(this), needed);
    }
}

contract BananaIndex is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isExcludedFromDividends;
    mapping (address => bool) private _liquidityHolders;

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;

    uint256 constant private startingSupply = 1_000_000_000_000;

    string constant private _name = "Banana Index";
    string constant private _symbol = "Bandex";
    uint8 constant private _decimals = 9;

    uint256 constant private _tTotal = startingSupply * (10 ** _decimals);

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 rewards;
        uint16 liquidity;
        uint16 marketing;
        uint16 dev;
        uint16 floorSupport;
        uint16 buybackAndBurn;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 1400,
        sellFee: 1400,
        transferFee: 0
        });

    Ratios public _ratios = Ratios({
        rewards: 200,
        liquidity: 300,
        marketing: 300,
        dev: 200,
        floorSupport: 200,
        buybackAndBurn: 200,
        total: 1400
        });

    uint256 constant public maxBuyTaxes = 1500;
    uint256 constant public maxSellTaxes = 1500;
    uint256 constant public maxTransferTaxes = 1500;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;

    // BTFA MAINNET ADDRESS
    address private BTFA = 0xC631bE100F6Cf9A7012C23De5a6ccb990EAFC133;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant private ZERO = 0x0000000000000000000000000000000000000000;

    struct TaxWallets {
        address payable marketing;
        address payable dev;
        address payable floorSupport;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0x1764041440eD4081Ae361EC9c2245Eb33F023F60),
        dev: payable(0x4C97047ff011c523f7E7f359784659dC05ca0A91),
        floorSupport: payable(0x040C3d1B80630ec46627db3d9077255AA52b7e87)
        });

    uint256 private _maxTxAmount = (_tTotal * 100) / 100;
    uint256 private _maxWalletSize = (_tTotal * 100) / 100;

    Cashier reflector;
    uint256 reflectorGas = 300000;
    AirDropper public airdrop;

    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public processReflect = false;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountBNB, uint256 amount);

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;

        _tOwned[_owner] = _tTotal;
        emit Transfer(ZERO, _owner, _tTotal);
        emit OwnershipTransferred(address(0), _owner);

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
            BTFA = 0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684;
        } else if (block.chainid == 1 || block.chainid == 4) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        airdrop = new AirDropper(address(this), _decimals);

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(_owner, address(airdrop), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _isExcludedFromDividends[_owner] = true;
        _isExcludedFromDividends[lpPair] = true;
        _isExcludedFromDividends[address(this)] = true;
        _isExcludedFromDividends[DEAD] = true;
        _isExcludedFromDividends[ZERO] = true;
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        _isExcludedFromFees[_owner] = false;
        _isExcludedFromDividends[_owner] = false;
        _isExcludedFromFees[newOwner] = true;
        _isExcludedFromDividends[newOwner] = true;
        
        if(balanceOf(_owner) > 0) {
            _finalizeTransfer(_owner, newOwner, balanceOf(_owner), false, false, false, true);
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner {
        _isExcludedFromFees[_owner] = false;
        _isExcludedFromDividends[_owner] = false;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    receive() external payable {}

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() public onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) public onlyOwner {
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
    }

    function setInitializers(address aInitializer, address cInitializer) external onlyOwner {
        require(!tradingEnabled);
        require(cInitializer != address(this) && aInitializer != address(this) && cInitializer != aInitializer);
        reflector = Cashier(cInitializer);
        antiSnipe = AntiSnipe(aInitializer);
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromDividends(address account) external view returns(bool) {
        return _isExcludedFromDividends[account];
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function setDividendExcluded(address holder, bool enabled) public onlyOwner {
        require(holder != address(this) && holder != lpPair);
        _isExcludedFromDividends[holder] = enabled;
        if (enabled) {
            reflector.tally(holder, 0);
        } else {
            reflector.tally(holder, _tOwned[holder]);
        }
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

//================================================ BLACKLIST

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabled(account, enabled);
        setDividendExcluded(account, enabled);
    }

    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabledMultiple(accounts, enabled);
        for(uint256 i = 0; i < accounts.length; i++){
            setDividendExcluded(accounts[i], enabled);
        }
    }

    function isBlacklisted(address account) public view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiGas, bool _antiBlock, bool _algo) external onlyOwner {
        antiSnipe.setProtections(_antiSnipe, _antiGas, _antiBlock, _algo);
    }

    function setGasPriceLimit(uint256 gas) external onlyOwner {
        require(gas >= 150, "Too low.");
        antiSnipe.setGasPriceLimit(gas);
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        try reflector.initialize() {} catch {}
        tradingEnabled = true;
        allowedPresaleExclusion = false;
        swapThreshold = (balanceOf(lpPair) * 5) / 10000;
        swapAmount = (balanceOf(lpPair) * 1) / 1000;
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes);
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 rewards, uint16 liquidity, uint16 marketing, uint16 dev, uint16 floorSupport, uint16 buybackAndBurn) external onlyOwner {
        _ratios.rewards = rewards;
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.dev = dev;
        _ratios.floorSupport = floorSupport;
        _ratios.buybackAndBurn = buybackAndBurn;
        _ratios.total = rewards + liquidity + marketing + dev + floorSupport + buybackAndBurn;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(_ratios.total <= total, "Cannot exceed sum of buy and sell fees.");
    }

    function setWallets(address payable marketing, address payable dev, address payable floorSupport) external onlyOwner {
        _taxWallets.marketing = payable(marketing);
        _taxWallets.dev = payable(dev);
        _taxWallets.floorSupport = payable(floorSupport);
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() public view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setContractSwapSettings(bool _enabled, bool processReflectEnabled) external onlyOwner {
        contractSwapEnabled = _enabled;
        processReflect = processReflectEnabled;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setRewardsProperties(uint256 _minPeriod, uint256 _minReflection, uint256 minReflectionMultiplier) external onlyOwner {
        _minReflection = _minReflection * 10**minReflectionMultiplier;
        reflector.setRewardsProperties(_minPeriod, _minReflection);
    }

    function setReflectorSettings(uint256 gas) external onlyOwner {
        require(gas < 750000);
        reflectorGas = gas;
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion);
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(presale, true);
            setDividendExcluded(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(router, true);
            setExcludedFromFees(presale, true);
            setDividendExcluded(router, true);
            setDividendExcluded(presale, true);
        }
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        bool buy = false;
        bool sell = false;
        bool other = false;
        if (lpPairs[from]) {
            buy = true;
        } else if (lpPairs[to]) {
            sell = true;
        } else {
            other = true;
        }
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(buy || sell){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
                }
            }
            if(to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        bool takeFee = true;
        
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (sell) {
            if (!inSwap
                && contractSwapEnabled
                && !presaleAddresses[to]
                && !presaleAddresses[from]
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    contractSwap(contractTokenBalance);
                }
            }      
        } 

        return _finalizeTransfer(from, to, amount, takeFee, buy, sell, other);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee, bool buy, bool sell, bool other) internal returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        if(_hasLimits(from, to)) {
            bool checked;
            try antiSnipe.checkUser(from, to, amount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        _tOwned[from] -= amount;
        uint256 amountReceived = amount;
        if (takeFee) {
            amountReceived = takeTaxes(from, amount, buy, sell, other);
        }
        _tOwned[to] += amountReceived;

        processRewards(from, to);

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function processRewards(address from, address to) internal {
        if (!_isExcludedFromDividends[from]) {
            try reflector.tally(from, _tOwned[from]) {} catch {}
        }
        if (!_isExcludedFromDividends[to]) {
            try reflector.tally(to, _tOwned[to]) {} catch {}
        }
        if (processReflect) {
            try reflector.cashout(reflectorGas) {} catch {}
        }
    }

    function _basicTransfer(address from, address to, uint256 amount) external returns (bool) {
        require(msg.sender == address(airdrop), "Only airdropper may call.");
        _tOwned[from] -= amount;
        _tOwned[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function takeTaxes(address from, uint256 amount, bool buy, bool sell, bool other) internal returns (uint256) {
        uint256 currentFee;
        if (buy) {
            currentFee = _taxRates.buyFee;
        } else if (sell) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }

        if (currentFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function contractSwap(uint256 contractTokenBalance) internal swapping {
        Ratios memory ratios = _ratios;
        if (ratios.total == 0) {
            return;
        }
        
        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        address _WETH = dexRouter.WETH();

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) / (ratios.total)) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _WETH;

        uint256 initial = address(this).balance;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance - initial;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }

        amtBalance -= liquidityBalance;
        ratios.total -= ratios.liquidity;
        uint256 rewardsBalance = (amtBalance * ratios.rewards) / ratios.total;
        uint256 devBalance = (amtBalance * ratios.dev) / ratios.total;
        uint256 floorSupportBalance = (amtBalance * ratios.floorSupport) / ratios.total;
        uint256 buybackAndBurnBalance = (amtBalance * ratios.buybackAndBurn) / ratios.total;
        uint256 marketingBalance = amtBalance - (rewardsBalance + devBalance + floorSupportBalance + buybackAndBurnBalance);

        if (ratios.rewards > 0) {
            try reflector.load{value: rewardsBalance}() {} catch {}
        }

        if(ratios.marketing > 0){
            _taxWallets.marketing.transfer(marketingBalance);
        }
        if(ratios.dev > 0){
            _taxWallets.dev.transfer(devBalance);
        }
        if(ratios.floorSupport > 0){
            _taxWallets.floorSupport.transfer(floorSupportBalance);
        }
    }

    function buyAndBurnBTFA() external onlyOwner {
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = BTFA;

        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: address(this).balance}
        (
            0,
            path,
            DEAD,
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)) {
                antiSnipe = AntiSnipe(address(this));
            }
            if(address(reflector) ==  address(0)) {
                reflector = Cashier(address(this));
            }
            contractSwapEnabled = true;
            allowedPresaleExclusion = false;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, false, true);
        }
    }

    function manualDeposit() external onlyOwner {
        try reflector.load{value: address(this).balance}() {} catch {}
    }

//=====================================================================================
//            Reflector

    function giveMeWelfarePlease() external {
        reflector.giveMeWelfarePlease(msg.sender);
    }

    function getTotalReflected() external view returns (uint256) {
        return reflector.getTotalDistributed();
    }

    function getUserInfo(address user) external view returns (string memory, string memory, string memory, string memory) {
        return reflector.getUserInfo(user);
    }

    function getUserRealizedGains(address user) external view returns (uint256) {
        return reflector.getUserRealizedRewards(user);
    }

    function getUserUnpaidEarnings(address user) external view returns (uint256) {
        return reflector.getPendingRewards(user);
    }

//=====================================================================================
//            Airdropper

    function ADgetTotalNeededTokens() external view returns (uint256) {
        return airdrop.getTotalNeededTokens();
    }

    function ADgetClaimableTokens(address account) external view returns (uint256) {
        return airdrop.getClaimableTokens(account);
    }

    function ADgetSecondsUntilNextClaim(address account) external view returns (uint256) {
        return airdrop.getSecondsUntilNextClaim(account);
    }

    function ADsetClaimDelay(uint256 time) external onlyOwner {
        airdrop.setClaimDelay(time);
    }

    function ADdisableDelayedClaim() external onlyOwner {
        airdrop.disableDelayedClaim();
    }

    function ADsetUserToDrop(address account, uint256 tokens) external onlyOwner {
        airdrop.setUserToDrop(account, tokens);
    }

    function ADmultiSet(address[] calldata accounts, uint256[] calldata tokens) external onlyOwner {
        airdrop.multiSet(accounts, tokens);
    }

    bool entry;

    function ADwithdrawDailyTokens() external {
        require(entry == false, "Entered.");
        entry = true;
        airdrop.withdrawDailyTokens(msg.sender);
        entry = false;
    }

    function ADdepositTokens() external onlyOwner{
        airdrop.depositTokens();
    }
}