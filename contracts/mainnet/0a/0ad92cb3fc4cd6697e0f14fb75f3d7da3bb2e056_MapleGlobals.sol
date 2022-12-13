// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

import { NonTransparentProxied } from "../modules/non-transparent-proxy/contracts/NonTransparentProxied.sol";

import { IMapleGlobals } from "./interfaces/IMapleGlobals.sol";

import { IChainlinkAggregatorV3Like, IPoolManagerLike } from "./interfaces/Interfaces.sol";

/*

    ███╗   ███╗ █████╗ ██████╗ ██╗     ███████╗     ██████╗ ██╗      ██████╗ ██████╗  █████╗ ██╗     ███████╗
    ████╗ ████║██╔══██╗██╔══██╗██║     ██╔════╝    ██╔════╝ ██║     ██╔═══██╗██╔══██╗██╔══██╗██║     ██╔════╝
    ██╔████╔██║███████║██████╔╝██║     █████╗      ██║  ███╗██║     ██║   ██║██████╔╝███████║██║     ███████╗
    ██║╚██╔╝██║██╔══██║██╔═══╝ ██║     ██╔══╝      ██║   ██║██║     ██║   ██║██╔══██╗██╔══██║██║     ╚════██║
    ██║ ╚═╝ ██║██║  ██║██║     ███████╗███████╗    ╚██████╔╝███████╗╚██████╔╝██████╔╝██║  ██║███████╗███████║
    ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚══════╝╚══════╝     ╚═════╝ ╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝

*/

contract MapleGlobals is IMapleGlobals, NonTransparentProxied {

    /******************************************************************************************************************************/
    /*** Structs                                                                                                                ***/
    /******************************************************************************************************************************/

    struct PoolDelegate {
        address ownedPoolManager;
        bool    isPoolDelegate;
    }

    struct ScheduledCall {
        uint256 timestamp;
        bytes32 dataHash;
    }

    struct TimelockParameters {
        uint128 delay;
        uint128 duration;
    }

    /******************************************************************************************************************************/
    /*** Storage                                                                                                                ***/
    /******************************************************************************************************************************/

    uint256 public constant HUNDRED_PERCENT = 100_0000;

    address public override mapleTreasury;
    address public override migrationAdmin;
    address public override pendingGovernor;
    address public override securityAdmin;

    bool public override protocolPaused;

    TimelockParameters public override defaultTimelockParameters;

    mapping(address => address) public override oracleFor;

    mapping(address => bool) public override isBorrower;
    mapping(address => bool) public override isCollateralAsset;
    mapping(address => bool) public override isPoolAsset;
    mapping(address => bool) public override isPoolDeployer;

    mapping(address => uint256) public override manualOverridePrice;
    mapping(address => uint256) public override maxCoverLiquidationPercent;
    mapping(address => uint256) public override minCoverAmount;
    mapping(address => uint256) public override bootstrapMint;
    mapping(address => uint256) public override platformManagementFeeRate;
    mapping(address => uint256) public override platformOriginationFeeRate;
    mapping(address => uint256) public override platformServiceFeeRate;

    mapping(address => mapping(bytes32 => TimelockParameters)) public override timelockParametersOf;

    mapping(bytes32 => mapping(address => bool)) public override isFactory;

    // Timestamp and call data hash for a caller, on a contract, for a function id.
    mapping(address => mapping(address => mapping(bytes32 => ScheduledCall))) public override scheduledCalls;

    mapping(address => PoolDelegate) public override poolDelegates;

    /******************************************************************************************************************************/
    /*** Modifiers                                                                                                              ***/
    /******************************************************************************************************************************/

    modifier isGovernor {
        require(msg.sender == admin(), "MG:NOT_GOVERNOR");
        _;
    }

    /******************************************************************************************************************************/
    /*** Governor Transfer Functions                                                                                            ***/
    /******************************************************************************************************************************/

    function acceptGovernor() external {
        require(msg.sender == pendingGovernor, "MG:NOT_PENDING_GOVERNOR");
        emit GovernorshipAccepted(admin(), msg.sender);
        _setAddress(ADMIN_SLOT, msg.sender);
        pendingGovernor = address(0);
    }

    function setPendingGovernor(address pendingGovernor_) external isGovernor {
        emit PendingGovernorSet(pendingGovernor = pendingGovernor_);
    }

    /******************************************************************************************************************************/
    /*** Global Setters                                                                                                         ***/
    /******************************************************************************************************************************/

    // NOTE: `minCoverAmount` is not enforced at activation time.
    function activatePoolManager(address poolManager_) external override isGovernor {
        address delegate_ = IPoolManagerLike(poolManager_).poolDelegate();
        require(poolDelegates[delegate_].ownedPoolManager == address(0), "MG:APM:ALREADY_OWNS");

        emit PoolManagerActivated(poolManager_, delegate_);
        poolDelegates[delegate_].ownedPoolManager = poolManager_;
        IPoolManagerLike(poolManager_).setActive(true);
    }

    function setMapleTreasury(address mapleTreasury_) external override isGovernor {
        require(mapleTreasury_ != address(0), "MG:SMT:ZERO_ADDRESS");
        emit MapleTreasurySet(mapleTreasury, mapleTreasury_);
        mapleTreasury = mapleTreasury_;
    }

    function setMigrationAdmin(address migrationAdmin_) external override isGovernor {
        emit MigrationAdminSet(migrationAdmin, migrationAdmin_);
        migrationAdmin = migrationAdmin_;
    }

    function setBootstrapMint(address asset_, uint256 amount_) external override isGovernor {
        emit BootstrapMintSet(asset_, bootstrapMint[asset_] = amount_);
    }

    function setPriceOracle(address asset_, address oracle_) external override isGovernor {
        require(oracle_ != address(0) && asset_ != address(0), "MG:SPO:ZERO_ADDRESS");
        oracleFor[asset_] = oracle_;
        emit PriceOracleSet(asset_, oracle_);
    }

    function setSecurityAdmin(address securityAdmin_) external override isGovernor {
        require(securityAdmin_ != address(0), "MG:SSA:ZERO_ADDRESS");
        emit SecurityAdminSet(securityAdmin, securityAdmin_);
        securityAdmin = securityAdmin_;
    }

    function setDefaultTimelockParameters(uint128 defaultTimelockDelay_, uint128 defaultTimelockDuration_) external override isGovernor {
        emit DefaultTimelockParametersSet(defaultTimelockParameters.delay, defaultTimelockDelay_, defaultTimelockParameters.duration, defaultTimelockDuration_);
        defaultTimelockParameters = TimelockParameters(defaultTimelockDelay_, defaultTimelockDuration_);
    }

    /******************************************************************************************************************************/
    /*** Boolean Setters                                                                                                        ***/
    /******************************************************************************************************************************/

    function setProtocolPause(bool protocolPaused_) external override {
        require(msg.sender == securityAdmin, "MG:SPP:NOT_SECURITY_ADMIN");
        protocolPaused = protocolPaused_;
        emit ProtocolPauseSet(msg.sender, protocolPaused_);
    }

    /******************************************************************************************************************************/
    /*** Allowlist Setters                                                                                                      ***/
    /******************************************************************************************************************************/

    function setValidBorrower(address borrower_, bool isValid_) external override isGovernor {
        isBorrower[borrower_] = isValid_;
        emit ValidBorrowerSet(borrower_, isValid_);
    }

    function setValidCollateralAsset(address collateralAsset_, bool isValid_) external override isGovernor {
        isCollateralAsset[collateralAsset_] = isValid_;
        emit ValidCollateralAssetSet(collateralAsset_, isValid_);
    }

    function setValidFactory(bytes32 factoryKey_, address factory_, bool isValid_) external override isGovernor {
        isFactory[factoryKey_][factory_] = isValid_;
        emit ValidFactorySet(factoryKey_, factory_, isValid_);
    }

    function setValidPoolAsset(address poolAsset_, bool isValid_) external override isGovernor {
        isPoolAsset[poolAsset_] = isValid_;
        emit ValidPoolAssetSet(poolAsset_, isValid_);
    }

    function setValidPoolDelegate(address account_, bool isValid_) external override isGovernor {
        require(account_ != address(0),                                             "MG:SVPD:ZERO_ADDRESS");
        require(isValid_ || poolDelegates[account_].ownedPoolManager == address(0), "MG:SVPD:OWNS_POOL_MANAGER");  // Cannot remove pool delegates that own a pool manager.
        poolDelegates[account_].isPoolDelegate = isValid_;
        emit ValidPoolDelegateSet(account_, isValid_);
    }

    function setValidPoolDeployer(address poolDeployer_, bool isValid_) external override isGovernor {
        isPoolDeployer[poolDeployer_] = isValid_;
        emit ValidPoolDeployerSet(poolDeployer_, isValid_);
    }

    /******************************************************************************************************************************/
    /*** Price Setters                                                                                                          ***/
    /******************************************************************************************************************************/

    function setManualOverridePrice(address asset_, uint256 price_) external override isGovernor {
        manualOverridePrice[asset_] = price_;
        emit ManualOverridePriceSet(asset_, price_);
    }

    /******************************************************************************************************************************/
    /*** Cover Setters                                                                                                          ***/
    /******************************************************************************************************************************/

    function setMinCoverAmount(address poolManager_, uint256 minCoverAmount_) external override isGovernor {
        minCoverAmount[poolManager_] = minCoverAmount_;
        emit MinCoverAmountSet(poolManager_, minCoverAmount_);
    }

    function setMaxCoverLiquidationPercent(address poolManager_, uint256 maxCoverLiquidationPercent_) external override isGovernor {
        require(maxCoverLiquidationPercent_ <= HUNDRED_PERCENT, "MG:SMCLP:GT_100");
        maxCoverLiquidationPercent[poolManager_] = maxCoverLiquidationPercent_;
        emit MaxCoverLiquidationPercentSet(poolManager_, maxCoverLiquidationPercent_);
    }

    /******************************************************************************************************************************/
    /*** Fee Setters                                                                                                            ***/
    /******************************************************************************************************************************/

    function setPlatformManagementFeeRate(address poolManager_, uint256 platformManagementFeeRate_) external override isGovernor {
        require(platformManagementFeeRate_ <= HUNDRED_PERCENT, "MG:SPMFR:RATE_GT_100");
        platformManagementFeeRate[poolManager_] = platformManagementFeeRate_;
        emit PlatformManagementFeeRateSet(poolManager_, platformManagementFeeRate_);
    }

    function setPlatformOriginationFeeRate(address poolManager_, uint256 platformOriginationFeeRate_) external override isGovernor {
        require(platformOriginationFeeRate_ <= HUNDRED_PERCENT, "MG:SPOFR:RATE_GT_100");
        platformOriginationFeeRate[poolManager_] = platformOriginationFeeRate_;
        emit PlatformOriginationFeeRateSet(poolManager_, platformOriginationFeeRate_);
    }

    function setPlatformServiceFeeRate(address poolManager_, uint256 platformServiceFeeRate_) external override isGovernor {
        require(platformServiceFeeRate_ <= HUNDRED_PERCENT, "MG:SPSFR:RATE_GT_100");
        platformServiceFeeRate[poolManager_] = platformServiceFeeRate_;
        emit PlatformServiceFeeRateSet(poolManager_, platformServiceFeeRate_);
    }

    /******************************************************************************************************************************/
    /*** Contract Control Functions                                                                                             ***/
    /******************************************************************************************************************************/

    function setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) public override isGovernor {
        timelockParametersOf[contract_][functionId_] = TimelockParameters(delay_, duration_);
        emit TimelockWindowSet(contract_, functionId_, delay_, duration_);
    }

    function setTimelockWindows(address contract_, bytes32[] calldata functionIds_, uint128[] calldata delays_, uint128[] calldata durations_) public override isGovernor {
        for (uint256 i_; i_ < functionIds_.length;) {
            _setTimelockWindow(contract_, functionIds_[i_], delays_[i_], durations_[i_]);
            unchecked { ++i_; }
        }
    }

    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external override {
        PoolDelegate storage fromDelegate_ = poolDelegates[fromPoolDelegate_];
        PoolDelegate storage toDelegate_   = poolDelegates[toPoolDelegate_];

        require(fromDelegate_.ownedPoolManager == msg.sender, "MG:TOPM:NOT_AUTHORIZED");
        require(toDelegate_.isPoolDelegate,                   "MG:TOPM:NOT_POOL_DELEGATE");
        require(toDelegate_.ownedPoolManager == address(0),   "MG:TOPM:ALREADY_OWNS");

        fromDelegate_.ownedPoolManager = address(0);
        toDelegate_.ownedPoolManager   = msg.sender;

        emit PoolManagerOwnershipTransferred(fromPoolDelegate_, toPoolDelegate_, msg.sender);
    }

    /******************************************************************************************************************************/
    /*** Schedule Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    function scheduleCall(address contract_, bytes32 functionId_, bytes calldata callData_) external override {
        bytes32 dataHash_ = keccak256(abi.encode(callData_));
        scheduledCalls[msg.sender][contract_][functionId_] = ScheduledCall(block.timestamp, dataHash_);
        emit CallScheduled(msg.sender, contract_, functionId_, dataHash_, block.timestamp);
    }

    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external override {
        delete scheduledCalls[caller_][msg.sender][functionId_];
        emit CallUnscheduled(caller_, msg.sender, functionId_, keccak256(abi.encode(callData_)), block.timestamp);
    }

    function unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external override isGovernor {
        delete scheduledCalls[caller_][contract_][functionId_];
        emit CallUnscheduled(caller_, contract_, functionId_, keccak256(abi.encode(callData_)), block.timestamp);
    }

    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) public override view returns (bool isValid_) {
        ScheduledCall      storage scheduledCall_      = scheduledCalls[caller_][contract_][functionId_];
        TimelockParameters storage timelockParameters_ = timelockParametersOf[contract_][functionId_];

        uint256 timestamp = scheduledCall_.timestamp;
        uint128 delay     = timelockParameters_.delay;
        uint128 duration  = timelockParameters_.duration;

        if (duration == uint128(0)) {
            delay    = defaultTimelockParameters.delay;
            duration = defaultTimelockParameters.duration;
        }

        isValid_ =
            (block.timestamp >= timestamp + delay) &&
            (block.timestamp <= timestamp + delay + duration) &&
            (keccak256(abi.encode(callData_)) == scheduledCall_.dataHash);
    }

    /******************************************************************************************************************************/
    /*** View Functions                                                                                                         ***/
    /******************************************************************************************************************************/

    function getLatestPrice(address asset_) external override view returns (uint256 latestPrice_) {
        // If governor has overridden price because of oracle outage, return overridden price.
        if (manualOverridePrice[asset_] != 0) return manualOverridePrice[asset_];

        address oracle_ = oracleFor[asset_];

        require(oracle_ != address(0), "MG:GLP:ZERO_ORACLE");

        ( uint80 roundId_, int256 price_, , uint256 updatedAt_, uint80 answeredInRound_ ) = IChainlinkAggregatorV3Like(oracle_).latestRoundData();

        require(updatedAt_ != 0,              "MG:GLP:ROUND_NOT_COMPLETE");
        require(answeredInRound_ >= roundId_, "MG:GLP:STALE_DATA");
        require(price_ > int256(0),           "MG:GLP:ZERO_PRICE");

        latestPrice_ = uint256(price_);
    }

    function governor() external view override returns (address governor_) {
        governor_ = admin();
    }

    function isPoolDelegate(address account_) external view override returns (bool isPoolDelegate_) {
        isPoolDelegate_ = poolDelegates[account_].isPoolDelegate;
    }

    function ownedPoolManager(address account_) external view override returns (address poolManager_) {
        poolManager_ = poolDelegates[account_].ownedPoolManager;
    }

    /******************************************************************************************************************************/
    /*** Helper Functions                                                                                                       ***/
    /******************************************************************************************************************************/

    function _setAddress(bytes32 slot_, address value_) private {
        assembly {
            sstore(slot_, value_)
        }
    }

    function _setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) internal {
        timelockParametersOf[contract_][functionId_] = TimelockParameters(delay_, duration_);
        emit TimelockWindowSet(contract_, functionId_, delay_, duration_);
    }

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IMapleGlobals {

    /******************************************************************************************************************************/
    /*** Events                                                                                                                 ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   A time locked call has been scheduled.
     *  @param caller_     The address of the function caller.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param dataHash_   The hash of the parameters to pass to the function.
     *  @param timestamp_  The timestamp of the schedule.
     */
    event CallScheduled(address indexed caller_, address indexed contract_, bytes32 indexed functionId_, bytes32 dataHash_, uint256 timestamp_);

    /**
     *  @dev   A time locked call has been unscheduled.
     *  @param caller_     The address of the function caller.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param dataHash_   The hash of the parameters to pass to the function.
     *  @param timestamp_  The timestamp of the schedule.
     */
    event CallUnscheduled(address indexed caller_, address indexed contract_, bytes32 indexed functionId_, bytes32 dataHash_, uint256 timestamp_);

    /**
     *  @dev   The default parameters for the time lock has been set.
     *  @param previousDelay_    The previous required delay.
     *  @param currentDelay_     The newly set required delay.
     *  @param previousDuration_ The previous required duration.
     *  @param currentDuration_  The newly set required duration.
     */
    event DefaultTimelockParametersSet(uint256 previousDelay_, uint256 currentDelay_, uint256 previousDuration_, uint256 currentDuration_);

    /**
     *  @dev   The governorship has been accepted.
     *  @param previousGovernor_ The previous governor.
     *  @param currentGovernor_  The new governor.
     */
    event GovernorshipAccepted(address indexed previousGovernor_, address indexed currentGovernor_);

    /**
     *  @dev   The price for an asset has been set.
     *  @param asset_ The address of the asset.
     *  @param price_ The manually set price of the asset.
     */
    event ManualOverridePriceSet(address indexed asset_, uint256 price_);

    /**
     *  @dev   The address for the Maple treasury has been set.
     *  @param previousMapleTreasury_ The previous treasury.
     *  @param currentMapleTreasury_  The new treasury.
     */
    event MapleTreasurySet(address indexed previousMapleTreasury_, address indexed currentMapleTreasury_);

    /**
     *  @dev   The max liquidation percent for the given pool manager has been set.
     *  @param poolManager_                The address of the pool manager.
     *  @param maxCoverLiquidationPercent_ The new value for the cover liquidation percent.
     */
    event MaxCoverLiquidationPercentSet(address indexed poolManager_, uint256 maxCoverLiquidationPercent_);

    /**
     *  @dev   The migration admin has been set.
     *  @param previousMigrationAdmin_ The previous migration admin.
     *  @param nextMigrationAdmin_     The new migration admin.
     */
    event MigrationAdminSet(address indexed previousMigrationAdmin_, address indexed nextMigrationAdmin_);

    /**
     *  @dev   The minimum cover amount for the given pool manager has been set.
     *  @param poolManager_    The address of the pool manager.
     *  @param minCoverAmount_ The new value for the minimum cover amount.
     */
    event MinCoverAmountSet(address indexed poolManager_, uint256 minCoverAmount_);

    /**
     *  @dev   A virtualized first mint that acts as as offset to `totalAssets` and `totalSupply`.
     *  @param asset_         The address of the pool asset.
     *  @param bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    event BootstrapMintSet(address indexed asset_, uint256 bootstrapMint_);

    /**
     *  @dev   The pending governor has been set.
     *  @param pendingGovernor_ The new pending governor.
     */
    event PendingGovernorSet(address indexed pendingGovernor_);

    /**
     *  @dev   The platform management fee rate for the given pool manager has been set.
     *  @param poolManager_               The address of the pool manager.
     *  @param platformManagementFeeRate_ The new value for the platform management fee rate.
     */
    event PlatformManagementFeeRateSet(address indexed poolManager_, uint256 platformManagementFeeRate_);

    /**
     *  @dev   The platform origination fee rate for the given pool manager has been set.
     *  @param poolManager_                The address of the pool manager.
     *  @param platformOriginationFeeRate_ The new value for the origination fee rate.
     */
    event PlatformOriginationFeeRateSet(address indexed poolManager_, uint256 platformOriginationFeeRate_);

    /**
     *  @dev   The platform service fee rate for the given pool manager has been set.
     *  @param poolManager_            The address of the pool manager.
     *  @param platformServiceFeeRate_ The new value for the platform service fee rate.
     */
    event PlatformServiceFeeRateSet(address indexed poolManager_, uint256 platformServiceFeeRate_);

    /**
     *  @dev   The pool manager was activated.
     *  @param poolManager_  The address of the pool manager.
     *  @param poolDelegate_ The address of the pool delegate.
     */
    event PoolManagerActivated(address indexed poolManager_, address indexed poolDelegate_);

    /**
     *  @dev   The ownership of the pool manager was transferred.
     *  @param fromPoolDelegate_ The address of the previous pool delegate.
     *  @param toPoolDelegate_   The address of the new pool delegate.
     *  @param poolManager_      The address of the pool manager.
     */
    event PoolManagerOwnershipTransferred(address indexed fromPoolDelegate_, address indexed toPoolDelegate_, address indexed poolManager_);

    /**
     *  @dev   The oracle for an asset has been set.
     *  @param asset_  The address of the asset.
     *  @param oracle_ The address of the oracle.
     */
    event PriceOracleSet(address indexed asset_, address indexed oracle_);

    /**
     *  @dev   The protocol pause was set to a new state.
     *  @param securityAdmin_  The address of the security admin.
     *  @param protocolPaused_ The protocol paused state.
     */
    event ProtocolPauseSet(address indexed securityAdmin_, bool indexed protocolPaused_);

    /**
     *  @dev   The security admin was set.
     *  @param previousSecurityAdmin_ The address of the previous security admin.
     *  @param currentSecurityAdmin_  The address of the new security admin.
     */
    event SecurityAdminSet(address indexed previousSecurityAdmin_, address indexed currentSecurityAdmin_);

    /**
     *  @dev   A new timelock window was set.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param delay_      The delay of the timelock window.
     *  @param duration_   The duration of the timelock window.
     */
    event TimelockWindowSet(address indexed contract_, bytes32 indexed functionId_, uint128 delay_, uint128 duration_);

    /**
     *  @dev   A valid borrower was set.
     *  @param borrower_ The address of the borrower.
     *  @param isValid_  The validity of the borrower.
     */
    event ValidBorrowerSet(address indexed borrower_, bool indexed isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param collateralAsset_ The address of the collateral asset.
     *  @param isValid_         The validity of the collateral asset.
     */
     event ValidCollateralAssetSet(address indexed collateralAsset_, bool indexed isValid_);

    /**
     *  @dev   A valid factory was set.
     *  @param factoryKey_ The key of the factory.
     *  @param factory_    The address of the factory.
     *  @param isValid_    The validity of the factory.
     */
    event ValidFactorySet(bytes32 indexed factoryKey_, address indexed factory_, bool indexed isValid_);

    /**
     *  @dev   A valid asset was set.
     *  @param poolAsset_ The address of the asset.
     *  @param isValid_   The validity of the asset.
     */
    event ValidPoolAssetSet(address indexed poolAsset_, bool indexed isValid_);

    /**
     *  @dev   A valid pool delegate was set.
     *  @param account_ The address the account.
     *  @param isValid_ The validity of the asset.
     */
    event ValidPoolDelegateSet(address indexed account_, bool indexed isValid_);

    /**
     *  @dev   A valid pool deployer was set.
     *  @param poolDeployer_ The address the account.
     *  @param isValid_      The validity of the asset.
     */
    event ValidPoolDeployerSet(address indexed poolDeployer_, bool indexed isValid_);

    /******************************************************************************************************************************/
    /*** State Variables                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev    Gets the default timelock parameters.
     *  @return delay    The default timelock delay.
     *  @return duration The default timelock duration.
     */
    function defaultTimelockParameters() external view returns (uint128 delay, uint128 duration);

    /**
     *  @dev    Gets the validity of a borrower.
     *  @param  borrower_ The address of the borrower to query.
     *  @return isValid_  A boolean indicating the validity of the borrower.
     */
    function isBorrower(address borrower_) external view returns (bool isValid_);

    /**
     *  @dev    Gets the validity of a collateral asset.
     *  @param  collateralAsset_ The address of the collateralAsset to query.
     *  @return isValid_         A boolean indicating the validity of the collateral asset.
     */
    function isCollateralAsset(address collateralAsset_) external view returns (bool isValid_);

    /**
     *  @dev    Gets the validity of a factory.
     *  @param  factoryId_ The address of the factory to query.
     *  @param  factory_   The address of the factory to query.
     *  @return isValid_   A boolean indicating the validity of the factory.
     */
    function isFactory(bytes32 factoryId_, address factory_) external view returns (bool isValid_);

    /**
     *  @dev    Gets the validity of a pool asset.
     *  @param  poolAsset_ The address of the poolAsset to query.
     *  @return isValid_   A boolean indicating the validity of the pool asset.
     */
    function isPoolAsset(address poolAsset_) external view returns (bool isValid_);

    /**
     *  @dev    Gets the validity of a pool dekegate.
     *  @param  account_  The address of the aaccount to query.
     *  @return isValid_  A boolean indicating the validity of the pool delegate.
     */
    function isPoolDelegate(address account_) external view returns (bool isValid_);

    /**
     *  @dev    Gets the validity of a pool deployer.
     *  @param  account_  The address of the account to query.
     *  @return isValid_  A boolean indicating the validity of the pool deployer.
     */
    function isPoolDeployer(address account_) external view returns (bool isValid_);

    /**
    *  @dev    Gets the latest price for an asset.
    *  @param  asset_       The address of the asset to query.
    *  @return latestPrice_ The latest price for the asset.
    */
    function getLatestPrice(address asset_) external view returns (uint256 latestPrice_);

    /**
     *  @dev    Gets governor address.
     *  @return governor_ The address of the governor.
     */
    function governor() external view returns (address governor_);

    /**
    *  @dev    Gets the manual override price for an asset.
    *  @param  asset_               The address of the asset to query.
    *  @return manualOverridePrice_ The manual override price for the asset.
    */
    function manualOverridePrice(address asset_) external view returns (uint256 manualOverridePrice_);

    /**
     *  @dev    Gets maple treasury address.
     *  @return mapleTreasury_ The address of the maple treasury.
     */
    function mapleTreasury() external view returns (address mapleTreasury_);

    /**
     *  @dev    Gets the maximum cover liquidation percent for a given pool manager.
     *  @param  poolManager_                The address of the pool manager to query.
     *  @return maxCoverLiquidationPercent_ The maximum cover liquidation percent.
     */
    function maxCoverLiquidationPercent(address poolManager_) external view returns (uint256 maxCoverLiquidationPercent_);

    /**
     *  @dev    Gets migration admin address.
     *  @return migrationAdmin_ The address of the migration admin.
     */
    function migrationAdmin() external view returns (address migrationAdmin_);

    /**
     *  @dev    Gets the minimum cover amount for a given pool manager.
     *  @param  poolManager_    The address of the pool manager to query.
     *  @return minCoverAmount_ The minimum cover amount.
     */
    function minCoverAmount(address poolManager_) external view returns (uint256 minCoverAmount_);

    /**
     *  @dev    Gets the virtualized first mint that acts as as offset to `totalAssets` and `totalSupply` for a given pool asset.
     *  @param  asset_         The address of the pool asset to query
     *  @return bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    function bootstrapMint(address asset_) external view returns (uint256 bootstrapMint_);

    /**
     *  @dev    Gets the address of the oracle for the given asset.
     *  @param  asset_  The address of the asset to query.
     *  @return oracle_ The address of the oracle.
     */
    function oracleFor(address asset_) external view returns (address oracle_);

    /**
     *  @dev    Gets the address of the owner pool manager.
     *  @param  account_     The address of the account to query.
     *  @return poolManager_ The address of the pool manager.
     */
    function ownedPoolManager(address account_) external view returns (address poolManager_);

    /**
     *  @dev    Gets the pending governor address.
     *  @return pendingGovernor_ The address of the pending governor.
     */
    function pendingGovernor() external view returns (address pendingGovernor_);

    /**
     *  @dev    Gets the platform management fee rate for a given pool manager.
     *  @param  poolManager_               The address of the pool manager to query.
     *  @return platformManagementFeeRate_ The platform management fee rate.
     */
    function platformManagementFeeRate(address poolManager_) external view returns (uint256 platformManagementFeeRate_);

    /**
     *  @dev    Gets the platform origination fee rate for a given pool manager.
     *  @param  poolManager_                The address of the pool manager to query.
     *  @return platformOriginationFeeRate_ The platform origination fee rate.
     */
    function platformOriginationFeeRate(address poolManager_) external view returns (uint256 platformOriginationFeeRate_);

    /**
     *  @dev    Gets the platform service fee rate for a given pool manager.
     *  @param  poolManager_            The address of the pool manager to query.
     *  @return platformServiceFeeRate_ The platform service fee rate.
     */
    function platformServiceFeeRate(address poolManager_) external view returns (uint256 platformServiceFeeRate_);

    /**
     *  @dev    Gets pool delegate address information.
     *  @param  poolDelegate_    The address of the pool delegate to query.
     *  @return ownedPoolManager The address of the pool manager owned by the pool delegate.
     *  @return isPoolDelegate   A boolean indication weather or not the address passed is a current pool delegate.
     */
    function poolDelegates(address poolDelegate_) external view returns (address ownedPoolManager, bool isPoolDelegate);

    /**
     *  @dev    Gets the status of the protocol pause.
     *  @return protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function protocolPaused() external view returns (bool protocolPaused_);

    /**
     *  @dev    Gets the schedule calls for the parameters.
     *  @param  caller_     The address of the caller.
     *  @param  contract_   The address of the contract.
     *  @param  functionId_ The id function to call.
     *  @return timestamp   The timestamp of the next scheduled call.
     *  @return dataHash    The hash of data fot the scheduled call.
     */
    function scheduledCalls(address caller_, address contract_, bytes32 functionId_) external view returns (uint256 timestamp, bytes32 dataHash);

    /**
     *  @dev    Gets secutity admin address.
     *  @return securityAdmin_ The address of the secutity admin.
     */
    function securityAdmin() external view returns (address securityAdmin_);

    /**
     *  @dev    Gets the time lock parameters for a given contract and function.
     *  @param  contract_   The address of the contract to query.
     *  @param  functionId_ The id of the function to query.
     *  @return delay       The time lock delay.
     *  @return duration    The time lock duration.
     */
    function timelockParametersOf(address contract_, bytes32 functionId_) external view returns (uint128 delay, uint128 duration);

    /******************************************************************************************************************************/
    /*** Global Setters                                                                                                         ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Activates the pool manager.
     *  @param poolManager_ The address of the pool manager to activate.
     */
    function activatePoolManager(address poolManager_) external;

    /**
     *  @dev   Sets the address of the Maple treasury.
     *  @param mapleTreasury_ The address of the Maple treasury.
     */
    function setMapleTreasury(address mapleTreasury_) external;

    /**
     *  @dev   Sets the address of the migration admin.
     *  @param migrationAdmin_ The address of the migration admin.
     */
    function setMigrationAdmin(address migrationAdmin_) external;

    /**
     *  @dev   Sets the virtualized first mint that acts as as offset to `totalAssets` and `totalSupply`
     *         to prevent an MEV-exploit vector against the first pool depositor.
     *  @param asset_         The address of the pool asset.
     *  @param bootstrapMint_ The amount of shares that will offset `totalAssets` and `totalSupply`.
     */
    function setBootstrapMint(address asset_, uint256 bootstrapMint_) external;

    /**
     *  @dev   Sets the price oracle for the given asset.
     *  @param asset_       The address of the asset to set the oracle for.
     *  @param priceOracle_ The address of the oracle to set for the asset.
     */
    function setPriceOracle(address asset_, address priceOracle_) external;

    /**
     *  @dev   Sets the address of the security admin.
     *  @param securityAdmin_ The address of the security admin.
     */
    function setSecurityAdmin(address securityAdmin_) external;

    /**
     *  @dev   Sets the default time lock parameters.
     *  @param defaultTimelockDelay_    The default time lock delay.
     *  @param defaultTimelockDuration_ The default time lock duration.
     */
    function setDefaultTimelockParameters(uint128 defaultTimelockDelay_, uint128 defaultTimelockDuration_) external;

    /******************************************************************************************************************************/
    /*** Boolean Setters                                                                                                        ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the protocol pause.
     *  @param protocolPaused_ A boolean indicating the status of the protocol pause.
     */
    function setProtocolPause(bool protocolPaused_) external;

    /******************************************************************************************************************************/
    /*** Allowlist Setters                                                                                                      ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the validity of the borrower.
     *  @param borrower_ The address of the borrower to set the validity for.
     *  @param isValid_  A boolean indicating the validity of the borrower.
     */
    function setValidBorrower(address borrower_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of a collateral asset.
     *  @param collateralAsset_ The address of the collateral asset to set the validity for.
     *  @param isValid_         A boolean indicating the validity of the collateral asset.
     */
    function setValidCollateralAsset(address collateralAsset_ , bool isValid_) external;

    /**
     *  @dev   Sets the validity of the factory.
     *  @param factoryKey_ The key of the factory to set the validity for.
     *  @param factory_    The address of the factory to set the validity for.
     *  @param isValid_    Boolean indicating the validity of the factory.
     */
    function setValidFactory(bytes32 factoryKey_, address factory_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool asset.
     *  @param poolAsset_ The address of the pool asset to set the validity for.
     *  @param isValid_   A boolean indicating the validity of the pool asset.
     */
    function setValidPoolAsset(address poolAsset_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool delegate.
     *  @param poolDelegate_ The address of the pool delegate to set the validity for.
     *  @param isValid_      A boolean indicating the validity of the pool delegate.
     */
    function setValidPoolDelegate(address poolDelegate_, bool isValid_) external;

    /**
     *  @dev   Sets the validity of the pool deployer.
     *  @param poolDeployer_ The address of the pool deployer to set the validity for.
     *  @param isValid_      A boolean indicating the validity of the pool deployer.
     */
    function setValidPoolDeployer(address poolDeployer_, bool isValid_) external;

    /******************************************************************************************************************************/
    /*** Price Setters                                                                                                          ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the manual override price of the asset.
     *  @param asset_ The address of the asset to set the price for.
     *  @param price_ The price of the asset.
     */
    function setManualOverridePrice(address asset_, uint256 price_) external;

    /******************************************************************************************************************************/
    /*** Cover Setters                                                                                                          ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the maximum cover liquidation percent for the given pool manager.
     *  @param poolManager_                The address of the pool manager to set the maximum cover liquidation percent for.
     *  @param maxCoverLiquidationPercent_ The maximum cover liquidation percent.
     */
    function setMaxCoverLiquidationPercent(address poolManager_, uint256 maxCoverLiquidationPercent_) external;

    /**
     *  @dev   Sets the minimum cover amount for the given pool manager.
     *  @param poolManager_    The address of the pool manager to set the minimum cover amount  for.
     *  @param minCoverAmount_ The minimum cover amount.
     */
    function setMinCoverAmount(address poolManager_, uint256 minCoverAmount_) external;

    /******************************************************************************************************************************/
    /*** Fee Setters                                                                                                            ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the platform management fee rate for the given pool manager.
     *  @param poolManager_               The address of the pool manager to set the fee for.
     *  @param platformManagementFeeRate_ The platform management fee rate.
     */
    function setPlatformManagementFeeRate(address poolManager_, uint256 platformManagementFeeRate_) external;

    /**
     *  @dev   Sets the platform origination fee rate for the given pool manager.
     *  @param poolManager_                The address of the pool manager to set the fee for.
     *  @param platformOriginationFeeRate_ The platform origination fee rate.
     */
    function setPlatformOriginationFeeRate(address poolManager_, uint256 platformOriginationFeeRate_) external;

    /**
     *  @dev   Sets the platform service fee rate for the given pool manager.
     *  @param poolManager_            The address of the pool manager to set the fee for.
     *  @param platformServiceFeeRate_ The platform service fee rate.
     */
    function setPlatformServiceFeeRate(address poolManager_, uint256 platformServiceFeeRate_) external;

    /******************************************************************************************************************************/
    /*** Contact Control Functions                                                                                              ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Sets the timelock for the given contract.
     *  @param contract_   The address of the contract to add.
     *  @param functionId_ The id of the function.
     *  @param delay_      The delay for the timelock window.
     *  @param duration_   The duration for the timelock window.
     */
    function setTimelockWindow(address contract_, bytes32 functionId_, uint128 delay_, uint128 duration_) external;

    /**
     *  @dev   Sets the timelock for the many function ids in a contract.
     *  @param contract_    The address of the contract to add.
     *  @param functionIds_ The ids of the functions.
     *  @param delays_      The delays for the timelock window.
     *  @param durations_   The durations for the timelock window.
     */
    function setTimelockWindows(address contract_, bytes32[] calldata functionIds_, uint128[] calldata delays_, uint128[] calldata durations_) external;

    /**
     *  @dev   Transfer the ownership of the pool manager.
     *  @param fromPoolDelegate_ The address of the pool delegate to transfer ownership from.
     *  @param toPoolDelegate_   The address of the pool delegate to transfer ownership to.
     */
    function transferOwnedPoolManager(address fromPoolDelegate_, address toPoolDelegate_) external;

    /******************************************************************************************************************************/
    /*** Schedule Functions                                                                                                     ***/
    /******************************************************************************************************************************/

    /**
     *  @dev   Schedules a call to be executed.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function scheduleCall(address contract_, bytes32 functionId_, bytes calldata callData_) external;

    /**
     *  @dev   Unschedules a call to be executed.
     *  @param caller_     The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function unscheduleCall(address caller_, bytes32 functionId_, bytes calldata callData_) external;

    /**
     *  @dev   Unschedules a call to be executed.
     *  @param caller_     The contract to execute the call on.
     *  @param contract_   The contract to execute the call on.
     *  @param functionId_ The id of the function to execute.
     *  @param callData_   The of the parameters to pass to the function.
     */
    function unscheduleCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external;

    /**
     *  @dev    Checks if a call is scheduled.
     *  @param  caller_     The contract to execute the call on.
     *  @param  contract_   The contract to execute the call on.
     *  @param  functionId_ The id of the function to execute.
     *  @param  callData_   The of the parameters to pass to the function.
     *  @return isValid_    True if the call is scheduled, false otherwise.
     */
    function isValidScheduledCall(address caller_, address contract_, bytes32 functionId_, bytes calldata callData_) external view returns (bool isValid_);

}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.7;

interface IChainlinkAggregatorV3Like {

    function latestRoundData()
        external
        view
        returns (
            uint80  roundId_,
            int256  price_,
            uint256 startedAt_,
            uint256 updatedAt_,
            uint80  answeredInRound_
        );

}

interface IPoolLike {

    function manager() external view returns (address manager_);

}

interface IPoolManagerLike {

    function poolDelegate() external view returns (address poolDelegate_);

    function setActive(bool active) external;

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

import { INonTransparentProxied } from "./interfaces/INonTransparentProxied.sol";

contract NonTransparentProxied is INonTransparentProxied {

    bytes32 internal constant ADMIN_SLOT          = bytes32(uint256(keccak256("eip1967.proxy.admin"))          - 1);
    bytes32 internal constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

    function admin() public view override returns (address admin_) {
        admin_ = _getAddress(ADMIN_SLOT);
    }

    function implementation() public view override returns (address implementation_) {
        implementation_ = _getAddress(IMPLEMENTATION_SLOT);
    }

    function _getAddress(bytes32 slot_) private view returns (address value_) {
        assembly {
            value_ := sload(slot_)
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.7;

interface INonTransparentProxied {

    /**
     *  @dev    Returns the proxy's admin address.
     *  @return admin_ The address of the admin.
     */
    function admin() external view returns (address admin_);

    /**
     *  @dev    Returns the proxy's implementation address.
     *  @return implementation_ The address of the implementation.
     */
    function implementation() external view returns (address implementation_);

}