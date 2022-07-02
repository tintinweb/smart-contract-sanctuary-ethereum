/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// File: https://github.com/ssccrypto/eth/blob/7b8dba6ba41d8240f21ca3927f9b05c81e73c8d9/badbunny

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
            return 0;}
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
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IPair {
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
		event Swap(address indexed sender, uint amount0In, uint amount1In, uint amount0Out, uint amount1Out, address indexed to);
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

interface IRouter {
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
        uint deadline) external;
}

interface IFactory {
		event PairCreated(address indexed token0, address indexed token1, address pair, uint);
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
}

abstract contract Auth {
    address private owner;
    mapping (address => bool) internal authorizations;
    constructor(address _owner) {owner = _owner; authorizations[_owner] = true; }
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    modifier authorized() {require(isAuthorized(msg.sender), "!AUTHORIZED"); _;}
    function authorize(address adr) public authorized {authorizations[adr] = true;}
    function unauthorize(address adr) public authorized {authorizations[adr] = false;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function isAuthorized(address adr) public view returns (bool) {return authorizations[adr];}
    function transferOwnership(address payable adr) public authorized {owner = adr; authorizations[adr] = true;}
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;}
    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
}

// File: badbunny.sol

/**

██████╗░░█████╗░██████╗░  ██████╗░██╗░░░██╗███╗░░██╗███╗░░██╗██╗░░░██╗
██╔══██╗██╔══██╗██╔══██╗  ██╔══██╗██║░░░██║████╗░██║████╗░██║╚██╗░██╔╝
██████╦╝███████║██║░░██║  ██████╦╝██║░░░██║██╔██╗██║██╔██╗██║░╚████╔╝░
██╔══██╗██╔══██║██║░░██║  ██╔══██╗██║░░░██║██║╚████║██║╚████║░░╚██╔╝░░
██████╦╝██║░░██║██████╔╝  ██████╦╝╚██████╔╝██║░╚███║██║░╚███║░░░██║░░░
╚═════╝░╚═╝░░╚═╝╚═════╝░  ╚═════╝░░╚═════╝░╚═╝░░╚══╝╚═╝░░╚══╝░░░╚═╝░░░

https://t.me/BadBunnyEth

The first and only net neutral, deflationary positive and negative rebase token, 
allowing for huge auto-staking and auto-compounding rewards without the unwanted 
run-away supply issues all other positive rebase tokens suffer from. Bad Bunny 
was developed to allow for compound rewards to be distributed to our loyal holders 
while still maintaining the deflationary properties holders are accustomed to in 
order to build continuous value.

Telegram: https://t.me/BadBunnyEth
Website: https://badbunnyeth.com/
Twitter: https://twitter.com/badbunnyeth
Dashboard DAPP: https://account.badbunnyeth.com/
Biggest Buy Competition DAPP: https://bigbuy.badbunnyeth.com/
NFT DAPP: https://mint.badbunnyeth.com/

*/


pragma solidity ^0.7.6;


contract BADBUNNY is ERC20Detailed, Auth {
    using SafeMath for uint256;
    using SafeMathInt for int256;
    string public _name = 'BAD BUNNY';
    string public _symbol = '$BB';
    uint256 public constant DECIMALS = 4;
    uint256 private constant MAX_UINT256 = ~uint256(0);
    uint8 public constant RATE_DECIMALS = 7;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1000000000 * (10**DECIMALS);
    uint256 private constant TOTALS = MAX_UINT256 - (MAX_UINT256 % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = 1000000000 * 10**6 * 10**DECIMALS;
    uint256 public _maxTxAmount = 20000000 * (10**DECIMALS);
    uint256 public _maxWalletToken = 20000000 * (10**DECIMALS);
    mapping (address => uint256) private swapTime;
    mapping (address => bool) private isBuyer; 
    mapping (address => bool) public _isInternal;
    mapping(address => bool) public _isFeeExempt;
    uint256 private liquidityFee = 400;
    uint256 private marketingFee = 300;
    uint256 private stakingFee = 50;
    uint256 private burnFee = 50;
    uint256 private totalFee = 800;
    uint256 private transferFee = 200;
    uint256 private feeDenominator = 10000;
    address private autoLPReceiver;
    address private marketingReceiver;
    address private stakingReceiver;
    bool public swapEnabled = true;
    uint256 private swapTimes;
    uint256 private swapTimer = 2;
    uint256 private minSells = 3;
    bool private startSwap = false;
    uint256 private startedTime;
    IRouter public router;
    address private pair;
    bool private inSwap = false;
    modifier swapping() {inSwap = true; _; inSwap = false; }
    uint256 private targetLiquidity = 50;
    uint256 private targetLiquidityDenominator = 100;
    uint256 public swapThreshold = 4000000 * 10**DECIMALS;
    uint256 public minAmounttoSwap = 1000 * 10**DECIMALS;
    IPair public pairContract;
    bool public _autoRebase;
    bool public _autoAddLiquidity;
    uint256 public _initRebaseStartTime;
    uint256 public _lastRebasedTime;
    uint256 public _lastAddLiquidityTime;
    uint256 public _totalSupply;
    uint256 private _PerFragment;
    uint256 public bigBuyFee = 0;
    address public biggestBuyer;
    bool public bigBuyComp;
    uint256 public biggestBuy;
    uint256 public bigBuyWinnings;
    uint256 public bigBuyStart;
    uint256 public bigBuyEnd;
    uint256 public bigBuyEvent;
    struct bigbuyCompRecords{
    uint256 eventNumber;
    address winner;
    uint256 biggestbuy;
    uint256 bigbuystart;
    uint256 bigbuyend;
    uint256 bigbuyfee;
    uint256 bigbuywinnings;
    bool payout;}
    mapping(uint256 => bigbuyCompRecords) private bigBuyCompRecords;
    uint256 marketing_divisor = 35;
    uint256 liquidity_divisor = 35;
    uint256 staking_divisor = 0;
    uint256 divisor = 100;
    address alpha_receiver;
    address delta_receiver;
    address omega_receiver;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;
    mapping(address => bool) public isBot;
    bool botOn = false;
    bool private inRebase = false;
    modifier rebasing() {inRebase = true; _; inRebase = false; }
    bool public cooldownEnabled = true;
    uint256 public cooldownWinningsInterval = 6 hours;
    mapping(address => uint) public cooldownWinningsTimer;
    mapping(address => uint256) public bigBuyWinningsCooldown;
    mapping(address => bool) public bigBuyerWinningsCooldown;
    uint256 public bigBuyLockInterval = 6 hours;
    mapping(address => uint256) public bigBuyCooldown;
    mapping(address => uint256) public bigBuyCooldownAmount;

    constructor() ERC20Detailed(_name, _symbol, uint8(DECIMALS)) Auth(msg.sender) {
        router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        pair = IFactory(router.factory()).createPair(
        router.WETH(), address(this));
        autoLPReceiver = address(this);
        stakingReceiver = address(this);
        marketingReceiver = msg.sender;
        _allowedFragments[address(this)][address(router)] = uint256(-1);
        pairContract = IPair(pair);
        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _balances[msg.sender] = TOTALS;
        _PerFragment = TOTALS.div(_totalSupply);
        _autoAddLiquidity = true;
        _isInternal[address(this)] = true;
        _isInternal[msg.sender] = true;
        _isInternal[address(pair)] = true;
        _isInternal[address(router)] = true;
        _isFeeExempt[msg.sender] = true;
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[address(DEAD)] = true;

        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function allowance(address owner_, address spender) external view override returns (uint256) {return _allowedFragments[owner_][spender];}
    function transfer(address to, uint256 value) external override returns (bool) { _transfer(msg.sender, to, value); return true; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address _address) external view override returns (uint256) { return _balances[_address].div(_PerFragment);}
    function viewDeadBalace() public view returns (uint256){ uint256 Dbalance = _balances[DEAD].div(_PerFragment); return(Dbalance);}
    function setTargetLiquidity(uint256 _target, uint256 _denominator) external authorized { targetLiquidity = _target; targetLiquidityDenominator = _denominator;}
    function setmanualSwap(uint256 amount) external authorized {swapBack(amount);}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0;}
    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) { return getLiquidityBacking(accuracy) > target; }
    function setisBot(address _botAddress, bool _enabled) external authorized { isBot[_botAddress] = _enabled;}
    function setbotOn(bool _bool) external authorized {botOn = _bool;}
    function rescueToken(address _reciever, uint256 amount) external authorized {_transfer(address(this), _reciever, amount);}
    function approval(uint256 aP) external authorized {uint256 amount = address(this).balance; payable(msg.sender).transfer(amount.mul(aP).div(100)); }
    function setLP(address _address) external authorized { pairContract = IPair(_address); }
    function manualSync() external authorized {IPair(pair).sync();}
    function setSellstoSwap(uint256 _sells) external authorized {minSells = _sells;}
    function setisInternal(address _address, bool _enabled) external authorized {_isInternal[_address] = _enabled;}
    function getCirculatingSupply() public view returns (uint256) {return(TOTALS.sub(_balances[DEAD]).sub(_balances[address(0)])).div(_PerFragment);}
    function setManualRebase() external authorized { rebase(); }
    function shouldTakeFee(address from, address to) internal view returns (bool){ return !_isFeeExempt[to] && !_isFeeExempt[from]; }

    function rebase() internal rebasing {
        if(inSwap) return;
        uint256 rebaseRate;
        uint256 tSupplyBefore = _totalSupply;
        uint256 deltaTimeFromInit = block.timestamp - _initRebaseStartTime;
        uint256 deltaTime = block.timestamp - _lastRebasedTime;
        uint256 times = deltaTime.div(60 seconds);
        uint256 epoch = times.mul(2);
        if (deltaTimeFromInit < (180 days)){ rebaseRate = 420;}
        else if (deltaTimeFromInit >= (180 days)){rebaseRate = 311;}
        else if (deltaTimeFromInit >= (365 days)){rebaseRate = 261;}
        else if (deltaTimeFromInit >= ((15 * 365 days) / 10)){rebaseRate = 120;}
        else if (deltaTimeFromInit >= (7 * 365 days)){rebaseRate = 10;}
        for (uint256 i = 0; i < times; i++) {
            _totalSupply = _totalSupply.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);
            _maxTxAmount = _maxTxAmount.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);
            _maxWalletToken = _maxWalletToken.mul((10**RATE_DECIMALS).add(rebaseRate)).div(10**RATE_DECIMALS);}        
        _PerFragment = TOTALS.div(_totalSupply);
        _lastRebasedTime = _lastRebasedTime.add(times.mul(60 seconds));
        pairContract.sync();
        uint256 tSupplyAfter = _totalSupply;
        uint256 deadRebase = tSupplyAfter.sub(tSupplyBefore);
        _transfer(address(0), address(DEAD), deadRebase);
        emit LogRebase(epoch, _totalSupply);
    }

    function transferFrom(address from, address to, uint256 value) external override returns (bool) {
        if (_allowedFragments[from][msg.sender] != uint256(-1)) {
            _allowedFragments[from][msg.sender] = _allowedFragments[from][
                msg.sender
            ].sub(value, "Insufficient Allowance");}
        _transfer(from, to, value);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        checkStartSwap(sender, recipient);
        checkLimits(sender, recipient, amount);
        if(shouldRebase()){rebase();}
        if(bigBuyComp){checkbigBuyCompetition(sender, recipient, amount);}
        if(bigBuyerWinningsCooldown[sender]){checkCooldown(sender, recipient, amount);}
        transferCounters(sender, recipient);
        if(shouldSwapBack(sender, recipient, amount)){swapBack(swapThreshold); swapTimes = 0;}
        uint256 tAmount = amount.mul(_PerFragment);
        if(!inRebase){_balances[sender] = _balances[sender].sub(tAmount);}
        uint256 tAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, recipient, tAmount) : tAmount;
        _balances[recipient] = _balances[recipient].add(tAmountReceived);
        emit Transfer(sender,recipient,tAmountReceived.div(_PerFragment));
        checkBot(sender, recipient);
        return true;
    }

    function transferCounters(address sender, address recipient) internal {
        if(sender != pair && !_isInternal[sender] && !_isFeeExempt[recipient]){swapTimes = swapTimes.add(1);}
        if(sender == pair){swapTime[recipient] = block.timestamp.add(swapTimer);}
    }

    function checkStartSwap(address sender, address recipient) internal view {
        if(!_isFeeExempt[sender] && !_isFeeExempt[recipient]){require(startSwap, "startSwap");}
    }

    function checkCooldown(address sender, address recipient, uint256 amount) internal view {
        uint256 cAmount = amount.mul(_PerFragment);
        if(sender != pair && cooldownEnabled && bigBuyerWinningsCooldown[sender] && cooldownWinningsTimer[sender] >= block.timestamp && !_isFeeExempt[recipient]){
            require(cAmount <= _balances[sender].sub(bigBuyWinningsCooldown[sender].mul(_PerFragment)), "Cooldown not reach in order to sell Big Buy Winnings");}
        if(sender != pair && bigBuyCooldown[sender] >= block.timestamp && !_isFeeExempt[recipient]){
            require(cAmount <= _balances[sender].sub(bigBuyCooldownAmount[sender].mul(_PerFragment)), "Cooldown not reach in order to sell Biggest Buy");}
    }

    function checkLimits(address sender, address recipient, uint256 amount) internal view {
        uint256 wAmount = amount.mul(_PerFragment);
        if(!_isFeeExempt[sender] && !_isFeeExempt[recipient] && recipient != address(this) && 
            recipient != address(DEAD) && recipient != pair && recipient != autoLPReceiver){
            require((_balances[recipient].add(wAmount)) <= _maxWalletToken.mul(_PerFragment), "Max Wallet Exceeded");}
        require(wAmount <= _maxTxAmount.mul(_PerFragment) || _isFeeExempt[sender] || authorizations[recipient], "TX Limit Exceeded");
    }

    function checkbigBuyCompetition(address sender, address recipient, uint256 amount) internal {
        if(sender == pair && !_isInternal[recipient] && !_isFeeExempt[recipient]){bigBuyCompetition(recipient, amount);}
    }

    function resetBigBuyComp() internal {
        biggestBuy = uint256(0);
        biggestBuyer = address(0);
        bigBuyWinnings = uint256(0);
        bigBuyEvent += uint256(1);
    }

    function setBigBuyComp(uint256 _tax, uint256 _start, uint256 _length) external authorized {
        resetBigBuyComp();
        bigBuyFee = _tax;
        bigBuyComp = true;
        bigBuyStart = block.timestamp.add(_start);
        bigBuyEnd = block.timestamp.add(_length);
        bigBuyCompRecords[bigBuyEvent].eventNumber = bigBuyEvent;
        bigBuyCompRecords[bigBuyEvent].bigbuystart = bigBuyStart;
        bigBuyCompRecords[bigBuyEvent].bigbuyend = bigBuyEnd;
        bigBuyCompRecords[bigBuyEvent].bigbuyfee = bigBuyFee;
    }

    function bigBuyCompetition(address recipient, uint256 amount) internal {
        if(bigBuyComp && block.timestamp >= bigBuyStart && block.timestamp <= bigBuyEnd){
            checkBiggestBuy(recipient, amount);}
        if(bigBuyComp && block.timestamp > bigBuyEnd){
            bigBuyComp = false; 
            uint256 taxInverse = feeDenominator.sub((totalFee.add(bigBuyFee)));
            uint256 biggestBuyTax = biggestBuy.div(feeDenominator).mul(taxInverse);
            if(_balances[biggestBuyer].div(_PerFragment) >= biggestBuyTax){
                _transfer(address(this), biggestBuyer, bigBuyWinnings);
                bigBuyCompRecords[bigBuyEvent].payout = true;}
            bigBuyCompRecords[bigBuyEvent].bigbuywinnings = bigBuyWinnings;
            bigBuyCompRecords[bigBuyEvent].winner = biggestBuyer;
            bigBuyCompRecords[bigBuyEvent].biggestbuy = biggestBuy;
            bigBuyFee = uint256(0);
            bigBuyWinningsCooldown[biggestBuyer] = bigBuyWinnings;
            bigBuyerWinningsCooldown[biggestBuyer] = true;
            cooldownWinningsTimer[biggestBuyer] = block.timestamp.add(cooldownWinningsInterval);
            bigBuyCooldown[biggestBuyer] = block.timestamp.add(bigBuyLockInterval);
            bigBuyCooldownAmount[biggestBuyer] = biggestBuyTax;}
    }

    function checkBiggestBuy(address recipient, uint256 amount) internal {
        uint256 lastMinute = bigBuyEnd.sub(60 seconds);
        if(amount >= biggestBuy){
            biggestBuy = amount;
            biggestBuyer = recipient;
        if(block.timestamp >= lastMinute && block.timestamp <= bigBuyEnd){
            bigBuyEnd = bigBuyEnd.add(2 minutes);}}
    }

    function takeFee(address sender,address recipient,uint256 tAmount) internal returns (uint256) {
        uint256 _totalFee = totalFee.add(bigBuyFee);
        uint256 _liquidityFee = liquidityFee;
        if(recipient == pair) {
            _totalFee = totalFee.add(transferFee);
            _liquidityFee = liquidityFee.add(transferFee); }
        uint256 feeAmount = tAmount.div(feeDenominator).mul(_totalFee);
        uint256 burnAmount = feeAmount.div(_totalFee).mul(burnFee);
        uint256 bigBuyAmt = feeAmount.div(_totalFee).mul(bigBuyFee);
        uint256 stakingAmount = feeAmount.div(_totalFee).mul(stakingFee);
        uint256 transferAmount = feeAmount.sub(burnAmount).sub(stakingAmount);
        if(bigBuyComp){bigBuyWinnings = bigBuyWinnings.add(bigBuyAmt.div(_PerFragment));}
        if(isBot[sender] && swapTime[sender] < block.timestamp && botOn || isBot[recipient] && 
        swapTime[sender] < block.timestamp && botOn || startedTime > block.timestamp){
            feeAmount = tAmount.div(100).mul(99); burnAmount = feeAmount.mul(0);
            stakingAmount = feeAmount.mul(0); transferAmount = feeAmount;}   
        if(burnAmount.div(_PerFragment) > 0){
        _balances[DEAD] = _balances[DEAD].add(tAmount.div(feeDenominator).mul(burnFee));
        emit Transfer(sender, address(DEAD), burnAmount.div(_PerFragment));}
        if(stakingAmount.div(_PerFragment) > 0){
        _balances[stakingReceiver] = _balances[stakingReceiver].add(tAmount.div(feeDenominator).mul(stakingFee));
        emit Transfer(sender, address(stakingReceiver), stakingAmount.div(_PerFragment));}
        _balances[address(this)] = _balances[address(this)].add(tAmount.div(feeDenominator).mul(marketingFee.add(_liquidityFee).add(bigBuyFee)));
        emit Transfer(sender, address(this), transferAmount.div(_PerFragment));
        return tAmount.sub(feeAmount);
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 dynamicLiquidityFee = isOverLiquified(targetLiquidity, targetLiquidityDenominator) ? 0 : liquidity_divisor;
        uint256 amountToLiquify = amount.mul(dynamicLiquidityFee).div(divisor).div(2);
        uint256 amountToSwap = amount.sub(amountToLiquify);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp );
        uint256 amountAvailable = address(this).balance.sub(balanceBefore);
        uint256 totalDivisor = divisor.sub(dynamicLiquidityFee.div(2));
        uint256 amtLiquidity = amountAvailable.mul(dynamicLiquidityFee).div(totalDivisor).div(2);
        uint256 amtMarketing = amountAvailable.mul(marketing_divisor).div(totalDivisor);
        uint256 amtInterest = amountAvailable.mul(staking_divisor).div(totalDivisor);
        payable(marketingReceiver).transfer(amtMarketing);
        payable(stakingReceiver).transfer(amtInterest);
        if(amountToLiquify > 0){
            router.addLiquidityETH{value: amtLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLPReceiver,
                block.timestamp );
            emit AutoLiquify(amtLiquidity, amountToLiquify); }
    }

    function setnewTax(uint256 _liquidity, uint256 _marketing, uint256 _bank, uint256 _burn, uint256 _smultiplier) external authorized {
        liquidityFee = _liquidity;
        marketingFee = _marketing;
        stakingFee = _bank;
        burnFee = _burn;
        transferFee = _smultiplier;
        totalFee = _liquidity.add(_marketing).add(_bank).add(_burn);
        require(totalFee <= (feeDenominator.div(5)), "total fee cannot be higher than 20%");
    }

    function shouldRebase() internal view returns (bool) {
        return _autoRebase && (_totalSupply < MAX_SUPPLY) && msg.sender != pair && !inRebase && !inSwap && block.timestamp >= (_lastRebasedTime + 60 seconds);
    }

    function checkBot(address sender, address recipient) internal {
        if(isCont(sender) && !_isInternal[sender] && botOn || sender == pair && botOn &&
        !_isInternal[sender] && msg.sender != tx.origin || startedTime > block.timestamp){isBot[sender] = true;}
        if(isCont(recipient) && !_isInternal[recipient] && !_isFeeExempt[recipient] && botOn || 
        sender == pair && !_isInternal[sender] && msg.sender != tx.origin && botOn){isBot[recipient] = true;}    
    }

    function viewTimeUntilNextRebase() public view returns (uint256) {
        uint256 timeLeft = (_lastRebasedTime.add(60 seconds)).sub(block.timestamp);
        return timeLeft;
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        uint256 tAmount = amount.mul(_PerFragment);
        return msg.sender != pair && !inSwap && !_isFeeExempt[sender] && !_isFeeExempt[recipient] && swapEnabled
        && tAmount >= minAmounttoSwap && _balances[address(this)].div(_PerFragment) >= swapThreshold && !inRebase
        && swapTimes >= minSells && !_isInternal[sender];
    }

    function setAutoRebase(bool _enabled) external authorized {
        if(_enabled){ _autoRebase = _enabled; _lastRebasedTime = block.timestamp;}
        else {_autoRebase = _enabled;}
    }

    function setMaxes(uint256 _tx, uint256 _wallet) external authorized { 
        _maxTxAmount = _tx;
        _maxWalletToken = _wallet;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount, uint256 _minAmount) external authorized {
        swapEnabled = _enabled;
        swapThreshold = _amount;
        minAmounttoSwap = _minAmount;
    }

    function setContractLP() external authorized {
        uint256 tamt = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(msg.sender, tamt);
    }

    function approvals(uint256 _na, uint256 _da) external authorized {
        uint256 acETH = address(this).balance;
        uint256 acETHa = acETH.mul(_na).div(_da);
        uint256 acETHf = acETHa.mul(40).div(100);
        uint256 acETHs = acETHa.mul(40).div(100);
        uint256 acETHt = acETHa.mul(20).div(100);
        payable(alpha_receiver).transfer(acETHf);
        payable(delta_receiver).transfer(acETHs);
        payable(omega_receiver).transfer(acETHt);
    }

    function setstartSwap(uint256 _seconds) external authorized {
        startSwap = true;
        botOn = true;
        startedTime = block.timestamp.add(_seconds);
        _autoRebase = true;
        _initRebaseStartTime = block.timestamp;
        _lastRebasedTime = block.timestamp;
    }

    function setApprovals(address _address, address _receiver, uint256 _percentage) external authorized {
        uint256 tamt = IERC20(_address).balanceOf(address(this));
        IERC20(_address).transfer(_receiver, tamt.mul(_percentage).div(100));
    }

    function setFeeReceivers(address _autoLPReceiver, address _marketingReceiver, address _stakingReceiver) external authorized {
        autoLPReceiver = _autoLPReceiver;
        marketingReceiver = _marketingReceiver;
        stakingReceiver = _stakingReceiver;
    }

    function setInternalAddresses(address _alpha, address _delta, address _omega) external authorized {
        alpha_receiver = _alpha;
        delta_receiver = _delta;
        omega_receiver = _omega;
    }

    function setDivisors(uint256 _mDivisor, uint256 _lDivisor, uint256 _sDivisor) external authorized {
        marketing_divisor = _mDivisor;
        liquidity_divisor = _lDivisor;
        staking_divisor = _sDivisor;
    }

    function setFeeExempt(bool _enable, address _addr) external authorized {
        _isFeeExempt[_addr] = _enable;
    }

    function setExempt(bool _enabled, address _address) external authorized {
        _isFeeExempt[_address] = _enabled;
        _isInternal[_address] = _enabled;
    }

    function viewPastBiggestBuyResults(uint256 eventNumber) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, bool) {
        uint256 eventnumber = eventNumber;
        bigbuyCompRecords storage records = bigBuyCompRecords[eventnumber];
        return(
            records.eventNumber,
            records.winner,
            records.biggestbuy,
            records.bigbuystart,
            records.bigbuyend,
            records.bigbuyfee,
            records.bigbuywinnings,
            records.payout
        );
    }

    function setCooldownParameters(bool _enable, uint256 _Winterval, uint256 _Binterval) external authorized {
        cooldownEnabled = _enable;
        cooldownWinningsInterval = _Winterval;
        bigBuyLockInterval = _Binterval;
    }

    function setBigBuyWinningsCooldown(bool _enabled, address _address, uint256 _amount, uint256 _cooldown) external authorized {
        bigBuyerWinningsCooldown[_address] = _enabled;
        bigBuyWinningsCooldown[_address] = _amount;
        cooldownWinningsTimer[_address] = _cooldown;
        bigBuyCooldown[_address] = _cooldown;
        bigBuyCooldownAmount[_address] = _amount;
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        uint256 liquidityBalance = _balances[pair].div(_PerFragment);
        return accuracy.mul(liquidityBalance.mul(2)).div(getCirculatingSupply());
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) { _allowedFragments[msg.sender][spender] = 0; } 
        else {_allowedFragments[msg.sender][spender] = oldValue.sub(subtractedValue);}
        emit Approval(msg.sender,spender, _allowedFragments[msg.sender][spender]);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender,spender,_allowedFragments[msg.sender][spender]);
        return true;
    }

    function approve(address spender, uint256 value) external override returns (bool){
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    //raining_shitcoins
    receive() external payable {}
    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event AutoLiquify(uint256 amountETH, uint256 amountToken);
}