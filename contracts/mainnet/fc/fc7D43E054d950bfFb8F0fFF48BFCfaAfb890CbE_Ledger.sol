// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/ILedger.sol";
import "./interfaces/IPriceOracleGetter.sol";
import "./interfaces/IUserData.sol";
import "./libraries/logic/GeneralLogic.sol";
import "./libraries/logic/CollateralLogic.sol";
import "./libraries/logic/ReservePoolLogic.sol";
import "./libraries/logic/CollateralPoolLogic.sol";
import "./libraries/logic/TradeLogic.sol";
import "./libraries/logic/LiquidationLogic.sol";
import "./libraries/logic/PositionLogic.sol";
import "./libraries/helpers/Errors.sol";
import "./types/DataTypes.sol";
import "./libraries/storage/LedgerStorage.sol";

contract Ledger is ILedger, Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    using SafeERC20Upgradeable for IERC20Upgradeable;
    using CollateralLogic for DataTypes.CollateralData;

    uint256 public constant VERSION = 2;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    bytes32 public constant LIQUIDATE_EXECUTOR = keccak256("LIQUIDATE_EXECUTOR");

    event UpdatedConfigurator(address oldAddress, address newAddress);

    /**
     * @notice Initializes the upgradeable contract
     * @param treasury_ Address where fees are sent to
     * @param configurator_ Configurator
     */
    function initialize(
        address treasury_,
        address configurator_,
        address userData_
    ) external initializer {
        __AccessControl_init();
        __ReentrancyGuard_init();

        DataTypes.ProtocolConfig storage config = LedgerStorage.getProtocolConfig();

        config.treasury = treasury_;
        config.configuratorAddress = configurator_;
        config.userData = userData_;
        config.leverageFactor = 5e18;
        config.liquidationRatioMantissa = 0.9e18;
        config.tradeFeeMantissa = 0.01e18;
        config.swapBufferLimitPercentage = 1.1e18;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /**
     * @notice Setter for configurator address
     * @param configurator_ The new configurator address
     */
    function updateConfigurator(address configurator_) external onlyOperator {
        require(configurator_ != address(0), Errors.INVALID_ZERO_ADDRESS);
        DataTypes.ProtocolConfig storage configuration = LedgerStorage.getProtocolConfig();
        emit UpdatedConfigurator(configuration.configuratorAddress, configurator_);
        configuration.configuratorAddress = configurator_;
    }

    function setProtocolConfig(DataTypes.ProtocolConfig memory config) external onlyConfigurator {
        DataTypes.ProtocolConfig storage configuration = LedgerStorage.getProtocolConfig();
        configuration.treasury = config.treasury;
        configuration.userData = config.userData;
        configuration.leverageFactor = config.leverageFactor;
        configuration.tradeFeeMantissa = config.tradeFeeMantissa;
        configuration.liquidationRatioMantissa = config.liquidationRatioMantissa;
        configuration.swapBufferLimitPercentage = config.swapBufferLimitPercentage;
    }

    function getProtocolConfig() external pure returns (DataTypes.ProtocolConfig memory) {
        return LedgerStorage.getProtocolConfig();
    }

    function whitelistedCallers(address caller) external view returns (bool) {
        return LedgerStorage.getMappingStorage().whitelistedCallers[caller];
    }

    function userLastTradeBlock(address caller) external view returns (uint256) {
        return LedgerStorage.getMappingStorage().userLastTradeBlock[caller];
    }

    function liquidatedCollaterals(address asset) external view returns (uint256) {
        return LedgerStorage.getMappingStorage().liquidatedCollaterals[asset];
    }

    /**
     * @notice Setter for whitelisted addresses
     * @param address_  new whitelisted address
     * @param on_  bool flag for whitelist address
     */
    function setWhitelist(address address_, bool on_) external onlyOperator {
        LedgerStorage.getMappingStorage().whitelistedCallers[address_] = on_;
    }

    /********************** CORE FUNCTIONS *******************************/

    /**
     * @notice Registers an asset to the ledger
     * @param asset Address
     * @return assigned assetId
     */
    function initAssetConfiguration(address asset) external onlyConfigurator returns (uint256) {
        DataTypes.AssetStorage storage assetStorage = LedgerStorage.getAssetStorage();
        assetStorage.assetsCount++;
        assetStorage.assetsList[assetStorage.assetsCount] = asset;
        assetStorage.assetConfigs[asset].assetId = assetStorage.assetsCount;
        return assetStorage.assetsCount;
    }

    /**
     * @notice Configures an asset on the ledger
     * @param asset Address
     * @param configuration configuration
     */
    function setAssetConfiguration(
        address asset,
        DataTypes.AssetConfig memory configuration
    ) public onlyConfigurator {
        require(configuration.assetId == LedgerStorage.getAssetStorage().assetConfigs[asset].assetId, Errors.INVALID_ASSET_CONFIGURATION);
        LedgerStorage.getAssetStorage().assetConfigs[asset] = configuration;
    }

    // TODO: can be moved to a library
    /*
    * @notice Initialize Reserve
    * @param asset initialize asset address
    */
    function initReserve(address asset) external onlyConfigurator returns (uint256) {
        DataTypes.ReserveStorage storage reserveStorage = LedgerStorage.getReserveStorage();

        require(reserveStorage.reservesList[asset] == 0, Errors.POOL_EXIST);

        reserveStorage.reservesCount++;
        uint256 localPid = reserveStorage.reservesCount;

        reserveStorage.reservesList[asset] = localPid;

        reserveStorage.reserves[localPid].poolId = localPid;
        reserveStorage.reserves[localPid].asset = asset;
        reserveStorage.reserves[localPid].reserveIndexRay = MathUtils.RAY;
        reserveStorage.reserves[localPid].lastUpdatedTimestamp = block.timestamp;

        return localPid;
    }

    /*
    * @notice Setter for Reserve Reinvestment
    * @param pid Pool Id
    * @param reinvestment Address where the asset is reinvested in
    */
    function setReserveReinvestment(uint256 pid, address newReinvestment) external onlyConfigurator {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        require(reserve.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        reserve.ext.reinvestment = newReinvestment;
    }

    /*
    * @notice Setter for Reserve Reinvestment
    * @param pid Pool Id
    * @param reinvestment Address where the asset is reinvested in
    */
    function setReserveBonusPool(uint256 pid, address newBonusPool) external onlyConfigurator {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        require(reserve.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        reserve.ext.bonusPool = newBonusPool;
    }

    /*
    * @notice Setter for Reserve Reinvestment
    * @param pid Pool Id
    * @param reinvestment Address where the asset is reinvested in
    */
    function setReserveLongReinvestment(uint256 pid, address newReinvestment) external onlyConfigurator {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        require(reserve.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        reserve.ext.longReinvestment = newReinvestment;
    }

    /*
    * @notice Setter for the Reserve Config
    * @param asset Address
    * @param configuration configuration
    */
    function setReserveConfiguration(uint256 pid, DataTypes.ReserveConfiguration memory configuration) external onlyConfigurator {
        ReservePoolLogic.setReserveConfiguration(pid, configuration);
    }

    /**
     * @notice Initializes a collateral
     * @param asset Address
     * @param reinvestment Address where the asset is reinvested in
     */
    function initCollateral(
        address asset,
        address reinvestment
    ) external onlyConfigurator returns (uint256) {
        DataTypes.CollateralStorage storage collateralStorage = LedgerStorage.getCollateralStorage();
        require(collateralStorage.collateralsList[asset][reinvestment] == 0, Errors.POOL_EXIST);

        collateralStorage.collateralsCount++;
        uint256 localPid = collateralStorage.collateralsCount;
        collateralStorage.collateralsList[asset][reinvestment] = localPid;

        collateralStorage.collaterals[localPid].poolId = localPid;
        collateralStorage.collaterals[localPid].asset = asset;
        collateralStorage.collaterals[localPid].reinvestment = reinvestment;

        return localPid;
    }

    function setCollateralReinvestment(uint256 pid, address newReinvestment) external onlyConfigurator {
        DataTypes.CollateralStorage storage collateralStorage = LedgerStorage.getCollateralStorage();
        DataTypes.CollateralData memory collateral = collateralStorage.collaterals[pid];
        require(collateral.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        collateralStorage.collateralsList[collateral.asset][newReinvestment] = pid;
        delete collateralStorage.collateralsList[collateral.asset][collateral.reinvestment];
        collateralStorage.collaterals[pid].reinvestment = newReinvestment;
    }

    function setCollateralConfiguration(
        uint256 pid,
        DataTypes.CollateralConfiguration memory configuration
    ) public onlyConfigurator {
        require(pid != 0, Errors.POOL_NOT_INITIALIZED);
        LedgerStorage.getCollateralStorage().collaterals[pid].configuration = configuration;
    }

    function depositReserve(address asset, uint256 amount) external nonReentrant onlyWhitelistedCaller {
        ReservePoolLogic.executeDepositReserve(
            msg.sender,
            asset,
            amount
        );
    }

    function withdrawReserve(address asset, uint256 amount) external nonReentrant onlyWhitelistedCaller {
        ReservePoolLogic.executeWithdrawReserve(
            msg.sender,
            asset,
            amount
        );
    }

    function depositCollateral(address asset, address reinvestment, uint256 amount) external nonReentrant onlyWhitelistedCaller {
        CollateralPoolLogic.executeDepositCollateral(
            msg.sender,
            asset,
            reinvestment,
            amount
        );
    }

    function withdrawCollateral(address asset, address reinvestment, uint256 amount) external nonReentrant onlyWhitelistedCaller {
        CollateralPoolLogic.executeWithdrawCollateral(
            msg.sender,
            asset,
            reinvestment,
            amount
        );
    }

    /**
     * @notice Trade
     * @param shortAsset The shorting asset address
     * @param longAsset The longing asset address
     * @param amount The swap amount without fees applied
     * @param data The swap quotes with fees applied
     */
    function trade(address shortAsset, address longAsset, uint256 amount, bytes memory data) external nonReentrant onlyWhitelistedCaller {
        TradeLogic.executeTrade(
            msg.sender,
            shortAsset,
            longAsset,
            amount,
            data
        );
    }

    /**
     * @notice Repay short position
     * @param asset Address
     * @param amount Amount to repay
     */
    function repayShort(address asset, uint256 amount, address behalfOf) external nonReentrant onlyWhitelistedCaller {
        PositionLogic.executeRepayShort(
            msg.sender,
            behalfOf,
            asset,
            amount
        );
    }

    /**
     * @notice Withdraw from long position
     * @param asset Address
     * @param amount Amount to withdraw
     */
    function withdrawLong(address asset, uint256 amount) external nonReentrant onlyWhitelistedCaller {
        PositionLogic.executeWithdrawLong(
            msg.sender,
            asset,
            amount
        );
    }

    function getLibrariesVersion() external pure returns (uint256,uint256,uint256,uint256,uint256,uint256) {
        return (
            GeneralLogic.VERSION,
            ReservePoolLogic.VERSION,
            CollateralPoolLogic.VERSION,
            PositionLogic.VERSION,
            TradeLogic.VERSION,
            LiquidationLogic.VERSION
        );
    }

    /**
     * @notice Get a asset's config
     * @param asset Address
     * @return The asset's config
    */
    function getAssetConfiguration(address asset) external view returns (DataTypes.AssetConfig memory) {
        return LedgerStorage.getAssetStorage().assetConfigs[asset];
    }

    /**
     * @notice Get a reserve data
     * @param asset Address
     * @return The Reserve Data
     */
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory) {
        return LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ];
    }

    /**
     * @notice Get a collateral data
     * @param asset Address
     * @param reinvestment Address
     * @return The Collateral Data
    */
    function getCollateralData(address asset, address reinvestment) external view returns (DataTypes.CollateralData memory) {
        return LedgerStorage.getCollateralStorage().collaterals[
            LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment]
        ];
    }

    /**
     * @notice Get reserve indexes
     * @param asset Address
     * @return reserveIndex reserve index
     * @return protocolIndex protocol index
     * @return borrowIndex borrow index
    */
    function getReserveIndexes(address asset) external override view returns (uint256, uint256, uint256) {
        return ReservePoolLogic.getReserveIndexes(asset);
    }

    /**
     * @notice Get a reserve's list of supply
     * @param asset Address
     * @return availableSupply Available supply
     * @return reserveSupply Reserve supply
     * @return protocolUtilizedSupply Protocol utilized supply
     * @return totalSupply Totality of reserve supply with protocol utilized supply
     * @return utilizedSupply Utilized supply
     */
    function reserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return ReservePoolLogic.getReserveSupplies(asset);
    }

    /**
     * @notice Get collateral total supply
     * @param asset Address
     * @param reinvestment Address where the asset is reinvested in
     * @return collateral Total supply of the collateral
     */
    function collateralTotalSupply(address asset, address reinvestment) external view returns (uint256) {
        return LedgerStorage.getCollateralStorage().collaterals[
            LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment]
        ].getCollateralSupply();
    }

    /**
     * @notice Get user's liquidity
     * @param user_ User's address
     * @return userLiquidity User's liquidity
     */
    function getUserLiquidity(address user_) external view returns (
        DataTypes.UserLiquidity memory
    ) {
        // resolve stack too deep
        address user = user_;

        (DataTypes.UserLiquidity memory result,) = GeneralLogic.getUserLiquidity(
            user,
            address(0),
            address(0)
        );

        return result;
    }

    /**
     * @notice CheckpointReserve
     * @param asset Address
     */
    function checkpointReserve(address asset) external {
        ReservePoolLogic.checkpointReserve(asset);
    }

    /**
     * @notice Claim reinvestment rewards from collateral deposits
     * @param asset Underlying asset address
     * @param reinvestment Address where the asset is reinvested in
     */
    function claimCollateralReinvestmentRewards(address asset, address reinvestment) external {
        CollateralPoolLogic.claimReinvestmentRewards(msg.sender, asset, reinvestment);
    }

    /******************************* ADMIN METHODS *******************************/

    /**
     * @notice Manage pools reinvestment
     * @param actionId Action id
     * @param pid Pool Id
     */
    function managePoolReinvestment(uint256 actionId, uint256 pid) external onlyConfigurator {
        if (actionId == 0) {
            ReservePoolLogic.executeEmergencyWithdrawReserve(pid);
        } else if (actionId == 1) {
            ReservePoolLogic.executeReinvestReserveSupply(pid);
        } else if (actionId == 2) {
            CollateralPoolLogic.executeEmergencyWithdrawCollateral(pid);
        } else if (actionId == 3) {
            CollateralPoolLogic.executeReinvestCollateralSupply(pid);
        } else if (actionId == 4) {
            ReservePoolLogic.executeEmergencyWithdrawLong(pid);
        } else if (actionId == 5) {
            ReservePoolLogic.executeReinvestLongSupply(pid);
        } else {
            revert(Errors.INVALID_ACTION_ID);
        }
    }

    /*
     * @notice Sweep reserve long supply profit
     * @param asset Reserve asset
     */
    function sweepLongReinvestment(address asset) external onlyOperator {
        ReservePoolLogic.executeSweepLongReinvestment(asset);
    }

    /**
     * @notice Sweep unregistered assets in Ledger
     * @param otherAsset Asset address
     */
    function sweep(address otherAsset) external onlyOperator {
        require(LedgerStorage.getAssetStorage().assetConfigs[otherAsset].assetId == 0, Errors.CANNOT_SWEEP_REGISTERED_ASSET);
        IERC20Upgradeable(otherAsset).safeTransfer(
            LedgerStorage.getProtocolConfig().treasury,
            IERC20Upgradeable(otherAsset).balanceOf(address(this))
        );
    }

    /******************************* LIQUIDATION METHODS *******************************/

    /**
     * @notice Foreclose a user
     * @param users collection of user addresses to foreclose
     */
    function foreclose(address[] memory users) external onlyLiquidateExecutor {
        LiquidationLogic.executeForeclosure(users);
    }

    /**
     * @notice Unwrapping LP tokens
     * @param unwrapper Address
     * @param asset Address
     * @param amount Amount
     */
    function unwrapLp(address unwrapper, address asset, uint256 amount) external onlyLiquidateExecutor {
        LiquidationLogic.executeUnwrapLp(unwrapper, asset, amount);
    }

    /**
     * @notice Settle liquidation wallet positions
     * @param assetIn Address
     * @param assetOut Address648
     * @param amount Amount
     * @param data Swap Data
     */
    function swapPosition(address assetIn, address assetOut, uint256 amount, bytes memory data) external onlyLiquidateExecutor {
        TradeLogic.liquidationTrade(assetIn, assetOut, amount, data);
    }

    function withdrawLiquidationWalletLong(address asset, uint256 amount) external onlyOperator {
        LiquidationLogic.executeWithdrawLiquidationWalletLong(asset, amount);
    }

    /********************** MODIFIER *******************************/

    modifier onlyConfigurator() {
        require(LedgerStorage.getProtocolConfig().configuratorAddress == msg.sender, Errors.CALLER_NOT_CONFIGURATOR);
        _;
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), Errors.CALLER_NOT_OPERATOR);
        _;
    }

    modifier onlyWhitelistedCaller() {
        // it should be from an address || it should be from a whitelisted contract
        require(msg.sender == tx.origin || LedgerStorage.getMappingStorage().whitelistedCallers[msg.sender] == true, Errors.CALLER_NOT_WHITELISTED);
        _;
    }

    modifier onlyLiquidateExecutor() {
        require(hasRole(LIQUIDATE_EXECUTOR, msg.sender), Errors.CALLER_NOT_LIQUIDATE_EXECUTOR);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface ILedger {

    function getProtocolConfig() external view returns (DataTypes.ProtocolConfig memory);

    function setProtocolConfig(DataTypes.ProtocolConfig memory config) external;

    function initAssetConfiguration(address asset) external returns (uint256 assetId);

    function setAssetConfiguration(address asset, DataTypes.AssetConfig memory configuration) external;

    function initReserve(address asset) external returns (uint256 poolId);

    function initCollateral(address asset, address reinvestment) external returns (uint256 poolId);

    function setReserveBonusPool(uint256 poolId, address newBonusPool) external;

    function setReserveReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveLongReinvestment(uint256 poolId, address newReinvestment) external;

    function setCollateralReinvestment(uint256 poolId, address newReinvestment) external;

    function setReserveConfiguration(uint256 poolId, DataTypes.ReserveConfiguration memory configuration) external;

    function setCollateralConfiguration(uint256 poolId, DataTypes.CollateralConfiguration memory configuration) external;

    function managePoolReinvestment(uint256 actionId, uint256 poolId) external;

    function getAssetConfiguration(address asset) external view returns (DataTypes.AssetConfig memory);

    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);

    function getCollateralData(address asset, address reinvestment) external view returns (DataTypes.CollateralData memory);

    function getReserveIndexes(address asset) external view returns (uint256, uint256, uint256);

    function reserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256);

    function collateralTotalSupply(address asset, address reinvestment) external view returns (uint256);

    function getUserLiquidity(address user) external view returns (DataTypes.UserLiquidity memory);

    function depositReserve(address asset, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

interface IUserData {
    function depositReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawReserve(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function depositCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 decimals,
        uint256 currReserveSupply
    ) external;

    function withdrawCollateral(
        address user,
        uint256 pid,
        uint256 amount,
        uint256 currReserveSupply,
        uint256 decimals
    ) external;

    function changePosition(
        address user,
        uint256 pid,
        int256 incomingPosition,
        uint256 borrowIndex,
        uint256 decimals
    ) external;

    function getUserConfiguration(address user) external view returns (DataTypes.UserConfiguration memory);

    function getUserReserve(address user, address asset, bool claimable) external view returns (uint256);

    function getUserCollateral(address user, address asset, address reinvestment, bool claimable) external view returns (uint256);

    function getUserCollateralInternal(address user, uint256 pid, uint256 currPoolSupply, uint256 decimals) external view returns (uint256);

    function getUserPosition(address user, address asset) external view returns (int256);

    function getUserPositionInternal(address user, uint256 pid, uint256 borrowIndex, uint256 decimals) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../interfaces/IPriceOracleGetter.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./CollateralLogic.sol";
import "../storage/LedgerStorage.sol";
import "../../interfaces/IUserData.sol";

library GeneralLogic {
    using MathUtils for uint256;
    using MathUtils for int256;
    using UserConfiguration for DataTypes.UserConfiguration;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;

    uint256 public constant VERSION = 2;

    function getAssetAmountFromUsd(
        uint256 usdAmount,
        uint256 assetUnit,
        uint256 assetPrice,
        uint256 assetPriceUnit
    ) public pure returns (uint256) {
        return usdAmount.wadDiv(assetPrice.unitToWad(assetPriceUnit)).wadToUnit(assetUnit);
    }

    function getAssetUsdFromAmount(
        uint256 amount,
        uint256 assetUnit,
        uint256 assetPrice,
        uint256 assetPriceUnit
    ) public pure returns (uint256) {
        return amount.unitToWad(assetUnit).wadMul(assetPrice.unitToWad(assetPriceUnit));
    }

    struct CalculateUserLiquidityVars {
        address asset;
        address reinvestment;
        uint256 currUserCollateral;
        uint256 collateralUsd;
        uint256 positionUsd;
        uint16 i;
        uint256 ltv;
        uint256 assetPrice;
        uint256 assetPriceDecimal;
        int256 currUserPosition;
        DataTypes.ReserveData reserve;
        DataTypes.CollateralData collateral;
        DataTypes.AssetConfig assetConfig;
        DataTypes.UserConfiguration localUserConfig;
    }

    function getUserLiquidity(
        address user,
        address shortingAssetAddress,
        address longingAssetAddress
    ) external view returns (
        DataTypes.UserLiquidity memory,
        DataTypes.UserLiquidityCachedData memory
    ) {
        DataTypes.UserLiquidity memory result;
        DataTypes.UserLiquidityCachedData memory cachedData;
        CalculateUserLiquidityVars memory vars;

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        vars.localUserConfig = IUserData(protocolConfig.userData).getUserConfiguration(user);

        if (vars.localUserConfig.isEmpty()) {
            return (result, cachedData);
        }

        vars.i = 0;

        while (vars.localUserConfig.collateral != 0 || vars.localUserConfig.position != 0) {
            // TODO: can it use vars.i?
            if (vars.localUserConfig.isUsingCollateral(0)) {

                vars.collateral = LedgerStorage.getCollateralStorage().collaterals[vars.i];

                vars.asset = vars.collateral.asset;

                vars.reinvestment = vars.collateral.reinvestment;

                vars.assetConfig = LedgerStorage.getAssetStorage().assetConfigs[vars.asset];

                vars.currUserCollateral = IUserData(protocolConfig.userData).getUserCollateralInternal(
                    user,
                    vars.i,
                    vars.collateral.getCollateralSupply(),
                    vars.assetConfig.decimals
                );

                (vars.assetPrice, vars.assetPriceDecimal) = vars.assetConfig.oracle.getAssetPrice(vars.asset);

                vars.collateralUsd = getAssetUsdFromAmount(
                    vars.currUserCollateral,
                    vars.assetConfig.decimals,
                    vars.assetPrice,
                    vars.assetPriceDecimal
                );

                result.totalCollateralUsdPreLtv += vars.collateralUsd;

                result.totalCollateralUsdPostLtv += vars.collateralUsd.wadMul(
                    uint256(vars.collateral.configuration.ltvGwei).unitToWad(9)
                );
            }

            if (vars.localUserConfig.isUsingPosition(0)) {
                vars.reserve = LedgerStorage.getReserveStorage().reserves[vars.i];

                vars.asset = vars.reserve.asset;
                vars.assetConfig = LedgerStorage.getAssetStorage().assetConfigs[vars.asset];

                (,,uint256 borrowIndex) = vars.reserve.getReserveIndexes();

                vars.currUserPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
                    user,
                    vars.reserve.poolId,
                    borrowIndex,
                    vars.assetConfig.decimals
                );

                (vars.assetPrice, vars.assetPriceDecimal) = vars.assetConfig.oracle.getAssetPrice(vars.asset);

                if (shortingAssetAddress == vars.asset) {
                    cachedData.currShortingPosition = vars.currUserPosition;
                    cachedData.shortingPrice = vars.assetPrice;
                    cachedData.shortingPriceDecimals = vars.assetPriceDecimal;
                } else if (longingAssetAddress == vars.asset) {
                    cachedData.currLongingPosition = vars.currUserPosition;
                    cachedData.longingPrice = vars.assetPrice;
                    cachedData.longingPriceDecimals = vars.assetPriceDecimal;
                }

                vars.positionUsd = getAssetUsdFromAmount(
                    vars.currUserPosition.abs(),
                    vars.assetConfig.decimals,
                    vars.assetPrice,
                    vars.assetPriceDecimal
                );

                if (vars.currUserPosition < 0) {
                    result.totalShortUsd += vars.positionUsd;
                } else {
                    result.totalLongUsd += vars.positionUsd;
                }
            }

            vars.localUserConfig.collateral = vars.localUserConfig.collateral >> 1;

            vars.localUserConfig.position = vars.localUserConfig.position >> 1;

            vars.i++;
        }

        result.pnlUsd = int256(result.totalLongUsd) - int256(result.totalShortUsd);

        result.isLiquidatable = isLiquidatable(result.totalCollateralUsdPreLtv, protocolConfig.liquidationRatioMantissa, result.pnlUsd);

        result.totalLeverageUsd = (int256(result.totalCollateralUsdPostLtv) + result.pnlUsd) * int256(protocolConfig.leverageFactor) / int256(1e18);

        result.availableLeverageUsd = result.totalLeverageUsd - int(result.totalShortUsd);

        return (result, cachedData);
    }

    function isLiquidatable(
        uint256 totalCollateralUsdPreLtv,
        uint256 liquidationRatioMantissa,
        int256 pnlUsd
    ) public pure returns (bool) {
        return (int256(totalCollateralUsdPreLtv.wadMul(liquidationRatioMantissa)) + pnlUsd) < 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../math/MathUtils.sol";
import "../../types/DataTypes.sol";

library CollateralLogic {
    using MathUtils for uint256;

    function getCollateralSupply(
        DataTypes.CollateralData memory collateral
    ) internal view returns (uint256){
        return collateral.reinvestment == address(0)
        ? collateral.liquidSupply
        : IReinvestment(collateral.reinvestment).totalSupply();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../../configuration/UserConfiguration.sol";
import "../math/MathUtils.sol";
import "./HelpersLogic.sol";
import "./ReserveLogic.sol";
import "../../interfaces/IUserData.sol";
import "../../interfaces/IBonusPool.sol";
import "../storage/LedgerStorage.sol";

library ReservePoolLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 3;

    event DepositedReserve(address user, address asset, address reinvestment, uint256 amount);
    event WithdrawnReserve(address user, address asset, address reinvestment, uint256 amount);
    event EmergencyWithdrawnReserve(address asset, uint256 supply);
    event ReinvestedReserveSupply(address asset, uint256 supply);
    event EmergencyWithdrawnLong(address asset, uint256 supply, uint256 amountToTreasury);
    event ReinvestedLongSupply(address asset, uint256 supply);
    event SweepLongReinvestment(address asset, uint256 amountToTreasury);

    function setReserveConfiguration(uint256 pid, DataTypes.ReserveConfiguration memory configuration) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        require(reserve.asset != address(0), Errors.POOL_NOT_INITIALIZED);
        reserve.updateIndex();
        reserve.postUpdateReserveData();
        reserve.configuration = configuration;
    }

    function getReserveIndexes(address asset) external view returns (uint256, uint256, uint256) {
        return LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ].getReserveIndexes();
    }

    function getReserveSupplies(address asset) external view returns (uint256, uint256, uint256, uint256, uint256) {
        return LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ].getReserveSupplies();
    }

    function checkpointReserve(address asset) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[
            LedgerStorage.getReserveStorage().reservesList[asset]
        ];

        reserve.updateIndex();
        reserve.postUpdateReserveData();
    }

    function executeDepositReserve(
        address user, address asset, uint256 amount
    ) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        ValidationLogic.validateDepositReserve(localReserve, amount);

        reserve.updateIndex();

        (,uint256 currReserveSupply,,,) = reserve.getReserveSupplies();
        uint256 currUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);

        IUserData(protocolConfig.userData).depositReserve(user, pid, amount, assetConfig.decimals, currReserveSupply);

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        if (localReserve.ext.reinvestment != address(0)) {
            HelpersLogic.approveMax(asset, localReserve.ext.reinvestment, amount);

            IReinvestment(localReserve.ext.reinvestment).checkpoint(user, currUserReserveBalance);
            IReinvestment(localReserve.ext.reinvestment).invest(amount);
        } else {
            reserve.liquidSupply += amount;
        }

        if (localReserve.ext.bonusPool != address(0)) {
            uint256 nextUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
            IBonusPool(localReserve.ext.bonusPool).updatePoolUser(asset, user, nextUserReserveBalance);
        }

        reserve.postUpdateReserveData();

        emit DepositedReserve(user, asset, localReserve.ext.reinvestment, amount);
    }

    function executeWithdrawReserve(
        address user, address asset, uint256 amount
    ) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        (,uint256 currReserveSupply,,,) = reserve.getReserveSupplies();

        uint256 currUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
        uint256 currUserMaxClaimReserve = IUserData(protocolConfig.userData).getUserReserve(user, asset, true);

        if (amount > currUserMaxClaimReserve) {
            amount = currUserMaxClaimReserve;
        }

        ValidationLogic.validateWithdrawReserve(localReserve, currReserveSupply, amount);

        IUserData(protocolConfig.userData).withdrawReserve(user, pid, amount, assetConfig.decimals, currReserveSupply);

        if (localReserve.ext.reinvestment != address(0)) {
            IReinvestment(localReserve.ext.reinvestment).checkpoint(user, currUserReserveBalance);
            IReinvestment(localReserve.ext.reinvestment).divest(amount);
        } else {
            reserve.liquidSupply -= amount;
        }

        uint256 withdrawalFee;
        if (localReserve.configuration.depositFeeMantissaGwei > 0) {
            withdrawalFee = amount.wadMul(
                uint256(localReserve.configuration.depositFeeMantissaGwei).unitToWad(9)
            );

            IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, withdrawalFee);
        }

        if (localReserve.ext.bonusPool != address(0)) {
            uint256 nextUserReserveBalance = IUserData(protocolConfig.userData).getUserReserve(user, asset, false);
            IBonusPool(localReserve.ext.bonusPool).updatePoolUser(asset, user, nextUserReserveBalance);
        }

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(user, amount - withdrawalFee);

        emit WithdrawnReserve(user, asset, localReserve.ext.reinvestment, amount - withdrawalFee);
    }

    function executeEmergencyWithdrawReserve(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        uint256 priorBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(reserve.ext.reinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        reserve.liquidSupply += withdrawn;

        emit EmergencyWithdrawnReserve(reserve.asset, withdrawn);
    }

    function executeReinvestReserveSupply(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        IERC20Upgradeable(reserve.asset).safeApprove(reserve.ext.reinvestment, reserve.liquidSupply);
        IReinvestment(reserve.ext.reinvestment).invest(reserve.liquidSupply);

        emit ReinvestedReserveSupply(reserve.asset, reserve.liquidSupply);

        reserve.liquidSupply = 0;
    }

    function executeEmergencyWithdrawLong(uint256 pid) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        uint256 priorBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(reserve.ext.longReinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(reserve.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        uint256 amountToTreasury = withdrawn - reserve.longSupply;

        if (amountToTreasury > 0) {
            IERC20Upgradeable(reserve.asset).safeTransfer(protocolConfig.treasury, amountToTreasury);
        }

        emit EmergencyWithdrawnLong(reserve.asset, reserve.longSupply, amountToTreasury);
    }

    // @dev long supply is static and always has value, accrued amount from reinvestment will be transferred to treasury
    // @param reserve Reserve data
    function executeReinvestLongSupply(uint256 pid) external {
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];

        IERC20Upgradeable(reserve.asset).safeApprove(reserve.ext.longReinvestment, reserve.longSupply);
        IReinvestment(reserve.ext.longReinvestment).invest(reserve.longSupply);

        emit ReinvestedLongSupply(reserve.asset, reserve.longSupply);
    }

    function executeSweepLongReinvestment(address asset) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        require(pid != 0, Errors.POOL_NOT_INITIALIZED);

        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.ReserveData memory localReserve = reserve;

        reserve.updateIndex();

        require(localReserve.ext.longReinvestment != address(0), Errors.INVALID_ZERO_ADDRESS);

        uint256 reinvestmentBalance = IReinvestment(localReserve.ext.longReinvestment).totalSupply();
        uint256 amountToTreasury = reinvestmentBalance - reserve.longSupply;

        require(amountToTreasury > 0, Errors.INVALID_ZERO_AMOUNT);

        IReinvestment(localReserve.ext.longReinvestment).divest(amountToTreasury);
        IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, amountToTreasury);

        reserve.postUpdateReserveData();

        emit SweepLongReinvestment(asset, amountToTreasury);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./HelpersLogic.sol";
import "./ValidationLogic.sol";
import "./CollateralLogic.sol";
import "./ReserveLogic.sol";
import "../storage/LedgerStorage.sol";

library CollateralPoolLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 2;

    event DepositedCollateral(address user, address asset, address reinvestment, uint256 amount);
    event WithdrawnCollateral(address user, address asset, address reinvestment, uint256 amount);
    event EmergencyWithdrawnCollateral(address asset, address reinvestment, uint256 supply);
    event ReinvestedCollateralSupply(address asset, address reinvestment, uint256 supply);

    function executeDepositCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        uint256 currCollateralSupply = localCollateral.getCollateralSupply();
        uint256 currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, currCollateralSupply, assetConfig.decimals
        );

        ValidationLogic.validateDepositCollateral(localCollateral, userLastTradeBlock, amount, currUserCollateralBalance);

        IUserData(protocolConfig.userData).depositCollateral(user, pid, amount, assetConfig.decimals, currCollateralSupply);

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        if (reinvestment != address(0)) {
            HelpersLogic.approveMax(asset, reinvestment, amount);

            IReinvestment(reinvestment).checkpoint(user, currUserCollateralBalance);
            IReinvestment(reinvestment).invest(amount);
        } else {
            collateral.liquidSupply += amount;
        }

        emit DepositedCollateral(user, asset, reinvestment, amount);
    }

    struct ExecuteWithdrawVars {
        DataTypes.CollateralData collateralCache;
        uint256 currCollateralSupply;
        uint256 currUserCollateralBalance;
        uint256 maxAmountToWithdraw;
        uint256 feeAmount;
    }

    function executeWithdrawCollateral(
        address user,
        address asset,
        address reinvestment,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        ExecuteWithdrawVars memory vars;

        vars.currCollateralSupply = localCollateral.getCollateralSupply();
        vars.currUserCollateralBalance = IUserData(protocolConfig.userData).getUserCollateralInternal(
            user, pid, vars.currCollateralSupply, assetConfig.decimals
        );

        vars.maxAmountToWithdraw = IUserData(protocolConfig.userData).getUserCollateral(user, asset, reinvestment, true);

        // only allow certain amount to withdraw
        if (amount > vars.maxAmountToWithdraw) {
            amount = vars.maxAmountToWithdraw;
        }

        ValidationLogic.validateWithdrawCollateral(
            localCollateral,
            userLastTradeBlock,
            amount,
            vars.maxAmountToWithdraw,
            vars.currCollateralSupply
        );

        IUserData(protocolConfig.userData).withdrawCollateral(
            user,
            pid,
            amount,
            vars.currCollateralSupply,
            assetConfig.decimals
        );

        if (reinvestment != address(0)) {
            IReinvestment(reinvestment).checkpoint(user, vars.currUserCollateralBalance);
            IReinvestment(reinvestment).divest(amount);
        } else {
            collateral.liquidSupply -= amount;
        }

        if (localCollateral.configuration.depositFeeMantissaGwei > 0) {
            vars.feeAmount = amount.wadMul(
                uint256(localCollateral.configuration.depositFeeMantissaGwei).unitToWad(9)
            );

            IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, vars.feeAmount);
        }

        IERC20Upgradeable(asset).safeTransfer(user, amount - vars.feeAmount);

        emit WithdrawnCollateral(user, asset, reinvestment, amount - vars.feeAmount);
    }

    function executeEmergencyWithdrawCollateral(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        uint256 priorBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this));

        uint256 withdrawn = IReinvestment(collateral.reinvestment).emergencyWithdraw();

        uint256 receivedBalance = IERC20Upgradeable(collateral.asset).balanceOf(address(this)) - priorBalance;
        require(receivedBalance == withdrawn, Errors.ERROR_EMERGENCY_WITHDRAW);

        collateral.liquidSupply += withdrawn;

        emit EmergencyWithdrawnCollateral(collateral.asset, collateral.reinvestment, withdrawn);
    }

    function executeReinvestCollateralSupply(uint256 pid) external {
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];

        IERC20Upgradeable(collateral.asset).safeApprove(collateral.reinvestment, collateral.liquidSupply);
        IReinvestment(collateral.reinvestment).invest(collateral.liquidSupply);

        emit ReinvestedCollateralSupply(collateral.asset, collateral.reinvestment, collateral.liquidSupply);

        collateral.liquidSupply = 0;
    }

    function claimReinvestmentRewards(
        address user,
        address asset,
        address reinvestment
    ) external {
        uint256 pid = LedgerStorage.getCollateralStorage().collateralsList[asset][reinvestment];
        DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[pid];
        DataTypes.CollateralData memory localCollateral = collateral;

        require(localCollateral.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_INACTIVE);
        require(reinvestment != address(0), Errors.INVALID_POOL_REINVESTMENT);

        uint256 currBalance = IUserData(LedgerStorage.getProtocolConfig().userData).getUserCollateral(user, asset, reinvestment, false);

        IReinvestment(reinvestment).claim(user, currBalance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../../configuration/UserConfiguration.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./ReservePoolLogic.sol";
import "./GeneralLogic.sol";
import "./ValidationLogic.sol";
import "../storage/LedgerStorage.sol";

library TradeLogic {
    using MathUtils for uint256;
    using MathUtils for int256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;
    using UserConfiguration for DataTypes.UserConfiguration;

    uint256 public constant VERSION = 4;

    event Trade(address indexed user, address indexed shortAsset, address indexed longAsset, uint256 soldAmount, uint256 boughtAmount, bytes data, uint256 shortAssetPrice, uint256 longAssetPrice);

    struct ExecuteTradeVars {
        DataTypes.AssetConfig shortAssetConfig;
        DataTypes.AssetConfig longAssetConfig;
        DataTypes.ReserveDataCache shortReserveCache;
        DataTypes.ReserveDataCache longReserveCache;
        DataTypes.ProtocolConfig protocolConfig;
        DataTypes.UserLiquidity currUserLiquidity;
        DataTypes.UserLiquidityCachedData cachedData;
        uint256 shortReservePid;
        uint256 longReservePid;
        uint256 receivedAmount;
        uint256 currShortReserveAvailableSupply;
        uint256 shortAssetPrice;
        uint256 shortAssetPriceDecimals;
        uint256 longAssetPrice;
        uint256 longAssetPriceDecimals;
        uint256 maxSellableAmount;
        uint256 maxBorrowableUsd;
        uint256 additionalSellableUsdFromSelling;
        uint256 additionalSellableUsdFromBuying;
        uint256 maxSellableUsd;
    }

    function executeTrade(
        address user,
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        ExecuteTradeVars memory vars;

        vars.protocolConfig = LedgerStorage.getProtocolConfig();

        vars.shortReservePid = LedgerStorage.getReserveStorage().reservesList[shortAsset];
        vars.longReservePid = LedgerStorage.getReserveStorage().reservesList[longAsset];

        DataTypes.ReserveData storage shortReserve = LedgerStorage.getReserveStorage().reserves[vars.shortReservePid];
        DataTypes.ReserveData storage longReserve = LedgerStorage.getReserveStorage().reserves[vars.longReservePid];

        shortReserve.updateIndex();
        longReserve.updateIndex();

        vars.shortAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[shortAsset];
        vars.longAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[longAsset];

        (
        vars.currUserLiquidity,
        vars.cachedData
        ) = GeneralLogic.getUserLiquidity(
            user,
            shortAsset,
            longAsset
        );

        vars.shortReserveCache = shortReserve.cache();
        vars.longReserveCache = longReserve.cache();

        (vars.currShortReserveAvailableSupply,,,,) = shortReserve.getReserveSupplies();

        if (vars.cachedData.shortingPrice == 0) {
            (vars.shortAssetPrice, vars.shortAssetPriceDecimals) = vars.shortAssetConfig.oracle.getAssetPrice(shortAsset);
        } else {
            vars.shortAssetPrice = vars.cachedData.shortingPrice;
            vars.shortAssetPriceDecimals = vars.cachedData.shortingPriceDecimals;
        }

        if (vars.cachedData.longingPrice == 0) {
            (vars.longAssetPrice, vars.longAssetPriceDecimals) = vars.longAssetConfig.oracle.getAssetPrice(longAsset);
        } else {
            vars.longAssetPrice = vars.cachedData.longingPrice;
            vars.longAssetPriceDecimals = vars.cachedData.longingPriceDecimals;
        }

        vars.maxBorrowableUsd = vars.currUserLiquidity.availableLeverageUsd > 0
        ? uint256(vars.currUserLiquidity.availableLeverageUsd)
        : 0;

        // has value if selling asset is a long position
        vars.additionalSellableUsdFromSelling = vars.cachedData.currShortingPosition > 0
        ? GeneralLogic.getAssetUsdFromAmount(
            uint256(vars.cachedData.currShortingPosition),
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        )
        : 0;

        // has value if buying asset is a short position
        vars.additionalSellableUsdFromBuying = vars.cachedData.currLongingPosition < 0
        ? GeneralLogic.getAssetUsdFromAmount(
            uint256((vars.cachedData.currLongingPosition * (- 1))), // make it positive
            vars.longAssetConfig.decimals,
            vars.longAssetPrice,
            vars.longAssetPriceDecimals
        )
        : 0;

        vars.maxSellableUsd = vars.maxBorrowableUsd + vars.additionalSellableUsdFromSelling + vars.additionalSellableUsdFromBuying;

        vars.maxSellableAmount = GeneralLogic.getAssetAmountFromUsd(
            vars.maxSellableUsd,
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        );

        ValidationLogic.validateTrade(
            shortReserve,
            longReserve,
            vars.cachedData.currShortingPosition,
            DataTypes.ValidateTradeParams(
                user,
                amount,
                vars.currShortReserveAvailableSupply,
                vars.maxSellableAmount,
                userLastTradeBlock
            )
        );

        // update reserve data
        executeShorting(
            shortReserve,
            vars.shortAssetConfig,
            vars.cachedData.currShortingPosition,
            amount,
            true
        );

        // update user data
        IUserData(vars.protocolConfig.userData).changePosition(
            user,
            vars.shortReservePid,
            int256(amount) * (- 1),
            vars.shortReserveCache.currBorrowIndexRay,
            vars.shortAssetConfig.decimals
        );

        shortReserve.postUpdateReserveData();

        amount -= transferTradeFee(shortAsset, vars.protocolConfig.treasury, vars.protocolConfig.tradeFeeMantissa, amount);

        vars.receivedAmount = swap(vars.shortAssetConfig, shortAsset, longAsset, amount, data);

        uint256 increasedShortUsd = GeneralLogic.getAssetUsdFromAmount(
            amount,
            vars.shortAssetConfig.decimals,
            vars.shortAssetPrice,
            vars.shortAssetPriceDecimals
        );

        uint256 increasedLongUsd = GeneralLogic.getAssetUsdFromAmount(
            vars.receivedAmount,
            vars.longAssetConfig.decimals,
            vars.longAssetPrice,
            vars.longAssetPriceDecimals
        );

        vars.currUserLiquidity.pnlUsd += (int256(increasedLongUsd) - int256(increasedShortUsd));

        require(
            GeneralLogic.isLiquidatable(
                vars.currUserLiquidity.totalCollateralUsdPreLtv,
                vars.protocolConfig.liquidationRatioMantissa,
                vars.currUserLiquidity.pnlUsd
            ) == false,
            Errors.BAD_TRADE
        );

        // update reserve data
        executeLonging(
            longReserve,
            vars.longAssetConfig,
            vars.protocolConfig.treasury,
            vars.cachedData.currLongingPosition,
            vars.receivedAmount,
            true
        );

        // update user data
        IUserData(vars.protocolConfig.userData).changePosition(
            user,
            vars.longReservePid,
            int256(vars.receivedAmount),
            vars.longReserveCache.currBorrowIndexRay,
            vars.longAssetConfig.decimals
        );

        longReserve.postUpdateReserveData();

        LedgerStorage.getMappingStorage().userLastTradeBlock[user] = block.number;

        emit Trade(
            user,
            shortAsset,
            longAsset,
            amount,
            vars.receivedAmount,
            data,
            vars.shortAssetPrice,
            vars.longAssetPrice
        );
    }

    struct LiquidationTradeVars {
        DataTypes.ProtocolConfig protocolConfig;
        DataTypes.AssetConfig shortAssetConfig;
        DataTypes.AssetConfig longAssetConfig;
        DataTypes.ReserveDataCache shortReserveCache;
        DataTypes.ReserveDataCache longReserveCache;
        uint256 shortReservePid;
        uint256 longReservePid;
        int256 userShortPosition;
        int256 userLongPosition;
        uint256 amountShorted;
        uint256 maxAmountToShort;
        uint256 shortAssetPrice;
        uint256 shortAssetDecimals;
        uint256 longAssetPrice;
        uint256 longAssetDecimals;
        uint256 receivedAmount;
    }

    function liquidationTrade(
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) external {
        LiquidationTradeVars memory vars;

        vars.protocolConfig = LedgerStorage.getProtocolConfig();

        vars.shortAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[shortAsset];
        vars.longAssetConfig = LedgerStorage.getAssetStorage().assetConfigs[longAsset];

        vars.shortReservePid = LedgerStorage.getReserveStorage().reservesList[shortAsset];
        vars.longReservePid = LedgerStorage.getReserveStorage().reservesList[longAsset];

        DataTypes.ReserveData storage shortReserve = LedgerStorage.getReserveStorage().reserves[vars.shortReservePid];
        DataTypes.ReserveData storage longReserve = LedgerStorage.getReserveStorage().reserves[vars.longReservePid];

        shortReserve.updateIndex();
        longReserve.updateIndex();

        vars.shortReserveCache = shortReserve.cache();
        vars.longReserveCache = longReserve.cache();

        (vars.shortAssetPrice, vars.shortAssetDecimals) = vars.shortAssetConfig.oracle.getAssetPrice(shortAsset);
        (vars.longAssetPrice, vars.longAssetDecimals) = vars.longAssetConfig.oracle.getAssetPrice(longAsset);

        vars.userShortPosition = IUserData(vars.protocolConfig.userData).getUserPosition(DataTypes.LIQUIDATION_WALLET, shortAsset);
        vars.userLongPosition = IUserData(vars.protocolConfig.userData).getUserPosition(DataTypes.LIQUIDATION_WALLET, longAsset);

        (, vars.amountShorted) = executeShorting(
            shortReserve,
            vars.shortAssetConfig,
            vars.userShortPosition,
            amount,
            false
        );

        if (vars.amountShorted > 0) {
            require(vars.shortAssetConfig.kind == DataTypes.AssetKind.SingleStable, Errors.INVALID_ASSET_INPUT);

            vars.maxAmountToShort = GeneralLogic.getAssetAmountFromUsd(
                GeneralLogic.getAssetUsdFromAmount(
                    vars.userLongPosition.abs(),
                    vars.longAssetConfig.decimals,
                    vars.longAssetPrice,
                    vars.longAssetDecimals
                ),
                vars.shortAssetConfig.decimals,
                vars.shortAssetPrice,
                vars.shortAssetDecimals
            ).unitToWad(vars.shortAssetConfig.decimals)
            .wadMul(vars.protocolConfig.swapBufferLimitPercentage)
            .wadToUnit(vars.shortAssetConfig.decimals);

            require(vars.amountShorted <= vars.maxAmountToShort, Errors.INVALID_AMOUNT_INPUT);
        }

        IUserData(vars.protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            vars.shortReservePid,
            int256(amount) * (- 1),
            vars.shortReserveCache.currBorrowIndexRay,
            vars.shortAssetConfig.decimals
        );

        shortReserve.postUpdateReserveData();

        vars.receivedAmount = swap(vars.shortAssetConfig, shortAsset, longAsset, amount, data);

        executeLonging(
            longReserve,
            vars.longAssetConfig,
            vars.protocolConfig.treasury,
            vars.userLongPosition,
            vars.receivedAmount,
            false
        );

        IUserData(vars.protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            vars.longReservePid,
            int256(vars.receivedAmount),
            vars.longReserveCache.currBorrowIndexRay,
            vars.longAssetConfig.decimals
        );

        longReserve.postUpdateReserveData();

        emit Trade(DataTypes.LIQUIDATION_WALLET, shortAsset, longAsset, amount, vars.receivedAmount, data, vars.shortAssetPrice, vars.longAssetPrice);
    }

    function transferTradeFee(
        address asset,
        address treasury,
        uint256 tradeFeeMantissa,
        uint256 tradeAmount
    ) private returns (uint256) {
        if (tradeFeeMantissa == 0) return 0;

        uint256 feeAmount = tradeAmount.wadMul(tradeFeeMantissa);
        IERC20Upgradeable(asset).safeTransfer(treasury, feeAmount);

        return feeAmount;
    }

    function swap(
        DataTypes.AssetConfig memory shortAssetConfig,
        address shortAsset,
        address longAsset,
        uint256 amount,
        bytes memory data
    ) private returns (uint256) {
        if (
            IERC20Upgradeable(shortAsset).allowance(address(this), address(shortAssetConfig.swapAdapter)) < amount
        ) {
            IERC20Upgradeable(shortAsset).safeApprove(address(shortAssetConfig.swapAdapter), 0);
            IERC20Upgradeable(shortAsset).safeApprove(address(shortAssetConfig.swapAdapter), type(uint256).max);
        }

        return shortAssetConfig.swapAdapter.swap(shortAsset, longAsset, amount, data);
    }

    struct ExecuteShortingVars {
        uint256 unit;
        uint256 amountToBorrow;
        uint256 amountLongToWithdraw;
        uint256 amountReserveToDivest;
        int256 newPosition;
        DataTypes.ReserveDataCache reserveCache;
    }

    /**
     * @notice May decrease long supply, reserve supply and increase utilized supply depending on current users position and shorting amount
     * @param reserve reserveConfig
     * @param assetConfigCache assetConfigCache
     * @param currUserPosition currUserPosition
     * @param amountToShort shorting amount
     * @param fromLongSupply `true` will decrease long supply, `false` will not
     * @return amount
     * @return amount borrowed from the reserve
     **/
    function executeShorting(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfigCache,
        int256 currUserPosition,
        uint256 amountToShort,
        bool fromLongSupply
    ) public returns (uint256, uint256){
        ExecuteShortingVars memory vars;

        vars.unit = assetConfigCache.decimals;

        vars.reserveCache = reserve.cache();

        if (currUserPosition < 0) {
            // current position is short already
            vars.amountToBorrow = amountToShort;
        } else {
            // use long position to cover for shorting amount when available
            uint256 absCurrUserPosition = currUserPosition.abs();
            if (amountToShort > absCurrUserPosition) {
                // long position is not enough, borrow only lacking amount from reserve
                vars.amountLongToWithdraw = absCurrUserPosition;
                vars.amountToBorrow = amountToShort - absCurrUserPosition;
            } else {
                // long position can cover whole shorting amount, only use required shorting amount
                vars.amountLongToWithdraw = amountToShort;
                vars.amountToBorrow = 0;
            }
        }

        if (vars.amountLongToWithdraw > 0 && fromLongSupply) {
            reserve.longSupply -= vars.amountLongToWithdraw;

            if (reserve.ext.longReinvestment != address(0)) {
                IReinvestment(reserve.ext.longReinvestment).divest(vars.amountLongToWithdraw);
            }
        }

        if (vars.amountToBorrow > 0) {
            reserve.scaledUtilizedSupplyRay += vars.amountToBorrow.unitToRay(vars.unit).rayDiv(vars.reserveCache.currBorrowIndexRay);

            if (reserve.ext.reinvestment != address(0)) {
                IReinvestment(reserve.ext.reinvestment).divest(vars.amountToBorrow);
            } else {
                reserve.liquidSupply -= vars.amountToBorrow;
            }
        }

        require(
            IERC20Upgradeable(reserve.asset).balanceOf(address(this)) >= amountToShort,
            Errors.NOT_ENOUGH_POOL_BALANCE
        );

        return (amountToShort, vars.amountToBorrow);
    }

    struct ExecuteLongingVars {
        uint256 protocolClaimableAmount;
        uint256 amountLongToDeposit;
        uint256 amountToRepay;
        int256 newPosition;
        DataTypes.ReserveDataCache reserveCache;
    }

    /**
     * @notice executeLonging
     * @param reserve reserveConfig
     * @param assetConfigCache assetConfigCache
     * @param treasury treasury
     * @param currUserPosition currUserPosition
     * @param amountToLong amountToLong
     * @param toLongSupply will long amount goes to reserve long supply
     **/
    function executeLonging(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfigCache,
        address treasury,
        int256 currUserPosition,
        uint256 amountToLong,
        bool toLongSupply
    ) public {
        ExecuteLongingVars memory vars;

        // TODO: can refactor to better condition statement
        require(
            IERC20Upgradeable(reserve.asset).balanceOf(address(this)) >= amountToLong,
            Errors.MISSING_UNDERLYING_ASSET
        );

        vars.reserveCache = reserve.cache();

        if (currUserPosition < 0) {
            // repay current short position
            uint256 absCurrUserPosition = currUserPosition.abs();
            if (amountToLong > absCurrUserPosition) {
                // repay accumulated borrowed amount
                vars.amountToRepay = absCurrUserPosition;
                // long amount can cover all short, remaining long will be added to long supply
                vars.amountLongToDeposit = amountToLong - vars.amountToRepay;
            } else {
                // long amount is enough or not to pay short
                vars.amountLongToDeposit = 0;
                vars.amountToRepay = amountToLong;
            }
        } else {
            // current position is long already
            vars.amountLongToDeposit = amountToLong;
        }

        if (vars.amountLongToDeposit > 0 && toLongSupply) {
            reserve.longSupply += vars.amountLongToDeposit;

            if (reserve.ext.longReinvestment != address(0)) {
                invest(reserve.asset, reserve.ext.longReinvestment, vars.amountLongToDeposit);
            }
        }

        if (vars.amountToRepay > 0) {
            // protocol fee is included to users' debt

            // sent protocol fee portions to treasury
            vars.protocolClaimableAmount = vars.amountToRepay
            .unitToRay(assetConfigCache.decimals)
            .rayDiv(vars.reserveCache.currBorrowIndexRay)
            .rayMul(vars.reserveCache.currProtocolIndexRay)
            .rayToUnit(assetConfigCache.decimals);

            IERC20Upgradeable(reserve.asset).safeTransfer(treasury, vars.protocolClaimableAmount);

            // utilized supply is combination of protocol fee + reserve utilization.
            // reduce utilization according to amount repaid with protocol
            reserve.scaledUtilizedSupplyRay -= vars.amountToRepay
            .unitToRay(assetConfigCache.decimals)
            .rayDiv(vars.reserveCache.currBorrowIndexRay);

            // pay back to reserve pool the remainder
            vars.amountToRepay -= vars.protocolClaimableAmount;

            if (reserve.ext.reinvestment != address(0)) {
                invest(reserve.asset, reserve.ext.reinvestment, vars.amountToRepay);
            } else {
                reserve.liquidSupply += vars.amountToRepay;
            }
        }
    }

    function invest(address asset, address reinvestment, uint256 amount) private {
        if (IERC20Upgradeable(asset).allowance(address(this), reinvestment) < amount) {
            IERC20Upgradeable(asset).safeApprove(reinvestment, 0);
            IERC20Upgradeable(asset).safeApprove(reinvestment, type(uint256).max);
        }
        IReinvestment(reinvestment).invest(amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IUnwrapLp.sol";
import "../../configuration/UserConfiguration.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./TradeLogic.sol";
import "./CollateralLogic.sol";
import "./GeneralLogic.sol";
import "../storage/LedgerStorage.sol";

library LiquidationLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using UserConfiguration for DataTypes.UserConfiguration;
    using ReserveLogic for DataTypes.ReserveData;
    using CollateralLogic for DataTypes.CollateralData;

    uint256 public constant VERSION = 4;

    event Foreclosed(address indexed user, uint256 totalCollateralPreLtv, int256 pnlUsd);
    event ForeclosedCollateral(address indexed user, address indexed asset, address indexed reinvestment, uint256 amount);
    event ForeclosedPosition(address indexed user, address indexed asset, int256 amount);
    event UnwrappedLp(address assetIn, uint256 amountIn, address assetOut, uint256 amountOut);
    event SettledPosition(address assetIn, address assetOut, uint256 amount, bytes data);
    event WithdrawnLiquidationWalletLong(address asset, uint256 amount);

    function executeUnwrapLp(address unwrapper, address assetIn, uint256 amountIn) external {
        DataTypes.MappingStorage storage mStorage = LedgerStorage.getMappingStorage();

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        require(amountIn <= mStorage.liquidatedCollaterals[assetIn], Errors.NOT_ENOUGH_BALANCE);

        IERC20Upgradeable(assetIn).safeApprove(unwrapper, amountIn);

        mStorage.liquidatedCollaterals[assetIn] -= amountIn;

        address assetOut = IUnwrapLp(unwrapper).getAssetOut(assetIn);

        uint256 priorBalance = IERC20Upgradeable(assetOut).balanceOf(address(this));

        (, uint256 amountOut) = IUnwrapLp(unwrapper).unwrap(assetIn, amountIn);

        uint256 receivedBalance = IERC20Upgradeable(assetOut).balanceOf(address(this)) - priorBalance;

        require(receivedBalance == amountOut, Errors.ERROR_UNWRAP_LP);

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[assetOut];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[assetOut];
        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        int256 liquidationWalletAssetPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        // repay if liquidation wallet has short on asset output
        if (liquidationWalletAssetPosition < 0) {
            TradeLogic.executeLonging(
                reserve,
                assetConfig,
                protocolConfig.treasury,
                liquidationWalletAssetPosition,
                amountOut,
                false
            );

        }

        reserve.postUpdateReserveData();

        IUserData(protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            int256(amountOut),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        emit UnwrappedLp(assetIn, amountIn, assetOut, amountOut);
    }

    struct ExecuteForeclosureVars {
        address user;
        uint256 i;
        uint256 collateralPid;
        uint256 reservePid;
        DataTypes.CollateralData localCollateral;
        DataTypes.UserConfiguration localUserConfig;
    }

    /**
     * @notice Executes a foreclosure
     * @param users users
     **/
    function executeForeclosure(address[] memory users) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        ExecuteForeclosureVars memory vars;

        for (vars.i = 0; vars.i < users.length; vars.i++) {
            vars.user = users[vars.i];

            (
            DataTypes.UserLiquidity memory currUserLiquidity,
            ) = GeneralLogic.getUserLiquidity(
                vars.user,
                address(0),
                address(0)
            );

            if (!currUserLiquidity.isLiquidatable) {
                continue;
            }

            vars.localUserConfig = IUserData(protocolConfig.userData).getUserConfiguration(vars.user);

            // close collaterals
            vars.collateralPid = 0;
            while (vars.localUserConfig.hasCollateral(vars.collateralPid)) {
                if (vars.localUserConfig.isUsingCollateral(vars.collateralPid)) {
                    DataTypes.CollateralData storage collateral = LedgerStorage.getCollateralStorage().collaterals[vars.collateralPid];
                    vars.localCollateral = collateral;

                    vars.reservePid = LedgerStorage.getReserveStorage().reservesList[vars.localCollateral.asset];
                    DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[vars.reservePid];

                    reserve.updateIndex();

                    _forecloseCollateral(
                        reserve,
                        collateral,
                        ForecloseCollateralParams(
                            vars.user,
                            protocolConfig.treasury,
                            vars.reservePid,
                            reserve.cache().currBorrowIndexRay,
                            vars.collateralPid,
                            IUserData(protocolConfig.userData),
                            LedgerStorage.getAssetStorage().assetConfigs[vars.localCollateral.asset]
                        )
                    );
                }

                vars.collateralPid++;
            }

            // close positions
            vars.reservePid = 0;
            while (vars.localUserConfig.hasPosition(vars.reservePid)) {
                if (vars.localUserConfig.isUsingPosition(vars.reservePid)) {
                    DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[vars.reservePid];
                    reserve.updateIndex();

                    _foreclosePosition(
                        reserve,
                        LedgerStorage.getAssetStorage().assetConfigs[reserve.asset],
                        vars.user,
                        protocolConfig.treasury,
                        vars.reservePid,
                        reserve.cache().currBorrowIndexRay,
                        IUserData(protocolConfig.userData)
                    );
                }

                vars.reservePid++;
            }

            emit Foreclosed(
                vars.user,
                currUserLiquidity.totalCollateralUsdPreLtv,
                currUserLiquidity.pnlUsd
            );
        }
    }

    struct ForecloseCollateralParams {
        address user;
        address treasury;
        uint256 reservePoolId;
        uint256 reserveBorrowIndexRay;
        uint256 collateralPoolId;
        IUserData userData;
        DataTypes.AssetConfig assetConfig;
    }

    function _forecloseCollateral(
        DataTypes.ReserveData storage reserve,
        DataTypes.CollateralData storage collateral,
        ForecloseCollateralParams memory params
    ) private {
        DataTypes.MappingStorage storage mStorage = LedgerStorage.getMappingStorage();
        DataTypes.CollateralData memory localCollateral = collateral;

        uint256 currCollateralSupply = localCollateral.getCollateralSupply();
        uint256 currUserCollateral = params.userData.getUserCollateral(
            params.user,
            localCollateral.asset,
            localCollateral.reinvestment,
            false
        );

        params.userData.withdrawCollateral(
            params.user,
            params.collateralPoolId,
            currUserCollateral,
            currCollateralSupply,
            params.assetConfig.decimals
        );

        if (localCollateral.reinvestment != address(0)) {
            IReinvestment(localCollateral.reinvestment).checkpoint(params.user, currUserCollateral);
            IReinvestment(localCollateral.reinvestment).divest(currUserCollateral);
        } else {
            collateral.liquidSupply -= currUserCollateral;
        }

        if (params.assetConfig.kind == DataTypes.AssetKind.LP) {
            mStorage.liquidatedCollaterals[localCollateral.asset] += currUserCollateral;
        } else {
            int256 liquidationAssetPosition = params.userData.getUserPositionInternal(
                DataTypes.LIQUIDATION_WALLET,
                params.reservePoolId,
                params.reserveBorrowIndexRay,
                params.assetConfig.decimals
            );

            // make single asset to be position, repay any short position, but don't added to reserve long supply
            TradeLogic.executeLonging(
                reserve,
                params.assetConfig,
                params.treasury,
                liquidationAssetPosition,
                currUserCollateral,
                false
            );

            params.userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                params.reservePoolId,
                int256(currUserCollateral),
                params.reserveBorrowIndexRay,
                params.assetConfig.decimals
            );
        }

        reserve.postUpdateReserveData();

        emit ForeclosedCollateral(params.user, localCollateral.asset, localCollateral.reinvestment, currUserCollateral);
    }

    function _foreclosePosition(
        DataTypes.ReserveData storage reserve,
        DataTypes.AssetConfig memory assetConfig,
        address user,
        address treasury,
        uint256 reservePoolId,
        uint256 currBorrowIndexRay,
        IUserData userData
    ) private {
        address asset = reserve.asset;

        int256 userAssetPosition = userData.getUserPositionInternal(
            user,
            reservePoolId,
            currBorrowIndexRay,
            assetConfig.decimals
        );

        int256 liquidationAssetPosition = userData.getUserPositionInternal(
            DataTypes.LIQUIDATION_WALLET,
            reservePoolId,
            currBorrowIndexRay,
            assetConfig.decimals
        );

        if (userAssetPosition >= 0) {

            /*
            userAssetPosition is passed both as currentPosition and incomingPosition
            this is done to withdraw all users long to ledger contract
            `true`: long supply will decrease
            */
            TradeLogic.executeShorting(
                reserve,
                assetConfig,
                userAssetPosition,
                uint256(userAssetPosition),
                true
            );

            userData.changePosition(
                user,
                reservePoolId,
                userAssetPosition * (- 1),
                currBorrowIndexRay,
                assetConfig.decimals
            );

            /*
            add long to liquidation wallet position (without reinvesting and fees)
            `false`: long supply won't increase
            */
            TradeLogic.executeLonging(
                reserve,
                assetConfig,
                treasury,
                liquidationAssetPosition,
                uint256(userAssetPosition),
                false
            );

            userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                reservePoolId,
                userAssetPosition,
                currBorrowIndexRay,
                assetConfig.decimals
            );

        } else {
            // NOTE: TradeLogic.executeShorting will not be called since there is no borrowing happening
            // user position short, we assign that position to liquidation wallet, reserve supply remains the same
            uint256 amountToRepay;

            // repay user short with liquidation wallet if has any
            if (liquidationAssetPosition > 0) {
                /*
                expecting there is enough long position to repay user position
                will be reduce if long position available is not enough, will be overwritten with current long amount
                lacking amount will be a shorting to liquidation wallet
                */
                amountToRepay = uint256(userAssetPosition * (- 1));

                // use liquidation wallet long position to repay users' short position
                // only repay upto the liquidation wallet long position
                if (amountToRepay >= uint256(liquidationAssetPosition)) {
                    amountToRepay = uint256(liquidationAssetPosition);
                }

                // this is repays of user's short with existing long position of liquidation wallet in Ledger
                // only repay what is available
                // `false`: long supply won't increase
                TradeLogic.executeLonging(
                    reserve,
                    assetConfig,
                    treasury,
                    userAssetPosition,
                    amountToRepay,
                    false
                );

            }

            // clear user short position
            userData.changePosition(
                user,
                reservePoolId,
                userAssetPosition * (- 1), // make it positive
                currBorrowIndexRay,
                assetConfig.decimals
            );

            // assign users' short position to liquidation wallet by shorting with users' short amount
            userData.changePosition(
                DataTypes.LIQUIDATION_WALLET,
                reservePoolId,
                userAssetPosition,
                currBorrowIndexRay,
                assetConfig.decimals
            );
        }

        reserve.postUpdateReserveData();

        emit ForeclosedPosition(user, asset, userAssetPosition);
    }

    function executeWithdrawLiquidationWalletLong(
        address asset, uint256 amount
    ) external {
        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        (
        DataTypes.UserLiquidity memory currUserLiquidity,
        DataTypes.UserLiquidityCachedData memory cachedData
        ) = GeneralLogic.getUserLiquidity(
            DataTypes.LIQUIDATION_WALLET,
            address(0),
            asset
        );

        require(cachedData.currLongingPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);

        if (uint256(cachedData.currLongingPosition) < amount) {
            amount = uint256(cachedData.currLongingPosition);
        }

        require(currUserLiquidity.pnlUsd > 0, Errors.NEGATIVE_PNL);

        // this is always filled whenever `currPosition` is not zero
        uint256 assetPriceInWad = cachedData.longingPrice.unitToWad(cachedData.longingPriceDecimals);

        uint256 maxAmount = uint256(currUserLiquidity.pnlUsd).wadDiv(assetPriceInWad).wadToUnit(assetConfig.decimals);

        if (maxAmount < amount) {
            amount = maxAmount;
        }

        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);

        TradeLogic.executeShorting(
            reserve,
            assetConfig,
            cachedData.currLongingPosition,
            amount,
            false
        );

        IUserData(protocolConfig.userData).changePosition(
            DataTypes.LIQUIDATION_WALLET,
            pid,
            int256(amount) * (-1),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(protocolConfig.treasury, amount);

        emit WithdrawnLiquidationWalletLong(asset, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../math/MathUtils.sol";
import "./ReserveLogic.sol";
import "./GeneralLogic.sol";
import "./TradeLogic.sol";
import "../../types/DataTypes.sol";

library PositionLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ReserveLogic for DataTypes.ReserveData;

    uint256 public constant VERSION = 3;

    event RepaidShort(address user, address asset, uint256 amount, address behalfOf);
    event WithdrawnLong(address user, address asset, uint256 amount);

    function executeRepayShort(
        address user,
        address behalfOf,
        address asset,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        int256 currNormalizedPosition = IUserData(protocolConfig.userData).getUserPositionInternal(
            behalfOf,
            pid,
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        // cap amount to max repayable
        if (currNormalizedPosition < 0) {
            uint256 absCurrPosition = uint256(currNormalizedPosition * (- 1));
            if (amount > absCurrPosition) {
                amount = absCurrPosition;
            }
        } else {
            amount = 0;
        }

        ValidationLogic.validateRepayShort(
            currNormalizedPosition,
            userLastTradeBlock,
            user,
            asset,
            amount,
            reserve.configuration.state,
            reserve.configuration.mode
        );

        IERC20Upgradeable(asset).safeTransferFrom(user, address(this), amount);

        // repaid amount cannot exceed current short position
        // amount will not be invested to long
        TradeLogic.executeLonging(
            reserve,
            assetConfig,
            protocolConfig.treasury,
            currNormalizedPosition,
            amount,
            true
        );

        reserve.postUpdateReserveData();

        IUserData(protocolConfig.userData).changePosition(
            behalfOf,
            pid,
            int256(amount),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        emit RepaidShort(user, asset, amount, behalfOf);
    }

    struct ExecuteWithdrawLongVars {
        int256 pnlUsd;
        uint256 assetPrice;
        uint256 assetPriceDecimal;
        uint256 assetPriceInWad;
        uint256 assetUnit;
        uint256 maxAmount;
        int256 userAssetPosition;
    }

    function executeWithdrawLong(
        address user,
        address asset,
        uint256 amount
    ) external {
        uint256 userLastTradeBlock = LedgerStorage.getMappingStorage().userLastTradeBlock[user];

        DataTypes.ProtocolConfig memory protocolConfig = LedgerStorage.getProtocolConfig();

        uint256 pid = LedgerStorage.getReserveStorage().reservesList[asset];
        DataTypes.ReserveData storage reserve = LedgerStorage.getReserveStorage().reserves[pid];
        DataTypes.AssetConfig memory assetConfig = LedgerStorage.getAssetStorage().assetConfigs[asset];

        reserve.updateIndex();

        DataTypes.ReserveDataCache memory reserveCache = reserve.cache();

        (
        DataTypes.UserLiquidity memory currUserLiquidity,
        DataTypes.UserLiquidityCachedData memory cachedData
        ) = GeneralLogic.getUserLiquidity(
            user,
            asset,
            address(0)
        );

        ExecuteWithdrawLongVars memory vars;

        require(currUserLiquidity.pnlUsd > 0, Errors.NEGATIVE_AVAILABLE_LEVERAGE);

        if (cachedData.shortingPrice > 0) {
            vars.assetPrice = cachedData.shortingPrice;
            vars.assetPriceDecimal = cachedData.shortingPriceDecimals;
        } else {
            (vars.assetPrice, vars.assetPriceDecimal) = assetConfig.oracle.getAssetPrice(asset);
        }

        vars.assetPriceInWad = vars.assetPrice.unitToWad(vars.assetPriceDecimal);

        // Note: we calculate by wad, which may result in 1 wei less than expected
        // It is okay to be less then to be over
        vars.maxAmount = uint256(currUserLiquidity.pnlUsd).wadDiv(vars.assetPriceInWad).wadToUnit(assetConfig.decimals);

        if (amount > vars.maxAmount) {
            amount = vars.maxAmount;
        }

        vars.userAssetPosition = cachedData.currShortingPosition;

        ValidationLogic.validateWithdrawLong(
            vars.userAssetPosition,
            userLastTradeBlock,
            amount,
            reserve.configuration.state,
            reserve.configuration.mode
        );

        TradeLogic.executeShorting(
            reserve,
            assetConfig,
            vars.userAssetPosition,
            amount,
            true
        );

        IUserData(protocolConfig.userData).changePosition(
            user,
            pid,
            int256(amount) * (- 1),
            reserveCache.currBorrowIndexRay,
            assetConfig.decimals
        );

        reserve.postUpdateReserveData();

        IERC20Upgradeable(asset).safeTransfer(user, amount);

        emit WithdrawnLong(user, asset, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library Errors {
    string public constant LEDGER_INITIALIZED = 'LEDGER_INITIALIZED';
    string public constant CALLER_NOT_OPERATOR = 'CALLER_NOT_OPERATOR';
    string public constant CALLER_NOT_LIQUIDATE_EXECUTOR = 'CALLER_NOT_LIQUIDATE_EXECUTOR';
    string public constant CALLER_NOT_CONFIGURATOR = 'CALLER_NOT_CONFIGURATOR';
    string public constant CALLER_NOT_WHITELISTED = 'CALLER_NOT_WHITELISTED';
    string public constant CALLER_NOT_LEDGER = 'ONLY_LEDGER';
    string public constant INVALID_LEVERAGE_FACTOR = 'INVALID_LEVERAGE_FACTOR';
    string public constant INVALID_LIQUIDATION_RATIO = 'INVALID_LIQUIDATION_RATIO';
    string public constant INVALID_TRADE_FEE = 'INVALID_TRADE_FEE';
    string public constant INVALID_ZERO_ADDRESS = 'INVALID_ZERO_ADDRESS';
    string public constant INVALID_ASSET_CONFIGURATION = 'INVALID_ASSET_CONFIGURATION';
    string public constant ASSET_INACTIVE = 'ASSET_INACTIVE';
    string public constant ASSET_ACTIVE = 'ASSET_ACTIVE';
    string public constant POOL_INACTIVE = 'POOL_INACTIVE';
    string public constant POOL_ACTIVE = 'POOL_ACTIVE';
    string public constant POOL_EXIST = 'POOL_EXIST';
    string public constant INVALID_POOL_REINVESTMENT = 'INVALID_POOL_REINVESTMENT';
    string public constant ASSET_INITIALIZED = 'ASSET_INITIALIZED';
    string public constant ASSET_NOT_INITIALIZED = 'ASSET_NOT_INITIALIZED';
    string public constant POOL_INITIALIZED = 'POOL_INITIALIZED';
    string public constant POOL_NOT_INITIALIZED = 'POOL_NOT_INITIALIZED';
    string public constant INVALID_ZERO_AMOUNT = 'INVALID_ZERO_AMOUNT';
    string public constant CANNOT_SWEEP_REGISTERED_ASSET = 'CANNOT_SWEEP_REGISTERED_ASSET';
    string public constant INVALID_ACTION_ID = 'INVALID_ACTION_ID';
    string public constant INVALID_POSITION_TYPE = 'INVALID_POSITION_TYPE';
    string public constant INVALID_AMOUNT_INPUT = 'INVALID_AMOUNT_INPUT';
    string public constant INVALID_ASSET_INPUT = 'INVALID_ASSET_INPUT';
    string public constant INVALID_SWAP_BUFFER_LIMIT = 'INVALID_SWAP_BUFFER_LIMIT';
    string public constant NOT_ENOUGH_BALANCE = 'NOT_ENOUGH_BALANCE';
    string public constant NOT_ENOUGH_LONG_BALANCE = 'NOT_ENOUGH_LONG_BALANCE';
    string public constant NOT_ENOUGH_POOL_BALANCE = 'NOT_ENOUGH_POOL_BALANCE';
    string public constant NOT_ENOUGH_USER_LEVERAGE = 'NOT_ENOUGH_USER_LEVERAGE';
    string public constant MISSING_UNDERLYING_ASSET = 'MISSING_UNDERLYING_ASSET';
    string public constant NEGATIVE_PNL = 'NEGATIVE_PNL';
    string public constant NEGATIVE_AVAILABLE_LEVERAGE = 'NEGATIVE_AVAILABLE_LEVERAGE';
    string public constant BAD_TRADE = 'BAD_TRADE';
    string public constant USER_TRADE_BLOCK = 'USER_TRADE_BLOCK';
    string public constant ERROR_EMERGENCY_WITHDRAW = 'ERROR_EMERGENCY_WITHDRAW';
    string public constant ERROR_UNWRAP_LP = 'ERROR_UNWRAP_LP';
    string public constant CANNOT_TRADE_SAME_ASSET = 'CANNOT_TRADE_SAME_ASSET';
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../interfaces/ISwapAdapter.sol";
import "../interfaces/IPriceOracleGetter.sol";
import "../interfaces/IReinvestment.sol";
import "../interfaces/IBonusPool.sol";
import "../interfaces/IUserData.sol";

/// @dev This help resolves cyclic dependencies
library DataTypes {

    uint256 public constant VERSION = 1;

    address public constant LIQUIDATION_WALLET = 0x0000000000000000000000000000000000000001;

    enum AssetState {Disabled, Active, Withdrawing}

    enum PositionType {Long, Short}

    enum AssetMode {Disabled, OnlyReserve, OnlyLong, ReserveAndLong}

    enum AssetKind {SingleStable, SingleVolatile, LP}

    struct AssetStorage {
        uint256 assetsCount;
        mapping(uint256 => address) assetsList;
        mapping(address => DataTypes.AssetConfig) assetConfigs;
    }

    struct ReserveStorage {
        uint256 reservesCount;
        mapping(address => uint256) reservesList;
        mapping(uint256 => DataTypes.ReserveData) reserves;
    }

    struct CollateralStorage {
        uint256 collateralsCount;
        mapping(address => mapping(address => uint256)) collateralsList;
        mapping(uint256 => DataTypes.CollateralData) collaterals;
    }

    struct ProtocolConfig {
        address treasury;
        address configuratorAddress;
        address userData;
        uint256 leverageFactor;
        uint256 tradeFeeMantissa;
        uint256 liquidationRatioMantissa;
        uint256 swapBufferLimitPercentage;
    }

    struct MappingStorage {
        mapping(address => bool) whitelistedCallers;
        mapping(address => uint256) userLastTradeBlock;
        mapping(address => uint256) liquidatedCollaterals;
    }

    // Shared property of reserve, collateral and portfolio
    struct AssetConfig {
        uint256 assetId;
        uint8 decimals;
        AssetKind kind;
        ISwapAdapter swapAdapter;
        IPriceOracleGetter oracle;
    }

    struct ReserveConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 protocolRateMantissaGwei;
        uint32 utilizationBaseRateMantissaGwei;
        uint32 kinkMantissaGwei;
        uint32 multiplierAnnualGwei;
        uint32 jumpMultiplierAnnualGwei;
        // --- 208 bits used ---
        AssetState state;
        AssetMode mode;
    }

    struct ReserveDataExtension {
        address reinvestment;
        address longReinvestment;
        address bonusPool;
    }

    struct ReserveData {
        ReserveConfiguration configuration;
        ReserveDataExtension ext;
        address asset;
        uint256 poolId;
        uint256 liquidSupply;
        // scaled utilized supply on reserve, changes whenever a deposit, withdraw, borrow and repay is executed
        uint256 scaledUtilizedSupplyRay;
        uint256 longSupply;
        uint256 reserveIndexRay;
        uint256 utilizationPercentageRay;
        uint256 protocolIndexRay;
        uint256 lastUpdatedTimestamp;
    }

    struct ReserveDataCache {
        address asset;
        address reinvestment;
        address longReinvestment;
        uint256 currReserveIndexRay;
        uint256 currProtocolIndexRay;
        uint256 currBorrowIndexRay;
    }

    struct CollateralConfiguration {
        uint32 depositFeeMantissaGwei;
        uint32 ltvGwei;
        uint128 minBalance;
        // --- 192 bits used ---
        AssetState state;
    }

    struct CollateralData {
        CollateralConfiguration configuration;
        address asset;
        address reinvestment;
        uint256 poolId;
        uint256 liquidSupply;
        uint256 totalShareSupplyRay;
    }

    struct UserConfiguration {
        uint256 reserve;
        uint256 collateral;
        uint256 position;
    }

    struct UserData {
        UserConfiguration configuration;
        mapping(uint256 => uint256) reserveShares; // in ray
        mapping(uint256 => uint256) collateralShares; // in ray
        mapping(uint256 => int256) positions; // in ray
    }

    struct InitReserveData {
        address reinvestment;
        address bonusPool;
        address longReinvestment;
        uint32 depositFeeMantissa;
        uint32 protocolRateMantissaRay;
        uint32 utilizationBaseRateMantissaRay;
        uint32 kinkMantissaRay;
        uint32 multiplierAnnualRay;
        uint32 jumpMultiplierAnnualRay;
        AssetState state;
        AssetMode mode;
    }


    struct ValidateTradeParams {
        address user;
        uint256 amountToTrade;
        uint256 currShortReserveAvailableSupply;
        uint256 maxAmountToTrade;
        uint256 userLastTradeBlock;
    }

    struct UserLiquidity {
        uint256 totalCollateralUsdPreLtv;
        uint256 totalCollateralUsdPostLtv;
        uint256 totalLongUsd;
        uint256 totalShortUsd;
        int256 pnlUsd;
        int256 totalLeverageUsd;
        int256 availableLeverageUsd;
        bool isLiquidatable;
    }

    struct UserLiquidityCachedData {
        int256 currShortingPosition;
        int256 currLongingPosition;
        uint256 shortingPrice;
        uint256 shortingPriceDecimals;
        uint256 longingPrice;
        uint256 longingPriceDecimals;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../../types/DataTypes.sol";

library LedgerStorage {
    bytes32 constant ASSET_STORAGE_HASH = keccak256("asset_storage");
    bytes32 constant RESERVE_STORAGE_HASH = keccak256("reserve_storage");
    bytes32 constant COLLATERAL_STORAGE_HASH = keccak256("collateral_storage");
    bytes32 constant PROTOCOL_CONFIG_HASH = keccak256("protocol_config");
    bytes32 constant MAPPING_STORAGE_HASH = keccak256("mapping_storage");

    function getAssetStorage() internal pure returns (DataTypes.AssetStorage storage assetStorage) {
        bytes32 hash = ASSET_STORAGE_HASH;
        assembly {assetStorage.slot := hash}
    }

    function getReserveStorage() internal pure returns (DataTypes.ReserveStorage storage rs) {
        bytes32 hash = RESERVE_STORAGE_HASH;
        assembly {rs.slot := hash}
    }

    function getCollateralStorage() internal pure returns (DataTypes.CollateralStorage storage cs) {
        bytes32 hash = COLLATERAL_STORAGE_HASH;
        assembly {cs.slot := hash}
    }

    function getProtocolConfig() internal pure returns (DataTypes.ProtocolConfig storage pc) {
        bytes32 hash = PROTOCOL_CONFIG_HASH;
        assembly {pc.slot := hash}
    }

    function getMappingStorage() internal pure returns (DataTypes.MappingStorage storage ms) {
        bytes32 hash = MAPPING_STORAGE_HASH;
        assembly {ms.slot := hash}
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapAdapter {
    function swap(
        address selling,
        address buying,
        uint256 amount,
        bytes memory data
    ) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IReinvestmentProxy {
    function owner() external view returns (address);

    function logic() external view returns (address);

    function setLogic() external view returns (address);

    function supportedInterfaceId() external view returns (bytes4);
}

interface IReinvestmentLogic {

    event UpdatedTreasury(address oldAddress, address newAddress);
    event UpdatedFeeMantissa(uint256 oldFee, uint256 newFee);

    struct Reward {
        address asset;
        uint256 claimable;
    }

    function setTreasury(address treasury_) external;

    function setFeeMantissa(uint256 feeMantissa_) external;

    function asset() external view returns (address);

    function treasury() external view returns (address);

    function ledger() external view returns (address);

    function feeMantissa() external view returns (uint256);

    function receipt() external view returns (address);

    function platform() external view returns (address);

    function rewardOf(address, uint256) external view returns (Reward[] memory);

    function rewardLength() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function claim(address, uint256) external;

    function checkpoint(address, uint256) external;

    function invest(uint256) external;

    function divest(uint256) external;

    function emergencyWithdraw() external returns (uint256);

    function sweep(address) external;
}

interface IReinvestment is IReinvestmentProxy, IReinvestmentLogic {}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBonusPool {
    function updatePoolUser(address _token, address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../types/DataTypes.sol";

library UserConfiguration {

    function setUsingReserve(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingReserve
    ) internal {
        self.reserve = (self.reserve & ~(1 << bitIndex)) | (uint256(usingReserve ? 1 : 0) << bitIndex);
    }

    function setUsingCollateral(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingCollateral
    ) internal {
        self.collateral = (self.collateral & ~(1 << bitIndex)) | (uint256(usingCollateral ? 1 : 0) << bitIndex);
    }

    function setUsingPosition(
        DataTypes.UserConfiguration storage self,
        uint256 bitIndex,
        bool usingPosition
    ) internal {
        self.position = (self.position & ~(1 << bitIndex)) | (uint256(usingPosition ? 1 : 0) << bitIndex);
    }

    function isUsingReserve(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.reserve >> bitIndex) & 1 != 0;
    }

    function isUsingCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.collateral >> bitIndex) & 1 != 0;
    }

    function isUsingPosition(
        DataTypes.UserConfiguration memory self,
        uint256 bitIndex
    ) internal pure returns (bool) {
        return (self.position >> bitIndex) & 1 != 0;
    }

    function hasReserve(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.reserve >> offSetIndex) > 0;
    }

    function hasCollateral(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.collateral >> offSetIndex) > 0;
    }

    function hasPosition(
        DataTypes.UserConfiguration memory self,
        uint256 offSetIndex
    ) internal pure returns (bool) {
        return (self.position >> offSetIndex) > 0;
    }

    function isEmpty(DataTypes.UserConfiguration memory self) internal pure returns (bool) {
        return self.reserve == 0 && self.collateral == 0 && self.position == 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * @dev Provides mul and div function for wads (decimal numbers with 18 digits precision) and rays (decimals with 27 digits)
 **/
library MathUtils {
    uint256 public constant VERSION = 1;

    uint256 internal constant WAD_UNIT = 18;
    uint256 internal constant RAY_UNIT = 27;
    uint256 internal constant WAD_RAY_RATIO = 1e9;

    uint256 public constant WAD = 1e18;
    uint256 public constant RAY = 1e27;
    uint256 public constant HALF_WAD = WAD / 2;
    uint256 public constant HALF_RAY = RAY / 2;


    /**
     * @notice Multiplies two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a*b, in wad
     **/
    function wadMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_WAD) / b, "MathUtils: overflow");

        return (a * b + HALF_WAD) / WAD;
    }

    /**
     * @notice Divides two wad, rounding half up to the nearest wad
     * @param a Wad
     * @param b Wad
     * @return The result of a/b, in wad
     **/
    function wadDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / WAD, "MathUtils: overflow");

        return (a * WAD + halfB) / b;
    }

    /**
     * @notice Multiplies two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a*b, in ray
     **/
    function rayMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }

        require(a <= (type(uint256).max - HALF_RAY) / b, "MathUtils: overflow");

        return (a * b + HALF_RAY) / RAY;
    }

    /**
     * @notice Divides two ray, rounding half up to the nearest ray
     * @param a Ray
     * @param b Ray
     * @return The result of a/b, in ray
     **/
    function rayDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MathUtils: division by zero");
        uint256 halfB = b / 2;

        require(a <= (type(uint256).max - halfB) / RAY, "MathUtils: overflow");

        return (a * RAY + halfB) / b;
    }

    /**
     * @notice Casts ray down to wad
     * @param a Ray
     * @return a casted to wad, rounded half up to the nearest wad
     **/
    function rayToWad(uint256 a) internal pure returns (uint256) {
        uint256 halfRatio = WAD_RAY_RATIO / 2;
        uint256 result = halfRatio + a;
        require(result >= halfRatio, "MathUtils: overflow");

        return result / WAD_RAY_RATIO;
    }

    /**
     * @notice Converts wad up to ray
     * @param a Wad
     * @return a converted in ray
     **/
    function wadToRay(uint256 a) internal pure returns (uint256) {
        uint256 result = a * WAD_RAY_RATIO;
        require(result / WAD_RAY_RATIO == a, "MathUtils: overflow");
        return result;
    }

    /**
     * @notice Converts unit to wad
     * @param self Value
     * @param unit Value's unit
     * @return value converted in wad
     **/
    function unitToWad(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD_UNIT) return self;

        if (unit < WAD_UNIT) {
            return self * 10**(WAD_UNIT - unit);
        } else {
            return self / 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * 10**(RAY_UNIT -unit);
        } else {
            return self / 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts unit to ray
     * @param self Value
     * @param unit Value's unit
     * @return value converted in ray
     **/
    function unitToRay(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self * int256(10**(RAY_UNIT -unit));
        } else {
            return self / int256(10**(unit - RAY_UNIT));
        }
    }

    /**
     * @notice Converts wad to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function wadToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == WAD) return self;

        if (unit < WAD_UNIT) {
            return self / 10**(WAD_UNIT - unit);
        } else {
            return self * 10**(unit - WAD_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(uint256 self, uint256 unit) internal pure returns (uint256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / 10**(RAY_UNIT - unit);
        } else {
            return self * 10**(unit - RAY_UNIT);
        }
    }

    /**
     * @notice Converts ray to unit
     * @param self Value
     * @param unit Value's unit
     * @return value converted in unit
     **/
    function rayToUnit(int256 self, uint256 unit) internal pure returns (int256) {
        if (self == 0 || unit == RAY_UNIT) return self;

        if (unit < RAY_UNIT) {
            return self / int256(10**(RAY_UNIT - unit));
        } else {
            return self * int256(10**(unit - RAY_UNIT));
        }
    }

    function abs(int256 a) internal pure returns (uint256) {
        if (a < 0) {
            return uint256(a * (-1));
        } else {
            return uint256(a);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../interfaces/IReinvestment.sol";
import "../../interfaces/IUserData.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../math/InterestUtils.sol";
import "./ValidationLogic.sol";
import "../storage/LedgerStorage.sol";

library ReserveLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    /**
     * @dev The reserve supplies
     */
    function getReserveSupplies(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 unit = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;
        uint256 currAvailableSupply;

        if (reserve.ext.reinvestment == address(0)) {
            currAvailableSupply += reserve.liquidSupply;
        } else {
            currAvailableSupply += IReinvestment(reserve.ext.reinvestment).totalSupply();
        }

        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        uint256 currLockedReserveSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextReserveIndexRay);

        uint256 currProtocolUtilizedSupplyRay = reserve.scaledUtilizedSupplyRay.rayMul(nextProtocolIndexRay);

        uint256 currReserveSupply = currAvailableSupply + currLockedReserveSupplyRay.rayToUnit(unit);

        uint256 currUtilizedSupplyRay = currLockedReserveSupplyRay + currProtocolUtilizedSupplyRay;

        uint256 currTotalSupplyRay = currAvailableSupply.unitToRay(unit) + currUtilizedSupplyRay;

        return (
        currAvailableSupply,
        currReserveSupply,
        currProtocolUtilizedSupplyRay.rayToUnit(unit),
        currTotalSupplyRay.rayToUnit(unit),
        currUtilizedSupplyRay.rayToUnit(unit)
        );
    }

    /**
     * Get normalized debt
     * @return the normalized debt. expressed in ray
     **/
    function getReserveIndexes(
        DataTypes.ReserveData memory reserve
    ) internal view returns (uint256, uint256, uint256) {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        return (
        nextReserveIndexRay,
        nextProtocolIndexRay,
        nextProtocolIndexRay + nextReserveIndexRay
        );
    }

    function updateIndex(
        DataTypes.ReserveData storage reserve
    ) internal {
        (uint256 nextReserveIndexRay, uint256 nextProtocolIndexRay) = calculateIndexes(reserve, block.timestamp);

        reserve.reserveIndexRay = nextReserveIndexRay;
        reserve.protocolIndexRay = nextProtocolIndexRay;

        reserve.lastUpdatedTimestamp = block.timestamp;
    }

    function postUpdateReserveData(DataTypes.ReserveData storage reserve) internal {
        uint256 decimals = LedgerStorage.getAssetStorage().assetConfigs[reserve.asset].decimals;

        (,,,uint256 currTotalSupply, uint256 currUtilizedSupply) = getReserveSupplies(reserve);

        reserve.utilizationPercentageRay = currTotalSupply > 0 ? currUtilizedSupply.unitToRay(decimals).rayDiv(
            currTotalSupply.unitToRay(decimals)
        ) : 0;
    }

    function calculateIndexes(
        DataTypes.ReserveData memory reserve,
        uint256 blockTimestamp
    ) private pure returns (uint256, uint256) {
        if (reserve.utilizationPercentageRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 currBorrowIndexRay = reserve.reserveIndexRay + reserve.protocolIndexRay;

        uint256 interestRateRay = getInterestRate(
            reserve.utilizationPercentageRay,
            uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.utilizationBaseRateMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.kinkMantissaGwei).unitToRay(9),
            uint256(reserve.configuration.multiplierAnnualGwei).unitToRay(9),
            uint256(reserve.configuration.jumpMultiplierAnnualGwei).unitToRay(9)
        );

        if (interestRateRay == 0) {
            return (
            reserve.reserveIndexRay,
            reserve.protocolIndexRay
            );
        }

        uint256 cumulatedInterestIndexRay = InterestUtils.getCompoundedInterest(
            interestRateRay, reserve.lastUpdatedTimestamp, blockTimestamp
        );

        uint256 growthIndexRay = currBorrowIndexRay.rayMul(cumulatedInterestIndexRay) - currBorrowIndexRay;

        uint256 protocolInterestRatioRay = uint256(reserve.configuration.protocolRateMantissaGwei).unitToRay(9).rayDiv(interestRateRay);

        uint256 nextProtocolIndexRay = reserve.protocolIndexRay + growthIndexRay.rayMul(protocolInterestRatioRay);

        uint256 nextReserveIndexRay = reserve.reserveIndexRay + growthIndexRay.rayMul(MathUtils.RAY - protocolInterestRatioRay);

        return (nextReserveIndexRay, nextProtocolIndexRay);
    }

    /**
    * @notice Get the interest rate: `rate + utilizationBaseRate + protocolRate`
    * @param utilizationPercentageRay scaledTotalSupplyRay
    * @param protocolRateMantissaRay protocolRateMantissaRay
    * @param utilizationBaseRateMantissaRay utilizationBaseRateMantissaRay
    * @param kinkMantissaRay kinkMantissaRay
    * @param multiplierAnnualRay multiplierAnnualRay
    * @param jumpMultiplierAnnualRay jumpMultiplierAnnualRay
    **/
    function getInterestRate(
        uint256 utilizationPercentageRay,
        uint256 protocolRateMantissaRay,
        uint256 utilizationBaseRateMantissaRay,
        uint256 kinkMantissaRay,
        uint256 multiplierAnnualRay,
        uint256 jumpMultiplierAnnualRay
    ) private pure returns (uint256) {
        uint256 rateRay;

        if (utilizationPercentageRay <= kinkMantissaRay) {
            rateRay = utilizationPercentageRay.rayMul(multiplierAnnualRay);
        } else {
            uint256 normalRateRay = kinkMantissaRay.rayMul(multiplierAnnualRay);
            uint256 excessUtilRay = utilizationPercentageRay - kinkMantissaRay;
            rateRay = excessUtilRay.rayMul(jumpMultiplierAnnualRay) + normalRateRay;
        }

        return rateRay + utilizationBaseRateMantissaRay + protocolRateMantissaRay;
    }

    function cache(
        DataTypes.ReserveData storage reserve
    ) internal view returns (
        DataTypes.ReserveDataCache memory
    ) {
        DataTypes.ReserveDataCache memory reserveCache;

        reserveCache.asset = reserve.asset;
        reserveCache.reinvestment = reserve.ext.reinvestment;
        reserveCache.longReinvestment = reserve.ext.longReinvestment;

        // if the action involves mint/burn of debt, the cache needs to be updated
        reserveCache.currReserveIndexRay = reserve.reserveIndexRay;
        reserveCache.currProtocolIndexRay = reserve.protocolIndexRay;
        reserveCache.currBorrowIndexRay = reserveCache.currReserveIndexRay + reserveCache.currProtocolIndexRay;

        return reserveCache;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./MathUtils.sol";

library InterestUtils {
    using MathUtils for uint256;

    uint256 public constant VERSION = 1;

    uint256 internal constant SECONDS_PER_YEAR = 365 days;

    /**
   * @notice Function to calculate the interest using a compounded interest rate formula
   * @param rate The interest rate, in ray
   * @param lastUpdateTimestamp The timestamp of the last update of the interest
   * @return The interest rate compounded during the timeDelta, in ray
   **/
    function getCompoundedInterest(
        uint256 rate,
        uint256 lastUpdateTimestamp,
        uint256 currentTimestamp
    ) internal pure returns (uint256) {
        uint256 exp = currentTimestamp - lastUpdateTimestamp;

        if (exp == 0) {
            return MathUtils.RAY;
        }

        uint256 expMinusOne = exp - 1;

        uint256 expMinusTwo = exp > 2 ? exp - 2 : 0;

        uint256 ratePerSecond = rate / SECONDS_PER_YEAR;

        uint256 basePowerTwo = ratePerSecond.rayMul(ratePerSecond);
        uint256 basePowerThree = basePowerTwo.rayMul(ratePerSecond);

        uint256 secondTerm = exp * expMinusOne * basePowerTwo / 2;
        uint256 thirdTerm = exp * expMinusOne * expMinusTwo * basePowerThree / 6;

        return MathUtils.RAY + (ratePerSecond * exp) + secondTerm + thirdTerm;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../../types/DataTypes.sol";
import "../math/MathUtils.sol";
import "../helpers/Errors.sol";

library ValidationLogic {
    using MathUtils for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 public constant VERSION = 1;

    /**
     * @notice Validate a Deposit to Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateDepositReserve(
        DataTypes.ReserveData memory reserve,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
    }

    /**
     * @notice Validate a Withdraw from Reserve
     * @param reserve reserve
     * @param amount amount
     **/
    function validateWithdrawReserve(
        DataTypes.ReserveData memory reserve,
        uint256 currReserveSupply,
        uint256 amount
    ) internal pure {
        require(
            reserve.configuration.mode == DataTypes.AssetMode.OnlyReserve ||
            reserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong,
            "reserve mode disabled"
        );
        require(reserve.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currReserveSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
    }

    /**
     * @notice Validate a Deposit to Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateDepositCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(collateral.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(
            (userCollateral + amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    /**
     * @notice Validate a Withdraw from Collateral
     * @param collateral collateral
     * @param userLastTradeBlock userLastTradeBlock
     * @param amount amount
     * @param userCollateral userCollateral
     **/
    function validateWithdrawCollateral(
        DataTypes.CollateralData memory collateral,
        uint256 userLastTradeBlock,
        uint256 amount,
        uint256 userCollateral,
        uint256 currCollateralSupply
    ) internal view {
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(collateral.configuration.state != DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        require(currCollateralSupply >= amount, Errors.NOT_ENOUGH_POOL_BALANCE);
        require(
            (userCollateral - amount) == 0 || (userCollateral - amount) >= collateral.configuration.minBalance,
            "collateral will under the minimum collateral balance"
        );
    }

    /**
     * @notice Validate Short Repayment
     * @param userLastTradeBlock userLastTradeBlock
     * @param user user
     * @param asset asset
     * @param amount amount
     **/
    function validateRepayShort(
        int256 currNormalizedPosition,
        uint256 userLastTradeBlock,
        address user,
        address asset,
        uint256 amount,
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyReserve ||
            mode == DataTypes.AssetMode.ReserveAndLong),
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(currNormalizedPosition < 0, Errors.INVALID_POSITION_TYPE);
        require(amount != 0, Errors.INVALID_ZERO_AMOUNT);
        /*
        TODO: is allowance checked can be omitted?
        it will still revert during transfer if amount is not enough
        */
        require(
            IERC20Upgradeable(asset).allowance(user, address(this)) >= amount,
            "need to approve first"
        );
    }

    /**
     * @notice Validate a Withdraw Long
     * @param userPosition User position
     * @param userLastTradeBlock userLastTradeBlock
     **/
    function validateWithdrawLong(
        int256 userPosition,
        uint256 userLastTradeBlock,
        uint256 amount,
        DataTypes.AssetState state,
        DataTypes.AssetMode mode
    ) internal view {
        require(
            state == DataTypes.AssetState.Active &&
            (mode == DataTypes.AssetMode.OnlyLong ||
            mode == DataTypes.AssetMode.ReserveAndLong),
            Errors.POOL_INACTIVE
        );
        require(userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(userPosition > 0, Errors.NOT_ENOUGH_LONG_BALANCE);
        require(amount > 0, Errors.INVALID_AMOUNT_INPUT);
    }

    /**
     * @notice Validate a Trade
     * @param shortReserve Shorting reserve
     * @param longReserve Longing reserve
     * @param shortingAssetPosition User shorting asset position
     * @param params ValidateTradeParams object
     **/
    function validateTrade(
        DataTypes.ReserveData memory shortReserve,
        DataTypes.ReserveData memory longReserve,
        int256 shortingAssetPosition,
        DataTypes.ValidateTradeParams memory params
    ) internal view {
        require(shortReserve.asset != longReserve.asset, Errors.CANNOT_TRADE_SAME_ASSET);
        // is pool active
        require(
            shortReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            shortReserve.configuration.mode == DataTypes.AssetMode.OnlyReserve,
            "asset cannot short"
        );
        require(
            longReserve.configuration.mode == DataTypes.AssetMode.ReserveAndLong ||
            longReserve.configuration.mode == DataTypes.AssetMode.OnlyLong,
            "asset cannot long"
        );
        require(shortReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);
        require(longReserve.configuration.state == DataTypes.AssetState.Active, Errors.POOL_INACTIVE);

        // user constraint
        require(params.userLastTradeBlock != block.number, Errors.USER_TRADE_BLOCK);
        require(params.amountToTrade != 0, Errors.INVALID_ZERO_AMOUNT);

        // max short amount
        require(params.amountToTrade <= params.maxAmountToTrade, Errors.NOT_ENOUGH_USER_LEVERAGE);

        uint256 amountToBorrow;

        if (shortingAssetPosition < 0) {
            // Already negative on short side, so the entire trading amount will be borrowed
            amountToBorrow = params.amountToTrade;
        } else {
            // Not negative on short side: there may be something to sell before borrowing
            if (uint256(shortingAssetPosition) < params.amountToTrade) {
                amountToBorrow = params.amountToTrade - uint256(shortingAssetPosition);
            }
            // else, curr position is long and has enough to fill the trade
        }


        // check available reserve
        if (amountToBorrow > 0) {
            require(amountToBorrow <= params.currShortReserveAvailableSupply, Errors.NOT_ENOUGH_POOL_BALANCE);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library HelpersLogic {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function approveMax(address asset, address spender, uint256 minAmount) internal {
        uint256 currAllowance = IERC20Upgradeable(asset).allowance(address(this), spender);

        if (currAllowance < minAmount) {
            IERC20Upgradeable(asset).safeApprove(spender, 0);
            IERC20Upgradeable(asset).safeApprove(spender, type(uint256).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


interface IUnwrapLp {
    function unwrap(address assetLp, uint256 amount) external returns (address, uint256);
    function getAssetOut(address assetIn) external view returns (address);
}