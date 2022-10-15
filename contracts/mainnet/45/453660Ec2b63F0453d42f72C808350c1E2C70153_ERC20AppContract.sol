/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.16;

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

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
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
    function factory() external view returns (address);
}

interface IUniswapV2Router01 {
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract ERC20AppContract is Context, IERC20 {
    // Ownership moved to in-contract for customizability.
    address public _owner;

    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) public isExcludedFromMaxWalletRestrictions;
    mapping (address => bool) private _isblacklisted;


    bool private sameBlockActive = false;
    mapping (address => uint256) private lastTrade;   

    bool private isInitialized = false;
    
    mapping (address => uint256) firstBuy;
    
    uint256 private startingSupply;

    string private _name;
    string private _symbol;
//==========================
    // FEES
    struct taxes {
    uint buyFee;
    uint sellFee;
    uint transferFee;
    }

    taxes public Fees = taxes(
    {buyFee: 1000, sellFee: 3000, transferFee: 100});
//==========================
    // Max Limits

    struct MaxLimits {
    uint maxBuy;
    uint maxSell;
    uint maxTransfer;
    }

    MaxLimits public maxFees = MaxLimits(
    {maxBuy: 5000, maxSell: 5000, maxTransfer: 5000});
//==========================    
    //Proportions of Taxes
    struct feeProportions {
    uint liquidity;
    uint developer;
    }

    feeProportions public Ratios = feeProportions(
    { liquidity: 30, developer: 70});

    uint256 private constant masterTaxDivisor = 10000;
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals;
 
    uint256 private _tTotal = startingSupply * 10**_decimals;
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;


    address constant private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD; // Receives tokens, deflates supply, increases price floor.
    
    address public _devWallet;
    
    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 private maxTxPercent;
    uint256 private maxTxDivisor;
    uint256 private _maxTxAmount;
    
    uint256 private maxWalletPercent;
    uint256 private maxWalletDivisor;
    uint256 private _maxWalletSize;

    uint256 private swapThreshold;
    uint256 private swapAmount;

    bool public _hasLiqBeenAdded = false;
    
    uint256 private _liqAddStatus = 0;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private _initialLiquidityAmount = 0; // make constant

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Caller != owner.");
        _;
    }
    
    constructor () {
        _owner = msg.sender;
    }

    receive() external payable {}

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and recnouncements.
    // This allows for removal of ownership privelages from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFees(_owner, false);
        setExcludedFromFees(newOwner, true);
        
        if (_devWallet == payable(_owner))
            _devWallet = payable(newOwner);
        
        _allowances[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
    
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: Zero Address");
        require(spender != address(0), "ERC20: Zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function getFirstBuy(address account) public view returns (uint256) {
        return firstBuy[account];
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transfer(sender, recipient, amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromFees(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    function setNewRouter(address newRouter) public onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 1 weeks, "One week cooldown.");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function setupComplete(uint256 rInitializer) private  {
        require (_liqAddStatus == 0, "Error.");
        _liqAddStatus = rInitializer;
    }


    function finalSetup(string memory initName, string memory initSymbol, uint256 initSupply, address devWallet) external onlyOwner payable {
        require(!isInitialized, "Contract already initialized.");
        require(_liqAddStatus == 0);
        
        _name = initName;
        _symbol = initSymbol;

        startingSupply = initSupply;
        _decimals = 18;
        _tTotal = startingSupply * 10**_decimals;

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        _devWallet = address(devWallet);

        maxTxPercent = 99; // Max Transaction Amount: 100 = 1%
        maxTxDivisor = 10000;
        _maxTxAmount = (_tTotal * maxTxPercent) / maxTxDivisor;
        
        maxWalletPercent = 101; //Max Wallet 100: 1%
        maxWalletDivisor = 10000;
        _maxWalletSize = (_tTotal * maxWalletPercent) / maxWalletDivisor;
        
        swapThreshold = (_tTotal * 5) / 10_000;
        swapAmount = (_tTotal * 5) / 1_000;

        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[owner()] = true;


        approve(_routerAddress, type(uint256).max);
        approve(owner(), type(uint256).max);


        isInitialized = true;
        _tOwned[owner()] = _tTotal;
        _approve(owner(), _routerAddress, _tTotal);
        emit Transfer(address(0), owner(), _tTotal);
 
        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

    
        _transfer(_owner, address(this), balanceOf(_owner));

        dexRouter.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
        setupComplete(1);
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }


    function excludeFromWalletRestrictions(address excludedAddress) public onlyOwner{
        isExcludedFromMaxWalletRestrictions[excludedAddress] = true;
    }

    function revokeExcludedFromWalletRestrictions(address excludedAddress) public onlyOwner{
        isExcludedFromMaxWalletRestrictions[excludedAddress] = false;
    }
    

    function setRatios(uint _liquidity, uint _developer) external onlyOwner {
        require ( (_liquidity+_developer) == 1100, "limit taxes");
        Ratios.liquidity = _liquidity;
        Ratios.developer = _developer;
        }


    function setFees(uint _buyFee, uint _sellFee, uint _transferFee) external onlyOwner {
        require(_buyFee <= maxFees.maxBuy
                && _sellFee <= maxFees.maxSell
                && _transferFee <= maxFees.maxTransfer,
                "Cannot exceed maximums.");
         Fees.buyFee = _buyFee;
         Fees.sellFee = _sellFee;
         Fees.transferFee = _transferFee;

    }

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;
    }

    function setMaxTxPercent(uint percent, uint divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 300), "Must be above 0.33~% of total supply.");
        _maxTxAmount = check;
    }

    function setMaxWalletSize(uint percent, uint divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 300), "Must be above 0.33~% of total supply.");
        _maxWalletSize = check;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setWallets(address payable developerWallet) external onlyOwner {
        _devWallet = payable(developerWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
     
    function updateBots(address[] memory blacklisted_, bool status_) public onlyOwner {
        for (uint i = 0; i < blacklisted_.length; i++) {
            if (!lpPairs[blacklisted_[i]] && blacklisted_[i] != address(_routerAddress)) {
                _isblacklisted[blacklisted_[i]] = status_;
            }
        }
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != DEAD
            && to != address(0)
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: Zero address.");
        require(to != address(0), "ERC20: Zero address.");
        require(amount > 0, "Must >0.");
        require(!_isblacklisted[to] && !_isblacklisted[from],"unable to trade");
        if(_hasLimits(from, to)) {
            if (sameBlockActive) {
                if (lpPairs[from]){
                    require(lastTrade[to] != block.number);
                    lastTrade[to] = block.number;
                    } 
                else {
                    require(lastTrade[from] != block.number);
                    lastTrade[from] = block.number;
                    }
            }
            if(!(isExcludedFromMaxWalletRestrictions[from] || isExcludedFromMaxWalletRestrictions[to])) {
                if(lpPairs[from] || lpPairs[to]){
                require(amount <= _maxTxAmount, "Exceeds the maxTxAmount.");
                }
                if(to != _routerAddress && !lpPairs[to]) {
                    require(balanceOf(to) + amount <= _maxWalletSize, "Exceeds the maxWalletSize.");
                }

            }
            
        }

        if (_tOwned[to] == 0) {
            firstBuy[to] = block.timestamp;
        }

        bool takeFee = true;
        if(_isExcludedFromFees[from] || _isExcludedFromFees[to]){
            takeFee = false;
        }

        if (lpPairs[to]) {
            if (!inSwapAndLiquify
                && swapAndLiquifyEnabled
            ) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if (contractTokenBalance >= swapThreshold) {
                    if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                    swapAndLiquify(contractTokenBalance);
                }
            }      
        } 
        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        if (Ratios.liquidity + Ratios.developer == 0)
            return;
        uint256 toLiquify = ((contractTokenBalance * Ratios.liquidity) / (Ratios.liquidity + Ratios.developer) ) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;
        swapTokensForEth(toSwapForEth);

        uint256 currentBalance = address(this).balance;
        uint256 liquidityBalance = ((currentBalance * Ratios.liquidity) / (Ratios.liquidity + Ratios.developer) ) / 2;

        if (toLiquify > 0) {
            addLiquidity(toLiquify, liquidityBalance);
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (address(this).balance > 0) {
            bool success = true;
            (success,) = address(_devWallet).call{value: address(this).balance}("");
        }
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
                _liqAddBlock = block.number;

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) private returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer at this time.");
            }
        } 
        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? pullFees(from, to, amount) : amount; //A
        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function pullFees(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;

        if (to == lpPair) {
            currentFee=Fees.sellFee;
            } 

        else if (from == lpPair) {currentFee = Fees.buyFee;} 

        else {currentFee = Fees.transferFee;}

        if (_hasLimits(from, to)){
            if (_liqAddStatus == 0 || _liqAddStatus != (1)) {
                revert();
            }
        }
        uint256 feeAmount = (amount * currentFee / masterTaxDivisor);
        _tOwned[address(this)] += (feeAmount);
        emit Transfer(from, address(this), feeAmount);
        return amount - feeAmount;
    }
}