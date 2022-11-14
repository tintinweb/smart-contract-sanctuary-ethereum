// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IOrderHook} from "../interfaces/IOrderHook.sol";
import {IReferralController} from "../interfaces/IReferralController.sol";
import {Side, IPool} from "../interfaces/IPool.sol";
import {IOrderManager, Order, SwapOrder} from "../interfaces/IOrderManager.sol";

contract OrderHook is IOrderHook {
    address public immutable orderManager;
    IReferralController public referralController;

    modifier onlyOrderManager() {
        validateSender();
        _;
    }

    constructor(address _orderManager, address _referralController) {
        require(_orderManager != address(0), "LoyaltyProgramController:invalidAddress");
        require(_referralController != address(0), "LoyaltyProgramController:invalidAddress");
        orderManager = _orderManager;
        referralController = IReferralController(_referralController);
    }

    function postPlaceOrder(uint256 orderId, bytes calldata extradata) external onlyOrderManager {
        Order memory order = IOrderManager(orderManager).orders(orderId);
        address trader = order.owner;
        address referrer = abi.decode(extradata, (address));
        if (referrer != address(0)) {
            referralController.setReferrer(trader, referrer);
        }
    }

    function postPlaceSwapOrder(uint256 swapOrderId, bytes calldata extradata) external onlyOrderManager {
        SwapOrder memory order = IOrderManager(orderManager).swapOrders(swapOrderId);
        address trader = order.owner;
        address referrer = abi.decode(extradata, (address));
        if (referrer != address(0)) {
            referralController.setReferrer(trader, referrer);
        }
    }

    function validateSender() internal view {
        require(msg.sender == orderManager, "PositionHook:!orderManager");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

interface IOrderHook {
    function postPlaceOrder(uint256 orderId, bytes calldata extradata) external;

    function postPlaceSwapOrder(uint256 swapOrderId, bytes calldata extradata) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IPool} from "./IPool.sol";

struct Order {
    IPool pool;
    address owner;
    address indexToken;
    address collateralToken;
    address payToken;
    uint256 expiresAt;
    uint256 submissionBlock;
    uint256 price;
    uint256 executionFee;
    bool triggerAboveThreshold;
}

struct SwapOrder {
    IPool pool;
    address owner;
    address tokenIn;
    address tokenOut;
    uint256 amountIn;
    uint256 minAmountOut;
    uint256 price;
    uint256 executionFee;
}

interface IOrderManager {
    function orders(uint256 id) external view returns (Order memory);

    function swapOrders(uint256 id) external view returns (SwapOrder memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {SignedInt} from "../lib/SignedInt.sol";

enum Side {
    LONG,
    SHORT
}

struct TokenWeight {
    address token;
    uint256 weight;
}

interface IPool {
    function increasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _sizeChanged,
        Side _side
    )
        external;

    function decreasePosition(
        address _account,
        address _indexToken,
        address _collateralToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side,
        address _receiver
    )
        external;

    function liquidatePosition(address _account, address _indexToken, address _collateralToken, Side _side) external;

    function validateToken(address indexToken, address collateralToken, Side side, bool isIncrease)
        external
        view
        returns (bool);

    function swap(address _tokenIn, address _tokenOut, uint256 _minOut, address _to) external;

    function addLiquidity(address _tranche, address _token, uint256 _amountIn, uint256 _minLpAmount, address _to)
        external
        payable;

    // =========== EVENTS ===========
    event SetOrderManager(address orderManager);
    event IncreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralValue,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        uint256 feeValue
    );
    event UpdatePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount,
        uint256 indexPrice
    );
    event DecreasePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        uint256 collateralChanged,
        uint256 sizeChanged,
        Side side,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event ClosePosition(
        bytes32 key,
        uint256 size,
        uint256 collateralValue,
        uint256 entryPrice,
        uint256 entryInterestRate,
        uint256 reserveAmount
    );
    event LiquidatePosition(
        bytes32 key,
        address account,
        address collateralToken,
        address indexToken,
        Side side,
        uint256 size,
        uint256 collateralValue,
        uint256 reserveAmount,
        uint256 indexPrice,
        SignedInt pnl,
        uint256 feeValue
    );
    event DaoFeeWithdrawn(address token, address recipient, uint256 amount);
    event DaoFeeReduced(address token, uint256 amount);
    event FeeDistributorSet(address feeDistributor);
    event LiquidityAdded(
        address indexed tranche, address indexed sender, address token, uint256 amount, uint256 lpAmount, uint256 fee
    );
    event LiquidityRemoved(
        address indexed tranche, address indexed sender, address token, uint256 lpAmount, uint256 amountOut, uint256 fee
    );
    event TokenWeightSet(TokenWeight[]);
    event Swap(address sender, address tokenIn, address tokenOut, uint256 amountIn, uint256 amountOut, uint256 fee);
    event PositionFeeSet(uint256 positionFee, uint256 liquidationFee);
    event DaoFeeSet(uint256 value);
    event SwapFeeSet(
        uint256 baseSwapFee, uint256 taxBasisPoint, uint256 stableCoinBaseSwapFee, uint256 stableCoinTaxBasisPoint
    );
    event InterestAccrued(address token, uint256 borrowIndex);
    event MaxLeverageChanged(uint256 maxLeverage);
    event TokenWhitelisted(address token);
    event OracleChanged(address oldOracle, address newOracle);
    event InterestRateSet(uint256 interestRate, uint256);
    event MaxPositionSizeSet(uint256 maxPositionSize);
    event PositionHookChanged(address hook);
    event TrancheAdded(address lpToken);
    event TokenRiskFactorUpdated(address token);
    event PnLDistributed(address indexed asset, address indexed tranche, uint256 amount, bool hasProfit);
}

pragma solidity 0.8.15;

import {Side} from "./IPool.sol";

interface IReferralController {
    function handlePositionDecreased(
        address trader,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange
    ) external;

    function setReferrer(address _trader, address _referrer) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0;

uint256 constant POS = 1;
uint256 constant NEG = 0;

/// SignedInt is integer number with sign. It value range is -(2 ^ 256 - 1) to (2 ^ 256 - 1)
struct SignedInt {
    /// @dev sig = 1 -> positive, sig = 0 is negative
    /// using uint256 which take up full word to optimize gas and contract size
    uint256 sig;
    uint256 abs;
}

library SignedIntOps {
    function add(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        if (a.sig == b.sig) {
            return SignedInt({sig: a.sig, abs: a.abs + b.abs});
        }

        if (a.abs == b.abs) {
            return SignedInt(0, 0); // always return positive zero
        }

        (uint256 sig, uint256 abs) = a.abs > b.abs ? (a.sig, a.abs - b.abs) : (b.sig, b.abs - a.abs);
        return SignedInt(sig, abs);
    }

    function inv(SignedInt memory a) internal pure returns (SignedInt memory) {
        return a.abs == 0 ? a : (SignedInt({sig: 1 - a.sig, abs: a.abs}));
    }

    function sub(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        return add(a, inv(b));
    }

    function mul(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs * b.abs;
        return SignedInt(abs == 0 ? POS : sig, abs); // zero is alway positive
    }

    function div(SignedInt memory a, SignedInt memory b) internal pure returns (SignedInt memory) {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs / b.abs;
        return SignedInt(sig, abs);
    }

    function add(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return sub(a, wrap(b));
    }

    function add(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return sub(a, wrap(b));
    }

    function mul(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return mul(a, wrap(b));
    }

    function mul(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return mul(a, wrap(b));
    }

    function div(SignedInt memory a, uint256 b) internal pure returns (SignedInt memory) {
        return div(a, wrap(b));
    }

    function div(SignedInt memory a, int256 b) internal pure returns (SignedInt memory) {
        return div(a, wrap(b));
    }

    function wrap(int256 a) internal pure returns (SignedInt memory) {
        return a >= 0 ? SignedInt(POS, uint256(a)) : SignedInt(NEG, uint256(-a));
    }

    function wrap(uint256 a) internal pure returns (SignedInt memory) {
        return SignedInt(POS, a);
    }

    function toUint(SignedInt memory a) internal pure returns (uint256) {
        require(a.sig == POS, "SignedInt: below zero");
        return a.abs;
    }

    function lt(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.sig > b.sig || a.abs < b.abs;
    }

    function lt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return a.sig == NEG || a.abs < b;
    }

    function lt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function gt(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.sig < b.sig || a.abs > b.abs;
    }

    function gt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return b < 0 || a.abs > uint256(b);
    }

    function gt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function isNeg(SignedInt memory a) internal pure returns (bool) {
        return a.sig == NEG;
    }

    function isPos(SignedInt memory a) internal pure returns (bool) {
        return a.sig == POS;
    }

    function eq(SignedInt memory a, SignedInt memory b) internal pure returns (bool) {
        return a.abs == b.abs && a.sig == b.sig;
    }

    function eq(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function eq(SignedInt memory a, int256 b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function frac(SignedInt memory a, uint256 num, uint256 denom) internal pure returns (SignedInt memory) {
        return div(mul(a, num), denom);
    }
}