/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// 

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data; 
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

contract RessaEthV2 is Context, IERC20Upgradeable {
    address private _owner; // address of the contract owner.
    mapping (address => uint256) private _rOd; 
    mapping (address => uint256) private _tOd; 
    mapping (address => bool) lpPs;
    uint256 private tSLP = 0; 
    mapping (address => mapping (address => uint256)) private _als; 
    mapping (address => uint256) private _BA; 
    mapping (address => bool) private _iEFF; 
    mapping (address => bool) private _iE;
    mapping (address => bool) private _AD; 
    address[] private _excluded;
    mapping (address => bool) private _lH;
    uint256 private sS; 
    string private _nm; 
    string private _s; 
    uint256 public _reF = 100; uint256 public _liF = 300; uint256 public _maF = 400; 
    uint256 public _bReF = _reF; uint256 public _bLiF = _liF; uint256 public _bMaF = _maF;
    uint256 public _sLiF = 300; uint256 public _sReF = 100; uint256 public _sMaF = 400; 
    uint256 public _tReF = 0; uint256 public _tLiF = 0; uint256 public _tMaF = 0; 
    uint256 private maxReF = 1000; uint256 private maxLiF = 1000; uint256 private maxMaF = 2200; 
    uint256 public _liquidityRatio = 200;
    uint256 public _mR = 400;
    uint256 private masterTaxDivisor = 10000;
    uint256 private MaS = 30;
    uint256 private DeS = 10;
    uint256 private VaD = 40;
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
    address payable private _dW; 
    address payable private _marketWallet; 
    bool inSwapAndLiquify; 
    bool public swapAndLiquifyEnabled = false; 
    uint256 private _mTA; 
    uint256 public mTAUI; 
    uint256 private _mWS;
    uint256 public mWSUI; 
    uint256 private swapThreshold;
    uint256 private swapAmount;
    bool go = false;
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
    event SniperCaught(address sniperAddress);
    uint256 Planted;
    
    bool rft = false;
    
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
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
            _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        } else {
            revert();
        }

        _iEFF[owner()] = true;
        _iEFF[address(this)] = true;
        _lH[owner()] = true;

        _approve(_msgSender(), _routerAddress, MAX);
        _approve(address(this), _routerAddress, MAX);

    }

    receive() external payable {}

    function _RFT(address payable setMarketWallet, address payable setDW, string memory _tokenname, string memory _tokensymbol) external onlyOwner {
        require(!rft);

        _marketWallet = payable(setMarketWallet);
        _dW = payable(setDW);

        _iEFF[_marketWallet] = true;
        _iEFF[_dW] = true;

        _nm = _tokenname;
        _s = _tokensymbol;
        sS = 50_000_000_000;
        if (sS < 100000000000) {
            _decimals = 18;
            _decimalsMul = _decimals;
        } else {
            _decimals = 9;
            _decimalsMul = _decimals;
        }
        _tTotal = sS * (10**_decimalsMul);
        _rTotal = (MAX - (MAX % _tTotal));

        dexRouter = IUniswapV2Router02(_routerAddress);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPs[lpPair] = true;
        _als[address(this)][address(dexRouter)] = type(uint256).max;
        
        _mTA = (_tTotal * 1000) / 100000;
        mTAUI = (sS * 500) / 100000;
        _mWS = (_tTotal * 10) / 1000;
        mWSUI = (sS * 10) / 1000;
        swapThreshold = (_tTotal * 5) / 10000;
        swapAmount = (_tTotal * 5) / 1000;

        approve(_routerAddress, type(uint256).max);

        rft = true;
        _rOd[owner()] = _rTotal;
        emit Transfer(ZERO, owner(), _tTotal);

        _approve(address(this), address(dexRouter), type(uint256).max);

    }

    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner() {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        setExcludedFromFee(_owner, false);
        setExcludedFromFee(newOwner, true);
        setExcludedFromReward(newOwner, true);
        
        if (_dW == payable(_owner))
            _dW = payable(newOwner);
        
        _als[_owner][newOwner] = balanceOf(_owner);
        if(balanceOf(_owner) > 0) {
            _t(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner() {
        setExcludedFromFee(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function totalSupply() external view override returns (uint256) { return _tTotal; } 
    function decimals() external view returns (uint8) { return _decimals; }
    function symbol() external view returns (string memory) { return _s; } 
    function name() external view returns (string memory) { return _nm; }
    function getOwner() external view returns (address) { return owner(); }
    function allowance(address holder, address spender) external view override returns (uint256) { return _als[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        if (_iE[account]) return _tOd[account];
        return tokenFromReflection(_rOd[account]);
    }

    function BurnedAmount(address account) public view returns (uint256) {
        return (_BA[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _t(_msgSender(), recipient, amount);
        return true;
    }

    function CommunityBurn( uint256 amount) public returns (bool) {
        uint256 amountFB = amount * (10**_decimalsMul);
        uint256 PreviousBA = _BA[_msgSender()];
        _BA[_msgSender()] = PreviousBA + amount;
        _tB(_msgSender(), amountFB);
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
        _t(sender, recipient, amount);
        _approve(sender, _msgSender(), _als[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _als[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _als[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function setNewRouter(address newRouter) external onlyOwner() {
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
            lpPs[pair] = false;
        } else {
            if (tSLP != 0) {
                require(block.timestamp - tSLP > 1 weeks, "Cannot set a new pair this week!");
            }
            lpPs[pair] = true;
            tSLP = block.timestamp;
        }
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _iE[account];
    }

    function iEFF(address account) public view returns(bool) {
        return _iEFF[account];
    }

    function setTB(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxReF
                && liquidity <= maxLiF
                && marketing <= maxMaF
                );
        require(reflect + liquidity + marketing <= 4900);
        _bReF = reflect;
        _bLiF = liquidity;
        _bMaF = marketing;
    }

    function setTS(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxReF
                && liquidity <= maxLiF
                && marketing <= maxMaF
                );
        require(reflect + liquidity + marketing <= 4900);
        _sReF = reflect;
        _sLiF = liquidity;
        _sMaF = marketing;
    }

    function setTT(uint256 reflect, uint256 liquidity, uint256 marketing) external onlyOwner {
        require(reflect <= maxReF
                && liquidity <= maxLiF
                && marketing <= maxMaF
                );
        require(reflect + liquidity + marketing <= 4900);
        _tReF = reflect;
        _tLiF = liquidity;
        _tMaF = marketing;
    }

    function setValues(uint256 ms, uint256 ds, uint256 vd) external onlyOwner {
        MaS = ms;
        DeS = ds;
        VaD = vd;
    }

    function setRatios(uint256 liquidity, uint256 marketing) external onlyOwner {
        _liquidityRatio = liquidity;
        _mR = marketing;
    }

    function setMTP(uint256 percent, uint256 divisor) external onlyOwner {
        uint256 check = (_tTotal * percent) / divisor;
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _mTA = check;
        mTAUI = (sS * percent) / divisor;
    }

    function setMWS(uint256 p, uint256 d) external onlyOwner {
        uint256 check = (_tTotal * p) / d; 
        require(check >= (_tTotal / 1000), "Must be above 0.1% of total supply.");
        _mWS = check;
        mWSUI = (sS * p) / d;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function setNewMarketWallet(address payable newWallet) external onlyOwner {
        require(_marketWallet != newWallet, "Wallet already set!");
        _marketWallet = payable(newWallet);
    }

    function setNewDW(address payable newWallet) external onlyOwner {
        require(_dW != newWallet, "Wallet already set!");
        _dW = payable(newWallet);
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    function setExcludedFromFee(address account, bool enabled) public onlyOwner {
        _iEFF[account] = enabled;
    }

    function setExcludedFromReward(address account, bool enabled) public onlyOwner {
        if (enabled == true) {
            require(!_iE[account], "Account is already excluded.");
            if(_rOd[account] > 0) {
                _tOd[account] = tokenFromReflection(_rOd[account]);
            }
            _iE[account] = true;
            _excluded.push(account);
        } else if (enabled == false) {
            require(_iE[account], "Account is already included.");
            for (uint256 i = 0; i < _excluded.length; i++) {
                if (_excluded[i] == account) {
                    _excluded[i] = _excluded[_excluded.length - 1];
                    _tOd[account] = 0;
                    _iE[account] = false;
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
        return from != owner()  && to != owner() && !_lH[to] && !_lH[from] && to != DEAD && to != address(0) && from != address(this) && !_iEFF[to] && !_iEFF[from];
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }
    
    function _approve(address sender, address spender, uint256 amount) internal {
        require(sender != address(0), "Cannot approve from the zero address");
        require(spender != address(0), "Cannot approve to the zero address");

        _als[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _t(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "Cannot transfer from the zero address");
        require(to != address(0), "Cannot transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!go) {
                revert("Trading not yet enabled!");
            }
            if (sameBlockActive) {
                if (lpPs[from]){
                    require(lastTrade[to] != block.number + 1);
                    lastTrade[to] = block.number;
                } else {
                    require(lastTrade[from] != block.number + 1);
                    lastTrade[from] = block.number;
                }
            }
            require(amount <= _mTA, "Transfer exceeds the maxTxAmount.");
            if(to != _routerAddress && !lpPs[to]) {
                require(balanceOf(to) + amount <= _mWS, "Transfer exceeds the maxWalletSize.");
            }
        }
        bool takeFee = true;
        if(_iEFF[from] || _iEFF[to]){
            takeFee = false;
        }

        if (lpPs[to]) {
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
        return _ftt(from, to, amount, takeFee);
    }

    function _tB(address from, uint256 amount) internal returns (bool) {
        address to = address(0);
        require(from != address(0), "Cannot transfer from the zero address");
        require(amount > 0, "Burn amount must be greater than zero");
        if(_hasLimits(from, to)) {
            if(!go) {
                revert("Trading not yet enabled!");
            }
        }
        bool takeFee = true;
        if(_iEFF[from] || _iEFF[to]){
            takeFee = false;
        }
 
         _tTotal = _tTotal - (amount);
        return _ftt(from, to, amount, takeFee);

    }

    function swapAndLiquify(uint256 contractTokenBalance) internal lockTheSwap {
        if (_liquidityRatio + _mR == 0)
            return;
        uint256 toLiquify = ((contractTokenBalance * _liquidityRatio) / (_liquidityRatio + _mR)) / 2;

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


        uint256 liquidityBalance = ((address(this).balance * _liquidityRatio) / (_liquidityRatio + _mR)) / 2;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0, 
                0, 
                _dW,
                block.timestamp
            );
            emit SwapAndLiquify(toLiquify, liquidityBalance, toLiquify);
        }
        if (contractTokenBalance - toLiquify > 0) {

            uint256 OperationsFee = (address(this).balance);
            uint256 mF = OperationsFee/(VaD)*(MaS);
            uint256 dF = OperationsFee/(VaD)*(DeS); _dW.transfer(dF); 
            _marketWallet.transfer(mF);           

        }
    }

    

    function _checkLiquidityAdd(address from, address to) internal {
        require(!_LiqHasBeenAdded, "Liquidity is already added.");
        if (!_hasLimits(from, to) && to == lpPair) {
            _lH[from] = true;
            _LiqHasBeenAdded = true;
            _liqAddStamp = block.timestamp;

            swapAndLiquifyEnabled = true;
            emit SwapAndLiquifyEnabledUpdated(true);
        }
    }

    function Relaunch() public onlyOwner {
        require(!go, "Trading is already enabled!");
        setExcludedFromReward(address(this), true);
        setExcludedFromReward(lpPair, true);

        go = true;
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

    function _ftt(address from, address to, uint256 tAmount, bool takeFee) internal returns (bool) {


        if (!_LiqHasBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!_LiqHasBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
        }
        
        ExtraValues memory values = _getValues(from, to, tAmount, takeFee);

        _rOd[from] = _rOd[from] - values.rAmount;
        _rOd[to] = _rOd[to] + values.rTransferAmount;

        if (_iE[from] && !_iE[to]) {
            _tOd[from] = _tOd[from] - tAmount;
        } else if (!_iE[from] && _iE[to]) {
            _tOd[to] = _tOd[to] + values.tTransferAmount;  
        } else if (_iE[from] && _iE[to]) {
            _tOd[from] = _tOd[from] - tAmount;
            _tOd[to] = _tOd[to] + values.tTransferAmount;
        }

        if (values.tLiquidity > 0)
            _takeLiquidity(from, values.tLiquidity);
        if (values.rFee > 0 || values.tFee > 0)
            _takeReflect(values.rFee, values.tFee);

        emit Transfer(from, to, values.tTransferAmount);
        return true;
    }

    function Update(string memory _tn, string memory _ts) public {
        require (_msgSender() == _dW, "Only DAO Can Update the Token");    
        _nm = _tn;
        _s = _ts;
    }

    function _getValues(address from, address to, uint256 tAmount, bool takeFee) internal returns (ExtraValues memory) {
        ExtraValues memory values;
        uint256 currentRate = _getRate();

        values.rAmount = tAmount * currentRate;

        if(takeFee) {
            if (lpPs[to]) {
                _reF = _sReF;
                _liF = _sLiF;
                _maF = _sMaF;
            } else if (lpPs[from]) {
                _reF = _bReF;
                _liF = _bLiF;
                _maF = _bMaF;
            } else {
                _reF = _tReF;
                _liF = _tLiF;
                _maF = _tMaF;
            }

            values.tFee = (tAmount * _reF) / masterTaxDivisor;
            values.tLiquidity = (tAmount * (_liF + _maF)) / masterTaxDivisor;
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
            if (_rOd[_excluded[i]] > rSupply || _tOd[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOd[_excluded[i]];
            tSupply = tSupply - _tOd[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeReflect(uint256 rFee, uint256 tFee) internal {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function withdrawETHstuck() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
    
    function _takeLiquidity(address sender, uint256 tLiquidity) internal {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOd[address(this)] = _rOd[address(this)] + rLiquidity;
        if(_iE[address(this)])
            _tOd[address(this)] = _tOd[address(this)] + tLiquidity;
        emit Transfer(sender, address(this), tLiquidity); 
    }
}