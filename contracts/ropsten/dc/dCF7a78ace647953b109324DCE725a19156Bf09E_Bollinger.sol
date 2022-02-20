/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8);

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory);

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory);

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address _owner, address spender) external view returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
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

contract Bollinger is IERC20 {
    // Ownership moved to in-contract for customizability.
    address private _owner;

    mapping (address => uint256) _tOwned;
    mapping (address => bool) lpPairs;
    uint256 private timeSinceLastPair = 0;
    mapping (address => mapping (address => uint256)) _allowances;
    mapping (address => bool) _isFeeExcluded;
    mapping (address => bool) private _isSniper;

    mapping (address => bool) private _liquidityHolders;

    uint256 constant private startingSupply = 2_000_000;

    string constant private _name = "Bollinger";
    string constant private _symbol = "BOLLINGER";
    uint8 private _decimals = 18;

    uint256 private _tTotal = startingSupply * (10 ** _decimals);

    uint256 private snipeBlockAmt = 0;
    uint256 public snipersCaught = 0;
    bool private sameBlockActive = true;
    bool private sniperProtection = true;
    uint256 private _liqAddBlock = 0;

    struct Fees {
        uint16 buyFee;
        uint16 sellFee;
        uint16 transferFee;
    }

    struct StaticValuesStruct {
        uint16 maxBuyTaxes;
        uint16 maxSellTaxes;
        uint16 maxTransferTaxes;
        uint16 masterTaxDivisor;
    }

    struct Ratios {
        uint16 rewards;
        uint16 liquidity;
        uint16 marketing;
        uint16 treasury;
        uint16 total;
    }

    Fees public _taxRates = Fees({
        buyFee: 0,
        sellFee: 1000,
        transferFee: 4000
        });

    Ratios public _ratios = Ratios({
        rewards: 30,
        liquidity: 10,
        marketing: 10,
        treasury: 50,
        total: 100
        });

       

    StaticValuesStruct public staticVals = StaticValuesStruct({
        maxBuyTaxes: 2000,
        maxSellTaxes: 2000,
        maxTransferTaxes: 4000,
        masterTaxDivisor: 10000
        });

    IUniswapV2Router02 public dexRouter;
    address public lpPair;
    address public currentRouter;

    address private WETH;
    address public DEAD = 0x000000000000000000000000000000000000dEaD;
    address private zero = 0x0000000000000000000000000000000000000000;

    address payable public marketingWallet = payable(0x9988d417b01526B2ee3592d78F3387FE0C797553);//???
    address payable private rewardsPool = payable(0x9988d417b01526B2ee3592d78F3387FE0C797553);//????
    address payable private treasuryWallet = payable(0xde9f48a30fd245DdD434AD3e0d5EBD61fd445AAd);//??????

    uint256 private _maxTxAmount = (_tTotal * 1) / 100;
    uint256 private _maxWalletSize = (_tTotal * 5) / 100;

    bool public contractSwapEnabled = false;
    uint256 private swapThreshold = _tTotal / 20000;
    uint256 private swapAmount = _tTotal * 5 / 1000;
    bool inSwap;

    bool public tradingEnabled = false;
    bool public hasLiqBeenAdded = false;

    uint256 vBuy1 = 250;
    uint256 vBuy2 = 500;
    uint256 vBuy3 = 1500;
    uint256 vBuy4 = 2500;

    IERC20 shares = IERC20(0x9988d417b01526B2ee3592d78F3387FE0C797553);//??????????


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
    event AutoLiquify(uint256 amountETH, uint256 amount);
    event SniperCaught(address sniperAddress);

    constructor () {
        address msgSender = msg.sender;
        _tOwned[msgSender] = _tTotal;

        _owner = msgSender;

        currentRouter = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

        dexRouter = IUniswapV2Router02(currentRouter);
        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        lpPairs[lpPair] = true;
        _approve(msg.sender, currentRouter, type(uint256).max);
        _approve(address(this), currentRouter, type(uint256).max);

        WETH = dexRouter.WETH();

        _isFeeExcluded[owner()] = true;
        _isFeeExcluded[address(this)] = true;

        emit Transfer(zero, msg.sender, _tTotal);
        emit OwnershipTransferred(address(0), msgSender);
    }

//===============================================================================================================
//===============================================================================================================
//===============================================================================================================
    // Ownable removed as a lib and added here to allow for custom transfers and renouncements.
    // This allows for removal of ownership privileges from the owner once renounced or transferred.
    function owner() public view returns (address) {
        return _owner;
    }

    function transferOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Call renounceOwnership to transfer owner to the zero address.");
        require(newOwner != DEAD, "Call renounceOwnership to transfer owner to the zero address.");
        _isFeeExcluded[_owner] = false;
        _isFeeExcluded[newOwner] = true;
        
        if(_tOwned[_owner] > 0) {
            _transfer(_owner, newOwner, _tOwned[_owner]);
        }
        
        _owner = newOwner;
        emit OwnershipTransferred(_owner, newOwner);
        
    }

    function renounceOwnership() public virtual onlyOwner {
        _isFeeExcluded[_owner] = false;
        _owner = address(0);
        emit OwnershipTransferred(_owner, address(0));
    }
//===============================================================================================================
//===============================================================================================================
//===============================================================================================================

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _tTotal; }
    function decimals() external view override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _tOwned[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function nodeApprove(address spender, uint256 amount) external returns (bool) {
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

    function setStartingProtections(uint8 _block) external onlyOwner{
        require (snipeBlockAmt == 0 && _block <= 5 && !hasLiqBeenAdded);
        snipeBlockAmt = _block;
    }

    function isSniper(address account) public view returns (bool) {
        return _isSniper[account];
    }

    function removeSniper(address account) external onlyOwner() {
        require(_isSniper[account], "Account is not a recorded sniper.");
        _isSniper[account] = false;
    }

    function setProtectionSettings(bool antiSnipe, bool antiBlock) external onlyOwner() {
        sniperProtection = antiSnipe;
        sameBlockActive = antiBlock;
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

    function changeRouterContingency(address router) external onlyOwner {
        require(!hasLiqBeenAdded);
        currentRouter = router;
    }

    function isFeeExcluded(address account) public view returns(bool) {
        return _isFeeExcluded[account];
    }

    function enableTrading() public onlyOwner {
        require(!tradingEnabled, "Trading already enabled!");
        require(hasLiqBeenAdded, "Liquidity must be added.");
        _liqAddBlock = block.number;
        tradingEnabled = true;
    }

    function setExcludedFromFees(address account, bool enabled) public onlyOwner {
        _isFeeExcluded[account] = enabled;
    }

    function setTaxes(uint16 buyFee, uint16 sellFee, uint16 transferFee) external onlyOwner {
        require(buyFee <= staticVals.maxBuyTaxes
                && sellFee <= staticVals.maxSellTaxes
                && transferFee <= staticVals.maxTransferTaxes);
        _taxRates.buyFee = buyFee;
        _taxRates.sellFee = sellFee;
        _taxRates.transferFee = transferFee;
    }

    function setRatios(uint16 rewards, uint16 liquidity, uint16 marketing, uint16 treasury) external onlyOwner {
        _ratios.rewards = rewards;
        _ratios.liquidity = liquidity;
        _ratios.marketing = marketing;
        _ratios.treasury = treasury;
        _ratios.total = rewards + liquidity + marketing + treasury;
    }

    function setWallets(address payable marketing, address payable treasury, address payable rewards) external onlyOwner {
        marketingWallet = payable(marketing);
        treasuryWallet = payable(treasury);
        rewardsPool = payable(rewards);
    }

    function setContractSwapSettings(bool _enabled) external onlyOwner {
        contractSwapEnabled = _enabled;
    }

    function setSwapSettings(uint256 thresholdPercent, uint256 thresholdDivisor, uint256 amountPercent, uint256 amountDivisor) external onlyOwner {
        swapThreshold = (_tTotal * thresholdPercent) / thresholdDivisor;
        swapAmount = (_tTotal * amountPercent) / amountDivisor;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function updateSharesAddress(IERC20 _shares) external onlyOwner {
        require(_shares != IERC20(address(this)), "Shares address cannot be this address");
        shares = IERC20(_shares);
        
    }

    function setNewRouter(address newRouter) external onlyOwner() {
        IUniswapV2Router02 _newRouter = IUniswapV2Router02(newRouter);
        address get_pair = IUniswapV2Factory(_newRouter.factory()).getPair(address(this), _newRouter.WETH());
        if (get_pair == address(0)) {
            lpPair = IUniswapV2Factory(_newRouter.factory()).createPair(address(this), _newRouter.WETH());
        }
        else {
            lpPair = get_pair;
        }
        dexRouter = _newRouter;
        _approve(address(this), address(dexRouter), type(uint256).max);
    }

    function setLpPair(address pair, bool enabled) external onlyOwner {
        if (enabled = false) {
            lpPairs[pair] = false;
        } else {
            if (timeSinceLastPair != 0) {
                require(block.timestamp - timeSinceLastPair > 3 days, "Cannot set a new pair this week!");
            }
            lpPairs[pair] = true;
            timeSinceLastPair = block.timestamp;
        }
    }

    function setMaxTxPercent(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Transaction amt must be above 0.1% of total supply.");
        _maxTxAmount = (_tTotal * percent) / divisor;
    }

    function setMaxWalletSize(uint256 percent, uint256 divisor) external onlyOwner {
        require((_tTotal * percent) / divisor >= (_tTotal / 1000), "Max Wallet amt must be above 0.1% of total supply.");
        _maxWalletSize = (_tTotal * percent) / divisor;
    }

    function getMaxTX() external view returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function getMaxWallet() external view returns (uint256) {
        return _maxWalletSize / (10**_decimals);
    }

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != owner()
            && to != owner()
            && tx.origin != owner()
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
        if(_hasLimits(from, to)) {
            if(!tradingEnabled) {
                revert("Trading not yet enabled!");
            }

            if(lpPairs[from] || lpPairs[to]){
                require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
            }
            if(to != currentRouter && !lpPairs[to]) {
                require(balanceOf(to) + amount <= _maxWalletSize, "Transfer amount exceeds the maxWalletSize.");
            }
        }

        bool takeFee = true;
        
        if(_isFeeExcluded[from] || _isFeeExcluded[to]){
            takeFee = false;
        }

        return _finalizeTransfer(from, to, amount, takeFee);
    }

    function _finalizeTransfer(address from, address to, uint256 amount, bool takeFee) internal returns (bool) {
        if (sniperProtection){
            if (isSniper(from) || isSniper(to)) {
                revert("Sniper rejected.");
            }

            if (!hasLiqBeenAdded) {
                _checkLiquidityAdd(from, to);
                if (!hasLiqBeenAdded && _hasLimits(from, to)) {
                    revert("Only owner can transfer at this time.");
                }
            } else {
                if (_liqAddBlock > 0 
                    && lpPairs[from] 
                    && _hasLimits(from, to)
                ) {
                    if (block.number - _liqAddBlock < snipeBlockAmt) {
                        _isSniper[to] = true;
                        snipersCaught ++;
                        emit SniperCaught(to);
                    }
                }
            }
        }
            
        _tOwned[from] -= amount;        

        if (inSwap) {
            return _basicTransfer(from, to, amount);
        }

        uint256 contractTokenBalance = _tOwned[address(this)];
        if(contractTokenBalance >= swapAmount)
            contractTokenBalance = swapAmount;

        if (!inSwap
            && !lpPairs[from]
            && contractSwapEnabled
            && contractTokenBalance >= swapThreshold
        ) {
            contractSwap(contractTokenBalance);
        }

        uint256 amountReceived = amount;

        if (takeFee) {
            amountReceived = takeTaxes(from, to, amount);
        }

        _tOwned[to] += amountReceived;

        emit Transfer(from, to, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _tOwned[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setVBuy(uint256 _vBuy1, uint256 _vBuy2, uint256 _vBuy3, uint256 _vBuy4) external onlyOwner {
        require(_vBuy1 < _vBuy2, "vBuy1 must be less than vBuy2");
        vBuy1 = _vBuy1;
        require(_vBuy2 < _vBuy3, "vBuy2 must be less than vBuy3");
        vBuy2 = _vBuy2;
        require(_vBuy3 < _vBuy4, "vBuy3 must be less than vBuy4");
        vBuy3 = _vBuy3;
        require(_vBuy4 <= 2500, "vBuy4 must be less than 25%");
        vBuy4 = _vBuy4;
    }

    function getWhaleFee(address from) public view returns (uint256) {
        if(shares.balanceOf(from) >= 1 &&
            shares.balanceOf(from) < 20 ){return vBuy1;}
        if(shares.balanceOf(from) >= 20 &&
            shares.balanceOf(from) < 50 ){return vBuy2;}
        if(shares.balanceOf(from) >= 50 &&
            shares.balanceOf(from) < 100 ){return vBuy3;}
        if(shares.balanceOf(from) >= 100) {return vBuy4;}
        else{
            return 0;
        }

    }

    function takeTaxes(address from, address to, uint256 amount) internal returns (uint256) {
        uint256 currentFee;
        if (from == lpPair) {
            currentFee = _taxRates.buyFee;
        } else if (to == lpPair) {
            currentFee = _taxRates.sellFee + getWhaleFee(from);
        } else {
            currentFee = _taxRates.transferFee;
        }

        if (currentFee == 0) {
            return amount;
        }

        uint256 feeAmount = amount * currentFee / staticVals.masterTaxDivisor;

        _tOwned[address(this)] += feeAmount;
        emit Transfer(from, address(this), feeAmount);

        return amount - feeAmount;
    }

    function contractSwap(uint256 numTokensToSwap) internal swapping {
        if (_ratios.total == 0) {
            return;
        }
        
        if(_allowances[address(this)][address(dexRouter)] != type(uint256).max) {
            _allowances[address(this)][address(dexRouter)] = type(uint256).max;
        }

        uint256 amountToLiquify = ((numTokensToSwap * _ratios.liquidity) / (_ratios.total)) / 2;
        uint256 amountToRewardsPool = (numTokensToSwap * _ratios.rewards) / (_ratios.total);

        if(amountToRewardsPool > 0) {
            emit Transfer(address(this), rewardsPool, amountToRewardsPool);
        }

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETH;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            numTokensToSwap - amountToLiquify - amountToRewardsPool,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        uint256 amountETHLiquidity = ((amountETH * _ratios.liquidity) / (_ratios.total)) / 2;

        
        

        if (amountToLiquify > 0) {
            dexRouter.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(amountETHLiquidity, amountToLiquify);
        }


        if(address(this).balance > 0){
            amountETH = address(this).balance;
            treasuryWallet.transfer((amountETH * _ratios.treasury) / (_ratios.treasury + _ratios.marketing));
            marketingWallet.transfer(address(this).balance);
        }
    }

    

    function _checkLiquidityAdd(address from, address to) private {
        require(!hasLiqBeenAdded, "Liquidity already added and marked.");
        if (!_hasLimits(from, to) && to == lpPair) {
            
            _liqAddBlock = block.number;
            _liquidityHolders[from] = true;
            hasLiqBeenAdded = true;
            
            contractSwapEnabled = true;
            emit ContractSwapEnabledUpdated(true);
        }
    }

    function multiSendTokens(address[] memory accounts, uint256[] memory amounts) external {
        require(accounts.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= amounts[i]);
            _transfer(msg.sender, accounts[i], amounts[i]*10**_decimals);
        }
    }

    function multiSendPercents(address[] memory accounts, uint256[] memory percents, uint256[] memory divisors) external {
        require(accounts.length == percents.length && percents.length == divisors.length, "Lengths do not match.");
        for (uint8 i = 0; i < accounts.length; i++) {
            require(_tOwned[msg.sender] >= (_tTotal * percents[i]) / divisors[i]);
            _transfer(msg.sender, accounts[i], (_tTotal * percents[i]) / divisors[i]);
        }
    }
}