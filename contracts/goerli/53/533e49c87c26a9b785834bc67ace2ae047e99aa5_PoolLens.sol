// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {IERC20} from "openzeppelin/token/ERC20/IERC20.sol";

interface ILPToken is IERC20 {
    function mint(address to, uint amount) external;

    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

/// @title IOracle
/// @notice Read price of various token
interface IOracle {
    function getPrice(address token) external view returns (uint256);
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

import {Side, IPool} from "./IPool.sol";

interface IPositionHook {
    function preIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function postIncreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function preDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    function postDecreasePosition(
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes calldata extradata
    ) external;

    event PreIncreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PostIncreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PreDecreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
    event PostDecreasePositionExecuted(
        address pool,
        address owner,
        address indexToken,
        address collateralToken,
        Side side,
        uint256 sizeChange,
        bytes extradata
    );
}

// SPDX-License-Identifier: UNLCIENSED

pragma solidity >=0.8.0;

import {Side} from "../interfaces/IPool.sol";
import {SignedInt, SignedIntOps} from "./SignedInt.sol";

library PositionUtils {
    using SignedIntOps for SignedInt;

    function calcPnl(Side _side, uint256 _positionSize, uint256 _entryPrice, uint256 _indexPrice)
        internal
        pure
        returns (SignedInt memory)
    {
        if (_positionSize == 0) {
            return SignedIntOps.wrap(uint256(0));
        }
        if (_side == Side.LONG) {
            return SignedIntOps.wrap(_indexPrice).sub(_entryPrice).mul(_positionSize).div(_entryPrice);
        } else {
            return SignedIntOps.wrap(_entryPrice).sub(_indexPrice).mul(_positionSize).div(_entryPrice);
        }
    }
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.15;

import {PoolStorage, AssetInfo, PoolTokenInfo, Position} from "./PoolStorage.sol";
import {Side, IPool} from "../interfaces/IPool.sol";
import {SignedInt, SignedIntOps} from "../lib/SignedInt.sol";
import {PositionUtils} from "../lib/PositionUtils.sol";
import {IOracle} from "../interfaces/IOracle.sol";

struct PositionView {
    bytes32 key;
    uint256 size;
    uint256 collateralValue;
    uint256 entryPrice;
    uint256 pnl;
    uint256 reserveAmount;
    bool hasProfit;
    address collateralToken;
    uint256 borrowIndex;
}

struct PoolAsset {
    uint256 poolAmount;
    uint256 reservedAmount;
    uint256 feeReserve;
    uint256 guaranteedValue;
    uint256 totalShortSize;
    uint256 averageShortPrice;
    uint256 poolBalance;
    uint256 lastAccrualTimestamp;
    uint256 borrowIndex;
}

interface IPoolForLens is IPool {
    function getPoolAsset(address _token) external view returns (AssetInfo memory);
    function getAllTranchesLength() external view returns (uint256);
    function poolTokens(address) external view returns (PoolTokenInfo memory);
    function positions(bytes32) external view returns (Position memory);
    function oracle() external view returns (IOracle);
}

contract PoolLens {
    using SignedIntOps for SignedInt;

    function poolAssets(address _pool, address _token) external view returns (PoolAsset memory poolAsset) {
        IPoolForLens self = IPoolForLens(_pool);
        AssetInfo memory asset = self.getPoolAsset(_token);
        PoolTokenInfo memory tokenInfo = self.poolTokens(_token);
        poolAsset.poolAmount = asset.poolAmount;
        poolAsset.reservedAmount = asset.reservedAmount;
        poolAsset.guaranteedValue = asset.guaranteedValue;
        poolAsset.totalShortSize = asset.totalShortSize;
        poolAsset.feeReserve = tokenInfo.feeReserve;
        poolAsset.averageShortPrice = tokenInfo.averageShortPrice;
        poolAsset.poolBalance = tokenInfo.poolBalance;
        poolAsset.lastAccrualTimestamp = tokenInfo.lastAccrualTimestamp;
        poolAsset.borrowIndex = tokenInfo.borrowIndex;
    }

    function getPosition(address _pool, address _owner, address _indexToken, address _collateralToken, Side _side)
        external
        view
        returns (PositionView memory result)
    {
        IPoolForLens self = IPoolForLens(_pool);
        IOracle oracle = self.oracle();
        bytes32 positionKey = _getPositionKey(_owner, _indexToken, _collateralToken, _side);
        Position memory position = self.positions(positionKey);
        uint256 indexPrice = oracle.getPrice(_indexToken);
        SignedInt memory pnl = PositionUtils.calcPnl(_side, position.size, position.entryPrice, indexPrice);

        result.key = positionKey;
        result.size = position.size;
        result.collateralValue = position.collateralValue;
        result.pnl = pnl.abs;
        result.hasProfit = pnl.gt(uint256(0));
        result.entryPrice = position.entryPrice;
        result.borrowIndex = position.borrowIndex;
        result.reserveAmount = position.reserveAmount;
        result.collateralToken = _collateralToken;
    }

    function _getPositionKey(address _owner, address _indexToken, address _collateralToken, Side _side)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_owner, _indexToken, _collateralToken, _side));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import {IOracle} from "../interfaces/IOracle.sol";
import {ILPToken} from "../interfaces/ILPToken.sol";
import {IPositionHook} from "../interfaces/IPositionHook.sol";

uint256 constant INTEREST_RATE_PRECISION = 1e10;
uint256 constant FEE_PRECISION = 1e10;
uint256 constant LP_INITIAL_PRICE = 1e12; // fix to 1$
uint256 constant MAX_BASE_SWAP_FEE = 1e8; // 1%
uint256 constant MAX_TAX_BASIS_POINT = 1e8; // 1%
uint256 constant MAX_POSITION_FEE = 1e8; // 1%

struct Fee {
    /// @notice charge when changing position size
    uint256 positionFee;
    /// @notice charge when liquidate position (in dollar)
    uint256 liquidationFee;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 baseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 taxBasisPoint;
    /// @notice swap fee used when add/remove liquidity, swap token
    uint256 stableCoinBaseSwapFee;
    /// @notice tax used to adjust swapFee due to the effect of the action on token's weight
    /// It reduce swap fee when user add some amount of a under weight token to the pool
    uint256 stableCoinTaxBasisPoint;
    /// @notice part of fee will be kept for DAO, the rest will be distributed to pool amount, thus
    /// increase the pool value and the price of LP token
    uint256 daoFee;
}

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
    uint256 borrowIndex;
}

struct PoolTokenInfo {
    /// @notice amount reserved for fee
    uint256 feeReserve;
    /// @notice recorded balance of token in pool
    uint256 poolBalance;
    /// @notice last borrow index update timestamp
    uint256 lastAccrualTimestamp;
    /// @notice accumulated interest rate
    uint256 borrowIndex;
    /// @notice average entry price of all short position
    uint256 averageShortPrice;
}

struct AssetInfo {
    /// @notice amount of token deposited (via add liquidity or increase long position)
    uint256 poolAmount;
    /// @notice amount of token reserved for paying out when user decrease long position
    uint256 reservedAmount;
    /// @notice total borrowed (in USD) to leverage
    uint256 guaranteedValue;
    /// @notice total size of all short positions
    uint256 totalShortSize;
}

abstract contract PoolStorage {
    Fee public fee;

    address public feeDistributor;

    IOracle public oracle;

    address public orderManager;

    // ========= Assets management =========
    mapping(address => bool) public isAsset;
    /// @notice A list of all configured assets
    /// @dev use a pseudo address for ETH
    /// Note that token will not be removed from this array when it was delisted. We keep this
    /// list to calculate pool value properly
    address[] public allAssets;

    mapping(address => bool) public isListed;

    mapping(address => bool) public isStableCoin;

    mapping(address => PoolTokenInfo) public poolTokens;

    /// @notice target weight for each tokens
    mapping(address => uint256) public targetWeights;

    mapping(address => bool) public isTranche;
    /// @notice risk factor of each token in each tranche
    /// @dev token => tranche => risk factor
    mapping(address => mapping(address => uint256)) public riskFactor;
    /// @dev token => total risk score
    mapping(address => uint256) public totalRiskFactor;

    address[] public allTranches;

    mapping(address => mapping(address => AssetInfo)) public trancheAssets;
    /// @notice position reserve in each tranche
    mapping(address => mapping(bytes32 => uint256)) public tranchePositionReserves;

    /// @notice interest rate model
    uint256 public interestRate;

    uint256 public accrualInterval;

    uint256 public totalWeight;
    // ========= Positions management =========
    /// @notice max leverage for each token
    uint256 public maxLeverage;
    /// @notice positions tracks all open positions
    mapping(bytes32 => Position) public positions;
    /// @notice max position size allowed to open. Disable if set to 0
    uint256 public maxPositionSize;

    IPositionHook public positionHook;
}