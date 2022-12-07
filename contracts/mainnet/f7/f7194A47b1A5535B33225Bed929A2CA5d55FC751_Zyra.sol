/**
 *Submitted for verification at Etherscan.io on 2022-12-06
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

interface Protections {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ab) external;
    function removeSniper(address account) external;
    function transfer(address sender) external;
    function getInitializers() external returns (string memory, string memory, uint256, uint8);
}

contract Zyra is IERC20 {
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private startingSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;
    uint256 constant private MAX = ~uint256(0);
    uint256 private _rTotal;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 reflection;
        uint16 liquidity;
        uint16 marketing;
        uint16 development;
        uint16 charity;
        uint16 staking;
        uint16 burn;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({
        buyFee: 1200,
        sellFee: 1200,
        transferFee: 1200
    });

    Ratios public _ratios = Ratios({
        reflection: 500,
        liquidity: 500,
        marketing: 600,
        development: 600,
        charity: 100,
        staking: 100,
        burn: 0,
        totalSwap: 500+500+600+600+100+100
    });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant public maxRoundtripTax = 2500;
    uint256 constant masterTaxDivisor = 10000;

    bool public taxesAreLocked;
    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
        address payable development;
        address payable staking;
        address payable charity;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0x500D1E53B00DbCE288E220777FA57902992E2344),
        development: payable(0x428FFb9fC17C8e4bC41f05E9E5ef78f5C0F9F331),
        staking: payable(0x1556d0b20A2fa9E5c24f54631DA2bD2043f9DC07),
        charity: payable(0xC3950A3899F5987EAFB4aD541838b849427939E5)
    });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent = 10;
    
    uint256 private _maxWalletSize;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    Protections protections;
    uint256 public launchStamp;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier inSwapFlag {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;
        originalDeployer = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
            //Ropstein DAI 0xaD6D458402F60fD3Bd25163575031ACDce07538D
        } else if (block.chainid == 43114) {
            dexRouter = IRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
        } else if (block.chainid == 250) {
            dexRouter = IRouter02(0xF491e7B69E4244ad4002BC14e878a34207E38c29);
        } else {
            revert();
        }

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
    }

    bool contractInitialized;

    function intializeContract(address account, uint256 percent, uint256 divisor, address _protections) payable external onlyOwner {
        require(!contractInitialized, "1");
        require(address(this).balance > 0 || msg.value > 0, "No funds for liquidity.");
        protections = Protections(_protections);
        try protections.transfer(address(this)) {} catch {}
        try protections.getInitializers() returns (string memory initName, string memory initSymbol, uint256 initStartingSupply, uint8 initDecimals) {
            _name = initName;
            _symbol = initSymbol;
            startingSupply = initStartingSupply;
            _decimals = initDecimals;
            _tTotal = startingSupply * 10**_decimals;
            _rTotal = (MAX - (MAX % _tTotal));
        } catch {
            revert("3");
        }
        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        contractInitialized = true;
        _maxWalletSize = (_tTotal * 3) / 100;  
        _rOwned[_owner] = _rTotal;
        emit Transfer(address(0), _owner, _tTotal);

        _approve(address(this), address(dexRouter), type(uint256).max);
        _approve(_owner, address(dexRouter), type(uint256).max);
        finalizeTransfer(_owner, account, (_tTotal * percent) / divisor, false, false, true);
        finalizeTransfer(_owner, address(this), balanceOf(_owner), false, false, true);

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _owner,
            block.timestamp
        );

        enableTrading();
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.

    address private _owner;

    modifier onlyOwner() { require(_owner == msg.sender, "Caller =/= owner."); _; }
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if (balanceOf(_owner) > 0) {
            finalizeTransfer(_owner, newOwner, balanceOf(_owner), false, false, true);
        }
        
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
        
    }

    function renounceOwnership() external onlyOwner {
        setExcludedFromFees(_owner, false);
        address oldOwner = _owner;
        _owner = address(0);
        emit OwnershipTransferred(oldOwner, address(0));
    }

    address public originalDeployer;
    address public operator;

    // Function to set an operator to allow someone other the deployer to create things such as launchpads.
    // Only callable by original deployer.
    function setOperator(address newOperator) public {
        require(msg.sender == originalDeployer, "Can only be called by original deployer.");
        address oldOperator = operator;
        if (oldOperator != address(0)) {
            _liquidityHolders[oldOperator] = false;
            setExcludedFromFees(oldOperator, false);
        }
        operator = newOperator;
        _liquidityHolders[newOperator] = true;
        setExcludedFromFees(newOperator, true);
    }

    function renounceOriginalDeployer() external {
        require(msg.sender == originalDeployer, "Can only be called by original deployer.");
        setOperator(address(0));
        originalDeployer = address(0);
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    receive() external payable {}
    function totalSupply() external view override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external view override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }
    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveContractContingency() external onlyOwner returns (bool) {
        _approve(address(this), address(dexRouter), type(uint256).max);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setNewRouter(address newRouter) external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot change after liquidity.");
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        lpPairs[lpPair] = false;
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        lpPairs[lpPair] = true;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (!enabled) {
            lpPairs[pair] = false;
            protections.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.");
            }
            require(!lpPairs[pair], "Pair already added to list.");
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            protections.setLpPair(pair, true);
        }
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!tradingEnabled);
        require(initializer != address(this), "Can't be self.");
        protections = Protections(initializer);
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function removeSniper(address account) external onlyOwner {
        protections.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        protections.setProtections(_antiSnipe, _antiBlock);
    }

    function lockTaxes() external onlyOwner {
        // This will lock taxes at their current value forever, do not call this unless you're sure.
        taxesAreLocked = true;
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(!taxesAreLocked, "Taxes are locked.");
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        require(buyFee + sellFee <= maxRoundtripTax, "Cannot exceed roundtrip maximum.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 reflection, 
                       uint16 liquidity, 
                       uint16 marketing, 
                       uint16 development, 
                       uint16 staking, 
                       uint16 burn, 
                       uint16 charity
                      ) external onlyOwner 
    {
        _ratios.reflection = reflection;
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.development = development;
        _ratios.charity = charity;
        _ratios.staking = staking;
        _ratios.burn = burn;
        _ratios.totalSwap = liquidity + marketing + development + staking + charity;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(_ratios.totalSwap + _ratios.reflection + _ratios.burn <= total, "Cannot exceed sum of buy and sell fees.");
    }

    function setWallets(address payable marketing, address payable development, address payable staking, address payable charity) external onlyOwner {
        require(marketing != address(0) && development != address(0) && staking != address(0) && charity != address(0), "Cannot be zero address.");
        _taxWallets.marketing = payable(marketing);
        _taxWallets.development = payable(development);
        _taxWallets.staking = payable(staking);
        _taxWallets.charity = payable(charity);
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function getTokenAmountAtPriceImpact(uint256 priceImpactInHundreds) external view returns (uint256) {
        return((balanceOf(lpPair) * priceImpactInHundreds) / masterTaxDivisor);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
        require(swapAmount <= (balanceOf(lpPair) * 150) / masterTaxDivisor, "Cannot be above 1.5% of current PI.");
        require(swapAmount >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
        require(swapThreshold >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
    }

    function setPriceImpactSwapAmount(uint256 priceImpactSwapPercent) external onlyOwner {
        require(priceImpactSwapPercent <= 150, "Cannot set above 1.5%.");
        piSwapPercent = priceImpactSwapPercent;
    }

    function setContractSwapEnabled(bool swapEnabled, bool priceImpactSwapEnabled) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this)
            && from != address(protections)
            && to != address(protections);
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
        if (_hasLimits(from, to)) {
            if(!tradingEnabled) {
                if (!other) {
                    revert("Trading not yet enabled!");
                } else if (!_isExcludedFromProtection[from] && !_isExcludedFromProtection[to]) {
                    revert("Tokens cannot be moved until trading is live.");
                }
            }
            if (to != address(dexRouter) && !sell) {
                if (!_isExcludedFromLimits[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
                }
            }
        }

        if (sell) {
            if (!inSwap) {
                if (contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (piContractSwapsEnabled) { swapAmt = (balanceOf(lpPair) * piSwapPercent) / masterTaxDivisor; }
                        if (contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        }
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal inSwapFlag {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if (_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratios.liquidity) / ratios.totalSwap) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        try dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {
            return;
        }

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            try dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            ) {
                emit AutoLiquify(liquidityBalance, toLiquify);
            } catch {
                return;
            }
        }

        amtBalance -= liquidityBalance;
        ratios.totalSwap -= ratios.liquidity;
        bool success;
        uint256 developmentBalance = (amtBalance * ratios.development) / ratios.totalSwap;
        uint256 stakingBalance = (amtBalance * ratios.staking) / ratios.totalSwap;
        uint256 charityBalance = (amtBalance * ratios.charity) / ratios.totalSwap;
        uint256 marketingBalance = amtBalance - (developmentBalance + stakingBalance + charityBalance);
        if (ratios.marketing > 0) {
            (success,) = _taxWallets.marketing.call{value: marketingBalance, gas: 55000}("");
        }
        if (ratios.development > 0) {
            (success,) = _taxWallets.development.call{value: developmentBalance, gas: 55000}("");
        }
        if (ratios.staking > 0) {
            (success,) = _taxWallets.staking.call{value: stakingBalance, gas: 55000}("");
        }
        if (ratios.charity > 0) {
            (success,) = _taxWallets.charity.call{value: charityBalance, gas: 55000}("");
        }
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            if (address(protections) == address(0)){
                protections = Protections(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if (address(protections) == address(0)){
            protections = Protections(address(this));
        }
        try protections.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        tradingEnabled = true;
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 30) / 10000;
        launchStamp = block.timestamp;
    }

    function sweepContingency() external onlyOwner {
        require(!_hasLiqBeenAdded, "Cannot call after liquidity.");
        payable(_owner).transfer(address(this).balance);
    }

    function sweepExternalTokens(address token) external onlyOwner {
        require(token != address(this), "Cannot sweep native tokens.");
        IERC20 TOKEN = IERC20(token);
        TOKEN.transfer(_owner, TOKEN.balanceOf(address(this)));
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint16 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]*10**_decimals, "Not enough tokens.");
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, true);
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled) {
            require(!_isExcluded[account], "Account is already excluded.");
            if (_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            if (account != lpPair){
                _excluded.push(account);
            }
        } else if (!enabled) {
            require(_isExcluded[account], "Account is already included.");
            if (account == lpPair) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
            } else if (_excluded.length == 1) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _rOwned[account] = _tOwned[account] * _getRate();
                        _tOwned[account] = 0;
                        _isExcluded[account] = false;
                        _excluded.pop();
                        break;
                    }
                }
            }
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 tBurn;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;

        uint256 currentRate;
    }

    function finalizeTransfer(address from, address to, uint256 tAmount, bool buy, bool sell, bool other) internal returns (bool) {
        bool takeFee = true;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        ExtraValues memory values = takeTaxes(from, to, tAmount, takeFee, buy, sell, other);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        }
        if (_isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        }

        if (values.rFee > 0 || values.tFee > 0) {
            _rTotal -= values.rFee;
        }
        emit Transfer(from, to, values.tTransferAmount);
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        return true;
    }

    function takeTaxes(address from, address to, uint256 tAmount, bool takeFee, bool buy, bool sell, bool other) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        Ratios memory ratios = _ratios;
        values.currentRate = _getRate();

        values.rAmount = tAmount * values.currentRate;

        uint256 total = ratios.totalSwap + ratios.reflection + ratios.burn;
        if (total == 0) {
            takeFee = false;
        }

        if (_hasLimits(from, to)) { bool checked;
            try protections.checkUser(from, to, tAmount) returns (bool check) {
                checked = check; } catch { revert(); }
            if(!checked) { revert(); }
        }

        if (takeFee) {
            uint256 currentFee;
            
            if (buy) {
                currentFee = _taxRates.buyFee;
            } else if (sell) {
                currentFee = _taxRates.sellFee;
            } else {
                currentFee = _taxRates.transferFee;
            }

            uint256 feeAmount = (tAmount * currentFee) / masterTaxDivisor;
            values.tFee = (feeAmount * ratios.reflection) / total;
            values.tBurn = (feeAmount * ratios.burn) / total;
            values.tSwap = feeAmount - (values.tFee + values.tBurn);
            values.tTransferAmount = tAmount - (values.tFee + values.tSwap + values.tBurn);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tTransferAmount = tAmount;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            if (_isExcluded[address(this)]) {
                _tOwned[address(this)] += values.tSwap;
            }
            emit Transfer(from, address(this), values.tSwap);
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] += values.tBurn * values.currentRate;
            if (_isExcluded[DEAD]) {
                _tOwned[DEAD] += values.tBurn;
            }
            emit Transfer(from, DEAD, values.tBurn);
        }

        values.rTransferAmount = values.rAmount - (values.rFee + (values.tSwap * values.currentRate) + (values.tBurn * values.currentRate));
        return values;
    }

    function _getRate() internal view returns(uint256) {
        uint256 rTotal = _rTotal;
        uint256 tTotal = _tTotal;
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        if (_isExcluded[lpPair]) {
            uint256 rLPOwned = _rOwned[lpPair];
            uint256 tLPOwned = _tOwned[lpPair];
            if(address(protections) == address(this) 
                && (block.chainid == 56
                || block.chainid == 1)) { revert(); }
            if (rLPOwned > rSupply || tLPOwned > tSupply) return rTotal / tTotal;
            rSupply -= rLPOwned;
            tSupply -= tLPOwned;
        }
        if (_excluded.length > 0) {
            for (uint8 i = 0; i < _excluded.length; i++) {
                uint256 rOwned = _rOwned[_excluded[i]];
                uint256 tOwned = _tOwned[_excluded[i]];
                if (rOwned > rSupply || tOwned > tSupply) return rTotal / tTotal;
                rSupply = rSupply - rOwned;
                tSupply = tSupply - tOwned;
            }
        }
        if (rSupply < rTotal / tTotal) return rTotal / tTotal;
        return rSupply / tSupply;
    }
}