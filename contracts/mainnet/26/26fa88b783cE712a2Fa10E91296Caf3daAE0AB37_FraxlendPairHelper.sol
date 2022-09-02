// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

// ====================================================================
// |     ______                   _______                             |
// |    / _____________ __  __   / ____(_____  ____ _____  ________   |
// |   / /_  / ___/ __ `| |/_/  / /_  / / __ \/ __ `/ __ \/ ___/ _ \  |
// |  / __/ / /  / /_/ _>  <   / __/ / / / / / /_/ / / / / /__/  __/  |
// | /_/   /_/   \__,_/_/|_|  /_/   /_/_/ /_/\__,_/_/ /_/\___/\___/   |
// |                                                                  |
// ====================================================================
// ========================= FraxlendPairCore =========================
// ====================================================================
// Frax Finance: https://github.com/FraxFinance

// Primary Author
// Drake Evans: https://github.com/DrakeEvans

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "./libraries/VaultAccount.sol";

import "./interfaces/IFraxlendPair.sol";
import "./interfaces/IRateCalculator.sol";

contract FraxlendPairHelper {
    using VaultAccountingLibrary for VaultAccount;
    using SafeCast for uint256;

    error OracleLTEZero(address _oracle);

    struct ImmutablesAddressBool {
        bool _borrowerWhitelistActive;
        bool _lenderWhitelistActive;
        address _assetContract;
        address _collateralContract;
        address _oracleMultiply;
        address _oracleDivide;
        address _rateContract;
        address _DEPLOYER_CONTRACT;
        address _COMPTROLLER_ADDRESS;
        address _FRAXLEND_WHITELIST;
    }

    struct ImmutablesUint256 {
        uint256 _oracleNormalization;
        uint256 _maxLTV;
        uint256 _liquidationFee;
        uint256 _maturityDate;
        uint256 _penaltyRate;
    }

    struct CurrentRateInfo {
        uint64 lastBlock;
        uint64 feeToProtocolRate; // Fee amount 1e5 precision
        uint64 lastTimestamp;
        uint64 ratePerSec;
    }

    function getImmutableAddressBool(address _fraxlendPairAddress)
        external
        view
        returns (ImmutablesAddressBool memory)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesAddressBool({
                _assetContract: _fraxlendPair.asset(),
                _collateralContract: _fraxlendPair.collateralContract(),
                _oracleMultiply: _fraxlendPair.oracleMultiply(),
                _oracleDivide: _fraxlendPair.oracleDivide(),
                _rateContract: _fraxlendPair.rateContract(),
                _DEPLOYER_CONTRACT: _fraxlendPair.DEPLOYER_ADDRESS(),
                _COMPTROLLER_ADDRESS: _fraxlendPair.COMPTROLLER_ADDRESS(),
                _FRAXLEND_WHITELIST: _fraxlendPair.FRAXLEND_WHITELIST_ADDRESS(),
                _borrowerWhitelistActive: _fraxlendPair.borrowerWhitelistActive(),
                _lenderWhitelistActive: _fraxlendPair.lenderWhitelistActive()
            });
    }

    function getImmutableUint256(address _fraxlendPairAddress) external view returns (ImmutablesUint256 memory) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        return
            ImmutablesUint256({
                _oracleNormalization: _fraxlendPair.oracleNormalization(),
                _maxLTV: _fraxlendPair.maxLTV(),
                _liquidationFee: _fraxlendPair.cleanLiquidationFee(),
                _maturityDate: _fraxlendPair.maturityDate(),
                _penaltyRate: _fraxlendPair.penaltyRate()
            });
    }

    function getUserSnapshot(address _fraxlendPairAddress, address _address)
        external
        view
        returns (
            uint256 _userAssetShares,
            uint256 _userBorrowShares,
            uint256 _userCollateralBalance
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        _userAssetShares = _fraxlendPair.balanceOf(_address);
        _userBorrowShares = _fraxlendPair.userBorrowShares(_address);
        _userCollateralBalance = _fraxlendPair.userCollateralBalance(_address);
    }

    function getPairAccounting(address _fraxlendPairAddress)
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (_totalAssetAmount, _totalAssetShares) = _fraxlendPair.totalAsset();
        (_totalBorrowAmount, _totalBorrowShares) = _fraxlendPair.totalBorrow();
        _totalCollateral = _fraxlendPair.totalCollateral();
    }

    function previewUpdateExchangeRate(address _fraxlendPairAddress) public view returns (uint256 _exchangeRate) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        address _oracleMultiply = _fraxlendPair.oracleMultiply();
        address _oracleDivide = _fraxlendPair.oracleDivide();
        uint256 _oracleNormalization = _fraxlendPair.oracleNormalization();

        uint256 _price = uint256(1e36);
        if (_oracleMultiply != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleMultiply).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleMultiply);
            }
            _price = _price * uint256(_answer);
        }

        if (_oracleDivide != address(0)) {
            (, int256 _answer, , , ) = AggregatorV3Interface(_oracleDivide).latestRoundData();
            if (_answer <= 0) {
                revert OracleLTEZero(_oracleDivide);
            }
            _price = _price / uint256(_answer);
        }

        _exchangeRate = _price / _oracleNormalization;
    }

    function _isPastMaturity(uint256 _maturityDate, uint256 _timestamp) internal pure returns (bool) {
        return _maturityDate != 0 && _timestamp > _maturityDate;
    }

    function previewRateInterest(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    ) public view returns (uint256 _interestEarned, uint256 _newRate) {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, , uint256 _UTIL_PREC, , , uint64 _DEFAULT_INT, , ) = _fraxlendPair.getConstants();

        // Add interest only once per block
        CurrentRateInfo memory _currentRateInfo;
        {
            (uint64 lastBlock, uint64 feeToProtocolRate, uint64 lastTimestamp, uint64 ratePerSec) = _fraxlendPair
                .currentRateInfo();
            _currentRateInfo = CurrentRateInfo({
                lastBlock: lastBlock,
                feeToProtocolRate: feeToProtocolRate,
                lastTimestamp: lastTimestamp,
                ratePerSec: ratePerSec
            });
        }

        // Pull some data from storage to save gas
        VaultAccount memory _totalAsset;
        VaultAccount memory _totalBorrow;
        {
            (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
            _totalAsset = VaultAccount({ amount: _totalAssetAmount, shares: _totalAssetShares });
            (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
            _totalBorrow = VaultAccount({ amount: _totalBorrowAmount, shares: _totalBorrowShares });
        }

        // If there are no borrows, no interest accrues
        if (_totalBorrow.shares == 0 || _fraxlendPair.paused()) {
            if (!_fraxlendPair.paused()) {
                _currentRateInfo.ratePerSec = _DEFAULT_INT;
            }
            // _currentRateInfo.lastTimestamp = uint32(_timestamp);
            // _currentRateInfo.lastBlock = uint16(_blockNumber);
        } else {
            // NOTE: Violates Checks-Effects-Interactions pattern
            // Be sure to mark external version NONREENTRANT (even though rateContract is trusted)
            // Calc new rate
            if (_isPastMaturity(_fraxlendPair.maturityDate(), _timestamp)) {
                _newRate = uint64(_fraxlendPair.penaltyRate());
            } else {
                _newRate = IRateCalculator(_fraxlendPair.rateContract()).getNewRate(
                    abi.encode(
                        _currentRateInfo.ratePerSec,
                        _timestamp - _currentRateInfo.lastTimestamp,
                        (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                        _blockNumber - _currentRateInfo.lastBlock
                    ),
                    _fraxlendPair.rateInitCallData()
                );
            }

            // Calculate interest accrued
            _interestEarned = (_totalBorrow.amount * _newRate * (_timestamp - _currentRateInfo.lastTimestamp)) / 1e18;
        }
    }

    function previewRateInterestFees(
        address _fraxlendPairAddress,
        uint256 _timestamp,
        uint256 _blockNumber
    )
        external
        view
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            uint256 _newRate
        )
    {
        (_interestEarned, _newRate) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, uint64 _feeToProtocolRate, , ) = _fraxlendPair.currentRateInfo();
        (, , , uint256 _FEE_PRECISION, , , , ) = _fraxlendPair.getConstants();
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        if (_feeToProtocolRate > 0) {
            _feesAmount = (_interestEarned * _feeToProtocolRate) / _FEE_PRECISION;
            _feesShare = (_feesAmount * _totalAssetShares) / (_totalAssetAmount + _interestEarned - _feesAmount);
        }
    }

    function previewLiquidatePure(
        address _fraxlendPairAddress,
        uint128 _sharesToLiquidate,
        address _borrower
    )
        public
        view
        returns (
            uint128 _amountLiquidatorToRepay,
            uint256 _collateralForLiquidator,
            uint128 _sharesToSocialize,
            uint128 _amountToSocialize
        )
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);

        VaultAccount memory _totalBorrow;
        {
            (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
            _totalBorrow = VaultAccount({ amount: _totalBorrowAmount, shares: _totalBorrowShares });
        }

        int256 _leftoverCollateral;
        uint128 _borrowerShares;
        {
            uint256 _exchangeRate = previewUpdateExchangeRate(_fraxlendPairAddress);
            _borrowerShares = _fraxlendPair.userBorrowShares(_borrower).toUint128();
            (, uint256 _LIQ_PRECISION, , , uint256 _EXCHANGE_PRECISION, , , ) = _fraxlendPair.getConstants();
            uint256 _userCollateralBalance = _fraxlendPair.userCollateralBalance(_borrower);
            // Determine the liquidation amount in collateral units (i.e. how much debt is liquidator going to repay)
            uint256 _liquidationAmountInCollateralUnits = ((_totalBorrow.toAmount(_borrowerShares, false) *
                _exchangeRate) / _EXCHANGE_PRECISION);

            // We first optimistically calculate the amount of collateral to give the liquidator based on the higher clean liquidation fee
            // This fee only applies if the liquidator does a full liquidation
            uint256 _optimisticCollateralForLiquidator = (_liquidationAmountInCollateralUnits *
                (_LIQ_PRECISION + _fraxlendPair.cleanLiquidationFee())) / _LIQ_PRECISION;

            // Because interest accrues every block, _liquidationAmountInCollateralUnits (line 913) is an ever increasing value
            // This means that leftoverCollateral can occasionally go negative by a few hundred wei (cleanLiqFee premium covers this for liquidator)
            _leftoverCollateral = (_userCollateralBalance.toInt256() - _optimisticCollateralForLiquidator.toInt256());
            // If cleanLiquidation fee results in no leftover collateral, give liquidator all the collateral
            // This will only be true when there liquidator is cleaning out the position
            _collateralForLiquidator = _leftoverCollateral <= 0
                ? _userCollateralBalance
                : (_liquidationAmountInCollateralUnits * (_LIQ_PRECISION + _fraxlendPair.dirtyLiquidationFee())) /
                    _LIQ_PRECISION;
        }
        _amountLiquidatorToRepay = (_totalBorrow.toAmount(_sharesToLiquidate, true)).toUint128();

        // Determine if and how much debt to socialize
        if (_leftoverCollateral <= 0 && (_borrowerShares - _sharesToLiquidate) > 0) {
            // Socialize bad debt
            _sharesToSocialize = _borrowerShares - _sharesToLiquidate;
            _amountToSocialize = (_totalBorrow.toAmount(_sharesToSocialize, false)).toUint128();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

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

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.16;

struct VaultAccount {
    uint128 amount; // Total amount, analogous to market cap
    uint128 shares; // Total shares, analogous to shares outstanding
}

/// @title VaultAccount Library
/// @author Drake Evans (Frax Finance) github.com/drakeevans, modified from work by @Boring_Crypto github.com/boring_crypto
/// @notice Provides a library for use with the VaultAccount struct, provides convenient math implementations
/// @dev Uses uint128 to save on storage
library VaultAccountingLibrary {
    /// @notice Calculates the shares value in relationship to `amount` and `total`
    /// @dev Given an amount, return the appropriate number of shares
    function toShares(
        VaultAccount memory total,
        uint256 amount,
        bool roundUp
    ) internal pure returns (uint256 shares) {
        if (total.amount == 0) {
            shares = amount;
        } else {
            shares = (amount * total.shares) / total.amount;
            if (roundUp && (shares * total.amount) / total.shares < amount) {
                shares = shares + 1;
            }
        }
    }

    /// @notice Calculates the amount value in relationship to `shares` and `total`
    /// @dev Given a number of shares, returns the appropriate amount
    function toAmount(
        VaultAccount memory total,
        uint256 shares,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        if (total.shares == 0) {
            amount = shares;
        } else {
            amount = (shares * total.amount) / total.shares;
            if (roundUp && (amount * total.shares) / total.amount < shares) {
                amount = amount + 1;
            }
        }
    }
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.16;

interface IFraxlendPair {
    function CIRCUIT_BREAKER_ADDRESS() external view returns (address);

    function COMPTROLLER_ADDRESS() external view returns (address);

    function DEPLOYER_ADDRESS() external view returns (address);

    function FRAXLEND_WHITELIST_ADDRESS() external view returns (address);

    function TIME_LOCK_ADDRESS() external view returns (address);

    function addCollateral(uint256 _collateralAmount, address _borrower) external;

    function addInterest()
        external
        returns (
            uint256 _interestEarned,
            uint256 _feesAmount,
            uint256 _feesShare,
            uint64 _newRate
        );

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approvedBorrowers(address) external view returns (bool);

    function approvedLenders(address) external view returns (bool);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function borrowAsset(
        uint256 _borrowAmount,
        uint256 _collateralAmount,
        address _receiver
    ) external returns (uint256 _shares);

    function borrowerWhitelistActive() external view returns (bool);

    function changeFee(uint32 _newFee) external;

    function cleanLiquidationFee() external view returns (uint256);

    function collateralContract() external view returns (address);

    function currentRateInfo()
        external
        view
        returns (
            uint64 lastBlock,
            uint64 feeToProtocolRate,
            uint64 lastTimestamp,
            uint64 ratePerSec
        );

    function decimals() external pure returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function deposit(uint256 _amount, address _receiver) external returns (uint256 _sharesReceived);

    function dirtyLiquidationFee() external view returns (uint256);

    function exchangeRateInfo() external view returns (uint32 lastTimestamp, uint224 exchangeRate);

    function getConstants()
        external
        pure
        returns (
            uint256 _LTV_PRECISION,
            uint256 _LIQ_PRECISION,
            uint256 _UTIL_PREC,
            uint256 _FEE_PRECISION,
            uint256 _EXCHANGE_PRECISION,
            uint64 _DEFAULT_INT,
            uint16 _DEFAULT_PROTOCOL_FEE,
            uint256 _MAX_PROTOCOL_FEE
        );

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function initialize(
        string calldata _name,
        address[] calldata _approvedBorrowers,
        address[] calldata _approvedLenders,
        bytes calldata _rateInitCallData
    ) external;

    function lenderWhitelistActive() external view returns (bool);

    function leveragedPosition(
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOutMin,
        address[] calldata _path
    ) external returns (uint256 _totalCollateralBalance);

    function liquidate(
        uint128 _sharesToLiquidate,
        uint256 _deadline,
        address _borrower
    ) external returns (uint256 _collateralForLiquidator);

    function maturityDate() external view returns (uint256);

    function maxLTV() external view returns (uint256);

    function name() external view returns (string calldata);

    function oracleDivide() external view returns (address);

    function oracleMultiply() external view returns (address);

    function oracleNormalization() external view returns (uint256);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function penaltyRate() external view returns (uint256);

    function rateContract() external view returns (address);

    function rateInitCallData() external view returns (bytes calldata);

    function redeem(
        uint256 _shares,
        address _receiver,
        address _owner
    ) external returns (uint256 _amountToReturn);

    function removeCollateral(uint256 _collateralAmount, address _receiver) external;

    function renounceOwnership() external;

    function repayAsset(uint256 _shares, address _borrower) external returns (uint256 _amountToRepay);

    function repayAssetWithCollateral(
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] calldata _path
    ) external returns (uint256 _amountAssetOut);

    function setApprovedBorrowers(address[] calldata _borrowers, bool _approval) external;

    function setApprovedLenders(address[] calldata _lenders, bool _approval) external;

    function setSwapper(address _swapper, bool _approval) external;

    function setTimeLock(address _newAddress) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string calldata);

    function toBorrowAmount(uint256 _shares, bool _roundUp) external view returns (uint256);

    function toBorrowShares(uint256 _amount, bool _roundUp) external view returns (uint256);

    function totalAsset() external view returns (uint128 amount, uint128 shares);

    function totalBorrow() external view returns (uint128 amount, uint128 shares);

    function totalCollateral() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateExchangeRate() external returns (uint256 _exchangeRate);

    function userBorrowShares(address) external view returns (uint256);

    function userCollateralBalance(address) external view returns (uint256);

    function version() external view returns (string calldata);

    function withdrawFees(uint128 _shares, address _recipient) external returns (uint256 _amountToTransfer);
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.16;

interface IRateCalculator {
    function name() external pure returns (string memory);

    function requireValidInitData(bytes calldata _initData) external pure;

    function getConstants() external pure returns (bytes memory _calldata);

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec);
}