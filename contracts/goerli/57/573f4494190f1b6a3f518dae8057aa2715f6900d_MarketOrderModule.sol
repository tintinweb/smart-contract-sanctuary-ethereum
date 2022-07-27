/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
}

enum Side {
    LONG,
    SHORT
}

interface IPositionManager {
    function increasePosition(
        address _account,
        address _indexToken,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function decreasePosition(
        address _account,
        address _indexToken,
        uint256 _desiredCollateralReduce,
        uint256 _sizeChanged,
        Side _side
    ) external;

    function liquidatePosition(
        address account,
        address collateralToken,
        address market,
        bool isLong
    ) external;

    function validateToken(
        address indexToken,
        Side side,
        address collateralToken
    ) external view returns (bool);
}

enum OrderType {
    INCREASE,
    DECREASE
}

/// @notice Order info
/// @dev The executor MUST save this info and call execute method whenever they think it fulfilled.
/// The approriate module will check for their condition and then execute, returning success or not
struct Order {
    IModule module;
    address owner;
    address indexToken;
    address collateralToken;
    uint256 sizeChanged;
    /// @notice when increase, collateralAmount is desired amount of collateral used as margin.
    /// When decrease, collateralAmount is value in USD of collateral user want to reduce from
    /// their position
    uint256 collateralAmount;
    uint256 executionFee;
    /// @notice To prevent front-running, order MUST be executed on next block
    uint256 submissionBlock;
    uint256 submissionTimestamp;
    // long or short
    Side side;
    OrderType orderType;
    // extra data for each order type
    bytes data;
}

/// @notice Order module, will parse orders and call to corresponding handler.
/// After execution complete, module will pass result to position manager to
/// update related position
/// Will be some kind of: StopLimitHandler, LimitHandler, MarketHandler...
interface IModule {
    function execute(IOracle oracle, Order memory order) external;

    function validate(Order memory order) external view;
}

interface IOrderBook {
    function placeOrder(
        IModule _module,
        address _indexToken,
        address _collateralToken,
        uint256 _side,
        OrderType _orderType,
        uint256 _sizeChanged,
        bytes calldata _data
    ) external payable;

    function executeOrder(bytes32 _key, address payable _feeTo) external;

    function cancelOrder(bytes32 _key) external;
}

uint256 constant POS = 1;
uint256 constant NEG = 0;

/// SignedInt is integer number with sign. It value range is -(2 ^ 256 - 1) to (2 ^ 256 - 1)
struct SignedInt {
    /// @dev sig = 0 -> positive, sig = 1 is negative
    /// using uint256 which take up full word to optimize gas and contract size
    uint256 sig;
    uint256 abs;
}

library SignedIntOps {
    function add(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        if (a.sig == b.sig) {
            return SignedInt({sig: a.sig, abs: a.abs + b.abs});
        }

        if (a.abs == b.abs) {
            return SignedInt(0, 0); // always return positive zero
        }

        (uint256 sig, uint256 abs) = a.abs > b.abs
            ? (a.sig, a.abs - b.abs)
            : (b.sig, b.abs - a.abs);
        return SignedInt(sig, abs);
    }

    function inv(SignedInt memory a) internal pure returns (SignedInt memory) {
        return a.abs == 0 ? a : (SignedInt({sig: 1 - a.sig, abs: a.abs}));
    }

    function sub(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, inv(b));
    }

    function mul(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs * b.abs;
        return SignedInt(abs == 0 ? POS : sig, abs); // zero is alway positive
    }

    function div(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (SignedInt memory)
    {
        uint256 sig = (a.sig + b.sig + 1) % 2;
        uint256 abs = a.abs / b.abs;
        return SignedInt(sig, abs);
    }

    function add(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return sub(a, wrap(b));
    }

    function add(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return add(a, wrap(b));
    }

    function sub(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return sub(a, wrap(b));
    }

    function mul(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return mul(a, wrap(b));
    }

    function mul(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return mul(a, wrap(b));
    }

    function div(SignedInt memory a, uint256 b)
        internal
        pure
        returns (SignedInt memory)
    {
        return div(a, wrap(b));
    }

    function div(SignedInt memory a, int256 b)
        internal
        pure
        returns (SignedInt memory)
    {
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

    function lt(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (bool)
    {
        return a.sig > b.sig || a.abs < b.abs;
    }

    function lt(SignedInt memory a, uint256 b) internal pure returns (bool) {
        return a.sig == NEG || a.abs < b;
    }

    function lt(SignedInt memory a, int256 b) internal pure returns (bool) {
        return lt(a, wrap(b));
    }

    function gt(SignedInt memory a, SignedInt memory b)
        internal
        pure
        returns (bool)
    {
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

    function eq(SignedInt memory a, uint b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }

    function eq(SignedInt memory a, int b) internal pure returns (bool) {
        return eq(a, wrap(b));
    }
}

uint256 constant FEE_PRECISION = 1e10;
uint256 constant INTEREST_RATE_PRECISION = 1e10;
uint256 constant MAX_POSITION_FEE = 1e8; // 1%

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position
    uint256 liquidationFee;
    /// @notice fee reserved rate for admin
    uint256 adminFee;
    /// @notice interest rate when borrow token to leverage
    uint256 interestRate;
    uint256 accrualInterval;
    uint256 lastAccrualTimestamp;
    /// @notice cumulated interest rate, update on epoch
    uint256 cumulativeInterestRate;
}

library FeeUtils {
    function calcInterest(
        Fee memory self,
        uint256 entryCumulativeInterestRate,
        uint256 size
    ) internal pure returns (uint256) {
        return (size * (self.cumulativeInterestRate - entryCumulativeInterestRate)) / INTEREST_RATE_PRECISION;
    }

    function calcPositionFee(Fee memory self, uint256 sizeChanged) internal pure returns (uint256) {
        return (sizeChanged * self.positionFee) / FEE_PRECISION;
    }

    // TODO: fixed value or based on size?
    function calcLiquidationFee(Fee memory self, uint256 size) internal pure returns (uint256) {
        return (size * self.liquidationFee) / FEE_PRECISION;
    }

    function calcAdminFee(Fee memory self, uint256 feeAmount) internal pure returns (uint256) {
        return (feeAmount * self.adminFee) / FEE_PRECISION;
    }

    function cumulativeInterest(Fee storage self) internal {
        uint256 _now = block.timestamp;
        if (self.lastAccrualTimestamp == 0) {
            // accrue interest for the first time
            self.lastAccrualTimestamp = _now;
            return;
        }

        if (self.lastAccrualTimestamp + self.accrualInterval > _now) {
            return;
        }

        uint256 nInterval = (_now - self.lastAccrualTimestamp) / self.accrualInterval;
        self.cumulativeInterestRate += nInterval * self.interestRate;
        self.lastAccrualTimestamp += nInterval * self.accrualInterval;
    }

    function setInterestRate(
        Fee storage self,
        uint256 interestRate,
        uint256 accrualInterval
    ) internal {
        self.accrualInterval = accrualInterval;
        self.interestRate = interestRate;
    }

    function setFee(
        Fee storage self,
        uint256 positionFee,
        uint256 liquidationFee,
        uint256 adminFee
    ) internal {
        require(positionFee <= MAX_POSITION_FEE, "Fee: max position fee exceeded");
        self.positionFee = positionFee;
        self.liquidationFee = liquidationFee;
        self.adminFee = adminFee;
    }
}

uint256 constant MAX_LEVERAGE = 30;

struct Position {
    /// @dev contract size is evaluated in dollar
    uint256 size;
    /// @dev collateral value in dollar
    uint256 collateralValue;
    /// @dev contract size in indexToken
    uint256 reserveAmount;
    /// @dev average entry price
    uint256 entryPrice;
    /// @dev last cumulative interest rate
    uint256 entryInterestRate;
}

struct IncreasePositionResult {
    uint256 reserveAdded;
    uint256 collateralValueAdded;
    uint256 feeValue;
    uint256 adminFee;
}

struct DecreasePositionResult {
    uint256 collateralValueReduced;
    uint256 reserveReduced;
    uint256 feeValue;
    uint256 adminFee;
    uint256 payout;
    SignedInt pnl;
}

library PositionUtils {
    using SignedIntOps for SignedInt;
    using FeeUtils for Fee;

    /// @notice increase position size and/or collateral
    /// @param position position to update
    /// @param fee fee config
    /// @param side long or shor
    /// @param sizeChanged value in USD
    /// @param collateralAmount value in USD
    /// @param indexPrice price of index token
    /// @param collateralPrice price of collateral token
    function increase(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralAmount,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (IncreasePositionResult memory result) {
        result.collateralValueAdded = collateralPrice * collateralAmount;
        result.feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(sizeChanged);
        result.adminFee = fee.calcAdminFee(result.feeValue) / collateralPrice;
        require(
            position.collateralValue + result.collateralValueAdded > result.feeValue,
            "Position: increase cause liquidation"
        );

        result.reserveAdded = sizeChanged / indexPrice;

        position.entryPrice = calcAveragePrice(side, position.size, sizeChanged, position.entryPrice, indexPrice);
        position.collateralValue = position.collateralValue + result.collateralValueAdded - result.feeValue;
        position.size = position.size + sizeChanged;
        position.entryInterestRate = fee.cumulativeInterestRate;
        position.reserveAmount += result.reserveAdded;

        validatePosition(position, false, MAX_LEVERAGE);
        validateLiquidation(position, fee, side, indexPrice);
    }

    /// @notice decrease position size and/or collateral
    /// @param collateralChanged collateral value in $ to reduce
    function decrease(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralChanged,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        result = decreaseUnchecked(position, fee, side, sizeChanged, collateralChanged, indexPrice, collateralPrice);
        validatePosition(position, false, MAX_LEVERAGE);
        validateLiquidation(position, fee, side, indexPrice);
    }

    function liquidate(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        (bool allowed, , , ) = liquidatePositionAllowed(position, fee, side, indexPrice);
        require(allowed, "Position: can not liquidate");
        result = decreaseUnchecked(position, fee, side, position.size, 0, indexPrice, collateralPrice);
        assert(position.size == 0); // double check
        assert(position.collateralValue == 0);
    }

    function decreaseUnchecked(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 sizeChanged,
        uint256 collateralChanged,
        uint256 indexPrice,
        uint256 collateralPrice
    ) internal returns (DecreasePositionResult memory result) {
        require(position.size >= sizeChanged, "Position: decrease too much");
        require(position.collateralValue >= collateralChanged, "Position: reduce collateral too much");

        result.reserveReduced = (position.reserveAmount * sizeChanged) / position.size;
        collateralChanged = collateralChanged > 0
            ? collateralChanged
            : (position.collateralValue * sizeChanged) / position.size;

        result.pnl = calcPnl(side, sizeChanged, position.entryPrice, indexPrice);
        result.feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(sizeChanged);
        result.adminFee = fee.calcAdminFee(result.feeValue) / collateralPrice;

        SignedInt memory payoutValue = result.pnl.add(collateralChanged).sub(result.feeValue);
        SignedInt memory collateral = SignedIntOps.wrap(position.collateralValue).sub(collateralChanged);
        if (payoutValue.isNeg()) {
            // deduct uncovered lost from collateral
            collateral = collateral.add(payoutValue);
        }

        uint256 collateralValue = collateral.isNeg() ? 0 : collateral.abs;
        result.collateralValueReduced = position.collateralValue - collateralValue;
        position.collateralValue = collateralValue;
        position.size = position.size - sizeChanged;
        position.entryInterestRate = fee.cumulativeInterestRate;
        position.reserveAmount = position.reserveAmount - result.reserveReduced;
        result.payout = payoutValue.isNeg() ? 0 : payoutValue.abs / collateralPrice;
    }

    /// @notice calculate new avg entry price when increase position
    /// @dev for longs: nextAveragePrice = (nextPrice * nextSize)/ (nextSize + delta)
    ///      for shorts: nextAveragePrice = (nextPrice * nextSize) / (nextSize - delta)
    function calcAveragePrice(
        Side side,
        uint256 lastSize,
        uint256 increasedSize,
        uint256 entryPrice,
        uint256 nextPrice
    ) internal pure returns (uint256) {
        if (lastSize == 0) {
            return nextPrice;
        }
        SignedInt memory pnl = calcPnl(side, lastSize, entryPrice, nextPrice);
        SignedInt memory nextSize = SignedIntOps.wrap(lastSize + increasedSize);
        SignedInt memory divisor = side == Side.LONG ? nextSize.add(pnl) : nextSize.sub(pnl);
        return nextSize.mul(nextPrice).div(divisor).toUint();
    }

    function calcPnl(
        Side side,
        uint256 positionSize,
        uint256 entryPrice,
        uint256 indexPrice
    ) internal pure returns (SignedInt memory) {
        if (positionSize == 0) {
            return SignedIntOps.wrap(uint256(0));
        }
        if (side == Side.LONG) {
            return SignedIntOps.wrap(indexPrice).sub(entryPrice).mul(positionSize).div(entryPrice);
        } else {
            return SignedIntOps.wrap(entryPrice).sub(indexPrice).mul(positionSize).div(entryPrice);
        }
    }

    function validateLiquidation(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice
    ) internal view {
        (bool liquidated, , , ) = liquidatePositionAllowed(position, fee, side, indexPrice);
        require(!liquidated, "Position: liquidated");
    }

    function validatePosition(
        Position storage position,
        bool isIncrease,
        uint256 maxLeverage
    ) internal view {
        if (isIncrease) {
            require(position.size >= 0, "Position: invalid size");
        }
        require(position.size >= position.collateralValue, "Position: invalid leverage");
        require(position.size <= position.collateralValue * maxLeverage, "POSITION: max leverage exceeded");
    }

    function liquidatePositionAllowed(
        Position storage position,
        Fee memory fee,
        Side side,
        uint256 indexPrice
    )
        internal
        view
        returns (
            bool allowed,
            uint256 feeValue,
            uint256 remainingCollateralValue,
            SignedInt memory pnl
        )
    {
        // calculate fee needed when close position
        feeValue =
            fee.calcInterest(position.entryInterestRate, position.size) +
            fee.calcPositionFee(position.size) +
            fee.calcLiquidationFee(position.size);

        pnl = calcPnl(side, position.size, position.entryPrice, indexPrice);

        SignedInt memory remainingCollateral = pnl.add(position.collateralValue).sub(feeValue);

        (allowed, remainingCollateralValue) = remainingCollateral.isNeg()
            ? (true, 0)
            : (false, remainingCollateral.abs);
    }
}

contract MarketOrderModule is IModule {
    uint public maxOrderTimeout;

    constructor(uint _maxOrderTimeout) {
        require(_maxOrderTimeout > 0, "MarketOrderModule: invalid order timeout");
        maxOrderTimeout = _maxOrderTimeout;
    }

    /// @dev this function not restricted to view
    function execute(IOracle oracle, Order memory order) external view {
        uint256 acceptablePrice = abi.decode(order.data, (uint256));
        uint indexPrice = oracle.getPrice(order.indexToken);
        require(indexPrice > 0, "LimitOrderModule: invalid mark price");

        require(order.submissionTimestamp + maxOrderTimeout >= block.timestamp, "MarketOrderModule: order timed out");
        if (order.side == Side.LONG) {
            require(indexPrice <= acceptablePrice, "MarketOrderModule: mark price higher than limit");
        } else {
            require(indexPrice >= acceptablePrice, "MarketOrderModule: mark price lower than limit");
        }
    }

    function validate(Order memory order) external pure {
        uint256 acceptablePrice = abi.decode(order.data, (uint256));
        require(acceptablePrice > 0, "MarketOrderModule: acceptable price invalid");
    }
}