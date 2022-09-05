/**
 *Submitted for verification at Etherscan.io on 2022-09-04
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

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


contract Yokan is IERC20 {
    address private _owner;

    mapping (address => uint256) private _tOwned;
    address private lpPair;
    address public marketingWallet;
    mapping (address => mapping (address => uint256)) private _allowances;
    
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _liquidityHolders;
    mapping (address => bool) private _blacklist;

    string constant private _name = "Koi-no-yokan";
    string constant private _symbol = 'YOKAN';
    uint8 constant private _decimals = 18;

    uint256 constant private _tTotal = 100000000 * 10 ** _decimals;

   struct Fees {
        uint16 buyFeeLP;
        uint16 buyFeeMarketing;
        uint16 sellFeeLP;
        uint16 sellFeeMarketing;
    }

    Fees public _taxRates = Fees({
        buyFeeLP: 1,
        buyFeeMarketing:1,
        sellFeeLP: 1,
        sellFeeMarketing:1
        });

    IRouter02 public dexRouter;
    
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;
    address public secondPair;
    
    uint256 private _maxTxAmountBuy = (_tTotal * 2) / 100; // 1%
    uint256 private _maxTxAmountSell = (_tTotal * 2) / 100; // 1%
    uint256 private _maxWalletSize = (_tTotal * 3) / 100; // 2%

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    
    
    modifier onlyOwner() {
        require(_owner == msg.sender, "Only Owner can call this function.");
        _;
    }
    
    constructor () {
        marketingWallet = 0x19f5156382388fB73aa297CD941476E385B64ddA;
        _tOwned[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        _owner = msg.sender;

        dexRouter = IRouter02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

        secondPair = dexRouter.WETH(); 
        lpPair = IFactoryV2(dexRouter.factory()).createPair(secondPair, address(this)); 

        _isExcludedFromFees[_owner]=true;
        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

    }

    receive() external payable {}


    function setMarketingWallet(address newMarketingAddress) public onlyOwner {
        marketingWallet = newMarketingAddress;
    }
    function setNewFees(uint16 buyFeeLP,
        uint16 buyFeeMarketing,
        uint16 sellFeeLP,
        uint16 sellFeeMarketing) public onlyOwner {
            _taxRates.sellFeeMarketing = sellFeeMarketing;
            require(buyFeeLP <= 5,"Fee can never be more as 5%");
            require(buyFeeMarketing <= 5,"Fee can never be more as 5%");
            require(sellFeeLP <= 5,"Fee can not be about 5%");
            require(sellFeeMarketing <= 5,"Fee can not be about 5%");
            _taxRates.sellFeeLP = sellFeeLP;
            _taxRates.buyFeeMarketing = buyFeeMarketing;
            _taxRates.buyFeeLP = buyFeeLP;    
        }


    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        
        if(balanceOf(_owner) > 0) {
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner {
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }

    function totalSupply() external pure override returns (uint256) { if (_tTotal == 0) { revert(); } return _tTotal; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return _owner; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
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

    function setNewRouter(address newRouter) public onlyOwner {
        IRouter02 _newRouter = IRouter02(newRouter);
        address get_pair = IFactoryV2(_newRouter.factory()).getPair(secondPair,address(this));
        if (get_pair == address(0)) {
            lpPair = IFactoryV2(_newRouter.factory()).createPair(secondPair,address(this));
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    

    function setBlacklistEnabled(address account, bool enabled) external onlyOwner {
        _blacklist[account] = enabled;
    }

    function setBlacklistEnabledMultiple(address[] calldata accounts, bool enabled) external onlyOwner {
        for(uint index=0;index<accounts.length;index++)_blacklist[accounts[index]] = enabled;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklist[account];
    }



    function setMaxTxPercents(uint256 percentBuy, uint256 percentSell) external onlyOwner {
        require((_tTotal * percentBuy) / 1000 >= (_tTotal / 5000), "must be above 0.5%");
        require((_tTotal * percentSell) / 1000 >= (_tTotal / 5000), "must be above 0.5%");
        _maxTxAmountBuy = (_tTotal * percentBuy) / 1000;
        _maxTxAmountSell = (_tTotal * percentSell) / 1000;
    }

    function setMaxWalletSize(uint256 percent) external onlyOwner {
        require((_tTotal * percent) / 1000 >= (_tTotal / 100), "must be above 1%");
        _maxWalletSize = (_tTotal * percent) / 1000;
    }


    function setExcludedFromFees(address account, bool enabled) external onlyOwner {
        _isExcludedFromFees[account] = enabled;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
        _isExcludedFromLimits[account] = enabled;
    }

    function isExcludedFromLimits(address account) public view returns (bool) {
        return _isExcludedFromLimits[account];
    }

    function getMaxTXs() public view returns (uint256, uint256) {
        return (_maxTxAmountBuy / (10**_decimals), _maxTxAmountSell / (10**_decimals));
    }

    function getMaxWallet() public view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }


    function _hasLimits(address from, address to) private view returns (bool) {
        return from != _owner
            && to != _owner
            && tx.origin != _owner
            && to != DEAD
            && to != address(0)
            && !_liquidityHolders[to]
            && !_liquidityHolders[from]
            && from != address(this);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_blacklist[from]==false, "ERC20: address is blacklisted");
        require(_blacklist[to]==false, "ERC20: address is blacklisted");
        require(amount > 0, "Transfer amount must be greater than zero");
        


        uint256 _fee = 0;
        bool _hasCurrentLimits = _hasLimits(from, to);

        if(!tradingEnabled && _hasCurrentLimits) {
            revert("Trading not yet enabled!");
        }
        if(from == lpPair){ // buy
            if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to] && _hasCurrentLimits) {
                require(amount <= _maxTxAmountBuy, "Transfer amount exceeds the maxTxAmount.");
            }
            if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                uint256 fee1 = (amount * _taxRates.buyFeeLP) / 100 ;
                uint256 fee2 = (amount * _taxRates.buyFeeMarketing) / 100 ;       
                _tOwned[lpPair] += fee1;
                _tOwned[marketingWallet] += fee2;
                _fee += fee1 + fee2;
            }

        } else if (to == lpPair) { // sell
            if (!_isExcludedFromLimits[from] && !_isExcludedFromLimits[to] && _hasCurrentLimits) {
                require(amount <= _maxTxAmountSell, "Transfer amount exceeds the maxTxAmount.");
            }

            if(!_isExcludedFromFees[from] && !_isExcludedFromFees[to]){
                uint256 fee1 = (amount * _taxRates.sellFeeLP) / 100 ;
                uint256 fee2 = (amount * _taxRates.sellFeeMarketing) / 100 ;       
                _tOwned[lpPair] += fee1;
                _tOwned[marketingWallet] += fee2;
                _fee += fee1 + fee2;
            }


        }
        if(to != address(dexRouter) && !(lpPair == to) && _hasCurrentLimits) {
            if (!_isExcludedFromLimits[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }
        
        if (!_hasLiqBeenAdded) {
            if (!_hasCurrentLimits && to == lpPair) {
                _liquidityHolders[from] = true;
                _hasLiqBeenAdded = true;
            }
            if (!_hasLiqBeenAdded && _hasCurrentLimits) {
                revert("Only owner can transfer at this time.");
            }
        }


        _tOwned[from] -= amount;
        _tOwned[to] += amount - _fee;

        emit Transfer(from, to, amount);
        return true;
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(_hasLiqBeenAdded, "Liquidity must be added.");
        
        tradingEnabled = true;
    }    
}