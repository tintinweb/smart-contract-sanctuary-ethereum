// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";
import "./interfaces/IBanana.sol";
import "./interfaces/IBananaDistributor.sol";
import "./interfaces/ITWAMM.sol";
import "./interfaces/ITWAMMPair.sol";
import "../utils/Ownable.sol";
import "../utils/AnalyticMath.sol";
import "../libraries/FullMath.sol";
import "../libraries/TransferHelper.sol";

contract BuybackPool is Ownable, AnalyticMath {
    using FullMath for uint256;

    address public banana;
    address public usdc;
    address public twamm;
    address public bananaDistributor;

    uint256 public lastBuyingRate;
    uint256 public priceT1;
    uint256 public priceT2;
    uint256 public rewardT1;
    uint256 public rewardT2;
    uint256 public priceIndex = 100;
    uint256 public rewardIndex = 50;
    uint256 public secondsPerBlock = 12;
    uint256 public secondsOfEpoch = 604800; // seconds of one week, minus  7*24*3600=604800
    uint256 public lastOrderId;
    uint256 public lastExecuteTime;
    
    bool public isStop;

    constructor(
        address banana_, 
        address usdc_,
        address twamm_,
        address bananaDistributor_,
        uint256 initBuyingRate,
        uint256 startTime
    ) {
        owner = msg.sender;
        banana = banana_;
        usdc = usdc_;
        twamm = twamm_;
        bananaDistributor = bananaDistributor_;
        lastBuyingRate = initBuyingRate;
        lastExecuteTime = startTime;
    }

    function updatePriceIndex(uint256 newPriceIndex) external onlyOwner {
        priceIndex = newPriceIndex;
    }

    function updateRewardIndex(uint256 newRewardIndex) external onlyOwner {
        rewardIndex = newRewardIndex;
    }

    function updateSecondsPerBlock(uint256 newSecondsPerBlock) external onlyOwner {
        secondsPerBlock = newSecondsPerBlock;
    }

    function updateSecondsOfEpoch(uint256 newSecondsOfEpoch) external onlyOwner {
        secondsOfEpoch = newSecondsOfEpoch;
    }

    function updateStatus(bool isStop_) external onlyOwner {
        isStop = isStop_;
    }

    function withdraw(address to) external onlyOwner {
        require(isStop, "not stop");
        address pair = ITWAMM(twamm).obtainPairAddress(usdc, banana);
        ITWAMMPair.Order memory order = ITWAMMPair(pair).getOrderDetails(lastOrderId);
        require(block.number > order.expirationBlock, "not reach withdrawable block");
        ITWAMM(twamm).withdrawProceedsFromTermSwapTokenToToken(usdc, banana, lastOrderId, block.timestamp);
        uint256 bananaBalance = IERC20(banana).balanceOf(address(this));
        IBanana(banana).burn(address(this), bananaBalance);

        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        TransferHelper.safeTransfer(usdc, to, usdcBalance);
    }

    function execute() external {
        require(!isStop, "is stop");
        lastExecuteTime = lastExecuteTime + secondsOfEpoch;
        require(block.timestamp >= lastExecuteTime, "not reach execute time");
        
        if (lastOrderId > 0) {
            address pair = ITWAMM(twamm).obtainPairAddress(usdc, banana);
            ITWAMMPair.Order memory order = ITWAMMPair(pair).getOrderDetails(lastOrderId);
            require(block.number > order.expirationBlock, "not reach withdrawable block");

            ITWAMM(twamm).withdrawProceedsFromTermSwapTokenToToken(usdc, banana, lastOrderId, block.timestamp);
            uint256 bananaBalance = IERC20(banana).balanceOf(address(this));
            IBanana(banana).burn(address(this), bananaBalance);
        }
        
        if (priceT1 > 0 && priceT2 > 0 && rewardT1 > 0 && rewardT2 > 0) {
            (uint256 pn, uint256 pd) = pow(priceT2, priceT1, priceIndex, 100);
            (uint256 rn, uint256 rd) = pow(rewardT1, rewardT2, rewardIndex, 100);
            lastBuyingRate = lastBuyingRate.mulDiv(pn, pd).mulDiv(rn, rd);
        } 
        
        require(lastExecuteTime + secondsOfEpoch > block.timestamp, "over next opech time");
        uint256 intervalBlocks = (lastExecuteTime + secondsOfEpoch - block.timestamp) / secondsPerBlock;
        uint256 amountIn = intervalBlocks * lastBuyingRate * secondsPerBlock;
        uint256 usdcBalance = IERC20(usdc).balanceOf(address(this));
        if (amountIn > usdcBalance) {
            amountIn = usdcBalance;
        }
        require(amountIn > 0, "buying amount is 0");
        IERC20(usdc).approve(twamm, amountIn);
        lastOrderId = ITWAMM(twamm).longTermSwapTokenToToken(usdc, banana, amountIn, intervalBlocks / 5, block.timestamp);
        
        uint256 lastReward = IBananaDistributor(bananaDistributor).lastReward();
        rewardT2 = rewardT1;
        rewardT1 = lastReward;

        (uint256 reserve0, uint256 reserve1) = ITWAMM(twamm).obtainReserves(usdc, banana);
        uint256 currentPrice = reserve0.mulDiv(1e18, reserve1);
        priceT2 = priceT1;
        priceT1 = currentPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external pure returns (uint8);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../../interfaces/IERC20.sol";

interface IBanana is IERC20 {
    event RedeemTimeChanged(uint256 oldRedeemTime, uint256 newRedeemTime);
    event Mint(address indexed to, uint256 apeXAmount, uint256 mintAmount);
    event Burn(address indexed from, uint256 amount);
    event Redeem(address indexed user, uint256 burntAmount, uint256 apeXAmount);

    function apeXToken() external view returns (address);
    function redeemTime() external view returns (uint256);

    function mint(address to, uint256 apeXAmount) external returns (uint256);
    function burn(address from, uint256 value) external returns (bool);
    function redeem(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface IBananaDistributor {
    function lastReward() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ITWAMM {
    function factory() external view returns (address);

    function WETH() external view returns (address);

    function obtainReserves(address token0, address token1)
        external
        view
        returns (uint256 reserve0, uint256 reserve1);

    function obtainTotalSupply(address pair) external view returns (uint256);

    function obtainPairAddress(address token0, address token1)
        external
        view
        returns (address);

    function createPairWrapper(
        address token0,
        address token1,
        uint256 deadline
    ) external returns (address pair);

    function addInitialLiquidity(
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        uint256 deadline
    ) external returns (uint256 lpTokenAmount);

    function addInitialLiquidityETH(
        address token,
        uint256 amountToken,
        uint256 amountETH,
        uint256 deadline
    ) external payable returns (uint256 lpTokenAmount);

    function addLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external returns (uint256 amountIn0, uint256 amountIn1);

    function addLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external payable returns (uint256 amountTokenIn, uint256 amountETHIn);

    function withdrawLiquidity(
        address token0,
        address token1,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external returns (uint256 amountOut0, uint256 amountOut1);

    function withdrawLiquidityETH(
        address token,
        uint256 lpTokenAmount,
        uint256 deadline
    ) external returns (uint256 amountTokenOut, uint256 amountETHOut);

    function instantSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline
    ) external returns (uint256 amountOut);

    function instantSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 amountETHOutMin,
        uint256 deadline
    ) external returns (uint256 amountETHOut);

    function instantSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 amountTokenOutMin,
        uint256 deadline
    ) external payable returns (uint256 amountTokenOut);

    function longTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 amountIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external returns (uint256 orderId);

    function longTermSwapTokenToETH(
        address token,
        uint256 amountTokenIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external returns (uint256 orderId);

    function longTermSwapETHToToken(
        address token,
        uint256 amountETHIn,
        uint256 numberOfBlockIntervals,
        uint256 deadline
    ) external payable returns (uint256 orderId);

    function cancelTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function cancelTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function cancelTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 unsoldAmount, uint256 purchasedAmount);

    function withdrawProceedsFromTermSwapTokenToToken(
        address token0,
        address token1,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceeds);

    function withdrawProceedsFromTermSwapTokenToETH(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceeds);

    function withdrawProceedsFromTermSwapETHToToken(
        address token,
        uint256 orderId,
        uint256 deadline
    ) external returns (uint256 proceeds);

    function executeVirtualOrdersWrapper(address pair, uint256 blockNumber)
        external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

interface ITWAMMPair {
    struct Order {
        uint256 id;
        uint256 expirationBlock;
        uint256 saleRate;
        address owner;
        address sellTokenId;
        address buyTokenId;
    }

    function getOrderDetails(uint256 orderId)
        external
        view
        returns (Order memory);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

abstract contract Ownable {
    address public owner;
    address public pendingOwner;

    event NewOwner(address indexed oldOwner, address indexed newOwner);
    event NewPendingOwner(address indexed oldPendingOwner, address indexed newPendingOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: REQUIRE_OWNER");
        _;
    }

    function setPendingOwner(address newPendingOwner) external onlyOwner {
        require(pendingOwner != newPendingOwner, "Ownable: ALREADY_SET");
        emit NewPendingOwner(pendingOwner, newPendingOwner);
        pendingOwner = newPendingOwner;
    }

    function acceptOwner() external {
        require(msg.sender == pendingOwner, "Ownable: REQUIRE_PENDING_OWNER");
        address oldOwner = owner;
        address oldPendingOwner = pendingOwner;
        owner = pendingOwner;
        pendingOwner = address(0);
        emit NewOwner(oldOwner, owner);
        emit NewPendingOwner(oldPendingOwner, pendingOwner);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "../libraries/IntegralMath.sol";

contract AnalyticMath {
    uint8 internal constant MIN_PRECISION = 32;
    uint8 internal constant MAX_PRECISION = 127;

    uint256 internal constant FIXED_1 = 1 << MAX_PRECISION;
    uint256 internal constant FIXED_2 = 2 << MAX_PRECISION;

    // Auto-generated via 'PrintLn2ScalingFactors.py'
    uint256 internal constant LN2_NUMERATOR   = 0x3f80fe03f80fe03f80fe03f80fe03f8;
    uint256 internal constant LN2_DENOMINATOR = 0x5b9de1d10bf4103d647b0955897ba80;

    // Auto-generated via 'PrintOptimalThresholds.py'
    uint256 internal constant OPT_LOG_MAX_VAL = 0x15bf0a8b1457695355fb8ac404e7a79e4;
    uint256 internal constant OPT_EXP_MAX_VAL = 0x800000000000000000000000000000000;

    uint256[MAX_PRECISION + 1] private maxExpArray;

    /**
      * @dev Should be executed either during construction or after construction (if too large for the constructor)
    */
    constructor() {
        initMaxExpArray();
    }

    /**
      * @dev Compute (a / b) ^ (c / d)
    */
    function pow(uint256 a, uint256 b, uint256 c, uint256 d) internal view returns (uint256, uint256) { unchecked {
        if (a >= b)
            return mulDivExp(mulDivLog(FIXED_1, a, b), c, d);
        (uint256 q, uint256 p) = mulDivExp(mulDivLog(FIXED_1, b, a), c, d);
        return (p, q);
    }}

    /**
      * @dev Compute log(a / b)
    */
    function log(uint256 a, uint256 b) internal pure returns (uint256, uint256) { unchecked {
        require(a >= b, "log: a < b");
        return (mulDivLog(FIXED_1, a, b), FIXED_1);
    }}

    /**
      * @dev Compute e ^ (a / b)
    */
    function exp(uint256 a, uint256 b) internal view returns (uint256, uint256) { unchecked {
        return mulDivExp(FIXED_1, a, b);
    }}

    /**
      * @dev Compute log(x / FIXED_1) * FIXED_1
    */
    function fixedLog(uint256 x) internal pure returns (uint256) { unchecked {
        if (x < OPT_LOG_MAX_VAL) {
            return optimalLog(x);
        }
        else {
            return generalLog(x);
        }
    }}

    /**
      * @dev Compute e ^ (x / FIXED_1) * FIXED_1
    */
    function fixedExp(uint256 x) internal view returns (uint256, uint256) { unchecked {
        if (x < OPT_EXP_MAX_VAL) {
            return (optimalExp(x), 1 << MAX_PRECISION);
        }
        else {
            uint8 precision = findPosition(x);
            return (generalExp(x >> (MAX_PRECISION - precision), precision), 1 << precision);
        }
    }}

    /**
      * @dev Compute log(x / FIXED_1) * FIXED_1
      * This functions assumes that x >= FIXED_1, because the output would be negative otherwise
    */
    function generalLog(uint256 x) internal pure returns (uint256) { unchecked {
        uint256 res = 0;

        // if x >= 2, then we compute the integer part of log2(x), which is larger than 0
        if (x >= FIXED_2) {
            uint8 count = IntegralMath.floorLog2(x / FIXED_1);
            x >>= count; // now x < 2
            res = count * FIXED_1;
        }

        // if x > 1, then we compute the fraction part of log2(x), which is larger than 0
        if (x > FIXED_1) {
            for (uint8 i = MAX_PRECISION; i > 0; --i) {
                x = (x * x) / FIXED_1; // now 1 < x < 4
                if (x >= FIXED_2) {
                    x >>= 1; // now 1 < x < 2
                    res += 1 << (i - 1);
                }
            }
        }

        return res * LN2_NUMERATOR / LN2_DENOMINATOR;
    }}

    /**
      * @dev Approximate e ^ x as (x ^ 0) / 0! + (x ^ 1) / 1! + ... + (x ^ n) / n!
      * Auto-generated via 'PrintFunctionGeneralExp.py'
      * Detailed description:
      * - This function returns "e ^ (x / 2 ^ precision) * 2 ^ precision", that is, the result is upshifted for accuracy
      * - The global "maxExpArray" maps each "precision" to "((maximumExponent + 1) << (MAX_PRECISION - precision)) - 1"
      * - The maximum permitted value for "x" is therefore given by "maxExpArray[precision] >> (MAX_PRECISION - precision)"
    */
    function generalExp(uint256 x, uint8 precision) internal pure returns (uint256) { unchecked {
        uint256 xi = x;
        uint256 res = 0;

        xi = (xi * x) >> precision; res += xi * 0x3442c4e6074a82f1797f72ac0000000; // add x^02 * (33! / 02!)
        xi = (xi * x) >> precision; res += xi * 0x116b96f757c380fb287fd0e40000000; // add x^03 * (33! / 03!)
        xi = (xi * x) >> precision; res += xi * 0x045ae5bdd5f0e03eca1ff4390000000; // add x^04 * (33! / 04!)
        xi = (xi * x) >> precision; res += xi * 0x00defabf91302cd95b9ffda50000000; // add x^05 * (33! / 05!)
        xi = (xi * x) >> precision; res += xi * 0x002529ca9832b22439efff9b8000000; // add x^06 * (33! / 06!)
        xi = (xi * x) >> precision; res += xi * 0x00054f1cf12bd04e516b6da88000000; // add x^07 * (33! / 07!)
        xi = (xi * x) >> precision; res += xi * 0x0000a9e39e257a09ca2d6db51000000; // add x^08 * (33! / 08!)
        xi = (xi * x) >> precision; res += xi * 0x000012e066e7b839fa050c309000000; // add x^09 * (33! / 09!)
        xi = (xi * x) >> precision; res += xi * 0x000001e33d7d926c329a1ad1a800000; // add x^10 * (33! / 10!)
        xi = (xi * x) >> precision; res += xi * 0x0000002bee513bdb4a6b19b5f800000; // add x^11 * (33! / 11!)
        xi = (xi * x) >> precision; res += xi * 0x00000003a9316fa79b88eccf2a00000; // add x^12 * (33! / 12!)
        xi = (xi * x) >> precision; res += xi * 0x0000000048177ebe1fa812375200000; // add x^13 * (33! / 13!)
        xi = (xi * x) >> precision; res += xi * 0x0000000005263fe90242dcbacf00000; // add x^14 * (33! / 14!)
        xi = (xi * x) >> precision; res += xi * 0x000000000057e22099c030d94100000; // add x^15 * (33! / 15!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000057e22099c030d9410000; // add x^16 * (33! / 16!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000052b6b54569976310000; // add x^17 * (33! / 17!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000004985f67696bf748000; // add x^18 * (33! / 18!)
        xi = (xi * x) >> precision; res += xi * 0x000000000000003dea12ea99e498000; // add x^19 * (33! / 19!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000000031880f2214b6e000; // add x^20 * (33! / 20!)
        xi = (xi * x) >> precision; res += xi * 0x000000000000000025bcff56eb36000; // add x^21 * (33! / 21!)
        xi = (xi * x) >> precision; res += xi * 0x000000000000000001b722e10ab1000; // add x^22 * (33! / 22!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000001317c70077000; // add x^23 * (33! / 23!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000000000000cba84aafa00; // add x^24 * (33! / 24!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000000000000082573a0a00; // add x^25 * (33! / 25!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000000000000005035ad900; // add x^26 * (33! / 26!)
        xi = (xi * x) >> precision; res += xi * 0x000000000000000000000002f881b00; // add x^27 * (33! / 27!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000000000001b29340; // add x^28 * (33! / 28!)
        xi = (xi * x) >> precision; res += xi * 0x00000000000000000000000000efc40; // add x^29 * (33! / 29!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000000000000007fe0; // add x^30 * (33! / 30!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000000000000000420; // add x^31 * (33! / 31!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000000000000000021; // add x^32 * (33! / 32!)
        xi = (xi * x) >> precision; res += xi * 0x0000000000000000000000000000001; // add x^33 * (33! / 33!)

        return res / 0x688589cc0e9505e2f2fee5580000000 + x + (1 << precision); // divide by 33! and then add x^1 / 1! + x^0 / 0!
    }}

    /**
      * @dev Compute log(x / FIXED_1) * FIXED_1
      * Input range: FIXED_1 <= x <= OPT_LOG_MAX_VAL - 1
      * Auto-generated via 'PrintFunctionOptimalLog.py'
      * Detailed description:
      * - Rewrite the input as a product of natural exponents and a single residual r, such that 1 < r < 2
      * - The natural logarithm of each (pre-calculated) exponent is the degree of the exponent
      * - The natural logarithm of r is calculated via Taylor series for log(1 + x), where x = r - 1
      * - The natural logarithm of the input is calculated by summing up the intermediate results above
      * - For example: log(250) = log(e^4 * e^1 * e^0.5 * 1.021692859) = 4 + 1 + 0.5 + log(1 + 0.021692859)
    */
    function optimalLog(uint256 x) internal pure returns (uint256) { unchecked {
        uint256 res = 0;

        uint256 y;
        uint256 z;
        uint256 w;

        if (x >= 0xd3094c70f034de4b96ff7d5b6f99fcd9) {res += 0x40000000000000000000000000000000; x = x * FIXED_1 / 0xd3094c70f034de4b96ff7d5b6f99fcd9;} // add 1 / 2^1
        if (x >= 0xa45af1e1f40c333b3de1db4dd55f29a8) {res += 0x20000000000000000000000000000000; x = x * FIXED_1 / 0xa45af1e1f40c333b3de1db4dd55f29a8;} // add 1 / 2^2
        if (x >= 0x910b022db7ae67ce76b441c27035c6a2) {res += 0x10000000000000000000000000000000; x = x * FIXED_1 / 0x910b022db7ae67ce76b441c27035c6a2;} // add 1 / 2^3
        if (x >= 0x88415abbe9a76bead8d00cf112e4d4a9) {res += 0x08000000000000000000000000000000; x = x * FIXED_1 / 0x88415abbe9a76bead8d00cf112e4d4a9;} // add 1 / 2^4
        if (x >= 0x84102b00893f64c705e841d5d4064bd4) {res += 0x04000000000000000000000000000000; x = x * FIXED_1 / 0x84102b00893f64c705e841d5d4064bd4;} // add 1 / 2^5
        if (x >= 0x8204055aaef1c8bd5c3259f4822735a3) {res += 0x02000000000000000000000000000000; x = x * FIXED_1 / 0x8204055aaef1c8bd5c3259f4822735a3;} // add 1 / 2^6
        if (x >= 0x810100ab00222d861931c15e39b44e9a) {res += 0x01000000000000000000000000000000; x = x * FIXED_1 / 0x810100ab00222d861931c15e39b44e9a;} // add 1 / 2^7
        if (x >= 0x808040155aabbbe9451521693554f734) {res += 0x00800000000000000000000000000000; x = x * FIXED_1 / 0x808040155aabbbe9451521693554f734;} // add 1 / 2^8

        z = y = x - FIXED_1;
        w = y * y / FIXED_1;
        res += z * (0x100000000000000000000000000000000 - y) / 0x100000000000000000000000000000000; z = z * w / FIXED_1; // add y^01 / 01 - y^02 / 02
        res += z * (0x0aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa - y) / 0x200000000000000000000000000000000; z = z * w / FIXED_1; // add y^03 / 03 - y^04 / 04
        res += z * (0x099999999999999999999999999999999 - y) / 0x300000000000000000000000000000000; z = z * w / FIXED_1; // add y^05 / 05 - y^06 / 06
        res += z * (0x092492492492492492492492492492492 - y) / 0x400000000000000000000000000000000; z = z * w / FIXED_1; // add y^07 / 07 - y^08 / 08
        res += z * (0x08e38e38e38e38e38e38e38e38e38e38e - y) / 0x500000000000000000000000000000000; z = z * w / FIXED_1; // add y^09 / 09 - y^10 / 10
        res += z * (0x08ba2e8ba2e8ba2e8ba2e8ba2e8ba2e8b - y) / 0x600000000000000000000000000000000; z = z * w / FIXED_1; // add y^11 / 11 - y^12 / 12
        res += z * (0x089d89d89d89d89d89d89d89d89d89d89 - y) / 0x700000000000000000000000000000000; z = z * w / FIXED_1; // add y^13 / 13 - y^14 / 14
        res += z * (0x088888888888888888888888888888888 - y) / 0x800000000000000000000000000000000;                      // add y^15 / 15 - y^16 / 16

        return res;
    }}

    /**
      * @dev Compute e ^ (x / FIXED_1) * FIXED_1
      * Input range: 0 <= x <= OPT_EXP_MAX_VAL - 1
      * Auto-generated via 'PrintFunctionOptimalExp.py'
      * Detailed description:
      * - Rewrite the input as a sum of binary exponents and a single residual r, as small as possible
      * - The exponentiation of each binary exponent is given (pre-calculated)
      * - The exponentiation of r is calculated via Taylor series for e^x, where x = r
      * - The exponentiation of the input is calculated by multiplying the intermediate results above
      * - For example: e^5.521692859 = e^(4 + 1 + 0.5 + 0.021692859) = e^4 * e^1 * e^0.5 * e^0.021692859
    */
    function optimalExp(uint256 x) internal pure returns (uint256) { unchecked {
        uint256 res = 0;

        uint256 y;
        uint256 z;

        z = y = x % 0x10000000000000000000000000000000; // get the input modulo 2^(-3)
        z = z * y / FIXED_1; res += z * 0x10e1b3be415a0000; // add y^02 * (20! / 02!)
        z = z * y / FIXED_1; res += z * 0x05a0913f6b1e0000; // add y^03 * (20! / 03!)
        z = z * y / FIXED_1; res += z * 0x0168244fdac78000; // add y^04 * (20! / 04!)
        z = z * y / FIXED_1; res += z * 0x004807432bc18000; // add y^05 * (20! / 05!)
        z = z * y / FIXED_1; res += z * 0x000c0135dca04000; // add y^06 * (20! / 06!)
        z = z * y / FIXED_1; res += z * 0x0001b707b1cdc000; // add y^07 * (20! / 07!)
        z = z * y / FIXED_1; res += z * 0x000036e0f639b800; // add y^08 * (20! / 08!)
        z = z * y / FIXED_1; res += z * 0x00000618fee9f800; // add y^09 * (20! / 09!)
        z = z * y / FIXED_1; res += z * 0x0000009c197dcc00; // add y^10 * (20! / 10!)
        z = z * y / FIXED_1; res += z * 0x0000000e30dce400; // add y^11 * (20! / 11!)
        z = z * y / FIXED_1; res += z * 0x000000012ebd1300; // add y^12 * (20! / 12!)
        z = z * y / FIXED_1; res += z * 0x0000000017499f00; // add y^13 * (20! / 13!)
        z = z * y / FIXED_1; res += z * 0x0000000001a9d480; // add y^14 * (20! / 14!)
        z = z * y / FIXED_1; res += z * 0x00000000001c6380; // add y^15 * (20! / 15!)
        z = z * y / FIXED_1; res += z * 0x000000000001c638; // add y^16 * (20! / 16!)
        z = z * y / FIXED_1; res += z * 0x0000000000001ab8; // add y^17 * (20! / 17!)
        z = z * y / FIXED_1; res += z * 0x000000000000017c; // add y^18 * (20! / 18!)
        z = z * y / FIXED_1; res += z * 0x0000000000000014; // add y^19 * (20! / 19!)
        z = z * y / FIXED_1; res += z * 0x0000000000000001; // add y^20 * (20! / 20!)
        res = res / 0x21c3677c82b40000 + y + FIXED_1; // divide by 20! and then add y^1 / 1! + y^0 / 0!

        if ((x & 0x010000000000000000000000000000000) != 0) res = res * 0x1c3d6a24ed82218787d624d3e5eba95f9 / 0x18ebef9eac820ae8682b9793ac6d1e776; // multiply by e^2^(-3)
        if ((x & 0x020000000000000000000000000000000) != 0) res = res * 0x18ebef9eac820ae8682b9793ac6d1e778 / 0x1368b2fc6f9609fe7aceb46aa619baed4; // multiply by e^2^(-2)
        if ((x & 0x040000000000000000000000000000000) != 0) res = res * 0x1368b2fc6f9609fe7aceb46aa619baed5 / 0x0bc5ab1b16779be3575bd8f0520a9f21f; // multiply by e^2^(-1)
        if ((x & 0x080000000000000000000000000000000) != 0) res = res * 0x0bc5ab1b16779be3575bd8f0520a9f21e / 0x0454aaa8efe072e7f6ddbab84b40a55c9; // multiply by e^2^(+0)
        if ((x & 0x100000000000000000000000000000000) != 0) res = res * 0x0454aaa8efe072e7f6ddbab84b40a55c5 / 0x00960aadc109e7a3bf4578099615711ea; // multiply by e^2^(+1)
        if ((x & 0x200000000000000000000000000000000) != 0) res = res * 0x00960aadc109e7a3bf4578099615711d7 / 0x0002bf84208204f5977f9a8cf01fdce3d; // multiply by e^2^(+2)
        if ((x & 0x400000000000000000000000000000000) != 0) res = res * 0x0002bf84208204f5977f9a8cf01fdc307 / 0x0000003c6ab775dd0b95b4cbee7e65d11; // multiply by e^2^(+3)

        return res;
    }}

    /**
      * @dev The global "maxExpArray" is sorted in descending order, and therefore the following statements are equivalent:
      * - This function finds the position of [the smallest value in "maxExpArray" larger than or equal to "x"]
      * - This function finds the highest position of [a value in "maxExpArray" larger than or equal to "x"]
      * This function supports the rational approximation of "(a / b) ^ (c / d)" via "e ^ (log(a / b) * c / d)".
      * The value of "log(a / b)" is represented with an integer slightly smaller than "log(a / b) * 2 ^ precision".
      * The larger "precision" is, the more accurately this value represents the real value.
      * However, the larger "precision" is, the more bits are required in order to store this value.
      * And the exponentiation function, which takes "x" and calculates "e ^ x", is limited to a maximum exponent (a maximum value of "x").
      * This maximum exponent depends on the "precision" used, and it is given by "maxExpArray[precision] >> (MAX_PRECISION - precision)".
      * Hence we need to determine the highest precision which can be used for the given input, before calling the exponentiation function.
      * This allows us to compute the result with maximum accuracy and without exceeding 256 bits in any of the intermediate computations.
    */
    function findPosition(uint256 x) internal view returns (uint8) { unchecked {
        uint8 lo = MIN_PRECISION;
        uint8 hi = MAX_PRECISION;

        while (lo + 1 < hi) {
            uint8 mid = (lo + hi) / 2;
            if (maxExpArray[mid] >= x)
                lo = mid;
            else
                hi = mid;
        }

        if (maxExpArray[hi] >= x)
            return hi;
        if (maxExpArray[lo] >= x)
            return lo;

        revert("findPosition: x > max");
    }}

    /**
      * @dev Initialize internal data structure
      * Auto-generated via 'PrintMaxExpArray.py'
    */
    function initMaxExpArray() internal {
    //  maxExpArray[  0] = 0x6bffffffffffffffffffffffffffffffff;
    //  maxExpArray[  1] = 0x67ffffffffffffffffffffffffffffffff;
    //  maxExpArray[  2] = 0x637fffffffffffffffffffffffffffffff;
    //  maxExpArray[  3] = 0x5f6fffffffffffffffffffffffffffffff;
    //  maxExpArray[  4] = 0x5b77ffffffffffffffffffffffffffffff;
    //  maxExpArray[  5] = 0x57b3ffffffffffffffffffffffffffffff;
    //  maxExpArray[  6] = 0x5419ffffffffffffffffffffffffffffff;
    //  maxExpArray[  7] = 0x50a2ffffffffffffffffffffffffffffff;
    //  maxExpArray[  8] = 0x4d517fffffffffffffffffffffffffffff;
    //  maxExpArray[  9] = 0x4a233fffffffffffffffffffffffffffff;
    //  maxExpArray[ 10] = 0x47165fffffffffffffffffffffffffffff;
    //  maxExpArray[ 11] = 0x4429afffffffffffffffffffffffffffff;
    //  maxExpArray[ 12] = 0x415bc7ffffffffffffffffffffffffffff;
    //  maxExpArray[ 13] = 0x3eab73ffffffffffffffffffffffffffff;
    //  maxExpArray[ 14] = 0x3c1771ffffffffffffffffffffffffffff;
    //  maxExpArray[ 15] = 0x399e96ffffffffffffffffffffffffffff;
    //  maxExpArray[ 16] = 0x373fc47fffffffffffffffffffffffffff;
    //  maxExpArray[ 17] = 0x34f9e8ffffffffffffffffffffffffffff;
    //  maxExpArray[ 18] = 0x32cbfd5fffffffffffffffffffffffffff;
    //  maxExpArray[ 19] = 0x30b5057fffffffffffffffffffffffffff;
    //  maxExpArray[ 20] = 0x2eb40f9fffffffffffffffffffffffffff;
    //  maxExpArray[ 21] = 0x2cc8340fffffffffffffffffffffffffff;
    //  maxExpArray[ 22] = 0x2af09481ffffffffffffffffffffffffff;
    //  maxExpArray[ 23] = 0x292c5bddffffffffffffffffffffffffff;
    //  maxExpArray[ 24] = 0x277abdcdffffffffffffffffffffffffff;
    //  maxExpArray[ 25] = 0x25daf6657fffffffffffffffffffffffff;
    //  maxExpArray[ 26] = 0x244c49c65fffffffffffffffffffffffff;
    //  maxExpArray[ 27] = 0x22ce03cd5fffffffffffffffffffffffff;
    //  maxExpArray[ 28] = 0x215f77c047ffffffffffffffffffffffff;
    //  maxExpArray[ 29] = 0x1fffffffffffffffffffffffffffffffff;
    //  maxExpArray[ 30] = 0x1eaefdbdabffffffffffffffffffffffff;
    //  maxExpArray[ 31] = 0x1d6bd8b2ebffffffffffffffffffffffff;
        maxExpArray[ 32] = 0x1c35fedd14ffffffffffffffffffffffff;
        maxExpArray[ 33] = 0x1b0ce43b323fffffffffffffffffffffff;
        maxExpArray[ 34] = 0x19f0028ec1ffffffffffffffffffffffff;
        maxExpArray[ 35] = 0x18ded91f0e7fffffffffffffffffffffff;
        maxExpArray[ 36] = 0x17d8ec7f0417ffffffffffffffffffffff;
        maxExpArray[ 37] = 0x16ddc6556cdbffffffffffffffffffffff;
        maxExpArray[ 38] = 0x15ecf52776a1ffffffffffffffffffffff;
        maxExpArray[ 39] = 0x15060c256cb2ffffffffffffffffffffff;
        maxExpArray[ 40] = 0x1428a2f98d72ffffffffffffffffffffff;
        maxExpArray[ 41] = 0x13545598e5c23fffffffffffffffffffff;
        maxExpArray[ 42] = 0x1288c4161ce1dfffffffffffffffffffff;
        maxExpArray[ 43] = 0x11c592761c666fffffffffffffffffffff;
        maxExpArray[ 44] = 0x110a688680a757ffffffffffffffffffff;
        maxExpArray[ 45] = 0x1056f1b5bedf77ffffffffffffffffffff;
        maxExpArray[ 46] = 0x0faadceceeff8bffffffffffffffffffff;
        maxExpArray[ 47] = 0x0f05dc6b27edadffffffffffffffffffff;
        maxExpArray[ 48] = 0x0e67a5a25da4107fffffffffffffffffff;
        maxExpArray[ 49] = 0x0dcff115b14eedffffffffffffffffffff;
        maxExpArray[ 50] = 0x0d3e7a392431239fffffffffffffffffff;
        maxExpArray[ 51] = 0x0cb2ff529eb71e4fffffffffffffffffff;
        maxExpArray[ 52] = 0x0c2d415c3db974afffffffffffffffffff;
        maxExpArray[ 53] = 0x0bad03e7d883f69bffffffffffffffffff;
        maxExpArray[ 54] = 0x0b320d03b2c343d5ffffffffffffffffff;
        maxExpArray[ 55] = 0x0abc25204e02828dffffffffffffffffff;
        maxExpArray[ 56] = 0x0a4b16f74ee4bb207fffffffffffffffff;
        maxExpArray[ 57] = 0x09deaf736ac1f569ffffffffffffffffff;
        maxExpArray[ 58] = 0x0976bd9952c7aa957fffffffffffffffff;
        maxExpArray[ 59] = 0x09131271922eaa606fffffffffffffffff;
        maxExpArray[ 60] = 0x08b380f3558668c46fffffffffffffffff;
        maxExpArray[ 61] = 0x0857ddf0117efa215bffffffffffffffff;
        maxExpArray[ 62] = 0x07ffffffffffffffffffffffffffffffff;
        maxExpArray[ 63] = 0x07abbf6f6abb9d087fffffffffffffffff;
        maxExpArray[ 64] = 0x075af62cbac95f7dfa7fffffffffffffff;
        maxExpArray[ 65] = 0x070d7fb7452e187ac13fffffffffffffff;
        maxExpArray[ 66] = 0x06c3390ecc8af379295fffffffffffffff;
        maxExpArray[ 67] = 0x067c00a3b07ffc01fd6fffffffffffffff;
        maxExpArray[ 68] = 0x0637b647c39cbb9d3d27ffffffffffffff;
        maxExpArray[ 69] = 0x05f63b1fc104dbd39587ffffffffffffff;
        maxExpArray[ 70] = 0x05b771955b36e12f7235ffffffffffffff;
        maxExpArray[ 71] = 0x057b3d49dda84556d6f6ffffffffffffff;
        maxExpArray[ 72] = 0x054183095b2c8ececf30ffffffffffffff;
        maxExpArray[ 73] = 0x050a28be635ca2b888f77fffffffffffff;
        maxExpArray[ 74] = 0x04d5156639708c9db33c3fffffffffffff;
        maxExpArray[ 75] = 0x04a23105873875bd52dfdfffffffffffff;
        maxExpArray[ 76] = 0x0471649d87199aa990756fffffffffffff;
        maxExpArray[ 77] = 0x04429a21a029d4c1457cfbffffffffffff;
        maxExpArray[ 78] = 0x0415bc6d6fb7dd71af2cb3ffffffffffff;
        maxExpArray[ 79] = 0x03eab73b3bbfe282243ce1ffffffffffff;
        maxExpArray[ 80] = 0x03c1771ac9fb6b4c18e229ffffffffffff;
        maxExpArray[ 81] = 0x0399e96897690418f785257fffffffffff;
        maxExpArray[ 82] = 0x0373fc456c53bb779bf0ea9fffffffffff;
        maxExpArray[ 83] = 0x034f9e8e490c48e67e6ab8bfffffffffff;
        maxExpArray[ 84] = 0x032cbfd4a7adc790560b3337ffffffffff;
        maxExpArray[ 85] = 0x030b50570f6e5d2acca94613ffffffffff;
        maxExpArray[ 86] = 0x02eb40f9f620fda6b56c2861ffffffffff;
        maxExpArray[ 87] = 0x02cc8340ecb0d0f520a6af58ffffffffff;
        maxExpArray[ 88] = 0x02af09481380a0a35cf1ba02ffffffffff;
        maxExpArray[ 89] = 0x0292c5bdd3b92ec810287b1b3fffffffff;
        maxExpArray[ 90] = 0x0277abdcdab07d5a77ac6d6b9fffffffff;
        maxExpArray[ 91] = 0x025daf6654b1eaa55fd64df5efffffffff;
        maxExpArray[ 92] = 0x0244c49c648baa98192dce88b7ffffffff;
        maxExpArray[ 93] = 0x022ce03cd5619a311b2471268bffffffff;
        maxExpArray[ 94] = 0x0215f77c045fbe885654a44a0fffffffff;
        maxExpArray[ 95] = 0x01ffffffffffffffffffffffffffffffff;
        maxExpArray[ 96] = 0x01eaefdbdaaee7421fc4d3ede5ffffffff;
        maxExpArray[ 97] = 0x01d6bd8b2eb257df7e8ca57b09bfffffff;
        maxExpArray[ 98] = 0x01c35fedd14b861eb0443f7f133fffffff;
        maxExpArray[ 99] = 0x01b0ce43b322bcde4a56e8ada5afffffff;
        maxExpArray[100] = 0x019f0028ec1fff007f5a195a39dfffffff;
        maxExpArray[101] = 0x018ded91f0e72ee74f49b15ba527ffffff;
        maxExpArray[102] = 0x017d8ec7f04136f4e5615fd41a63ffffff;
        maxExpArray[103] = 0x016ddc6556cdb84bdc8d12d22e6fffffff;
        maxExpArray[104] = 0x015ecf52776a1155b5bd8395814f7fffff;
        maxExpArray[105] = 0x015060c256cb23b3b3cc3754cf40ffffff;
        maxExpArray[106] = 0x01428a2f98d728ae223ddab715be3fffff;
        maxExpArray[107] = 0x013545598e5c23276ccf0ede68034fffff;
        maxExpArray[108] = 0x01288c4161ce1d6f54b7f61081194fffff;
        maxExpArray[109] = 0x011c592761c666aa641d5a01a40f17ffff;
        maxExpArray[110] = 0x0110a688680a7530515f3e6e6cfdcdffff;
        maxExpArray[111] = 0x01056f1b5bedf75c6bcb2ce8aed428ffff;
        maxExpArray[112] = 0x00faadceceeff8a0890f3875f008277fff;
        maxExpArray[113] = 0x00f05dc6b27edad306388a600f6ba0bfff;
        maxExpArray[114] = 0x00e67a5a25da41063de1495d5b18cdbfff;
        maxExpArray[115] = 0x00dcff115b14eedde6fc3aa5353f2e4fff;
        maxExpArray[116] = 0x00d3e7a3924312399f9aae2e0f868f8fff;
        maxExpArray[117] = 0x00cb2ff529eb71e41582cccd5a1ee26fff;
        maxExpArray[118] = 0x00c2d415c3db974ab32a51840c0b67edff;
        maxExpArray[119] = 0x00bad03e7d883f69ad5b0a186184e06bff;
        maxExpArray[120] = 0x00b320d03b2c343d4829abd6075f0cc5ff;
        maxExpArray[121] = 0x00abc25204e02828d73c6e80bcdb1a95bf;
        maxExpArray[122] = 0x00a4b16f74ee4bb2040a1ec6c15fbbf2df;
        maxExpArray[123] = 0x009deaf736ac1f569deb1b5ae3f36c130f;
        maxExpArray[124] = 0x00976bd9952c7aa957f5937d790ef65037;
        maxExpArray[125] = 0x009131271922eaa6064b73a22d0bd4f2bf;
        maxExpArray[126] = 0x008b380f3558668c46c91c49a2f8e967b9;
        maxExpArray[127] = 0x00857ddf0117efa215952912839f6473e6;
    }

    // auxiliary function
    function mulDivLog(uint256 x, uint256 y, uint256 z) private pure returns (uint256) {
        return fixedLog(IntegralMath.mulDivF(x, y, z));
    }

    // auxiliary function
    function mulDivExp(uint256 x, uint256 y, uint256 z) private view returns (uint256, uint256) {
        return fixedExp(IntegralMath.mulDivF(x, y, z));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product

        // todo unchecked
        unchecked {
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            uint256 twos = (~denominator + 1) & denominator;
            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }

            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.

            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeApprove: approve failed"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::safeTransfer: transfer failed"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper::transferFrom: transferFrom failed"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper::safeTransferETH: ETH transfer failed");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

library IntegralMath {
    uint256 constant MAX_VAL = type(uint256).max;

    // reverts on overflow
    function safeAdd(uint256 x, uint256 y) internal pure returns (uint256) {
        return x + y;
    }

    // does not revert on overflow
    function unsafeAdd(uint256 x, uint256 y) internal pure returns (uint256) { unchecked {
        return x + y;
    }}

    // does not revert on overflow
    function unsafeSub(uint256 x, uint256 y) internal pure returns (uint256) { unchecked {
        return x - y;
    }}

    // does not revert on overflow
    function unsafeMul(uint256 x, uint256 y) internal pure returns (uint256) { unchecked {
        return x * y;
    }}

    // does not overflow
    function mulModMax(uint256 x, uint256 y) internal pure returns (uint256) { unchecked {
        return mulmod(x, y, MAX_VAL);
    }}

    // does not overflow
    function mulMod(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) { unchecked {
        return mulmod(x, y, z);
    }}
    /**
      * @dev Compute the largest integer smaller than or equal to the binary logarithm of `n`
    */
    function floorLog2(uint256 n) internal pure returns (uint8) { unchecked {
        uint8 res = 0;

        if (n < 256) {
            // at most 8 iterations
            while (n > 1) {
                n >>= 1;
                res += 1;
            }
        }
        else {
            // exactly 8 iterations
            for (uint8 s = 128; s > 0; s >>= 1) {
                if (n >= 1 << s) {
                    n >>= s;
                    res |= s;
                }
            }
        }

        return res;
    }}

    /**
      * @dev Compute the largest integer smaller than or equal to the square root of `n`
    */
    function floorSqrt(uint256 n) internal pure returns (uint256) { unchecked {
        if (n > 0) {
            uint256 x = n / 2 + 1;
            uint256 y = (x + n / x) / 2;
            while (x > y) {
                x = y;
                y = (x + n / x) / 2;
            }
            return x;
        }
        return 0;
    }}

    /**
      * @dev Compute the smallest integer larger than or equal to the square root of `n`
    */
    function ceilSqrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = floorSqrt(n);
        return x ** 2 == n ? x : x + 1;
    }}

    /**
      * @dev Compute the largest integer smaller than or equal to the cubic root of `n`
    */
    function floorCbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = 0;
        for (uint256 y = 1 << 255; y > 0; y >>= 3) {
            x <<= 1;
            uint256 z = 3 * x * (x + 1) + 1;
            if (n / y >= z) {
                n -= y * z;
                x += 1;
            }
        }
        return x;
    }}

    /**
      * @dev Compute the smallest integer larger than or equal to the cubic root of `n`
    */
    function ceilCbrt(uint256 n) internal pure returns (uint256) { unchecked {
        uint256 x = floorCbrt(n);
        return x ** 3 == n ? x : x + 1;
    }}

    /**
      * @dev Compute the nearest integer to the quotient of `n` and `d` (or `n / d`)
    */
    function roundDiv(uint256 n, uint256 d) internal pure returns (uint256) { unchecked {
        return n / d + (n % d) / (d - d / 2);
    }}

    /**
      * @dev Compute the largest integer smaller than or equal to `x * y / z`
    */
    function mulDivF(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) { unchecked {
        (uint256 xyh, uint256 xyl) = mul512(x, y);
        if (xyh == 0) { // `x * y < 2 ^ 256`
            return xyl / z;
        }
        if (xyh < z) { // `x * y / z < 2 ^ 256`
            uint256 m = mulMod(x, y, z);                    // `m = x * y % z`
            (uint256 nh, uint256 nl) = sub512(xyh, xyl, m); // `n = x * y - m` hence `n / z = floor(x * y / z)`
            if (nh == 0) { // `n < 2 ^ 256`
                return nl / z;
            }
            uint256 p = unsafeSub(0, z) & z; // `p` is the largest power of 2 which `z` is divisible by
            uint256 q = div512(nh, nl, p);   // `n` is divisible by `p` because `n` is divisible by `z` and `z` is divisible by `p`
            uint256 r = inv256(z / p);       // `z / p = 1 mod 2` hence `inverse(z / p) = 1 mod 2 ^ 256`
            return unsafeMul(q, r);          // `q * r = (n / p) * inverse(z / p) = n / z`
        }
        revert(); // `x * y / z >= 2 ^ 256`
    }}

    /**
      * @dev Compute the smallest integer larger than or equal to `x * y / z`
    */
    function mulDivC(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) { unchecked {
        uint256 w = mulDivF(x, y, z);
        if (mulMod(x, y, z) > 0)
            return safeAdd(w, 1);
        return w;
    }}

    /**
      * @dev Compute the value of `x * y`
    */
    function mul512(uint256 x, uint256 y) private pure returns (uint256, uint256) { unchecked {
        uint256 p = mulModMax(x, y);
        uint256 q = unsafeMul(x, y);
        if (p >= q)
            return (p - q, q);
        return (unsafeSub(p, q) - 1, q);
    }}

    /**
      * @dev Compute the value of `2 ^ 256 * xh + xl - y`, where `2 ^ 256 * xh + xl >= y`
    */
    function sub512(uint256 xh, uint256 xl, uint256 y) private pure returns (uint256, uint256) { unchecked {
        if (xl >= y)
            return (xh, xl - y);
        return (xh - 1, unsafeSub(xl, y));
    }}

    /**
      * @dev Compute the value of `(2 ^ 256 * xh + xl) / pow2n`, where `xl` is divisible by `pow2n`
    */
    function div512(uint256 xh, uint256 xl, uint256 pow2n) private pure returns (uint256) { unchecked {
        uint256 pow2nInv = unsafeAdd(unsafeSub(0, pow2n) / pow2n, 1); // `1 << (256 - n)`
        return unsafeMul(xh, pow2nInv) | (xl / pow2n); // `(xh << (256 - n)) | (xl >> n)`
    }}

    /**
      * @dev Compute the inverse of `d` modulo `2 ^ 256`, where `d` is congruent to `1` modulo `2`
    */
    function inv256(uint256 d) private pure returns (uint256) { unchecked {
        // approximate the root of `f(x) = 1 / x - d` using the newton–raphson convergence method
        uint256 x = 1;
        for (uint256 i = 0; i < 8; ++i)
            x = unsafeMul(x, unsafeSub(2, unsafeMul(x, d))); // `x = x * (2 - x * d) mod 2 ^ 256`
        return x;
    }}
}