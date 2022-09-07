/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity >=0.5.0 <0.9.0;
/**
       d8888 8888888b.  8888888888 Y88b   d88P                                             
      d88888 888   Y88b 888         Y88b d88P                                              
     d88P888 888    888 888          Y88o88P                                               
    d88P 888 888   d88P 8888888       Y888P                                                
   d88P  888 8888888P"  888           d888b                                                
  d88P   888 888        888          d88888b                                               
 d8888888888 888        888         d88P Y88b                                              
d88P     888 888        8888888888 d88P   Y88b                                             
                                                                                                                                                                                  
                                                                                           
888     888 8888888888 888b    888 88888888888 888     888 8888888b.  8888888888 .d8888b.  
888     888 888        8888b   888     888     888     888 888   Y88b 888       d88P  Y88b 
888     888 888        88888b  888     888     888     888 888    888 888       Y88b.      
Y88b   d88P 8888888    888Y88b 888     888     888     888 888   d88P 8888888    "Y888b.   
 Y88b d88P  888        888 Y88b888     888     888     888 8888888P"  888           "Y88b. 
  Y88o88P   888        888  Y88888     888     888     888 888 T88b   888             "888 
   Y888P    888        888   Y8888     888     Y88b. .d88P 888  T88b  888       Y88b  d88P 
    Y8P     8888888888 888    Y888     888      "Y88888P"  888   T88b 8888888888 "Y8888P"  



$APEX IS THE FIRST PROTOCOL TO ENSURE FUNDAMENTAL SUSTAINABILITY AND FAIRNESS IN REWARD DISTRIBUTION!


https://www.apexventureseth.com/
https://t.me/ApexVenturesOfficial


Welcome to APEX Ventures...  If you're reading these contract notes you're either a gem hunter watching new pairs, 
or you're a savvy investor who "Does YOR" and consumes all documentation before making a decision.  Perhaps we 
should address both audiences. The recent bear market has changed the crypto landscape as we know it, 
entire sub-industries like Defi 2.0 and FaaS we're brought to their knees.  We watched as giants tumbled one by one.
Strong, Ohm, Time, Mim, MCC, Luna, UST, Three Arrows.. the list goes on.  As the dust settled we looked around 
and asked ourselves one VERY SIMPLE question... who was actually left making profits?  

It was a simple question with a simple answer; the people getting their hands dirty and physically operating
the miners processing the transactions were the ones earning consistent reliable profits. That's why were 
introducing a totally unique and brand new utility that's never been tried as a layer-2 on Ethereum blockchain,
we're it calling MaaS, Mining as a service! Our innovative protocol will revolutionise the defi world and
offer truly sustainable yield generation to our holders and unlike our predecessors there won’t be a 
requirement to sell your $Apex tokens to materialise these rewards. 

Furthermore, Apex Ventures will offer our second brand new innovative utility to the Apex ecosystem which we 
are calling NaaS, NFTs as a service! Combining the protocols of MaaS and NaaS will allow us to offer exclusive 
yields to our NFT holders!    

You don’t want to miss this! Come check us out for yourself.... https://t.me/ApexVenturesOfficial

*/
abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

interface IDividendDistributor {
    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution,uint256 _minHoldReq) external;
    function setShare(address shareholder, uint256 amount) external;
    function deposit() external payable;
    function process(uint256 gas) external;        
    function claimDividendFor(address shareholder) external;
    function holdReq() external view returns(uint256);
    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256);
    function getAccountInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256);
}

contract DividendDistributor is IDividendDistributor {
    using SafeMath for uint256;
    
    address _token;
    
    struct Share {
        uint256 amount;
        uint256 totalExcluded;
        uint256 totalRealised;
    }
    
    address[] shareholders;
    mapping (address => uint256) shareholderIndexes;
    mapping (address => uint256) shareholderClaims;
    mapping (address => Share) public shares;
    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed;
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10 ** 36;
    
    uint256 public minPeriod = 24*60 minutes; // amount of time for min distribution to accumalate, once over it sends after x amount automatically.
    uint256 public minHoldReq = 100 * (10**9); // 100 tokens for rewards
    uint256 public minDistribution = 0.01 * (10 ** 18); // .01 token with 18 decimals reward for auto claim
    
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

    constructor () {
        _token = msg.sender;
    }

    function getShareholderInfo(address shareholder) external view override returns (uint256, uint256, uint256, uint256) {
        return (
            totalShares,
            totalDistributed,
            shares[shareholder].amount,
            shares[shareholder].totalRealised             
        );
    }

    function holdReq() external view override returns(uint256) {
        return minHoldReq;
    }

    function getAccountInfo(address shareholder) external view override returns(
        uint256 pendingReward,
        uint256 lastClaimTime,
        uint256 nextClaimTime,
        uint256 secondsUntilAutoClaimAvailable){
            
        pendingReward = getUnpaidEarnings(shareholder);
        lastClaimTime = shareholderClaims[shareholder];
        nextClaimTime = lastClaimTime + minPeriod;
        secondsUntilAutoClaimAvailable = nextClaimTime > block.timestamp ? nextClaimTime.sub(block.timestamp) : 0;
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldReq) external override onlyToken {
        minPeriod = _minPeriod;
        minDistribution = _minDistribution;
        minHoldReq = _minHoldReq * (10**9);
        emit DistributionCriteriaUpdated(minPeriod, minDistribution, minHoldReq);
    }
    
    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if(shares[shareholder].amount > 0){
            distributeDividend(shareholder);
        }
    
        if(amount >= minHoldReq && shares[shareholder].amount == 0){
            addShareholder(shareholder);
        }else if(amount < minHoldReq && shares[shareholder].amount > 0){
            removeShareholder(shareholder);
        }
    
        if(amount < minHoldReq) amount = 1;
        totalShares = totalShares.sub(shares[shareholder].amount).add(amount);
        shares[shareholder].amount = amount;
        shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
            
        emit ShareUpdated(shareholder, amount);
    }
    
    function deposit() external payable override {

        uint256 amount = msg.value;
    
        totalDividends = totalDividends.add(amount);
        dividendsPerShare = dividendsPerShare.add(dividendsPerShareAccuracyFactor.mul(amount).div(totalShares));
            
        emit Deposit(amount);
    }
    
    function process(uint256 gas) external override onlyToken {
        uint256 shareholderCount = shareholders.length;
    
        if(shareholderCount == 0) { return; }
    
        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
    
        uint256 iterations = 0;
        uint256 count = 0;
    
        while(gasUsed < gas && iterations < shareholderCount) {
            if(currentIndex >= shareholderCount){
                currentIndex = 0;
            }
    
            if(shouldDistribute(shareholders[currentIndex])){
                distributeDividend(shareholders[currentIndex]);
                count++;
            }
    
            gasUsed = gasUsed.add(gasLeft.sub(gasleft()));
            gasLeft = gasleft();
            currentIndex++;
            iterations++;
        }
            
        emit DividendsProcessed(iterations, count, currentIndex);
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
            payable(shareholder).transfer(amount);
            shareholderClaims[shareholder] = block.timestamp;
            shares[shareholder].totalRealised = shares[shareholder].totalRealised.add(amount);
            shares[shareholder].totalExcluded = getCumulativeDividends(shares[shareholder].amount);
                        
            emit Distribution(shareholder, amount);
        }
    }

    function claimDividend() public {
        distributeDividend(msg.sender);
    }
    
    function claimDividendFor(address shareholder) public override {
        distributeDividend(shareholder);
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
        
    event DistributionCriteriaUpdated(uint256 minPeriod, uint256 minDistribution, uint256 minHoldReq);
    event ShareUpdated(address shareholder, uint256 amount);
    event Deposit(uint256 amountETH);
    event Distribution(address shareholder, uint256 amount);
    event DividendsProcessed(uint256 iterations, uint256 count, uint256 index);
}

contract av is IERC20, Context {
    address public owner;
    address public autoLiquidityReceiver;
    address public treasuryFeeReceiver;
    address public pair;

    string constant _name = "Apex Ventures";
    string constant _symbol = "Apex";

    uint256 public constant _initialSupply = 1_000_000; // put supply amount here
    uint256 _totalSupply = _initialSupply * (10**_decimals); // total supply amount
    uint256 treasuryFees;
    uint256 feeAmount;
    uint256 liquidityAmount;
    uint32 distributorGas = 500000;
    uint16 feeDenominator = 100;
    uint16 totalFee;
    uint8 constant _decimals = 9;

    bool public autoClaimEnabled;
    bool public feeEnabled;
    bool public fundRewards;
    mapping(address => mapping(address => uint256)) _allowances;
    mapping(address => bool) authorizations;
    mapping(address => bool) public bannedUsers;
    mapping(address => uint256) _balances;
    mapping(address => uint256) cooldown;
    mapping(address => bool) isDividendExempt;
    mapping(address => bool) isFeeExempt;
    mapping(address => bool) public lpHolder;
    mapping(address => bool) public lpPairs;    
    mapping(address => bool) maxWalletExempt;
    struct IFees {
        uint16 liquidityFee;
        uint16 treasuryFee;
        uint16 reflectionFee;
        uint16 totalFee;
    }
    struct ICooldown {
        bool buycooldownEnabled;
        bool sellcooldownEnabled;
        uint8 cooldownLimit;
        uint8 cooldownTime;
    }
    struct ILiquiditySettings {
        uint256 liquidityFeeAccumulator;
        uint256 numTokensToSwap;
        uint256 lastSwap;
        uint8 swapInterval;
        bool swapEnabled;
        bool inSwap;
        bool autoLiquifyEnabled;
    }
    struct ILaunch {
        uint256 launchBlock;
        uint256 launchedAt;
        uint8 sniperBlocks;
        uint8 snipersCaught;
        bool tradingOpen;
        bool launchProtection;
        bool earlySellFee;
    }
    struct ITransactionSettings {
        uint256 maxTxAmount;
        uint256 maxWalletAmount;
        bool txLimits;
    }        
    IUniswapV2Router02 public router;
    IDividendDistributor public distributor;
    ILiquiditySettings public LiquiditySettings;
    ICooldown public cooldownInfo;    
    ILaunch public Launch;
    ITransactionSettings public TransactionSettings;
    IFees public BuyFees;
    IFees public SellFees;
    IFees public MaxFees;
    IFees public TransferFees;
    modifier swapping() {
        LiquiditySettings.inSwap = true;
        _;
        LiquiditySettings.inSwap = false;
    }
    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }
    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    constructor() {
        owner = _msgSender();
        authorizations[owner] = true;
        router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        pair = IUniswapV2Factory(router.factory()).createPair(router.WETH(), address(this));
        lpPairs[pair] = true;
        lpHolder[_msgSender()] = true;
        _allowances[address(this)][address(router)] = type(uint256).max;
        _allowances[_msgSender()][address(router)] = type(uint256).max;

        distributor = new DividendDistributor();

        isFeeExempt[address(this)] = true;
        isFeeExempt[_msgSender()] = true;

        maxWalletExempt[_msgSender()] = true;
        maxWalletExempt[address(this)] = true;
        maxWalletExempt[pair] = true;

        isDividendExempt[pair] = true;
        isDividendExempt[address(this)] = true;
        isDividendExempt[address(0xDead)] = true;
        setFeeReceivers(0x3f2A0733bF10526b635535667AA51a5d9e59953C,0x8f3625575254dC6A6C52043D8Ac7E2A48C7A4497);
        cooldownInfo.cooldownLimit = 60; // cooldown cannot go over 60 seconds
        MaxFees.totalFee = 20; // 20%
        BuyFees = IFees({
            liquidityFee: 1,
            reflectionFee: 3,
            treasuryFee: 5,
            totalFee: 2 + 3 + 5
        });
        SellFees = IFees({
            liquidityFee: 2,
            reflectionFee: 6,
            treasuryFee: 12,
            totalFee: 2 + 6 + 12
        });     
        cooldownInfo = ICooldown ({
            buycooldownEnabled: true,
            sellcooldownEnabled: true,
            cooldownLimit: 60, // cooldown cannot go over 60 seconds
            cooldownTime: 30
        });
        TransactionSettings.maxTxAmount = _totalSupply / 100;
        TransactionSettings.maxWalletAmount = _totalSupply / 50;
        TransactionSettings.txLimits = true;     
        LiquiditySettings.autoLiquifyEnabled = true;   
        LiquiditySettings.swapEnabled = true;
        LiquiditySettings.numTokensToSwap = (_totalSupply * 10) / (10000);
        feeEnabled = true;
        fundRewards = true;
        autoClaimEnabled = true;
        _balances[_msgSender()] = _totalSupply;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    receive() external payable {}
    // =============================================================
    //                      OWNERSHIP OPERATIONS
    // =============================================================    
    function transferOwnership(address payable adr) external onlyOwner {
        isFeeExempt[owner] = false;
        maxWalletExempt[owner] = false;
        lpHolder[owner] = false;
        authorizations[owner] = false;        
        isFeeExempt[adr] = true;
        maxWalletExempt[adr] = true;
        lpHolder[adr] = true;
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }
    
    function renounceOwnership() external onlyOwner {
        isFeeExempt[owner] = false;
        maxWalletExempt[owner] = false;
        lpHolder[owner] = false;
        authorizations[owner] = false; 
        owner = address(0);
        emit OwnershipRenounced();

    }

    function authorize(address adr) external onlyOwner {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    function unauthorize(address adr) external onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }
    
    // =============================================================
    //                      ADMIN OPERATIONS
    // =============================================================
    function clearStuckBalance(uint256 amountPercentage) external onlyOwner {
        require(amountPercentage <= 100);
        uint256 amountEth = address(this).balance;
        payable(treasuryFeeReceiver).transfer(
            (amountEth * amountPercentage) / 100
        );
        treasuryFees += amountEth * amountPercentage;
    }

    function clearStuckTokens(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0) && _token != address(this));
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
    }

    function airDropTokens(address[] memory addresses, uint256[] memory amounts) external onlyOwner{
        require(addresses.length == amounts.length, "Lengths do not match.");
        for (uint8 i = 0; i < addresses.length; i++) {
            require(balanceOf(msg.sender) >= amounts[i]);
            _basicTransfer(msg.sender, addresses[i], amounts[i]*10**_decimals);
        }
    }

    function setLpPair(address _pair, bool enabled) external onlyOwner{
        lpPairs[_pair] = enabled;
    }

    function setLpHolder(address holder, bool enabled) public onlyOwner{
        lpHolder[holder] = enabled;
    }

    function fundReward(bool rewards) external authorized {
        fundRewards = rewards;
    }

    function manualDeposit(uint256 amount) external authorized {
        require(amount <= address(this).balance);
        try distributor.deposit{value: amount}() {} catch {}
    }

    function launch(uint8 sniperBlocks) external onlyOwner {
        require(sniperBlocks <= 5);
        require(!Launch.tradingOpen);
        if(!Launch.tradingOpen) {
            Launch.sniperBlocks = sniperBlocks;
            Launch.launchedAt = block.timestamp;
            Launch.launchBlock = block.number; 
            Launch.earlySellFee = false;
            Launch.launchProtection = true;
            Launch.tradingOpen = true;
        }        
        emit Launched();
    }

    function setTransactionLimits(bool enabled) external onlyOwner {
        TransactionSettings.txLimits = enabled;
    }

    function setTxLimit(uint256 percent, uint256 divisor) external authorized {
        require(percent >= 1 && divisor <= 1000);
        TransactionSettings.maxTxAmount = (_totalSupply * (percent)) / (divisor);
        emit TxLimitUpdated(TransactionSettings.maxTxAmount);
    }

    function setMaxWallet(uint256 percent, uint256 divisor) external authorized {
        require(percent >= 1 && divisor <= 100);
        TransactionSettings.maxWalletAmount = (_totalSupply * percent) / divisor;
        emit WalletLimitUpdated(TransactionSettings.maxWalletAmount);
    }

    function setIsDividendExempt(address holder, bool exempt) external authorized{
        require(holder != address(this) && holder != pair);
        isDividendExempt[holder] = exempt;
        if (exempt) {
            distributor.setShare(holder, 0);
        } else {
            distributor.setShare(holder, _balances[holder]);
        }
        emit DividendExemptUpdated(holder, exempt);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
        emit FeeExemptUpdated(holder, exempt);
    }

    function setWalletBanStatus(address[] memory user, bool banned) external onlyOwner {
        for(uint256 i; i < user.length; i++) {
            _setBlacklistStatus(user[i], banned);
            emit WalletBanStatusUpdated(user[i], banned);
        }
    }

    function setMaxWalletExempt(address holder, bool exempt) external authorized {
        maxWalletExempt[holder] = exempt;
        emit TxLimitExemptUpdated(holder, exempt);
    }

    function setBuyFees(uint16 _liquidityFee, uint16 _reflectionFee, uint16 _treasuryFee) external authorized {
        require(_liquidityFee + _treasuryFee + _reflectionFee <= MaxFees.totalFee);
        BuyFees = IFees({
            liquidityFee: _liquidityFee,
            treasuryFee: _treasuryFee,
            reflectionFee: _reflectionFee,
            totalFee: _liquidityFee + _treasuryFee
        });
    }
    
    function setTransferFees(uint16 _liquidityFee, uint16 _reflectionFee, uint16 _treasuryFee) external authorized {
        require(_liquidityFee + _treasuryFee + _reflectionFee <= MaxFees.totalFee);
        TransferFees = IFees({
            liquidityFee: _liquidityFee,
            treasuryFee: _treasuryFee,
            reflectionFee: _reflectionFee,
            totalFee: _liquidityFee + _treasuryFee
        });
    }

    function setSellFees(uint16 _liquidityFee, uint16 _reflectionFee, uint16 _treasuryFee) external authorized {
        require(_liquidityFee + _treasuryFee + _reflectionFee <= MaxFees.totalFee);
        SellFees = IFees({
            liquidityFee: _liquidityFee,
            treasuryFee: _treasuryFee,
            reflectionFee: _reflectionFee,
            totalFee: _liquidityFee + _treasuryFee
        });
    } 

    function setMaxFees(uint16 _totalFee) external onlyOwner {
        require(_totalFee <= MaxFees.totalFee);
        MaxFees.totalFee = _totalFee;
    }

    function FeesEnabled(bool _enabled) external onlyOwner {
        feeEnabled = _enabled;
        emit AreFeesEnabled(_enabled);
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _treasuryFeeReceiver) public onlyOwner {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
        emit FeeReceiversUpdated(_autoLiquidityReceiver, _treasuryFeeReceiver);
    }

    function setCooldownEnabled(bool buy, bool sell, uint8 _cooldown) external authorized {
        require(_cooldown <= cooldownInfo.cooldownLimit);
        cooldownInfo.cooldownTime = _cooldown;
        cooldownInfo.buycooldownEnabled = buy;
        cooldownInfo.sellcooldownEnabled = sell;
    }

    function setSwapBackSettings(bool _enabled, uint256 _amount) external authorized{
        LiquiditySettings.swapEnabled = _enabled;
        LiquiditySettings.numTokensToSwap = (_totalSupply * (_amount)) / (10000);
        emit SwapBackSettingsUpdated(_enabled, _amount);
    }

   function setAutoLiquifyEnabled(bool _enabled) public authorized {
        LiquiditySettings.autoLiquifyEnabled = _enabled;
        emit AutoLiquifyUpdated(_enabled);
    }

    function setDistributionCriteria(uint256 _minPeriod, uint256 _minDistribution, uint256 _minHoldReq) external authorized {
        distributor.setDistributionCriteria(
            _minPeriod,
            _minDistribution,
            _minHoldReq
        );
    }

    function setDistributorSettings(uint32 gas, bool _autoClaim) external authorized {
        require(gas <= 1000000);
        distributorGas = gas;
        autoClaimEnabled = _autoClaim;
        emit DistributorSettingsUpdated(gas, _autoClaim);
    }

    // =============================================================
    //                      INTERNAL OPERATIONS
    // =============================================================
    function approveMax(address sender, address spender, uint256 amount) private {
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function limits(address from, address to) private view returns (bool) {
        return !isOwner(from)
            && !isOwner(to)
            && tx.origin != owner
            && !isAuthorized(from)
            && !isAuthorized(to)
            && !lpHolder[from]
            && !lpHolder[to]
            && to != address(0xdead)
            && to != address(0)
            && from != address(this);
    }

    function _transferFrom(address sender, address recipient, uint256 amount ) internal returns (bool) {
        if (LiquiditySettings.inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }
        require(!bannedUsers[sender]);
        require(!bannedUsers[recipient]);
        if(limits(sender, recipient)){
            if(!Launch.tradingOpen) checkLaunched(sender);
            if(Launch.tradingOpen && TransactionSettings.txLimits){
                if(!maxWalletExempt[recipient]){
                    require(amount <= TransactionSettings.maxTxAmount && balanceOf(recipient) + amount <= TransactionSettings.maxWalletAmount, "TOKEN: Amount exceeds Transaction size");
                }
                if (lpPairs[sender] && recipient != address(router) && !isFeeExempt[recipient] && cooldownInfo.buycooldownEnabled) {
                    require(cooldown[recipient] < block.timestamp);
                    cooldown[recipient] = block.timestamp + (cooldownInfo.cooldownTime);
                } else if (!lpPairs[sender] && !isFeeExempt[sender] && cooldownInfo.sellcooldownEnabled){
                    require(cooldown[sender] <= block.timestamp);
                    cooldown[sender] = block.timestamp + (cooldownInfo.cooldownTime);
                } 

                if(Launch.tradingOpen && Launch.launchProtection){
                    setBlacklistStatus(recipient);
                }
            }
        }

        if (shouldSwapBack()) {
            swapBack();
        }

        if(Launch.tradingOpen && autoClaimEnabled){
            try distributor.process(distributorGas) {} catch {}
        }

        uint256 amountReceived = shouldTakeFee(sender) ? takeFee(sender, recipient, amount) : amount;
        _basicTransfer(sender, recipient, amountReceived);

        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amount;
        emit Transfer(sender, recipient, amount);
        if (!isDividendExempt[sender]) {
            try distributor.setShare(sender, _balances[sender]) {} catch {}
        }
        if (!isDividendExempt[recipient]) {
            try distributor.setShare(recipient, _balances[recipient]){} catch {}
        }
        return true;
    }

    function checkLaunched(address sender) internal view {
        require(Launch.tradingOpen || isAuthorized(sender), "Pre-Launch Protection");
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return feeEnabled && !isFeeExempt[sender];
    }

    function takeFee(address sender, address receiver, uint256 amount) internal returns (uint256) {
        if (isFeeExempt[receiver]) {
            return amount;
        }
        if(block.timestamp >= Launch.launchedAt + 24 hours && Launch.earlySellFee){
            SellFees = IFees({
                liquidityFee: 2,
                treasuryFee: 5,
                reflectionFee: 3,
                totalFee: 2 + 5 + 3
            });
            Launch.earlySellFee = false;
        }
        if(lpPairs[receiver]) {            
            totalFee = SellFees.totalFee;         
        } else if(lpPairs[sender]){
            totalFee = BuyFees.totalFee;
        } else {
            totalFee = TransferFees.totalFee;
        }

        if(block.number == Launch.launchBlock){
            totalFee = 99;
        }
        feeAmount = (amount * totalFee) / feeDenominator;

        if (LiquiditySettings.autoLiquifyEnabled) {
            liquidityAmount = (feeAmount * (BuyFees.liquidityFee + SellFees.liquidityFee)) / ((BuyFees.totalFee + SellFees.totalFee) + (BuyFees.liquidityFee + SellFees.liquidityFee));
            if(block.number == Launch.launchBlock) liquidityAmount = feeAmount;
            LiquiditySettings.liquidityFeeAccumulator += liquidityAmount;
        }
        _basicTransfer(sender, address(this), feeAmount); 
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        return
            !lpPairs[_msgSender()] &&
            !LiquiditySettings.inSwap &&
            LiquiditySettings.swapEnabled &&
            block.timestamp >= LiquiditySettings.lastSwap + LiquiditySettings.swapInterval &&
            _balances[address(this)] >= LiquiditySettings.numTokensToSwap;
    }
 
    function swapBack() internal swapping {
        LiquiditySettings.lastSwap = block.timestamp;
        if (LiquiditySettings.liquidityFeeAccumulator >= LiquiditySettings.numTokensToSwap && LiquiditySettings.autoLiquifyEnabled) {
            LiquiditySettings.liquidityFeeAccumulator -= LiquiditySettings.numTokensToSwap;
            uint256 amountToLiquify = LiquiditySettings.numTokensToSwap / 2;

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                amountToLiquify,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountEth = address(this).balance - (balanceBefore);

            router.addLiquidityETH{value: amountEth}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );

            emit AutoLiquify(amountEth, amountToLiquify);
        } else {
            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = router.WETH();

            uint256 balanceBefore = address(this).balance;

            router.swapExactTokensForETHSupportingFeeOnTransferTokens(
                LiquiditySettings.numTokensToSwap,
                0,
                path,
                address(this),
                block.timestamp
            );

            uint256 amountEth = address(this).balance - (balanceBefore);

            uint256 amountEthTreasury = (amountEth *
                (BuyFees.treasuryFee + SellFees.treasuryFee)) /
                (BuyFees.totalFee + SellFees.totalFee);

            uint256 amountEthReflection = (amountEth *
                (BuyFees.reflectionFee + SellFees.reflectionFee)) /
                (BuyFees.totalFee + SellFees.totalFee);

            if(fundRewards) {
                try distributor.deposit{value: amountEthReflection}() {} catch {}
                (bool treasury, ) = payable(treasuryFeeReceiver).call{ value: amountEthTreasury, gas: 30000}("");
                if(treasury) treasuryFees += amountEthTreasury;
            } else {
                (bool treasury, ) = payable(treasuryFeeReceiver).call{ value: amountEthTreasury, gas: 30000}("");
                if(treasury) treasuryFees += amountEthTreasury;
            }

            emit SwapBack(LiquiditySettings.numTokensToSwap, amountEth);
        }
    }

    function setBlacklistStatus(address account) internal {
        Launch.launchBlock + Launch.sniperBlocks > block.number 
        ? _setBlacklistStatus(account, true)
        : turnOff();
        if(Launch.launchProtection){
            Launch.snipersCaught++;
            isDividendExempt[account] = true;
        }
    }

    function turnOff() internal {
        Launch.launchProtection = false;
    }

    function _setBlacklistStatus(address account, bool blacklisted) internal {
        if (blacklisted) {
            bannedUsers[account] = true;
        } else {
            bannedUsers[account] = false;
        }           
    }

    // =============================================================
    //                      EXTERNAL OPERATIONS
    // =============================================================

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function getOwner() external view override returns (address) {
        return owner;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function allowance(address holder, address spender) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) external override returns (bool){
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function getAccumulatedFees() external view returns (uint256 collectedFees, uint256 currentBalance) {
        collectedFees = treasuryFees;
        currentBalance = treasuryFeeReceiver.balance;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function processDividends(uint256 gas) external {
        if(gas == 0) gas = distributorGas;
        try distributor.process(gas) {} catch {}
    }

    function getShareholderInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return distributor.getShareholderInfo(shareholder);
    }

    function getAccountInfo(address shareholder) external view returns (uint256, uint256, uint256, uint256) {
        return distributor.getAccountInfo(shareholder);
    }

    function holdReq() external view returns(uint256) {
        return distributor.holdReq();
    }

    function claimDividendFor(address shareholder) external {
        distributor.claimDividendFor(shareholder);
    }

    function claimDividend() external {
        distributor.claimDividendFor(msg.sender);
    }

    event AreFeesEnabled(bool enabled);
    event Authorized(address adr);
    event AutoLiquify(uint256 amountEth, uint256 amountToken);
    event AutoLiquifyUpdated(bool enabled);
    event DistributorSettingsUpdated(uint256 gas, bool _autoClaim);
    event DividendExemptUpdated(address holder, bool exempt);
    event FeeExemptUpdated(address holder, bool exempt);
    event FeeReceiversUpdated(address autoLiquidityReceiver, address treasuryFeeReceiver);
    event Launched();
    event OwnershipRenounced();
    event OwnershipTransferred(address owner);
    event SwapBack(uint256 amountToken, uint256 amountEth);
    event SwapBackSettingsUpdated(bool enabled, uint256 amount);
    event TxLimitExemptUpdated(address holder, bool exempt);
    event TxLimitUpdated(uint256 amount);
    event Unauthorized(address adr);
    event WalletLimitUpdated(uint256 amount);
    event WalletBanStatusUpdated(address user, bool banned);
}