/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/*


EverestCoin is a Play to Earn Game. Join us and let’s climb Mount Everest together!

First 200 buyers get Bored Yeti NFT + 20M EVCoin ETH tokens 

First 1000 buyers get 2M EVCoin ETH tokens:

    Telegram: t.me/TheEverestCoin
    Twitter: Twitter.com/CoinEverest
    Website: everestcoin.io
    Bridge: bridge.everestcoin.io


*/


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
    function removeBlacklisted(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function setBlacklistEnabled(address account, bool enabled) external;
    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external;

    function fullReset() external;
}

contract LotteryArray {
    address[] private lotteryList;
    mapping (address => bool) private inLottery;
    address private token;
    uint256 lotteryEndStamp;

    modifier onlyToken() {
        require (msg.sender == token, "Caller must be token.");
        _;
    }

    constructor(uint256 _lotteryEndStamp, address _token) {
        lotteryEndStamp = _lotteryEndStamp;
        token = _token;
    }

    function checkUser(address account, bool balance) external view onlyToken returns (string memory) {
        return (inLottery[account] && balance) ? "User is in the lottery!" : "User is not in the lottery.";
    }

    function checkUserAtIndex(uint256 index) external view onlyToken returns (address) {
       return lotteryList[index - 1];
    }

    function addUserToLottery(address account) external onlyToken {
        if (block.timestamp < lotteryEndStamp) {
            lotteryList.push(account);
            inLottery[account] = true;
        }
    }

    function finishAndCloseLottery(address payable owner) external onlyToken {
        require (block.timestamp >= lotteryEndStamp, "Lottery must be over.");
        selfdestruct(owner);
    }

    function getLotteryUserLength() public view returns (uint256) {
        return uint256(lotteryList.length);
    }

    function getRemainingLotteryTime() public view returns (uint256) {
        return (lotteryEndStamp > block.timestamp) ? (lotteryEndStamp - block.timestamp) : 0;
    }

}

contract EverestCoin is IERC20 {
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

    mapping (address => bool) private presaleAddresses;
    bool private allowedPresaleExclusion = true;
   
    uint256 constant private startingSupply = 1_000_000_000_000;
    string constant private _name = "EverestCoin";
    string constant private _symbol = "$EVCoin";
    uint8 constant private _decimals = 9;

    uint256 constant private _tTotal = startingSupply * 10**_decimals;
    uint256 constant private MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        uint16 reflection;
        uint16 burn;

        uint16 marketing;
        uint16 liquidity;
        uint16 development;
        uint16 mod;
        uint16 gameAdvancement;
        uint16 technicalSupport;
        uint16 totalSwap;
    }

    Fees public _taxRates = Fees({
        buyFee: 300,
        sellFee: 300,
        transferFee: 300
        });

    Ratios public _ratios = Ratios({
        reflection: 400,
        burn: 200,

        marketing: 600,
        liquidity: 100,
        development: 200,
        mod: 200,
        gameAdvancement: 200,
        technicalSupport: 100,
        totalSwap: 1400
        });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address payable marketing;
        address payable development;
        address payable mod;
        address payable gameAdvancement;
        address payable technicalSupport;
    }

    TaxWallets public _taxWallets = TaxWallets({
        marketing: payable(0xD60b49CeA6e10D9e54DC1F90C7bc55bA55904097),
        development: payable(0xE4712e1d5d2B2594cB9887B5f07b17527F19D533),
        mod: payable(0x734336CC4c0a16Ac7c2Ea206e3DB65AF6B5803C1),
        gameAdvancement: payable(0x5b31FaF42470D84B20659354A4bE7cC603C6e640),
        technicalSupport: payable(0xBaAFeeb00d5B02F24243540bdB12DaE2C097fFEB)
        });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    
    uint256 private _maxTxAmount = (_tTotal * 2) / 100;
    uint256 private _maxWalletSize = (_tTotal * 4) / 100;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    Protections protections;

    LotteryArray lottery;
    bool public lotteryRunning;
    uint256 public minHoldForLotteryUI = 5 * 10**6;
    uint256 private minimumHoldForLottery = minHoldForLotteryUI * 10**_decimals; // 5 Million tokens needed to enter lottery.
    uint256 public minETHBuy = 19*10**16;

    bool public piEnabled = true;

    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    constructor () payable {
        _rOwned[msg.sender] = _rTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0xD99D1c33F9fC3444f8101754aBC46c52416550D1);
        } else if (block.chainid == 1) {
            dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        } else {
            revert();
        }

        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
        _isExcludedFromLimits[_taxWallets.development] = true;
        _isExcludedFromLimits[_taxWallets.gameAdvancement] = true;
    }

    receive() external payable {}

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

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external pure override returns (uint256) { return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
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

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
            protections.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            protections.setLpPair(pair, true);
        }
    }

    function setInitializer(address initializer) external onlyOwner {
        require(!_hasLiqBeenAdded);
        require(initializer != address(this), "Can't be self.");
        protections = Protections(initializer);
    }

    function isExcludedFromLimits(address account) external view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function isExcludedFromFees(address account) external view returns(bool) {
        return _isExcludedFromFees[account];
    }

    function isExcludedFromProtection(address account) external view returns (bool) {
        return _isExcludedFromProtection[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function setExcludedFromProtection(address account, bool enabled) external onlyOwner {
        _isExcludedFromProtection[account] = enabled;
    }
//================================================ BLACKLIST

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        protections.setBlacklistEnabled(account, enabled);
    }

    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external onlyOwner {
        protections.setBlacklistEnabledMultiple(accounts, enabled);
    }

    function isBlacklisted(address account) public view returns (bool) {
        return protections.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        protections.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        protections.setProtections(_antiSnipe, _antiBlock);
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= maxBuyTaxes
                && sellFee <= maxSellTaxes
                && transferFee <= maxTransferTaxes,
                "Cannot exceed maximums.");
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(
            uint16 reflection, 
            uint16 marketing,
            uint16 liquidity,
            uint16 development, 
            uint16 mod, 
            uint16 gameAdvancement, 
            uint16 technicalSupport, 
            uint16 burn
                      ) external onlyOwner {
        _ratios.technicalSupport = technicalSupport;
        _ratios.reflection = reflection;
        _ratios.marketing = marketing;
        _ratios.liquidity = liquidity;
        _ratios.mod = mod;
        _ratios.gameAdvancement = gameAdvancement;
        _ratios.development = development;
        _ratios.burn = burn;
        _ratios.totalSwap = marketing + development + mod + gameAdvancement + technicalSupport + liquidity;
        uint256 total = _taxRates.buyFee + _taxRates.sellFee;
        require(_ratios.totalSwap + _ratios.reflection + _ratios.burn <= total, "Cannot exceed sum of buy and sell fees.");
    }

    function setWallets(address payable marketing, address payable development, address payable mod, address payable gameAdvancement, address payable technicalSupport) external onlyOwner {
        _taxWallets.technicalSupport = technicalSupport;
        _taxWallets.marketing = payable(marketing);
        _taxWallets.mod = payable(mod);
        _taxWallets.gameAdvancement = payable(gameAdvancement);
        _taxWallets.development = payable(development);
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() public view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() public view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
        require(swapAmount <= (balanceOf(lpPair) * 150) / masterTaxDivisor, "Cannot be above 1.5% of current PI.");
        require(swapAmount >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
        require(swapThreshold >= _tTotal / 1_000_000, "Cannot be lower than 0.00001% of total supply.");
    }

    function setContractSwapEnabled(bool swapEnabled) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function excludePresaleAddresses(address router, address presale) external onlyOwner {
        require(allowedPresaleExclusion);
        require(router != address(this) && presale != address(this), "Just don't.");
        if (router == presale) {
            _liquidityHolders[presale] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(presale, true);
            setExcludedFromReward(presale, true);
        } else {
            _liquidityHolders[router] = true;
            _liquidityHolders[presale] = true;
            presaleAddresses[router] = true;
            presaleAddresses[presale] = true;
            setExcludedFromFees(router, true);
            setExcludedFromFees(presale, true);
            setExcludedFromReward(router, true);
            setExcludedFromReward(presale, true);
        }
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
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
        if (_hasLimits(from, to)) {
            if(!tradingEnabled) {
                if (!other) {
                    revert("Trading not yet enabled!");
                } else if (!_isExcludedFromProtection[from] && !_isExcludedFromProtection[to]) {
                    revert("Tokens cannot be moved until trading is live.");
                }
            }
            if (buy || sell){
                if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to]) {
                    require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
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
                if (contractSwapEnabled
                   && !presaleAddresses[to]
                   && !presaleAddresses[from]
                ) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance);
                    }
                }
            }
        }
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function contractSwap(uint256 contractTokenBalance) internal lockTheSwap {
        Ratios memory ratios = _ratios;
        if (ratios.totalSwap == 0) {
            return;
        }

        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
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
        uint256 modBalance = (amtBalance * ratios.mod) / ratios.totalSwap;
        uint256 developmentBalance = (amtBalance * ratios.development) / ratios.totalSwap;
        uint256 gameAdvancementBalance = (amtBalance * ratios.gameAdvancement) / ratios.totalSwap;
        uint256 technicalSupportBalance = (amtBalance * ratios.technicalSupport) / ratios.totalSwap;
        uint256 marketingBalance = amtBalance - (modBalance + developmentBalance + technicalSupportBalance + gameAdvancementBalance);
        bool success;
        if (ratios.marketing > 0) {
            sendValue(_taxWallets.marketing, marketingBalance);
        }
        if (ratios.mod > 0) {
            sendValue(_taxWallets.mod, modBalance);
        }
        if (ratios.development > 0) {
            sendValue(_taxWallets.development, developmentBalance);
        }
        if (ratios.gameAdvancement > 0) {
            sendValue(_taxWallets.gameAdvancement, gameAdvancementBalance);
        }
        if (ratios.technicalSupport > 0) {
            sendValue(_taxWallets.technicalSupport, technicalSupportBalance);
        }
    }

    function sendValue(address payable account, uint256 amount) internal {
        bool success;
        (success,) = account.call{value: amount, gas: 35000}("");
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            if(address(protections) == address(0)){
                protections = Protections(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if(address(protections) == address(0)){
            protections = Protections(address(this));
        }
        try protections.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        tradingEnabled = true;
        allowedPresaleExclusion = false;
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 25) / 10000;
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, true);
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _isExcluded[account] = true;
            if(account != lpPair){
                _excluded.push(account);
            }
        } else if (!enabled) {
            require(_isExcluded[account], "Account is already included.");
            if (account == lpPair) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
            } else if(_excluded.length == 1) {
                _rOwned[account] = _tOwned[account] * _getRate();
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
            } else {
                for (uint256 i = 0; i < _excluded.length; i++) {
                    if (_excluded[i] == account) {
                        _excluded[i] = _excluded[_excluded.length - 1];
                        _tOwned[account] = 0;
                        _rOwned[account] = _tOwned[account] * _getRate();
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

        if (lotteryRunning) {
            if (buy) {
                if (balanceOf(to) > minimumHoldForLottery && !_isExcludedFromFees[to]) {
                    address[] memory path = new address[](2);
                    path[0] = address(this);
                    path[1] = dexRouter.WETH();
                    uint256 ethBalance = dexRouter.getAmountsOut(tAmount, path)[1];
                    if (ethBalance >= minETHBuy) {
                        lottery.addUserToLottery(to);
                    }
                }
            }
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

    uint256 public _currentFee;
    uint256 public _bonus;

    function takeTaxes(address from, address to, uint256 tAmount, bool takeFee, bool buy, bool sell, bool other) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        Ratios memory ratios = _ratios;
        values.currentRate = _getRate();

        values.rAmount = tAmount * values.currentRate;

        if (_hasLimits(from, to)) {
            bool checked;
            try protections.checkUser(from, to, tAmount) returns (bool check) {
                checked = check;
            } catch {
                revert();
            }

            if(!checked) {
                revert();
            }
        }

        if(takeFee) {
            uint256 currentFee;

            if (buy) {
                currentFee = _taxRates.buyFee;
            } else if (sell) {
                currentFee = _taxRates.sellFee;
                if (piEnabled) {
                    uint256 balance = balanceOf(lpPair);
                    if (tAmount > balance / 100) {
                        _bonus = (tAmount * (10**4)) / balance;
                        currentFee += (tAmount * (10**4)) / balance;
                        if (currentFee > 3000) {
                            currentFee = 3000;
                        }
                        _currentFee = currentFee;
                    }
                }
            } else {
                currentFee = _taxRates.transferFee;
            }

            uint256 feeAmount = (tAmount * currentFee) / masterTaxDivisor;
            uint256 total = ratios.totalSwap + ratios.reflection + ratios.burn;
            values.tFee = (feeAmount * ratios.reflection) / total;
            values.tBurn = (feeAmount * ratios.burn) / total;
            values.tSwap = feeAmount - (values.tFee + values.tBurn);
            values.tTransferAmount = tAmount - (values.tFee + values.tSwap + values.tBurn);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tBurn = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            if(_isExcluded[address(this)]) {
                _tOwned[address(this)] += values.tSwap;
            }
            emit Transfer(from, address(this), values.tSwap);
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] += values.tBurn * values.currentRate;
            if(_isExcluded[DEAD]) {
                _tOwned[DEAD] += values.tBurn;
            }
            emit Transfer(from, DEAD, values.tBurn);
        }

        values.rTransferAmount = values.rAmount - (values.rFee + (values.tSwap * values.currentRate) + (values.tBurn * values.currentRate));
        return values;
    }

    function _getRate() internal view returns(uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if(_isExcluded[lpPair]) {
            if (_rOwned[lpPair] > rSupply || _tOwned[lpPair] > tSupply) return _rTotal / _tTotal;
            rSupply -= _rOwned[lpPair];
            tSupply -= _tOwned[lpPair];
        }
        if(_excluded.length > 0) {
            for (uint8 i = 0; i < _excluded.length; i++) {
                if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return _rTotal / _tTotal;
                rSupply = rSupply - _rOwned[_excluded[i]];
                tSupply = tSupply - _tOwned[_excluded[i]];
            }
        }
        if (rSupply < _rTotal / _tTotal) return _rTotal / _tTotal;
        return rSupply / tSupply;
    }

//============================Lottery====================================
    function startNewLottery(uint256 endTime) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        require(endTime > block.timestamp, "Cannot end in the past.");
        lottery = new LotteryArray(endTime, address(this));
        lotteryRunning = true;
    }

    function isUserInLottery(address account) public view returns (string memory) {
        require(lotteryRunning, "Lottery offline!");
        bool userBalance = (balanceOf(account) >= minimumHoldForLottery);
        return lottery.checkUser(account, userBalance);
    }

    function getLotteryUserLength() external view returns (uint256) {
        require(lotteryRunning, "Lottery offline!");
        return lottery.getLotteryUserLength();
    }

    function finishAndCloseLottery() external onlyOwner {
        require(lotteryRunning, "Lottery offline!");
        lottery.finishAndCloseLottery(payable(_owner));
        lotteryRunning = false;
    }

    function setMinimumHoldForLottery(uint256 minHoldPercent, uint256 divisor) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        minimumHoldForLottery = (_tTotal * minHoldPercent) / divisor;
        minHoldForLotteryUI = (startingSupply * minHoldPercent) / divisor;
    }

    function getRemainingLotteryTime() public view returns (uint256) {
        require(lotteryRunning, "Lottery offline!");
        return lottery.getRemainingLotteryTime();
    }

    function getUserAtIndex(uint256 index) public view returns (address, bool) {
        address account = lottery.checkUserAtIndex(index);
        bool returned;
        if (balanceOf(account) >= minimumHoldForLottery){
            returned = true;
        } else {
            returned = false;
        }
        return (account, returned);
    }

    function setMinETHBuyNeeded(uint256 amount, uint256 divisor) external onlyOwner {
        require(!lotteryRunning, "Lottery must be offline.");
        minETHBuy = amount * 10**divisor;
    }

    function setPriceImpactEnabled(bool enabled) external onlyOwner {
        piEnabled = enabled;
    }
}