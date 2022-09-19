// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.4;

import "./interfaces/IMorpho.sol";
import "./libraries/Types.sol";
import "./libraries/CompoundMath.sol";

contract MorphoChecker {
    using CompoundMath for uint256;

    function isLiquidatable(
        IMorpho _morpho,
        address _user,
        address _poolTokenAddress,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (bool) {
        ICompoundOracle oracle = ICompoundOracle(_morpho.comptroller().oracle());
        address[] memory enteredMarkets = _morpho.getEnteredMarkets(_user);
        uint256 numberOfEnteredMarkets = enteredMarkets.length;

        Types.AssetLiquidityData memory assetData;
        uint256 maxDebtValue;
        uint256 debtValue;
        uint256 i;

        while (i < numberOfEnteredMarkets) {
            address poolTokenEntered = enteredMarkets[i];

            assetData = _getUserLiquidityDataForAsset(_morpho, _user, poolTokenEntered, oracle);
            maxDebtValue += assetData.maxDebtValue;
            debtValue += assetData.debtValue;

            if (_poolTokenAddress == poolTokenEntered) {
                if (_borrowedAmount > 0)
                    debtValue += _borrowedAmount.mul(assetData.underlyingPrice);

                if (_withdrawnAmount > 0)
                    maxDebtValue -= _withdrawnAmount.mul(assetData.underlyingPrice).mul(
                        assetData.collateralFactor
                    );
            }

            unchecked {
                ++i;
            }
        }

        return debtValue > maxDebtValue;
    }

    function _getUserLiquidityDataForAsset(
        IMorpho _morpho,
        address _user,
        address _poolTokenAddress,
        ICompoundOracle _oracle
    ) internal view returns (Types.AssetLiquidityData memory assetData) {
        assetData.underlyingPrice = _oracle.getUnderlyingPrice(_poolTokenAddress);
        if (assetData.underlyingPrice == 0) revert("CompoundOracleFailed");
        (, assetData.collateralFactor, ) = _morpho.comptroller().markets(_poolTokenAddress);

        assetData.collateralValue = _getUserSupplyBalanceInOf(_morpho, _poolTokenAddress, _user)
            .mul(assetData.underlyingPrice);
        assetData.debtValue = _getUserBorrowBalanceInOf(_morpho, _poolTokenAddress, _user).mul(
            assetData.underlyingPrice
        );
        assetData.maxDebtValue = assetData.collateralValue.mul(assetData.collateralFactor);
    }

    function _getUserSupplyBalanceInOf(
        IMorpho _morpho,
        address _poolTokenAddress,
        address _user
    ) internal view returns (uint256) {
        Types.SupplyBalance memory userSupplyBalance = _morpho.supplyBalanceInOf(
            _poolTokenAddress,
            _user
        );
        return
            userSupplyBalance.inP2P.mul(_morpho.p2pSupplyIndex(_poolTokenAddress)) +
            userSupplyBalance.onPool.mul(ICToken(_poolTokenAddress).exchangeRateStored());
    }

    function _getUserBorrowBalanceInOf(
        IMorpho _morpho,
        address _poolTokenAddress,
        address _user
    ) internal view returns (uint256) {
        Types.BorrowBalance memory userBorrowBalance = _morpho.borrowBalanceInOf(
            _poolTokenAddress,
            _user
        );
        return
            userBorrowBalance.inP2P.mul(_morpho.p2pBorrowIndex(_poolTokenAddress)) +
            userBorrowBalance.onPool.mul(ICToken(_poolTokenAddress).borrowIndex());
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./IInterestRatesManager.sol";
import "./IPositionsManager.sol";
import "./IRewardsManager.sol";
import "./IIncentivesVault.sol";

import "../libraries/Types.sol";

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function isClaimRewardsPaused() external view returns (bool);
    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function dustThreshold() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function enteredMarkets(address) external view returns (address);
    function deltas(address) external view returns (Types.Delta memory);
    function marketsCreated() external view returns (address[] memory);
    function marketParameters(address) external view returns (Types.MarketParameters memory);
    function p2pDisabled(address) external view returns (bool);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function lastPoolIndexes(address) external view returns (Types.LastPoolIndexes memory);
    function marketStatus(address) external view returns (Types.MarketStatus memory);
    function comptroller() external view returns (IComptroller);
    function interestRatesManager() external view returns (IInterestRatesManager);
    function rewardsManager() external view returns (IRewardsManager);
    function positionsManager() external view returns (IPositionsManager);
    function incentiveVault() external view returns (IIncentivesVault);
    function treasuryVault() external view returns (address);
    function cEth() external view returns (address);
    function wEth() external view returns (address);

    /// GETTERS ///

    function updateP2PIndexes(address _poolTokenAddress) external;
    function getEnteredMarkets(address _user) external view returns (address[] memory enteredMarkets_);
    function getAllMarkets() external view returns (address[] memory marketsCreated_);
    function getHead(address _poolTokenAddress, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolTokenAddress, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setIncentivesVault(address _newIncentivesVault) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setInterestRatesManager(IInterestRatesManager _interestRatesManager) external;
    function setTreasuryVault(address _treasuryVault) external;
    function setDustThreshold(uint256 _dustThreshold) external;
    function setP2PDisabled(address _poolTokenAddress, bool _p2pDisabled) external;
    function setReserveFactor(address _poolTokenAddress, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolTokenAddress, uint16 _p2pIndexCursor) external;
    function setPauseStatusForAllMarkets(bool _newStatus) external;
    function setPauseStatus(address _poolTokenAddress, bool _newStatus) external;
    function setPartialPauseStatus(address _poolTokenAddress, bool _newStatus) external;
    function setPauseStatus(address _poolTokenAddress) external;
    function setPartialPauseStatus(address _poolTokenAddress) external;
    function claimToTreasury(address[] calldata _poolTokenAddresses, uint256[] calldata _amounts) external;
    function createMarket(address _poolTokenAddress, Types.MarketParameters calldata _params) external;

    /// USERS ///

    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function supply(address _poolTokenAddress, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolTokenAddress, uint256 _amount) external;
    function borrow(address _poolTokenAddress, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolTokenAddress, uint256 _amount) external;
    function repay(address _poolTokenAddress, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowedAddress, address _poolTokenCollateralAddress, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _cTokenAddresses, bool _tradeForMorphoToken) external returns (uint256 claimedAmount);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title Types.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Common types and structs used in Moprho contracts.
library Types {
    /// ENUMS ///

    enum PositionType {
        SUPPLIERS_IN_P2P,
        SUPPLIERS_ON_POOL,
        BORROWERS_IN_P2P,
        BORROWERS_ON_POOL
    }

    /// STRUCTS ///

    struct SupplyBalance {
        uint256 inP2P; // In supplier's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests earned by suppliers in peer-to-peer. Multiply by the peer-to-peer supply index to get the underlying amount.
        uint256 onPool; // In cToken. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In borrower's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In cdUnit, a unit that grows in value, to keep track of the debt increase when borrowers are on Compound. Multiply by the pool borrow index to get the underlying amount.
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in pool supply unit).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in pool borrow unit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer supply unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer borrow unit).
    }

    struct AssetLiquidityData {
        uint256 collateralValue; // The collateral value of the asset.
        uint256 maxDebtValue; // The maximum possible debt value of the asset.
        uint256 debtValue; // The debt value of the asset.
        uint256 underlyingPrice; // The price of the token.
        uint256 collateralFactor; // The liquidation threshold applied on this token.
    }

    struct LiquidityData {
        uint256 collateralValue; // The collateral value.
        uint256 maxDebtValue; // The maximum debt value possible.
        uint256 debtValue; // The debt value.
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct LastPoolIndexes {
        uint32 lastUpdateBlockNumber; // The last time the peer-to-peer indexes were updated.
        uint112 lastSupplyPoolIndex; // Last pool supply index.
        uint112 lastBorrowPoolIndex; // Last pool borrow index.
    }

    struct MarketParameters {
        uint16 reserveFactor; // Proportion of the interest earned by users sent to the DAO for each market, in basis point (100% = 10 000). The value is set at market creation.
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
    }

    struct MarketStatus {
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
        bool isPartiallyPaused; // Whether the market is partially paused or not (only supply and borrow are frozen).
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title CompoundMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Library emulating in solidity 8+ the behavior of Compound's mulScalarTruncate and divScalarByExpTruncate functions.
library CompoundMath {
    /// ERRORS ///

    /// @notice Reverts when the number exceeds 224 bits.
    error NumberExceeds224Bits();

    /// @notice Reverts when the number exceeds 32 bits.
    error NumberExceeds32Bits();

    /// INTERNAL ///

    function mul(uint256 x, uint256 y) internal pure returns (uint256) {
        return (x * y) / 1e18;
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256) {
        return ((1e18 * x * 1e18) / y) / 1e18;
    }

    function safe224(uint256 n) internal pure returns (uint224) {
        if (n >= 2**224) revert NumberExceeds224Bits();
        return uint224(n);
    }

    function safe32(uint256 n) internal pure returns (uint32) {
        if (n >= 2**32) revert NumberExceeds32Bits();
        return uint32(n);
    }

    function min(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return a < b ? a < c ? a : c : b < c ? b : c;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a - b : 0;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IInterestRatesManager {
    function updateP2PIndexes(address _marketAddress) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./compound/ICompound.sol";

interface IRewardsManager {
    function initialize(address _morpho) external;

    function claimRewards(address[] calldata, address) external returns (uint256);

    function userUnclaimedCompRewards(address) external view returns (uint256);

    function compSupplierIndex(address, address) external view returns (uint256);

    function compBorrowerIndex(address, address) external view returns (uint256);

    function getLocalCompSupplyState(address _cTokenAddress)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function getLocalCompBorrowState(address _cTokenAddress)
        external
        view
        returns (IComptroller.CompMarketState memory);

    function accrueUserSupplyUnclaimedRewards(
        address,
        address,
        uint256
    ) external;

    function accrueUserBorrowUnclaimedRewards(
        address,
        address,
        uint256
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IPositionsManager {
    function supplyLogic(
        address _poolTokenAddress,
        address _supplier,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function borrowLogic(
        address _poolTokenAddress,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function withdrawLogic(
        address _poolTokenAddress,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) external;

    function repayLogic(
        address _poolTokenAddress,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function liquidateLogic(
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress,
        address _borrower,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./IOracle.sol";

interface IIncentivesVault {
    function setOracle(IOracle _newOracle) external;

    function setMorphoDao(address _newMorphoDao) external;

    function setBonus(uint256 _newBonus) external;

    function setPauseStatus(bool _newStatus) external;

    function transferTokensToDao(address _token, uint256 _amount) external;

    function tradeCompForMorphoTokens(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface ICEth {
    function accrueInterest() external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external returns (uint256);

    function borrowBalanceStored(address) external returns (uint256);

    function mint() external payable;

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function redeem(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function balanceOf(address) external returns (uint256);

    function balanceOfUnderlying(address account) external returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow() external payable;

    function borrowBalanceCurrent(address) external returns (uint256);

    function borrowRatePerBlock() external view returns (uint256);
}

interface IComptroller {
    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

    function liquidationIncentiveMantissa() external view returns (uint256);

    function closeFactorMantissa() external view returns (uint256);

    function admin() external view returns (address);

    function oracle() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isComped
        );

    function enterMarkets(address[] calldata cTokens) external returns (uint256[] memory);

    function exitMarket(address cToken) external returns (uint256);

    function mintAllowed(
        address cToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintVerify(
        address cToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external;

    function redeemAllowed(
        address cToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address cToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function borrowAllowed(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowVerify(
        address cToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function repayBorrowAllowed(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address cToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function transferAllowed(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferVerify(
        address cToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view returns (uint256, uint256);

    function getAccountLiquidity(address)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getHypotheticalAccountLiquidity(
        address,
        address,
        uint256,
        uint256
    )
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function checkMembership(address, address) external view returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (CompMarketState memory);

    function compBorrowState(address) external view returns (CompMarketState memory);

    function getCompAddress() external view returns (address);

    function _setPriceOracle(address newOracle) external returns (uint256);

    function _setMintPaused(ICToken cToken, bool state) external returns (bool);

    function _setBorrowPaused(ICToken cToken, bool state) external returns (bool);

    function _setCollateralFactor(ICToken cToken, uint256 newCollateralFactorMantissa)
        external
        returns (uint256);

    function _setCompSpeeds(
        ICToken[] memory cTokens,
        uint256[] memory supplySpeeds,
        uint256[] memory borrowSpeeds
    ) external;
}

interface IInterestRateModel {
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view returns (uint256);

    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view returns (uint256);
}

interface ICToken {
    function isCToken() external returns (bool);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view returns (uint256);

    function supplyRatePerBlock() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account) external view returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getCash() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function borrowRate() external returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrow(uint256) external returns (uint256);

    function repayBorrow(uint256) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address cTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function mint(uint256) external returns (uint256);

    function redeemUnderlying(uint256) external returns (uint256);

    function accrueInterest() external returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalBorrows() external view returns (uint256);

    function accrualBlockNumber() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function interestRateModel() external view returns (IInterestRateModel);

    function reserveFactorMantissa() external view returns (uint256);

    function initialExchangeRateMantissa() external view returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external returns (uint256);

    function _acceptAdmin() external returns (uint256);

    function _setComptroller(IComptroller newComptroller) external returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setInterestRateModel(IInterestRateModel newInterestRateModel)
        external
        returns (uint256);
}

interface ICEther is ICToken {
    function mint() external payable;

    function repayBorrow() external payable;
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IOracle {
    function consult(uint256 _amountIn) external returns (uint256);
}