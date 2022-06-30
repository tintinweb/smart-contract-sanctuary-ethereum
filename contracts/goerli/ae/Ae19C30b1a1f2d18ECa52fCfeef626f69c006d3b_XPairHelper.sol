// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "../interfaces/IXPair.sol";
import "../interfaces/IXVault.sol";
import "../library/math/Rebase.sol";
import "../library/math/PercentageMath.sol";
import "../library/configuration/PairConfiguration.sol";

///
/// This is designed to be used for efficient off-chain data fetching
/// so it's not optimized gas wise
///
contract XPairHelper {
    using RebaseLibrary for Rebase;
    using PercentageMath for uint256;
    using PairConfiguration for Config;

    IXVault public immutable vault;

    constructor(IXVault _vault) {
        vault = _vault;
    }

    function viewBorrowedValue(IXPair[] calldata pairs, address _account) external view returns (uint256[] memory totals) {
        totals = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IXPair pair = pairs[i];
            totals[i] = _borrowShareToAmount(pair, pair.userBorrowShare(_account));
        }
    }

    function viewBorrowedValueInUSD(IXPair[] calldata pairs, address _account) external view returns (uint256[] memory totals) {
        totals = new uint256[](pairs.length);
        for (uint256 i = 0; i < pairs.length; i++) {
            IXPair pair = pairs[i];
            uint256 currentBorrowBalance = _borrowShareToAmount(pair, pair.userBorrowShare(_account));
            uint256 priceInUSD = pair.oracle().getPriceInUSD(pair.xasset()) * currentBorrowBalance;
            totals[i] = priceInUSD;
        }
    }

    function viewBorrowLimitInUSD(IXPair[] calldata pairs, address _account) external view returns (uint256[] memory limit) {
        limit = new uint256[](pairs.length);

        for (uint256 i = 0; i < pairs.length; i++) {
            IXPair pair = pairs[i];
            uint256 underlyingAmount = vault.toUnderlying(pair.collateral(), pair.userCollateral(_account));
            uint256 data = pair.getConfigurationData();
            Config memory configuration = Config(data);
            uint256 collateral = underlyingAmount.percentDiv(configuration.getCollateralFactorPercent_());
            uint256 priceInUSD = pair.oracle().getPriceInUSD(pair.collateral()) * collateral;
            limit[i] = priceInUSD;
        }
    }

    function viewBorrowLimit(IXPair[] calldata pairs, address _account) external view returns (uint256[] memory limit) {
        limit = new uint256[](pairs.length);

        for (uint256 i = 0; i < pairs.length; i++) {
            IXPair pair = pairs[i];
            uint256 underlyingAmount = vault.toUnderlying(pair.collateral(), pair.userCollateral(_account));
            uint256 data = pair.getConfigurationData();
            Config memory configuration = Config(data);
            uint256 collateral = underlyingAmount.percentDiv(configuration.getCollateralFactorPercent_());
            uint256 priceInUSD = pair.oracle().getPriceInUSD(pair.collateral()) * collateral;
            limit[i] = priceInUSD / pair.oracle().getPriceInUSD(pair.xasset());
        }
    }

    function availableCollateral(IXPair[] calldata pairs, uint256[] calldata amounts) external view returns (uint256[] memory limits) {
        limits = new uint256[](pairs.length);

        for (uint256 i = 0; i < pairs.length; i++) {
            IXPair pair = pairs[i];
            uint256 data = pair.getConfigurationData();
            Config memory configuration = Config(data);
            limits[i] = amounts[i].percentDiv(configuration.getCollateralFactorPercent_());
        }
    }

    function _borrowShareToAmount(IXPair pair, uint256 share) internal view returns (uint256 amount) {
        (uint128 elastic, uint128 base) = pair.totalBorrow();
        Rebase memory totalBorrow = Rebase(elastic, base);
        amount = totalBorrow.toElastic(share, false);
    }

    function getPairConfiguration(IXPair pair)
        external
        view
        returns (
            uint256 collateralFactor,
            uint256 liquidationFee,
            uint256 borrowFee,
            bool pauseAction,
            bool settlementMode
        )
    {
        Config memory data = Config(pair.getConfigurationData());
        return (
            data.getCollateralFactorPercent_(),
            data.getLiquidationFeePercent(),
            data.getBorrowFeePercent_(),
            data.isAllPaused(),
            data.getSettlementMode()
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IERC3156FlashBorrower {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "./IERC3156FlashBorrower.sol";

interface IERC3156FlashLender {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        IERC3156FlashBorrower receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

interface IOracle {
    /// @notice Price update event
    /// @param asset the asset
    /// @param newPrice price of the asset
    event PriceUpdated(address asset, uint256 newPrice);

    /// @dev returns latest answer
    function latestAnswer() external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IOracle.sol";

interface IPriceOracleAggregator {
    event UpdateOracle(IERC20 token, IOracle oracle);

    function getPriceInUSD(IERC20 _token) external view returns (uint256);

    function getPriceInUSDMultiple(IERC20[] calldata _tokens) external view returns (uint256[] memory);

    function setOracleForAsset(IERC20[] calldata _asset, IOracle[] calldata _oracle) external;

    event OwnershipAccepted(address newOwner, uint256 timestamp);
    event TransferControl(address _newTeam, uint256 timestamp);
    event StableTokenAdded(IERC20 _token, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IPriceOracleAggregator.sol";
import "./IXVault.sol";

interface IXPair {
    struct PairAccrueInfo {
        uint64 lastUpdateTimestamp;
        uint64 interestPerSecond;
        uint128 fees;
    }

    struct PairShutDown {
        bool shutdown;
        uint128 exchangeRate;
    }

    struct Settlement {
        uint64 timestamp;
        // address to
        address to;
    }

    enum PauseActions {
        Deposit,
        Borrow,
        Liquidate,
        Repay,
        All
    }

    /// @dev Emitted on initilaize
    /// @param pair address of the pair
    /// @param asset borrow asset
    /// @param collateralAsset collateral asset
    /// @param pauseGuardian user with ability to pause
    event Initialized(address indexed pair, address indexed asset, address indexed collateralAsset, address pauseGuardian);

    /// @dev Emitted on deposit
    /// @param user The user that made the deposit
    /// @param receipeint The user that receives the deposit
    /// @param amount The amount deposited
    event Deposit(address indexed user, address receipeint, uint256 amount);

    /// @dev Emitted on borrow
    /// @param borrower address of the borrrower
    /// @param receipeint The user address that receives the borrow amount
    /// @param amount amount being borrowed
    event Borrow(address indexed borrower, address receipeint, uint256 amount);

    /// @dev Emitted on repay
    /// @param repayer The user that's providing the funds
    /// @param beneficiary The user that's getting their debt reduced
    /// @param amount The amount being repaid
    event Repay(address indexed repayer, address beneficiary, uint256 amount);

    /// @dev Emitted on redeem
    /// @param account address amount being withdrawn to
    /// @param amount amount being withdrawn
    event WithdrawCollateral(address account, uint256 amount);

    /// @dev Emitted on withdrawFees
    event ReserveWithdraw(address user, uint256 shares);

    /// @dev Emitted on liquidation
    /// @param user The user that's getting liquidated
    /// @param collateralShare The collateral share transferred to the liquidator
    /// @param liquidator The liquidator
    event Liquidate(address indexed user, uint256 collateralShare, uint256 borrowShare, uint256 liquidationFee, address liquidator);

    /// @dev Emitted on flashLoan
    /// @param target The address of the flash loan receiver contract
    /// @param initiator The address initiating the flash loan
    /// @param asset The address of the asset being flash borrowed
    /// @param amount The amount flash borrowed
    /// @param premium The fee flash borrowed
    event FlashLoan(address indexed target, address indexed initiator, address indexed asset, uint256 amount, uint256 premium);

    /// @dev Emitted on interest accrued
    /// @param accrualBlockNumber block number
    /// @param borrowIndex borrow index
    /// @param totalBorrows total borrows
    /// @param totalReserves total reserves
    event InterestAccrued(
        address indexed pair,
        uint256 accrualBlockNumber,
        uint256 borrowIndex,
        uint256 totalBorrows,
        uint256 totalReserves
    );

    /// @dev Emitted on setStatus
    /// @param status status
    event SetStatus(bool status);

    /// @dev Emitted on settle
    /// @param amountOfTokensRedeem amount of borrow asset to redeem
    /// @param amountOfCollateral amount of collateral transferred
    event Settle(address to, uint256 amountOfTokensRedeem, uint256 amountOfCollateral);

    /// @dev Emitted on shutdown
    /// @param timestamp timestamp shutdown
    /// @param to address that holds funds
    event ShutDown(uint64 timestamp, address to);

    /// @dev Emitted on cancelShutDown
    event CancelShutDown(uint256 timestamp);

    /// @dev Emitted on updateInterestRate
    event UpdatedInterestRate(uint64 newInterestRatePerSecond);

    /// @dev Emitted on withdrawFees
    /// @param feeVault address of the fee vault
    /// @param share amount of fees withdrawn
    event WithdrawFees(address feeVault, uint256 share);

    /// @dev Emitted on creditline
    /// @param from address granting the credit line
    /// @param to address receiving the credit line
    /// @param amount amount of credit line to issue
    /// @param timestamp block timestamp of when the credit line was issued
    event Creditline(address from, address to, uint256 amount, uint256 timestamp);

    /// @notice Initialize
    /// @param _collateral pair collateral
    /// @param _decimals 18 - collateral decimals
    /// @param _liquidationFeePercent share of liquidation that we accrue
    /// @param _interestPerSecond interest per second
    /// @param _collateralFactorPercent pair collateral factor
    /// @param _configurator pair configurator
    /// @param _borrowFeePercent borrow fee
    function initialize(
        IERC20 _collateral,
        uint128 _decimals,
        uint128 _liquidationFeePercent,
        uint64 _interestPerSecond,
        uint128 _collateralFactorPercent,
        address _configurator,
        uint128 _borrowFeePercent
    ) external;

    /// @notice deposit allows a user to deposit underlying collateral from vault
    /// @param _recipient user address to credit the collateral amount
    /// @param _share is the amount of vault share being deposited
    /// @param _skim If true does only a balance check for deposit
    function depositCollateral(
        address _recipient,
        uint256 _share,
        bool _skim
    ) external;

    function xasset() external view returns (IERC20);

    function totalBorrow() external view returns (uint128 elastic, uint128 base);

    function collateral() external view returns (IERC20);

    function oracle() external view returns (IPriceOracleAggregator);

    /// @notice borrow a xasset
    /// @param _debtOwner address that holds the collateral
    /// @param _to address to transfer borrow tokens to
    /// @param _amount is the amount of the borrow asset the user wants to borrow
    function borrow(
        address _debtOwner,
        address _to,
        uint256 _amount
    ) external;

    function userCollateral(address _user) external view returns (uint256 collateralShare);

    /// @notice returns the user borrow share
    /// @param _user user address
    /// @dev To retrieve the actual user borrow amount convert to elastic
    function userBorrowShare(address _user) external view returns (uint256 borrowShare);

    function updateInterestRate(uint64 newInterestRatePerSecond) external;

    function cancelShutDown() external;

    function shutdown(address _to) external;

    function settle(address to, uint256 amount) external;

    function setStatus(bool) external;

    function status() external view returns (bool);

    function getConfigurationData() external view returns (uint256 data);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IERC3156FlashLender.sol";

interface IXVault is IERC3156FlashLender {
    // ************** //
    // *** EVENTS *** //
    // ************** //

    /// @notice Emitted on deposit
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being deposited
    /// @param amount being deposited
    /// @param shares the represent the amount deposited in the vault
    event Deposit(IERC20 indexed token, address indexed from, address indexed to, uint256 amount, uint256 shares);

    /// @notice Emitted on withdraw
    /// @param token being deposited
    /// @param from address making the depsoit
    /// @param to address to credit the tokens being withdrawn
    /// @param amount Amount of underlying being withdrawn
    /// @param shares the represent the amount withdraw from the vault
    event Withdraw(IERC20 indexed token, address indexed from, address indexed to, uint256 shares, uint256 amount);

    event Transfer(IERC20 indexed token, address indexed from, address indexed to, uint256 amount);

    event FlashLoan(address indexed borrower, IERC20 indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);

    event TransferControl(address _newTeam, uint256 timestamp);

    event UpdateFlashLoanRate(uint256 newRate);

    event Approval(address indexed user, address indexed allowed, bool status);

    event OwnershipAccepted(address newOwner, uint256 timestamp);

    event RegisterProtocol(address sender);

    event AllowContract(address whitelist, bool status);

    event RescueFunds(IERC20 token, uint256 amount);

    // ************** //
    // *** FUNCTIONS *** //
    // ************** //

    function initialize(uint256 _flashLoanRate, address _owner) external;

    function approveContract(
        address _user,
        address _contract,
        bool _status,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function deposit(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256, uint256);

    function withdraw(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (uint256);

    function balanceOf(IERC20, address) external view returns (uint256);

    function transfer(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _shares,
        uint256 _amount
    ) external;

    function toShare(
        IERC20 token,
        uint256 amount,
        bool ceil
    ) external view returns (uint256);

    function toUnderlying(IERC20 token, uint256 share) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

struct Config {
    // Pair Configuration data pack

    // 64 decimals
    // 16 collateral factor percent

    // 16 liquidation fee percent

    // 16 borrow fee percent

    // 1 bit all pause action
    // 1 bit settlement mode

    uint256 data;
}

library PairConfiguration {
    uint256 internal constant DECIMAL_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000000000000000;
    uint256 internal constant COLLATERAL_FACTOR_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF;
    uint256 internal constant LIQUIDATION_FEE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant BORROW_FEE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant ALL_PAUSE_ACTION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
    uint256 internal constant SETTLEMENT_MODE_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    uint256 internal constant COLLATERAL_FACTOR_POSITION = 64;
    uint256 internal constant LIQUIDATION_FEE_POSITION = 80;
    uint256 internal constant BORROW_FEE_POSITION = 96;
    uint256 internal constant ALL_PAUSE_ACTION_POSITION = 112;
    uint256 internal constant SETTLEMENT_MODE_POSITION = 113;

    uint256 internal constant MAX_UINT_64_VALUE = 1;
    uint256 internal constant MAX_UINT_16_VALUE = 65535;
    uint256 internal constant MAX_UINT_8_VALUE = 255;

    function setDecimals(Config memory _config, uint256 _decimals) internal pure {
        require(_decimals <= MAX_UINT_64_VALUE, "INVALID_DECIMALS");
        _config.data = (_config.data & DECIMAL_MASK) | _decimals;
    }

    function getDecimals(Config storage _config) internal view returns (uint256 decimals) {
        decimals = _config.data & ~DECIMAL_MASK;
    }

    function setCollateralFactorPercent(Config memory _config, uint256 _factor) internal pure {
        require(_factor < MAX_UINT_16_VALUE, "INVALID_VALUE");
        _config.data = (_config.data & COLLATERAL_FACTOR_MASK) | (_factor << COLLATERAL_FACTOR_POSITION);
    }

    function getCollateralFactorPercent_(Config memory _config) internal pure returns (uint256 collateralFactorPercent) {
        collateralFactorPercent = (_config.data & ~COLLATERAL_FACTOR_MASK) >> COLLATERAL_FACTOR_POSITION;
    }

    function getCollateralFactorPercent(Config storage _config) internal view returns (uint256 collateralFactorPercent) {
        collateralFactorPercent = (_config.data & ~COLLATERAL_FACTOR_MASK) >> COLLATERAL_FACTOR_POSITION;
    }

    function setLiquidationFeePercent(Config memory _config, uint256 _fee) internal pure {
        require(_fee < MAX_UINT_16_VALUE, "INVALID");
        _config.data = (_config.data & LIQUIDATION_FEE_MASK) | (_fee << LIQUIDATION_FEE_POSITION);
    }

    function getLiquidationFeePercent(Config memory _config) internal pure returns (uint256 liquidationFeePercent) {
        liquidationFeePercent = (_config.data & ~LIQUIDATION_FEE_MASK) >> LIQUIDATION_FEE_POSITION;
    }

    function setBorrowFeePercent(Config memory _config, uint256 _fee) internal pure {
        require(_fee < MAX_UINT_16_VALUE, "INVALID");
        _config.data = (_config.data & BORROW_FEE_MASK) | (_fee << BORROW_FEE_POSITION);
    }

    function getBorrowFeePercent(Config storage _config) internal view returns (uint256 fee) {
        fee = (_config.data & ~BORROW_FEE_MASK) >> BORROW_FEE_POSITION;
    }

    function getBorrowFeePercent_(Config memory _config) internal pure returns (uint256 fee) {
        fee = (_config.data & ~BORROW_FEE_MASK) >> BORROW_FEE_POSITION;
    }

    function setAllActionPaused(Config memory _config, bool status) internal pure {
        _config.data = (_config.data & ALL_PAUSE_ACTION_MASK) | (uint256(status ? 1 : 0) << ALL_PAUSE_ACTION_POSITION);
    }

    function isAllPaused(Config memory _config) internal pure returns (bool paused) {
        paused = (_config.data & ~ALL_PAUSE_ACTION_MASK) != 0;
    }

    function setSettlementMode(Config memory _config, bool status) internal pure {
        _config.data = (_config.data & SETTLEMENT_MODE_MASK) | (uint256(status ? 1 : 0) << SETTLEMENT_MODE_POSITION);
    }

    function getSettlementMode(Config memory _config) internal pure returns (bool paused) {
        paused = (_config.data & ~SETTLEMENT_MODE_MASK) != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

library PercentageMath {
    uint256 internal constant PERCENT_PRECISION = 10_000;

    function percentMul(uint256 value, uint256 percentage) internal pure returns (uint256 result) {
        if (percentage != 0) {
            result = (value * percentage) / PERCENT_PRECISION;
        }
    }

    function percentDiv(uint256 value, uint256 percent) internal pure returns (uint256 result) {
        if (percent != 0) {
            result = (value * PERCENT_PRECISION) / percent;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using SafeCast for uint256;

    /// elastic = Total token amount to be repayed by borrowers,
    /// base = Total parts of the debt held by borrowers
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base += 1;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic += 1;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic + elastic.toUint128();
        total.base = total.base + base.toUint128();
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic - elastic.toUint128();
        total.base = total.base - base.toUint128();
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic + elastic.toUint128();
        total.base = total.base + base.toUint128();
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic - elastic.toUint128();
        total.base = total.base - base.toUint128();
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic + elastic.toUint128();
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic - elastic.toUint128();
    }
}