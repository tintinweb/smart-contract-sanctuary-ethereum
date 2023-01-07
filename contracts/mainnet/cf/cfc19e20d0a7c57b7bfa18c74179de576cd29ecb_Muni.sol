/**
 *Submitted for verification at Etherscan.io on 2023-01-07
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data; 
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address lpPair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address lpPair);
    function createPair(address tokenA, address tokenB) external returns (address lpPair);
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

library Address {
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

interface IERC20Upgradeable {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
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

contract Muni is Context, IERC20Upgradeable {
    address private _owner; // address of the contract owner.
    mapping (address => uint256) private _rOwned; 
    mapping (address => uint256) private _tOwned; 
    mapping (address => bool) lpPairs;
    uint256 private LiquidityPairCount = 0; 
    mapping (address => mapping (address => uint256)) private _allowed; 
    mapping (address => bool) private _ExcludedFromFee; 
    mapping (address => bool) private _iExcempt;
    mapping(address => bool) private InJail;
    address[] private _excluded;
    mapping (address => bool) private _liqProv;
    uint256 private startSupply; 
    string private _name; 
    string private _symbol; 
    uint256 public _redistro = 0; 
    uint256 public _liq = 0; 
    uint256 public _market = 1000; 
    uint256 public _buydistro = _redistro; 
    uint256 public _buyliq = _liq; 
    uint256 public _buyMarket = _market;
    uint256 public _sellLiq = 0; 
    uint256 public _selldistro = 0; 
    uint256 public _sellMarket = 1000; 
    uint256 public _transferRedistro = 0; 
    uint256 public _transferLiq = 0; 
    uint256 public _transferMarket = 0; 
    uint256 private maxRedistro = 1000; 
    uint256 private maxLiq = 1000; 
    uint256 private maxMarket = 4000; 
    uint256 public _liquidityRatio = 0;
    uint256 public _marketRatio = 1000;
    uint256 private masterTaxDivisor = 10000;
    uint256 private MarketStake = 40;
    uint256 private DevStake = 10;
    uint256 private ValueDivisor = 50;
    uint256 private constant MAX = ~uint256(0);
    uint8 private _decimals;
    uint256 private _decimalsMul;
    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;

    IUniswapV2Router02 public dexRouter; 
    address public lpPair; 
    address public _routerAddress; 
    address public DEAD = 0x000000000000000000000000000000000000dEaD; 
    address public ZERO = 0x0000000000000000000000000000000000000000; 
    address payable private _MuniDev; 
    address payable private _marketWallet; 
    bool inSwapAndLiquify; 
    bool public swapAndLiquifyEnabled = false; 
    uint256 private _maxTxn; 
    uint256 public maxTxnUI; 
    uint256 private _maxWallet;
    uint256 public maxWalletUI; 
    uint256 private swapThreshold;
    uint256 private swapAmount;
    bool KickedOff = false;
    bool public _LiqHasBeenAdded = false;
    uint256 private _liqAddBlock = 0;
    uint256 private _liqAddStamp = 0;
    bool private sameBlockActive = true;
    mapping (address => uint256) private lastTrade;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    
    bool readyLiq = false;
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    constructor () payable {

        _owner = msg.sender;

        if (block.chainid == 56) {
            _routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
        } else if (block.chainid == 97) {
            _routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3 || block.chainid == 5) {
            _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else {
            revert();
        }

        _ExcludedFromFee[owner()] = true;
        _ExcludedFromFee[address(this)] = true;
        _liqProv[owner()] = true;

        _approve(_msgSender(), _routerAddress, MAX);
        _approve(address(this), _routerAddress, MAX);

    }

    receive() external payable {}

    function _ReadyLiq(address payable setMarketWallet, address payable setDev, string memory _tokenname, string memory _tokensymbol) external onlyOwner {
        require(!readyLiq);

        _marketWallet = payable(setMarketWallet);
        _MuniDev = payable(setDev);

        _ExcludedFromFee[_marketWallet] = true;
        _ExcludedFromFee[_MuniDev] = true;

        _name = _tokenname;
        _symbol = _tokensymbol;
        startSupply = 1_000_000_000;
        if (startSupply < 100000000000) {
            _decimals = 18;
            _decimalsMul = _decimals;
        } else {
            _decimals = 9;
            _decimalsMul = _decimals;
        }
        _tTotal = startSupply * (10**_decimalsMul);
        _rTotal = (MAX - (MAX % _tTotal));

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _allowed[address(this)][address(dexRouter)] = type(uint256).max;
        
        _maxTxn = (_tTotal * 1000) / 100000;
        maxTxnUI = (startSupply * 500) / 100000;
        _maxWallet = (_tTotal * 10) / 1000;
        maxWalletUI = (startSupply * 10) / 1000;
        swapThreshold = (_tTotal * 5) / 10000;
        swapAmount = (_tTotal * 5) / 1000;

        approve(_routerAddress, type(uint256).max);

        readyLiq = true;
        _rOwned[owner()] = _rTotal;
        emit Transfer(ZERO, owner(), _tTotal);

        _approve(address(this), address(dexRouter), type(uint256).max);

    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromTax(_owner, false);
        setExcludedFromTax(newOwner, true);
        setExcludedFromRedistro(newOwner, true);
        
        if (_MuniDev == payable(_owner))
            _MuniDev = payable(newOwner);
        
        _allowed[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromTax(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function totalSupply() external view override returns (uint256) { return _tTotal; } 
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _symbol; } 
    function name() external view returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowed[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_iExcempt[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function approveMax(address spender) public returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowed[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowed[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function setNextRouter(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address g_p = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (g_p == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = g_p;
        }
        dexRouter = _newRouter;
        _approve(address(this), newRouter, MAX);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled == false) {
            lpPairs[pair] = false;
        } else {
            if (LiquidityPairCount != 0) {
                require(block.timestamp - LiquidityPairCount > 0, "Cannot set two pairs in one block!");
            }
            lpPairs[pair] = true;
            LiquidityPairCount = block.timestamp;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _iExcempt[account];
    }

    function ExcludedFromFee(address account) public view returns(bool) {
        return _ExcludedFromFee[account];
    }

    function setTaxIn(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxRedistro
                && liquidity <= maxLiq
                && marketing <= maxMarket
                );
        require(reflect + liquidity + marketing <= 4900);
        _buydistro = reflect;
        _buyliq = liquidity;
        _buyMarket = marketing;
    }

    function setTaxOut(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxRedistro
                && liquidity <= maxLiq
                && marketing <= maxMarket
                );
        require(reflect + liquidity + marketing <= 4900);
        _selldistro = reflect;
        _sellLiq = liquidity;
        _sellMarket = marketing;
    }

    function setTaxTransfer(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxRedistro
                && liquidity <= maxLiq
                && marketing <= maxMarket
                );
        require(reflect + liquidity + marketing <= 4900);
        _transferRedistro = reflect;
        _transferLiq = liquidity;
        _transferMarket = marketing;
    }

    function setStakeValues(uint256 ms, uint256 ds, uint256 vd) external onlyOwner {
        MarketStake = ms;
        DevStake = ds;
        ValueDivisor = vd;
    }

    function setTaxDivisionRatio(uint256 liquidity, uint256 marketing) external onlyOwner {
        _liquidityRatio = liquidity;
        _marketRatio = marketing;
    }

    function setMaximumTransaction(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _maxTxn = check;
        maxTxnUI = (startSupply * percent) / divisor;
    }

    function setMaximumWallet(uint256 percentage, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percentage) / divisor; 
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _maxWallet = check;
        maxWalletUI = (startSupply * percentage) / divisor;
    }

    function setRouterSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setNextMarketing(address payable newWallet) external onlyOwner {
        require(_marketWallet != newWallet, "Wallet already set!");
        _marketWallet = payable(newWallet);
    }

    function setNextDeveloper(address payable newWallet) external onlyOwner {
        require(_MuniDev != newWallet, "Wallet already set!");
        _MuniDev = payable(newWallet);
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setExcludedFromTax(address account, bool enabled) public onlyOwner {
        _ExcludedFromFee[account] = enabled;
    }

    function setExcludedFromRedistro(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_iExcempt[account], "Account is already excluded.");
            if(_rOwned[account] > 0) {
                _tOwned[account] = tokenFromReflection(_rOwned[account]);
            }
            _iExcempt[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_iExcempt[account], "Account is already included.");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOwned[account] = 0;
                    _iExcempt[account] = false;
                    _excluded.pop();
                    break;
                }
            }
        }
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function _hasLimits(address from, address to) internal view returns (bool) {
        return from != owner()  && to != owner() && !_liqProv[to] && !_liqProv[from] && to != DEAD && to != address(0) && from != address(this) && !_ExcludedFromFee[to] && !_ExcludedFromFee[from];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections - MUNI");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }
    
    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "Cannot approve from the zero address - MUNI");
        require(spender != address(0), "Cannot approve to the zero address - MUNI");

        _allowed[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "Cannot transfer from the zero address - MUNI");
        require(to != address(0), "Cannot transfer to the zero address - MUNI");
        require(amount > 0, "Transfer amount must be greater than zero - MUNI");
        require(!InJail[from] && !InJail[to] && !InJail[msg.sender]);
        if(_hasLimits(from, to)) {
            if(!KickedOff) {
                revert("Trading not yet enabled! - MUNI");
            }
            if (sameBlockActive) {
                if (lpPairs[from]){
                    require(lastTrade[to] != block.number + 1);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number + 1);
                    lastTrade[from] = block.number;
                }
            }
            require(amount <= _maxTxn, "Transfer exceeds the maxTxAmount.- MUNI");
            if(to != _routerAddress && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWallet, "Transfer exceeds the maxWalletSize.- MUNI");
            }
        }
        bool takeFee = true;
        if(_ExcludedFromFee[from] || _ExcludedFromFee[to]){
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
        return _finalize(from, to, amount, takeFee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {
        if (_liquidityRatio + _marketRatio == 0)
            return;
        uint256 toLiquify = ((contractTokenBalance * _liquidityRatio) / (_liquidityRatio + _marketRatio)) / 2;

        uint256 toSwapForEth = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            toSwapForEth,
            0,
            path,
            address(this),
            block.timestamp
        );


        uint256 liquidityBalance = ((address(this).balance * _liquidityRatio) / (_liquidityRatio + _marketRatio)) / 2;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0, 
                0, 
                _MuniDev,
                block.timestamp
            );
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (contractTokenBalance - toLiquify > 0) {

            uint256 OperationsFee = (address(this).balance);
            uint256 marketFund = OperationsFee/(ValueDivisor)*(MarketStake);
            uint256 devFund = OperationsFee/(ValueDivisor)*(DevStake); _MuniDev.transfer(devFund); 
            _marketWallet.transfer(marketFund);           

        }
    }

    

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_LiqHasBeenAdded, "Liquidity is already added.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _liqProv[from] = true;
            _LiqHasBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function MuniStart() public onlyOwner {
        require(!KickedOff, "Trading is already enabled!");
        setExcludedFromRedistro(address(this), true);
        setExcludedFromRedistro(lpPair, true);

        KickedOff = true;
        swapAndLiquifyEnabled = true;
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tLiquidity;

        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
    }

    function _finalize(address from, address to, uint256 tAmount, bool takeFee) internal returns (bool) {


        if (!_LiqHasBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_LiqHasBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
        }
        
        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOwned[from] = _rOwned[from] - values.rAmount;
        _rOwned[to] = _rOwned[to] + values.rTransferAmount;

        if (_iExcempt[from] && !_iExcempt[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
        } else if (!_iExcempt[from] && _iExcempt[to]) {
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;  
        } else if (_iExcempt[from] && _iExcempt[to]) {
            _tOwned[from] = _tOwned[from] - tAmount;
            _tOwned[to] = _tOwned[to] + values.tTransferAmount;
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _takeReflect(values.rFee, values.tFee);

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            if (lpPairs[to]) {
                _redistro = _selldistro;
                _liq = _sellLiq;
                _market = _sellMarket;
            } else if (lpPairs[from]) {
                _redistro = _buydistro;
                _liq = _buyliq;
                _market = _buyMarket;
            } else {
                _redistro = _transferRedistro;
                _liq = _transferLiq;
                _market = _transferMarket;
            }

            values.tFee = (tAmount * _redistro) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (_liq + _market)) / masterTaxDivisor;
            values.tTransferAmount = tAmount - (values.tFee + values.tLiquidity);

            values.rFee = values.tFee * currentRate;
        } else {
            values.tFee = 0;
            values.tLiquidity = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        values.rTransferAmount = values.rAmount - (values.rFee + (values.tLiquidity * currentRate));
        return values;
    }

    function _getRate() internal view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() internal view returns(uint256, uint256) {
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
    
    function _takeReflect(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function RemoveEthStuckInMuniContract() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) internal {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_iExcempt[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); 
    }

    function UnderInvestigation(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            InJail[accounts[i]] = state;
        }
    }
 
    function Caught(address account, bool state) external onlyOwner{
        InJail[account] = state;
    }

    function SetLowerTaxes() external onlyOwner() {
        _buydistro = 0;
        _buyliq = 0;
        _buyMarket = 1000;
        _selldistro = 0;
        _sellLiq = 0;
        _sellMarket = 1000;
        _transferRedistro = 0;
        _transferLiq = 0;
        _transferMarket = 0;
    }
}