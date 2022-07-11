/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
/*


http://www.Drkorpus.com

 _______                   __    __    _  _                                           
/       \                 /  |  /  |  / |/ |                                          
$$$$$$$  |  ______        $$ | /$$/   $/_$/_    ______    ______   __    __   _______ 
$$ |  $$ | /      \       $$ |/$$/   /      \  /      \  /      \ /  |  /  | /       |
$$ |  $$ |/$$$$$$  |      $$  $$<   /$$$$$$  |/$$$$$$  |/$$$$$$  |$$ |  $$ |/$$$$$$$/ 
$$ |  $$ |$$ |  $$/       $$$$$  \  $$ |  $$ |$$ |  $$/ $$ |  $$ |$$ |  $$ |$$      \ 
$$ |__$$ |$$ |            $$ |$$  \ $$ \__$$ |$$ |      $$ |__$$ |$$ \__$$ | $$$$$$  |
$$    $$/ $$ |            $$ | $$  |$$    $$/ $$ |      $$    $$/ $$    $$/ /     $$/ 
$$$$$$$/  $$/             $$/   $$/  $$$$$$/  $$/       $$$$$$$/   $$$$$$/  $$$$$$$/  
                                                        $$ |                          
                                                        $$ |                          
                                                        $$/          

http://www.Drkorpus.com                 

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

interface AntiSnipe {
    function checkUser(address from, address to, uint256 amt) external returns (bool);
    function setLaunch(address _initialLpPair, uint32 _liqAddBlock, uint64 _liqAddStamp, uint8 dec) external;
    function setLpPair(address pair, bool enabled) external;
    function setProtections(bool _as, bool _ab) external;
    function removeSniper(address account) external;
    function removeBlacklisted(address account) external;
    function isBlacklisted(address account) external view returns (bool);
    function transfer(address sender) external;
    function setBlacklistEnabled(address account, bool enabled) external;
    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external;
    function getInitializers() external returns (string memory, string memory, uint256, uint8);

    function fullReset() external;
}

contract FleshOfHumanity is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromProtection;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
   
    uint256 private startingSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _tTotal;

    struct Fees {
        uint16 bracketOne;
        uint16 bracketTwo;
        uint16 bracketThree;
        uint16 bracketFour;
        uint16 bracketFive;
    }

    struct NormalTaxes {
        uint16 buyTaxes;
        uint16 sellTaxes;
        uint16 transferTaxes;
    }

    Fees public _buyTaxes = Fees({
        bracketOne: 1000,
        bracketTwo: 500,
        bracketThree: 0,
        bracketFour: 0,
        bracketFive: 0
    });

    Fees public _sellTaxes = Fees({
        bracketOne: 2200,
        bracketTwo: 2000,
        bracketThree: 1500,
        bracketFour: 1000,
        bracketFive: 500
    });

    NormalTaxes public _normalTaxes = NormalTaxes({
        buyTaxes: 0,
        sellTaxes: 0,
        transferTaxes: 0
    });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant public maxRoundtripTax = 3000;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    
    uint256 private _maxTxAmount;
    uint256 private _maxWalletSize;

    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    bool public piContractSwapsEnabled;
    uint256 public piSwapPercent;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    AntiSnipe antiSnipe;

    bool public tokensLPBurnEnabled = false;
    uint256 public tokensLPBurnPercent = 25;
    uint256 public tokensLPBurnFrequency = 30 minutes;
    uint256 public tokensLPBurnFrequencyManual = 2 hours;
    uint256 public lastTokensBurnStamp;
    uint256 public lastManualBurnStamp;

    bool taxBracketsEnabled = true;

    struct UserValues {
        uint256 firstBuy;
        bool taxLocked;
        uint256 lockedBuyFee;
        uint256 lockedSellFee;
    }

    mapping (address => UserValues) userValues;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller =/= owner.");
        _;
    }

    constructor () payable {
        // Set the owner.
        _owner = msg.sender;

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

    receive() external payable {}

    bool contractInitialized;

    function intializeContract(address p2eWallet, address _antiSnipe) external onlyOwner {
        require(!contractInitialized, "1");
        antiSnipe = AntiSnipe(_antiSnipe);
        try antiSnipe.transfer(address(this)) {} catch {}
        try antiSnipe.getInitializers() returns (string memory initName, string memory initSymbol, uint256 initStartingSupply, uint8 initDecimals) {
            _name = initName;
            _symbol = initSymbol;
            startingSupply = initStartingSupply;
            _decimals = initDecimals;
            _tTotal = startingSupply * 10**_decimals;
        } catch {
            revert("3");
        }
        lpPair = IFactoryV2(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _maxTxAmount = (_tTotal * 1) / 100;
        _maxWalletSize = (_tTotal * 1) / 100;
        contractInitialized = true;     
        _tOwned[_owner] = _tTotal;
        emit Transfer(address(0), _owner, _tTotal);

        _approve(address(this), address(dexRouter), type(uint256).max);
        _approve(_owner, address(dexRouter), type(uint256).max);

        finalizeTransfer(_owner, p2eWallet, (_tTotal * 3) / 10, false, false, true);
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
    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if(balanceOf(_owner) > 0) {
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

    function totalSupply() external view override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external view override returns (uint8) { if (_tTotal == 0) { revert(); } return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
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

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (!enabled) {
            lpPairs[pair] = false;
            antiSnipe.setLpPair(pair, false);
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
            antiSnipe.setLpPair(pair, true);
        }
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

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

//================================================ BLACKLIST

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabled(account, enabled);
    }

    function setBlacklistEnabledMultiple(address[] memory accounts, bool enabled) external onlyOwner {
        antiSnipe.setBlacklistEnabledMultiple(accounts, enabled);
    }


    function isBlacklisted(address account) external view returns (bool) {
        return antiSnipe.isBlacklisted(account);
    }

    function removeSniper(address account) external onlyOwner {
        antiSnipe.removeSniper(account);
    }

    function setProtectionSettings(bool _antiSnipe, bool _antiBlock) external onlyOwner {
        antiSnipe.setProtections(_antiSnipe, _antiBlock);
    }

    function setTaxesBuy(uint16 bracketOne, uint16 bracketTwo) external onlyOwner {
        require(bracketTwo < bracketOne
                && bracketOne <= maxBuyTaxes,
                "Cannot exceed maximum values, and each bracket must be lower than the prior.");
        require(bracketOne + _sellTaxes.bracketOne <= maxRoundtripTax, "Cannot exceed roundtrip maximum.");
        _buyTaxes.bracketOne = bracketOne;
        _buyTaxes.bracketTwo = bracketTwo;
    }

    function setTaxesSell(uint16 bracketOne, uint16 bracketTwo, uint16 bracketThree, uint16 bracketFour, uint16 bracketFive) external onlyOwner {
        require(bracketFive < bracketFour
                && bracketFour < bracketThree
                && bracketThree < bracketTwo
                && bracketTwo < bracketOne
                && bracketOne <= maxSellTaxes,
                "Cannot exceed maximum values, and each bracket must be lower than the prior.");
        require(bracketOne + _buyTaxes.bracketOne <= maxRoundtripTax, "Cannot exceed roundtrip maximum.");
        _sellTaxes.bracketOne = bracketOne;
        _sellTaxes.bracketTwo = bracketTwo;
        _sellTaxes.bracketThree = bracketThree;
        _sellTaxes.bracketFour = bracketFour;
        _sellTaxes.bracketFive = bracketFive;
    }

    function setTaxes(uint16 buyTaxes, uint16 sellTaxes, uint16 transferTaxes) external onlyOwner {
        require(buyTaxes <= maxBuyTaxes
                && sellTaxes <= maxSellTaxes
                && transferTaxes <= maxTransferTaxes,
                "Cannot exceed maximums.");
        require(buyTaxes + sellTaxes <= maxRoundtripTax, "Cannot exceed roundtrip maximum.");
        _normalTaxes.buyTaxes = buyTaxes;
        _normalTaxes.sellTaxes = sellTaxes;
        _normalTaxes.transferTaxes = transferTaxes;
    }


    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }


    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 100), "Max Wallet amt must be above 1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }


    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        require(swapThreshold <= swapAmount, "Threshold cannot be above amount.");
    }

    function setPriceImpactSwapAmount(uint256 priceImpactSwapPercent) external onlyOwner {
        require(priceImpactSwapPercent <= 200, "Cannot set above 2%.");
        piSwapPercent = priceImpactSwapPercent;
    }

    function setContractSwapEnabled(bool swapEnabled, bool priceImpactSwapEnabled) external onlyOwner {
        contractSwapEnabled = swapEnabled;
        piContractSwapsEnabled = priceImpactSwapEnabled;
        emit ContractSwapEnabledUpdated(swapEnabled);
    }

    function getUserTaxValues(address account) external view returns (bool taxesAreLocked, uint256 firstBuyTimestamp, uint256 lockedBuyTax, uint256 lockedSellTax) {
        if (!userValues[account].taxLocked) {
            return(false, userValues[account].firstBuy, 0, 0);
        } else {
            return(true, userValues[account].firstBuy, userValues[account].lockedBuyFee, userValues[account].lockedSellFee);
        }
    }

    function setTokensInLPBurnEnabled(bool enabled) external onlyOwner {
        tokensLPBurnEnabled = enabled;
    }

    function setTokensInLPBurnSettings(uint256 percentInHundreds, uint256 frequencyInSeconds) external onlyOwner {
        require(frequencyInSeconds > 10 minutes, "Cannot exceed 10 minutes.");
        require(percentInHundreds <= 500, "Cannot exceed 5%.");
        tokensLPBurnFrequency = frequencyInSeconds;
        tokensLPBurnPercent = percentInHundreds;
    }

    function manualTokensInLPBurn(uint256 percentInHundreds) external onlyOwner {
        require(lastManualBurnStamp + tokensLPBurnFrequencyManual < block.timestamp, "Must wait for cooldown.");
        require(percentInHundreds <= 300, "Cannot exceed 3% manual burns.");
        lpBurnTransfer((balanceOf(lpPair) * percentInHundreds) / masterTaxDivisor);
        lastManualBurnStamp = block.timestamp;
    }

    function setTaxBracketsEnabled(bool enabled) external onlyOwner {
        taxBracketsEnabled = enabled;
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
            && from != address(antiSnipe)
            && to != address(antiSnipe);
    }

    function lpBurnTransfer(uint256 amount) internal {
        _tOwned[lpPair] -= amount;
        emit Transfer(lpPair, DEAD, amount);
        IV2Pair(lpPair).sync();
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
                revert("Trading not yet enabled!");
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
                if (contractSwapEnabled) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        uint256 swapAmt = swapAmount;
                        if (piContractSwapsEnabled) { swapAmt = (balanceOf(lpPair) * piSwapPercent) / masterTaxDivisor; }
                        if (contractTokenBalance >= swapAmt) { contractTokenBalance = swapAmt; }
                        contractSwap(contractTokenBalance);
                    }
                }
                if (tokensLPBurnEnabled && lastTokensBurnStamp + tokensLPBurnFrequency < block.timestamp) {
                    uint256 balance = balanceOf(lpPair);
                    uint256 burnAmount = (balance * tokensLPBurnPercent) / masterTaxDivisor;
                    lpBurnTransfer(burnAmount);
                    lastTokensBurnStamp = block.timestamp;
                }
            }
        } 
        return finalizeTransfer(from, to, amount, buy, sell, other);
    }

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liquidityHolders[from] = true;
            _isExcludedFromFees[from] = true;
            _hasLiqBeenAdded = true;
            if(address(antiSnipe) == address(0)){
                antiSnipe = AntiSnipe(address(this));
            }
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        if(address(antiSnipe) == address(0)){
            antiSnipe = AntiSnipe(address(this));
        }
        try antiSnipe.setLaunch(lpPair, uint32(block.number), uint64(block.timestamp), _decimals) {} catch {}
        swapThreshold = (balanceOf(lpPair) * 10) / 10000;
        swapAmount = (balanceOf(lpPair) * 30) / 10000;
        tradingEnabled = true;
        tokensLPBurnEnabled = true;
        lastTokensBurnStamp = block.timestamp;
    }

    function sweepContingency() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external onlyOwner {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, true);
        }
    }

    function contractSwap(uint256 contractTokenBalance) internal lockTheSwap {
        if (_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 toLiquify = contractTokenBalance / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: amtBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amtBalance, toLiquify);
        }
    }

    function finalizeTransfer(address from, address to, uint256 amount, bool buy, bool sell, bool other) internal returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to) && !_isExcludedFromProtection[from] && !_isExcludedFromProtection[to] && !other) {
                revert("Pre-liquidity transfer protection.");
            }
        }

        if (_hasLimits(from, to)) {
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

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, to, buy, sell, amount) : amount;
        _tOwned[to] += amountReceived;

        if (!sell) {
            if (userValues[to].firstBuy == 0) {
                userValues[to].firstBuy = block.timestamp;
            }
        }

        emit Transfer(from, to, amountReceived);
        return true;
    }
    
    function takeTaxes(address from, address to, bool buy, bool sell, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (taxBracketsEnabled) {
            if (buy) {
                UserValues memory memVals = userValues[to];
                if (memVals.taxLocked) {
                    currentFee = userValues[to].lockedBuyFee;
                } else if (memVals.firstBuy == 0) {
                    currentFee = 1000;
                } else {
                    uint256 delta = block.timestamp - memVals.firstBuy;
                    if (delta < 30 days) {
                        currentFee = 1000;
                    } else if (delta < 60 days) {
                        currentFee = 500;
                    } else {
                        return amount;
                    }
                }
            } else if (sell) {
                UserValues memory memVals = userValues[from];
                if (memVals.taxLocked) {
                    currentFee = userValues[from].lockedSellFee;
                } else {
                    uint256 delta = block.timestamp - memVals.firstBuy;
                    if (delta < 10 days) {
                        memVals.lockedBuyFee = _buyTaxes.bracketOne;
                        memVals.lockedSellFee = _sellTaxes.bracketOne;
                        memVals.taxLocked = true;
                    } else if (delta < 20 days) {
                        memVals.lockedBuyFee = _buyTaxes.bracketOne;
                        memVals.lockedSellFee = _sellTaxes.bracketTwo;
                        memVals.taxLocked = true;
                    } else if (delta < 30 days) {
                        memVals.lockedBuyFee = _buyTaxes.bracketOne;
                        memVals.lockedSellFee = _sellTaxes.bracketThree;
                        memVals.taxLocked = true;
                    } else if (delta < 40 days) {
                        memVals.lockedBuyFee = _buyTaxes.bracketTwo;
                        memVals.lockedSellFee = _sellTaxes.bracketFour;
                        memVals.taxLocked = true;
                    } else if (delta < 60 days) {
                        memVals.lockedBuyFee = _buyTaxes.bracketTwo;
                        memVals.lockedSellFee = _sellTaxes.bracketFive;
                        memVals.taxLocked = true;
                    } else {
                        memVals.lockedBuyFee = 0;
                        memVals.lockedSellFee = 0;
                        memVals.taxLocked = true;
                    }
                    currentFee = memVals.lockedSellFee;
                    userValues[from] = memVals;
                }
            } else {
                return amount;
            }
        } else {
            if (buy) {
                currentFee = _normalTaxes.buyTaxes;
            } else if (sell) {
                currentFee = _normalTaxes.sellTaxes;
            } else {
                currentFee = _normalTaxes.transferTaxes;
            }
        }

        if (currentFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }
}