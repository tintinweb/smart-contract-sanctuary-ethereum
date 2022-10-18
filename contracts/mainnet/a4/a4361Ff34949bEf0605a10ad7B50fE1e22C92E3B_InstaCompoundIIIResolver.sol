// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "./interfaces.sol";
import "./helpers.sol";

/**
 *@title Compund III Resolver
 *@dev get user position, user configuration, market configuration.
 */
contract CompoundIIIResolver is CompoundIIIHelpers {
    /**
     *@dev get position of the user for all collaterals.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param markets Array of addresses of the market for which the user's position details are needed
     *@return positionData Array of overall position details of the user - balances, rewards, collaterals and flags.
     *@return marketConfig Array of the market configuration details.
     */
    function getPositionForMarkets(address user, address[] calldata markets)
        public
        returns (PositionData[] memory positionData, MarketConfig[] memory marketConfig)
    {
        uint256 length = markets.length;
        positionData = new PositionData[](length);
        marketConfig = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            positionData[i].userData = getUserData(user, markets[i]);
            positionData[i].collateralData = getCollateralAll(user, markets[i]);
            marketConfig[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get position of the user for given collateral.
     *@notice get position details of the user in a market including overall position data, collaterals, rewards etc.
     *@param user Address of the user whose position details are needed.
     *@param markets Array of addresses of the market for which the user's position details are needed
     *@param tokenIDs IDs or offsets of the token as per comet market whose collateral details are needed.
     *@return positionData Array of overall position details of the user - balances, rewards, collaterals and flags.
     *@return marketConfig Array of the market configuration details.
     */
    function getPositionForTokenIds(
        address user,
        address[] calldata markets,
        uint8[] calldata tokenIDs
    ) public returns (PositionData[] memory positionData, MarketConfig[] memory marketConfig) {
        uint256 length = markets.length;
        positionData = new PositionData[](length);
        marketConfig = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            positionData[i].userData = getUserData(user, markets[i]);
            positionData[i].collateralData = getAssetCollaterals(user, markets[i], tokenIDs);
            marketConfig[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get market configuration.
     *@notice returns the market stats including market supplies, balances, rates, flags for market operations,
     *collaterals or assets active, base asset info etc.
     *@param markets Array of addresses of the comet market for which the user's position details are needed.
     *@return marketConfigs Array of struct containing data related to the market and the assets.
     */
    function getMarketConfiguration(address[] calldata markets)
        public
        view
        returns (MarketConfig[] memory marketConfigs)
    {
        uint256 length = markets.length;
        marketConfigs = new MarketConfig[](length);

        for (uint256 i = 0; i < length; i++) {
            marketConfigs[i] = getMarketConfig(markets[i]);
        }
    }

    /**
     *@dev get list of collaterals user has supplied..
     *@notice get list of all collaterals in the market.
     *@param user Address of the user whose collateral details are needed.
     *@param markets Array of addresses of the comet market for which the user's collateral details are needed.
     *@return datas array of token addresses supported in the market.
     */
    function getUsedCollateralsList(address user, address[] calldata markets)
        public
        returns (address[][] memory datas)
    {
        uint256 length = markets.length;
        datas = new address[][](length);

        for (uint256 i = 0; i < length; i++) {
            datas[i] = getUsedCollateralList(user, markets[i]);
        }
    }
}

contract InstaCompoundIIIResolver is CompoundIIIResolver {
    string public constant name = "Compound-III-Resolver-v1.0";
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

struct AssetInfo {
    uint8 offset;
    address asset;
    address priceFeed;
    uint64 scale;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}

struct RewardConfig {
    address token;
    uint64 rescaleFactor;
    bool shouldUpscale;
}

struct RewardOwed {
    address token;
    uint256 owed;
}

struct AssetConfig {
    address asset;
    address priceFeed;
    uint8 decimals;
    uint64 borrowCollateralFactor;
    uint64 liquidateCollateralFactor;
    uint64 liquidationFactor;
    uint128 supplyCap;
}

struct Configuration {
    address governor;
    address pauseGuardian;
    address baseToken;
    address baseTokenPriceFeed;
    address extensionDelegate;
    uint64 supplyKink;
    uint64 supplyPerYearInterestRateSlopeLow;
    uint64 supplyPerYearInterestRateSlopeHigh;
    uint64 supplyPerYearInterestRateBase;
    uint64 borrowKink;
    uint64 borrowPerYearInterestRateSlopeLow;
    uint64 borrowPerYearInterestRateSlopeHigh;
    uint64 borrowPerYearInterestRateBase;
    uint64 storeFrontPriceFactor;
    uint64 trackingIndexScale;
    uint64 baseTrackingSupplySpeed;
    uint64 baseTrackingBorrowSpeed;
    uint104 baseMinForRewards;
    uint104 baseBorrowMin;
    uint104 targetReserves;
    AssetConfig[] assetConfigs;
}

struct TotalsBasic {
    // 1st slot
    uint64 baseSupplyIndex;
    uint64 baseBorrowIndex;
    uint64 trackingSupplyIndex;
    uint64 trackingBorrowIndex;
    // 2nd slot
    uint104 totalSupplyBase;
    uint104 totalBorrowBase;
    uint40 lastAccrualTime;
    uint8 pauseFlags;
}

struct TotalsCollateral {
    uint128 totalSupplyAsset;
    uint128 _reserved;
}

struct UserBasic {
    int104 principal;
    uint64 baseTrackingIndex;
    uint64 baseTrackingAccrued;
    uint16 assetsIn;
    uint8 _reserved;
}

struct UserCollateral {
    uint128 balance;
    uint128 _reserved;
}

interface IComet {
    function getAssetInfo(uint8 i) external view returns (AssetInfo memory);

    function getAssetInfoByAddress(address asset) external view returns (AssetInfo memory);

    function getSupplyRate(uint256 utilization) external view returns (uint64);

    function getBorrowRate(uint256 utilization) external view returns (uint64);

    function getUtilization() external view returns (uint64);

    function getPrice(address priceFeed) external view returns (uint256);

    function getReserves() external view returns (int256);

    function isBorrowCollateralized(address account) external view returns (bool);

    function isLiquidatable(address account) external view returns (bool);

    function isSupplyPaused() external view returns (bool);

    function isTransferPaused() external view returns (bool);

    function isWithdrawPaused() external view returns (bool);

    function isAbsorbPaused() external view returns (bool);

    function isBuyPaused() external view returns (bool);

    function quoteCollateral(address asset, uint256 baseAmount) external view returns (uint256);

    function totalSupply() external view returns (uint104);

    function totalBorrow() external view returns (uint104);

    function balanceOf(address account) external view returns (uint256);

    function baseBalanceOf(address account) external view returns (int104);

    function borrowBalanceOf(address account) external view returns (uint256);

    function targetReserves() external view returns (uint104);

    function numAssets() external view returns (uint8);

    function decimals() external view returns (uint8);

    function initializeStorage() external;

    function baseScale() external view returns (uint64);

    /// @dev uint64
    function trackingIndexScale() external view returns (uint64);

    /// @dev uint64
    function baseTrackingSupplySpeed() external view returns (uint64);

    /// @dev uint64
    function baseTrackingBorrowSpeed() external view returns (uint64);

    /// @dev uint104
    function baseMinForRewards() external view returns (uint104);

    /// @dev uint104
    function baseBorrowMin() external view returns (uint104);

    /// @dev uint64
    function supplyKink() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeLow() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateSlopeHigh() external view returns (uint64);

    /// @dev uint64
    function supplyPerSecondInterestRateBase() external view returns (uint64);

    /// @dev uint64
    function borrowKink() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeLow() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateSlopeHigh() external view returns (uint64);

    /// @dev uint64
    function borrowPerSecondInterestRateBase() external view returns (uint64);

    /// @dev uint64
    function storeFrontPriceFactor() external view returns (uint64);

    function baseToken() external view returns (address);

    function baseTokenPriceFeed() external view returns (address);

    function collateralBalanceOf(address account, address asset) external view returns (uint128);

    // total accrued base rewards for an account
    function baseTrackingAccrued(address account) external view returns (uint64);

    function baseAccrualScale() external view returns (uint64);

    function baseIndexScale() external view returns (uint64);

    function factorScale() external view returns (uint64);

    function priceScale() external view returns (uint64);

    function maxAssets() external view returns (uint8);

    function totalsBasic() external view returns (TotalsBasic memory);

    function totalsCollateral(address) external view returns (TotalsCollateral memory);

    function userNonce(address) external returns (uint256);

    function userBasic(address) external returns (UserBasic memory);

    function userCollateral(address, address) external returns (UserCollateral memory);
}

interface TokenInterface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

interface ICometRewards {
    function getRewardOwed(address comet, address account) external returns (RewardOwed memory);

    function rewardConfig(address cometProxy) external view returns (RewardConfig memory);

    function rewardsClaimed(address cometProxy, address account) external view returns (uint256);
}

interface ICometConfig {
    function getAssetIndex(address cometProxy, address asset) external view returns (uint256);

    function getConfiguration(address cometProxy) external view returns (Configuration memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./interfaces.sol";
import { DSMath } from "../../../utils/dsmath.sol";

contract CompoundIIIHelpers is DSMath {
    /**
     *@dev Returns ethereum address
     */
    function getEthAddr() internal pure returns (address) {
        return 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    }

    function getCometRewardsAddress() internal pure returns (address) {
        return 0x1B0e765F6224C21223AeA2af16c1C46E38885a40;
    }

    function getConfiguratorAddress() internal pure returns (address) {
        return 0xcFC1fA6b7ca982176529899D99af6473aD80DF4F;
    }

    struct BaseAssetInfo {
        address token;
        address priceFeed;
        uint256 price;
        uint8 decimals;
        ///@dev scale for base asset i.e. (10 ** decimals)
        uint64 mantissa;
        ///@dev The scale for base index (depends on time/rate scales, not base token) -> 1e15
        uint64 indexScale;
        ///@dev An index for tracking participation of accounts that supply the base asset.
        uint64 trackingSupplyIndex;
        ///@dev An index for tracking participation of accounts that borrow the base asset.
        uint64 trackingBorrowIndex;
    }

    struct Scales {
        ///@dev liquidation factor, borrow factor scale
        uint64 factorScale;
        ///@dev scale for USD prices
        uint64 priceScale;
        ///@dev The scale for the index tracking protocol rewards, useful in calculating rewards APR
        uint64 trackingIndexScale;
    }

    struct Token {
        uint8 offset;
        uint8 decimals;
        address token;
        string symbol;
        ///@dev 10**decimals
        uint256 scale;
    }

    struct AssetData {
        Token token;
        ///@dev token's priceFeed
        address priceFeed;
        ///@dev answer as per latestRoundData from the priceFeed scaled by priceScale
        uint256 price;
        ///@dev The collateral factor(decides how much each collateral can increase borrowing capacity of user),
        //integer representing the decimal value scaled up by 10 ^ 18.
        uint64 borrowCollateralFactor;
        ///@dev sets the limits for account's borrow balance,
        //integer representing the decimal value scaled up by 10 ^ 18.
        uint64 liquidateCollateralFactor;
        ///@dev liquidation penalty deducted from account's balance upon absorption
        uint64 liquidationFactor;
        ///@dev integer scaled up by 10 ^ decimals
        uint128 supplyCapInWei;
        ///@dev  current amount of collateral that all accounts have supplied
        uint128 totalCollateralInWei;
    }

    struct AccountFlags {
        ///@dev flag indicating whether the user's position is liquidatable
        bool isLiquidatable;
        ///@dev flag indicating whether an account has enough collateral to borrow
        bool isBorrowCollateralized;
    }

    struct MarketFlags {
        bool isAbsorbPaused;
        bool isBuyPaused;
        bool isSupplyPaused;
        bool isTransferPaused;
        bool isWithdrawPaused;
    }

    struct UserCollateralData {
        Token token;
        ///@dev current positive base balance of an account or zero
        uint256 suppliedBalanceInBase;
        uint256 suppliedBalanceInAsset;
    }

    struct RewardsConfig {
        address token;
        uint64 rescaleFactor;
        bool shouldUpScale;
        ///@dev The minimum amount of base principal wei for rewards to accrue.
        //The minimum amount of base asset supplied to the protocol in order for accounts to accrue rewards.
        uint104 baseMinForRewardsInBase;
    }

    struct UserRewardsData {
        address rewardToken;
        uint8 rewardTokenDecimals;
        uint256 amountOwedInWei;
        uint256 amountClaimedInWei;
    }

    struct UserData {
        ///@dev principal value the amount of base asset that the account has supplied (greater than zero)
        //or owes (less than zero) to the protocol.
        int104 principalInBase;
        ///@dev the base balance of supplies with interest, 0 for borrowing case or no supplies
        uint256 suppliedBalanceInBase;
        ///@dev the borrow base balance including interest, for non-negative base asset balance value is 0
        uint256 borrowedBalanceInBase;
        ///@dev the assets which are supplied as collateral in packed form
        uint16 assetsIn;
        ///@dev index tracking user's position
        uint64 accountTrackingIndex;
        ///@dev amount of reward token accrued based on usage of the base asset within the protocol
        //for the specified account, scaled up by 10 ^ 6.
        uint64 interestAccruedInBase;
        uint256 userNonce;
        // int256 borrowableAmount;
        // uint256 healthFactor;
        UserRewardsData[] rewards;
        AccountFlags flags;
    }

    struct MarketConfig {
        uint8 assetCount;
        ///@dev the per second supply rate as the decimal representation of a percentage scaled up by 10 ^ 18.
        uint64 supplyRateInPercentWei;
        uint64 borrowRateInPercentWei;
        ///@dev for rewards APR calculation
        //The speed at which supply rewards are tracked (in trackingIndexScale)
        uint64 baseTrackingSupplySpeed;
        ///@dev  The speed at which borrow rewards are tracked (in trackingIndexScale)
        uint64 baseTrackingBorrowSpeed;
        ///@dev total protocol reserves
        int256 reservesInBase;
        ///@dev Fraction of the liquidation penalty that goes to buyers of collateral
        uint64 storeFrontPriceFactor;
        ///@dev minimum borrow amount
        uint104 baseBorrowMinInBase;
        //amount of reserves allowed before absorbed collateral is no longer sold by the protocol
        uint104 targetReservesInBase;
        uint104 totalSupplyInBase;
        uint104 totalBorrowInBase;
        uint256 utilization;
        BaseAssetInfo baseToken;
        Scales scales;
        RewardsConfig[] rewardConfig;
        AssetData[] assets;
    }

    struct PositionData {
        UserData userData;
        UserCollateralData[] collateralData;
    }

    ICometRewards internal cometRewards = ICometRewards(getCometRewardsAddress());
    ICometConfig internal cometConfig = ICometConfig(getConfiguratorAddress());

    function getBaseTokenInfo(IComet _comet) internal view returns (BaseAssetInfo memory baseAssetInfo) {
        baseAssetInfo.token = _comet.baseToken();
        baseAssetInfo.priceFeed = _comet.baseTokenPriceFeed();
        baseAssetInfo.price = _comet.getPrice(baseAssetInfo.priceFeed);
        baseAssetInfo.decimals = _comet.decimals();
        baseAssetInfo.mantissa = _comet.baseScale();
        baseAssetInfo.indexScale = _comet.baseIndexScale();

        TotalsBasic memory indices = _comet.totalsBasic();
        baseAssetInfo.trackingSupplyIndex = indices.trackingSupplyIndex;
        baseAssetInfo.trackingBorrowIndex = indices.trackingBorrowIndex;
    }

    function getScales(IComet _comet) internal view returns (Scales memory scales) {
        scales.factorScale = _comet.factorScale();
        scales.priceScale = _comet.priceScale();
        scales.trackingIndexScale = _comet.trackingIndexScale();
    }

    function getMarketFlags(IComet _comet) internal view returns (MarketFlags memory flags) {
        flags.isAbsorbPaused = _comet.isAbsorbPaused();
        flags.isBuyPaused = _comet.isBuyPaused();
        flags.isSupplyPaused = _comet.isSupplyPaused();
        flags.isWithdrawPaused = _comet.isWithdrawPaused();
        flags.isTransferPaused = _comet.isWithdrawPaused();
    }

    function getRewardsConfig(address cometMarket) internal view returns (RewardsConfig memory rewards) {
        RewardConfig memory _rewards = cometRewards.rewardConfig(cometMarket);
        rewards.token = _rewards.token;
        rewards.rescaleFactor = _rewards.rescaleFactor;
        rewards.shouldUpScale = _rewards.shouldUpscale;
        rewards.baseMinForRewardsInBase = IComet(cometMarket).baseMinForRewards();
    }

    function getMarketAssets(IComet _comet, uint8 length) internal view returns (AssetData[] memory assets) {
        assets = new AssetData[](length);
        for (uint8 i = 0; i < length; i++) {
            AssetInfo memory asset;
            Token memory _token;
            AssetData memory _asset;
            asset = _comet.getAssetInfo(i);

            TokenInterface token = TokenInterface(asset.asset);
            _token.offset = asset.offset;
            _token.token = asset.asset;
            _token.symbol = token.symbol();
            _token.decimals = token.decimals();
            _token.scale = asset.scale;

            _asset.token = _token;
            _asset.priceFeed = asset.priceFeed;
            _asset.price = _comet.getPrice(asset.priceFeed);
            _asset.borrowCollateralFactor = asset.borrowCollateralFactor;
            _asset.liquidateCollateralFactor = asset.liquidateCollateralFactor;
            _asset.liquidationFactor = asset.liquidationFactor;
            _asset.supplyCapInWei = asset.supplyCap;
            _asset.totalCollateralInWei = _comet.totalsCollateral(asset.asset).totalSupplyAsset;

            assets[i] = _asset;
        }
    }

    function getMarketConfig(address cometMarket) internal view returns (MarketConfig memory market) {
        IComet _comet = IComet(cometMarket);
        market.utilization = _comet.getUtilization();
        market.assetCount = _comet.numAssets();
        market.supplyRateInPercentWei = _comet.getSupplyRate(market.utilization);
        market.borrowRateInPercentWei = _comet.getBorrowRate(market.utilization);
        market.baseTrackingSupplySpeed = _comet.baseTrackingSupplySpeed();
        market.baseTrackingBorrowSpeed = _comet.baseTrackingBorrowSpeed();
        market.reservesInBase = _comet.getReserves();
        market.storeFrontPriceFactor = _comet.storeFrontPriceFactor();
        market.baseBorrowMinInBase = _comet.baseBorrowMin();
        market.targetReservesInBase = _comet.targetReserves();
        market.totalSupplyInBase = _comet.totalSupply();
        market.totalBorrowInBase = _comet.totalBorrow();

        market.baseToken = getBaseTokenInfo(_comet);
        market.scales = getScales(_comet);

        market.rewardConfig = new RewardsConfig[](1);
        market.rewardConfig[0] = getRewardsConfig(cometMarket);
        market.assets = getMarketAssets(_comet, market.assetCount);
    }

    function currentValue(
        int104 principalValue,
        uint64 baseSupplyIndex,
        uint64 baseBorrowIndex,
        uint64 baseIndexScale
    ) internal view returns (int104) {
        if (principalValue >= 0) {
            return int104((uint104(principalValue) * baseSupplyIndex) / uint64(baseIndexScale));
        } else {
            return -int104((uint104(principalValue) * baseBorrowIndex) / uint64(baseIndexScale));
        }
    }

    function isAssetIn(uint16 assetsIn, uint8 assetOffset) internal pure returns (bool) {
        return (assetsIn & (uint16(1) << assetOffset) != 0);
    }

    function getBorrowableAmount(address account, address cometAddress) public returns (int256) {
        IComet _comet = IComet(cometAddress);
        UserBasic memory _userBasic = _comet.userBasic(account);
        TotalsBasic memory _totalsBasic = _comet.totalsBasic();
        uint8 _numAssets = _comet.numAssets();
        address baseTokenPriceFeed = _comet.baseTokenPriceFeed();

        int256 amount_ = int256(
            (currentValue(
                _userBasic.principal,
                _totalsBasic.baseSupplyIndex,
                _totalsBasic.baseBorrowIndex,
                _comet.baseIndexScale()
            ) * int256(_comet.getPrice(baseTokenPriceFeed))) / int256(1e8)
        );

        for (uint8 i = 0; i < _numAssets; i++) {
            if (isAssetIn(_userBasic.assetsIn, i)) {
                AssetInfo memory asset = _comet.getAssetInfo(i);
                UserCollateral memory coll = _comet.userCollateral(account, asset.asset);
                uint256 newAmount = (uint256(coll.balance) * _comet.getPrice(asset.priceFeed)) / 1e8;
                amount_ += int256((newAmount * asset.borrowCollateralFactor) / 1e18);
            }
        }

        return amount_;
    }

    function getAccountFlags(address account, IComet _comet) internal view returns (AccountFlags memory flags) {
        flags.isLiquidatable = _comet.isLiquidatable(account);
        flags.isBorrowCollateralized = _comet.isBorrowCollateralized(account);
    }

    function getCollateralData(
        address account,
        IComet _comet,
        uint8[] memory offsets
    ) internal returns (UserCollateralData[] memory _collaterals, address[] memory collateralAssets) {
        UserBasic memory _userBasic = _comet.userBasic(account);
        uint16 _assetsIn = _userBasic.assetsIn;
        uint8 numAssets = uint8(offsets.length);
        uint8 _length = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            if (isAssetIn(_assetsIn, offsets[i])) {
                _length++;
            }
        }
        _collaterals = new UserCollateralData[](numAssets);
        collateralAssets = new address[](_length);
        uint8 j = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            Token memory _token;
            AssetInfo memory asset = _comet.getAssetInfo(offsets[i]);
            _token.token = asset.asset;
            _token.symbol = TokenInterface(asset.asset).symbol();
            _token.decimals = TokenInterface(asset.asset).decimals();
            _token.scale = asset.scale;
            _token.offset = asset.offset;
            uint256 suppliedAmt = uint256(_comet.userCollateral(account, asset.asset).balance);
            _collaterals[i].token = _token;
            _collaterals[i].suppliedBalanceInAsset = suppliedAmt;
            _collaterals[i].suppliedBalanceInBase = getCollateralBalanceInBase(suppliedAmt, _comet, asset.priceFeed);

            if (isAssetIn(_assetsIn, offsets[i])) {
                collateralAssets[j] = _token.token;
                j++;
            }
        }
    }

    function getCollateralBalanceInBase(
        uint256 balanceInAsset,
        IComet _comet,
        address assetPriceFeed
    ) internal view returns (uint256 suppliedBalanceInBase) {
        address basePriceFeed = _comet.baseTokenPriceFeed();
        uint256 baseAssetprice = _comet.getPrice(basePriceFeed);
        uint256 collateralPrice = _comet.getPrice(assetPriceFeed);
        suppliedBalanceInBase = div(mul(balanceInAsset, collateralPrice), baseAssetprice);
    }

    function getUserData(address account, address cometMarket) internal returns (UserData memory userData) {
        IComet _comet = IComet(cometMarket);
        userData.suppliedBalanceInBase = _comet.balanceOf(account);
        userData.borrowedBalanceInBase = _comet.borrowBalanceOf(account);
        UserBasic memory accountDataInBase = _comet.userBasic(account);
        userData.principalInBase = accountDataInBase.principal;
        userData.assetsIn = accountDataInBase.assetsIn;
        userData.accountTrackingIndex = accountDataInBase.baseTrackingIndex;
        userData.interestAccruedInBase = accountDataInBase.baseTrackingAccrued;
        userData.userNonce = _comet.userNonce(account);
        UserRewardsData memory _rewards;
        RewardOwed memory reward = cometRewards.getRewardOwed(cometMarket, account);
        _rewards.rewardToken = reward.token;
        _rewards.rewardTokenDecimals = TokenInterface(reward.token).decimals();
        _rewards.amountOwedInWei = reward.owed;
        _rewards.amountClaimedInWei = cometRewards.rewardsClaimed(cometMarket, account);

        userData.rewards = new UserRewardsData[](1);
        userData.rewards[0] = _rewards;

        userData.flags = getAccountFlags(account, _comet);

        uint8 length = _comet.numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
    }

    function getHealthFactor(address account, address cometMarket) public returns (uint256 healthFactor) {
        IComet _comet = IComet(cometMarket);
        UserBasic memory _userBasic = _comet.userBasic(account);
        uint16 _assetsIn = _userBasic.assetsIn;
        uint8 numAssets = _comet.numAssets();
        uint256 sumSupplyXFactor = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            if (isAssetIn(_assetsIn, i)) {
                AssetInfo memory asset = _comet.getAssetInfo(i);
                uint256 suppliedAmt = uint256(_comet.userCollateral(account, asset.asset).balance);
                sumSupplyXFactor = add(sumSupplyXFactor, mul(suppliedAmt, asset.liquidateCollateralFactor));
            }
        }

        healthFactor = div(sumSupplyXFactor, _comet.borrowBalanceOf(account));
    }

    function getCollateralAll(address account, address cometMarket)
        internal
        returns (UserCollateralData[] memory collaterals)
    {
        IComet _comet = IComet(cometMarket);
        uint8 length = _comet.numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
        (collaterals, ) = getCollateralData(account, _comet, offsets);
    }

    function getAssetCollaterals(
        address account,
        address cometMarket,
        uint8[] memory offsets
    ) internal returns (UserCollateralData[] memory collaterals) {
        IComet _comet = IComet(cometMarket);
        (collaterals, ) = getCollateralData(account, _comet, offsets);
    }

    function getUserPosition(address account, address cometMarket) internal returns (UserData memory userData) {
        userData = getUserData(account, cometMarket);
    }

    function getUsedCollateralList(address account, address cometMarket) internal returns (address[] memory assets) {
        uint8 length = IComet(cometMarket).numAssets();
        uint8[] memory offsets = new uint8[](length);

        for (uint8 i = 0; i < length; i++) {
            offsets[i] = i;
        }
        (, assets) = getCollateralData(account, IComet(cometMarket), offsets);
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