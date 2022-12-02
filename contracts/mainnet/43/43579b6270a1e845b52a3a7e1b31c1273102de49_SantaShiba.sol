/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// Santa Shiba - Launched December 02 2022
// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

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


contract SantaShiba is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcludedFromLimits;
    mapping (address => bool) private _liquidityHolders;
   
    uint256 constant private startingSupply = 1_000_000_000;

    string constant private _name = "SantaShiba";
    string constant private _symbol = "SSHIB";
    uint8 constant private _decimals = 18;

    uint256 constant private _tTotal = startingSupply * 10**_decimals;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct Ratios {
        
        uint16 tokens;
        uint16 swap;
        uint16 burn;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 900,
        sellFee: 900,
        transferFee: 0
        });

    Ratios public _ratios = Ratios({
        tokens: 0,
        swap: 8,
        burn: 2,
        total: 10
        });

    uint256 constant public maxBuyTaxes = 2000;
    uint256 constant public maxSellTaxes = 2000;
    uint256 constant public maxTransferTaxes = 2000;
    uint256 constant masterTaxDivisor = 10000;

    IRouter02 public dexRouter;
    address public lpPair;
    address constant public DEAD = 0x000000000000000000000000000000000000dEaD;

    struct TaxWallets {
        address tokens;
        address payable swap;
    }

    TaxWallets public _taxWallets = TaxWallets({
        tokens: 0x8B913Fb8b50d648D85390Cc4FED1bfA9f4cf9f7E,
        swap: payable(0x8B913Fb8b50d648D85390Cc4FED1bfA9f4cf9f7E)
        });
    
    bool inSwap;
    bool public contractSwapEnabled = false;
    uint256 public contractSwapTimer = 0 seconds;
    uint256 private lastSwap;
    uint256 public swapThreshold;
    uint256 public swapAmount;
    
    uint256 public _amountTokensLastSold;
    uint256 public _percentLastSoldToBuyBackTimesTen = 10;
    uint256 private _buyBackAmount;
    

    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxWalletSize = _tTotal;

    bool public tradingEnabled = false;
    bool public _hasLiqBeenAdded = false;
    bool public buyBackEnabled = true;
    

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ContractSwapEnabledUpdated(bool enabled);
    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);
    event SwapETHForTokens(uint256 amountIn, address[] path);
      
    
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
        _tOwned[msg.sender] = _tTotal;
        emit Transfer(address(0), msg.sender, _tTotal);

        // Set the owner.
        _owner = msg.sender;

        if (block.chainid == 56) {
            dexRouter = IRouter02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        } else if (block.chainid == 97) {
            dexRouter = IRouter02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3);
        } else if (block.chainid == 1 || block.chainid == 4 || block.chainid == 3) {
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

        _approve(_owner, address(dexRouter), type(uint256).max);
        _approve(address(this), address(dexRouter), type(uint256).max);

        _isExcludedFromFees[_owner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;
        _liquidityHolders[_owner] = true;
    }

    receive() external payable {}

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
            _transfer(_owner, newOwner, balanceOf(_owner));
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner {
        setExcludedFromFees(_owner, false);
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

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
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "3 Day cooldown.!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
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
    
    function setRatios(uint16 tokens, uint16 swap, uint16 burn) external onlyOwner {
        
        _ratios.tokens = tokens;
        _ratios.swap = swap;
        _ratios.burn = burn;
        _ratios.total =  swap + burn;
    }

    
    function setExcludedFromLimits(address account, bool enabled) external onlyOwner {
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


    function getAmountTokensLastSold() public view returns (uint256) {
        return _amountTokensLastSold;
    }

    function percentLastSoldToBuyBackTimesTen() public view returns (uint256) {
        return _percentLastSoldToBuyBackTimesTen;
    }

    
    function setBuyBackEnabled(bool _enabled) public onlyOwner {
        buyBackEnabled = _enabled;
        
    }

    function setPercentLastSoldToBuyBackTimesTen(uint256 percentLastSoldToBuyBackTimesTenNew) public onlyOwner {
        _percentLastSoldToBuyBackTimesTen = percentLastSoldToBuyBackTimesTenNew;
    }

     function _getSellETHAmount(uint256 tokenAmount) private view returns(uint256) {
        address[] memory path = new address[](2);

        path[0] = address(this);
        path[1] = dexRouter.WETH();

        uint[] memory amounts = dexRouter.getAmountsOut(tokenAmount, path);

        return amounts[1];
        
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor, uint256 time) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
        contractSwapTimer = time;
    }

    function setWallets(address tokens, address payable swap) external onlyOwner {
        _taxWallets.tokens = tokens;
        _taxWallets.swap = payable(swap);
    }

    function setContractSwapEnabled(bool enabled) external onlyOwner {
        contractSwapEnabled = enabled;
        emit ContractSwapEnabledUpdated(enabled);
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

        if (sell) 
        {
            if (!inSwap
                && contractSwapEnabled
            ) {
                if (lastSwap + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if(contractTokenBalance >= swapAmount) { contractTokenBalance = swapAmount; }
                        contractSwap();
                        lastSwap = block.timestamp;
                    }
                }

            }
            
            uint256 balance = address(this).balance;
            if (buyBackEnabled && contractSwapEnabled) {
                        _amountTokensLastSold += _getSellETHAmount(amount);
                        uint256 buyBackAmount = _amountTokensLastSold / (1000) * (_percentLastSoldToBuyBackTimesTen);
                        if(buyBackAmount < balance){
                            buyBackTokens(buyBackAmount);
			                _amountTokensLastSold;
                        }else{
			                _amountTokensLastSold = 0;
                        }
                    }
                

            
               
            
            
        }
        return _finalizeTransfer(from, to, amount, takeFee, buy, sell, other);
        
    }

    function contractSwap() internal lockTheSwap {
        uint256 amountToSwap = swapAmount;
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        uint256 balanceBefore = address(this).balance;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp

        );
        uint256 amountETH = address(this).balance - (balanceBefore);
        uint256 amountETHMarketing = amountETH * (_ratios.swap) / (_ratios.total);
        
        (bool MarketingSuccess, /* bytes memory data */) = payable(_taxWallets.swap).call{value: amountETHMarketing, gas: 30000}("");
        require(MarketingSuccess, "receiver rejected ETH transfer");

    }
    
  function buyBackTokens(uint256 amount) private lockTheSwap {
    	if (amount > 0) {
    	    swapETHForTokens(amount);
	    }
    }

    //swapExactETHForTokens
    function swapETHForTokens(uint256 amount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = dexRouter.WETH();
        path[1] = address(this);

      // make the swap
        dexRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{value: amount}(
            0, // accept any amount of Tokens
            path,
            DEAD, // Burn address
            block.timestamp 
        );

        emit SwapETHForTokens(amount, path);
    }
    
    function _checkLiquidityAdd(address from, address to) internal {
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
        swapThreshold = (balanceOf(lpPair) * 5) / 10000;
        swapAmount = (balanceOf(lpPair) * 5) / 10000;
    }

    function sweepContingency() external onlyOwner {
        payable(_owner).transfer(address(this).balance);
    }


    function transferContractToken(address _token, address _to, uint256 _quant) public onlyOwner returns(bool _sent){
        _sent = IERC20(_token).transfer(_to, _quant);
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _finalizeTransfer(msg.sender, accounts[i], amounts[i]*10**_decimals, false, false, false, true);
        }
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee, bool buy, bool sell, bool other) internal returns (bool) {
        if (!_hasLiqBeenAdded) {
            _checkLiquidityAdd(from, to);
            if (!_hasLiqBeenAdded && _hasLimits(from, to)) {
                revert("Only owner can transfer at this time.");
            }
        }

        

        _tOwned[from] -= amount;
        uint256 amountReceived = (takeFee) ? takeTaxes(from, buy, sell, amount) : amount;
        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function takeTaxes(address from, bool buy, bool sell, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (buy) {
            currentFee = _taxRates.buyFee;
        } else if (sell) {
            currentFee = _taxRates.sellFee;
        } else {
            currentFee = _taxRates.transferFee;
        }

        uint256 feeAmount = amount * currentFee / masterTaxDivisor;
        uint256 tokenAmount = (feeAmount * _ratios.tokens) / (_ratios.total);
        if (tokenAmount > 0) {
            feeAmount -= tokenAmount;
            address destination = _taxWallets.tokens;
            _tOwned[destination] += tokenAmount;
            emit Transfer(from, destination, tokenAmount);
        }
        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - (feeAmount + tokenAmount);
    }
}