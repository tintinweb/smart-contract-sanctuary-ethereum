// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Aave v3 Resolver
 *@dev get user position, user configuration & reserves list.
 */
contract AaveV3Resolver is AaveV3Helper {
    /**
     *@dev get position of the user
     *@notice get position of user, including details of user's 
     overall position, rewards and assets owned for the tokens passed.
     *@param user The address of the user whose details are needed.
     *@param tokens Array of token addresses corresponding to which user details are needed.
     *@return AaveV3UserData user's overall position (e.g. total collateral, total borrows, e-mode id etc.).
     *@return AaveV3UserTokenData details of user's tokens for the tokens passed 
     (e.g. supplied amount, borrowed amount, supply rate etc.).
     *@return AaveV3TokenData details of tokens (e.g. symbol, decimals, ltv etc.).
     *@return ReserveIncentiveData details of user's rewards corresponding to the tokens passed.
     */
    function getPosition(address user, address[] memory tokens)
        public
        view
        returns (
            AaveV3UserData memory,
            AaveV3UserTokenData[] memory,
            AaveV3TokenData[] memory,
            ReserveIncentiveData[] memory
        )
    {
        uint256 length = tokens.length;
        address[] memory _tokens = new address[](length);

        for (uint256 i = 0; i < length; i++) {
            _tokens[i] = tokens[i] == getEthAddr() ? getWethAddr() : tokens[i];
        }

        AaveV3UserData memory userDetails = getUserData(user);

        AaveV3UserTokenData[] memory tokensData = new AaveV3UserTokenData[](length);
        AaveV3TokenData[] memory collData = new AaveV3TokenData[](length);

        for (uint256 i = 0; i < length; i++) {
            tokensData[i] = getUserTokenData(user, _tokens[i]);
            collData[i] = userCollateralData(_tokens[i]);
        }

        return (userDetails, tokensData, collData, getIncentivesInfo(user));
    }

    /**
     *@dev get position of the user for all tokens.
     *@notice get position of user, including details of user's 
     overall position, rewards and assets owned for all tokens available in market.
     *@param user The address of the user whose details are needed.
     *@return AaveV3UserData user's overall position (e.g. total collateral, total borrows, e-mode id etc.).
     *@return AaveV3UserTokenData user's details of tokens(e.g. supplied amount, borrowed amount, supply rate etc.).
     *@return AaveV3TokenData details of tokens (e.g. symbol, decimals, ltv etc.).
     *@return ReserveIncentiveData details of user's rewards corresponding to the tokens in the market.
     */
    function getPositionAll(address user)
        public
        view
        returns (
            AaveV3UserData memory,
            AaveV3UserTokenData[] memory,
            AaveV3TokenData[] memory,
            ReserveIncentiveData[] memory
        )
    {
        return getPosition(user, getList());
    }

    /**
     *@dev get user's configuration.
     *@notice get configuration of user, whether the token is used as collateral or borrowed or not.
     *@param user The address of the user whose configuration is needed.
     *@return collateral array with an element as true if 
     the corresponding token is used as collateral by the user, false otherwise.
     *@return borrowed array with an element as true if 
     the corresponding token is borrowed by the user, false otherwise.
     */
    function getConfiguration(address user) public view returns (bool[] memory collateral, bool[] memory borrowed) {
        uint256 data = getConfig(user).data;
        address[] memory reserveIndex = getList();

        collateral = new bool[](reserveIndex.length);
        borrowed = new bool[](reserveIndex.length);

        for (uint256 i = 0; i < reserveIndex.length; i++) {
            if (isUsingAsCollateralOrBorrowing(data, i)) {
                collateral[i] = (isUsingAsCollateral(data, i)) ? true : false;
                borrowed[i] = (isBorrowing(data, i)) ? true : false;
            }
        }
    }

    /**
     *@dev get reserves list.
     *@notice get list of all tokens available in the market.
     *@return data array of token addresses available in the market.
     */
    function getReservesList() public view returns (address[] memory data) {
        data = getList();
    }
}

contract InstaAaveV3Resolver is AaveV3Resolver {
    string public constant name = "AaveV3-Resolver-v1.0";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex; //ray
    uint128 currentLiquidityRate; //ray
    uint128 variableBorrowIndex; //ray
    uint128 currentVariableBorrowRate; //ray
    uint128 currentStableBorrowRate; //ray
    uint40 lastUpdateTimestamp;
    uint16 id;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
}
struct UserConfigurationMap {
    uint256 data;
}

struct EModeCategory {
    // each eMode category has a custom ltv and liquidation threshold
    uint16 ltv;
    uint16 liquidationThreshold;
    uint16 liquidationBonus;
    // each eMode category may or may not have a custom oracle to override the individual assets price oracles
    address priceSource;
    string label;
}

struct ReserveConfigurationMap {
    uint256 data;
}

//IUiIncentives
struct AggregatedReserveIncentiveData {
    address underlyingAsset;
    IncentiveData aIncentiveData;
    IncentiveData vIncentiveData;
    IncentiveData sIncentiveData;
}

struct IncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    RewardInfo[] rewardsTokenInformation;
}

struct RewardInfo {
    string rewardTokenSymbol;
    address rewardTokenAddress;
    address rewardOracleAddress;
    uint256 emissionPerSecond;
    uint256 incentivesLastUpdateTimestamp;
    uint256 tokenIncentivesIndex;
    uint256 emissionEndTimestamp;
    int256 rewardPriceFeed;
    uint8 rewardTokenDecimals;
    uint8 precision;
    uint8 priceFeedDecimals;
}

struct UserReserveIncentiveData {
    address underlyingAsset;
    UserIncentiveData aTokenIncentivesUserData;
    UserIncentiveData vTokenIncentivesUserData;
    UserIncentiveData sTokenIncentivesUserData;
}

struct UserIncentiveData {
    address tokenAddress;
    address incentiveControllerAddress;
    UserRewardInfo[] userRewardsInformation;
}

struct UserRewardInfo {
    string rewardTokenSymbol;
    address rewardOracleAddress;
    address rewardTokenAddress;
    uint256 userUnclaimedRewards;
    uint256 tokenIncentivesUserIndex;
    int256 rewardPriceFeed;
    uint8 priceFeedDecimals;
    uint8 rewardTokenDecimals;
}

//IUiDataProvider
struct BaseCurrencyInfo {
    uint256 marketReferenceCurrencyUnit;
    int256 marketReferenceCurrencyPriceInUsd;
    int256 networkBaseTokenPriceInUsd;
    uint8 networkBaseTokenPriceDecimals;
}

struct AggregatedReserveData {
    address underlyingAsset;
    string name;
    string symbol;
    uint256 decimals;
    uint256 baseLTVasCollateral;
    uint256 reserveLiquidationThreshold;
    uint256 reserveLiquidationBonus;
    uint256 reserveFactor;
    bool usageAsCollateralEnabled;
    bool borrowingEnabled;
    bool stableBorrowRateEnabled;
    bool isActive;
    bool isFrozen;
    // base data
    uint128 liquidityIndex;
    uint128 variableBorrowIndex;
    uint128 liquidityRate;
    uint128 variableBorrowRate;
    uint128 stableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    //
    uint256 availableLiquidity;
    uint256 totalPrincipalStableDebt;
    uint256 averageStableRate;
    uint256 stableDebtLastUpdateTimestamp;
    uint256 totalScaledVariableDebt;
    uint256 priceInMarketReferenceCurrency;
    address priceOracle;
    uint256 variableRateSlope1;
    uint256 variableRateSlope2;
    uint256 stableRateSlope1;
    uint256 stableRateSlope2;
    uint256 baseStableBorrowRate;
    uint256 baseVariableBorrowRate;
    uint256 optimalUsageRatio;
    // v3 only
    bool isPaused;
    bool isSiloedBorrowing;
    uint128 accruedToTreasury;
    uint128 unbacked;
    uint128 isolationModeTotalDebt;
    bool flashLoanEnabled;
    //
    uint256 debtCeiling;
    uint256 debtCeilingDecimals;
    uint8 eModeCategoryId;
    uint256 borrowCap;
    uint256 supplyCap;
    // eMode
    uint16 eModeLtv;
    uint16 eModeLiquidationThreshold;
    uint16 eModeLiquidationBonus;
    address eModePriceSource;
    string eModeLabel;
    bool borrowableInIsolation;
}

interface IPool {
    function getUserAccountData(address user)
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        );

    function getEModeCategoryData(uint8 id) external view returns (EModeCategory memory);

    //@return emode id of the user
    function getUserEMode(address user) external view returns (uint256);

    function getReservesList() external view virtual returns (address[] memory);

    function getUserConfiguration(address user) external view returns (UserConfigurationMap memory);

    function getReserveData(address asset) external view returns (ReserveData memory);
}

interface IPriceOracleGetter {
    // @notice Returns the base currency address
    // @dev Address 0x0 is reserved for USD as base currency.
    function BASE_CURRENCY() external view returns (address);

    // @notice Returns the base currency unit
    // @dev 1 ether for ETH, 1e8 for USD.
    function BASE_CURRENCY_UNIT() external view returns (uint256);

    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);
}

interface IAaveIncentivesController {
    //@notice returns total(accrued+non-accrued) rewards of user for given assets
    function getRewardsBalance(address[] calldata assets, address user) external view returns (uint256);

    //@notice Returns the unclaimed rewards of the user
    function getUserUnclaimedRewards(address user) external view returns (uint256);

    // @notice Returns the user index for a specific asset
    function getUserAssetData(address user, address asset) external view returns (uint256);

    // @dev Returns the configuration of the distribution for a certain asset
    // @return The asset index, the emission per second and the last updated timestamp
    function assets(address asset)
        external
        view
        returns (
            uint128,
            uint128,
            uint256
        );
}

interface IAaveOracle is IPriceOracleGetter {
    // @notice Returns a list of prices from a list of assets addresses
    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);

    // @notice Returns the address of the source for an asset address
    function getSourceOfAsset(address asset) external view returns (address);

    // @notice Returns the address of the fallback oracle
    function getFallbackOracle() external view returns (address);
}

interface IPoolAddressesProvider {
    // @notice Returns the address of the Pool proxy.
    function getPool() external view returns (address);

    // @notice Returns the address of the price oracle.
    function getPriceOracle() external view returns (address);

    // @notice Returns the address of the data provider.
    function getPoolDataProvider() external view returns (address);
}

interface IPoolDataProvider {
    // @notice Returns the reserve data
    function getReserveData(address asset)
        external
        view
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
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
}

interface IPriceOracle {
    // @notice Returns the asset price in the base currency
    function getAssetPrice(address asset) external view returns (uint256);

    function getAssetsPrices(address[] calldata assets) external view returns (uint256[] memory);
}

interface IStableDebtToken {
    // @notice Returns the stable rate of the user debt
    function getUserStableRate(address user) external view returns (uint256);
}

interface IAaveProtocolDataProvider is IPoolDataProvider {
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

    function getPaused(address asset) external view returns (bool isPaused);

    /*
     * @notice Returns whether the reserve has FlashLoans enabled or disabled
     * @param asset The address of the underlying asset of the reserve
     * @return True if FlashLoans are enabled, false otherwise
     */
    function getFlashLoanEnabled(address asset) external view returns (bool);

    function getLiquidationProtocolFee(address asset) external view returns (uint256);

    function getReserveEModeCategory(address asset) external view returns (uint256);

    function getReserveCaps(address asset) external view returns (uint256 borrowCap, uint256 supplyCap);

    // @notice Returns the debt ceiling of the reserve
    function getDebtCeiling(address asset) external view returns (uint256);

    // @notice Returns the debt ceiling decimals
    function getDebtCeilingDecimals() external pure returns (uint256);

    function getATokenTotalSupply(address asset) external view returns (uint256);

    function getReserveData(address asset)
        external
        view
        override
        returns (
            uint256 unbacked,
            uint256 accruedToTreasuryScaled,
            uint256 totalAToken,
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

    function getUserReserveData(address asset, address user)
        external
        view
        returns (
            uint256 currentATokenBalance,
            uint256 currentStableDebt,
            uint256 currentVariableDebt,
            uint256 principalStableDebt,
            uint256 scaledVariableDebt,
            uint256 stableBorrowRate,
            uint256 liquidityRate,
            uint40 stableRateLastUpdated,
            bool usageAsCollateralEnabled
        );

    function getReserveTokensAddresses(address asset)
        external
        view
        returns (
            address aTokenAddress,
            address stableDebtTokenAddress,
            address variableDebtTokenAddress
        );
}

//chainlink price feed
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

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

    function latestAnswer() external view returns (int256);
}

interface IERC20Detailed {
    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface IUiIncentiveDataProviderV3 {
    function getReservesIncentivesData(IPoolAddressesProvider provider)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory);

    function getUserReservesIncentivesData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (UserReserveIncentiveData[] memory);

    // generic method with full data
    function getFullReservesIncentiveData(IPoolAddressesProvider provider, address user)
        external
        view
        returns (AggregatedReserveIncentiveData[] memory, UserReserveIncentiveData[] memory);
}

interface IRewardsDistributor {
    function getUserAssetData(
        address user,
        address asset,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns the configuration of the distribution for a certain asset
     * @param asset The incentivized asset
     * @param reward The reward token of the incentivized asset
     * @return The asset index, the emission per second, the last updated timestamp and the distribution end timestamp
     **/
    function getRewardsData(address asset, address reward)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    /**
     * @dev Returns the list of available reward token addresses of an incentivized asset
     * @param asset The incentivized asset
     * @return List of rewards addresses of the input asset
     **/
    function getRewardsByAsset(address asset) external view returns (address[] memory);

    /**
     * @dev Returns the list of available reward addresses
     * @return List of rewards supported in this contract
     **/
    function getRewardsList() external view returns (address[] memory);

    /**
     * @dev Returns a single rewards balance of an user 
     from contract storage state, not including virtually accrued rewards since last distribution.
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return Unclaimed rewards, from storage
     **/
    function getUserUnclaimedRewardsFromStorage(address user, address reward) external view returns (uint256);

    /**
     * @dev Returns a single rewards balance of an user, including virtually accrued and unrealized claimable rewards.
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @param reward The address of the reward token
     * @return The rewards amount
     **/
    function getUserRewards(
        address[] calldata assets,
        address user,
        address reward
    ) external view returns (uint256);

    /**
     * @dev Returns a list all rewards of an user, including already accrued and unrealized claimable rewards
     * @param assets List of incentivized assets to check eligible distributions
     * @param user The address of the user
     * @return The function returns a Tuple of rewards list and the unclaimed rewards list
     **/
    function getAllUserRewards(address[] calldata assets, address user)
        external
        view
        returns (address[] memory, uint256[] memory);

    /**
     * @dev Returns the decimals of an asset to calculate the distribution delta
     * @param asset The address to retrieve decimals saved at storage
     * @return The decimals of an underlying asset
     */
    function getAssetDecimals(address asset) external view returns (uint8);
}

interface IRewardsController is IRewardsDistributor {
    function getRewardOracle(address reward) external view returns (address);

    /**
     * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
     * @param user The address of the user
     * @return The claimer address
     */
    function getClaimer(address user) external view returns (address);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract AaveV3Helper is DSMath {
    // ----------------------- USING LATEST ADDRESSES -----------------------------

    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    /**
     *@dev Returns WETH address
     */
    function getWethAddr() internal pure returns (address) {
        return 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; //Mainnet WEth Address
    }

    /**
     *@dev Returns Pool AddressProvider Address
     */
    function getPoolAddressProvider() internal pure returns (address) {
        return 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e; //Mainnet PoolAddressesProvider address
    }

    /**
     *@dev Returns Pool DataProvider Address
     */
    function getPoolDataProvider() internal pure returns (address) {
        return 0x7B4EB56E7CD4b454BA8ff71E4518426369a138a3; //Mainnet PoolDataProvider address
    }

    /**
     *@dev Returns AaveOracle Address
     */
    function getAaveOracle() internal pure returns (address) {
        return 0x54586bE62E3c3580375aE3723C145253060Ca0C2; //Mainnet address
    }

    function getChainLinkFeed() internal pure returns (address) {
        //todo: confirm
        return 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;
    }

    function getUiIncetivesProvider() internal pure returns (address) {
        return 0x162A7AC02f547ad796CA549f757e2b8d1D9b10a6;
    }

    function getRewardsController() internal pure returns (address) {
        return 0x8164Cc65827dcFe994AB23944CBC90e0aa80bFcb;
    }

    struct BaseCurrency {
        uint256 baseUnit;
        address baseAddress;
        string symbol;
    }

    struct Token {
        address tokenAddress;
        string symbol;
        uint256 decimals;
    }

    struct ReserveAddresses {
        Token aToken;
        Token stableDebtToken;
        Token variableDebtToken;
    }

    struct EmodeData {
        EModeCategory data;
    }

    struct AaveV3UserTokenData {
        uint256 supplyBalance;
        uint256 stableBorrowBalance;
        uint256 variableBorrowBalance;
        uint256 supplyRate;
        uint256 stableBorrowRate;
        uint256 userStableBorrowRate;
        uint256 variableBorrowRate;
        bool isCollateral;
        uint256 price; //price of token in base currency
        Flags flag;
    }

    struct AaveV3UserData {
        uint256 totalCollateralBase;
        uint256 totalBorrowsBase;
        uint256 availableBorrowsBase;
        uint256 currentLiquidationThreshold;
        uint256 ltv;
        uint256 healthFactor;
        uint256 eModeId;
        BaseCurrency base;
    }

    struct AaveV3TokenData {
        address asset;
        string symbol;
        uint256 decimals;
        uint256 ltv;
        uint256 threshold;
        uint256 reserveFactor;
        uint256 totalSupply;
        uint256 availableLiquidity;
        uint256 totalStableDebt;
        uint256 totalVariableDebt;
        ReserveAddresses reserves;
        AaveV3Token token;
    }

    struct Flags {
        bool usageAsCollateralEnabled;
        bool borrowEnabled;
        bool stableBorrowEnabled;
        bool isActive;
        bool isFrozen;
    }

    struct AaveV3Token {
        uint256 supplyCap;
        uint256 borrowCap;
        uint256 eModeCategory;
        uint256 debtCeiling;
        uint256 debtCeilingDecimals;
        uint256 liquidationFee;
        bool isolationBorrowEnabled;
        bool isPaused;
        bool flashLoanEnabled;
    }

    struct TokenPrice {
        uint256 priceInEth;
        uint256 priceInUsd;
    }

    //Rewards details
    struct ReserveIncentiveData {
        address underlyingAsset;
        IncentivesData aIncentiveData;
        IncentivesData vIncentiveData;
        IncentivesData sIncentiveData;
    }

    struct IncentivesData {
        address token;
        RewardsInfo[] rewardsTokenInfo;
        UserRewards userRewards;
    }

    struct UserRewards {
        address[] rewardsToken;
        uint256[] unbalancedAmounts;
    }

    struct RewardsInfo {
        string rewardTokenSymbol;
        address rewardTokenAddress;
        uint256 emissionPerSecond;
        uint256 rewardTokenDecimals;
        uint256 precision;
    }

    IPoolAddressesProvider internal provider = IPoolAddressesProvider(getPoolAddressProvider());
    IAaveOracle internal aaveOracle = IAaveOracle(getAaveOracle());
    IAaveProtocolDataProvider internal aaveData = IAaveProtocolDataProvider(provider.getPoolDataProvider());
    IPool internal pool = IPool(provider.getPool());
    IUiIncentiveDataProviderV3 internal uiIncentives = IUiIncentiveDataProviderV3(getUiIncetivesProvider());
    IRewardsController internal rewardsCntr = IRewardsController(getRewardsController());

    function getUserReward(
        address user,
        address[] memory assets,
        RewardsInfo[] memory _rewards
    ) internal view returns (UserRewards memory unclaimedRewards) {
        if (_rewards.length > 0) {
            (address[] memory reserves, uint256[] memory rewards) = rewardsCntr.getAllUserRewards(assets, user);
            unclaimedRewards = UserRewards(reserves, rewards);
        }
    }

    function getIncentivesInfo(address user) internal view returns (ReserveIncentiveData[] memory incentives) {
        AggregatedReserveIncentiveData[] memory _aggregateIncentive = uiIncentives.getReservesIncentivesData(provider);
        incentives = new ReserveIncentiveData[](_aggregateIncentive.length);
        for (uint256 i = 0; i < _aggregateIncentive.length; i++) {
            address[] memory rToken = new address[](1);
            RewardsInfo[] memory _aRewards = getRewardInfo(
                _aggregateIncentive[i].aIncentiveData.rewardsTokenInformation
            );
            RewardsInfo[] memory _sRewards = getRewardInfo(
                _aggregateIncentive[i].sIncentiveData.rewardsTokenInformation
            );
            RewardsInfo[] memory _vRewards = getRewardInfo(
                _aggregateIncentive[i].vIncentiveData.rewardsTokenInformation
            );
            rToken[0] = _aggregateIncentive[i].aIncentiveData.tokenAddress;
            IncentivesData memory _aToken = IncentivesData(
                _aggregateIncentive[i].aIncentiveData.tokenAddress,
                _aRewards,
                getUserReward(user, rToken, _aRewards)
            );
            rToken[0] = _aggregateIncentive[i].sIncentiveData.tokenAddress;
            IncentivesData memory _sToken = IncentivesData(
                _aggregateIncentive[i].sIncentiveData.tokenAddress,
                _sRewards,
                getUserReward(user, rToken, _sRewards)
            );
            rToken[0] = _aggregateIncentive[i].vIncentiveData.tokenAddress;
            IncentivesData memory _vToken = IncentivesData(
                _aggregateIncentive[i].vIncentiveData.tokenAddress,
                _vRewards,
                getUserReward(user, rToken, _vRewards)
            );
            incentives[i] = ReserveIncentiveData(_aggregateIncentive[i].underlyingAsset, _aToken, _vToken, _sToken);
        }
    }

    function getRewardInfo(RewardInfo[] memory rewards) internal pure returns (RewardsInfo[] memory rewardData) {
        // console.log(rewards.length);
        rewardData = new RewardsInfo[](rewards.length);
        for (uint256 i = 0; i < rewards.length; i++) {
            rewardData[i] = RewardsInfo(
                rewards[i].rewardTokenSymbol,
                rewards[i].rewardTokenAddress,
                rewards[i].emissionPerSecond,
                uint256(rewards[i].rewardTokenDecimals),
                uint256(rewards[i].precision)
            );
        }
    }

    function getTokensPrices(uint256 basePriceInUSD, address[] memory tokens)
        internal
        view
        returns (TokenPrice[] memory tokenPrices, uint256 ethPrice)
    {
        uint256[] memory _tokenPrices = aaveOracle.getAssetsPrices(tokens);
        tokenPrices = new TokenPrice[](_tokenPrices.length);
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());

        for (uint256 i = 0; i < _tokenPrices.length; i++) {
            tokenPrices[i] = TokenPrice(
                (_tokenPrices[i] * basePriceInUSD * 10**10) / ethPrice,
                wmul(_tokenPrices[i] * 10**10, basePriceInUSD * 10**10)
            );
        }
    }

    function getEmodePrices(address priceOracleAddr, address[] memory tokens)
        internal
        view
        returns (uint256[] memory tokenPrices)
    {
        tokenPrices = IPriceOracle(priceOracleAddr).getAssetsPrices(tokens);
    }

    function getIsolationDebt(address token) internal view returns (uint256 isolationDebt) {
        isolationDebt = uint256(pool.getReserveData(token).isolationModeTotalDebt);
    }

    function getUserData(address user) internal view returns (AaveV3UserData memory userData) {
        (
            userData.totalCollateralBase,
            userData.totalBorrowsBase,
            userData.availableBorrowsBase,
            userData.currentLiquidationThreshold,
            userData.ltv,
            userData.healthFactor
        ) = pool.getUserAccountData(user);

        userData.base = getBaseCurrencyDetails();
        userData.eModeId = pool.getUserEMode(user);
    }

    function getFlags(address token) internal view returns (Flags memory flag) {
        (
            ,
            ,
            ,
            ,
            ,
            flag.usageAsCollateralEnabled,
            flag.borrowEnabled,
            flag.stableBorrowEnabled,
            flag.isActive,
            flag.isFrozen
        ) = aaveData.getReserveConfigurationData(token);
    }

    function getIsolationBorrowStatus(address token) internal view returns (bool iBorrowStatus) {
        ReserveConfigurationMap memory self = (pool.getReserveData(token)).configuration;
        uint256 BORROWABLE_IN_ISOLATION_MASK = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFFFFFFFFFFFFFFF;
        return (self.data & ~BORROWABLE_IN_ISOLATION_MASK) != 0;
    }

    function getV3Token(address token) internal view returns (AaveV3Token memory tokenData) {
        (
            (tokenData.borrowCap, tokenData.supplyCap),
            tokenData.eModeCategory,
            tokenData.debtCeiling,
            tokenData.debtCeilingDecimals,
            tokenData.liquidationFee,
            tokenData.isPaused,
            tokenData.flashLoanEnabled
        ) = (
            aaveData.getReserveCaps(token),
            aaveData.getReserveEModeCategory(token),
            aaveData.getDebtCeiling(token),
            aaveData.getDebtCeilingDecimals(),
            aaveData.getLiquidationProtocolFee(token),
            aaveData.getPaused(token),
            aaveData.getFlashLoanEnabled(token)
        );
        {
            (tokenData.isolationBorrowEnabled) = getIsolationBorrowStatus(token);
        }
    }

    function getEthPrice() public view returns (uint256 ethPrice) {
        ethPrice = uint256(AggregatorV3Interface(getChainLinkFeed()).latestAnswer());
    }

    function getEmodeCategoryData(uint8 id) external view returns (EmodeData memory eModeData) {
        EModeCategory memory data_ = pool.getEModeCategoryData(id);
        {
            eModeData.data = data_;
        }
    }

    function reserveConfig(address token)
        internal
        view
        returns (
            uint256 decimals,
            uint256 ltv,
            uint256 threshold,
            uint256 reserveFactor
        )
    {
        (decimals, ltv, threshold, , reserveFactor, , , , , ) = aaveData.getReserveConfigurationData(token);
    }

    function resData(address token)
        internal
        view
        returns (
            uint256 availableLiquidity,
            uint256 totalStableDebt,
            uint256 totalVariableDebt
        )
    {
        (, , availableLiquidity, totalStableDebt, totalVariableDebt, , , , , , , ) = aaveData.getReserveData(token);
    }

    function getAaveTokensData(address token) internal view returns (ReserveAddresses memory reserve) {
        (
            reserve.aToken.tokenAddress,
            reserve.stableDebtToken.tokenAddress,
            reserve.variableDebtToken.tokenAddress
        ) = aaveData.getReserveTokensAddresses(token);
        reserve.aToken.symbol = IERC20Detailed(reserve.aToken.tokenAddress).symbol();
        reserve.stableDebtToken.symbol = IERC20Detailed(reserve.stableDebtToken.tokenAddress).symbol();
        reserve.variableDebtToken.symbol = IERC20Detailed(reserve.variableDebtToken.tokenAddress).symbol();
        reserve.aToken.decimals = IERC20Detailed(reserve.aToken.tokenAddress).decimals();
        reserve.stableDebtToken.decimals = IERC20Detailed(reserve.stableDebtToken.tokenAddress).decimals();
        reserve.variableDebtToken.decimals = IERC20Detailed(reserve.variableDebtToken.tokenAddress).decimals();
    }

    function userCollateralData(address token) internal view returns (AaveV3TokenData memory aaveTokenData) {
        aaveTokenData.asset = token;
        aaveTokenData.symbol = IERC20Detailed(token).symbol();
        (
            aaveTokenData.decimals,
            aaveTokenData.ltv,
            aaveTokenData.threshold,
            aaveTokenData.reserveFactor
        ) = reserveConfig(token);

        {
            (
                aaveTokenData.availableLiquidity,
                aaveTokenData.totalStableDebt,
                aaveTokenData.totalVariableDebt
            ) = resData(token);
        }

        aaveTokenData.token = getV3Token(token);

        //-------------INCENTIVE DETAILS---------------

        aaveTokenData.reserves = getAaveTokensData(token);
    }

    function getUserTokenData(address user, address token)
        internal
        view
        returns (AaveV3UserTokenData memory tokenData)
    {
        uint256 basePrice = IPriceOracle(IPoolAddressesProvider(getPoolAddressProvider()).getPriceOracle())
            .getAssetPrice(token);
        tokenData.price = basePrice;
        (
            tokenData.supplyBalance,
            tokenData.stableBorrowBalance,
            tokenData.variableBorrowBalance,
            ,
            ,
            tokenData.userStableBorrowRate,
            tokenData.supplyRate,
            ,
            tokenData.isCollateral
        ) = aaveData.getUserReserveData(token, user);

        {
            tokenData.flag = getFlags(token);
            (, , , , , , tokenData.variableBorrowRate, tokenData.stableBorrowRate, , , , ) = aaveData.getReserveData(
                token
            );
        }
    }

    function getPrices(bytes memory data) internal pure returns (uint256) {
        (, BaseCurrencyInfo memory baseCurrency) = abi.decode(data, (AggregatedReserveData[], BaseCurrencyInfo));
        return uint256(baseCurrency.marketReferenceCurrencyPriceInUsd);
    }

    function getBaseCurrencyDetails() internal view returns (BaseCurrency memory baseCurr) {
        if (aaveOracle.BASE_CURRENCY() == address(0)) {
            baseCurr.symbol = "USD";
        } else {
            baseCurr.symbol = IERC20Detailed(aaveOracle.BASE_CURRENCY()).symbol();
        }

        baseCurr.baseUnit = aaveOracle.BASE_CURRENCY_UNIT();
        baseCurr.baseAddress = aaveOracle.BASE_CURRENCY();

        //TODO
        //     (, bytes memory data) = getUiDataProvider().staticcall(
        //         abi.encodeWithSignature("getReservesData(address)", IPoolAddressesProvider(getPoolAddressProvider()))
        //     );
        //     baseCurr.baseInUSD = getPrices(data);
        // }
    }

    function getList() public view returns (address[] memory data) {
        data = pool.getReservesList();
    }

    function isUsingAsCollateralOrBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 3 != 0;
    }

    function isUsingAsCollateral(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2 + 1)) & 1 != 0;
    }

    function isBorrowing(uint256 self, uint256 reserveIndex) public pure returns (bool) {
        require(reserveIndex < 128, "can't be more than 128");
        return (self >> (reserveIndex * 2)) & 1 != 0;
    }

    function getConfig(address user) public view returns (UserConfigurationMap memory data) {
        data = pool.getUserConfiguration(user);
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