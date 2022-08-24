// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./MarketsLens.sol";

/// @title Lens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice This contract exposes an API to query on-chain data related to the Morpho Protocol, its markets and its users.
contract Lens is MarketsLens {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @param _morpho The address of the main Morpho contract.
    constructor(address _morpho) LensStorage(_morpho) {}

    /// EXTERNAL ///

    /// @notice Computes and returns the total distribution of supply through Morpho, using virtually updated indexes.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in ETH).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in ETH).
    /// @return totalSupplyAmount The total amount supplied through Morpho (in ETH).
    function getTotalSupply()
        external
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 totalSupplyAmount
        )
    {
        address[] memory markets = morpho.getMarketsCreated();
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());

        uint256 nbMarkets = markets.length;
        for (uint256 i; i < nbMarkets; ) {
            address _poolToken = markets[i];

            (
                address underlyingToken,
                uint256 marketP2PSupplyAmount,
                uint256 marketPoolSupplyAmount
            ) = _getTotalMarketSupply(_poolToken);

            uint256 underlyingPrice = oracle.getAssetPrice(underlyingToken);
            (, , , uint256 reserveDecimals, ) = pool
            .getConfiguration(underlyingToken)
            .getParamsMemory();

            uint256 tokenUnit = 10**reserveDecimals;
            p2pSupplyAmount += (marketP2PSupplyAmount * underlyingPrice) / tokenUnit;
            poolSupplyAmount += (marketPoolSupplyAmount * underlyingPrice) / tokenUnit;

            unchecked {
                ++i;
            }
        }

        totalSupplyAmount = p2pSupplyAmount + poolSupplyAmount;
    }

    /// @notice Computes and returns the total distribution of borrows through Morpho, using virtually updated indexes.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in ETH).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in ETH).
    /// @return totalBorrowAmount The total amount borrowed through Morpho (in ETH).
    function getTotalBorrow()
        external
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        )
    {
        address[] memory markets = morpho.getMarketsCreated();
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());

        uint256 nbMarkets = markets.length;
        for (uint256 i; i < nbMarkets; ) {
            address _poolToken = markets[i];

            (
                address underlyingToken,
                uint256 marketP2PBorrowAmount,
                uint256 marketPoolBorrowAmount
            ) = _getTotalMarketBorrow(_poolToken);

            uint256 underlyingPrice = oracle.getAssetPrice(underlyingToken);
            (, , , uint256 reserveDecimals, ) = pool
            .getConfiguration(underlyingToken)
            .getParamsMemory();

            uint256 tokenUnit = 10**reserveDecimals;
            p2pBorrowAmount += (marketP2PBorrowAmount * underlyingPrice) / tokenUnit;
            poolBorrowAmount += (marketPoolBorrowAmount * underlyingPrice) / tokenUnit;

            unchecked {
                ++i;
            }
        }

        totalBorrowAmount = p2pBorrowAmount + poolBorrowAmount;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./RatesLens.sol";

/// @title MarketsLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol markets.
abstract contract MarketsLens is RatesLens {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using WadRayMath for uint256;

    /// EXTERNAL ///

    /// @notice Checks if a market is created.
    /// @param _poolToken The address of the market to check.
    /// @return true if the market is created and not paused, otherwise false.
    function isMarketCreated(address _poolToken) external view returns (bool) {
        return morpho.market(_poolToken).isCreated;
    }

    /// @notice Checks if a market is created and not paused.
    /// @param _poolToken The address of the market to check.
    /// @return true if the market is created and not paused, otherwise false.
    function isMarketCreatedAndNotPaused(address _poolToken) external view returns (bool) {
        Types.Market memory market = morpho.market(_poolToken);
        return market.isCreated && !market.isPaused;
    }

    /// @notice Checks if a market is created and not paused or partially paused.
    /// @param _poolToken The address of the market to check.
    /// @return true if the market is created, not paused and not partially paused, otherwise false.
    function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolToken)
        external
        view
        returns (bool)
    {
        Types.Market memory market = morpho.market(_poolToken);
        return market.isCreated && !market.isPaused && !market.isPartiallyPaused;
    }

    /// @notice Returns all created markets.
    /// @return marketsCreated The list of market addresses.
    function getAllMarkets() external view returns (address[] memory marketsCreated) {
        return morpho.getMarketsCreated();
    }

    /// @notice For a given market, returns the average supply/borrow rates and amounts of underlying asset supplied and borrowed through Morpho, on the underlying pool and matched peer-to-peer.
    /// @dev The returned values are not updated.
    /// @param _poolToken The address of the market of which to get main data.
    /// @return avgSupplyRatePerYear The average supply rate experienced on the given market.
    /// @return avgBorrowRatePerYear The average borrow rate experienced on the given market.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getMainMarketData(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 avgBorrowRatePerYear,
            uint256 p2pSupplyAmount,
            uint256 p2pBorrowAmount,
            uint256 poolSupplyAmount,
            uint256 poolBorrowAmount
        )
    {
        (avgSupplyRatePerYear, p2pSupplyAmount, poolSupplyAmount) = getAverageSupplyRatePerYear(
            _poolToken
        );
        (avgBorrowRatePerYear, p2pBorrowAmount, poolBorrowAmount) = getAverageBorrowRatePerYear(
            _poolToken
        );
    }

    /// @notice Returns non-updated indexes, the block at which they were last updated and the total deltas of a given market.
    /// @param _poolToken The address of the market of which to get advanced data.
    /// @return p2pSupplyIndex The peer-to-peer supply index of the given market (in ray).
    /// @return p2pBorrowIndex The peer-to-peer borrow index of the given market (in ray).
    /// @return poolSupplyIndex The pool supply index of the given market (in ray).
    /// @return poolBorrowIndex The pool borrow index of the given market (in ray).
    /// @return lastUpdateTimestamp The block number at which pool indexes were last updated.
    /// @return p2pSupplyDelta The total supply delta (in underlying).
    /// @return p2pBorrowDelta The total borrow delta (in underlying).
    function getAdvancedMarketData(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex,
            uint32 lastUpdateTimestamp,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        )
    {
        (p2pSupplyIndex, p2pBorrowIndex, poolSupplyIndex, poolBorrowIndex) = getIndexes(_poolToken);

        Types.Delta memory delta = morpho.deltas(_poolToken);
        p2pSupplyDelta = delta.p2pSupplyDelta.rayMul(poolSupplyIndex);
        p2pBorrowDelta = delta.p2pBorrowDelta.rayMul(poolBorrowIndex);
        lastUpdateTimestamp = morpho.poolIndexes(_poolToken).lastUpdateTimestamp;
    }

    /// @notice Returns market's configuration.
    /// @return underlying The underlying token address.
    /// @return isCreated Whether the market is created or not.
    /// @return isP2PDisabled Whether user are put in peer-to-peer or not.
    /// @return isPaused Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
    /// @return isPartiallyPaused Whether the market is partially paused or not (only supply and borrow are frozen).
    /// @return reserveFactor The reserve factor applied to this market.
    /// @return p2pIndexCursor The p2p index cursor applied to this market.
    /// @return loanToValue The ltv of the given market, set by AAVE.
    /// @return liquidationThreshold The liquidation threshold of the given market, set by AAVE.
    /// @return liquidationBonus The liquidation bonus of the given market, set by AAVE.
    /// @return decimals The number of decimals of the underlying token.
    function getMarketConfiguration(address _poolToken)
        external
        view
        returns (
            address underlying,
            bool isCreated,
            bool isP2PDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 loanToValue,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 decimals
        )
    {
        underlying = IAToken(_poolToken).UNDERLYING_ASSET_ADDRESS();

        Types.Market memory market = morpho.market(_poolToken);
        isCreated = market.isCreated;
        isP2PDisabled = market.isP2PDisabled;
        isPaused = market.isPaused;
        isPartiallyPaused = market.isPartiallyPaused;
        reserveFactor = market.reserveFactor;
        p2pIndexCursor = market.p2pIndexCursor;

        (loanToValue, liquidationThreshold, liquidationBonus, decimals, ) = pool
        .getConfiguration(underlying)
        .getParamsMemory();
    }

    /// PUBLIC ///

    /// @notice Computes and returns the total distribution of supply for a given market.
    /// @param _poolToken The address of the market to check.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function getTotalMarketSupply(address _poolToken)
        public
        view
        returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount)
    {
        (, p2pSupplyAmount, poolSupplyAmount) = _getTotalMarketSupply(_poolToken);
    }

    /// @notice Computes and returns the total distribution of borrows for a given market.
    /// @param _poolToken The address of the market to check.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getTotalMarketBorrow(address _poolToken)
        public
        view
        returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount)
    {
        (, p2pBorrowAmount, poolBorrowAmount) = _getTotalMarketBorrow(_poolToken);
    }

    /// INTERNAL ///

    /// @notice Computes and returns the total distribution of supply for a given market.
    /// @param _poolToken The address of the market to check.
    /// @return underlyingToken The address of the underlying ERC20 token of the given market.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function _getTotalMarketSupply(address _poolToken)
        public
        view
        returns (
            address underlyingToken,
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount
        )
    {
        (
            Types.Market memory market,
            uint256 p2pSupplyIndex,
            uint256 poolSupplyIndex,

        ) = _getSupplyIndexes(_poolToken);

        underlyingToken = market.underlyingToken;
        (p2pSupplyAmount, poolSupplyAmount) = _getMarketSupply(
            _poolToken,
            p2pSupplyIndex,
            poolSupplyIndex
        );
    }

    /// @notice Computes and returns the total distribution of borrows for a given market.
    /// @param _poolToken The address of the market to check.
    /// @return underlyingToken The address of the underlying ERC20 token of the given market.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function _getTotalMarketBorrow(address _poolToken)
        public
        view
        returns (
            address underlyingToken,
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount
        )
    {
        (
            Types.Market memory market,
            uint256 p2pBorrowIndex,
            ,
            uint256 poolBorrowIndex
        ) = _getBorrowIndexes(_poolToken);

        underlyingToken = market.underlyingToken;
        DataTypes.ReserveData memory reserve = pool.getReserveData(underlyingToken);

        (p2pBorrowAmount, poolBorrowAmount) = _getMarketBorrow(
            reserve,
            p2pBorrowIndex,
            poolBorrowIndex
        );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../interfaces/aave/IVariableDebtToken.sol";

import "./UsersLens.sol";

/// @title RatesLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol users and their positions.
abstract contract RatesLens is UsersLens {
    using WadRayMath for uint256;

    /// STRUCTS ///

    struct Indexes {
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 poolSupplyIndex;
        uint256 poolBorrowIndex;
    }

    /// EXTERNAL ///

    /// @notice Returns the supply rate per year experienced on a market after having supplied the given amount on behalf of the given user.
    /// @dev Note: the returned supply rate is a lower bound: when supplying through Morpho-Aave,
    /// a supplier could be matched more than once instantly or later and thus benefit from a higher supply rate.
    /// @param _poolToken The address of the market.
    /// @param _user The address of the user on behalf of whom to supply.
    /// @param _amount The amount to supply.
    /// @return nextSupplyRatePerYear An approximation of the next supply rate per year experienced after having supplied (in wad).
    /// @return balanceInP2P The total balance matched peer-to-peer after having supplied (in underlying).
    /// @return balanceOnPool The total balance supplied on pool after having supplied (in underlying).
    /// @return totalBalance The total balance supplied through Morpho (in underlying).
    function getNextUserSupplyRatePerYear(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextSupplyRatePerYear,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(_poolToken, _user);

        Indexes memory indexes;
        Types.Market memory market;
        (
            market,
            indexes.p2pSupplyIndex,
            indexes.poolSupplyIndex,
            indexes.poolBorrowIndex
        ) = _getSupplyIndexes(_poolToken);

        if (_amount > 0) {
            uint256 deltaInUnderlying = morpho.deltas(_poolToken).p2pBorrowDelta.rayMul(
                indexes.poolBorrowIndex
            );

            if (deltaInUnderlying > 0) {
                uint256 matchedDelta = Math.min(deltaInUnderlying, _amount);

                supplyBalance.inP2P += matchedDelta.rayDiv(indexes.p2pSupplyIndex);
                _amount -= matchedDelta;
            }
        }

        if (_amount > 0 && !market.isP2PDisabled) {
            uint256 firstPoolBorrowerBalance = morpho
            .borrowBalanceInOf(
                _poolToken,
                morpho.getHead(_poolToken, Types.PositionType.BORROWERS_ON_POOL)
            ).onPool;

            if (firstPoolBorrowerBalance > 0) {
                uint256 matchedP2P = Math.min(
                    firstPoolBorrowerBalance.rayMul(indexes.poolBorrowIndex),
                    _amount
                );

                supplyBalance.inP2P += matchedP2P.rayDiv(indexes.p2pSupplyIndex);
                _amount -= matchedP2P;
            }
        }

        if (_amount > 0) supplyBalance.onPool += _amount.rayDiv(indexes.poolSupplyIndex);

        balanceOnPool = supplyBalance.onPool.rayMul(indexes.poolSupplyIndex);
        balanceInP2P = supplyBalance.inP2P.rayMul(indexes.p2pSupplyIndex);
        totalBalance = balanceOnPool + balanceInP2P;

        nextSupplyRatePerYear = _getUserSupplyRatePerYear(
            _poolToken,
            balanceOnPool,
            balanceInP2P,
            totalBalance
        );
    }

    /// @notice Returns the borrow rate per year experienced on a market after having supplied the given amount on behalf of the given user.
    /// @dev Note: the returned borrow rate is an upper bound: when borrowing through Morpho-Aave,
    /// a borrower could be matched more than once instantly or later and thus benefit from a lower borrow rate.
    /// @param _poolToken The address of the market.
    /// @param _user The address of the user on behalf of whom to borrow.
    /// @param _amount The amount to borrow.
    /// @return nextBorrowRatePerYear An approximation of the next borrow rate per year experienced after having supplied (in wad).
    /// @return balanceInP2P The total balance matched peer-to-peer after having supplied (in underlying).
    /// @return balanceOnPool The total balance supplied on pool after having supplied (in underlying).
    /// @return totalBalance The total balance supplied through Morpho (in underlying).
    function getNextUserBorrowRatePerYear(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextBorrowRatePerYear,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.BorrowBalance memory borrowBalance = morpho.borrowBalanceInOf(_poolToken, _user);

        Indexes memory indexes;
        Types.Market memory market;
        (
            market,
            indexes.p2pBorrowIndex,
            indexes.poolSupplyIndex,
            indexes.poolBorrowIndex
        ) = _getBorrowIndexes(_poolToken);

        if (_amount > 0) {
            uint256 deltaInUnderlying = morpho.deltas(_poolToken).p2pSupplyDelta.rayMul(
                indexes.poolSupplyIndex
            );

            if (deltaInUnderlying > 0) {
                uint256 matchedDelta = Math.min(deltaInUnderlying, _amount);

                borrowBalance.inP2P += matchedDelta.rayDiv(indexes.p2pBorrowIndex);
                _amount -= matchedDelta;
            }
        }

        if (_amount > 0 && !market.isP2PDisabled) {
            uint256 firstPoolSupplierBalance = morpho
            .supplyBalanceInOf(
                _poolToken,
                morpho.getHead(_poolToken, Types.PositionType.SUPPLIERS_ON_POOL)
            ).onPool;

            if (firstPoolSupplierBalance > 0) {
                uint256 matchedP2P = Math.min(
                    firstPoolSupplierBalance.rayMul(indexes.poolSupplyIndex),
                    _amount
                );

                borrowBalance.inP2P += matchedP2P.rayDiv(indexes.p2pBorrowIndex);
                _amount -= matchedP2P;
            }
        }

        if (_amount > 0) borrowBalance.onPool += _amount.rayDiv(indexes.poolBorrowIndex);

        balanceOnPool = borrowBalance.onPool.rayMul(indexes.poolBorrowIndex);
        balanceInP2P = borrowBalance.inP2P.rayMul(indexes.p2pBorrowIndex);
        totalBalance = balanceOnPool + balanceInP2P;

        nextBorrowRatePerYear = _getUserBorrowRatePerYear(
            _poolToken,
            balanceOnPool,
            balanceInP2P,
            totalBalance
        );
    }

    /// PUBLIC ///

    /// @notice Computes and returns the current supply rate per year experienced on average on a given market.
    /// @param _poolToken The market address.
    /// @return avgSupplyRatePerYear The market's average supply rate per year (in wad).
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function getAverageSupplyRatePerYear(address _poolToken)
        public
        view
        returns (
            uint256 avgSupplyRatePerYear,
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount
        )
    {
        (
            Types.Market memory market,
            uint256 p2pSupplyIndex,
            uint256 poolSupplyIndex,

        ) = _getSupplyIndexes(_poolToken);

        DataTypes.ReserveData memory reserve = pool.getReserveData(market.underlyingToken);
        uint256 poolSupplyRate = reserve.currentLiquidityRate;
        uint256 poolBorrowRate = reserve.currentVariableBorrowRate;

        // Do not take delta into account as it's already taken into account in p2pSupplyAmount & poolSupplyAmount
        uint256 p2pSupplyRate = InterestRatesModel.computeP2PSupplyRatePerYear(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: PercentageMath.weightedAvg(
                    poolSupplyRate,
                    poolBorrowRate,
                    market.p2pIndexCursor
                ),
                poolRate: poolSupplyRate,
                poolIndex: poolSupplyIndex,
                p2pIndex: p2pSupplyIndex,
                p2pDelta: 0,
                p2pAmount: 0,
                reserveFactor: market.reserveFactor
            })
        );

        (p2pSupplyAmount, poolSupplyAmount) = _getMarketSupply(
            _poolToken,
            p2pSupplyIndex,
            poolSupplyIndex
        );

        uint256 totalSupply = p2pSupplyAmount + poolSupplyAmount;
        if (p2pSupplyAmount > 0)
            avgSupplyRatePerYear += p2pSupplyRate.wadMul(p2pSupplyAmount.wadDiv(totalSupply));
        if (poolSupplyAmount > 0)
            avgSupplyRatePerYear += poolSupplyRate.wadMul(poolSupplyAmount.wadDiv(totalSupply));
    }

    /// @notice Computes and returns the current average borrow rate per year experienced on a given market.
    /// @param _poolToken The market address.
    /// @return avgBorrowRatePerYear The market's average borrow rate per year (in wad).
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function getAverageBorrowRatePerYear(address _poolToken)
        public
        view
        returns (
            uint256 avgBorrowRatePerYear,
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount
        )
    {
        (
            Types.Market memory market,
            uint256 p2pBorrowIndex,
            ,
            uint256 poolBorrowIndex
        ) = _getBorrowIndexes(_poolToken);

        DataTypes.ReserveData memory reserve = pool.getReserveData(market.underlyingToken);
        uint256 poolSupplyRate = reserve.currentLiquidityRate;
        uint256 poolBorrowRate = reserve.currentVariableBorrowRate;

        // Do not take delta into account as it's already taken into account in p2pBorrowAmount & poolBorrowAmount
        uint256 p2pBorrowRate = InterestRatesModel.computeP2PBorrowRatePerYear(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: PercentageMath.weightedAvg(
                    poolSupplyRate,
                    poolBorrowRate,
                    market.p2pIndexCursor
                ),
                poolRate: poolBorrowRate,
                poolIndex: poolBorrowIndex,
                p2pIndex: p2pBorrowIndex,
                p2pDelta: 0,
                p2pAmount: 0,
                reserveFactor: market.reserveFactor
            })
        );

        (p2pBorrowAmount, poolBorrowAmount) = _getMarketBorrow(
            reserve,
            p2pBorrowIndex,
            poolBorrowIndex
        );

        uint256 totalBorrow = p2pBorrowAmount + poolBorrowAmount;
        if (p2pBorrowAmount > 0)
            avgBorrowRatePerYear += p2pBorrowRate.wadMul(p2pBorrowAmount.wadDiv(totalBorrow));
        if (poolBorrowAmount > 0)
            avgBorrowRatePerYear += poolBorrowRate.wadMul(poolBorrowAmount.wadDiv(totalBorrow));
    }

    /// @notice Computes and returns peer-to-peer and pool rates for a specific market.
    /// @dev Note: prefer using getAverageSupplyRatePerBlock & getAverageBorrowRatePerBlock to get the experienced supply/borrow rate instead of this.
    /// @param _poolToken The market address.
    /// @return p2pSupplyRate The market's peer-to-peer supply rate per year (in ray).
    /// @return p2pBorrowRate The market's peer-to-peer borrow rate per year (in ray).
    /// @return poolSupplyRate The market's pool supply rate per year (in ray).
    /// @return poolBorrowRate The market's pool borrow rate per year (in ray).
    function getRatesPerYear(address _poolToken)
        public
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        )
    {
        (
            address underlyingToken,
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        ) = _getIndexes(_poolToken);

        DataTypes.ReserveData memory reserve = pool.getReserveData(underlyingToken);
        poolSupplyRate = reserve.currentLiquidityRate;
        poolBorrowRate = reserve.currentVariableBorrowRate;

        Types.Market memory market = morpho.market(_poolToken);
        uint256 p2pRate = PercentageMath.weightedAvg(
            poolSupplyRate,
            poolBorrowRate,
            market.p2pIndexCursor
        );

        Types.Delta memory delta = morpho.deltas(_poolToken);

        p2pSupplyRate = InterestRatesModel.computeP2PSupplyRatePerYear(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: p2pRate,
                poolRate: poolSupplyRate,
                poolIndex: poolSupplyIndex,
                p2pIndex: p2pSupplyIndex,
                p2pDelta: delta.p2pSupplyDelta,
                p2pAmount: delta.p2pSupplyAmount,
                reserveFactor: market.reserveFactor
            })
        );

        p2pBorrowRate = InterestRatesModel.computeP2PBorrowRatePerYear(
            InterestRatesModel.P2PRateComputeParams({
                p2pRate: p2pRate,
                poolRate: poolBorrowRate,
                poolIndex: poolBorrowIndex,
                p2pIndex: p2pBorrowIndex,
                p2pDelta: delta.p2pBorrowDelta,
                p2pAmount: delta.p2pBorrowAmount,
                reserveFactor: market.reserveFactor
            })
        );
    }

    /// @notice Returns the supply rate per year a given user is currently experiencing on a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to compute the supply rate per year for.
    /// @return The supply rate per year the user is currently experiencing (in wad).
    function getCurrentUserSupplyRatePerYear(address _poolToken, address _user)
        public
        view
        returns (uint256)
    {
        (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        ) = getCurrentSupplyBalanceInOf(_poolToken, _user);

        return _getUserSupplyRatePerYear(_poolToken, balanceOnPool, balanceInP2P, totalBalance);
    }

    /// @notice Returns the borrow rate per year a given user is currently experiencing on a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to compute the borrow rate per year for.
    /// @return The borrow rate per year the user is currently experiencing (in wad).
    function getCurrentUserBorrowRatePerYear(address _poolToken, address _user)
        public
        view
        returns (uint256)
    {
        (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        ) = getCurrentBorrowBalanceInOf(_poolToken, _user);

        return _getUserBorrowRatePerYear(_poolToken, balanceOnPool, balanceInP2P, totalBalance);
    }

    /// INTERNAL ///

    /// @notice Computes and returns the total distribution of supply for a given market, optionally using virtually updated indexes.
    /// @param _poolToken The address of the market to check.
    /// @param _p2pSupplyIndex The given market's peer-to-peer supply index.
    /// @param _poolSupplyIndex The underlying pool's supply index.
    /// @return p2pSupplyAmount The total supplied amount matched peer-to-peer, subtracting the supply delta (in underlying).
    /// @return poolSupplyAmount The total supplied amount on the underlying pool, adding the supply delta (in underlying).
    function _getMarketSupply(
        address _poolToken,
        uint256 _p2pSupplyIndex,
        uint256 _poolSupplyIndex
    ) internal view returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount) {
        Types.Delta memory delta = morpho.deltas(_poolToken);

        p2pSupplyAmount =
            delta.p2pSupplyAmount.rayMul(_p2pSupplyIndex) -
            delta.p2pSupplyDelta.rayMul(_poolSupplyIndex);
        poolSupplyAmount = IAToken(_poolToken).balanceOf(address(morpho));
    }

    /// @notice Computes and returns the total distribution of borrows for a given market, optionally using virtually updated indexes.
    /// @param reserve The reserve data of the underlying pool.
    /// @param _p2pBorrowIndex The given market's peer-to-peer borrow index.
    /// @param _poolBorrowIndex The underlying pool's borrow index.
    /// @return p2pBorrowAmount The total borrowed amount matched peer-to-peer, subtracting the borrow delta (in underlying).
    /// @return poolBorrowAmount The total borrowed amount on the underlying pool, adding the borrow delta (in underlying).
    function _getMarketBorrow(
        DataTypes.ReserveData memory reserve,
        uint256 _p2pBorrowIndex,
        uint256 _poolBorrowIndex
    ) internal view returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount) {
        Types.Delta memory delta = morpho.deltas(reserve.aTokenAddress);

        p2pBorrowAmount =
            delta.p2pBorrowAmount.rayMul(_p2pBorrowIndex) -
            delta.p2pBorrowDelta.rayMul(_poolBorrowIndex);
        poolBorrowAmount = IVariableDebtToken(reserve.variableDebtTokenAddress)
        .scaledBalanceOf(address(morpho))
        .rayMul(_poolBorrowIndex);
    }

    /// @dev Returns the supply rate per year experienced on a market based on a given position distribution.
    /// @param _poolToken The address of the market.
    /// @param _balanceOnPool The amount of balance supplied on pool (in a unit common to `_balanceInP2P` and `_totalBalance`).
    /// @param _balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `_balanceOnPool` and `_totalBalance`).
    /// @param _totalBalance The total amount of balance (should equal `_balanceOnPool + _balanceInP2P` but is used for saving gas).
    /// @return supplyRatePerYear The supply rate per year experienced by the given position (in wad).
    function _getUserSupplyRatePerYear(
        address _poolToken,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P,
        uint256 _totalBalance
    ) internal view returns (uint256 supplyRatePerYear) {
        if (_totalBalance == 0) return 0;

        (uint256 p2pSupplyRate, , uint256 poolSupplyRate, ) = getRatesPerYear(_poolToken);

        if (_balanceOnPool > 0)
            supplyRatePerYear += poolSupplyRate.wadMul(_balanceOnPool.wadDiv(_totalBalance));
        if (_balanceInP2P > 0)
            supplyRatePerYear += p2pSupplyRate.wadMul(_balanceInP2P.wadDiv(_totalBalance));
    }

    /// @dev Returns the borrow rate per year experienced on a market based on a given position distribution.
    /// @param _poolToken The address of the market.
    /// @param _balanceOnPool The amount of balance supplied on pool (in a unit common to `_balanceInP2P` and `_totalBalance`).
    /// @param _balanceInP2P The amount of balance matched peer-to-peer (in a unit common to `_balanceOnPool` and `_totalBalance`).
    /// @param _totalBalance The total amount of balance (should equal `_balanceOnPool + _balanceInP2P` but is used for saving gas).
    /// @return borrowRatePerYear The borrow rate per year experienced by the given position (in wad).
    function _getUserBorrowRatePerYear(
        address _poolToken,
        uint256 _balanceOnPool,
        uint256 _balanceInP2P,
        uint256 _totalBalance
    ) internal view returns (uint256 borrowRatePerYear) {
        if (_totalBalance == 0) return 0;

        (, uint256 p2pBorrowRate, , uint256 poolBorrowRate) = getRatesPerYear(_poolToken);

        if (_balanceOnPool > 0)
            borrowRatePerYear += poolBorrowRate.wadMul(_balanceOnPool.wadDiv(_totalBalance));
        if (_balanceInP2P > 0)
            borrowRatePerYear += p2pBorrowRate.wadMul(_balanceInP2P.wadDiv(_totalBalance));
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

/**
 * @title IVariableDebtToken
 * @author Aave
 * @notice Defines the basic interface for a variable debt token.
 **/
interface IVariableDebtToken is IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param onBehalfOf The address of the user on which behalf minting has been performed
     * @param value The amount to be minted
     * @param index The last index of the reserve
     **/
    event Mint(address indexed from, address indexed onBehalfOf, uint256 value, uint256 index);

    /**
     * @dev delegates borrowing power to a user on the specific debt token
     * @param delegatee the address receiving the delegated borrowing power
     * @param amount the maximum amount being delegated. Delegation will still
     * respect the liquidation constraints (even if delegated, a delegatee cannot
     * force a delegator HF to go below 1)
     **/
    function approveDelegation(address delegatee, uint256 amount) external;

    /**
     * @dev returns the borrow allowance of the user
     * @param fromUser The user to giving allowance
     * @param toUser The user to give allowance to
     * @return the current allowance of toUser
     **/
    function borrowAllowance(address fromUser, address toUser) external view returns (uint256);

    /**
     * @dev Mints debt token to the `onBehalfOf` address
     * @param user The address receiving the borrowed underlying, being the delegatee in case
     * of credit delegate, or same as `onBehalfOf` otherwise
     * @param onBehalfOf The address receiving the debt tokens
     * @param amount The amount of debt being minted
     * @param index The variable debt index of the reserve
     * @return `true` if the the previous balance of the user is 0
     **/
    function mint(
        address user,
        address onBehalfOf,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted when variable debt is burnt
     * @param user The user which debt has been burned
     * @param amount The amount of debt being burned
     * @param index The index of the user
     **/
    event Burn(address indexed user, uint256 amount, uint256 index);

    /**
     * @dev Burns user variable debt
     * @param user The user which debt is burnt
     * @param index The variable debt index of the reserve
     **/
    function burn(
        address user,
        uint256 amount,
        uint256 index
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import {ERC20} from "@rari-capital/solmate/src/utils/SafeTransferLib.sol";

import "./IndexesLens.sol";

/// @title UsersLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol users and their positions.
abstract contract UsersLens is IndexesLens {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using PercentageMath for uint256;
    using WadRayMath for uint256;
    using Math for uint256;

    /// EXTERNAL ///

    /// @notice Returns all markets entered by a given user.
    /// @param _user The address of the user.
    /// @return enteredMarkets The list of markets entered by this user.
    function getEnteredMarkets(address _user)
        external
        view
        returns (address[] memory enteredMarkets)
    {
        address[] memory createdMarkets = morpho.getMarketsCreated();
        uint256 nbCreatedMarkets = createdMarkets.length;

        uint256 nbEnteredMarkets;
        enteredMarkets = new address[](nbCreatedMarkets);

        bytes32 userMarkets = morpho.userMarkets(_user);
        for (uint256 i; i < nbCreatedMarkets; ) {
            if (_isSupplyingOrBorrowing(userMarkets, createdMarkets[i])) {
                enteredMarkets[nbEnteredMarkets] = createdMarkets[i];
                ++nbEnteredMarkets;
            }

            unchecked {
                ++i;
            }
        }

        // Resize the array for return
        assembly {
            mstore(enteredMarkets, nbEnteredMarkets)
        }
    }

    /// @notice Returns the maximum amount available to withdraw and borrow for `_user` related to `_poolToken` (in underlyings).
    /// @param _user The user to determine the capacities for.
    /// @param _poolToken The address of the market.
    /// @return withdrawable The maximum withdrawable amount of underlying token allowed (in underlying).
    /// @return borrowable The maximum borrowable amount of underlying token allowed (in underlying).
    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable)
    {
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());

        Types.LiquidityData memory liquidityData = getUserHypotheticalBalanceStates(
            _user,
            address(0),
            0,
            0
        );
        Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
            _user,
            _poolToken,
            oracle
        );
        uint256 healthFactor = liquidityData.debt > 0
            ? liquidityData.liquidationThreshold.wadDiv(liquidityData.debt)
            : type(uint256).max;

        // Not possible to withdraw nor borrow.
        if (healthFactor <= HEALTH_FACTOR_LIQUIDATION_THRESHOLD) return (0, 0);

        borrowable =
            ((liquidityData.maxDebt - liquidityData.debt) * assetData.tokenUnit) /
            assetData.underlyingPrice;
        withdrawable = (assetData.collateral * assetData.tokenUnit) / assetData.underlyingPrice;

        if (assetData.ltv != 0)
            withdrawable = Math.min(withdrawable, borrowable.percentDiv(assetData.ltv));
    }

    /// @dev Computes the maximum repayable amount for a potential liquidation.
    /// @param _user The potential liquidatee.
    /// @param _poolTokenBorrowedAddress The address of the market to repay.
    /// @param _poolTokenCollateralAddress The address of the market to seize.
    /// @return The maximum repayable amount (in underlying).
    function computeLiquidationRepayAmount(
        address _user,
        address _poolTokenBorrowedAddress,
        address _poolTokenCollateralAddress
    ) external view returns (uint256) {
        if (!isLiquidatable(_user)) return 0;

        (
            address collateralToken,
            ,
            ,
            uint256 totalCollateralBalance
        ) = _getCurrentSupplyBalanceInOf(_poolTokenCollateralAddress, _user);
        (address borrowedToken, , , uint256 totalBorrowBalance) = _getCurrentBorrowBalanceInOf(
            _poolTokenBorrowedAddress,
            _user
        );

        (, , uint256 liquidationBonus, uint256 collateralReserveDecimals, ) = pool
        .getConfiguration(collateralToken)
        .getParamsMemory();

        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        uint256 borrowedPrice = oracle.getAssetPrice(borrowedToken);
        uint256 collateralPrice = oracle.getAssetPrice(collateralToken);

        return
            Math.min(
                ((totalCollateralBalance * collateralPrice * 10**ERC20(borrowedToken).decimals()) /
                    (borrowedPrice * 10**collateralReserveDecimals))
                    .percentDiv(liquidationBonus),
                totalBorrowBalance.percentMul(DEFAULT_LIQUIDATION_CLOSE_FACTOR)
            );
    }

    /// PUBLIC ///

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        (, balanceInP2P, balanceOnPool, totalBalance) = _getCurrentSupplyBalanceInOf(
            _poolToken,
            _user
        );
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        (, balanceInP2P, balanceOnPool, totalBalance) = _getCurrentBorrowBalanceInOf(
            _poolToken,
            _user
        );
    }

    /// @notice Returns the collateral value, debt value and max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @return The liquidity data of the user.
    function getUserBalanceStates(address _user) public view returns (Types.LiquidityData memory) {
        return getUserHypotheticalBalanceStates(_user, address(0), 0, 0);
    }

    /// @dev Returns the debt value, max debt value of a given user.
    /// @param _user The user to determine liquidity for.
    /// @param _poolToken The market to hypothetically withdraw/borrow in.
    /// @param _withdrawnAmount The number of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    /// @return liquidityData The liquidity data of the user.
    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) public view returns (Types.LiquidityData memory liquidityData) {
        IPriceOracleGetter oracle = IPriceOracleGetter(addressesProvider.getPriceOracle());
        address[] memory createdMarkets = morpho.getMarketsCreated();
        bytes32 userMarkets = morpho.userMarkets(_user);

        uint256 nbCreatedMarkets = createdMarkets.length;
        for (uint256 i; i < nbCreatedMarkets; ) {
            address poolToken = createdMarkets[i];

            if (_isSupplyingOrBorrowing(userMarkets, poolToken)) {
                Types.AssetLiquidityData memory assetData = getUserLiquidityDataForAsset(
                    _user,
                    poolToken,
                    oracle
                );

                liquidityData.collateral += assetData.collateral;
                liquidityData.maxDebt += assetData.collateral.percentMul(assetData.ltv);
                liquidityData.liquidationThreshold += assetData.collateral.percentMul(
                    assetData.liquidationThreshold
                );
                liquidityData.debt += assetData.debt;

                if (_poolToken == poolToken) {
                    if (_borrowedAmount > 0)
                        liquidityData.debt += (_borrowedAmount * assetData.underlyingPrice).divUp(
                            assetData.tokenUnit
                        );

                    if (_withdrawnAmount > 0) {
                        uint256 assetCollateral = (_withdrawnAmount * assetData.underlyingPrice) /
                            assetData.tokenUnit;

                        liquidityData.collateral -= assetCollateral;
                        liquidityData.maxDebt -= assetCollateral.percentMul(assetData.ltv);
                        liquidityData.liquidationThreshold -= assetCollateral.percentMul(
                            assetData.liquidationThreshold
                        );
                    }
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @notice Returns the data related to `_poolToken` for the `_user`.
    /// @param _user The user to determine data for.
    /// @param _poolToken The address of the market.
    /// @param _oracle The oracle used.
    /// @return assetData The data related to this asset.
    function getUserLiquidityDataForAsset(
        address _user,
        address _poolToken,
        IPriceOracleGetter _oracle
    ) public view returns (Types.AssetLiquidityData memory assetData) {
        (
            address underlyingToken,
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        ) = _getIndexes(_poolToken);

        assetData.underlyingPrice = _oracle.getAssetPrice(underlyingToken); // In ETH.
        (assetData.ltv, assetData.liquidationThreshold, , assetData.decimals, ) = pool
        .getConfiguration(underlyingToken)
        .getParamsMemory();

        (, , uint256 totalCollateralBalance) = _getSupplyBalanceInOf(
            _poolToken,
            _user,
            p2pSupplyIndex,
            poolSupplyIndex
        );
        (, , uint256 totalDebtBalance) = _getBorrowBalanceInOf(
            _poolToken,
            _user,
            p2pBorrowIndex,
            poolBorrowIndex
        );

        assetData.tokenUnit = 10**assetData.decimals;
        assetData.debt = (totalDebtBalance * assetData.underlyingPrice).divUp(assetData.tokenUnit);
        assetData.collateral =
            (totalCollateralBalance * assetData.underlyingPrice) /
            assetData.tokenUnit;
    }

    /// @dev Computes the health factor of a given user, given a list of markets of which to compute virtually updated pool & peer-to-peer indexes.
    /// @param _user The user of whom to get the health factor.
    /// @return The health factor of the given user (in wad).
    function getUserHealthFactor(address _user) public view returns (uint256) {
        return getUserHypotheticalHealthFactor(_user, address(0), 0, 0);
    }

    /// @dev Returns the hypothetical health factor of a user
    /// @param _user The user to determine liquidity for.
    /// @param _poolToken The market to hypothetically withdraw/borrow from.
    /// @param _withdrawnAmount The number of tokens to hypothetically withdraw (in underlying).
    /// @param _borrowedAmount The amount of tokens to hypothetically borrow (in underlying).
    /// @return healthFactor The health factor of the user.
    function getUserHypotheticalHealthFactor(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) public view returns (uint256 healthFactor) {
        Types.LiquidityData memory liquidityData = getUserHypotheticalBalanceStates(
            _user,
            _poolToken,
            _withdrawnAmount,
            _borrowedAmount
        );
        if (liquidityData.debt == 0) return type(uint256).max;

        return liquidityData.liquidationThreshold.wadDiv(liquidityData.debt);
    }

    /// @dev Checks whether a liquidation can be performed on a given user.
    /// @param _user The user to check.
    /// @return whether or not the user is liquidatable.
    function isLiquidatable(address _user) public view returns (bool) {
        return getUserHealthFactor(_user) < HEALTH_FACTOR_LIQUIDATION_THRESHOLD;
    }

    /// INTERNAL ///

    /// @dev Returns if a user has been borrowing or supplying on a given market.
    /// @param _userMarkets The user to check for.
    /// @param _market The address of the market to check.
    /// @return True if the user has been supplying or borrowing on this market, false otherwise.
    function _isSupplyingOrBorrowing(bytes32 _userMarkets, address _market)
        internal
        view
        returns (bool)
    {
        bytes32 marketBorrowMask = morpho.borrowMask(_market);

        return _userMarkets & (marketBorrowMask | (marketBorrowMask << 1)) != 0;
    }

    /// @notice Returns the balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return underlyingToken The address of the underlying ERC20 token of the given market.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function _getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            address underlyingToken,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        (
            Types.Market memory market,
            uint256 p2pSupplyIndex,
            uint256 poolSupplyIndex,

        ) = _getSupplyIndexes(_poolToken);

        underlyingToken = market.underlyingToken;
        (balanceInP2P, balanceOnPool, totalBalance) = _getSupplyBalanceInOf(
            _poolToken,
            _user,
            p2pSupplyIndex,
            poolSupplyIndex
        );
    }

    /// @notice Returns the borrow balance in underlying of a given user in a given market.
    /// @param _poolToken The address of the market.
    /// @param _user The user to determine balances of.
    /// @return underlyingToken The address of the underlying ERC20 token of the given market.
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function _getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        public
        view
        returns (
            address underlyingToken,
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        (
            Types.Market memory market,
            uint256 p2pBorrowIndex,
            ,
            uint256 poolBorrowIndex
        ) = _getBorrowIndexes(_poolToken);

        underlyingToken = market.underlyingToken;
        (balanceInP2P, balanceOnPool, totalBalance) = _getBorrowBalanceInOf(
            _poolToken,
            _user,
            p2pBorrowIndex,
            poolBorrowIndex
        );
    }

    /// @dev Returns the supply balance of `_user` in the `_poolToken` market.
    /// @dev Note: Compute the result with the index stored and not the most up to date one.
    /// @param _poolToken The market where to get the supply amount.
    /// @param _user The address of the user.
    /// @param _p2pSupplyIndex The peer-to-peer supply index of the given market (in ray).
    /// @param _poolSupplyIndex The pool supply index of the given market (in ray).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function _getSupplyBalanceInOf(
        address _poolToken,
        address _user,
        uint256 _p2pSupplyIndex,
        uint256 _poolSupplyIndex
    )
        internal
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.SupplyBalance memory supplyBalance = morpho.supplyBalanceInOf(_poolToken, _user);

        balanceInP2P = supplyBalance.inP2P.rayMul(_p2pSupplyIndex);
        balanceOnPool = supplyBalance.onPool.rayMul(_poolSupplyIndex);

        totalBalance = balanceOnPool + balanceInP2P;
    }

    /// @dev Returns the borrow balance of `_user` in the `_poolToken` market.
    /// @param _poolToken The market where to get the borrow amount.
    /// @param _user The address of the user.
    /// @param _p2pBorrowIndex The peer-to-peer borrow index of the given market (in ray).
    /// @param _poolBorrowIndex The pool borrow index of the given market (in ray).
    /// @return balanceInP2P The balance in peer-to-peer of the user (in underlying).
    /// @return balanceOnPool The balance on pool of the user (in underlying).
    /// @return totalBalance The total balance of the user (in underlying).
    function _getBorrowBalanceInOf(
        address _poolToken,
        address _user,
        uint256 _p2pBorrowIndex,
        uint256 _poolBorrowIndex
    )
        internal
        view
        returns (
            uint256 balanceInP2P,
            uint256 balanceOnPool,
            uint256 totalBalance
        )
    {
        Types.BorrowBalance memory borrowBalance = morpho.borrowBalanceInOf(_poolToken, _user);

        balanceInP2P = borrowBalance.inP2P.rayMul(_p2pBorrowIndex);
        balanceOnPool = borrowBalance.onPool.rayMul(_poolBorrowIndex);

        totalBalance = balanceOnPool + balanceInP2P;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IScaledBalanceToken {
    /**
     * @dev Returns the scaled balance of the user. The scaled balance is the sum of all the
     * updated stored balance divided by the reserve's liquidity index at the moment of the update
     * @param user The user whose balance is calculated
     * @return The scaled balance of the user
     **/
    function scaledBalanceOf(address user) external view returns (uint256);

    /**
     * @dev Returns the scaled balance of the user and the scaled total supply.
     * @param user The address of the user
     * @return The scaled balance of the user
     * @return The scaled balance and the scaled total supply
     **/
    function getScaledUserBalanceAndSupply(address user) external view returns (uint256, uint256);

    /**
     * @dev Returns the scaled total supply of the variable debt token. Represents sum(debt/index)
     * @return The scaled total supply
     **/
    function scaledTotalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./LensStorage.sol";

/// @title IndexesLens.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Intermediary layer exposing endpoints to query live data related to the Morpho Protocol market indexes & rates.
abstract contract IndexesLens is LensStorage {
    /// PUBLIC ///

    /// @notice Returns the updated peer-to-peer supply index.
    /// @param _poolToken The address of the market.
    /// @return currentP2PSupplyIndex The updated peer-to-peer supply index.
    function getCurrentP2PSupplyIndex(address _poolToken)
        public
        view
        returns (uint256 currentP2PSupplyIndex)
    {
        (, currentP2PSupplyIndex, , ) = _getSupplyIndexes(_poolToken);
    }

    /// @notice Returns the updated peer-to-peer borrow index.
    /// @param _poolToken The address of the market.
    /// @return currentP2PBorrowIndex The updated peer-to-peer borrow index.
    function getCurrentP2PBorrowIndex(address _poolToken)
        public
        view
        returns (uint256 currentP2PBorrowIndex)
    {
        (, currentP2PBorrowIndex, , ) = _getBorrowIndexes(_poolToken);
    }

    /// @notice Returns the updated peer-to-peer and pool indexes.
    /// @param _poolToken The address of the market.
    /// @return p2pSupplyIndex The updated peer-to-peer supply index.
    /// @return p2pBorrowIndex The updated peer-to-peer borrow index.
    /// @return poolSupplyIndex The updated pool supply index.
    /// @return poolBorrowIndex The updated pool borrow index.
    function getIndexes(address _poolToken)
        public
        view
        returns (
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        )
    {
        (, p2pSupplyIndex, p2pBorrowIndex, poolSupplyIndex, poolBorrowIndex) = _getIndexes(
            _poolToken
        );
    }

    /// INTERNAL ///

    /// @notice Returns the updated peer-to-peer and pool indexes.
    /// @param _poolToken The address of the market.
    /// @return underlyingToken The address of the underlying ERC20 token of the given market.
    /// @return p2pSupplyIndex The updated peer-to-peer supply index.
    /// @return p2pBorrowIndex The updated peer-to-peer borrow index.
    /// @return poolSupplyIndex The updated pool supply index.
    /// @return poolBorrowIndex The updated pool borrow index.
    function _getIndexes(address _poolToken)
        public
        view
        returns (
            address underlyingToken,
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        )
    {
        Types.Delta memory delta = morpho.deltas(_poolToken);
        Types.Market memory market = morpho.market(_poolToken);
        Types.PoolIndexes memory lastPoolIndexes = morpho.poolIndexes(_poolToken);
        underlyingToken = market.underlyingToken;

        InterestRatesModel.GrowthFactors memory growthFactors = InterestRatesModel
        .computeGrowthFactors(
            poolSupplyIndex = pool.getReserveNormalizedIncome(underlyingToken),
            poolBorrowIndex = pool.getReserveNormalizedVariableDebt(underlyingToken),
            lastPoolIndexes,
            market.p2pIndexCursor,
            market.reserveFactor
        );

        p2pSupplyIndex = InterestRatesModel.computeP2PSupplyIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolSupplyGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pSupplyGrowthFactor,
                lastPoolIndex: lastPoolIndexes.poolSupplyIndex,
                lastP2PIndex: morpho.p2pSupplyIndex(_poolToken),
                p2pDelta: delta.p2pSupplyDelta,
                p2pAmount: delta.p2pSupplyAmount
            })
        );
        p2pBorrowIndex = InterestRatesModel.computeP2PBorrowIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolBorrowGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pBorrowGrowthFactor,
                lastPoolIndex: lastPoolIndexes.poolBorrowIndex,
                lastP2PIndex: morpho.p2pBorrowIndex(_poolToken),
                p2pDelta: delta.p2pBorrowDelta,
                p2pAmount: delta.p2pBorrowAmount
            })
        );
    }

    /// @notice Returns the updated peer-to-peer supply index.
    /// @param _poolToken The address of the market.
    /// @return market The market from which to compute the peer-to-peer supply index.
    /// @return currentP2PSupplyIndex The updated peer-to-peer supply index.
    /// @return poolSupplyIndex The updated pool supply index.
    /// @return poolBorrowIndex The updated pool borrow index.
    function _getSupplyIndexes(address _poolToken)
        internal
        view
        returns (
            Types.Market memory market,
            uint256 currentP2PSupplyIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        )
    {
        market = morpho.market(_poolToken);
        Types.Delta memory delta = morpho.deltas(_poolToken);
        Types.PoolIndexes memory lastPoolIndexes = morpho.poolIndexes(_poolToken);

        InterestRatesModel.GrowthFactors memory growthFactors = InterestRatesModel
        .computeGrowthFactors(
            poolSupplyIndex = pool.getReserveNormalizedIncome(market.underlyingToken),
            poolBorrowIndex = pool.getReserveNormalizedVariableDebt(market.underlyingToken),
            lastPoolIndexes,
            market.p2pIndexCursor,
            market.reserveFactor
        );

        currentP2PSupplyIndex = InterestRatesModel.computeP2PSupplyIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolSupplyGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pSupplyGrowthFactor,
                lastPoolIndex: lastPoolIndexes.poolSupplyIndex,
                lastP2PIndex: morpho.p2pSupplyIndex(_poolToken),
                p2pDelta: delta.p2pSupplyDelta,
                p2pAmount: delta.p2pSupplyAmount
            })
        );
    }

    /// @notice Returns the updated peer-to-peer borrow index.
    /// @param _poolToken The address of the market.
    /// @return market The market from which to compute the peer-to-peer borrow index.
    /// @return currentP2PBorrowIndex The updated peer-to-peer borrow index.
    /// @return poolSupplyIndex The updated pool supply index.
    /// @return poolBorrowIndex The updated pool borrow index.
    function _getBorrowIndexes(address _poolToken)
        internal
        view
        returns (
            Types.Market memory market,
            uint256 currentP2PBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        )
    {
        market = morpho.market(_poolToken);
        Types.Delta memory delta = morpho.deltas(_poolToken);
        Types.PoolIndexes memory lastPoolIndexes = morpho.poolIndexes(_poolToken);

        InterestRatesModel.GrowthFactors memory growthFactors = InterestRatesModel
        .computeGrowthFactors(
            poolSupplyIndex = pool.getReserveNormalizedIncome(market.underlyingToken),
            poolBorrowIndex = pool.getReserveNormalizedVariableDebt(market.underlyingToken),
            lastPoolIndexes,
            market.p2pIndexCursor,
            market.reserveFactor
        );

        currentP2PBorrowIndex = InterestRatesModel.computeP2PBorrowIndex(
            InterestRatesModel.P2PIndexComputeParams({
                poolGrowthFactor: growthFactors.poolBorrowGrowthFactor,
                p2pGrowthFactor: growthFactors.p2pBorrowGrowthFactor,
                lastPoolIndex: lastPoolIndexes.poolBorrowIndex,
                lastP2PIndex: morpho.p2pBorrowIndex(_poolToken),
                p2pDelta: delta.p2pBorrowDelta,
                p2pAmount: delta.p2pBorrowAmount
            })
        );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../interfaces/aave/IPriceOracleGetter.sol";
import "../interfaces/aave/ILendingPool.sol";
import "../interfaces/aave/IAToken.sol";
import "../interfaces/IMorpho.sol";

import "../libraries/aave/ReserveConfiguration.sol";
import "../../../lib/morpho-utils/src/math/PercentageMath.sol";
import "../../../lib/morpho-utils/src/math/WadRayMath.sol";
import "../../../lib/morpho-utils/src/math/Math.sol";
import "../libraries/aave/DataTypes.sol";
import "../libraries/InterestRatesModel.sol";

/// @title LensStorage.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Base layer to the Morpho Protocol Lens, managing the upgradeable storage layout.
abstract contract LensStorage {
    /// STORAGE ///

    uint16 public constant DEFAULT_LIQUIDATION_CLOSE_FACTOR = 5_000; // 50% in basis points.
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1e18; // Health factor below which the positions can be liquidated.

    IMorpho public immutable morpho;
    ILendingPoolAddressesProvider public immutable addressesProvider;
    ILendingPool public immutable pool;

    /// CONSTRUCTOR ///

    /// @notice Constructs the contract.
    /// @param _morpho The address of the main Morpho contract.
    constructor(address _morpho) {
        morpho = IMorpho(_morpho);
        pool = ILendingPool(morpho.pool());
        addressesProvider = ILendingPoolAddressesProvider(morpho.addressesProvider());
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/************
@title IPriceOracleGetter interface
@notice Interface for the Aave price oracle.*/
interface IPriceOracleGetter {
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address _asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import {ILendingPoolAddressesProvider} from "./ILendingPoolAddressesProvider.sol";
import {DataTypes} from "../../libraries/aave/DataTypes.sol";

interface ILendingPool {
    /**
     * @dev Emitted on deposit()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address initiating the deposit
     * @param onBehalfOf The beneficiary of the deposit, receiving the aTokens
     * @param amount The amount deposited
     * @param referral The referral code used
     **/
    event Deposit(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on withdraw()
     * @param reserve The address of the underlyng asset being withdrawn
     * @param user The address initiating the withdrawal, owner of aTokens
     * @param to Address that will receive the underlying
     * @param amount The amount to be withdrawn
     **/
    event Withdraw(
        address indexed reserve,
        address indexed user,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Emitted on borrow() and flashLoan() when debt needs to be opened
     * @param reserve The address of the underlying asset being borrowed
     * @param user The address of the user initiating the borrow(), receiving the funds on borrow() or just
     * initiator of the transaction on flashLoan()
     * @param onBehalfOf The address that will be getting the debt
     * @param amount The amount borrowed out
     * @param borrowRateMode The rate mode: 1 for Stable, 2 for Variable
     * @param borrowRate The numeric rate at which the user has borrowed
     * @param referral The referral code used
     **/
    event Borrow(
        address indexed reserve,
        address user,
        address indexed onBehalfOf,
        uint256 amount,
        uint256 borrowRateMode,
        uint256 borrowRate,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The beneficiary of the repayment, getting his debt reduced
     * @param repayer The address of the user initiating the repay(), providing the funds
     * @param amount The amount repaid
     **/
    event Repay(
        address indexed reserve,
        address indexed user,
        address indexed repayer,
        uint256 amount
    );

    /**
     * @dev Emitted on swapBorrowRateMode()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user swapping his rate mode
     * @param rateMode The rate mode that the user wants to swap to
     **/
    event Swap(address indexed reserve, address indexed user, uint256 rateMode);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralEnabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on setUserUseReserveAsCollateral()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user enabling the usage as collateral
     **/
    event ReserveUsedAsCollateralDisabled(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on rebalanceStableBorrowRate()
     * @param reserve The address of the underlying asset of the reserve
     * @param user The address of the user for which the rebalance has been executed
     **/
    event RebalanceStableBorrowRate(address indexed reserve, address indexed user);

    /**
     * @dev Emitted on flashLoan()
     * @param target The address of the flash loan receiver contract
     * @param initiator The address initiating the flash loan
     * @param asset The address of the asset being flash borrowed
     * @param amount The amount flash borrowed
     * @param premium The fee flash borrowed
     * @param referralCode The referral code used
     **/
    event FlashLoan(
        address indexed target,
        address indexed initiator,
        address indexed asset,
        uint256 amount,
        uint256 premium,
        uint16 referralCode
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendingPool contract. The event is therefore replicated here so it
     * gets added to the LendingPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param stableBorrowRate The new stable borrow rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 stableBorrowRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
     * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
     * @param asset The address of the underlying asset to deposit
     * @param amount The amount to be deposited
     * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
     *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
     *   is a different wallet
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    /**
     * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
     * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
     * @param asset The address of the underlying asset to withdraw
     * @param amount The underlying amount to be withdrawn
     *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
     * @param to Address that will receive the underlying, same as msg.sender if the user
     *   wants to receive it on his own wallet, or a different address if the beneficiary is a
     *   different wallet
     * @return The final amount withdrawn
     **/
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral, or he was given enough allowance by a credit delegator on the
     * corresponding debt token (StableDebtToken or VariableDebtToken)
     * - E.g. User borrows 100 USDC passing as `onBehalfOf` his own address, receiving the 100 USDC in his wallet
     *   and 100 stable/variable debt tokens, depending on the `interestRateMode`
     * @param asset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param interestRateMode The interest rate mode at which the user wants to borrow: 1 for Stable, 2 for Variable
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     * @param onBehalfOf Address of the user who will receive the debt. Should be the address of the borrower itself
     * calling the function if he wants to borrow against his own collateral, or the address of the credit delegator
     * if he has been given credit delegation allowance
     **/
    function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned
     * - E.g. User repays 100 USDC, burning 100 variable/stable debt tokens of the `onBehalfOf` address
     * @param asset The address of the borrowed underlying asset previously borrowed
     * @param amount The amount to repay
     * - Send the value type(uint256).max in order to repay the whole debt for `asset` on the specific `debtMode`
     * @param rateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
     * @param onBehalfOf Address of the user who will get his debt reduced/removed. Should be the address of the
     * user calling the function if he wants to reduce/remove his own debt, or the address of any other
     * other borrower whose debt should be removed
     * @return The final amount repaid
     **/
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external returns (uint256);

    /**
     * @dev Allows a borrower to swap his debt between stable and variable mode, or viceversa
     * @param asset The address of the underlying asset borrowed
     * @param rateMode The rate mode that the user wants to swap to
     **/
    function swapBorrowRateMode(address asset, uint256 rateMode) external;

    /**
     * @dev Rebalances the stable interest rate of a user to the current stable rate defined on the reserve.
     * - Users can be rebalanced if the following conditions are satisfied:
     *     1. Usage ratio is above 95%
     *     2. the current deposit APY is below REBALANCE_UP_THRESHOLD * maxVariableBorrowRate, which means that too much has been
     *        borrowed at a stable rate and depositors are not earning enough
     * @param asset The address of the underlying asset borrowed
     * @param user The address of the user to be rebalanced
     **/
    function rebalanceStableBorrowRate(address asset, address user) external;

    /**
     * @dev Allows depositors to enable/disable a specific deposited asset as collateral
     * @param asset The address of the underlying asset deposited
     * @param useAsCollateral `true` if the user wants to use the deposit as collateral, `false` otherwise
     **/
    function setUserUseReserveAsCollateral(address asset, bool useAsCollateral) external;

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise, with Health Factor below 1
     * - The caller (liquidator) covers `debtToCover` amount of debt of the user getting liquidated, and receives
     *   a proportionally amount of the `collateralAsset` plus a bonus to cover market risk
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     **/
    function liquidationCall(
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external;

    /**
     * @dev Allows smartcontracts to access the liquidity of the pool within one transaction,
     * as long as the amount taken plus a fee is returned.
     * IMPORTANT There are security concerns for developers of flashloan receiver contracts that must be kept into consideration.
     * For further details please visit https://developers.aave.com
     * @param receiverAddress The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
     * @param assets The addresses of the assets being flash-borrowed
     * @param amounts The amounts amounts being flash-borrowed
     * @param modes Types of the debt to open if the flash loan is not returned:
     *   0 -> Don't open any debt, just revert if funds can't be transferred from the receiver
     *   1 -> Open debt at stable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     *   2 -> Open debt at variable rate for the value of the amount flash-borrowed to the `onBehalfOf` address
     * @param onBehalfOf The address  that will receive the debt in the case of using on `modes` 1 or 2
     * @param params Variadic packed params to pass to the receiver as extra information
     * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
     *   0 if the action is executed directly by the user, without any middle-man
     **/
    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external;

    /**
     * @dev Returns the user account data across all the reserves
     * @param user The address of the user
     * @return totalCollateralETH the total collateral in ETH of the user
     * @return totalDebtETH the total debt in ETH of the user
     * @return availableBorrowsETH the borrowing power left of the user
     * @return currentLiquidationThreshold the liquidation threshold of the user
     * @return ltv the loan to value of the user
     * @return healthFactor the current health factor of the user
     **/
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralETH,
            uint256 totalDebtETH,
            uint256 availableBorrowsETH,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function initReserve(
        address reserve,
        address aTokenAddress,
        address stableDebtAddress,
        address variableDebtAddress,
        address interestRateStrategyAddress
    ) external;

    function setReserveInterestRateStrategyAddress(address reserve, address rateStrategyAddress)
        external;

    function setConfiguration(address reserve, uint256 configuration) external;

    /**
     * @dev Returns the configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The configuration of the reserve
     **/
    function getConfiguration(address asset)
        external
        view
        returns (DataTypes.ReserveConfigurationMap memory);

    /**
     * @dev Returns the configuration of the user across all the reserves
     * @param user The user address
     * @return The configuration of the user
     **/
    function getUserConfiguration(address user)
        external
        view
        returns (DataTypes.UserConfigurationMap memory);

    /**
     * @dev Returns the normalized income normalized income of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve's normalized income
     */
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /**
     * @dev Returns the normalized variable debt per unit of asset
     * @param asset The address of the underlying asset of the reserve
     * @return The reserve normalized variable debt
     */
    function getReserveNormalizedVariableDebt(address asset) external view returns (uint256);

    /**
     * @dev Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state of the reserve
     **/
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function finalizeTransfer(
        address asset,
        address from,
        address to,
        uint256 amount,
        uint256 balanceFromAfter,
        uint256 balanceToBefore
    ) external;

    function getReservesList() external view returns (address[] memory);

    function getAddressesProvider() external view returns (ILendingPoolAddressesProvider);

    function setPause(bool val) external;

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {IScaledBalanceToken} from "./IScaledBalanceToken.sol";

interface IAToken is IERC20, IScaledBalanceToken {
    /**
     * @dev Emitted after the mint action
     * @param from The address performing the mint
     * @param value The amount being
     * @param index The new liquidity index of the reserve
     **/
    event Mint(address indexed from, uint256 value, uint256 index);

    /**
     * @dev Mints `amount` aTokens to `user`
     * @param user The address receiving the minted tokens
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     * @return `true` if the the previous balance of the user was 0
     */
    function mint(
        address user,
        uint256 amount,
        uint256 index
    ) external returns (bool);

    /**
     * @dev Emitted after aTokens are burned
     * @param from The owner of the aTokens, getting them burned
     * @param target The address that will receive the underlying
     * @param value The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    event Burn(address indexed from, address indexed target, uint256 value, uint256 index);

    /**
     * @dev Emitted during the transfer action
     * @param from The user whose tokens are being transferred
     * @param to The recipient
     * @param value The amount being transferred
     * @param index The new liquidity index of the reserve
     **/
    event BalanceTransfer(address indexed from, address indexed to, uint256 value, uint256 index);

    /**
     * @dev Burns aTokens from `user` and sends the equivalent amount of underlying to `receiverOfUnderlying`
     * @param user The owner of the aTokens, getting them burned
     * @param receiverOfUnderlying The address that will receive the underlying
     * @param amount The amount being burned
     * @param index The new liquidity index of the reserve
     **/
    function burn(
        address user,
        address receiverOfUnderlying,
        uint256 amount,
        uint256 index
    ) external;

    /**
     * @dev Mints aTokens to the reserve treasury
     * @param amount The amount of tokens getting minted
     * @param index The new liquidity index of the reserve
     */
    function mintToTreasury(uint256 amount, uint256 index) external;

    /**
     * @dev Transfers aTokens in the event of a borrow being liquidated, in case the liquidators reclaims the aToken
     * @param from The address getting liquidated, current owner of the aTokens
     * @param to The recipient
     * @param value The amount of tokens getting transferred
     **/
    function transferOnLiquidation(
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Transfers the underlying asset to `target`. Used by the LendingPool to transfer
     * assets in borrow(), withdraw() and flashLoan()
     * @param user The recipient of the aTokens
     * @param amount The amount getting transferred
     * @return The amount transferred
     **/
    function transferUnderlyingTo(address user, uint256 amount) external returns (uint256);

    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./aave/ILendingPoolAddressesProvider.sol";
import "./aave/ILendingPool.sol";
import "./IEntryPositionsManager.sol";
import "./IExitPositionsManager.sol";
import "./IInterestRatesManager.sol";
import "./IIncentivesVault.sol";
import "./IRewardsManager.sol";

import "../libraries/Types.sol";

// prettier-ignore
interface IMorpho {

    /// STORAGE ///

    function NO_REFERRAL_CODE() external view returns(uint8);
    function VARIABLE_INTEREST_MODE() external view returns(uint8);
    function MAX_BASIS_POINTS() external view returns(uint16);
    function DEFAULT_LIQUIDATION_CLOSE_FACTOR() external view returns(uint16);
    function HEALTH_FACTOR_LIQUIDATION_THRESHOLD() external view returns(uint256);
    function MAX_NB_OF_MARKETS() external view returns(uint256);
    function BORROWING_MASK() external view returns(bytes32);
    function ONE() external view returns(bytes32);

    function isClaimRewardsPaused() external view returns (bool);
    function defaultMaxGasForMatching() external view returns (Types.MaxGasForMatching memory);
    function maxSortedUsers() external view returns (uint256);
    function supplyBalanceInOf(address, address) external view returns (Types.SupplyBalance memory);
    function borrowBalanceInOf(address, address) external view returns (Types.BorrowBalance memory);
    function deltas(address) external view returns (Types.Delta memory);
    function market(address) external view returns (Types.Market memory);
    function p2pSupplyIndex(address) external view returns (uint256);
    function p2pBorrowIndex(address) external view returns (uint256);
    function poolIndexes(address) external view returns (Types.PoolIndexes memory);
    function interestRatesManager() external view returns (IInterestRatesManager);
    function rewardsManager() external view returns (IRewardsManager);
    function entryPositionsManager() external view returns (IEntryPositionsManager);
    function exitPositionsManager() external view returns (IExitPositionsManager);
    function aaveIncentivesController() external view returns (IAaveIncentivesController);
    function addressesProvider() external view returns (ILendingPoolAddressesProvider);
    function incentivesVault() external view returns (IIncentivesVault);
    function pool() external view returns (ILendingPool);
    function treasuryVault() external view returns (address);
    function borrowMask(address) external view returns (bytes32);
    function userMarkets(address) external view returns (bytes32);

    /// UTILS ///

    function updateIndexes(address _poolToken) external;

    /// GETTERS ///

    function getMarketsCreated() external view returns (address[] memory marketsCreated_);
    function getHead(address _poolToken, Types.PositionType _positionType) external view returns (address head);
    function getNext(address _poolToken, Types.PositionType _positionType, address _user) external view returns (address next);

    /// GOVERNANCE ///

    function setMaxSortedUsers(uint256 _newMaxSortedUsers) external;
    function setDefaultMaxGasForMatching(Types.MaxGasForMatching memory _maxGasForMatching) external;
    function setTreasuryVault(address _newTreasuryVaultAddress) external;
    function setIncentivesVault(address _newIncentivesVault) external;
    function setRewardsManager(address _rewardsManagerAddress) external;
    function setP2PDisabledStatus(address _poolToken, bool _isP2PDisabled) external;
    function setReserveFactor(address _poolToken, uint256 _newReserveFactor) external;
    function setP2PIndexCursor(address _poolToken, uint16 _p2pIndexCursor) external;
    function setPauseStatusForAllMarkets(bool _newStatus) external;
    function setClaimRewardsPauseStatus(bool _newStatus) external;
    function setPauseStatus(address _poolToken, bool _newStatus) external;
    function setPartialPauseStatus(address _poolToken, bool _newStatus) external;
    function setExitPositionsManager(IExitPositionsManager _exitPositionsManager) external;
    function setEntryPositionsManager(IEntryPositionsManager _entryPositionsManager) external;
    function setInterestRatesManager(IInterestRatesManager _interestRatesManager) external;
    function claimToTreasury(address[] calldata _poolTokens, uint256[] calldata _amounts) external;
    function createMarket(address _underlyingToken, uint16 _reserveFactor, uint16 _p2pIndexCursor) external;

    /// USERS ///

    function supply(address _poolToken, address _onBehalf, uint256 _amount) external;
    function supply(address _poolToken, address _onBehalf, uint256 _amount, uint256 _maxGasForMatching) external;
    function borrow(address _poolToken, uint256 _amount) external;
    function borrow(address _poolToken, uint256 _amount, uint256 _maxGasForMatching) external;
    function withdraw(address _poolToken, uint256 _amount) external;
    function repay(address _poolToken, address _onBehalf, uint256 _amount) external;
    function liquidate(address _poolTokenBorrowed, address _poolTokenCollateral, address _borrower, uint256 _amount) external;
    function claimRewards(address[] calldata _assets, bool _tradeForMorphoToken) external returns (uint256 claimedAmount);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import {Errors} from "./Errors.sol";
import {DataTypes} from "./DataTypes.sol";

/**
 * @title ReserveConfiguration library
 * @author Aave
 * @notice Implements the bitmap logic to handle the reserve configuration
 */
library ReserveConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant LIQUIDATION_THRESHOLD_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFF; // prettier-ignore
    uint256 constant LIQUIDATION_BONUS_MASK =     0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFF; // prettier-ignore
    uint256 constant DECIMALS_MASK =              0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00FFFFFFFFFFFF; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant FROZEN_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant BORROWING_MASK =             0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFBFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant STABLE_BORROWING_MASK =      0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF7FFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant RESERVE_FACTOR_MASK =        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant LIQUIDATION_THRESHOLD_START_BIT_POSITION = 16;
    uint256 constant LIQUIDATION_BONUS_START_BIT_POSITION = 32;
    uint256 constant RESERVE_DECIMALS_START_BIT_POSITION = 48;
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant IS_FROZEN_START_BIT_POSITION = 57;
    uint256 constant BORROWING_ENABLED_START_BIT_POSITION = 58;
    uint256 constant STABLE_BORROWING_ENABLED_START_BIT_POSITION = 59;
    uint256 constant RESERVE_FACTOR_START_BIT_POSITION = 64;

    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_THRESHOLD = 65535;
    uint256 constant MAX_VALID_LIQUIDATION_BONUS = 65535;
    uint256 constant MAX_VALID_DECIMALS = 255;
    uint256 constant MAX_VALID_RESERVE_FACTOR = 65535;

    /**
     * @dev Sets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @param ltv the new ltv
     **/
    function setLtv(DataTypes.ReserveConfigurationMap memory self, uint256 ltv) internal pure {
        require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @dev Gets the Loan to Value of the reserve
     * @param self The reserve configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @dev Sets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @param threshold The new liquidation threshold
     **/
    function setLiquidationThreshold(
        DataTypes.ReserveConfigurationMap memory self,
        uint256 threshold
    ) internal pure {
        require(threshold <= MAX_VALID_LIQUIDATION_THRESHOLD, Errors.RC_INVALID_LIQ_THRESHOLD);

        self.data =
            (self.data & LIQUIDATION_THRESHOLD_MASK) |
            (threshold << LIQUIDATION_THRESHOLD_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation threshold of the reserve
     * @param self The reserve configuration
     * @return The liquidation threshold
     **/
    function getLiquidationThreshold(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION;
    }

    /**
     * @dev Sets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @param bonus The new liquidation bonus
     **/
    function setLiquidationBonus(DataTypes.ReserveConfigurationMap memory self, uint256 bonus)
        internal
        pure
    {
        require(bonus <= MAX_VALID_LIQUIDATION_BONUS, Errors.RC_INVALID_LIQ_BONUS);

        self.data =
            (self.data & LIQUIDATION_BONUS_MASK) |
            (bonus << LIQUIDATION_BONUS_START_BIT_POSITION);
    }

    /**
     * @dev Gets the liquidation bonus of the reserve
     * @param self The reserve configuration
     * @return The liquidation bonus
     **/
    function getLiquidationBonus(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION;
    }

    /**
     * @dev Sets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @param decimals The decimals
     **/
    function setDecimals(DataTypes.ReserveConfigurationMap memory self, uint256 decimals)
        internal
        pure
    {
        require(decimals <= MAX_VALID_DECIMALS, Errors.RC_INVALID_DECIMALS);

        self.data = (self.data & DECIMALS_MASK) | (decimals << RESERVE_DECIMALS_START_BIT_POSITION);
    }

    /**
     * @dev Gets the decimals of the underlying asset of the reserve
     * @param self The reserve configuration
     * @return The decimals of the asset
     **/
    function getDecimals(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION;
    }

    /**
     * @dev Sets the active state of the reserve
     * @param self The reserve configuration
     * @param active The active state
     **/
    function setActive(DataTypes.ReserveConfigurationMap memory self, bool active) internal pure {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the reserve
     * @param self The reserve configuration
     * @return The active state
     **/
    function getActive(DataTypes.ReserveConfigurationMap memory self) internal pure returns (bool) {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the frozen state of the reserve
     * @param self The reserve configuration
     * @param frozen The frozen state
     **/
    function setFrozen(DataTypes.ReserveConfigurationMap memory self, bool frozen) internal pure {
        self.data =
            (self.data & FROZEN_MASK) |
            (uint256(frozen ? 1 : 0) << IS_FROZEN_START_BIT_POSITION);
    }

    /**
     * @dev Gets the frozen state of the reserve
     * @param self The reserve configuration
     * @return The frozen state
     **/
    function getFrozen(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~FROZEN_MASK) != 0;
    }

    /**
     * @dev Enables or disables borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the borrowing needs to be enabled, false otherwise
     **/
    function setBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self, bool enabled)
        internal
        pure
    {
        self.data =
            (self.data & BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the borrowing state of the reserve
     * @param self The reserve configuration
     * @return The borrowing state
     **/
    function getBorrowingEnabled(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (bool)
    {
        return (self.data & ~BORROWING_MASK) != 0;
    }

    /**
     * @dev Enables or disables stable rate borrowing on the reserve
     * @param self The reserve configuration
     * @param enabled True if the stable rate borrowing needs to be enabled, false otherwise
     **/
    function setStableRateBorrowingEnabled(
        DataTypes.ReserveConfigurationMap memory self,
        bool enabled
    ) internal pure {
        self.data =
            (self.data & STABLE_BORROWING_MASK) |
            (uint256(enabled ? 1 : 0) << STABLE_BORROWING_ENABLED_START_BIT_POSITION);
    }

    /**
     * @dev Gets the stable rate borrowing state of the reserve
     * @param self The reserve configuration
     * @return The stable rate borrowing state
     **/
    function getStableRateBorrowingEnabled(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~STABLE_BORROWING_MASK) != 0;
    }

    /**
     * @dev Sets the reserve factor of the reserve
     * @param self The reserve configuration
     * @param reserveFactor The reserve factor
     **/
    function setReserveFactor(DataTypes.ReserveConfigurationMap memory self, uint256 reserveFactor)
        internal
        pure
    {
        require(reserveFactor <= MAX_VALID_RESERVE_FACTOR, Errors.RC_INVALID_RESERVE_FACTOR);

        self.data =
            (self.data & RESERVE_FACTOR_MASK) |
            (reserveFactor << RESERVE_FACTOR_START_BIT_POSITION);
    }

    /**
     * @dev Gets the reserve factor of the reserve
     * @param self The reserve configuration
     * @return The reserve factor
     **/
    function getReserveFactor(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (uint256)
    {
        return (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION;
    }

    /**
     * @dev Gets the configuration flags of the reserve
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlags(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        uint256 dataLocal = self.data;

        return (
            (dataLocal & ~ACTIVE_MASK) != 0,
            (dataLocal & ~FROZEN_MASK) != 0,
            (dataLocal & ~BORROWING_MASK) != 0,
            (dataLocal & ~STABLE_BORROWING_MASK) != 0
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve
     * @param self The reserve configuration
     * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
     **/
    function getParams(DataTypes.ReserveConfigurationMap storage self)
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 dataLocal = self.data;

        return (
            dataLocal & ~LTV_MASK,
            (dataLocal & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (dataLocal & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (dataLocal & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (dataLocal & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration paramters of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state params representing ltv, liquidation threshold, liquidation bonus, the reserve decimals
     **/
    function getParamsMemory(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            self.data & ~LTV_MASK,
            (self.data & ~LIQUIDATION_THRESHOLD_MASK) >> LIQUIDATION_THRESHOLD_START_BIT_POSITION,
            (self.data & ~LIQUIDATION_BONUS_MASK) >> LIQUIDATION_BONUS_START_BIT_POSITION,
            (self.data & ~DECIMALS_MASK) >> RESERVE_DECIMALS_START_BIT_POSITION,
            (self.data & ~RESERVE_FACTOR_MASK) >> RESERVE_FACTOR_START_BIT_POSITION
        );
    }

    /**
     * @dev Gets the configuration flags of the reserve from a memory object
     * @param self The reserve configuration
     * @return The state flags representing active, frozen, borrowing enabled, stableRateBorrowing enabled
     **/
    function getFlagsMemory(DataTypes.ReserveConfigurationMap memory self)
        internal
        pure
        returns (
            bool,
            bool,
            bool,
            bool
        )
    {
        return (
            (self.data & ~ACTIVE_MASK) != 0,
            (self.data & ~FROZEN_MASK) != 0,
            (self.data & ~BORROWING_MASK) != 0,
            (self.data & ~STABLE_BORROWING_MASK) != 0
        );
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title PercentageMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library PercentageMath to conduct percentage manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/PercentageMath.sol
library PercentageMath {
    ///	CONSTANTS ///

    uint256 internal constant PERCENTAGE_FACTOR = 1e4;
    uint256 internal constant HALF_PERCENTAGE_FACTOR = 0.5e4;
    uint256 internal constant MAX_UINT256 = 2**256 - 1;
    uint256 internal constant MAX_UINT256_MINUS_HALF_PERCENTAGE = 2**256 - 1 - 0.5e4;

    /// ERRORS ///

    // Thrown when percentage is above 100%.
    error PercentageTooHigh();

    /// INTERNAL ///

    /// @notice Executes a percentage multiplication.
    /// @param x The value of which the percentage needs to be calculated.
    /// @param percentage The percentage of the value to be calculated.
    /// @return y The result of the multiplication.
    function percentMul(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // Let percentage > 0
        // Overflow if x * percentage + HALF_PERCENTAGE_FACTOR > type(uint256).max
        // <=> x * percentage > type(uint256).max - HALF_PERCENTAGE_FACTOR
        // <=> x > (type(uint256).max - HALF_PERCENTAGE_FACTOR) / percentage
        assembly {
            if mul(percentage, gt(x, div(MAX_UINT256_MINUS_HALF_PERCENTAGE, percentage))) {
                revert(0, 0)
            }

            y := div(add(mul(x, percentage), HALF_PERCENTAGE_FACTOR), PERCENTAGE_FACTOR)
        }
    }

    /// @notice Executes a percentage division.
    /// @param x The value of which the percentage needs to be calculated.
    /// @param percentage The percentage of the value to be calculated.
    /// @return y The result of the division.
    function percentDiv(uint256 x, uint256 percentage) internal pure returns (uint256 y) {
        // let percentage > 0
        // Overflow if x * PERCENTAGE_FACTOR + halfPercentage > type(uint256).max
        // <=> x * PERCENTAGE_FACTOR > type(uint256).max - halfPercentage
        // <=> x > type(uint256).max - halfPercentage / PERCENTAGE_FACTOR
        assembly {
            y := div(percentage, 2)
            if iszero(mul(percentage, iszero(gt(x, div(sub(MAX_UINT256, y), PERCENTAGE_FACTOR))))) {
                revert(0, 0)
            }

            y := div(add(mul(x, PERCENTAGE_FACTOR), y), percentage)
        }
    }

    /// @notice Executes a weighted average, given an interval [x, y] and a percent p: x * (1 - p) + y * p
    /// @param x The value at the start of the interval (included).
    /// @param y The value at the end of the interval (included).
    /// @param percentage The percentage of the interval to be calculated.
    /// @return the average of x and y, weighted by percentage.
    function weightedAvg(
        uint256 x,
        uint256 y,
        uint256 percentage
    ) internal pure returns (uint256) {
        if (percentage > PERCENTAGE_FACTOR) revert PercentageTooHigh();

        return percentMul(x, PERCENTAGE_FACTOR - percentage) + percentMul(y, percentage);
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title WadRayMath.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @notice Optimized version of Aave V3 math library WadRayMath to conduct wad and ray manipulations: https://github.com/aave/aave-v3-core/blob/master/contracts/protocol/libraries/math/WadRayMath.sol
library WadRayMath {
    /// CONSTANTS ///

    uint256 internal constant WAD = 1e18;
    uint256 internal constant HALF_WAD = 0.5e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant HALF_RAY = 0.5e27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;
    uint256 internal constant HALF_WAD_RAY_RATIO = 0.5e9;
    uint256 internal constant MAX_UINT256 = 2**256 - 1; // Not possible to use type(uint256).max in yul.
    uint256 internal constant MAX_UINT256_MINUS_HALF_WAD = 2**256 - 1 - 0.5e18;
    uint256 internal constant MAX_UINT256_MINUS_HALF_RAY = 2**256 - 1 - 0.5e27;

    /// INTERNAL ///

    /// @dev Multiplies two wad, rounding half up to the nearest wad.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x * y, in wad.
    function wadMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Let y > 0
        // Overflow if (x * y + HALF_WAD) > type(uint256).max
        // <=> x * y > type(uint256).max - HALF_WAD
        // <=> x > (type(uint256).max - HALF_WAD) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_WAD, y))) {
                revert(0, 0)
            }

            z := div(add(mul(x, y), HALF_WAD), WAD)
        }
    }

    /// @dev Divides two wad, rounding half up to the nearest wad.
    /// @param x Wad.
    /// @param y Wad.
    /// @return z The result of x / y, in wad.
    function wadDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if y == 0
        // Overflow if (x * WAD + y / 2) > type(uint256).max
        // <=> x * WAD > type(uint256).max - y / 2
        // <=> x > (type(uint256).max - y / 2) / WAD
        assembly {
            z := div(y, 2)
            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), WAD))))) {
                revert(0, 0)
            }

            z := div(add(mul(x, WAD), z), y)
        }
    }

    /// @dev Multiplies two ray, rounding half up to the nearest ray.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x * y, in ray.
    function rayMul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Let y > 0
        // Overflow if (x * y + HALF_RAY) > type(uint256).max
        // <=> x * y > type(uint256).max - HALF_RAY
        // <=> x > (type(uint256).max - HALF_RAY) / y
        assembly {
            if mul(y, gt(x, div(MAX_UINT256_MINUS_HALF_RAY, y))) {
                revert(0, 0)
            }

            z := div(add(mul(x, y), HALF_RAY), RAY)
        }
    }

    /// @dev Divides two ray, rounding half up to the nearest ray.
    /// @param x Ray.
    /// @param y Ray.
    /// @return z The result of x / y, in ray.
    function rayDiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        // Overflow if y == 0
        // Overflow if (x * RAY + y / 2) > type(uint256).max
        // <=> x * RAY > type(uint256).max - y / 2
        // <=> x > (type(uint256).max - y / 2) / RAY
        assembly {
            z := div(y, 2)
            if iszero(mul(y, iszero(gt(x, div(sub(MAX_UINT256, z), RAY))))) {
                revert(0, 0)
            }

            z := div(add(mul(x, RAY), z), y)
        }
    }

    /// @dev Casts ray down to wad.
    /// @param x Ray.
    /// @return y = x converted to wad, rounded half up to the nearest wad.
    function rayToWad(uint256 x) internal pure returns (uint256 y) {
        assembly {
            // If x % WAD_RAY_RATIO >= HALF_WAD_RAY_RATIO, round up.
            y := add(div(x, WAD_RAY_RATIO), iszero(lt(mod(x, WAD_RAY_RATIO), HALF_WAD_RAY_RATIO)))
        }
    }

    /// @dev Converts wad up to ray.
    /// @param x Wad.
    /// @return y = x converted in ray.
    function wadToRay(uint256 x) internal pure returns (uint256 y) {
        assembly {
            y := mul(x, WAD_RAY_RATIO)
            // Revert if y / WAD_RAY_RATIO != x
            if iszero(eq(div(y, WAD_RAY_RATIO), x)) {
                revert(0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(mul(x, lt(x, y)), mul(y, iszero(lt(x, y))))
        }
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := add(mul(x, gt(x, y)), mul(y, iszero(gt(x, y))))
        }
    }

    /// @dev Returns max(x - y, 0).
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns x / y rounded up (x / y + boolAsInt(x % y > 0)).
    function divUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Revert if y = 0
            if iszero(y) {
                revert(0, 0)
            }

            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {
        NONE,
        STABLE,
        VARIABLE
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "../../../lib/morpho-utils/src/math/PercentageMath.sol";
import "../../../lib/morpho-utils/src/math/WadRayMath.sol";
import "../../../lib/morpho-utils/src/math/Math.sol";

import "./Types.sol";

library InterestRatesModel {
    using PercentageMath for uint256;
    using WadRayMath for uint256;

    /// ERRORS ///

    // Thrown when percentage is above 100%.
    error PercentageTooHigh();

    /// STRUCTS ///

    struct GrowthFactors {
        uint256 poolSupplyGrowthFactor; // The pool's supply index growth factor (in ray).
        uint256 poolBorrowGrowthFactor; // The pool's borrow index growth factor (in ray).
        uint256 p2pSupplyGrowthFactor; // Peer-to-peer supply index growth factor (in ray).
        uint256 p2pBorrowGrowthFactor; // Peer-to-peer borrow index growth factor (in ray).
    }

    struct P2PIndexComputeParams {
        uint256 poolGrowthFactor; // The pool's index growth factor (in ray).
        uint256 p2pGrowthFactor; // Morpho peer-to-peer's median index growth factor (in ray).
        uint256 lastPoolIndex; // The pool's last stored index (in ray).
        uint256 lastP2PIndex; // Morpho's last stored peer-to-peer index (in ray).
        uint256 p2pDelta; // The peer-to-peer delta for the given market (in pool unit).
        uint256 p2pAmount; // The peer-to-peer amount for the given market (in peer-to-peer unit).
    }

    struct P2PRateComputeParams {
        uint256 poolRate; // The pool's index growth factor (in wad).
        uint256 p2pRate; // Morpho peer-to-peer's median index growth factor (in wad).
        uint256 poolIndex; // The pool's last stored index (in ray).
        uint256 p2pIndex; // Morpho's last stored peer-to-peer index (in ray).
        uint256 p2pDelta; // The peer-to-peer delta for the given market (in pool unit).
        uint256 p2pAmount; // The peer-to-peer amount for the given market (in peer-to-peer unit).
        uint256 reserveFactor; // The reserve factor of the given market (in bps).
    }

    /// @notice Computes and returns the new growth factors associated to a given pool's supply/borrow index & Morpho's peer-to-peer index.
    /// @param _newPoolSupplyIndex The pool's last current supply index.
    /// @param _newPoolBorrowIndex The pool's last current borrow index.
    /// @param _lastPoolIndexes The pool's last stored indexes.
    /// @param _p2pIndexCursor The peer-to-peer index cursor for the given market.
    /// @param _reserveFactor The reserve factor of the given market.
    /// @return growthFactors The market's indexes growth factors (in ray).
    function computeGrowthFactors(
        uint256 _newPoolSupplyIndex,
        uint256 _newPoolBorrowIndex,
        Types.PoolIndexes memory _lastPoolIndexes,
        uint256 _p2pIndexCursor,
        uint256 _reserveFactor
    ) internal pure returns (GrowthFactors memory growthFactors) {
        growthFactors.poolSupplyGrowthFactor = _newPoolSupplyIndex.rayDiv(
            _lastPoolIndexes.poolSupplyIndex
        );
        growthFactors.poolBorrowGrowthFactor = _newPoolBorrowIndex.rayDiv(
            _lastPoolIndexes.poolBorrowIndex
        );

        uint256 p2pGrowthFactor = PercentageMath.weightedAvg(
            growthFactors.poolSupplyGrowthFactor,
            growthFactors.poolBorrowGrowthFactor,
            _p2pIndexCursor
        );

        growthFactors.p2pSupplyGrowthFactor =
            p2pGrowthFactor -
            (p2pGrowthFactor - growthFactors.poolSupplyGrowthFactor).percentMul(_reserveFactor);
        growthFactors.p2pBorrowGrowthFactor =
            p2pGrowthFactor +
            (growthFactors.poolBorrowGrowthFactor - p2pGrowthFactor).percentMul(_reserveFactor);
    }

    /// @notice Computes and returns the new peer-to-peer supply index of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return newP2PSupplyIndex The updated peer-to-peer index (in ray).
    function computeP2PSupplyIndex(P2PIndexComputeParams memory _params)
        internal
        pure
        returns (uint256 newP2PSupplyIndex)
    {
        if (_params.p2pAmount == 0 || _params.p2pDelta == 0) {
            newP2PSupplyIndex = _params.lastP2PIndex.rayMul(_params.p2pGrowthFactor);
        } else {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.wadToRay().rayMul(_params.lastPoolIndex).rayDiv(
                    _params.p2pAmount.wadToRay().rayMul(_params.lastP2PIndex)
                ),
                WadRayMath.RAY // To avoid shareOfTheDelta > 1 with rounding errors.
            ); // In ray.

            newP2PSupplyIndex = _params.lastP2PIndex.rayMul(
                (WadRayMath.RAY - shareOfTheDelta).rayMul(_params.p2pGrowthFactor) +
                    shareOfTheDelta.rayMul(_params.poolGrowthFactor)
            );
        }
    }

    /// @notice Computes and returns the new peer-to-peer borrow index of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return newP2PBorrowIndex The updated peer-to-peer index (in ray).
    function computeP2PBorrowIndex(P2PIndexComputeParams memory _params)
        internal
        pure
        returns (uint256 newP2PBorrowIndex)
    {
        if (_params.p2pAmount == 0 || _params.p2pDelta == 0) {
            newP2PBorrowIndex = _params.lastP2PIndex.rayMul(_params.p2pGrowthFactor);
        } else {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.wadToRay().rayMul(_params.lastPoolIndex).rayDiv(
                    _params.p2pAmount.wadToRay().rayMul(_params.lastP2PIndex)
                ),
                WadRayMath.RAY // To avoid shareOfTheDelta > 1 with rounding errors.
            ); // In ray.

            newP2PBorrowIndex = _params.lastP2PIndex.rayMul(
                (WadRayMath.RAY - shareOfTheDelta).rayMul(_params.p2pGrowthFactor) +
                    shareOfTheDelta.rayMul(_params.poolGrowthFactor)
            );
        }
    }

    /// @notice Computes and returns the peer-to-peer supply rate per year of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return p2pSupplyRate The peer-to-peer supply rate per year (in ray).
    function computeP2PSupplyRatePerYear(P2PRateComputeParams memory _params)
        internal
        pure
        returns (uint256 p2pSupplyRate)
    {
        p2pSupplyRate =
            _params.p2pRate -
            (_params.p2pRate - _params.poolRate).percentMul(_params.reserveFactor);

        if (_params.p2pDelta > 0 && _params.p2pAmount > 0) {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.wadToRay().rayMul(_params.poolIndex).rayDiv(
                    _params.p2pAmount.wadToRay().rayMul(_params.p2pIndex)
                ),
                WadRayMath.RAY // To avoid shareOfTheDelta > 1 with rounding errors.
            ); // In ray.

            p2pSupplyRate =
                p2pSupplyRate.rayMul(WadRayMath.RAY - shareOfTheDelta) +
                _params.poolRate.rayMul(shareOfTheDelta);
        }
    }

    /// @notice Computes and returns the peer-to-peer borrow rate per year of a market given its parameters.
    /// @param _params The computation parameters.
    /// @return p2pBorrowRate The peer-to-peer borrow rate per year (in ray).
    function computeP2PBorrowRatePerYear(P2PRateComputeParams memory _params)
        internal
        pure
        returns (uint256 p2pBorrowRate)
    {
        p2pBorrowRate =
            _params.p2pRate +
            (_params.poolRate - _params.p2pRate).percentMul(_params.reserveFactor);

        if (_params.p2pDelta > 0 && _params.p2pAmount > 0) {
            uint256 shareOfTheDelta = Math.min(
                _params.p2pDelta.wadToRay().rayMul(_params.poolIndex).rayDiv(
                    _params.p2pAmount.wadToRay().rayMul(_params.p2pIndex)
                ),
                WadRayMath.RAY // To avoid shareOfTheDelta > 1 with rounding errors.
            ); // In ray.

            p2pBorrowRate =
                p2pBorrowRate.rayMul(WadRayMath.RAY - shareOfTheDelta) +
                _params.poolRate.rayMul(shareOfTheDelta);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title LendingPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Aave Governance
 * @author Aave
 **/
interface ILendingPoolAddressesProvider {
    event MarketIdSet(string newMarketId);
    event LendingPoolUpdated(address indexed newAddress);
    event ConfigurationAdminUpdated(address indexed newAddress);
    event EmergencyAdminUpdated(address indexed newAddress);
    event LendingPoolConfiguratorUpdated(address indexed newAddress);
    event LendingPoolCollateralManagerUpdated(address indexed newAddress);
    event PriceOracleUpdated(address indexed newAddress);
    event LendingRateOracleUpdated(address indexed newAddress);
    event ProxyCreated(bytes32 id, address indexed newAddress);
    event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy);

    function getMarketId() external view returns (string memory);

    function setMarketId(string calldata marketId) external;

    function setAddress(bytes32 id, address newAddress) external;

    function setAddressAsProxy(bytes32 id, address impl) external;

    function getAddress(bytes32 id) external view returns (address);

    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address pool) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address configurator) external;

    function getLendingPoolCollateralManager() external view returns (address);

    function setLendingPoolCollateralManager(address manager) external;

    function getPoolAdmin() external view returns (address);

    function setPoolAdmin(address admin) external;

    function getEmergencyAdmin() external view returns (address);

    function setEmergencyAdmin(address admin) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address lendingRateOracle) external;
}

// SPDX-License-Identifier: agpl-3.0
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

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IEntryPositionsManager {
    function supplyLogic(
        address _poolToken,
        address _supplier,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function borrowLogic(
        address _poolToken,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IExitPositionsManager {
    function withdrawLogic(
        address _poolToken,
        uint256 _amount,
        address _supplier,
        address _receiver,
        uint256 _maxGasForMatching
    ) external;

    function repayLogic(
        address _poolToken,
        address _repayer,
        address _onBehalf,
        uint256 _amount,
        uint256 _maxGasForMatching
    ) external;

    function liquidateLogic(
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address _borrower,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IInterestRatesManager {
    function updateIndexes(address _marketAddress) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./IOracle.sol";

interface IIncentivesVault {
    function setOracle(IOracle _newOracle) external;

    function setIncentivesTreasuryVault(address _newIncentivesTreasuryVault) external;

    function setBonus(uint256 _newBonus) external;

    function setPauseStatus(bool _newStatus) external;

    function transferTokensToDao(address _token, uint256 _amount) external;

    function tradeRewardTokensForMorphoTokens(address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

import "./aave/IAaveIncentivesController.sol";

interface IRewardsManager {
    function initialize(address _morpho) external;

    function getUserIndex(address, address) external returns (uint256);

    function getUserUnclaimedRewards(address[] calldata, address) external view returns (uint256);

    function claimRewards(
        IAaveIncentivesController _aaveIncentivesController,
        address[] calldata,
        address
    ) external returns (uint256);

    function updateUserAssetAndAccruedRewards(
        IAaveIncentivesController _aaveIncentivesController,
        address _user,
        address _asset,
        uint256 _userBalance,
        uint256 _totalBalance
    ) external;
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

/// @title Types.
/// @author Morpho Labs.
/// @custom:contact [email protected]
/// @dev Common types and structs used in Morpho contracts.
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
        uint256 onPool; // In scaled balance. Multiply by the pool supply index to get the underlying amount.
    }

    struct BorrowBalance {
        uint256 inP2P; // In borrower's peer-to-peer unit, a unit that grows in underlying value, to keep track of the interests paid by borrowers in peer-to-peer. Multiply by the peer-to-peer borrow index to get the underlying amount.
        uint256 onPool; // In adUnit, a unit that grows in value, to keep track of the debt increase when borrowers are on Aave. Multiply by the pool borrow index to get the underlying amount.
    }

    // Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
    struct MaxGasForMatching {
        uint64 supply;
        uint64 borrow;
        uint64 withdraw;
        uint64 repay;
    }

    struct Delta {
        uint256 p2pSupplyDelta; // Difference between the stored peer-to-peer supply amount and the real peer-to-peer supply amount (in aToken).
        uint256 p2pBorrowDelta; // Difference between the stored peer-to-peer borrow amount and the real peer-to-peer borrow amount (in adUnit).
        uint256 p2pSupplyAmount; // Sum of all stored peer-to-peer supply (in peer-to-peer unit).
        uint256 p2pBorrowAmount; // Sum of all stored peer-to-peer borrow (in peer-to-peer unit).
    }

    struct AssetLiquidityData {
        uint256 decimals; // The number of decimals of the underlying token.
        uint256 tokenUnit; // The token unit considering its decimals.
        uint256 liquidationThreshold; // The liquidation threshold applied on this token (in basis point).
        uint256 ltv; // The LTV applied on this token (in basis point).
        uint256 underlyingPrice; // The price of the token (in ETH).
        uint256 collateral; // The collateral value of the asset (in ETH).
        uint256 debt; // The debt value of the asset (in ETH).
    }

    struct LiquidityData {
        uint256 collateral; // The collateral value (in ETH).
        uint256 maxDebt; // The max debt value (in ETH).
        uint256 liquidationThreshold; // The liquidation threshold value (in ETH).
        uint256 debt; // The debt value (in ETH).
    }

    // Variables are packed together to save gas (will not exceed their limit during Morpho's lifetime).
    struct PoolIndexes {
        uint32 lastUpdateTimestamp; // The last time the local pool and peer-to-peer indexes were updated.
        uint112 poolSupplyIndex; // Last pool supply index.
        uint112 poolBorrowIndex; // Last pool borrow index.
    }

    struct Market {
        address underlyingToken; // The underlying address of the market.
        uint16 reserveFactor; // Proportion of the additional interest earned being matched peer-to-peer on Morpho compared to being on the pool. It is sent to the DAO for each market. The default value is 0. In basis point (100% = 10 000).
        uint16 p2pIndexCursor; // Position of the peer-to-peer rate in the pool's spread. Determine the weights of the weighted arithmetic average in the indexes computations ((1 - p2pIndexCursor) * r^S + p2pIndexCursor * r^B) (in basis point).
        bool isCreated; // Whether or not this market is created.
        bool isPaused; // Whether the market is paused or not (all entry points on Morpho are frozen; supply, borrow, withdraw, repay and liquidate).
        bool isPartiallyPaused; // Whether the market is partially paused or not (only supply and borrow are frozen).
        bool isP2PDisabled; // Whether the market's peer-to-peer is open or not.
    }

    struct LiquidityStackVars {
        address poolToken;
        uint256 poolTokensLength;
        bytes32 userMarkets;
        bytes32 borrowMask;
        address underlyingToken;
        uint256 underlyingPrice;
    }
}

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity ^0.8.0;

interface IOracle {
    function consult(uint256 _amountIn) external returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

interface IAaveDistributionManager {
    event AssetConfigUpdated(address indexed asset, uint256 emission);
    event AssetIndexUpdated(address indexed asset, uint256 index);
    event UserIndexUpdated(address indexed user, address indexed asset, uint256 index);
    event DistributionEndUpdated(uint256 newDistributionEnd);

    /**
     * @dev Sets the end date for the distribution
     * @param distributionEnd The end date timestamp
     **/
    function setDistributionEnd(uint256 distributionEnd) external;

    /**
     * @dev Gets the end date for the distribution
     * @return The end of the distribution
     **/
    function getDistributionEnd() external view returns (uint256);

    /**
     * @dev for backwards compatibility with the previous DistributionManager used
     * @return The end of the distribution
     **/
    function DISTRIBUTION_END() external view returns (uint256);

    /**
     * @dev Returns the data of an user on a distribution
     * @param user Address of the user
     * @param asset The address of the reference asset of the distribution
     * @return The new index
     **/
    function getUserAssetData(address user, address asset) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The address of the reference asset of the distribution
     * @return The asset index, the emission per second and the last updated timestamp
     **/
    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );
}

interface IAaveIncentivesController is IAaveDistributionManager {
    event RewardsAccrued(address indexed user, uint256 amount);

    event RewardsClaimed(
        address indexed user,
        address indexed to,
        address indexed claimer,
        uint256 amount
    );

    event ClaimerSet(address indexed user, address indexed claimer);

    /**
     * @dev Whitelists an address to claim the rewards on behalf of another address
     * @param user The address of the user
     * @param claimer The address of the claimer
     */
    function setClaimer(address user, address claimer) external;

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);

    /**
     * @dev Configure assets for a certain rewards emission
     * @param assets The assets to incentivize
     * @param emissionsPerSecond The emission for each asset
     */
    function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
        external;

    /**
     * @dev Called by the corresponding asset on any update that affects the rewards distribution
     * @param asset The address of the user
     * @param userBalance The balance of the user of the asset in the lending pool
     * @param totalSupply The total supply of the asset in the lending pool
     **/
    function handleAction(
        address asset,
        uint256 userBalance,
        uint256 totalSupply
    ) external;

    /**
     * @dev Returns the total of rewards of an user, already accrued + not yet accrued
     * @param user The address of the user
     * @return The rewards
     **/
    function getRewardsBalance(address[] calldata assets, address user)
        external
        view
        returns (uint256);

    /**
     * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
     * @param amount Amount of rewards to claim
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewards(
        address[] calldata assets,
        uint256 amount,
        address to
    ) external returns (uint256);

    /**
     * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
     * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
     * @param amount Amount of rewards to claim
     * @param user Address to check and claim rewards
     * @param to Address that will be receiving the rewards
     * @return Rewards claimed
     **/
    function claimRewardsOnBehalf(
        address[] calldata assets,
        uint256 amount,
        address user,
        address to
    ) external returns (uint256);

    /**
     * @dev returns the unclaimed rewards of the user
     * @param user the address of the user
     * @return the unclaimed user rewards
     */
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    /**
     * @dev for backward compatibility with previous implementation of the Incentives controller
     */
    function REWARD_TOKEN() external view returns (address);

    struct AssetData {
        uint128 emissionPerSecond;
        uint128 lastUpdateTimestamp;
        uint256 index;
    }

    function assets(address) external view returns (AssetData memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title Errors library
 * @author Aave
 * @notice Defines the error messages emitted by the different contracts of the Aave protocol
 * @dev Error messages prefix glossary:
 *  - VL = ValidationLogic
 *  - MATH = Math libraries
 *  - CT = Common errors between tokens (AToken, VariableDebtToken and StableDebtToken)
 *  - AT = AToken
 *  - SDT = StableDebtToken
 *  - VDT = VariableDebtToken
 *  - LP = LendingPool
 *  - LPAPR = LendingPoolAddressesProviderRegistry
 *  - LPC = LendingPoolConfiguration
 *  - RL = ReserveLogic
 *  - LPCM = LendingPoolCollateralManager
 *  - P = Pausable
 */
library Errors {
    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "33"; // 'The caller must be the pool admin'
    string public constant BORROW_ALLOWANCE_NOT_ENOUGH = "59"; // User borrows on behalf, but allowance are too small

    //contract specific errors
    string public constant VL_INVALID_AMOUNT = "1"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "2"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "3"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_CURRENT_AVAILABLE_LIQUIDITY_NOT_ENOUGH = "4"; // 'The current liquidity is not enough'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "5"; // 'User cannot withdraw more than the available balance'
    string public constant VL_TRANSFER_NOT_ALLOWED = "6"; // 'Transfer cannot be allowed.'
    string public constant VL_BORROWING_NOT_ENABLED = "7"; // 'Borrowing is not enabled'
    string public constant VL_INVALID_INTEREST_RATE_MODE_SELECTED = "8"; // 'Invalid interest rate mode selected'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "9"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD = "10"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "11"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_STABLE_BORROWING_NOT_ENABLED = "12"; // stable borrowing not enabled
    string public constant VL_COLLATERAL_SAME_AS_BORROWING_CURRENCY = "13"; // collateral is (mostly) the same currency that is being borrowed
    string public constant VL_AMOUNT_BIGGER_THAN_MAX_LOAN_SIZE_STABLE = "14"; // 'The requested amount is greater than the max loan size in stable rate mode
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "15"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_EXPLICIT_AMOUNT_TO_REPAY_ON_BEHALF = "16"; // 'To repay on behalf of an user an explicit amount to repay is needed'
    string public constant VL_NO_STABLE_RATE_LOAN_IN_RESERVE = "17"; // 'User does not have a stable rate loan in progress on this reserve'
    string public constant VL_NO_VARIABLE_RATE_LOAN_IN_RESERVE = "18"; // 'User does not have a variable rate loan in progress on this reserve'
    string public constant VL_UNDERLYING_BALANCE_NOT_GREATER_THAN_0 = "19"; // 'The underlying balance needs to be greater than 0'
    string public constant VL_DEPOSIT_ALREADY_IN_USE = "20"; // 'User deposit is already being used as collateral'
    string public constant LP_NOT_ENOUGH_STABLE_BORROW_BALANCE = "21"; // 'User does not have any stable rate loan for this reserve'
    string public constant LP_INTEREST_RATE_REBALANCE_CONDITIONS_NOT_MET = "22"; // 'Interest rate rebalance conditions were not met'
    string public constant LP_LIQUIDATION_CALL_FAILED = "23"; // 'Liquidation call failed'
    string public constant LP_NOT_ENOUGH_LIQUIDITY_TO_BORROW = "24"; // 'There is not enough liquidity available to borrow'
    string public constant LP_REQUESTED_AMOUNT_TOO_SMALL = "25"; // 'The requested amount is too small for a FlashLoan.'
    string public constant LP_INCONSISTENT_PROTOCOL_ACTUAL_BALANCE = "26"; // 'The actual balance of the protocol is inconsistent'
    string public constant LP_CALLER_NOT_LENDING_POOL_CONFIGURATOR = "27"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_INCONSISTENT_FLASHLOAN_PARAMS = "28";
    string public constant CT_CALLER_MUST_BE_LENDING_POOL = "29"; // 'The caller of this function must be a lending pool'
    string public constant CT_CANNOT_GIVE_ALLOWANCE_TO_HIMSELF = "30"; // 'User cannot give allowance to himself'
    string public constant CT_TRANSFER_AMOUNT_NOT_GT_0 = "31"; // 'Transferred amount needs to be greater than zero'
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "32"; // 'Reserve has already been initialized'
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "34"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ATOKEN_POOL_ADDRESS = "35"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_POOL_ADDRESS = "36"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_POOL_ADDRESS = "37"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_STABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "38"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_VARIABLE_DEBT_TOKEN_UNDERLYING_ADDRESS = "39"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_ADDRESSES_PROVIDER_ID = "40"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "75"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "76"; // 'The caller must be the emergency admin'
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "41"; // 'Provider is not registered'
    string public constant LPCM_HEALTH_FACTOR_NOT_BELOW_THRESHOLD = "42"; // 'Health factor is not below the threshold'
    string public constant LPCM_COLLATERAL_CANNOT_BE_LIQUIDATED = "43"; // 'The collateral chosen cannot be liquidated'
    string public constant LPCM_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "44"; // 'User did not borrow the specified currency'
    string public constant LPCM_NOT_ENOUGH_LIQUIDITY_TO_LIQUIDATE = "45"; // "There isn't enough liquidity available to liquidate"
    string public constant LPCM_NO_ERRORS = "46"; // 'No errors'
    string public constant LP_INVALID_FLASHLOAN_MODE = "47"; //Invalid flashloan mode selected
    string public constant MATH_MULTIPLICATION_OVERFLOW = "48";
    string public constant MATH_ADDITION_OVERFLOW = "49";
    string public constant MATH_DIVISION_BY_ZERO = "50";
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "51"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "52"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "53"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "54"; //  Variable borrow rate overflows uint128
    string public constant RL_STABLE_BORROW_RATE_OVERFLOW = "55"; //  Stable borrow rate overflows uint128
    string public constant CT_INVALID_MINT_AMOUNT = "56"; //invalid amount to mint
    string public constant LP_FAILED_REPAY_WITH_COLLATERAL = "57";
    string public constant CT_INVALID_BURN_AMOUNT = "58"; //invalid amount to burn
    string public constant LP_FAILED_COLLATERAL_SWAP = "60";
    string public constant LP_INVALID_EQUAL_ASSETS_TO_SWAP = "61";
    string public constant LP_REENTRANCY_NOT_ALLOWED = "62";
    string public constant LP_CALLER_MUST_BE_AN_ATOKEN = "63";
    string public constant LP_IS_PAUSED = "64"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "65";
    string public constant LP_INVALID_FLASH_LOAN_EXECUTOR_RETURN = "66";
    string public constant RC_INVALID_LTV = "67";
    string public constant RC_INVALID_LIQ_THRESHOLD = "68";
    string public constant RC_INVALID_LIQ_BONUS = "69";
    string public constant RC_INVALID_DECIMALS = "70";
    string public constant RC_INVALID_RESERVE_FACTOR = "71";
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "72";
    string public constant VL_INCONSISTENT_FLASHLOAN_PARAMS = "73";
    string public constant LP_INCONSISTENT_PARAMS_LENGTH = "74";
    string public constant UL_INVALID_INDEX = "77";
    string public constant LP_NOT_CONTRACT = "78";
    string public constant SDT_STABLE_DEBT_OVERFLOW = "79";
    string public constant SDT_BURN_EXCEEDS_BALANCE = "80";

    enum CollateralManagerErrors {
        NO_ERROR,
        NO_COLLATERAL_AVAILABLE,
        COLLATERAL_CANNOT_BE_LIQUIDATED,
        CURRRENCY_NOT_BORROWED,
        HEALTH_FACTOR_ABOVE_THRESHOLD,
        NOT_ENOUGH_LIQUIDITY,
        NO_ACTIVE_RESERVE,
        HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD,
        INVALID_EQUAL_ASSETS_TO_SWAP,
        FROZEN_RESERVE
    }
}