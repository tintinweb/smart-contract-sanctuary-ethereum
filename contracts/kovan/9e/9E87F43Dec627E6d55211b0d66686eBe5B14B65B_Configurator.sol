// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CometFactory.sol";
import "./CometConfiguration.sol";
import "./ConfiguratorStorage.sol";

contract Configurator is ConfiguratorStorage {

    /** Custom events **/

    event AddAsset(AssetConfig assetConfig);
    event CometDeployed(address newComet);
    event GovernorTransferred(address oldGovernor, address newGovernor);
    event SetFactory(address oldFactory, address newFactory);
    event SetGovernor(address oldGovernor, address newGovernor);
    event SetPauseGuardian(address oldPauseGuardian, address newPauseGuardian);
    event SetBaseTokenPriceFeed(address oldBaseTokenPriceFeed, address newBaseTokenPriceFeed);
    event SetExtensionDelegate(address oldExt, address newExt);
    event SetKink(uint64 oldKink, uint64 newKink);
    event SetPerYearInterestRateSlopeLow(uint64 oldIRSlopeLow, uint64 newIRSlopeLow);
    event SetPerYearInterestRateSlopeHigh(uint64 oldIRSlopeHigh, uint64 newIRSlopeHigh);
    event SetPerYearInterestRateBase(uint64 oldIRBase, uint64 newIRBase);
    event SetReserveRate(uint64 oldReserveRate, uint64 newReserveRate);
    event SetStoreFrontPriceFactor(uint64 oldStoreFrontPriceFactor, uint64 newStoreFrontPriceFactor);
    event SetBaseTrackingSupplySpeed(uint64 oldBaseTrackingSupplySpeed, uint64 newBaseTrackingSupplySpeed);
    event SetBaseTrackingBorrowSpeed(uint64 oldBaseTrackingBorrowSpeed, uint64 newBaseTrackingBorrowSpeed);
    event SetBaseMinForRewards(uint104 oldBaseMinForRewards, uint104 newBaseMinForRewards);
    event SetBaseBorrowMin(uint104 oldBaseBorrowMin, uint104 newBaseBorrowMin);
    event SetTargetReserves(uint104 oldTargetReserves, uint104 newTargetReserves);
    event UpdateAsset(AssetConfig oldAssetConfig, AssetConfig newAssetConfig);
    event UpdateAssetPriceFeed(address indexed asset, address oldPriceFeed, address newPriceFeed);
    event UpdateAssetBorrowCollateralFactor(address indexed asset, uint64 oldBorrowCF, uint64 newBorrowCF);
    event UpdateAssetLiquidateCollateralFactor(address indexed asset, uint64 oldLiquidateCF, uint64 newLiquidateCF);
    event UpdateAssetLiquidationFactor(address indexed asset, uint64 oldLiquidationFactor, uint64 newLiquidationFactor);
    event UpdateAssetSupplyCap(address indexed asset, uint128 oldSupplyCap, uint128 newSupplyCap);

    /** Custom errors **/

    error AlreadyInitialized();
    error AssetDoesNotExist();
    error InvalidAddress();
    error Unauthorized();

    /// @notice Initializes the storage for Configurator
    function initialize(address _governor, address _factory, Configuration calldata _config) public {
        if (version != 0) revert AlreadyInitialized();
        if (_governor == address(0)) revert InvalidAddress();
        if (_factory == address(0)) revert InvalidAddress();

        governor = _governor;
        factory = _factory;
        configuratorParams = _config;
        version = 1;
    }

    /// @notice Sets the factory for Configurator
    /// @dev only callable by governor
    function setFactory(address newFactory) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldFactory = factory;
        factory = newFactory;
        emit SetFactory(oldFactory, newFactory);
    }

    /** Setters for Comet-related configuration **/
    /**
    * The following configuration parameters do not have setters:
    *   - BaseToken
    *   - TrackingIndexScale
    */

    /// @dev only callable by governor
    function setGovernor(address newGovernor) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldGovernor = configuratorParams.governor;
        configuratorParams.governor = newGovernor;
        emit SetGovernor(oldGovernor, newGovernor);
    }

    /// @dev only callable by governor
    function setPauseGuardian(address newPauseGuardian) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldPauseGuardian = configuratorParams.pauseGuardian;
        configuratorParams.pauseGuardian = newPauseGuardian;
        emit SetPauseGuardian(oldPauseGuardian, newPauseGuardian);
    }

    /// @dev only callable by governor
    function setBaseTokenPriceFeed(address newBaseTokenPriceFeed) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldBaseTokenPriceFeed = configuratorParams.baseTokenPriceFeed;
        configuratorParams.baseTokenPriceFeed = newBaseTokenPriceFeed;
        emit SetBaseTokenPriceFeed(oldBaseTokenPriceFeed, newBaseTokenPriceFeed);
    }

    /// @dev only callable by governor
    function setExtensionDelegate(address newExtensionDelegate) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldExtensionDelegate = configuratorParams.extensionDelegate;
        configuratorParams.extensionDelegate = newExtensionDelegate;
        emit SetExtensionDelegate(oldExtensionDelegate, newExtensionDelegate);
    }

    /// @dev only callable by governor
    function setKink(uint64 newKink) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldKink = configuratorParams.kink;
        configuratorParams.kink = newKink;
        emit SetKink(oldKink, newKink);
    }

    /// @dev only callable by governor
    function setPerYearInterestRateSlopeLow(uint64 newSlope) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldSlope = configuratorParams.perYearInterestRateSlopeLow;
        configuratorParams.perYearInterestRateSlopeLow = newSlope;
        emit SetPerYearInterestRateSlopeLow(oldSlope, newSlope);
    }

    /// @dev only callable by governor
    function setPerYearInterestRateSlopeHigh(uint64 newSlope) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldSlope = configuratorParams.perYearInterestRateSlopeHigh;
        configuratorParams.perYearInterestRateSlopeHigh = newSlope;
        emit SetPerYearInterestRateSlopeHigh(oldSlope, newSlope);
    }

    /// @dev only callable by governor
    function setPerYearInterestRateBase(uint64 newBase) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldBase = configuratorParams.perYearInterestRateBase;
        configuratorParams.perYearInterestRateBase = newBase;
        emit SetPerYearInterestRateBase(oldBase, newBase);
    }

    /// @dev only callable by governor
    function setReserveRate(uint64 newReserveRate) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldReserveRate = configuratorParams.reserveRate;
        configuratorParams.reserveRate = newReserveRate;
        emit SetReserveRate(oldReserveRate, newReserveRate);
    }

    /// @dev only callable by governor
    function setStoreFrontPriceFactor(uint64 newStoreFrontPriceFactor) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldStoreFrontPriceFactor = configuratorParams.storeFrontPriceFactor;
        configuratorParams.storeFrontPriceFactor = newStoreFrontPriceFactor;
        emit SetStoreFrontPriceFactor(oldStoreFrontPriceFactor, newStoreFrontPriceFactor);
    }

    /// @dev only callable by governor
    function setBaseTrackingSupplySpeed(uint64 newBaseTrackingSupplySpeed) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldBaseTrackingSupplySpeed = configuratorParams.baseTrackingSupplySpeed;
        configuratorParams.baseTrackingSupplySpeed = newBaseTrackingSupplySpeed;
        emit SetBaseTrackingSupplySpeed(oldBaseTrackingSupplySpeed, newBaseTrackingSupplySpeed);
    }

    /// @dev only callable by governor
    function setBaseTrackingBorrowSpeed(uint64 newBaseTrackingBorrowSpeed) external {
        if (msg.sender != governor) revert Unauthorized();
        uint64 oldBaseTrackingBorrowSpeed = configuratorParams.baseTrackingBorrowSpeed;
        configuratorParams.baseTrackingBorrowSpeed = newBaseTrackingBorrowSpeed;
        emit SetBaseTrackingBorrowSpeed(oldBaseTrackingBorrowSpeed, newBaseTrackingBorrowSpeed);
    }

    /// @dev only callable by governor
    function setBaseMinForRewards(uint104 newBaseMinForRewards) external {
        if (msg.sender != governor) revert Unauthorized();
        uint104 oldBaseMinForRewards = configuratorParams.baseMinForRewards;
        configuratorParams.baseMinForRewards = newBaseMinForRewards;
        emit SetBaseMinForRewards(oldBaseMinForRewards, newBaseMinForRewards);
    }

    /// @dev only callable by governor
    function setBaseBorrowMin(uint104 newBaseBorrowMin) external {
        if (msg.sender != governor) revert Unauthorized();
        uint104 oldBaseBorrowMin = configuratorParams.baseBorrowMin;
        configuratorParams.baseBorrowMin = newBaseBorrowMin;
        emit SetBaseBorrowMin(oldBaseBorrowMin, newBaseBorrowMin);
    }

    /// @dev only callable by governor
    function setTargetReserves(uint104 newTargetReserves) external {
        if (msg.sender != governor) revert Unauthorized();
        uint104 oldTargetReserves = configuratorParams.targetReserves;
        configuratorParams.targetReserves = newTargetReserves;
        emit SetTargetReserves(oldTargetReserves, newTargetReserves);
    }

    /// @dev only callable by governor
    function addAsset(AssetConfig calldata assetConfig) external {
        if (msg.sender != governor) revert Unauthorized();
        configuratorParams.assetConfigs.push(assetConfig);
        emit AddAsset(assetConfig);
    }

    /// @dev only callable by governor
    function updateAsset(AssetConfig calldata newAssetConfig) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(newAssetConfig.asset);
        AssetConfig memory oldAssetConfig = configuratorParams.assetConfigs[assetIndex];
        configuratorParams.assetConfigs[assetIndex] = newAssetConfig;
        emit UpdateAsset(oldAssetConfig, newAssetConfig);
    }

    /// @dev only callable by governor
    function updateAssetPriceFeed(address asset, address newPriceFeed) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(asset);
        address oldPriceFeed = configuratorParams.assetConfigs[assetIndex].priceFeed;
        configuratorParams.assetConfigs[assetIndex].priceFeed = newPriceFeed;
        emit UpdateAssetPriceFeed(asset, oldPriceFeed, newPriceFeed);
    }

    /// @dev only callable by governor
    function updateAssetBorrowCollateralFactor(address asset, uint64 newBorrowCF) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(asset);
        uint64 oldBorrowCF = configuratorParams.assetConfigs[assetIndex].borrowCollateralFactor;
        configuratorParams.assetConfigs[assetIndex].borrowCollateralFactor = newBorrowCF;
        emit UpdateAssetBorrowCollateralFactor(asset, oldBorrowCF, newBorrowCF);
    }

    /// @dev only callable by governor
    function updateAssetLiquidateCollateralFactor(address asset, uint64 newLiquidateCF) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(asset);
        uint64 oldLiquidateCF = configuratorParams.assetConfigs[assetIndex].liquidateCollateralFactor;
        configuratorParams.assetConfigs[assetIndex].liquidateCollateralFactor = newLiquidateCF;
        emit UpdateAssetLiquidateCollateralFactor(asset, oldLiquidateCF, newLiquidateCF);
    }

    /// @dev only callable by governor
    function updateAssetLiquidationFactor(address asset, uint64 newLiquidationFactor) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(asset);
        uint64 oldLiquidationFactor = configuratorParams.assetConfigs[assetIndex].liquidationFactor;
        configuratorParams.assetConfigs[assetIndex].liquidationFactor = newLiquidationFactor;
        emit UpdateAssetLiquidationFactor(asset, oldLiquidationFactor, newLiquidationFactor);
    }

    /// @dev only callable by governor
    function updateAssetSupplyCap(address asset, uint128 newSupplyCap) external {
        if (msg.sender != governor) revert Unauthorized();

        uint assetIndex = getAssetIndex(asset);
        uint128 oldSupplyCap = configuratorParams.assetConfigs[assetIndex].supplyCap;
        configuratorParams.assetConfigs[assetIndex].supplyCap = newSupplyCap;
        emit UpdateAssetSupplyCap(asset, oldSupplyCap, newSupplyCap);
    }

    /// @dev Determine index of asset that matches given address
    function getAssetIndex(address asset) internal view returns (uint) {
        AssetConfig[] memory assetConfigs = configuratorParams.assetConfigs;
        uint numAssets = assetConfigs.length;
        for (uint i = 0; i < numAssets; i++) {
            if (assetConfigs[i].asset == asset) {
                return i;
            }
        }
        revert AssetDoesNotExist();
    }

    /** End of setters for Comet-related configuration **/

    /// @notice Gets the configuration params
    function getConfiguration() external view returns (Configuration memory) {
        return configuratorParams;
    }

    /// @notice Deploy a new version of the Comet implementation.
    /// @dev callable by anyone
    function deploy() external returns (address) {
        address newComet = CometFactory(factory).clone(configuratorParams);
        emit CometDeployed(newComet);
        return newComet;
    }

    /// @notice Transfers the governor rights to a new address
    /// @dev only callable by governor
    function transferGovernor(address newGovernor) external {
        if (msg.sender != governor) revert Unauthorized();
        address oldGovernor = governor;
        governor = newGovernor;
        emit GovernorTransferred(oldGovernor, newGovernor);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./Comet.sol";
import "./CometConfiguration.sol";

contract CometFactory is CometConfiguration {
    function clone(Configuration calldata config) external returns (address) {
        return address(new Comet(config));
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/**
 * @title Compound's Comet Configuration Interface
 * @author Compound
 */
contract CometConfiguration {
    struct ExtConfiguration {
        bytes32 symbol32;
    }

    struct Configuration {
        address governor;
        address pauseGuardian;
        address baseToken;
        address baseTokenPriceFeed;
        address extensionDelegate;

        uint64 kink;
        uint64 perYearInterestRateSlopeLow;
        uint64 perYearInterestRateSlopeHigh;
        uint64 perYearInterestRateBase;
        uint64 reserveRate;
        uint64 storeFrontPriceFactor;
        uint64 trackingIndexScale;
        uint64 baseTrackingSupplySpeed;
        uint64 baseTrackingBorrowSpeed;
        uint104 baseMinForRewards;
        uint104 baseBorrowMin;
        uint104 targetReserves;

        AssetConfig[] assetConfigs;
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
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CometConfiguration.sol";

/**
 * @title Compound's Comet Configuration Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract ConfiguratorStorage is CometConfiguration {
    /// @notice The current version of Configurator. This version should be
    /// checked in the initializer function.
    uint public version;

    /// @notice Configuration settings used to deploy new Comet instances
    /// by the configurator
    /// @dev This needs to be internal to avoid a `CompilerError: Stack too deep
    /// when compiling inline assembly` error that is caused by the default
    /// getters created for public variables.
    Configuration internal configuratorParams; // XXX can create a public getter for this

    /// @notice The governor of the protocol
    address public governor;

    /// @notice Address for the Comet factory contract
    address public factory;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CometMainInterface.sol";
import "./ERC20.sol";
import "./vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/**
 * @title Compound's Comet Contract
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
contract Comet is CometMainInterface {
    /** Custom errors **/

    error Absurd();
    error AlreadyInitialized();
    error BadAsset();
    error BadDecimals();
    error BadDiscount();
    error BadKink();
    error BadMinimum();
    error BadPrice();
    error BadReserveRate();
    error BorrowTooSmall();
    error BorrowCFTooLarge();
    error InsufficientReserves();
    error LiquidateCFTooLarge();
    error NoSelfTransfer();
    error NotCollateralized();
    error NotForSale();
    error NotLiquidatable();
    error Paused();
    error SupplyCapExceeded();
    error TimestampTooLarge();
    error TooManyAssets();
    error TooMuchSlippage();
    error TransferInFailed();
    error TransferOutFailed();
    error Unauthorized();

    /** General configuration constants **/

    /// @notice The admin of the protocol
    address public override immutable governor;

    /// @notice The account which may trigger pauses
    address public override immutable pauseGuardian;

    /// @notice The address of the base token contract
    address public override immutable baseToken;

    /// @notice The address of the price feed for the base token
    address public override immutable baseTokenPriceFeed;

    /// @notice The address of the extension contract delegate
    address public override immutable extensionDelegate;

    /// @notice The point in the supply and borrow rates separating the low interest rate slope and the high interest rate slope (factor)
    /// @dev uint64
    uint public override immutable kink;

    /// @notice Per second interest rate slope applied when utilization is below kink (factor)
    /// @dev uint64
    uint public override immutable perSecondInterestRateSlopeLow;

    /// @notice Per second interest rate slope applied when utilization is above kink (factor)
    /// @dev uint64
    uint public override immutable perSecondInterestRateSlopeHigh;

    /// @notice Per second base interest rate (factor)
    /// @dev uint64
    uint public override immutable perSecondInterestRateBase;

    /// @notice The rate of total interest paid that goes into reserves (factor)
    /// @dev uint64
    uint public override immutable reserveRate;

    /// @notice The fraction of the liquidation penalty that goes to buyers of collateral instead of the protocol
    /// @dev uint64
    uint public override immutable storeFrontPriceFactor;

    /// @notice The scale for base token (must be less than 18 decimals)
    /// @dev uint64
    uint public override immutable baseScale;

    /// @notice The scale for reward tracking
    /// @dev uint64
    uint public override immutable trackingIndexScale;

    /// @notice The speed at which supply rewards are tracked (in trackingIndexScale)
    /// @dev uint64
    uint public override immutable baseTrackingSupplySpeed;

    /// @notice The speed at which borrow rewards are tracked (in trackingIndexScale)
    /// @dev uint64
    uint public override immutable baseTrackingBorrowSpeed;

    /// @notice The minimum amount of base wei for rewards to accrue
    /// @dev This must be large enough so as to prevent division by base wei from overflowing the 64 bit indices
    /// @dev uint104
    uint public override immutable baseMinForRewards;

    /// @notice The minimum base amount required to initiate a borrow
    /// @dev uint104
    uint public override immutable baseBorrowMin;

    /// @notice The minimum base token reserves which must be held before collateral is hodled
    /// @dev uint104
    uint public override immutable targetReserves;

    /// @notice The number of decimals for wrapped base token
    uint8 public override immutable decimals;

    /// @notice The number of assets this contract actually supports
    uint8 public override immutable numAssets;

    /// @notice Factor to divide by when accruing rewards in order to preserve 6 decimals (i.e. baseScale / 1e6)
    uint internal immutable accrualDescaleFactor;

    /**  Collateral asset configuration (packed) **/

    uint256 internal immutable asset00_a;
    uint256 internal immutable asset00_b;
    uint256 internal immutable asset01_a;
    uint256 internal immutable asset01_b;
    uint256 internal immutable asset02_a;
    uint256 internal immutable asset02_b;
    uint256 internal immutable asset03_a;
    uint256 internal immutable asset03_b;
    uint256 internal immutable asset04_a;
    uint256 internal immutable asset04_b;
    uint256 internal immutable asset05_a;
    uint256 internal immutable asset05_b;
    uint256 internal immutable asset06_a;
    uint256 internal immutable asset06_b;
    uint256 internal immutable asset07_a;
    uint256 internal immutable asset07_b;
    uint256 internal immutable asset08_a;
    uint256 internal immutable asset08_b;
    uint256 internal immutable asset09_a;
    uint256 internal immutable asset09_b;
    uint256 internal immutable asset10_a;
    uint256 internal immutable asset10_b;
    uint256 internal immutable asset11_a;
    uint256 internal immutable asset11_b;
    uint256 internal immutable asset12_a;
    uint256 internal immutable asset12_b;
    uint256 internal immutable asset13_a;
    uint256 internal immutable asset13_b;
    uint256 internal immutable asset14_a;
    uint256 internal immutable asset14_b;

    /**
     * @notice Construct a new protocol instance
     * @param config The mapping of initial/constant parameters
     **/
    constructor(Configuration memory config) {
        // Sanity checks
        uint8 decimals_ = ERC20(config.baseToken).decimals();
        if (decimals_ > MAX_BASE_DECIMALS) revert BadDecimals();
        if (config.storeFrontPriceFactor > FACTOR_SCALE) revert BadDiscount();
        if (config.assetConfigs.length > MAX_ASSETS) revert TooManyAssets();
        if (config.baseMinForRewards == 0) revert BadMinimum();
        if (AggregatorV3Interface(config.baseTokenPriceFeed).decimals() != PRICE_FEED_DECIMALS) revert BadDecimals();
        if (config.reserveRate > FACTOR_SCALE) revert BadReserveRate();
        if (config.kink > FACTOR_SCALE) revert BadKink();

        // Copy configuration
        unchecked {
            governor = config.governor;
            pauseGuardian = config.pauseGuardian;
            baseToken = config.baseToken;
            baseTokenPriceFeed = config.baseTokenPriceFeed;
            extensionDelegate = config.extensionDelegate;
            storeFrontPriceFactor = config.storeFrontPriceFactor;

            decimals = decimals_;
            baseScale = uint64(10 ** decimals_);
            trackingIndexScale = config.trackingIndexScale;
            if (baseScale < BASE_ACCRUAL_SCALE) revert BadDecimals();
            accrualDescaleFactor = baseScale / BASE_ACCRUAL_SCALE;

            baseMinForRewards = config.baseMinForRewards;
            baseTrackingSupplySpeed = config.baseTrackingSupplySpeed;
            baseTrackingBorrowSpeed = config.baseTrackingBorrowSpeed;

            baseBorrowMin = config.baseBorrowMin;
            targetReserves = config.targetReserves;
        }

        // Set interest rate model configs
        unchecked {
            kink = config.kink;
            perSecondInterestRateSlopeLow = config.perYearInterestRateSlopeLow / SECONDS_PER_YEAR;
            perSecondInterestRateSlopeHigh = config.perYearInterestRateSlopeHigh / SECONDS_PER_YEAR;
            perSecondInterestRateBase = config.perYearInterestRateBase / SECONDS_PER_YEAR;
            reserveRate = config.reserveRate;
        }

        // Set asset info
        numAssets = uint8(config.assetConfigs.length);

        (asset00_a, asset00_b) = _getPackedAsset(config.assetConfigs, 0);
        (asset01_a, asset01_b) = _getPackedAsset(config.assetConfigs, 1);
        (asset02_a, asset02_b) = _getPackedAsset(config.assetConfigs, 2);
        (asset03_a, asset03_b) = _getPackedAsset(config.assetConfigs, 3);
        (asset04_a, asset04_b) = _getPackedAsset(config.assetConfigs, 4);
        (asset05_a, asset05_b) = _getPackedAsset(config.assetConfigs, 5);
        (asset06_a, asset06_b) = _getPackedAsset(config.assetConfigs, 6);
        (asset07_a, asset07_b) = _getPackedAsset(config.assetConfigs, 7);
        (asset08_a, asset08_b) = _getPackedAsset(config.assetConfigs, 8);
        (asset09_a, asset09_b) = _getPackedAsset(config.assetConfigs, 9);
        (asset10_a, asset10_b) = _getPackedAsset(config.assetConfigs, 10);
        (asset11_a, asset11_b) = _getPackedAsset(config.assetConfigs, 11);
        (asset12_a, asset12_b) = _getPackedAsset(config.assetConfigs, 12);
        (asset13_a, asset13_b) = _getPackedAsset(config.assetConfigs, 13);
        (asset14_a, asset14_b) = _getPackedAsset(config.assetConfigs, 14);
    }

    /**
     * @notice Initialize storage for the contract
     * @dev Can be used from constructor or proxy
     */
    function initializeStorage() override external {
        if (lastAccrualTime != 0) revert AlreadyInitialized();

        // Initialize aggregates
        lastAccrualTime = getNowInternal();
        baseSupplyIndex = BASE_INDEX_SCALE;
        baseBorrowIndex = BASE_INDEX_SCALE;

        // Implicit initialization (not worth increasing contract size)
        // trackingSupplyIndex = 0;
        // trackingBorrowIndex = 0;
    }

    /**
     * @dev Checks and gets the packed asset info for storage
     */
    function _getPackedAsset(AssetConfig[] memory assetConfigs, uint i) internal view returns (uint256, uint256) {
        AssetConfig memory assetConfig;
        if (i < assetConfigs.length) {
            assembly {
                assetConfig := mload(add(add(assetConfigs, 0x20), mul(i, 0x20)))
            }
        } else {
            return (0, 0);
        }
        address asset = assetConfig.asset;
        address priceFeed = assetConfig.priceFeed;
        uint8 decimals_ = assetConfig.decimals;

        // Short-circuit if asset is nil
        if (asset == address(0)) {
            return (0, 0);
        }

        // Sanity check price feed and asset decimals
        if (AggregatorV3Interface(priceFeed).decimals() != PRICE_FEED_DECIMALS) revert BadDecimals();
        if (ERC20(asset).decimals() != decimals_) revert BadDecimals();

        // Ensure collateral factors are within range
        if (assetConfig.borrowCollateralFactor >= assetConfig.liquidateCollateralFactor) revert BorrowCFTooLarge();
        if (assetConfig.liquidateCollateralFactor > MAX_COLLATERAL_FACTOR) revert LiquidateCFTooLarge();

        unchecked {
            // Keep 4 decimals for each factor
            uint descale = FACTOR_SCALE / 1e4;
            uint16 borrowCollateralFactor = uint16(assetConfig.borrowCollateralFactor / descale);
            uint16 liquidateCollateralFactor = uint16(assetConfig.liquidateCollateralFactor / descale);
            uint16 liquidationFactor = uint16(assetConfig.liquidationFactor / descale);

            // Be nice and check descaled values are still within range
            if (borrowCollateralFactor >= liquidateCollateralFactor) revert BorrowCFTooLarge();

            // Keep whole units of asset for supply cap
            uint64 supplyCap = uint64(assetConfig.supplyCap / (10 ** decimals_));

            uint256 word_a = (uint160(asset) << 0 |
                              uint256(borrowCollateralFactor) << 160 |
                              uint256(liquidateCollateralFactor) << 176 |
                              uint256(liquidationFactor) << 192);
            uint256 word_b = (uint160(priceFeed) << 0 |
                              uint256(decimals_) << 160 |
                              uint256(supplyCap) << 168);

            return (word_a, word_b);
        }
    }

    /**
     * @notice Get the i-th asset info, according to the order they were passed in originally
     * @param i The index of the asset info to get
     * @return The asset info object
     */
    function getAssetInfo(uint8 i) override public view returns (AssetInfo memory) {
        if (i >= numAssets) revert BadAsset();

        uint256 word_a;
        uint256 word_b;

        if (i == 0) {
            word_a = asset00_a;
            word_b = asset00_b;
        } else if (i == 1) {
            word_a = asset01_a;
            word_b = asset01_b;
        } else if (i == 2) {
            word_a = asset02_a;
            word_b = asset02_b;
        } else if (i == 3) {
            word_a = asset03_a;
            word_b = asset03_b;
        } else if (i == 4) {
            word_a = asset04_a;
            word_b = asset04_b;
        } else if (i == 5) {
            word_a = asset05_a;
            word_b = asset05_b;
        } else if (i == 6) {
            word_a = asset06_a;
            word_b = asset06_b;
        } else if (i == 7) {
            word_a = asset07_a;
            word_b = asset07_b;
        } else if (i == 8) {
            word_a = asset08_a;
            word_b = asset08_b;
        } else if (i == 9) {
            word_a = asset09_a;
            word_b = asset09_b;
        } else if (i == 10) {
            word_a = asset10_a;
            word_b = asset10_b;
        } else if (i == 11) {
            word_a = asset11_a;
            word_b = asset11_b;
        } else if (i == 12) {
            word_a = asset12_a;
            word_b = asset12_b;
        } else if (i == 13) {
            word_a = asset13_a;
            word_b = asset13_b;
        } else if (i == 14) {
            word_a = asset14_a;
            word_b = asset14_b;
        } else {
            revert Absurd();
        }

        address asset = address(uint160(word_a & type(uint160).max));
        uint rescale = FACTOR_SCALE / 1e4;
        uint64 borrowCollateralFactor = uint64(((word_a >> 160) & type(uint16).max) * rescale);
        uint64 liquidateCollateralFactor = uint64(((word_a >> 176) & type(uint16).max) * rescale);
        uint64 liquidationFactor = uint64(((word_a >> 192) & type(uint16).max) * rescale);

        address priceFeed = address(uint160(word_b & type(uint160).max));
        uint8 decimals_ = uint8(((word_b >> 160) & type(uint8).max));
        uint64 scale = uint64(10 ** decimals_);
        uint128 supplyCap = uint128(((word_b >> 168) & type(uint64).max) * scale);

        return AssetInfo({
            offset: i,
            asset: asset,
            priceFeed: priceFeed,
            scale: scale,
            borrowCollateralFactor: borrowCollateralFactor,
            liquidateCollateralFactor: liquidateCollateralFactor,
            liquidationFactor: liquidationFactor,
            supplyCap: supplyCap
         });
    }

    /**
     * @dev Determine index of asset that matches given address
     */
    function getAssetInfoByAddress(address asset) override public view returns (AssetInfo memory) {
        for (uint8 i = 0; i < numAssets; i++) {
            AssetInfo memory assetInfo = getAssetInfo(i);
            if (assetInfo.asset == asset) {
                return assetInfo;
            }
        }
        revert BadAsset();
    }

    /**
     * @return The current timestamp
     **/
    function getNowInternal() virtual internal view returns (uint40) {
        if (block.timestamp >= 2**40) revert TimestampTooLarge();
        return uint40(block.timestamp);
    }

    /**
     * @dev Calculate accrued interest indices for base token supply and borrows
     **/
    function accruedInterestIndices(uint timeElapsed) internal view returns (uint64, uint64) {
        uint64 baseSupplyIndex_ = baseSupplyIndex;
        uint64 baseBorrowIndex_ = baseBorrowIndex;
        if (timeElapsed > 0) {
            uint supplyRate = getSupplyRate();
            uint borrowRate = getBorrowRate();
            baseSupplyIndex_ += safe64(mulFactor(baseSupplyIndex_, supplyRate * timeElapsed));
            baseBorrowIndex_ += safe64(mulFactor(baseBorrowIndex_, borrowRate * timeElapsed));
        }
        return (baseSupplyIndex_, baseBorrowIndex_);
    }

    /**
     * @dev Accrue interest (and rewards) in base token supply and borrows
     **/
    function accrueInternal() internal {
        uint40 now_ = getNowInternal();
        uint timeElapsed = now_ - lastAccrualTime;
        if (timeElapsed > 0) {
            (baseSupplyIndex, baseBorrowIndex) = accruedInterestIndices(timeElapsed);
            if (totalSupplyBase >= baseMinForRewards) {
                uint supplySpeed = baseTrackingSupplySpeed;
                trackingSupplyIndex += safe64(divBaseWei(supplySpeed * timeElapsed, totalSupplyBase));
            }
            if (totalBorrowBase >= baseMinForRewards) {
                uint borrowSpeed = baseTrackingBorrowSpeed;
                trackingBorrowIndex += safe64(divBaseWei(borrowSpeed * timeElapsed, totalBorrowBase));
            }
            lastAccrualTime = now_;
        }
    }

    /**
     * @notice Accrue interest and rewards for an account
     **/
    function accrueAccount(address account) override external {
        accrueInternal();

        UserBasic memory basic = userBasic[account];
        updateBasePrincipal(account, basic, basic.principal);
    }

    /**
     * @dev Note: Does not accrue interest first
     * @return The current per second supply rate
     */
    function getSupplyRate() override public view returns (uint64) {
        uint utilization = getUtilization();
        uint reserveScalingFactor = utilization * (FACTOR_SCALE - reserveRate) / FACTOR_SCALE;
        if (utilization <= kink) {
            // (interestRateBase + interestRateSlopeLow * utilization) * utilization * (1 - reserveRate)
            return safe64(mulFactor(reserveScalingFactor, (perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, utilization))));
        } else {
            // (interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)) * utilization * (1 - reserveRate)
            return safe64(mulFactor(reserveScalingFactor, (perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, kink) + mulFactor(perSecondInterestRateSlopeHigh, (utilization - kink)))));
        }
    }

    /**
     * @dev Note: Does not accrue interest first
     * @return The current per second borrow rate
     */
    function getBorrowRate() override public view returns (uint64) {
        uint utilization = getUtilization();
        if (utilization <= kink) {
            // interestRateBase + interestRateSlopeLow * utilization
            return safe64(perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, utilization));
        } else {
            // interestRateBase + interestRateSlopeLow * kink + interestRateSlopeHigh * (utilization - kink)
            return safe64(perSecondInterestRateBase + mulFactor(perSecondInterestRateSlopeLow, kink) + mulFactor(perSecondInterestRateSlopeHigh, (utilization - kink)));
        }
    }

    /**
     * @dev Note: Does not accrue interest first
     * @return The utilization rate of the base asset
     */
    function getUtilization() override public view returns (uint) {
        uint totalSupply = presentValueSupply(baseSupplyIndex, totalSupplyBase);
        uint totalBorrow = presentValueBorrow(baseBorrowIndex, totalBorrowBase);
        if (totalSupply == 0) {
            return 0;
        } else {
            return totalBorrow * FACTOR_SCALE / totalSupply;
        }
    }

    /**
     * @notice Get the current price from a feed
     * @param priceFeed The address of a price feed
     * @return The price, scaled by `PRICE_SCALE`
     */
    function getPrice(address priceFeed) override public view returns (uint128) {
        (, int price, , , ) = AggregatorV3Interface(priceFeed).latestRoundData();
        if (price <= 0 || price > type(int128).max) revert BadPrice();
        return uint128(int128(price));
    }

    /**
     * @notice Gets the total amount of protocol reserves, denominated in the number of base tokens
     */
    function getReserves() override public view returns (int) {
        (uint64 baseSupplyIndex_, uint64 baseBorrowIndex_) = accruedInterestIndices(getNowInternal() - lastAccrualTime);
        uint balance = ERC20(baseToken).balanceOf(address(this));
        uint104 totalSupply = presentValueSupply(baseSupplyIndex_, totalSupplyBase);
        uint104 totalBorrow = presentValueBorrow(baseBorrowIndex_, totalBorrowBase);
        return signed256(balance) - signed104(totalSupply) + signed104(totalBorrow);
    }

    /**
     * @notice Check whether an account has enough collateral to borrow
     * @param account The address to check
     * @return Whether the account is minimally collateralized enough to borrow
     */
    function isBorrowCollateralized(address account) override public view returns (bool) {
        int104 principal = userBasic[account].principal;

        if (principal >= 0) {
            return true;
        }

        uint16 assetsIn = userBasic[account].assetsIn;
        int liquidity = signedMulPrice(
            presentValue(principal),
            getPrice(baseTokenPriceFeed),
            uint64(baseScale)
        );

        for (uint8 i = 0; i < numAssets; i++) {
            if (isInAsset(assetsIn, i)) {
                if (liquidity >= 0) {
                    return true;
                }

                AssetInfo memory asset = getAssetInfo(i);
                uint newAmount = mulPrice(
                    userCollateral[account][asset.asset].balance,
                    getPrice(asset.priceFeed),
                    asset.scale
                );
                liquidity += signed256(mulFactor(
                    newAmount,
                    asset.borrowCollateralFactor
                ));
            }
        }

        return liquidity >= 0;
    }

    /**
     * @notice Calculate the amount of borrow liquidity for account
     * @param account The address to check liquidity for
     * @return The common price quantity of borrow liquidity
     */
    function getBorrowLiquidity(address account) override external view returns (int) {
        uint16 assetsIn = userBasic[account].assetsIn;

        int liquidity = signedMulPrice(
            presentValue(userBasic[account].principal),
            getPrice(baseTokenPriceFeed),
            uint64(baseScale)
        );

        for (uint8 i = 0; i < numAssets; i++) {
            if (isInAsset(assetsIn, i)) {
                AssetInfo memory asset = getAssetInfo(i);
                uint newAmount = mulPrice(
                    userCollateral[account][asset.asset].balance,
                    getPrice(asset.priceFeed),
                    asset.scale
                );
                liquidity += signed256(mulFactor(
                    newAmount,
                    asset.borrowCollateralFactor
                ));
            }
        }

        return liquidity;
    }

    /**
     * @notice Check whether an account has enough collateral to not be liquidated
     * @param account The address to check
     * @return Whether the account is minimally collateralized enough to not be liquidated
     */
    function isLiquidatable(address account) override public view returns (bool) {
        int104 principal = userBasic[account].principal;

        if (principal >= 0) {
            return false;
        }

        uint16 assetsIn = userBasic[account].assetsIn;
        int liquidity = signedMulPrice(
            presentValue(principal),
            getPrice(baseTokenPriceFeed),
            uint64(baseScale)
        );

        for (uint8 i = 0; i < numAssets; i++) {
            if (isInAsset(assetsIn, i)) {
                if (liquidity >= 0) {
                    return false;
                }

                AssetInfo memory asset = getAssetInfo(i);
                uint newAmount = mulPrice(
                    userCollateral[account][asset.asset].balance,
                    getPrice(asset.priceFeed),
                    asset.scale
                );
                liquidity += signed256(mulFactor(
                    newAmount,
                    asset.liquidateCollateralFactor
                ));
            }
        }

        return liquidity < 0;
    }

    /**
     * @notice Calculate the amount of liquidation margin for account
     * @param account The address to check margin for
     * @return The common price quantity of liquidation margin
     */
    function getLiquidationMargin(address account) override external view returns (int) {
        uint16 assetsIn = userBasic[account].assetsIn;

        int liquidity = signedMulPrice(
            presentValue(userBasic[account].principal),
            getPrice(baseTokenPriceFeed),
            uint64(baseScale)
        );

        for (uint8 i = 0; i < numAssets; i++) {
            if (isInAsset(assetsIn, i)) {
                AssetInfo memory asset = getAssetInfo(i);
                uint newAmount = mulPrice(
                    userCollateral[account][asset.asset].balance,
                    getPrice(asset.priceFeed),
                    asset.scale
                );
                liquidity += signed256(mulFactor(
                    newAmount,
                    asset.liquidateCollateralFactor
                ));
            }
        }

        return liquidity;
    }

    /**
     * @dev The change in principal broken into repay and supply amounts
     * @dev Note: The assumption `newPrincipal >= oldPrincipal` MUST be true
     */
    function repayAndSupplyAmount(int104 oldPrincipal, int104 newPrincipal) internal pure returns (uint104, uint104) {
        if (newPrincipal <= 0) {
            return (uint104(newPrincipal - oldPrincipal), 0);
        } else if (oldPrincipal >= 0) {
            return (0, uint104(newPrincipal - oldPrincipal));
        } else {
            return (uint104(-oldPrincipal), uint104(newPrincipal));
        }
    }

    /**
     * @dev The change in principal broken into withdraw and borrow amounts
     * @dev Note: The assumption `oldPrincipal >= newPrincipal` MUST be true
     */
    function withdrawAndBorrowAmount(int104 oldPrincipal, int104 newPrincipal) internal view returns (uint104, uint104) {
        if (newPrincipal >= 0) {
            return (uint104(oldPrincipal - newPrincipal), 0);
        } else if (oldPrincipal <= 0) {
            return (0, uint104(oldPrincipal - newPrincipal));
        } else {
            return (uint104(oldPrincipal), uint104(-newPrincipal));
        }
    }

    /**
     * @notice Pauses different actions within Comet
     * @param supplyPaused Boolean for pausing supply actions
     * @param transferPaused Boolean for pausing transfer actions
     * @param withdrawPaused Boolean for pausing withdraw actions
     * @param absorbPaused Boolean for pausing absorb actions
     * @param buyPaused Boolean for pausing buy actions
     */
    function pause(
        bool supplyPaused,
        bool transferPaused,
        bool withdrawPaused,
        bool absorbPaused,
        bool buyPaused
    ) override external {
        if (msg.sender != governor && msg.sender != pauseGuardian) revert Unauthorized();

        pauseFlags =
            uint8(0) |
            (toUInt8(supplyPaused) << PAUSE_SUPPLY_OFFSET) |
            (toUInt8(transferPaused) << PAUSE_TRANSFER_OFFSET) |
            (toUInt8(withdrawPaused) << PAUSE_WITHDRAW_OFFSET) |
            (toUInt8(absorbPaused) << PAUSE_ABSORB_OFFSET) |
            (toUInt8(buyPaused) << PAUSE_BUY_OFFSET);

        emit PauseAction(supplyPaused, transferPaused, withdrawPaused, absorbPaused, buyPaused);
    }

    /**
     * @return Whether or not supply actions are paused
     */
    function isSupplyPaused() override public view returns (bool) {
        return toBool(pauseFlags & (uint8(1) << PAUSE_SUPPLY_OFFSET));
    }

    /**
     * @return Whether or not transfer actions are paused
     */
    function isTransferPaused() override public view returns (bool) {
        return toBool(pauseFlags & (uint8(1) << PAUSE_TRANSFER_OFFSET));
    }

    /**
     * @return Whether or not withdraw actions are paused
     */
    function isWithdrawPaused() override public view returns (bool) {
        return toBool(pauseFlags & (uint8(1) << PAUSE_WITHDRAW_OFFSET));
    }

    /**
     * @return Whether or not absorb actions are paused
     */
    function isAbsorbPaused() override public view returns (bool) {
        return toBool(pauseFlags & (uint8(1) << PAUSE_ABSORB_OFFSET));
    }

    /**
     * @return Whether or not buy actions are paused
     */
    function isBuyPaused() override public view returns (bool) {
        return toBool(pauseFlags & (uint8(1) << PAUSE_BUY_OFFSET));
    }

    /**
     * @dev Multiply a number by a factor
     */
    function mulFactor(uint n, uint factor) internal pure returns (uint) {
        return n * factor / FACTOR_SCALE;
    }

    /**
     * @dev Divide a number by an amount of base
     */
    function divBaseWei(uint n, uint baseWei) internal view returns (uint) {
        return n * baseScale / baseWei;
    }

    /**
     * @dev Multiply a `fromScale` quantity by a price, returning a common price quantity
     */
    function mulPrice(uint128 n, uint128 price, uint64 fromScale) internal pure returns (uint) {
        unchecked {
            return uint256(n) * price / fromScale;
        }
    }

    /**
     * @dev Multiply a signed `fromScale` quantity by a price, returning a common price quantity
     */
    function signedMulPrice(int128 n, uint128 price, uint64 fromScale) internal pure returns (int) {
        unchecked {
            return n * signed256(price) / signed256(fromScale);
        }
    }

    /**
     * @dev Divide a common price quantity by a price, returning a `toScale` quantity
     */
    function divPrice(uint n, uint price, uint64 toScale) internal pure returns (uint) {
        return n * toScale / price;
    }

    /**
     * @dev Whether user has a non-zero balance of an asset, given assetsIn flags
     */
    function isInAsset(uint16 assetsIn, uint8 assetOffset) internal pure returns (bool) {
        return (assetsIn & (uint16(1) << assetOffset) != 0);
    }

    /**
     * @dev Update assetsIn bit vector if user has entered or exited an asset
     */
    function updateAssetsIn(
        address account,
        AssetInfo memory assetInfo,
        uint128 initialUserBalance,
        uint128 finalUserBalance
    ) internal {
        if (initialUserBalance == 0 && finalUserBalance != 0) {
            // set bit for asset
            userBasic[account].assetsIn |= (uint16(1) << assetInfo.offset);
        } else if (initialUserBalance != 0 && finalUserBalance == 0) {
            // clear bit for asset
            userBasic[account].assetsIn &= ~(uint16(1) << assetInfo.offset);
        }
    }

    /**
     * @dev Write updated principal to store and tracking participation
     */
    function updateBasePrincipal(address account, UserBasic memory basic, int104 principalNew) internal {
        int104 principal = basic.principal;
        basic.principal = principalNew;

        if (principal >= 0) {
            uint indexDelta = trackingSupplyIndex - basic.baseTrackingIndex;
            basic.baseTrackingAccrued += safe64(uint104(principal) * indexDelta / trackingIndexScale / accrualDescaleFactor);
        } else {
            uint indexDelta = trackingBorrowIndex - basic.baseTrackingIndex;
            basic.baseTrackingAccrued += safe64(uint104(-principal) * indexDelta / trackingIndexScale / accrualDescaleFactor);
        }

        if (principalNew >= 0) {
            basic.baseTrackingIndex = trackingSupplyIndex;
        } else {
            basic.baseTrackingIndex = trackingBorrowIndex;
        }

        userBasic[account] = basic;
    }

    /**
     * @dev Safe ERC20 transfer in, assumes no fee is charged and amount is transferred
     */
    function doTransferIn(address asset, address from, uint amount) internal {
        bool success = ERC20(asset).transferFrom(from, address(this), amount);
        if (!success) revert TransferInFailed();
    }

    /**
     * @dev Safe ERC20 transfer out
     */
    function doTransferOut(address asset, address to, uint amount) internal {
        bool success = ERC20(asset).transfer(to, amount);
        if (!success) revert TransferOutFailed();
    }

    /**
     * @notice Supply an amount of asset to the protocol
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supply(address asset, uint amount) override external {
        return supplyInternal(msg.sender, msg.sender, msg.sender, asset, amount);
    }

    /**
     * @notice Supply an amount of asset to dst
     * @param dst The address which will hold the balance
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supplyTo(address dst, address asset, uint amount) override external {
        return supplyInternal(msg.sender, msg.sender, dst, asset, amount);
    }

    /**
     * @notice Supply an amount of asset from `from` to dst, if allowed
     * @param from The supplier address
     * @param dst The address which will hold the balance
     * @param asset The asset to supply
     * @param amount The quantity to supply
     */
    function supplyFrom(address from, address dst, address asset, uint amount) override external {
        return supplyInternal(msg.sender, from, dst, asset, amount);
    }

    /**
     * @dev Supply either collateral or base asset, depending on the asset, if operator is allowed
     */
    function supplyInternal(address operator, address from, address dst, address asset, uint amount) internal {
        if (isSupplyPaused()) revert Paused();
        if (!hasPermission(from, operator)) revert Unauthorized();

        if (asset == baseToken) {
            return supplyBase(from, dst, safe104(amount));
        } else {
            return supplyCollateral(from, dst, asset, safe128(amount));
        }
    }

    /**
     * @dev Supply an amount of base asset from `from` to dst
     */
    function supplyBase(address from, address dst, uint104 amount) internal {
        doTransferIn(baseToken, from, amount);

        accrueInternal();

        UserBasic memory dstUser = userBasic[dst];
        int104 dstPrincipal = dstUser.principal;
        int104 dstBalance = presentValue(dstPrincipal) + signed104(amount);
        int104 dstPrincipalNew = principalValue(dstBalance);

        (uint104 repayAmount, uint104 supplyAmount) = repayAndSupplyAmount(dstPrincipal, dstPrincipalNew);

        totalSupplyBase += supplyAmount;
        totalBorrowBase -= repayAmount;

        updateBasePrincipal(dst, dstUser, dstPrincipalNew);

        emit Supply(from, dst, amount);
        emit Transfer(address(0), dst, amount);
    }

    /**
     * @dev Supply an amount of collateral asset from `from` to dst
     */
    function supplyCollateral(address from, address dst, address asset, uint128 amount) internal {
        doTransferIn(asset, from, amount);

        AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        TotalsCollateral memory totals = totalsCollateral[asset];
        totals.totalSupplyAsset += amount;
        if (totals.totalSupplyAsset > assetInfo.supplyCap) revert SupplyCapExceeded();

        uint128 dstCollateral = userCollateral[dst][asset].balance;
        uint128 dstCollateralNew = dstCollateral + amount;

        totalsCollateral[asset] = totals;
        userCollateral[dst][asset].balance = dstCollateralNew;

        updateAssetsIn(dst, assetInfo, dstCollateral, dstCollateralNew);

        emit SupplyCollateral(from, dst, asset, amount);
    }

    /**
     * @notice ERC20 transfer an amount of base token to dst
     * @param dst The recipient address
     * @param amount The quantity to transfer
     * @return true
     */
    function transfer(address dst, uint amount) override external returns (bool) {
        transferInternal(msg.sender, msg.sender, dst, baseToken, amount);
        return true;
    }

    /**
     * @notice ERC20 transfer an amount of base token from src to dst, if allowed
     * @param src The sender address
     * @param dst The recipient address
     * @param amount The quantity to transfer
     * @return true
     */
    function transferFrom(address src, address dst, uint amount) override external returns (bool) {
        transferInternal(msg.sender, src, dst, baseToken, amount);
        return true;
    }

    /**
     * @notice Transfer an amount of asset to dst
     * @param dst The recipient address
     * @param asset The asset to transfer
     * @param amount The quantity to transfer
     */
    function transferAsset(address dst, address asset, uint amount) override external {
        return transferInternal(msg.sender, msg.sender, dst, asset, amount);
    }

    /**
     * @notice Transfer an amount of asset from src to dst, if allowed
     * @param src The sender address
     * @param dst The recipient address
     * @param asset The asset to transfer
     * @param amount The quantity to transfer
     */
    function transferAssetFrom(address src, address dst, address asset, uint amount) override external {
        return transferInternal(msg.sender, src, dst, asset, amount);
    }

    /**
     * @dev Transfer either collateral or base asset, depending on the asset, if operator is allowed
     */
    function transferInternal(address operator, address src, address dst, address asset, uint amount) internal {
        if (isTransferPaused()) revert Paused();
        if (!hasPermission(src, operator)) revert Unauthorized();
        if (src == dst) revert NoSelfTransfer();

        if (asset == baseToken) {
            return transferBase(src, dst, safe104(amount));
        } else {
            return transferCollateral(src, dst, asset, safe128(amount));
        }
    }

    /**
     * @dev Transfer an amount of base asset from src to dst, borrowing if possible/necessary
     */
    function transferBase(address src, address dst, uint104 amount) internal {
        accrueInternal();

        UserBasic memory srcUser = userBasic[src];
        UserBasic memory dstUser = userBasic[dst];

        int104 srcPrincipal = srcUser.principal;
        int104 dstPrincipal = dstUser.principal;
        int104 srcBalance = presentValue(srcPrincipal) - signed104(amount);
        int104 dstBalance = presentValue(dstPrincipal) + signed104(amount);
        int104 srcPrincipalNew = principalValue(srcBalance);
        int104 dstPrincipalNew = principalValue(dstBalance);

        (uint104 withdrawAmount, uint104 borrowAmount) = withdrawAndBorrowAmount(srcPrincipal, srcPrincipalNew);
        (uint104 repayAmount, uint104 supplyAmount) = repayAndSupplyAmount(dstPrincipal, dstPrincipalNew);

        // Note: Instead of `total += addAmount - subAmount` to avoid underflow errors.
        totalSupplyBase = totalSupplyBase + supplyAmount - withdrawAmount;
        totalBorrowBase = totalBorrowBase + borrowAmount - repayAmount;

        updateBasePrincipal(src, srcUser, srcPrincipalNew);
        updateBasePrincipal(dst, dstUser, dstPrincipalNew);

        if (srcBalance < 0) {
            if (uint104(-srcBalance) < baseBorrowMin) revert BorrowTooSmall();
            if (!isBorrowCollateralized(src)) revert NotCollateralized();
        }

        emit Transfer(src, dst, amount);
    }

    /**
     * @dev Transfer an amount of collateral asset from src to dst
     */
    function transferCollateral(address src, address dst, address asset, uint128 amount) internal {
        uint128 srcCollateral = userCollateral[src][asset].balance;
        uint128 dstCollateral = userCollateral[dst][asset].balance;
        uint128 srcCollateralNew = srcCollateral - amount;
        uint128 dstCollateralNew = dstCollateral + amount;

        userCollateral[src][asset].balance = srcCollateralNew;
        userCollateral[dst][asset].balance = dstCollateralNew;

        AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        updateAssetsIn(src, assetInfo, srcCollateral, srcCollateralNew);
        updateAssetsIn(dst, assetInfo, dstCollateral, dstCollateralNew);

        // Note: no accrue interest, BorrowCF < LiquidationCF covers small changes
        if (!isBorrowCollateralized(src)) revert NotCollateralized();

        emit TransferCollateral(src, dst, asset, amount);
    }

    /**
     * @notice Withdraw an amount of asset from the protocol
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdraw(address asset, uint amount) override external {
        return withdrawInternal(msg.sender, msg.sender, msg.sender, asset, amount);
    }

    /**
     * @notice Withdraw an amount of asset to `to`
     * @param to The recipient address
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdrawTo(address to, address asset, uint amount) override external {
        return withdrawInternal(msg.sender, msg.sender, to, asset, amount);
    }

    /**
     * @notice Withdraw an amount of asset from src to `to`, if allowed
     * @param src The sender address
     * @param to The recipient address
     * @param asset The asset to withdraw
     * @param amount The quantity to withdraw
     */
    function withdrawFrom(address src, address to, address asset, uint amount) override external {
        return withdrawInternal(msg.sender, src, to, asset, amount);
    }

    /**
     * @dev Withdraw either collateral or base asset, depending on the asset, if operator is allowed
     */
    function withdrawInternal(address operator, address src, address to, address asset, uint amount) internal {
        if (isWithdrawPaused()) revert Paused();
        if (!hasPermission(src, operator)) revert Unauthorized();

        if (asset == baseToken) {
            return withdrawBase(src, to, safe104(amount));
        } else {
            return withdrawCollateral(src, to, asset, safe128(amount));
        }
    }

    /**
     * @dev Withdraw an amount of base asset from src to `to`, borrowing if possible/necessary
     */
    function withdrawBase(address src, address to, uint104 amount) internal {
        accrueInternal();

        UserBasic memory srcUser = userBasic[src];
        int104 srcPrincipal = srcUser.principal;
        int104 srcBalance = presentValue(srcPrincipal) - signed104(amount);
        int104 srcPrincipalNew = principalValue(srcBalance);

        (uint104 withdrawAmount, uint104 borrowAmount) = withdrawAndBorrowAmount(srcPrincipal, srcPrincipalNew);

        totalSupplyBase -= withdrawAmount;
        totalBorrowBase += borrowAmount;

        updateBasePrincipal(src, srcUser, srcPrincipalNew);

        if (srcBalance < 0) {
            if (uint104(-srcBalance) < baseBorrowMin) revert BorrowTooSmall();
            if (!isBorrowCollateralized(src)) revert NotCollateralized();
        }

        doTransferOut(baseToken, to, amount);

        emit Withdraw(src, to, amount);
        emit Transfer(src, address(0), amount);
    }

    /**
     * @dev Withdraw an amount of collateral asset from src to `to`
     */
    function withdrawCollateral(address src, address to, address asset, uint128 amount) internal {
        uint128 srcCollateral = userCollateral[src][asset].balance;
        uint128 srcCollateralNew = srcCollateral - amount;

        totalsCollateral[asset].totalSupplyAsset -= amount;
        userCollateral[src][asset].balance = srcCollateralNew;

        AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        updateAssetsIn(src, assetInfo, srcCollateral, srcCollateralNew);

        // Note: no accrue interest, BorrowCF < LiquidationCF covers small changes
        if (!isBorrowCollateralized(src)) revert NotCollateralized();

        doTransferOut(asset, to, amount);

        emit WithdrawCollateral(src, to, asset, amount);
    }

    /**
     * @notice Absorb a list of underwater accounts onto the protocol balance sheet
     * @param absorber The recipient of the incentive paid to the caller of absorb
     * @param accounts The list of underwater accounts to absorb
     */
    function absorb(address absorber, address[] calldata accounts) override external {
        if (isAbsorbPaused()) revert Paused();

        uint startGas = gasleft();
        accrueInternal();
        for (uint i = 0; i < accounts.length; i++) {
            absorbInternal(absorber, accounts[i]);
        }
        uint gasUsed = startGas - gasleft();

        LiquidatorPoints memory points = liquidatorPoints[absorber];
        points.numAbsorbs++;
        points.numAbsorbed += safe64(accounts.length);
        points.approxSpend += safe128(gasUsed * block.basefee);
        liquidatorPoints[absorber] = points;
    }

    /**
     * @dev Transfer user's collateral and debt to the protocol itself.
     */
    function absorbInternal(address absorber, address account) internal {
        if (!isLiquidatable(account)) revert NotLiquidatable();

        UserBasic memory accountUser = userBasic[account];
        int104 oldPrincipal = accountUser.principal;
        int104 oldBalance = presentValue(oldPrincipal);
        uint16 assetsIn = accountUser.assetsIn;

        uint128 basePrice = getPrice(baseTokenPriceFeed);
        uint deltaValue = 0;

        for (uint8 i = 0; i < numAssets; i++) {
            if (isInAsset(assetsIn, i)) {
                AssetInfo memory assetInfo = getAssetInfo(i);
                address asset = assetInfo.asset;
                uint128 seizeAmount = userCollateral[account][asset].balance;
                userCollateral[account][asset].balance = 0;
                userCollateral[address(this)][asset].balance += seizeAmount;

                uint value = mulPrice(seizeAmount, getPrice(assetInfo.priceFeed), assetInfo.scale);
                deltaValue += mulFactor(value, assetInfo.liquidationFactor);

                emit AbsorbCollateral(absorber, account, asset, seizeAmount, value);
            }
        }

        uint104 deltaBalance = safe104(divPrice(deltaValue, basePrice, uint64(baseScale)));
        int104 newBalance = oldBalance + signed104(deltaBalance);
        // New balance will not be negative, all excess debt absorbed by reserves
        if (newBalance < 0) {
            newBalance = 0;
        }

        int104 newPrincipal = principalValue(newBalance);
        updateBasePrincipal(account, accountUser, newPrincipal);

        // reset assetsIn
        userBasic[account].assetsIn = 0;

        (uint104 repayAmount, uint104 supplyAmount) = repayAndSupplyAmount(oldPrincipal, newPrincipal);

        // Reserves are decreased by increasing total supply and decreasing borrows
        //  the amount of debt repaid by reserves is `newBalance - oldBalance`
        totalSupplyBase += supplyAmount;
        totalBorrowBase -= repayAmount;

        uint104 debtAbsorbed = unsigned104(newBalance - oldBalance);
        uint valueOfDebtAbsorbed = mulPrice(debtAbsorbed, basePrice, uint64(baseScale));
        emit AbsorbDebt(absorber, account, debtAbsorbed, valueOfDebtAbsorbed);
    }

    /**
     * @notice Buy collateral from the protocol using base tokens, increasing protocol reserves
       A minimum collateral amount should be specified to indicate the maximum slippage acceptable for the buyer.
     * @param asset The asset to buy
     * @param minAmount The minimum amount of collateral tokens that should be received by the buyer
     * @param baseAmount The amount of base tokens used to buy the collateral
     * @param recipient The recipient address
     */
    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) override external {
        if (isBuyPaused()) revert Paused();

        int reserves = getReserves();
        if (reserves >= 0 && uint(reserves) >= targetReserves) revert NotForSale();

        // Note: Re-entrancy can skip the reserves check above on a second buyCollateral call.
        doTransferIn(baseToken, msg.sender, baseAmount);

        uint collateralAmount = quoteCollateral(asset, baseAmount);
        if (collateralAmount < minAmount) revert TooMuchSlippage();

        // Note: Pre-transfer hook can re-enter buyCollateral with a stale collateral ERC20 balance.
        //       This is a problem if quoteCollateral derives its discount from the collateral ERC20 balance.
        withdrawCollateral(address(this), recipient, asset, safe128(collateralAmount));

        emit BuyCollateral(msg.sender, asset, baseAmount, collateralAmount);
    }

    /**
     * @notice Gets the quote for a collateral asset in exchange for an amount of base asset
     * @param asset The collateral asset to get the quote for
     * @param baseAmount The amount of the base asset to get the quote for
     * @return The quote in terms of the collateral asset
     */
    function quoteCollateral(address asset, uint baseAmount) override public view returns (uint) {
        AssetInfo memory assetInfo = getAssetInfoByAddress(asset);
        uint128 assetPrice = getPrice(assetInfo.priceFeed);
        // Store front discount is derived from the collateral asset's liquidationFactor and storeFrontPriceFactor
        // discount = storeFrontPriceFactor * (1e18 - liquidationFactor)
        uint discountFactor = mulFactor(storeFrontPriceFactor, FACTOR_SCALE - assetInfo.liquidationFactor);
        uint128 assetPriceDiscounted = uint128(mulFactor(assetPrice, FACTOR_SCALE - discountFactor));
        uint128 basePrice = getPrice(baseTokenPriceFeed);
        // # of collateral assets
        // = (TotalValueOfBaseAmount / DiscountedPriceOfCollateralAsset) * assetScale
        // = ((basePrice * baseAmount / baseScale) / assetPriceDiscounted) * assetScale
        return basePrice * baseAmount * assetInfo.scale / assetPriceDiscounted / baseScale;
    }

    /**
     * @notice Withdraws base token reserves if called by the governor
     * @param to An address of the receiver of withdrawn reserves
     * @param amount The amount of reserves to be withdrawn from the protocol
     */
    function withdrawReserves(address to, uint amount) override external {
        if (msg.sender != governor) revert Unauthorized();

        int reserves = getReserves();
        if (reserves < 0 || amount > unsigned256(reserves)) revert InsufficientReserves();

        doTransferOut(baseToken, to, amount);
    }

    /**
     * @notice Sets Comet's ERC20 allowance of an asset for a manager
     * @dev Only callable by governor
     * @dev Note: Setting the `asset` as Comet's address will allow the manager
     * to withdraw from Comet's Comet balance
     * @param asset The asset that the manager will gain approval of
     * @param manager The account which will be allowed or disallowed
     * @param amount The amount of an asset to approve
     */
    function approveThis(address manager, address asset, uint amount) override external {
        if (msg.sender != governor) revert Unauthorized();

        ERC20(asset).approve(manager, amount);
    }

    /**
     * @notice Get the total number of tokens in circulation
     * @dev Note: uses updated interest indices to calculate
     * @return The supply of tokens
     **/
    function totalSupply() override external view returns (uint256) {
        (uint64 baseSupplyIndex_, ) = accruedInterestIndices(getNowInternal() - lastAccrualTime);
        return presentValueSupply(baseSupplyIndex_, totalSupplyBase);
    }

    /**
     * @notice Get the total amount of debt
     * @dev Note: uses updated interest indices to calculate
     * @return The amount of debt
     **/
    function totalBorrow() override external view returns (uint256) {
        (, uint64 baseBorrowIndex_) = accruedInterestIndices(getNowInternal() - lastAccrualTime);
        return presentValueBorrow(baseBorrowIndex_, totalBorrowBase);
    }

    /**
     * @notice Query the current positive base balance of an account or zero
     * @dev Note: uses updated interest indices to calculate
     * @param account The account whose balance to query
     * @return The present day base balance magnitude of the account, if positive
     */
    function balanceOf(address account) override external view returns (uint256) {
        (uint64 baseSupplyIndex_, ) = accruedInterestIndices(getNowInternal() - lastAccrualTime);
        int104 principal = userBasic[account].principal;
        return principal > 0 ? presentValueSupply(baseSupplyIndex_, unsigned104(principal)) : 0;
    }

    /**
     * @notice Query the current negative base balance of an account or zero
     * @dev Note: uses updated interest indices to calculate
     * @param account The account whose balance to query
     * @return The present day base balance magnitude of the account, if negative
     */
    function borrowBalanceOf(address account) override external view returns (uint256) {
        (, uint64 baseBorrowIndex_) = accruedInterestIndices(getNowInternal() - lastAccrualTime);
        int104 principal = userBasic[account].principal;
        return principal < 0 ? presentValueBorrow(baseBorrowIndex_, unsigned104(-principal)) : 0;
    }

    /**
     * @notice Fallback to calling the extension delegate for everything else
     */
    fallback() external payable {
        address delegate = extensionDelegate;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), delegate, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CometCore.sol";

/**
 * @title Compound's Comet Main Interface (without Ext)
 * @notice An efficient monolithic money market protocol
 * @author Compound
 */
abstract contract CometMainInterface is CometCore {
    event Supply(address indexed from, address indexed dst, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed src, address indexed to, uint256 amount);

    event SupplyCollateral(address indexed from, address indexed dst, address indexed asset, uint256 amount);
    event TransferCollateral(address indexed from, address indexed to, address indexed asset, uint256 amount);
    event WithdrawCollateral(address indexed src, address indexed to, address indexed asset, uint256 amount);

    /// @notice Event emitted when an action is paused/unpaused
    event PauseAction(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused);
    /// @notice Event emitted when a borrow position is absorbed by the protocol
    event AbsorbDebt(address indexed absorber, address indexed borrower, uint104 debtAbsorbed, uint usdValue);
    /// @notice Event emitted when a user's collateral is absorbed by the protocol
    event AbsorbCollateral(address indexed absorber, address indexed borrower, address indexed asset, uint128 collateralAbsorbed, uint usdValue);
    /// @notice Event emitted when a collateral asset is purchased from the protocol
    event BuyCollateral(address indexed buyer, address indexed asset, uint baseAmount, uint collateralAmount);

    function supply(address asset, uint amount) virtual external;
    function supplyTo(address dst, address asset, uint amount) virtual external;
    function supplyFrom(address from, address dst, address asset, uint amount) virtual external;

    function transfer(address dst, uint amount) virtual external returns (bool);
    function transferFrom(address src, address dst, uint amount) virtual external returns (bool);

    function transferAsset(address dst, address asset, uint amount) virtual external;
    function transferAssetFrom(address src, address dst, address asset, uint amount) virtual external;

    function withdraw(address asset, uint amount) virtual external;
    function withdrawTo(address to, address asset, uint amount) virtual external;
    function withdrawFrom(address src, address to, address asset, uint amount) virtual external;

    function approveThis(address manager, address asset, uint amount) virtual external;
    function withdrawReserves(address to, uint amount) virtual external;

    function absorb(address absorber, address[] calldata accounts) virtual external;
    function buyCollateral(address asset, uint minAmount, uint baseAmount, address recipient) virtual external;
    function quoteCollateral(address asset, uint baseAmount) virtual public view returns (uint);

    function getAssetInfo(uint8 i) virtual public view returns (AssetInfo memory);
    function getAssetInfoByAddress(address asset) virtual public view returns (AssetInfo memory);
    function getReserves() virtual public view returns (int);
    function getPrice(address priceFeed) virtual public view returns (uint128);

    function isBorrowCollateralized(address account) virtual public view returns (bool);
    function isLiquidatable(address account) virtual public view returns (bool);
    function getBorrowLiquidity(address account) virtual external view returns (int);
    function getLiquidationMargin(address account) virtual external view returns (int);

    function totalSupply() virtual external view returns (uint256);
    function totalBorrow() virtual external view returns (uint256);
    function balanceOf(address owner) virtual external view returns (uint256);
    function borrowBalanceOf(address account) virtual external view returns (uint256);

    function pause(bool supplyPaused, bool transferPaused, bool withdrawPaused, bool absorbPaused, bool buyPaused) virtual external;
    function isSupplyPaused() virtual public view returns (bool);
    function isTransferPaused() virtual public view returns (bool);
    function isWithdrawPaused() virtual public view returns (bool);
    function isAbsorbPaused() virtual public view returns (bool);
    function isBuyPaused() virtual public view returns (bool);

    function accrueAccount(address account) virtual external;
    function getSupplyRate() virtual public view returns (uint64);
    function getBorrowRate() virtual public view returns (uint64);
    function getUtilization() virtual public view returns (uint);

    function governor() virtual external view returns (address);
    function pauseGuardian() virtual external view returns (address);
    function baseToken() virtual external view returns (address);
    function baseTokenPriceFeed() virtual external view returns (address);
    function extensionDelegate() virtual external view returns (address);

    /// @dev uint64
    function kink() virtual external view returns (uint);
    /// @dev uint64
    function perSecondInterestRateSlopeLow() virtual external view returns (uint);
    /// @dev uint64
    function perSecondInterestRateSlopeHigh() virtual external view returns (uint);
    /// @dev uint64
    function perSecondInterestRateBase() virtual external view returns (uint);
    /// @dev uint64
    function reserveRate() virtual external view returns (uint);
    /// @dev uint64
    function storeFrontPriceFactor() virtual external view returns (uint);

    /// @dev uint64
    function baseScale() virtual external view returns (uint);
    /// @dev uint64
    function trackingIndexScale() virtual external view returns (uint);

    /// @dev uint64
    function baseTrackingSupplySpeed() virtual external view returns (uint);
    /// @dev uint64
    function baseTrackingBorrowSpeed() virtual external view returns (uint);
    /// @dev uint104
    function baseMinForRewards() virtual external view returns (uint);
    /// @dev uint104
    function baseBorrowMin() virtual external view returns (uint);
    /// @dev uint104
    function targetReserves() virtual external view returns (uint);

    function numAssets() virtual external view returns (uint8);
    function decimals() virtual external view returns (uint8);

    function initializeStorage() virtual external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface ERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

import "./CometConfiguration.sol";
import "./CometStorage.sol";
import "./CometMath.sol";
import "./vendor/@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract CometCore is CometConfiguration, CometStorage, CometMath {
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

    /** Internal constants **/

    /// @dev The max number of assets this contract is hardcoded to support
    ///  Do not change this variable without updating all the fields throughout the contract,
    //    including the size of UserBasic.assetsIn and corresponding integer conversions.
    uint8 internal constant MAX_ASSETS = 15;

    /// @dev The max number of decimals base token can have
    ///  Note this cannot just be increased arbitrarily.
    uint8 internal constant MAX_BASE_DECIMALS = 18;

    /// @dev The max value for a collateral factor (1)
    uint64 internal constant MAX_COLLATERAL_FACTOR = FACTOR_SCALE;

    /// @dev Offsets for specific actions in the pause flag bit array
    uint8 internal constant PAUSE_SUPPLY_OFFSET = 0;
    uint8 internal constant PAUSE_TRANSFER_OFFSET = 1;
    uint8 internal constant PAUSE_WITHDRAW_OFFSET = 2;
    uint8 internal constant PAUSE_ABSORB_OFFSET = 3;
    uint8 internal constant PAUSE_BUY_OFFSET = 4;

    /// @dev The decimals required for a price feed
    uint8 internal constant PRICE_FEED_DECIMALS = 8;

    /// @dev 365 days * 24 hours * 60 minutes * 60 seconds
    uint64 internal constant SECONDS_PER_YEAR = 31_536_000;

    /// @dev The scale for base tracking accrual
    uint64 internal constant BASE_ACCRUAL_SCALE = 1e6;

    /// @dev The scale for base index (depends on time/rate scales, not base token)
    uint64 internal constant BASE_INDEX_SCALE = 1e15;

    /// @dev The scale for prices (in USD)
    uint64 internal constant PRICE_SCALE = uint64(10 ** PRICE_FEED_DECIMALS);

    /// @dev The scale for factors
    uint64 internal constant FACTOR_SCALE = 1e18;

    /**
     * @notice Determine if the manager has permission to act on behalf of the owner
     * @param owner The owner account
     * @param manager The manager account
     * @return Whether or not the manager has permission
     */
    function hasPermission(address owner, address manager) public view returns (bool) {
        return owner == manager || isAllowed[owner][manager];
    }

    /**
     * @dev The positive present supply balance if positive or the negative borrow balance if negative
     *  Note This will overflow at 2^103/1e18=~10 trillion for assets with 18 decimals.
     */
    function presentValue(int104 principalValue_) internal view returns (int104) {
        if (principalValue_ >= 0) {
            return signed104(presentValueSupply(baseSupplyIndex, unsigned104(principalValue_)));
        } else {
            return -signed104(presentValueBorrow(baseBorrowIndex, unsigned104(-principalValue_)));
        }
    }

    /**
     * @dev The principal amount projected forward by the supply index
     *  Note This will overflow at 2^104/1e18=~20 trillion for assets with 18 decimals.
     */
    function presentValueSupply(uint64 baseSupplyIndex_, uint104 principalValue_) internal pure returns (uint104) {
        return uint104(uint(principalValue_) * baseSupplyIndex_ / BASE_INDEX_SCALE);
    }

    /**
     * @dev The principal amount projected forward by the borrow index
     *  Note This will overflow at 2^104/1e18=~20 trillion for assets with 18 decimals.
     */
    function presentValueBorrow(uint64 baseBorrowIndex_, uint104 principalValue_) internal pure returns (uint104) {
        return uint104(uint(principalValue_) * baseBorrowIndex_ / BASE_INDEX_SCALE);
    }

    /**
     * @dev The positive principal if positive or the negative principal if negative
     */
    function principalValue(int104 presentValue_) internal view returns (int104) {
        if (presentValue_ >= 0) {
            return signed104(principalValueSupply(baseSupplyIndex, unsigned104(presentValue_)));
        } else {
            return -signed104(principalValueBorrow(baseBorrowIndex, unsigned104(-presentValue_)));
        }
    }

    /**
     * @dev The present value projected backward by the supply index (rounded down)
     */
    function principalValueSupply(uint64 baseSupplyIndex_, uint104 presentValue_) internal pure returns (uint104) {
        return uint104((uint(presentValue_) * BASE_INDEX_SCALE) / baseSupplyIndex_);
    }

    /**
     * @dev The present value projected backward by the borrow index (rounded up)
     */
    function principalValueBorrow(uint64 baseBorrowIndex_, uint104 presentValue_) internal pure returns (uint104) {
        return uint104((uint(presentValue_) * BASE_INDEX_SCALE + baseBorrowIndex_ - 1) / baseBorrowIndex_);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/**
 * @title Compound's Comet Storage Interface
 * @dev Versions can enforce append-only storage slots via inheritance.
 * @author Compound
 */
contract CometStorage {
    // 512 bits total = 2 slots
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

    struct LiquidatorPoints {
        uint32 numAbsorbs;
        uint64 numAbsorbed;
        uint128 approxSpend;
        uint32 _reserved;
    }

    /// @dev Aggregate variables tracked for the entire market
    uint64 internal baseSupplyIndex;
    uint64 internal baseBorrowIndex;
    uint64 internal trackingSupplyIndex;
    uint64 internal trackingBorrowIndex;
    uint104 internal totalSupplyBase;
    uint104 internal totalBorrowBase;
    uint40 internal lastAccrualTime;
    uint8 internal pauseFlags;

    /// @notice Aggregate variables tracked for each collateral asset
    mapping(address => TotalsCollateral) public totalsCollateral;

    /// @notice Mapping of users to accounts which may be permitted to manage the user account
    mapping(address => mapping(address => bool)) public isAllowed;

    /// @notice The next expected nonce for an address, for validating authorizations via signature
    mapping(address => uint) public userNonce;

    /// @notice Mapping of users to base principal and other basic data
    mapping(address => UserBasic) public userBasic;

    /// @notice Mapping of users to collateral data per collateral asset
    mapping(address => mapping(address => UserCollateral)) public userCollateral;

    /// @notice Mapping of magic liquidator points
    mapping(address => LiquidatorPoints) public liquidatorPoints;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.13;

/**
 * @title Compound's Comet Math Contract
 * @dev Pure math functions
 * @author Compound
 */
contract CometMath {
    /** Custom errors **/

    error InvalidUInt64();
    error InvalidUInt104();
    error InvalidUInt128();
    error InvalidInt104();
    error InvalidInt256();
    error NegativeNumber();

    function min(uint104 a, uint104 b) internal pure returns (uint104) {
        return a < b ? a : b;
    }

    function safe64(uint n) internal pure returns (uint64) {
        if (n > type(uint64).max) revert InvalidUInt64();
        return uint64(n);
    }

    function safe104(uint n) internal pure returns (uint104) {
        if (n > type(uint104).max) revert InvalidUInt104();
        return uint104(n);
    }

    function safe128(uint n) internal pure returns (uint128) {
        if (n > type(uint128).max) revert InvalidUInt128();
        return uint128(n);
    }

    function signed104(uint104 n) internal pure returns (int104) {
        if (n > uint104(type(int104).max)) revert InvalidInt104();
        return int104(n);
    }

    function signed256(uint256 n) internal pure returns (int256) {
        if (n > uint256(type(int256).max)) revert InvalidInt256();
        return int256(n);
    }

    function unsigned104(int104 n) internal pure returns (uint104) {
        if (n < 0) revert NegativeNumber();
        return uint104(n);
    }

    function unsigned256(int256 n) internal pure returns (uint256) {
        if (n < 0) revert NegativeNumber();
        return uint256(n);
    }

    function toUInt8(bool x) internal pure returns (uint8) {
        return x ? 1 : 0;
    }

    function toBool(uint8 x) internal pure returns (bool) {
        return x != 0;
    }
}