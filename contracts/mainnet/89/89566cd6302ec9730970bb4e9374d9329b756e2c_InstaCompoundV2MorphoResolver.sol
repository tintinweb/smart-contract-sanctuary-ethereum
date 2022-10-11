// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Morpho Resolver
 *@dev get user position details and market details.
 */
contract MorphoResolver is MorphoHelpers {
    /**
     *@dev get position of the user for all markets entered.
     *@notice get position details of the user in all entered market: overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@return positionData_ Overall position details of the user - balances, rewards, collaterals, market details.
     */
    function getPositionAll(address user) public view returns (UserData memory positionData_) {
        address[] memory userMarkets_ = getUserMarkets(user);
        positionData_ = getUserData(user, userMarkets_);
    }

    /**
     *@dev get position of the user for given markets.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param userMarkets Array of addresses of the markets for which user details are needed.
     *@return positionData_ Overall position details of the user - balances, rewards, collaterals and market details.
     */
    function getPosition(address user, address[] memory userMarkets)
        public
        view
        returns (UserData memory positionData_)
    {
        positionData_ = getUserData(user, userMarkets);
    }

    /**
     *@dev get Morpho markets config for protocols supported and claim rewards flag.
     *@notice get Morpho markets config for protocols supported and claim rewards flag.
     *@return morphoData_ Struct containing supported protocols' details: markets created,rewards flags.
     */
    function getMorphoConfig() public view returns (MorphoData memory morphoData_) {
        morphoData_ = getMorphoData();
    }
}

contract InstaCompoundV2MorphoResolver is MorphoResolver {
    string public constant name = "Morpho-Compound-Resolver-v1.0";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

// Max gas to consume during the matching process for supply, borrow, withdraw and repay functions.
struct MaxGasForMatching {
    uint64 supply;
    uint64 borrow;
    uint64 withdraw;
    uint64 repay;
}

struct AssetLiquidityData {
    uint256 collateralValue; // The collateral value of the asset.
    uint256 maxDebtValue; // The maximum possible debt value of the asset.
    uint256 debtValue; // The debt value of the asset.
    uint256 underlyingPrice; // The price of the token.
    uint256 collateralFactor; // The liquidation threshold applied on this token.
}

interface TokenInterface {
    function decimals() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);
}

interface IComptroller {
    struct CompMarketState {
        /// @notice The market's last updated compBorrowIndex or compSupplyIndex
        uint224 index;
        /// @notice The block number the index was last updated at
        uint32 block;
    }

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

    function checkMembership(address, address) external view returns (bool);

    function claimComp(address holder) external;

    function claimComp(address holder, address[] memory cTokens) external;

    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function compSupplyState(address) external view returns (CompMarketState memory);

    function compBorrowState(address) external view returns (CompMarketState memory);
}

interface ICompoundOracle {
    function getUnderlyingPrice(address) external view returns (uint256);
}

interface IMorpho {
    function isClaimRewardsPaused() external view returns (bool);

    function defaultMaxGasForMatching() external view returns (MaxGasForMatching memory);

    function maxSortedUsers() external view returns (uint256);

    function dustThreshold() external view returns (uint256);

    function p2pDisabled(address) external view returns (bool);

    function p2pSupplyIndex(address) external view returns (uint256);

    function p2pBorrowIndex(address) external view returns (uint256);

    function getAllMarkets() external view returns (address[] memory marketsCreated_);
}

interface ICompoundLens {
    function MAX_BASIS_POINTS() external view returns (uint256);

    function WAD() external view returns (uint256);

    function morpho() external view returns (IMorpho);

    function comptroller() external view returns (IComptroller);

    function getTotalSupply()
        external
        view
        returns (
            uint256 p2pSupplyAmount,
            uint256 poolSupplyAmount,
            uint256 totalSupplyAmount
        );

    function getTotalBorrow()
        external
        view
        returns (
            uint256 p2pBorrowAmount,
            uint256 poolBorrowAmount,
            uint256 totalBorrowAmount
        );

    function isMarketCreated(address _poolToken) external view returns (bool);

    function isMarketCreatedAndNotPaused(address _poolToken) external view returns (bool);

    function isMarketCreatedAndNotPausedNorPartiallyPaused(address _poolToken) external view returns (bool);

    function getAllMarkets() external view returns (address[] memory marketsCreated_);

    function getMainMarketData(address _poolToken)
        external
        view
        returns (
            uint256 avgSupplyRatePerBlock,
            uint256 avgBorrowRatePerBlock,
            uint256 p2pSupplyAmount,
            uint256 p2pBorrowAmount,
            uint256 poolSupplyAmount,
            uint256 poolBorrowAmount
        );

    function getTotalMarketSupply(address _poolToken)
        external
        view
        returns (uint256 p2pSupplyAmount, uint256 poolSupplyAmount);

    function getTotalMarketBorrow(address _poolToken)
        external
        view
        returns (uint256 p2pBorrowAmount, uint256 poolBorrowAmount);

    function getCurrentP2PSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentP2PBorrowIndex(address _poolToken) external view returns (uint256);

    function getCurrentPoolIndexes(address _poolToken)
        external
        view
        returns (uint256 currentPoolSupplyIndex, uint256 currentPoolBorrowIndex);

    function getIndexes(address _poolToken, bool _computeUpdatedIndexes)
        external
        view
        returns (
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex
        );

    function getEnteredMarkets(address _user) external view returns (address[] memory enteredMarkets);

    function getUserMaxCapacitiesForAsset(address _user, address _poolToken)
        external
        view
        returns (uint256 withdrawable, uint256 borrowable);

    function getUserHypotheticalBalanceStates(
        address _user,
        address _poolToken,
        uint256 _withdrawnAmount,
        uint256 _borrowedAmount
    ) external view returns (uint256 debtValue, uint256 maxDebtValue);

    function getUserLiquidityDataForAsset(
        address _user,
        address _poolToken,
        bool _computeUpdatedIndexes,
        ICompoundOracle _oracle
    ) external view returns (AssetLiquidityData memory assetData);

    function computeLiquidationRepayAmount(
        address _user,
        address _poolTokenBorrowed,
        address _poolTokenCollateral,
        address[] calldata _updatedMarkets
    ) external view returns (uint256 toRepay);

    function getAverageSupplyRatePerBlock(address _poolToken) external view returns (uint256);

    function getAverageBorrowRatePerBlock(address _poolToken) external view returns (uint256);

    function getNextUserSupplyRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextSupplyRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getNextUserBorrowRatePerBlock(
        address _poolToken,
        address _user,
        uint256 _amount
    )
        external
        view
        returns (
            uint256 nextBorrowRatePerBlock,
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getMarketConfiguration(address _poolToken)
        external
        view
        returns (
            address underlying,
            bool isCreated,
            bool p2pDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 collateralFactor
        );

    function getRatesPerBlock(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyRate,
            uint256 p2pBorrowRate,
            uint256 poolSupplyRate,
            uint256 poolBorrowRate
        );

    function getAdvancedMarketData(address _poolToken)
        external
        view
        returns (
            uint256 p2pSupplyIndex,
            uint256 p2pBorrowIndex,
            uint256 poolSupplyIndex,
            uint256 poolBorrowIndex,
            uint32 lastUpdateBlockNumber,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        );

    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnPool,
            uint256 balanceInP2P,
            uint256 totalBalance
        );

    function getUserBalanceStates(address _user, address[] calldata _updatedMarkets)
        external
        view
        returns (
            uint256 collateralValue,
            uint256 debtValue,
            uint256 maxDebtValue
        );

    function getAccruedSupplierComp(
        address _supplier,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getAccruedBorrowerComp(
        address _borrower,
        address _poolToken,
        uint256 _balance
    ) external view returns (uint256);

    function getCurrentCompSupplyIndex(address _poolToken) external view returns (uint256);

    function getCurrentCompBorrowIndex(address _poolToken) external view returns (uint256);

    function getUserUnclaimedRewards(address[] calldata _poolTokens, address _user)
        external
        view
        returns (uint256 unclaimedRewards);

    function isLiquidatable(address _user, address[] memory _updatedMarkets) external view returns (bool);

    function getCurrentUserSupplyRatePerBlock(address _poolToken, address _user) external view returns (uint256);

    function getCurrentUserBorrowRatePerBlock(address _poolToken, address _user) external view returns (uint256);

    function getUserHealthFactor(address _user, address[] calldata _updatedMarkets) external view returns (uint256);
}

interface IComp {
    function compSpeeds(address) external view returns (uint256);

    function compSupplySpeeds(address) external view returns (uint256);

    function compBorrowSpeeds(address) external view returns (uint256);

    function borrowCaps(address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";

contract MorphoHelpers {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    struct MorphoData {
        MarketDetail[] compMarketsCreated;
        bool isClaimRewardsPausedComp;
        uint256 p2pSupplyAmount;
        uint256 p2pBorrowAmount;
        uint256 poolSupplyAmount;
        uint256 poolBorrowAmount;
        uint256 totalSupplyAmount;
        uint256 totalBorrowAmount;
    }

    struct TokenConfig {
        address poolTokenAddress;
        address underlyingToken;
        uint256 decimals;
    }

    struct CompoundMarketDetail {
        uint256 compSpeed;
        uint256 compSupplySpeed;
        uint256 compBorrowSpeed;
        uint256 collateralFactor;
        uint256 marketBorrowCap;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRatePerBlock; //in wad
        uint256 avgBorrowRatePerBlock; //in wad
        uint256 p2pSupplyRate;
        uint256 p2pBorrowRate;
        uint256 poolSupplyRate;
        uint256 poolBorrowRate;
        uint256 totalP2PSupply;
        uint256 totalPoolSupply;
        uint256 totalP2PBorrows;
        uint256 totalPoolBorrows;
        uint256 p2pSupplyIndex;
        uint256 p2pBorrowIndex;
        uint256 poolSupplyIndex; //exchange rate of cTokens for compound
        uint256 poolBorrowIndex;
        uint256 updatedP2PSupplyIndex;
        uint256 updatedP2PBorrowIndex;
        uint256 updatedPoolSupplyIndex; //exchange rate of cTokens for compound
        uint256 updatedPoolBorrowIndex;
        uint256 lastUpdateBlockNumber;
        uint256 p2pSupplyDelta; //The total amount of underlying ERC20 tokens supplied through Morpho,
        //stored as matched peer-to-peer but supplied on the underlying pool
        uint256 p2pBorrowDelta; //The total amount of underlying ERC20 tokens borrow through Morpho,
        //stored as matched peer-to-peer but borrowed from the underlying pool
        uint256 reserveFactor;
        uint256 p2pIndexCursor; //p2p rate position b/w supply and borrow rate, in bps,
        // 0% = supply rate, 100% = borrow rate
        CompoundMarketDetail compData;
        Flags flags;
    }

    struct Flags {
        bool isCreated;
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRatePerBlock;
        uint256 supplyRatePerBlock;
        uint256 totalSupplies;
        uint256 totalBorrows;
        uint256 p2pBorrows;
        uint256 p2pSupplies;
        uint256 poolBorrows;
        uint256 poolSupplies;
        uint256 maxWithdrawable;
        uint256 maxBorrowable;
    }

    struct UserData {
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets for comp
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets for comp
        uint256 debtValue; //calculated by updating interest accrue indices for all markets for comp
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets for comp
        bool isLiquidatable;
        uint256 unclaimedRewards; //only for compound as of now
        UserMarketData[] marketData;
    }

    ICompoundLens internal compLens = ICompoundLens(0x930f1b46e1D081Ec1524efD95752bE3eCe51EF67);
    IMorpho internal compMorpho = IMorpho(0x8888882f8f843896699869179fB6E4f7e3B58888);
    IComp internal comptroller = IComp(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);

    function getCompSpeeds(CompoundMarketDetail memory cf_, address poolTokenAddress_)
        internal
        view
        returns (CompoundMarketDetail memory)
    {
        cf_.compSpeed = comptroller.compSpeeds(poolTokenAddress_);
        cf_.compSupplySpeed = comptroller.compSupplySpeeds(poolTokenAddress_);
        cf_.compBorrowSpeed = comptroller.compBorrowSpeeds(poolTokenAddress_);
        return cf_;
    }

    function getCompMarketDataHelper(MarketDetail memory marketData_, address poolTokenAddress_)
        internal
        view
        returns (MarketDetail memory)
    {
        (
            ,
            ,
            ,
            ,
            ,
            marketData_.reserveFactor,
            marketData_.p2pIndexCursor,
            marketData_.compData.collateralFactor
        ) = compLens.getMarketConfiguration(poolTokenAddress_);
        return marketData_;
    }

    function getCompMarketData(MarketDetail memory marketData_, address poolTokenAddress_)
        internal
        view
        returns (MarketDetail memory)
    {
        TokenConfig memory tokenData_;
        CompoundMarketDetail memory cf_;
        Flags memory flags_;

        tokenData_.poolTokenAddress = poolTokenAddress_;
        tokenData_.decimals = TokenInterface(poolTokenAddress_).decimals();
        (
            tokenData_.underlyingToken,
            flags_.isCreated,
            flags_.isP2PDisabled,
            flags_.isPaused,
            flags_.isPartiallyPaused,
            ,
            ,

        ) = compLens.getMarketConfiguration(poolTokenAddress_);

        cf_.marketBorrowCap = comptroller.borrowCaps(poolTokenAddress_);

        cf_ = getCompSpeeds(cf_, poolTokenAddress_);

        marketData_.config = tokenData_;
        marketData_.compData = cf_;
        marketData_.flags = flags_;

        marketData_ = getCompMarketDataHelper(marketData_, poolTokenAddress_);

        return marketData_;
    }

    function getMarketData(address poolTokenAddress) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getCompMarketData(marketData_, poolTokenAddress);

        (
            marketData_.avgSupplyRatePerBlock,
            marketData_.avgBorrowRatePerBlock,
            marketData_.totalP2PSupply,
            marketData_.totalP2PBorrows,
            marketData_.totalPoolSupply,
            marketData_.totalPoolBorrows
        ) = compLens.getMainMarketData(poolTokenAddress);

        (
            marketData_.p2pSupplyRate,
            marketData_.p2pBorrowRate,
            marketData_.poolSupplyRate,
            marketData_.poolBorrowRate
        ) = compLens.getRatesPerBlock(poolTokenAddress);

        (
            marketData_.p2pSupplyIndex,
            marketData_.p2pBorrowIndex,
            marketData_.poolSupplyIndex,
            marketData_.poolBorrowIndex,
            marketData_.lastUpdateBlockNumber,
            marketData_.p2pSupplyDelta,
            marketData_.p2pBorrowDelta
        ) = compLens.getAdvancedMarketData(poolTokenAddress);

        (
            marketData_.updatedP2PSupplyIndex,
            marketData_.updatedP2PBorrowIndex,
            marketData_.updatedPoolSupplyIndex,
            marketData_.updatedPoolBorrowIndex
        ) = compLens.getIndexes(poolTokenAddress, true);
    }

    function getUserMarketData(address user, address poolTokenAddress)
        internal
        view
        returns (UserMarketData memory userMarketData_)
    {
        userMarketData_.marketData = getMarketData(poolTokenAddress);

        (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = compLens
            .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
        (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = compLens
            .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
        userMarketData_.borrowRatePerBlock = compLens.getCurrentUserBorrowRatePerBlock(poolTokenAddress, user);
        userMarketData_.supplyRatePerBlock = compLens.getCurrentUserSupplyRatePerBlock(poolTokenAddress, user);

        (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = compLens.getUserMaxCapacitiesForAsset(
            user,
            poolTokenAddress
        );
    }

    function getUserMarkets(address user) internal view returns (address[] memory userMarkets_) {
        userMarkets_ = compLens.getEnteredMarkets(user);
    }

    function getUserData(address user, address[] memory poolTokenAddresses)
        internal
        view
        returns (UserData memory userData_)
    {
        uint256 length_ = poolTokenAddresses.length;

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(user, poolTokenAddresses[i]);
        }

        userData_.marketData = marketData_;
        // uint256 unclaimedRewards;
        address[] memory userMarkets_ = getUserMarkets(user);

        userData_.healthFactor = compLens.getUserHealthFactor(user, userMarkets_);
        (userData_.collateralValue, userData_.debtValue, userData_.maxDebtValue) = compLens.getUserBalanceStates(
            user,
            userMarkets_
        );
        userData_.isLiquidatable = compLens.isLiquidatable(user, userMarkets_);
        userData_.unclaimedRewards = compLens.getUserUnclaimedRewards(userMarkets_, user);
    }

    function getMorphoData() internal view returns (MorphoData memory morphoData_) {
        address[] memory compMarkets_ = compLens.getAllMarkets();
        MarketDetail[] memory compMarket_ = new MarketDetail[](compMarkets_.length);
        uint256 length_ = compMarkets_.length;
        for (uint256 i = 0; i < length_; i++) {
            compMarket_[i] = getMarketData(compMarkets_[i]);
        }

        morphoData_.compMarketsCreated = compMarket_;
        morphoData_.isClaimRewardsPausedComp = compMorpho.isClaimRewardsPaused();
        (morphoData_.p2pSupplyAmount, morphoData_.poolSupplyAmount, morphoData_.totalSupplyAmount) = compLens
            .getTotalSupply();
        (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = compLens
            .getTotalBorrow();
    }
}