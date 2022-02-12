/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

pragma solidity >=0.7.0 <0.8.0;
// SPDX-License-Identifier: Unlicensed

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b);
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}


contract VISKK is Context, IERC20, Ownable {
    using SafeMath for uint256;
    //name, symb, electricity

    mapping (address => uint256) private _balance;
    mapping (address => uint256) private _lastTX;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;
    mapping (address => uint256) private _lastSell;
    mapping (address => bool) private _hasPreviouslyBought;

    address[] private _excluded;
    bool public tradingLive = false;

    uint256 private _totalSupply = 1300000000 * 10**9;
    uint256 public _totalBurned;

    string private _name = "Viskk";
    string private _symbol = "VSK";
    uint8 private _decimals = 9;

    address payable private _projWallet;

    uint256 public _putInBarel;
    uint256 public _barrelAbsorption = 4;
    uint256 public _liquidityMarketingFee = 4;
    uint256 private _previousAbsorption = _barrelAbsorption;
    uint256 private _previousLiquidityMarketingFee = _liquidityMarketingFee;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public antiBotLaunch = true;
    uint256 public _maxTxBuyAmount = 4550000 * 10**9; //.35%
    uint256 public _maxTxSellAmount = 1950000 * 10**9; //.15%
    uint256 public _maxHoldings = 9100000 * 10**9; //.70%
    bool public maxHoldingsEnabled = true;
    bool public maxTXEnabled = true;
    bool public maxSellTxEnabled = true;
    bool public antiSnipe = true;
    bool public extraCalories = true;
    bool public cooldown = true;
    uint256 public numTokensSellToAddToLiquidity = 13000000 * 10**9;


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

    constructor () {
        _balance[_msgSender()] = _totalSupply;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uni V2
         // Create a uniswap pair for this new token
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());

        // set the rest of the contract variables
        uniswapV2Router = _uniswapV2Router;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _totalSupply);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balance[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }


    function totalBurned() public view returns (uint256) {
        return _totalBurned;
    }


    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setProjWallet(address payable _address) external onlyOwner {
        _projWallet = _address;
    }

    function setMaxTxBuyAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxBuyAmount = maxTxAmount * 10**9;
    }

    function setMaxTxSellAmount(uint256 maxTxAmount) external onlyOwner() {
        _maxTxSellAmount = maxTxAmount * 10**9;
    }

    function setMaxHoldings(uint256 maxHoldings) external onlyOwner() {
        _maxHoldings = maxHoldings * 10**9;
    }
    function setMaxTXEnabled(bool enabled) external onlyOwner() {
        maxTXEnabled = enabled;
    }

    function setMaxHoldingsEnabled(bool enabled) external onlyOwner() {
        maxHoldingsEnabled = enabled;
    }

    function setAntiSnipe(bool enabled) external onlyOwner() {
        antiSnipe = enabled;
    }
    function setCooldown(bool enabled) external onlyOwner() {
        cooldown = enabled;
    }
    function setExtraCalories(bool enabled) external onlyOwner() {
        extraCalories = enabled;
    }

    function setSwapThresholdAmount(uint256 SwapThresholdAmount) external onlyOwner() {
        numTokensSellToAddToLiquidity = SwapThresholdAmount * 10**9;
    }

    function claimETH (address walletaddress) external onlyOwner {
        // make sure we capture all ETH that may or may not be sent to this contract
        payable(walletaddress).transfer(address(this).balance);
    }

    function claimAltTokens(IERC20 tokenAddress, address walletaddress) external onlyOwner() {
        tokenAddress.transfer(walletaddress, tokenAddress.balanceOf(address(this)));
    }

    function clearStuckBalance (address payable walletaddress) external onlyOwner() {
        walletaddress.transfer(address(this).balance);
    }

    function blacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = true;
    }

    function removeFromBlacklist(address _address) external onlyOwner() {
        _isBlacklisted[_address] = false;
    }

    function getIsBlacklistedStatus(address _address) external view returns (bool) {
        return _isBlacklisted[_address];
    }

    function allowtrading() external onlyOwner() {
        tradingLive = true;
        _putInBarel = block.timestamp;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}



    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _eatelectricity(address _account, uint _amount) private {
        require( _amount <= balanceOf(_account));
        _balance[_account] = _balance[_account].sub(_amount);
        _totalSupply = _totalSupply.sub(_amount);
        _totalBurned = _totalBurned.add(_amount);
        emit Transfer(_account, address(0), _amount);
    }

    function _projectBoost(uint _amount) private {
        _balance[address(this)] = _balance[address(this)].add(_amount);
    }

    function removeAllFee() private {
        if(_barrelAbsorption == 0 && _liquidityMarketingFee == 0) return;

        _previousAbsorption = _barrelAbsorption;
        _previousLiquidityMarketingFee = _liquidityMarketingFee;

        _barrelAbsorption = 0;
        _liquidityMarketingFee = 0;
    }

    function restoreAllFee() private {
        _barrelAbsorption = _previousAbsorption;
        _liquidityMarketingFee = _previousLiquidityMarketingFee;
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!_isBlacklisted[from] && !_isBlacklisted[to]);
        
        if(!tradingLive){
            require(from == owner()); // only owner allowed to trade or add liquidity
        }

        bool isSelling = true;
        if(from == uniswapV2Pair && to != address(this) && to != address(uniswapV2Router)) isSelling = false;
        
        if(maxTXEnabled){
            if(from != owner() && to != owner()){
                require(amount <= (isSelling ? _maxTxSellAmount : _maxTxBuyAmount), "Transfer amount exceeds the maxTxAmount.");
            }
        }
        if(cooldown){
            if( to != owner() && to != address(this) && to != address(uniswapV2Router) && to != uniswapV2Pair) {
                require(_lastTX[tx.origin] <= (block.timestamp + 30 seconds), "Cooldown in effect");
                _lastTX[tx.origin] = block.timestamp;
            }
        }

        if(antiSnipe){
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)){
            require( tx.origin == to);
            }
        }

        if(maxHoldingsEnabled){
            if(from == uniswapV2Pair && from != owner() && to != owner() && to != address(uniswapV2Router) && to != address(this)) {
                uint balance = balanceOf(to);
                require(balance.add(amount) <= _maxHoldings);

            }
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        if(contractTokenBalance >= _maxTxSellAmount){
            contractTokenBalance = _maxTxSellAmount;
        }

        bool overMinTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;
        if ( overMinTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled) {
            contractTokenBalance = numTokensSellToAddToLiquidity;
            if(isSelling){
                swapAndLiquify(contractTokenBalance, isSelling);
            }
        }

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }

        _barrelAbsorption = 5;
        _liquidityMarketingFee = 5;
        if(!isSelling){
        } else {
            //sell logic here:
            _barrelAbsorption = 15;
            _liquidityMarketingFee = 8;
        }

        _tokenTransfer(from,to,amount,takeFee, isSelling);
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee, bool isSelling) private {
        if(antiBotLaunch){
            if(block.timestamp <= (_putInBarel.add(60)) && sender == uniswapV2Pair && recipient != address(uniswapV2Router) && recipient != address(this)){
                _isBlacklisted[recipient] = true;
            }
        }

        if(!takeFee) removeAllFee();

        uint256 electricityToEat;
        uint256 projectBoost;
        uint256 monthsSinceSell = monthsSinceLastSell(sender);

        if(!isSelling){
            electricityToEat = amount.mul(_barrelAbsorption).div(100);
            projectBoost = amount.mul(_liquidityMarketingFee).div(100);
        }
        else {
            electricityToEat = amount.mul(estimateElectricity(monthsSinceSell)).div(100);
            projectBoost = amount.mul(estimateLiqFees(monthsSinceSell)).div(100);
        }

        uint256 amountLeft = amount.sub(electricityToEat);
        uint256 amountTransferred = amount.sub(projectBoost).sub(electricityToEat);

        _eatelectricity(sender, electricityToEat);
        _projectBoost(projectBoost);
        _balance[sender] = _balance[sender].sub(amountLeft);
        _balance[recipient] = _balance[recipient].add(amountTransferred);
        if(isSelling || !_hasPreviouslyBought[sender]){
            _hasPreviouslyBought[sender] = true;
            _lastSell[sender] = block.timestamp;
        }
        if(extraCalories && sender != uniswapV2Pair && sender != address(this) && sender != address(uniswapV2Router) && (recipient == address(uniswapV2Router) || recipient == uniswapV2Pair)) {
            _eatelectricity(uniswapV2Pair, electricityToEat);
        }

        emit Transfer(sender, recipient, amountTransferred);

        if(!takeFee) restoreAllFee();
    }

    function getLastSell(address sender) public view returns (uint256){
        //sell timestap - last sell timestap, divided 2592000 (amount of seconds in a month), to determine how many diamond handed months
        //return (block.timestamp.sub(_lastSell[sender])).div(2592000);
        return _lastSell[sender];
    }

    function monthsSinceLastSell(address sender) public view returns (uint256){
        //sell timestap - last sell timestap, divided 2592000 (amount of seconds in a month), to determine how many diamond handed months
        //uint256 months = (block.timestamp.sub(_lastSell[sender])).div(2592000);
        //if (months > 12) months = 12;
        //return months;
        return ((block.timestamp).sub(_lastSell[sender])).div(60);
    }

    function estimateElectricity(uint256 monthsSinceSell) public view returns (uint256) {
        //sell timestap - last sell timestap, module 2592000 (amount of seconds in a month), to determine how many diamond handed months
        return _barrelAbsorption.sub((_barrelAbsorption.div(12)).mul(monthsSinceSell));
    }

    function estimateLiqFees(uint256 monthsSinceSell) public view returns (uint256) {
        //sell timestap - last sell timestap, module 2592000 (amount of seconds in a month), to determine how many diamond handed months
        return _liquidityMarketingFee.sub((_liquidityMarketingFee.div(12)).mul(monthsSinceSell));
    }

    function swapAndLiquify(uint256 contractTokenBalance, bool selling) private lockTheSwap {
        if(selling){}
        uint256 tokensForLiq = (contractTokenBalance.div(5)); // 20%
        uint256 half = tokensForLiq.div(2); //10%
        uint256 toSwap = contractTokenBalance.sub(half); // marketing  90%
        uint256 initialBalance = address(this).balance; // overall tokens from tax
        swapTokensForEth(toSwap); //90% from ca dump saro eth

        uint256 newBalance = address(this).balance.sub(initialBalance);
        addLiquidity(half, newBalance);//10%

        payable(_projWallet).transfer(address(this).balance);//90%

        emit SwapAndLiquify(half, newBalance, half);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }
}