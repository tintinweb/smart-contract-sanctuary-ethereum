/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: contracts/libraries/SafeMath.sol

pragma solidity >=0.5.16;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

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

// File: contracts/libraries/UniswapV2Library.sol

pragma solidity >=0.5.0;



library UniswapV2Library {
    using SafeMath for uint;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, 'UniswapV2Library: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), 'UniswapV2Library: ZERO_ADDRESS');
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(address factory, address tokenA, address tokenB) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(uint(keccak256(abi.encodePacked(
                hex'ff',
                factory,
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f' // init code hash
            ))));
    }

    // fetches and sorts the reserves for a pair
    function getReserves(address factory, address tokenA, address tokenB) internal view returns (uint reserveA, uint reserveB) {
        (address token0,) = sortTokens(tokenA, tokenB);
        (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(uint amountA, uint reserveA, uint reserveB) internal pure returns (uint amountB) {
        require(amountA > 0, 'UniswapV2Library: INSUFFICIENT_AMOUNT');
        require(reserveA > 0 && reserveB > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) internal pure returns (uint amountIn) {
        require(amountOut > 0, 'UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint numerator = reserveIn.mul(amountOut).mul(1000);
        uint denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(address factory, uint amountIn, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[0] = amountIn;
        for (uint i; i < path.length - 1; i++) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i], path[i + 1]);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(address factory, uint amountOut, address[] memory path) internal view returns (uint[] memory amounts) {
        require(path.length >= 2, 'UniswapV2Library: INVALID_PATH');
        amounts = new uint[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint i = path.length - 1; i > 0; i--) {
            (uint reserveIn, uint reserveOut) = getReserves(factory, path[i - 1], path[i]);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// File: contracts/modules/Ownable.sol

pragma solidity 0.6.6;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/genesisOracle/GenesisOracleData.sol

pragma solidity =0.6.6;

contract GenesisOracleData {
    uint256[] btcDayPrices = [4983365243674,5001842179037,4667669736646,4715811054168,4486804898274,4763907216303,4863665291713,5042959279160,4943283482079,4775319429103,4838441519585,5020233796002,5078834130199,5396342519788,5537220290450,5628948644752,5685437755098,5877255502877,6042688825790,5754570996402,5537388743274,5617378281023,5845891004381,5828169778556,5879131132148,5731480024418,5680542968115,5472078686450,5518067577896,5219135064552,5326244241425,5520380591888,5584994890968,5692449857237,5837561916861,5876634584632,5894205395260,5934300903174,5892711103764,5774058790767,5809706339991,5847102892340,5699997282521,5720140140416,5822875258153,5985799422635,5979146880185,6011794397901,6215922039443,6341003579358,6287942569369,6171580196906,6130073443769,5606705649847,5635238206200,5549414128218,5539293856585,5379944436014,4988781369661,5020691403785,4981085586194,5312035011150,5469829108871,5487328852099,5395503173232,5535539019291,5785864140789,5697571031844,5801717680441,5542058698598,5595159941115,5708422199679,5695002848623,5863714962049,5805500605416,5782055875548,5592613764551,5604788048538,4988170841750,5025687008933,4893422649640,4781404856991,4439026522109,4424388779231,3914786380987,3986522571386,3916130311743,3754368292443,3509516582538,3710586570822,3841925735816,3930482471918,3885187522005,3666617795717,3530104919951,3551420384025,3617583457190,3662851551843,3728536948339,3853499012919,3712365424936,3662689245694,3599554673990,3591740499704,3291442033615,3486786760712,3701575050668,3701120784215,3577977038981,3639796683216,3964907087737,4019817804598,3945486463586,3861445354831,3704994327836,3578497528552,3515887684548,3323663431666,3205945871256,3374216281117,3373765531130,3340217029312,3153823517521,3304820836665,3447087125815,3550560714325,3500452982887,3380583740306,3330736347513,3435380535130,3501841746227,3411509928652,3417631006102,3457446685010,3290135785980,3316399692436,3370091358281,3379893684850,3370567383898,3286088680666,3250131082134,3212341177928,3176745107766,3157874912803,3178042561148,3120270836891,2986037787622,3120567826458,3215283869914,3249948428880,3389148483062,3441656355540,3820419230135,3762057659816,3975943492714,3992449634569,3960097665087,4157050373693,4150497908070,3963680374091,3849226989581,3957315434377,4009051741314,4135603606220,4353599692013,4432737573811,4489718500051,4561863839475,4611416475740,4499461198074,4621818326720,4713632067774,4644876256668,4695348013161,4598652284311,4515468866976,4522690765616,4779202120833,4906188059492,4890862485510,4990046956359,4892378211661,4827822871620,4737555646431,4774331484116,4889852086967,4866004238410,4809561953436,4732392176648,4768831138449,4965540807369,4990576240379,5007711885268,5034611419727,5178075763932,5001181358476,4633134006773,4643750392195,4595392292260,4538768302641,4564937521016,4482613239020,4605616594366,4758965431713,4791243800779,4759301388886,4824262381486,4774879455726,4467133071289,4247974634748,4256798095210,4410181283232,4315612236921,4260493973576,4282223300225,4354099322576,4194964879101,4183386090132,4326102790830,4604729860226,4783643875057,4801112085247,4818251730244,5010952591501,5296253483019,5442494516981,5454392865047,5480833455358,5521332952058,5670627434515,5664255166663,5605236406735,5763864841572,5986312434699,6126476028419,6084031906304,6178993706818,6272416591742,6494744146002,6435571038678,6218915391874,6111463177144,6074690301686,6261590047651,6232398332102,5954150730090,6033275256875,6163782239049,6163775544118,6114032318306,6130586330826,6254555055952,6287698317539,6191805781993,6160003950875,6107057379976,6219297882248,6581622666903,6757188431267,6693847446469,6502192116544,6429434052453,6414731206940,6460109825306,6518825254274,6095194202252,6000384289989,5911843602926,5729999374617,5877744409695,5927544680281,5746570819295,5688896169103,5680636387569,5813774639293,5627574356291,5543052827571,5470759659736,5758678046448,5735009766764,5740516693256,5679847945955,5600761428522,4919305375343,4923002176770,4887571376951,5111162933760,5042926601987,4910027814659,4833616758891,4854167755035,4971691992817,4833757431609,4728622685077,4820261139194,4862244173924,4713501128777,4671570470549,4727113775774,4664882388229,4831233178552,4872962318506,4919460737387,5115447927927,5096703668291,5030081163834,5118132618833,4899501452812,4767510269082,4716214392246,4731630970019,4714727555556,4734693914698,4691999636274,4655372821839,4599950975746,4319781032072,4215680024705,4176773439506,4202794015725,4171296839306,4227170189700,4325618260590,4346137873753,4280253044492,4322462650655,4319026891368,4262434010992,4201341468700,4198220669713,4227734056875,3876802194169,3561505760435,3553584375937,3518482322768,3658576104177,3759328629030,3644372778062,3719533378569,3793638962730,3803300444479,3763914341178,3861869851271,3811006031075,3687075179031,3870710370560,4154270841013,4164177605631,4315550004181,4393822600517,4401032262705,4441087181984,4326055947938,4242394044677,4246333879281,4232892211232,4393885636815,4404759389010,4270524488625,4048606716418,4015182991925,3886156912286,3855660294426,3736661382410,3820472196476,3618184025344,3886437192359,3927083333355,3877954410643];
    uint256 btcDaySartTime = 1614124800000;
}

// File: contracts/genesisOracle/SlideWndOracle.sol

pragma solidity =0.6.6;

//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
//import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
//import '@uniswap/lib/contracts/libraries/FixedPoint.sol';


//import '../libraries/UniswapV2OracleLibrary.sol';



// sliding window oracle that uses observations collected over a window to provide moving price averages in the past
// `windowSize` with a precision of `windowSize / granularity`
// note this is a singleton oracle and only needs to be deployed once per desired parameters, which
// differs from the simple oracle which must be deployed once per pair.
contract GenesisOracle is Ownable,GenesisOracleData {
   // using FixedPoint for *;
    using SafeMath for uint;
    struct Observation {
        uint timestamp;
        uint price0;
    }

    // the desired amount of time over which the moving average should be computed, e.g. 24 hours
    uint256 public windowSize = 86400;//one day
    // the number of observations stored for each pair, i.e. how many price observations are stored for the window.
    // as granularity increases from 1, more frequent updates are needed, but moving averages become more precise.
    // averages are computed over intervals with sizes in the range:
    //   [windowSize - (windowSize / granularity) * 2, windowSize]
    // e.g. if the window size is 24 hours, and the granularity is 24, the oracle will return the average price for
    //   the period:
    //   [now - [22 hours, 24 hours], now]
    uint256 public granularity = 24;//24 times
    // this is redundant with granularity and windowSize, but stored for gas savings & informational purposes.
    uint256 public periodSize = windowSize/ granularity;

    address public uniFactory = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address public susiFactory = 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac;

    address public uniWbtcUsdtLp =  0x004375Dff511095CC5A197A54140a24eFEF3A416;//lp
    address public wbtc = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;//wbtc
    //address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;//usdt
    address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;//wbtc

    address public btch = address(0);//btch
    address public susiWbtcUsdtLp = 0x784178D58b641a4FebF8D477a6ABd28504273132;//lp
    address public susiBtchWbtcLp = address(0);

    uint256 public btcDecimal = 1e8;
    uint256 public usdcDecimal = 1e6;
    uint256 public btchDecimal = 1e9;

    uint256 public priceDecimal = 1e8;

    uint256 public daySeconds = 86400;

    uint256 public lastUpdateTime;
    //tokenAddress=>dayIdx(timeStamp/86400)=>price
    //WBTC/USDT, BTCH/WBTC两种币对，
    //WBTC/USDT需要365，24，实时, UNI
    //BTCH/WBTC需要24， 实时，SUSHI
    mapping(uint256=>uint256) public sushiBtchDayPrice;
    mapping(uint256=>uint256) public uiniAvgBtcDayPrice;
    mapping(address =>mapping(uint256=>Observation)) public pairObservations;

    event SetBtcAvg24Price(address indexed from,uint256 avgPrice,uint256 periodIdx);
    event BtchAvg24Price(address indexed from,uint256 avgPrice,uint256 periodIdx);

    constructor() public {
        uint256 idx = btcDaySartTime/daySeconds;
        for(uint256 i=0;i<btcDayPrices.length;i++){
            uiniAvgBtcDayPrice[idx++] = btcDayPrices[i];
        }
    }

    function setTimeWndGranularity(uint windowSize_, uint8 granularity_)  external onlyOwner {
        require(granularity_ > 1, 'SlidingWindowOracle: GRANULARITY');
        require(
        (periodSize = windowSize_ / granularity_) * granularity_ == windowSize_,
        'SlidingWindowOracle: WINDOW_NOT_EVENLY_DIVISIBLE'
        );
        windowSize = windowSize_;
        granularity = granularity_;
    }

    function setFactoryAddress(address uniFactory_,address susiFactory_) external onlyOwner{
        uniFactory = uniFactory_;
        susiFactory = susiFactory_;
    }

    function initBtch(address btch_,uint256 btchDecimal_) external onlyOwner{
        btch = btch_;
        btchDecimal = btchDecimal_;
    }

    function setBtc(address wbtc_,uint256 btcDecimal_) external onlyOwner{
        wbtc = wbtc_;
        btcDecimal = btcDecimal_;
    }

    function setUsdc(address usdc_,uint256 usdcDecimal_) external onlyOwner{
        usdc = usdc_;
        usdcDecimal = usdcDecimal_;
    }

    function setBtchDayPrice(uint256[] calldata timestamps,uint256[] calldata dayprices) external onlyOwner{
        require(timestamps.length==dayprices.length,"array length is not equal!");
        uint256 i=0;
        for(;i<timestamps.length;i++) {
            uint256 dayidx = timestamps[i]/daySeconds;
            sushiBtchDayPrice[dayidx] = dayprices[i];
        }
    }

    //btch realtime price in wbtc
    function getBTCHBTC() public view returns(uint256){
        (uint256 btchReserve/*reserveA*/,uint256 wbtcReserve/*reserveB*/)= UniswapV2Library.getReserves(susiFactory, btch/*tokenA*/, wbtc/*tokenB*/);
        if(btchReserve==0) {
            return 0;
        }
        return UniswapV2Library.getAmountOut(btchDecimal,btchReserve,wbtcReserve);
    }

    //btch avg price(24 hours) in wbtc
    function getBTCHBTC24() public view returns(uint256){
        uint256 idx = block.timestamp/periodSize;
        uint256 price = 0;
        uint256 i = idx - daySeconds/periodSize;
        uint256 idxcnt = 0;

        for(;i<=idx;i++) {
            if( pairObservations[btch][i].price0>0) {
                price = price.add(pairObservations[btch][i].price0);
                idxcnt++;
            }
        }

        if(idxcnt>0) {
            price = price/idxcnt;
        }

        return price;
    }

    //btch realtime price in wbtc
    function getBTCUSDC() public view returns(uint256){
        (uint256 btcReserve/*reserveA*/,uint256 usdcReserve/*reserveB*/)= UniswapV2Library.getReserves(susiFactory, wbtc/*tokenA*/, usdc/*tokenB*/);
        if(btcReserve==0) {
            return 0;
        }
        return UniswapV2Library.getAmountOut(btcDecimal,btcReserve,usdcReserve);
    }

    //btc avg price(24 hours) in wbtc
    function getBTCUSDC24() public view returns(uint256){
        uint256 idx = block.timestamp/periodSize;
        uint256 price = 0;
        uint256 i = idx - daySeconds/periodSize;
        uint256 idxcnt = 0;
        for(;i<=idx;i++) {
            if( pairObservations[wbtc][i].price0>0) {
                price = price.add(pairObservations[wbtc][i].price0);
                idxcnt++;
            }
        }
        if(idxcnt>0) {
            price = price/idxcnt;
        }
        return price;
    }

    function getBTCUSDC365() external view returns(uint256) {
       return caluiniAvgBtc365Price();
    }

    function needUpdate() public view returns (bool) {
        uint256 idx = block.timestamp/periodSize;
        bool timeupdate = (block.timestamp-lastUpdateTime)>(periodSize/2);
        bool uniupdate = (pairObservations[wbtc][idx].timestamp==0);
        bool susiupdate = (pairObservations[btch][idx].timestamp==0);
        return (uniupdate&&susiupdate&&timeupdate);
    }

    function update() external {
        //will return if is not over periodSize/2
        if((block.timestamp-lastUpdateTime)<(periodSize/2)) {
            return;
        }
        //update observation for uni btc day price
        updateOberverVation();
        //caculate day price for btc2usdt
        calDayPrice();

        lastUpdateTime = block.timestamp;
    }

    // update the cumulative price for the observation at the current timestamp. each observation is updated at most
    // once per epoch period.
    function updateOberverVation() private {
        uint256 idx = block.timestamp/periodSize;
        uint256 price = 0;
        if(pairObservations[wbtc][idx].timestamp==0) {
            price = getBTCUSDC();
            pairObservations[wbtc][idx] = Observation(block.timestamp,price);
            emit SetBtcAvg24Price(msg.sender,price,idx);
        }

        if(pairObservations[btch][idx].timestamp==0) {
            price = getBTCHBTC();
            pairObservations[btch][idx] = Observation(block.timestamp,price);
            emit BtchAvg24Price(msg.sender,price,idx);
        }
    }

    function calDayPrice() private {
        uint256 dayidx =  block.timestamp/daySeconds;
        uiniAvgBtcDayPrice[dayidx] = getBTCUSDC24();
        sushiBtchDayPrice[dayidx] = getBTCHBTC24();
    }

    function caluiniAvgBtc365Price() private view returns (uint256){
        uint256 dayidx = block.timestamp/daySeconds;
        //if already caculated or day price is not caculated,return
        uint256 daycnt = 0;
        uint256 total = 0;
        uint256 i = dayidx-364;
        for(;i<=dayidx;i++) {
            if(uiniAvgBtcDayPrice[i]!=0) {
                daycnt++;
                total = total.add(uiniAvgBtcDayPrice[i]);
            }
        }

        if(daycnt>0) {
            return total/daycnt;
        } else {
            return 0;
        }
    }
}