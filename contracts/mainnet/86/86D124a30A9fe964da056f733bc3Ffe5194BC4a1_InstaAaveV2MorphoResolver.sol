// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Morpho-Aave Resolver
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
        uint256 length = userMarkets.length;
        address[] memory _tokens = new address[](length);
        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = userMarkets[i] == getEthAddr() ? getAWethAddr() : userMarkets[i];
        }
        positionData_ = getUserData(user, _tokens);
    }

    /**
     *@dev get Morpho markets config for protocols supported and claim rewards flag.
     *@notice get Morpho markets config for protocols supported and claim rewards flag.
     *@return morphoData_ Struct containing supported protocols' details: markets created,rewards flags.
     */
    function getMorphoConfig(address[] calldata aTokenArray) public view returns (MorphoData memory morphoData_) {
        morphoData_ = getMorphoData(aTokenArray);
    }
}

contract InstaAaveV2MorphoResolver is MorphoResolver {
    string public constant name = "Morpho-Aave-Resolver-v1.1";
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

interface IAaveLens {
    function MAX_BASIS_POINTS() external view returns (uint256);

    function WAD() external view returns (uint256);

    function morpho() external view returns (IMorpho);

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

    function getIndexes(address _poolToken)
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
            bool isP2PDisabled,
            bool isPaused,
            bool isPartiallyPaused,
            uint16 reserveFactor,
            uint16 p2pIndexCursor,
            uint256 loanToValue,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 decimals
        );

    function getRatesPerYear(address _poolToken)
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
            uint32 lastUpdateTimestamp,
            uint256 p2pSupplyDelta,
            uint256 p2pBorrowDelta
        );

    function getCurrentSupplyBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnP2P,
            uint256 balanceInPool,
            uint256 totalBalance
        );

    function getCurrentBorrowBalanceInOf(address _poolToken, address _user)
        external
        view
        returns (
            uint256 balanceOnP2P,
            uint256 balanceInPool,
            uint256 totalBalance
        );

    function getUserBalanceStates(address _user)
        external
        view
        returns (
            uint256 collateralValue,
            uint256 maxDebtValue,
            uint256 liquidationThreshold,
            uint256 debtValue
        );

    function isLiquidatable(address _user) external view returns (bool);

    function getCurrentUserSupplyRatePerYear(address _poolToken, address _user) external view returns (uint256);

    function getCurrentUserBorrowRatePerYear(address _poolToken, address _user) external view returns (uint256);

    function getUserHealthFactor(address _user) external view returns (uint256);
}

interface IAave {
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt,
            uint256 liquidityRate,
            uint256 variableBorrowRate,
            uint256 stableBorrowRate,
            uint256 averageStableBorrowRate,
            uint256 liquidityIndex,
            uint256 variableBorrowIndex,
            uint40 lastUpdateTimestamp
        );

    function getAssetData(address asset)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );

    function getReserveConfigurationData(address asset)
        external
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 liquidationThreshold,
            uint256 liquidationBonus,
            uint256 reserveFactor,
            bool usageAsCollateralEnabled,
            bool borrowingEnabled,
            bool stableBorrowRateEnabled,
            bool isActive,
            bool isFrozen
        );
}

interface AaveAddressProvider {
    function getLendingPool() external view returns (address);

    function getPriceOracle() external view returns (address);
}

interface AavePriceOracle {
    function getAssetPrice(address _asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata _assets) external view returns (uint256[] memory);

    function getSourceOfAsset(address _asset) external view returns (uint256);

    function getFallbackOracle() external view returns (uint256);
}

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint256);
}

interface IAToken {
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../../utils/dsmath.sol";

contract MorphoHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getAWethAddr() internal pure returns (address) {
        return 0x030bA81f1c18d280636F32af80b9AAd02Cf0854e;
    }

    function getChainlinkEthFeed() internal pure returns (address) {
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getAaveProtocolDataProvider() internal pure returns (address) {
        return 0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d;
    }

    function getAaveIncentivesController() internal pure returns (address) {
        return 0xd784927Ff2f95ba542BfC824c8a8a98F3495f6b5;
    }

    struct MorphoData {
        MarketDetail[] aaveMarketsCreated;
        bool isClaimRewardsPausedAave;
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
        uint256 tokenPriceInEth;
        uint256 tokenPriceInUsd;
    }

    struct AaveMarketDetail {
        uint256 aEmissionPerSecond;
        uint256 sEmissionPerSecond;
        uint256 vEmissionPerSecond;
        uint256 availableLiquidity;
        uint256 liquidityRate;
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 totalSupplies;
        uint256 totalStableBorrows;
        uint256 totalVariableBorrows;
    }

    struct MarketDetail {
        TokenConfig config;
        uint256 avgSupplyRatePerYear; //in wad
        uint256 avgBorrowRatePerYear; //in wad
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
        uint256 lastUpdateTimestamp;
        uint256 p2pSupplyDelta; //The total amount of underlying ERC20 tokens supplied through Morpho,
        //stored as matched peer-to-peer but supplied on the underlying pool
        uint256 p2pBorrowDelta; //The total amount of underlying ERC20 tokens borrow through Morpho,
        //stored as matched peer-to-peer but borrowed from the underlying pool
        uint256 reserveFactor;
        uint256 p2pIndexCursor; //p2p rate position b/w supply and borrow rate, in bps,
        // 0% = supply rate, 100% = borrow rate
        AaveMarketDetail aaveData;
        Flags flags;
    }

    struct Flags {
        bool isCreated;
        bool isPaused;
        bool isPartiallyPaused;
        bool isP2PDisabled;
        bool isUnderlyingBorrowEnabled;
    }

    struct UserMarketData {
        MarketDetail marketData;
        uint256 borrowRatePerYear;
        uint256 supplyRatePerYear;
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
        uint256 healthFactor; //calculated by updating interest accrue indices for all markets
        uint256 collateralValue; //calculated by updating interest accrue indices for all markets
        uint256 debtValue; //calculated by updating interest accrue indices for all markets
        uint256 maxDebtValue; //calculated by updating interest accrue indices for all markets
        bool isLiquidatable;
        uint256 liquidationThreshold;
        UserMarketData[] marketData;
        uint256 ethPriceInUsd;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    IAaveLens internal aavelens = IAaveLens(0x507fA343d0A90786d86C7cd885f5C49263A91FF4);
    IMorpho internal aaveMorpho = IMorpho(0x777777c9898D384F785Ee44Acfe945efDFf5f3E0);
    AaveAddressProvider addrProvider = AaveAddressProvider(0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5);
    IAave internal protocolData = IAave(getAaveProtocolDataProvider());
    IAave internal incentiveData = IAave(getAaveIncentivesController());

    function getTokensPrices(AaveAddressProvider aaveAddressProvider, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = AavePriceOracle(aaveAddressProvider.getPriceOracle()).getAssetsPrices(tokens);
        ethPrice = uint256(ChainLinkInterface(getChainlinkEthFeed()).latestAnswer());
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(_tokenPrices[i], wmul(_tokenPrices[i], uint256(ethPrice) * 10**10));
        }
    }

    function getLiquidatyData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        address asset
    ) internal view returns (MarketDetail memory) {
        (
            ,
            ,
            ,
            ,
            ,
            marketData_.reserveFactor,
            marketData_.p2pIndexCursor,
            marketData_.aaveData.ltv,
            marketData_.aaveData.liquidationThreshold,
            marketData_.aaveData.liquidationBonus,

        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        (, address sToken_, address vToken_) = protocolData.getReserveTokensAddresses(asset);

        (, marketData_.aaveData.aEmissionPerSecond, ) = incentiveData.getAssetData(asset);
        (, marketData_.aaveData.sEmissionPerSecond, ) = incentiveData.getAssetData(sToken_);
        (, marketData_.aaveData.vEmissionPerSecond, ) = incentiveData.getAssetData(vToken_);
        (
            marketData_.aaveData.availableLiquidity,
            marketData_.aaveData.totalStableBorrows,
            marketData_.aaveData.totalVariableBorrows,
            marketData_.aaveData.liquidityRate,
            ,
            ,
            ,
            ,
            ,

        ) = protocolData.getReserveData(asset);
        return marketData_;
    }

    function getAaveHelperData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        address token_
    ) internal view returns (MarketDetail memory) {
        (, , , , , , marketData_.flags.isUnderlyingBorrowEnabled, , , ) = protocolData.getReserveConfigurationData(
            token_
        );
        marketData_.aaveData.totalSupplies = IAToken(poolTokenAddress_).totalSupply();
        return marketData_;
    }

    function getAaveMarketData(
        MarketDetail memory marketData_,
        address poolTokenAddress_,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory) {
        marketData_.config.poolTokenAddress = poolTokenAddress_;
        marketData_.config.tokenPriceInEth = priceInEth;
        marketData_.config.tokenPriceInUsd = priceInUsd;
        (
            marketData_.config.underlyingToken,
            marketData_.flags.isCreated,
            marketData_.flags.isP2PDisabled,
            marketData_.flags.isPaused,
            marketData_.flags.isPartiallyPaused,
            ,
            ,
            ,
            ,
            ,
            marketData_.config.decimals
        ) = aavelens.getMarketConfiguration(poolTokenAddress_);

        marketData_ = getLiquidatyData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);
        marketData_ = getAaveHelperData(marketData_, poolTokenAddress_, marketData_.config.underlyingToken);

        return marketData_;
    }

    function getMarketData(
        address poolTokenAddress,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (MarketDetail memory marketData_) {
        marketData_ = getAaveMarketData(marketData_, poolTokenAddress, priceInEth, priceInUsd);

        (
            marketData_.avgSupplyRatePerYear,
            marketData_.avgBorrowRatePerYear,
            marketData_.totalP2PSupply,
            marketData_.totalP2PBorrows,
            marketData_.totalPoolSupply,
            marketData_.totalPoolBorrows
        ) = aavelens.getMainMarketData(poolTokenAddress);

        (
            marketData_.p2pSupplyRate,
            marketData_.p2pBorrowRate,
            marketData_.poolSupplyRate,
            marketData_.poolBorrowRate
        ) = aavelens.getRatesPerYear(poolTokenAddress);

        (
            marketData_.p2pSupplyIndex,
            marketData_.p2pBorrowIndex,
            marketData_.poolSupplyIndex,
            marketData_.poolBorrowIndex,
            marketData_.lastUpdateTimestamp,
            marketData_.p2pSupplyDelta,
            marketData_.p2pBorrowDelta
        ) = aavelens.getAdvancedMarketData(poolTokenAddress);

        // (
        //     marketData_.updatedP2PSupplyIndex,
        //     marketData_.updatedP2PBorrowIndex,
        //     marketData_.updatedPoolSupplyIndex,
        //     marketData_.updatedPoolBorrowIndex
        // ) = aavelens.getIndexes(poolTokenAddress);
    }

    function getUserMarketData(
        address user,
        address poolTokenAddress,
        uint256 priceInEth,
        uint256 priceInUsd
    ) internal view returns (UserMarketData memory userMarketData_) {
        userMarketData_.marketData = getMarketData(poolTokenAddress, priceInEth, priceInUsd);
        (userMarketData_.p2pBorrows, userMarketData_.poolBorrows, userMarketData_.totalBorrows) = aavelens
            .getCurrentBorrowBalanceInOf(poolTokenAddress, user);
        (userMarketData_.p2pSupplies, userMarketData_.poolSupplies, userMarketData_.totalSupplies) = aavelens
            .getCurrentSupplyBalanceInOf(poolTokenAddress, user);
        userMarketData_.borrowRatePerYear = aavelens.getCurrentUserBorrowRatePerYear(poolTokenAddress, user);
        userMarketData_.supplyRatePerYear = aavelens.getCurrentUserSupplyRatePerYear(poolTokenAddress, user);

        (userMarketData_.maxWithdrawable, userMarketData_.maxBorrowable) = aavelens.getUserMaxCapacitiesForAsset(
            user,
            poolTokenAddress
        );
    }

    function getUserMarkets(address user) internal view returns (address[] memory userMarkets_) {
        userMarkets_ = aavelens.getEnteredMarkets(user);
    }

    function getUserData(address user, address[] memory poolTokenAddresses)
        internal
        view
        returns (UserData memory userData_)
    {
        uint256 length_ = poolTokenAddresses.length;
        address[] memory tokens_ = getUnderlyingAssets(poolTokenAddresses);

        UserMarketData[] memory marketData_ = new UserMarketData[](length_);
        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            marketData_[i] = getUserMarketData(
                user,
                poolTokenAddresses[i],
                tokenPrices[i].priceInEth,
                tokenPrices[i].priceInUsd
            );
        }

        userData_.marketData = marketData_;
        // uint256 unclaimedRewards;

        userData_.healthFactor = aavelens.getUserHealthFactor(user);
        (
            userData_.collateralValue,
            userData_.maxDebtValue,
            userData_.liquidationThreshold,
            userData_.debtValue
        ) = aavelens.getUserBalanceStates(user);
        userData_.isLiquidatable = aavelens.isLiquidatable(user);
        userData_.ethPriceInUsd = ethPrice;
    }

    function getUnderlyingAssets(address[] memory atokens_) internal view returns (address[] memory tokens_) {
        uint256 length_ = atokens_.length;
        tokens_ = new address[](length_);

        for (uint256 i = 0; i < length_; i++) {
            tokens_[i] = IAToken(atokens_[i]).UNDERLYING_ASSET_ADDRESS();
        }
    }

    function getMorphoData(address[] calldata aTokenArray) internal view returns (MorphoData memory morphoData_) {
        // address[] memory aaveMarkets_ = aavelens.getAllMarkets();
        address[] memory aaveMarkets_ = aTokenArray;
        address[] memory tokens_ = getUnderlyingAssets(aaveMarkets_);

        MarketDetail[] memory aaveMarket_ = new MarketDetail[](aaveMarkets_.length);
        uint256 length_ = aaveMarkets_.length;

        (TokenPrice[] memory tokenPrices, uint256 ethPrice) = getTokensPrices(addrProvider, tokens_);

        for (uint256 i = 0; i < length_; i++) {
            aaveMarket_[i] = getMarketData(aaveMarkets_[i], tokenPrices[i].priceInEth, tokenPrices[i].priceInUsd);
        }

        morphoData_.aaveMarketsCreated = aaveMarket_;

        morphoData_.isClaimRewardsPausedAave = aaveMorpho.isClaimRewardsPaused();

        (morphoData_.p2pSupplyAmount, morphoData_.poolSupplyAmount, morphoData_.totalSupplyAmount) = aavelens
            .getTotalSupply();
        (morphoData_.p2pBorrowAmount, morphoData_.poolBorrowAmount, morphoData_.totalBorrowAmount) = aavelens
            .getTotalBorrow();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0;

contract DSMath {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "math-not-safe");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x - y <= x ? x - y : 0;
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "math-not-safe");
    }

    function div(uint256 x, uint256 y) internal pure returns (uint256 z) {
        if (y == 0) return type(uint256).max;
        z = x / y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    uint256 internal constant WAD = 10**18;
    uint256 internal constant RAY = 10**27;

    function rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
}