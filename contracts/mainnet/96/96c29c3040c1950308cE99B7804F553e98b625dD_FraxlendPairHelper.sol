// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

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
import "./interfaces/IRateCalculatorV2.sol";

contract FraxlendPairHelper {
    using VaultAccountingLibrary for VaultAccount;
    using SafeCast for uint256;

    error OracleLTEZero(address _oracle);

    string public constant version = "1.1.0";

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
        uint64 fullUtilizationRate;
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
        returns (uint256 _userAssetShares, uint256 _userBorrowShares, uint256 _userCollateralBalance)
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

    function previewRateInterest(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (uint256 _interestEarned, uint256 _newRate)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, , uint256 _UTIL_PREC, , , uint64 _DEFAULT_INT, , ) = _fraxlendPair.getConstants();

        // Add interest only once per block
        CurrentRateInfo memory _currentRateInfo;
        {
            (uint64 lastBlock, uint64 feeToProtocolRate, uint64 lastTimestamp, uint64 ratePerSec, uint64 _fullUtilizationRate) = _fraxlendPair
                .currentRateInfo();
            _currentRateInfo = CurrentRateInfo({
                lastBlock: lastBlock,
                feeToProtocolRate: feeToProtocolRate,
                lastTimestamp: lastTimestamp,
                ratePerSec: ratePerSec,
                fullUtilizationRate: _fullUtilizationRate
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
                try _fraxlendPair.version() {
                    (_newRate, ) = IRateCalculatorV2(_fraxlendPair.rateContract()).getNewRate(
                        _timestamp - _currentRateInfo.lastTimestamp,
                        (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                        _currentRateInfo.fullUtilizationRate
                    );
                } catch {
                    _newRate = IRateCalculator(_fraxlendPair.rateContract()).getNewRate(
                        abi.encode(
                            _currentRateInfo.ratePerSec,
                            _timestamp - _currentRateInfo.lastTimestamp,
                            (_totalBorrow.amount * _UTIL_PREC) / _totalAsset.amount,
                            _blockNumber - _currentRateInfo.lastBlock
                        ),
                        abi.encode()
                    );
                }
            }

            // Calculate interest accrued
            _interestEarned = (_totalBorrow.amount * _newRate * (_timestamp - _currentRateInfo.lastTimestamp)) / 1e18;
        }
    }

    function previewRateInterestFees(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        external
        view
        returns (uint256 _interestEarned, uint256 _feesAmount, uint256 _feesShare, uint256 _newRate)
    {
        (_interestEarned, _newRate) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (, uint64 _feeToProtocolRate, , , ) = _fraxlendPair.currentRateInfo();
        (, , , uint256 _FEE_PRECISION, , , , ) = _fraxlendPair.getConstants();
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        if (_feeToProtocolRate > 0) {
            _feesAmount = (_interestEarned * _feeToProtocolRate) / _FEE_PRECISION;
            _feesShare = (_feesAmount * _totalAssetShares) / (_totalAssetAmount + _interestEarned - _feesAmount);
        }
    }

    function previewLiquidatePure(address _fraxlendPairAddress, uint128 _sharesToLiquidate, address _borrower)
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

    function previewTotalBorrow(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (VaultAccount memory _previewTotalBorrow)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (uint128 _totalBorrowAmount, uint128 _totalBorrowShares) = _fraxlendPair.totalBorrow();
        (uint256 _interestEarned, ) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        _previewTotalBorrow.amount = _totalBorrowAmount + _interestEarned.toUint128();
        _previewTotalBorrow.shares = _totalBorrowShares;
    }

    function previewTotalAsset(address _fraxlendPairAddress, uint256 _timestamp, uint256 _blockNumber)
        public
        view
        returns (VaultAccount memory _previewTotalBorrow)
    {
        IFraxlendPair _fraxlendPair = IFraxlendPair(_fraxlendPairAddress);
        (uint128 _totalAssetAmount, uint128 _totalAssetShares) = _fraxlendPair.totalAsset();
        (uint256 _interestEarned, ) = previewRateInterest(_fraxlendPairAddress, _timestamp, _blockNumber);
        _previewTotalBorrow.amount = _totalAssetAmount + _interestEarned.toUint128();
        _previewTotalBorrow.shares = _totalAssetShares;
    }

    function toBorrowAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _amount, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalBorrow = previewTotalBorrow(_fraxlendPairAddress, _timestamp, _blockNumber);
        _amount = _previewTotalBorrow.toAmount(_shares, _roundUp);
        _totalAmount = _previewTotalBorrow.amount;
        _totalShares = _previewTotalBorrow.shares;
    }

    function toBorrowShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _shares, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalBorrow = previewTotalBorrow(_fraxlendPairAddress, _timestamp, _blockNumber);
        _shares = _previewTotalBorrow.toShares(_amount, _roundUp);
        _totalAmount = _previewTotalBorrow.amount;
        _totalShares = _previewTotalBorrow.shares;
    }

    function toAssetAmount(
        address _fraxlendPairAddress,
        uint256 _shares,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _amount, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalAsset = previewTotalAsset(_fraxlendPairAddress, _timestamp, _blockNumber);
        _amount = _previewTotalAsset.toAmount(_shares, _roundUp);
        _totalAmount = _previewTotalAsset.amount;
        _totalShares = _previewTotalAsset.shares;
    }

    function toAssetShares(
        address _fraxlendPairAddress,
        uint256 _amount,
        uint256 _timestamp,
        uint256 _blockNumber,
        bool _roundUp
    ) external view returns (uint256 _shares, uint256 _totalAmount, uint256 _totalShares) {
        VaultAccount memory _previewTotalAsset = previewTotalAsset(_fraxlendPairAddress, _timestamp, _blockNumber);
        _shares = _previewTotalAsset.toShares(_amount, _roundUp);
        _totalAmount = _previewTotalAsset.amount;
        _totalShares = _previewTotalAsset.shares;
    }
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

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
pragma solidity >=0.8.17;

interface IRateCalculator {
    function name() external pure returns (string memory);

    function requireValidInitData(bytes calldata _initData) external pure;

    function getConstants() external pure returns (bytes memory _calldata);

    function getNewRate(bytes calldata _data, bytes calldata _initData) external pure returns (uint64 _newRatePerSec);
}

// SPDX-License-Identifier: ISC
pragma solidity ^0.8.17;

interface IRateCalculatorV2 {
    function name() external view returns (string memory);

    function version() external view returns (uint256, uint256, uint256);

    function getNewRate(uint256 _deltaTime, uint256 _utilization, uint64 _maxInterest)
        external
        view
        returns (uint64 _newRatePerSec, uint64 _newMaxInterest);
}

// SPDX-License-Identifier: ISC
pragma solidity >=0.8.17;

interface IFraxlendPair {
    function CIRCUIT_BREAKER_ADDRESS() external view returns (address);

    function COMPTROLLER_ADDRESS() external view returns (address);

    function DEPLOYER_ADDRESS() external view returns (address);

    function FRAXLEND_WHITELIST_ADDRESS() external view returns (address);

    function TIME_LOCK_ADDRESS() external view returns (address);

    function addCollateral(uint256 _collateralAmount, address _borrower) external;

    function addInterest()
        external
        returns (uint256 _interestEarned, uint256 _feesAmount, uint256 _feesShare, uint64 _newRate);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function approvedBorrowers(address) external view returns (bool);

    function approvedLenders(address) external view returns (bool);

    function asset() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function borrowAsset(uint256 _borrowAmount, uint256 _collateralAmount, address _receiver)
        external
        returns (uint256 _shares);

    function borrowerWhitelistActive() external view returns (bool);

    function changeFee(uint32 _newFee) external;

    function cleanLiquidationFee() external view returns (uint256);

    function collateralContract() external view returns (address);

    function currentRateInfo()
        external
        view
        returns (
            uint32 lastBlock,
            uint32 feeToProtocolRate,
            uint64 lastTimestamp,
            uint64 ratePerSec,
            uint64 fullUtilizationRate
        );

    function decimals() external view returns (uint8);

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

    function getImmutableAddressBool()
        external
        view
        returns (
            address _assetContract,
            address _collateralContract,
            address _oracleMultiply,
            address _oracleDivide,
            address _rateContract,
            address _DEPLOYER_CONTRACT,
            address _COMPTROLLER_ADDRESS,
            address _FRAXLEND_WHITELIST,
            bool _borrowerWhitelistActive,
            bool _lenderWhitelistActive
        );

    function getImmutableUint256()
        external
        view
        returns (
            uint256 _oracleNormalization,
            uint256 _maxLTV,
            uint256 _cleanLiquidationFee,
            uint256 _maturityDate,
            uint256 _penaltyRate
        );

    function getPairAccounting()
        external
        view
        returns (
            uint128 _totalAssetAmount,
            uint128 _totalAssetShares,
            uint128 _totalBorrowAmount,
            uint128 _totalBorrowShares,
            uint256 _totalCollateral
        );

    function getUserSnapshot(address _address)
        external
        view
        returns (uint256 _userAssetShares, uint256 _userBorrowShares, uint256 _userCollateralBalance);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function lenderWhitelistActive() external view returns (bool);

    function leveragedPosition(
        address _swapperAddress,
        uint256 _borrowAmount,
        uint256 _initialCollateralAmount,
        uint256 _amountCollateralOutMin,
        address[] memory _path
    ) external returns (uint256 _totalCollateralBalance);

    function liquidate(uint128 _sharesToLiquidate, uint256 _deadline, address _borrower)
        external
        returns (uint256 _collateralForLiquidator);

    function maturityDate() external view returns (uint256);

    function maxLTV() external view returns (uint256);

    function maxOracleDelay() external view returns (uint256);

    function name() external view returns (string memory);

    function oracleDivide() external view returns (address);

    function oracleMultiply() external view returns (address);

    function oracleNormalization() external view returns (uint256);

    function owner() external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function penaltyRate() external view returns (uint256);

    function rateContract() external view returns (address);

    function redeem(uint256 _shares, address _receiver, address _owner) external returns (uint256 _amountToReturn);

    function removeCollateral(uint256 _collateralAmount, address _receiver) external;

    function renounceOwnership() external;

    function repayAsset(uint256 _shares, address _borrower) external returns (uint256 _amountToRepay);

    function repayAssetWithCollateral(
        address _swapperAddress,
        uint256 _collateralToSwap,
        uint256 _amountAssetOutMin,
        address[] memory _path
    ) external returns (uint256 _amountAssetOut);

    function setApprovedBorrowers(address[] memory _borrowers, bool _approval) external;

    function setApprovedLenders(address[] memory _lenders, bool _approval) external;

    function setMaxOracleDelay(uint256 _newDelay) external;

    function setSwapper(address _swapper, bool _approval) external;

    function setTimeLock(address _newAddress) external;

    function swappers(address) external view returns (bool);

    function symbol() external view returns (string memory);

    function toAssetAmount(uint256 _shares, bool _roundUp) external view returns (uint256);

    function toAssetShares(uint256 _amount, bool _roundUp) external view returns (uint256);

    function toBorrowAmount(uint256 _shares, bool _roundUp) external view returns (uint256);

    function toBorrowShares(uint256 _amount, bool _roundUp) external view returns (uint256);

    function totalAsset() external view returns (uint128 amount, uint128 shares);

    function totalBorrow() external view returns (uint128 amount, uint128 shares);

    function totalCollateral() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function transferOwnership(address newOwner) external;

    function unpause() external;

    function updateExchangeRate() external returns (uint256 _exchangeRate);

    function userBorrowShares(address) external view returns (uint256);

    function userCollateralBalance(address) external view returns (uint256);

    function version() external pure returns (uint256 _major, uint256 _minor, uint256 _patch);

    function withdrawFees(uint128 _shares, address _recipient) external returns (uint256 _amountToTransfer);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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