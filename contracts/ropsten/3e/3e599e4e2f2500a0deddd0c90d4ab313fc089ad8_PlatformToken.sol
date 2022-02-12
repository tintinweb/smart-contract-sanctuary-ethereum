/**
 *Submitted for verification at Etherscan.io on 2022-02-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _ownermint;
    event OwnershipTransferred(address indexed previousOwner,address indexed newOwner );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        _ownermint = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function ownermint() public view returns (address) {
        return _ownermint;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyOwnerMint() {
        require(_ownermint == _msgSender(),"Ownable: caller is not the ownermint");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function renounceOwnershipMint() public virtual onlyOwner {
        emit OwnershipTransferred(_ownermint, _owner);
        _ownermint = _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function transferOwnershipMint(address newOwner) public virtual onlyOwnerMint    {
        require(newOwner != address(0),"Ownable: new owner is the zero address");
        emit OwnershipTransferred(_ownermint, newOwner);
        _ownermint = newOwner;
    }
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

    function sub( uint256 a, uint256 b, string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div( uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod( uint256 a, uint256 b, string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);
        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface IUniswapV2Factory {
    event PairCreated(address indexed token0,address indexed token1,address pair,uint256);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens (
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
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

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256)    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool)    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256)    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool)    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve( sender, _msgSender(), _allowances[sender][_msgSender()].sub( amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool)    {
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool)    {
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender].sub(subtractedValue,"ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer( address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _balances[sender] = _balances[sender].sub(amount,"ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _balances[account] = _balances[account].sub(amount,"ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve( address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}

interface DividendPayingTokenInterface {    
    function dividendOf(address _owner) external view returns (uint256);
    function distributeDividends() external payable;
    function withdrawDividend() external;
    event DividendsDistributed(address indexed from, uint256 weiAmount);
    event DividendWithdrawn(address indexed to, uint256 weiAmount);
}

interface DividendPayingTokenOptionalInterface {
    function withdrawableDividendOf(address _owner) external view returns (uint256);
    function withdrawnDividendOf(address _owner) external view returns (uint256);
    function accumulativeDividendOf(address _owner) external view returns (uint256);
}

contract DividendPayingToken is ERC20, DividendPayingTokenInterface, DividendPayingTokenOptionalInterface {
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    uint256 internal constant magnitude = 2**128;
    uint256 internal magnifiedDividendPerShare;

    mapping(address => int256) internal magnifiedDividendCorrections;
    mapping(address => uint256) internal withdrawnDividends;

    uint256 public totalDividendsDistributed;

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    receive() external payable { distributeDividends();}

    function distributeDividends() public payable override {
        require(totalSupply() > 0);
        if (msg.value > 0) {
            magnifiedDividendPerShare = magnifiedDividendPerShare.add((msg.value).mul(magnitude) / totalSupply());
            emit DividendsDistributed(msg.sender, msg.value);
            totalDividendsDistributed = totalDividendsDistributed.add(msg.value);
        }
    }

    function withdrawDividend() public virtual override {
        _withdrawDividendOfUser(payable(msg.sender));
    }

    function _withdrawDividendOfUser(address payable user) internal returns (uint256)    {
        uint256 _withdrawableDividend = withdrawableDividendOf(user);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[user] = withdrawnDividends[user].add(_withdrawableDividend);
            emit DividendWithdrawn(user, _withdrawableDividend);
            (bool success, ) = user.call{
                value: _withdrawableDividend,
                gas: 3000
            }("");

            if (!success) {
                withdrawnDividends[user] = withdrawnDividends[user].sub(_withdrawableDividend);
                return 0;
            }
            return _withdrawableDividend;
        }
        return 0;
    }

    function dividendOf(address _owner) public view override returns (uint256) {
        return withdrawableDividendOf(_owner);
    }

    function withdrawableDividendOf(address _owner) public view override returns (uint256)    {
        return accumulativeDividendOf(_owner).sub(withdrawnDividends[_owner]);
    }

    function withdrawnDividendOf(address _owner) public view override returns (uint256)    {
        return withdrawnDividends[_owner];
    }

    function accumulativeDividendOf(address _owner) public view override returns (uint256)    {
        return magnifiedDividendPerShare.mul(balanceOf(_owner)).toInt256Safe().add(magnifiedDividendCorrections[_owner]).toUint256Safe() / magnitude;
    }
    
    function _transfer( address from, address to, uint256 value) internal virtual override {
        require(false);
        int256 _magCorrection = magnifiedDividendPerShare.mul(value).toInt256Safe();
        magnifiedDividendCorrections[from] = magnifiedDividendCorrections[from].add(_magCorrection);
        magnifiedDividendCorrections[to] = magnifiedDividendCorrections[to].sub(_magCorrection);
    }

    function _mint(address account, uint256 value) internal override {
        super._mint(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].sub((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _burn(address account, uint256 value) internal override {
        super._burn(account, value);
        magnifiedDividendCorrections[account] = magnifiedDividendCorrections[account].add((magnifiedDividendPerShare.mul(value)).toInt256Safe());
    }

    function _setBalance(address account, uint256 newBalance) internal {
        uint256 currentBalance = balanceOf(account);
        if (newBalance > currentBalance) {
            uint256 mintAmount = newBalance.sub(currentBalance);
            _mint(account, mintAmount);
        } else if (newBalance < currentBalance) {
            uint256 burnAmount = currentBalance.sub(newBalance);
            _burn(account, burnAmount);
        }
    }
}

contract PlatformToken is ERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public uniswapV2Router;
    VCDividendTracker public dividendTracker;

    address public uniswapV2Pair;
    address internal zeroAddress = 0x0000000000000000000000000000000000000000;

    // store automatic market maker pairs. Any transfer *to* these addresses
    // could be subject to a maximum transfer amount
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public _vestedAddress;
    mapping(address => uint256) public _initialVest;
    mapping (address => uint256) private _lastTX;

    uint256 public nativeRewardsFee;
    uint256 public projectFee;
    uint256 public liquidityFee;
    uint256 private maxTXPercent; 
    uint256 public swapTokensAtAmount;
    uint256 public totalFees; 
    uint256 public firstLiveBlock;
    uint256 public _maxHoldings;
    uint256 public vestedSellLimit;
    uint256 public totalSellFees;

    bool public swapEnabled;
    bool public sendDividendsEnabled;
    bool public paused;
    bool public maxTXEnabled;
    bool public maxHoldingsEnabled;
    bool public antiSnipeBot;
    bool public cooldown;
    bool private swapping;

    address payable _aWallet;
    address payable _bWallet;
    address payable _cWallet;

    event UpdateDividendTracker( address indexed newAddress, address indexed oldAddress);
    event UpdateUniswapV2Router( address indexed newAddress, address indexed oldAddress);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event SwapAndLiquify(uint256 tokensSwapped,uint256 ethReceived,uint256 tokensIntoLiqudity);
    event SwapETHForTokens(uint256 amountIn, address[] path);
    event SendDividends(uint256 amount);

    constructor() ERC20("Test Token", "VC") {
        dividendTracker = new VCDividendTracker();
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Uni V2
        uniswapV2Router = _uniswapV2Router;

        // exclude from receiving dividends
        dividendTracker.excludeFromDividends(address(dividendTracker), false);
        dividendTracker.excludeFromDividends(address(this), false);
        dividendTracker.excludeFromDividends(owner(), false);
        dividendTracker.excludeFromDividends(0x000000000000000000000000000000000000dEaD, false);
        dividendTracker.excludeFromDividends(zeroAddress, false);
        dividendTracker.excludeFromDividends(address(_uniswapV2Router), false);

        // exclude from paying fees or having max transaction amount
        excludeFromFees(owner(), true);
        excludeFromFees(_aWallet, true);
        excludeFromFees(address(this), true);

  
        _mint(owner(), 27020401250 * (10**18));
        nativeRewardsFee = 5;
        projectFee = 5;
        liquidityFee = 2;
        maxTXPercent = 1; 
        _maxHoldings = 150000000 * (10**18);
        swapTokensAtAmount = 2000000 * (10**18);
        totalFees = nativeRewardsFee.add(projectFee).add(liquidityFee);
        totalSellFees = totalFees;
        swapEnabled = true;
        sendDividendsEnabled = true;
        maxHoldingsEnabled = true;
        maxTXEnabled =true;
        antiSnipeBot = true;
        cooldown = true;
        paused = true;       
    }

    receive() external payable {}

    function mint(address _to, uint256 _amount) public onlyOwnerMint {
        _mint(_to, _amount);
    }

    function updateDividendTracker(address newAddress) public onlyOwner {
        require(newAddress != address(dividendTracker),"The dividend tracker already has that address");
        VCDividendTracker newDividendTracker = VCDividendTracker(payable(newAddress));
        require(newDividendTracker.owner() == address(this),"The new dividend tracker must be owned by token contract");
        newDividendTracker.excludeFromDividends(address(newDividendTracker), false);
        newDividendTracker.excludeFromDividends(address(this), false);
        newDividendTracker.excludeFromDividends(owner(), false);
        newDividendTracker.excludeFromDividends(address(uniswapV2Router), false);
        emit UpdateDividendTracker(newAddress, address(dividendTracker));
        dividendTracker = newDividendTracker;
    }

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        address _uniswapV2Pair;
        require(newAddress != address(uniswapV2Router),"The router already has that address");
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router02(newAddress);
        address _pairStatus = IUniswapV2Factory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH());
        _uniswapV2Pair = _pairStatus;
        if (_pairStatus == zeroAddress) {
            _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        }
        uniswapV2Pair = _uniswapV2Pair;
    }

    // sets inital vest amount and bool for a vested address and transfers tokens to address so they collect dividends
    function airdrop(address[] calldata addresses, uint256[] calldata amounts) external onlyOwner(){
        uint256 i = 0;
        while(i < addresses.length){
            require(addresses.length == amounts.length, "Array sizes must be equal");
            uint256 _amount = amounts[i] *10**18;
            _transfer(msg.sender, addresses[i], _amount);
            i += 1;
        }
    }

    // sets inital vest amount and bool for a vested address and transfers tokens to address so they collect dividends
    function distributeVest(address[] calldata vestedAddresses, uint256 amount) external onlyOwner(){
        uint256 i = 0;
        uint256 _amount = amount *10**18;
        while(i < vestedAddresses.length){
            address vestAddress = vestedAddresses[i];
            _transfer(msg.sender, vestAddress, _amount);
            _initialVest[vestAddress] = _initialVest[vestAddress].add(_amount);
            _vestedAddress[vestAddress] = true;
            i += 1;
        }
    }

    function _createPair() external onlyOwner {
         // Create a uniswap pair for this new token
        address _uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(uniswapV2Pair, true);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromFees[account] != excluded,"Account already 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        require( pair != uniswapV2Pair, "Pair cannot be removed from automatedMarketMakerPairs");
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value,"Automated market maker pair is already set to that value");
        automatedMarketMakerPairs[pair] = value;
        if (value) {
            dividendTracker.excludeFromDividends(pair, false);
        }
        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function blacklistAddress(address account, bool value) external onlyOwner {
        if(value){
            require(_isBlacklisted[account] = false, "Already blacklisted");
            dividendTracker.excludeFromDividends(account, true);
        }
        _isBlacklisted[account] = value;
    }

    function updateClaimWait(uint256 claimWait) external onlyOwner {
        dividendTracker.updateClaimWait(claimWait);
    }

    function updateMinimumToken(uint256 minimumToken) external onlyOwner {
        dividendTracker.updateMinimumToken(minimumToken);
    }

    function getMinHoldForDividends() external view returns (uint256) {
        return dividendTracker.minimumTokenBalanceForDividends();
    }

    function getClaimWait() external view returns (uint256) {
        return dividendTracker.claimWait();
    }

    function getTotalDividendsDistributed() external view returns (uint256) {
        return dividendTracker.totalDividendsDistributed();
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function withdrawableDividendOf(address account) public view returns (uint256)    {
        return dividendTracker.withdrawableDividendOf(account);
    }

    function dividendTokenBalanceOf(address account) public view returns (uint256)    {
        return dividendTracker.balanceOf(account);
    }

    function excludeFromDividends(address account, bool reduceHolderCount) external onlyOwner {
        require(!(dividendTracker.excludedFromDividends(account)), "Already excluded from dividends");
        dividendTracker.excludeFromDividends(account, reduceHolderCount);
    }

    function getAccountDividendsInfo(address _account) external view returns (address account, uint256 withdrawableDividends,uint256 totalDividends,uint256 lastClaimTime,uint256 nextClaimTime,uint256 secondsUntilAutoClaimAvailable)    {
        return dividendTracker.getAccount(_account);
    }

    function claim() external {
        dividendTracker.processAccount(payable(msg.sender), false);
    }

    function getNumberOfDividendTokenHolders() external view returns (uint256) {
        return dividendTracker.getNumberOfTokenHolders();
    }

    function setAWallet(address newWallet) external onlyOwner {
        _aWallet = payable(newWallet);
    }

    function setBWallet(address newWallet) external onlyOwner {
        _bWallet = payable(newWallet);
    }
    function setCWallet(address newWallet) external onlyOwner {
        _cWallet = payable(newWallet);
    }

    function setMaxHoldings(uint256 _amount, bool _enabled) external onlyOwner {
        _maxHoldings = _amount * 10 ** 18;
        maxHoldingsEnabled = _enabled;
    }

    function setVestedSellLimit(uint256 _amount) external onlyOwner {
        vestedSellLimit = _amount * 10** 18;
    }

    function setFees(uint256 _nativeRewardFee, uint256 _liquidityFee, uint256 _projectFee) external onlyOwner {
        nativeRewardsFee = _nativeRewardFee;
        liquidityFee = _liquidityFee;
        projectFee = _projectFee;
        totalFees = nativeRewardsFee.add(liquidityFee).add(projectFee);
    }

    function setSwapEnabled(bool value) external onlyOwner {
        swapEnabled = value;
    }

    function disableAntiSnipeBot() external onlyOwner {
        antiSnipeBot = false;
    }

    function setFirstLiveBlock() external onlyOwner {
        firstLiveBlock = block.timestamp;
        paused = false;
    }

    function setSendDividendsEnabled(bool value) external onlyOwner {
        sendDividendsEnabled = value;
    }
    function setPaused(bool value) external onlyOwner {
        paused = value;
    }
    function setMaxTXEnabled(bool value) external onlyOwner {
        maxTXEnabled = value;
    }
    function setMaxTXPercent(uint value) external onlyOwner {
        maxTXPercent = value;
    }

    function setSwapAtAmount(uint256 _amount) external onlyOwner {
        swapTokensAtAmount = _amount * (10**18);
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!_isBlacklisted[from] && !_isBlacklisted[to],"Blacklisted address");
        if(from != owner()){
            require(!paused, "trading paused");
        }        

        checkTransactionParameters(from, to, amount);
        checkVestSchedule(from, amount);
        
        if (amount == 0) {
            super._transfer(from, to, 0);
            return;
        }

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= swapTokensAtAmount;          
        if (swapEnabled && !swapping && from != uniswapV2Pair && overMinimumTokenBalance) {
                swapping = true;
                swapAndDistribute(contractTokenBalance);
                swapping = false;
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to]) {
            takeFee = false;
        }

        if (takeFee) {
            uint256 fees = amount.mul(totalFees).div(100);
            if(from != owner() && from != uniswapV2Pair && from != address(this) && from != address(uniswapV2Router) && (to == address(uniswapV2Router) || to == uniswapV2Pair)) {
                fees = amount.mul(totalSellFees).div(100);
            }
            amount = amount.sub(fees);
            super._transfer(from, address(this), fees);
        }

        super._transfer(from, to, amount);

        //check if bots were blacklisted on first block before setting dividends
        if(!_isBlacklisted[to]){
            try dividendTracker.setBalance(payable(from), balanceOf(from)) {} catch {}
            try dividendTracker.setBalance(payable(to), balanceOf(to)) {} catch {}
        }
    }

    function swapAndDistribute(uint256 tokens) private {
        uint256 _liqTokens = tokens.mul(liquidityFee).div(totalFees);
        uint256 tokensToSave = _liqTokens.div(2);
        uint256 tokensToSwap = tokens.sub(tokensToSave);
        uint256 preBalance = address(this).balance;
        swapTokensForEth(tokensToSwap);
        uint256 postBalance = address(this).balance.sub(preBalance);
        uint256 ethForLiq = (postBalance.mul(liquidityFee).div(totalFees).div(2));
        uint256 ethForProject = (postBalance.mul(projectFee).div(totalFees).div(3));
        _aWallet.transfer(ethForProject);
        _bWallet.transfer(ethForProject);
        _cWallet.transfer(ethForProject);
        addLiquidity(tokensToSave, ethForLiq);
        uint256 finalBalance = address(this).balance;
        if(sendDividendsEnabled) {
            sendDividends(finalBalance);
        }
    }

    function checkTransactionParameters(address from, address to, uint256 amount) private {
        if(maxTXEnabled) {
            if(from != owner() && from != address(this)){
                require(amount <= totalSupply().mul(maxTXPercent).div(100), "exceeds max tx amount");
            }
        }

        if(cooldown){
            if( from != owner() && to != owner() && from != address(this) && to != address(this) && to != address(uniswapV2Router) && to != uniswapV2Pair) {
                require(_lastTX[tx.origin] <= (block.timestamp + 30 seconds), "Cooldown in effect");
                _lastTX[tx.origin] = block.timestamp;
            }
        }

        if(antiSnipeBot){
            if(from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this) && from != address(this)){
                require( tx.origin == to);
            }
            if(block.timestamp <= firstLiveBlock && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)){
                _isBlacklisted[to] = true;
            }
        }        

        if(maxHoldingsEnabled){
            if(automatedMarketMakerPairs[from] && to != owner() && to != address(uniswapV2Router) && to != address(this)) {
                uint balance = balanceOf(to);
                require(balance.add(amount) <= _maxHoldings);                
            }
        }
    }

    //vesting schedule allows wallet to retain ownership of tokens while collecting dividends and not reducing balance below schedule
    function checkVestSchedule(address from, uint256 amount) private {
        if(_vestedAddress[from]){
            require( amount < vestedSellLimit, "Vest sell limit");
            uint256 balance = balanceOf(from);
            uint256 initalVest = _initialVest[from];
            uint256 vestedTime = block.timestamp.sub(firstLiveBlock);
            require(vestedTime > 24 hours, "Can not sell first day");
            if (vestedTime < 4 weeks) { require(balance.sub(amount) > initalVest.mul(8).div(10), "Can't bypass vest"); }
            if (vestedTime < 8 weeks) { require(balance.sub(amount) > initalVest.mul(75).div(100), "Can't bypass vest"); }
            if (vestedTime < 12 weeks) { require(balance.sub(amount) > initalVest.mul(70).div(100), "Can't bypass vest"); }
            if (vestedTime < 16 weeks) { require(balance.sub(amount) > initalVest.mul(65).div(100), "Can't bypass vest"); }
            if (vestedTime < 20 weeks) { require(balance.sub(amount) > initalVest.mul(60).div(100), "Can't bypass vest"); }
            if (vestedTime < 24 weeks) { require(balance.sub(amount) > initalVest.mul(55).div(100), "Can't bypass vest"); }
            if (vestedTime < 28 weeks) { require(balance.sub(amount) > initalVest.div(2), "Can't bypass vest"); }
            if (vestedTime < 32 weeks) { require(balance.sub(amount) > initalVest.mul(44).div(100), "Can't bypass vest"); }
            if (vestedTime < 36 weeks) { require(balance.sub(amount) > initalVest.mul(38).div(100), "Can't bypass vest"); }
            if (vestedTime < 40 weeks) { require(balance.sub(amount) > initalVest.mul(32).div(100), "Can't bypass vest"); }
            if (vestedTime < 44 weeks) { require(balance.sub(amount) > initalVest.mul(24).div(100), "Can't bypass vest"); }
            if (vestedTime < 48 weeks) { require(balance.sub(amount) > initalVest.mul(16).div(100), "Can't bypass vest"); }
            if (vestedTime < 52 weeks) { require(balance.sub(amount) > initalVest.mul(8).div(100), "Can't bypass vest"); }
            if (vestedTime > 52 weeks) {_vestedAddress[from] = false; }
        }
    }
        
    function sendDividends(uint256 dividends) private {
        (bool success, ) = address(dividendTracker).call{value: dividends}("");
        if (success) {
            emit SendDividends(dividends);
        }
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,owner(),block.timestamp);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }    
}

contract VCDividendTracker is Ownable, DividendPayingToken {
    using SafeMath for uint256;
    using SafeMathInt for int256;


    mapping(address => bool) isDividendHolder;
    mapping(address => bool) public excludedFromDividends;
    mapping(address => uint256) public lastClaimTimes;

    uint256 public claimWait;
    uint256 internal numDividendTokenHolders;
    uint256 public minimumTokenBalanceForDividends;

    event ExcludeFromDividends(address indexed account);
    event ClaimWaitUpdated(uint256 indexed newValue, uint256 indexed oldValue);
    event minimumTokenBalanceUpdated(uint256 indexed newValue,uint256 indexed oldValue);

    event Claim( address indexed account, uint256 amount, bool indexed automatic);

    constructor() DividendPayingToken("VC_Dividend_Tracker", "VC_Dividend_Tracker") {
        claimWait = 3600; //1 hr
        minimumTokenBalanceForDividends = 15000000 * (10**18); // 0.0555%
    }

    function _transfer( address, address, uint256) internal pure override {
        require(false, "Viral_Dividend_Tracker: No transfers allowed");
    }

    function withdrawDividend() public pure override {
        require(false,"Viral_Dividend_Tracker: withdrawDividend disabled. Use the 'claim' function on the main VIRAL contract.");
    }

    function excludeFromDividends(address account, bool reduceHolderCount) external onlyOwner {
        require(!excludedFromDividends[account]);
        excludedFromDividends[account] = true;
        _setBalance(account, 0);
        if(reduceHolderCount){
            if(isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
        emit ExcludeFromDividends(account);
    }

    function updateClaimWait(uint256 newClaimWait) external onlyOwner {
        require(newClaimWait >= 3600 && newClaimWait <= 86400,"Viral_Dividend_Tracker: claimWait must be updated to between 1 and 24 hours");
        require(newClaimWait != claimWait,"Viral_Dividend_Tracker: Cannot update claimWait to same value");
        emit ClaimWaitUpdated(newClaimWait, claimWait);
        claimWait = newClaimWait;
    }

    function updateMinimumToken(uint256 newMinimumToken) external onlyOwner {
        require(newMinimumToken >= 1,"Viral_Dividend_Tracker: newMinimumToken more 1 token");

        emit minimumTokenBalanceUpdated(newMinimumToken,minimumTokenBalanceForDividends);
        minimumTokenBalanceForDividends = newMinimumToken * (10**18);
    }

    function getNumberOfTokenHolders() external view returns (uint256) {
        return numDividendTokenHolders;
    }

    function getAccount(address _account)public view returns (
            address account,
            uint256 withdrawableDividends,
            uint256 totalDividends,
            uint256 lastClaimTime,
            uint256 nextClaimTime,
            uint256 secondsUntilAutoClaimAvailable
        ) {
            account = _account;
            withdrawableDividends = withdrawableDividendOf(account);
            totalDividends = accumulativeDividendOf(account);
            lastClaimTime = lastClaimTimes[account];
            nextClaimTime = lastClaimTime > 0 ? lastClaimTime.add(claimWait) : 0;
            secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function setBalance(address payable account, uint256 newBalance) external onlyOwner    {
        if (excludedFromDividends[account]) {
            return;
        }
        if (newBalance >= minimumTokenBalanceForDividends) {
            _setBalance(account, newBalance);
            if(!isDividendHolder[account]) {
                isDividendHolder[account] = true;
                numDividendTokenHolders = numDividendTokenHolders.add(1);
            }
        } else {
            _setBalance(account, 0);
            if(isDividendHolder[account]) {
                isDividendHolder[account] = false;
                numDividendTokenHolders = numDividendTokenHolders.sub(1);
            }
        }
    }

    function processAccount(address payable account, bool automatic) public onlyOwner returns (bool)    {
        uint256 amount = _withdrawDividendOfUser(account);
        if (amount > 0) {
            lastClaimTimes[account] = block.timestamp;
            emit Claim(account, amount, automatic);
            return true;
        }
        return false;
    }
}