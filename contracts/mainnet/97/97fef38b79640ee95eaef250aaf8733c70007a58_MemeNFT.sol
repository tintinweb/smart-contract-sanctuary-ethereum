/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: UNLICENSED
// ALL RIGHTS RESERVED
// MemeNFT by 5th Web Development reserves all rights on this code. You may NOT copy this contract.

pragma solidity =0.8.15;

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
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
}

interface IUniswapV2Pair {
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
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Ownable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    function transferOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != address(0xdead), "Call renounceOwnership to transfer owner to the zero address.");
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
    }
    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
}

contract MemeNFT is IERC20, Ownable {
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) public lpPairs;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    mapping (address => bool) private _isBot;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 private startingSupply = 10_000_000_000;

    string private _name = "MemeNFT";
    string private _symbol = "MNFT";
    uint256 private _reflectFee = 0;
    uint256 private _liquidityFee = 0;
    uint256 private _councilFee = 0;
    uint256 private _treasuryFee = 0;
    uint256 private _burnFee = 0;
    uint256 public _buyReflectFee = 300;
    uint256 public _buyLiquidityFee = 200;
    uint256 public _buyCouncilFee = 100;
    uint256 public _buyTreasuryFee = 100;
    uint256 public _buyBurnFee = 0;
    uint256 public _sellReflectFee = 300;
    uint256 public _sellLiquidityFee = 200;
    uint256 public _sellCouncilFee = 100;
    uint256 public _sellTreasuryFee = 100;
    uint256 public _sellBurnFee = 0;
    uint256 constant private maxReflectFee = 500;
    uint256 constant private maxLiquidityFee = 500;
    uint256 constant private maxCouncilFee = 500;
    uint256 constant private maxTreasuryFee = 500;
    uint256 constant private maxBurnFee = 500;
    uint256 constant private masterTaxDivisor = 10000;

    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals = 18;
    uint256 private _decimalsMul = _decimals;
    uint256 private _tTotal = startingSupply * 10**_decimalsMul;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter;
    address public lpPair;
    address private _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public constant burnAddress = address(0xdead);
    address public constant ZERO = address(0);
    address payable private _councilWallet = payable(0xF17d535EE94C5E472b277F71DDB9C1ae6F8eAEe8);
    address payable private _treasuryWallet = payable(0x8DA48F43e271CcCac2f157f5723507e78251F4cc);
    
    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = false;
    
    uint256 private buyMaxTxPercent = 3;
    uint256 private buyMaxTxDivisor = 100;
    uint256 private _buyMaxTxAmount = (_tTotal * buyMaxTxPercent) / buyMaxTxDivisor;
    uint256 private _buyPreviousBuyMaxTxAmount = _buyMaxTxAmount;
    uint256 public buyMaxTxAmountUI = (startingSupply * buyMaxTxPercent) / buyMaxTxDivisor;
    uint256 private sellMaxTxPercent = 3;
    uint256 private sellMaxTxDivisor = 100;
    uint256 private _sellMaxTxAmount = (_tTotal * sellMaxTxPercent) / sellMaxTxDivisor;
    uint256 private _sellPreviousMaxTxAmount = _sellMaxTxAmount;
    uint256 public sellMaxTxAmountUI = (startingSupply * sellMaxTxPercent) / sellMaxTxDivisor;

    uint256 private swapThreshold = (_tTotal * 5) / 10000;
    uint256 private swapAmount = (_tTotal * 5) / 1000;

    bool private tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    bool public getTokens = true;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    uint256 private snipeBlockAmt = 0;
    uint256 public botsCaught = 0;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event BotCaught(address botAddress);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor ()  {
        _rOwned[msg.sender] = _rTotal;
        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowances[address(this)][address(dexRouter)] = type(uint256).max;

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[_treasuryWallet] = true;
        _isExcludedFromFee[_councilWallet] = true;
        _isExcludedFromFee[address(this)] = true;
        _liquidityHolders[owner()] = true;

        _approve(msg.sender, _routerAddress, _tTotal);

        emit Transfer(address(0), msg.sender, _tTotal);
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external view override returns (string memory) { return _symbol; }
    function name() external view override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflect(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] - subtractedValue);
        return true;
    }

    function setNewRouter(address newRouter) public onlyOwner {
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
            lpPairs[pair] = true;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function isBot(address account) public view returns (bool) {
        return _isBot[account];
    }

    function setStartingProtections(uint8 _block) external onlyOwner{
        require (snipeBlockAmt == 0 && !_hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function removeBot(address account) external onlyOwner {
        require(_isBot[account], "Account is not a recorded bot.");
        _isBot[account] = false;
    }

    function setTaxesBuy(uint256 liquidityFee, uint256 reflectionFee, uint256 councilFee, uint256 treasuryFee, uint256 burnFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectFee
                && councilFee <= maxCouncilFee
                && treasuryFee <= maxTreasuryFee
                && burnFee <= maxBurnFee);
        require(liquidityFee + reflectionFee + councilFee + treasuryFee + burnFee <= 5000);
        _buyLiquidityFee = liquidityFee;
        _buyReflectFee = reflectionFee;
        _buyCouncilFee = councilFee;
        _buyTreasuryFee = treasuryFee;
        _buyBurnFee = burnFee;
    }

    function setTaxesSell(uint256 liquidityFee, uint256 reflectionFee, uint256 councilFee, uint256 treasuryFee, uint256 burnFee) external onlyOwner {
        require(liquidityFee <= maxLiquidityFee
                && reflectionFee <= maxReflectFee
                && councilFee <= maxCouncilFee
                && treasuryFee <= maxTreasuryFee
                && burnFee <= maxBurnFee);
        require(liquidityFee + reflectionFee + councilFee + treasuryFee + burnFee <= 5000);
        _sellLiquidityFee = liquidityFee;
        _sellReflectFee = reflectionFee;
        _sellCouncilFee = councilFee;
        _sellTreasuryFee = treasuryFee;
        _sellBurnFee = burnFee;
    }

    function setMaxTxPercents(uint256 buyPercent, uint256 buyDivisor, uint256 sellPercent, uint256 sellDivisor) public onlyOwner {
        _buyMaxTxAmount = (_tTotal * buyPercent) / buyDivisor;
        buyMaxTxAmountUI = (startingSupply * buyPercent) / buyDivisor;
        _sellMaxTxAmount = (_tTotal * sellPercent) / sellDivisor;
        sellMaxTxAmountUI = (startingSupply * sellPercent) / sellDivisor;
        require(_sellMaxTxAmount >= (_tTotal / 1000) 
                && _buyMaxTxAmount >= (_tTotal / 1000), 
                "Max Transaction amts must be above 0.1% of total supply."
                );
    }


    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setgetTokens(bool onoff) external onlyOwner {
        getTokens = onoff;
    }

    function setWallets(address payable newCouncilWallet, address payable newTreasuryWallet) external onlyOwner {
        _councilWallet = payable(newCouncilWallet);
        _treasuryWallet = payable(newTreasuryWallet);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _isExcludedFromFee[account] = enabled;
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_isExcluded[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflect(_rOwned[account]);
            }
            _isExcluded[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_isExcluded[account], "Account is already included.");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _isExcluded[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && to != burnAddress
            && to != address(0)
            && from != address(this);
    }

    function tokenFromReflect(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }
    
    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function adjustTaxes(address from, address to) internal {
        if (lpPairs[from]) {
            _reflectFee = _buyReflectFee;
            _liquidityFee = _buyLiquidityFee;
            _councilFee = _buyCouncilFee;
            _treasuryFee = _buyTreasuryFee;
            _burnFee = _buyBurnFee;
        } else if (lpPairs[to]) {
            _reflectFee = _sellReflectFee;
            _liquidityFee = _sellLiquidityFee;
            _councilFee = _sellCouncilFee;
            _treasuryFee = _sellTreasuryFee;
            _burnFee = _sellBurnFee;
        } else {
            _reflectFee = 0;
            _liquidityFee = 0;
            _councilFee = 0;
            _treasuryFee = 0;
            _burnFee = 0;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }
            if(lpPairs[to]) {
                require(amount <= _sellMaxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            } else {
                require(amount <= _buyMaxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
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
        uint256 totalFee = _sellLiquidityFee + _sellCouncilFee + _sellTreasuryFee;
        if (totalFee == 0)
            return;
        uint256 toLiquify = (contractTokenBalance * _sellLiquidityFee) / (totalFee);
        uint256 toCouncil = ((contractTokenBalance * _sellCouncilFee) / (totalFee)) / 2;
        uint256 toTreasury = ((contractTokenBalance * _sellTreasuryFee) / (totalFee)) / 2;
        if(!getTokens){
            toCouncil = 0;
            toTreasury = 0;
        }
        uint256 ethOut = contractTokenBalance - toLiquify - toCouncil - toTreasury;
        uint256 half = toLiquify / 2;
        uint256 otherHalf = toLiquify - half;
        uint256 initialBalance = address(this).balance;
        uint256 toSwapForEth = half + ethOut;
        swapTokensForEth(toSwapForEth);

        uint256 fromSwap = address(this).balance - initialBalance;
        uint256 liquidityBalance = (fromSwap * half) / toSwapForEth;

        if (toLiquify > 0) {
            addLiquidity(otherHalf, liquidityBalance);
            emit SwapAndLiquify(half, liquidityBalance, otherHalf);
        }
        if (toCouncil > 0) {
            _transfer(address(this), _councilWallet, toTreasury);
        }
        if (toTreasury > 0) {
            _transfer(address(this), _treasuryWallet, toTreasury);
        }
        if (ethOut > 0) {
            transferETHOut(fromSwap - liquidityBalance);
        }
    }

    function transferETHOut(uint256 amt) internal {
        uint256 toCouncil = (amt * _sellCouncilFee) / (_sellCouncilFee + _sellTreasuryFee);
        uint256 toTreasury = amt - toCouncil;
        bool success;
        if (toCouncil > 0) {
            (success,) = address(_councilWallet).call{value: toCouncil}("");
        }
        if (toTreasury > 0) {
            (success,) = address(_treasuryWallet).call{value: toTreasury}("");
        }
    }

    function swapTokensForEth(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(dexRouter), tokenAmount);
        dexRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0, 
            address(this),
            block.timestamp
        );
    }

    function _checkLiquidityAdd(address from, address to) private {
        require(!_hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            if (snipeBlockAmt == 0 || snipeBlockAmt > 5) {
                _liqAddBlock = block.number + 2;
            } else {
                _liqAddBlock = block.number;
            }

            _liquidityHolders[from] = true;
            _hasLiqBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function enableTrading() external onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(owner(), true);
        setExcludedFromReward(burnAddress, true);
        setExcludedFromReward(lpPair, true);
        setExcludedFromReward(_councilWallet, true);
        setExcludedFromReward(_treasuryWallet, true);
        _liqAddBlock = block.number;
        tradingEnabled = true;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;
        uint256 tBurn;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }

    function _finalizeTransfer(address from, address to, uint256 tAmount, bool takeFee) private returns (bool) {
            if (!_hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPairs[from] 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isBot[to] = true;
                        botsCaught ++;
                        emit BotCaught(to);
                    }
                }
            }
        
        adjustTaxes(from, to);
        ExtraValues memory values = _getValues(tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_isExcluded[from] && !_isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }
        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.tBurn > 0)
            _takeBurn(from, values.tBurn);
        if (values.rFee > 0 || values.tFee > 0)
            _takeReflect(values.rFee, values.tFee);

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function getETHFee() internal view returns (uint256) {
        return _liquidityFee + _councilFee;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            values.tFee = (tAmount * _reflectFee) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (getETHFee())) / masterTaxDivisor;
            values.tBurn = (tAmount * _burnFee) / masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity + values.tBurn);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tBurn = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }
        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate) + (values.tBurn * currentRate));
        return values;
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeReflect(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity);
    }

    function _takeBurn(address sender, uint256 tBurn) private {
        uint256 currentRate =  _getRate();
        uint256 rBurn = tBurn * currentRate;
        _rOwned[burnAddress] = _rOwned[burnAddress] + rBurn;
        if(_isExcluded[burnAddress])
            _tOwned[burnAddress] = _tOwned[burnAddress] + tBurn;
        emit Transfer(sender, burnAddress, tBurn);
    }

    function sweepTokens(address token) external onlyOwner {
        IERC20 toTransfer = IERC20(token);
        toTransfer.transfer(msg.sender, toTransfer.balanceOf(address(this)));
    }

    function sweepETH() external onlyOwner{
        uint256 bal = address(this).balance;
        bool success;
        (success,) = address(msg.sender).call{value: bal}("");
    }
}