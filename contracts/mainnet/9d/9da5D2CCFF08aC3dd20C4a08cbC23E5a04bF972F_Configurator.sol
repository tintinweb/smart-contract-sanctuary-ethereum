// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./libraries/helpers/Errors.sol";
import "./interfaces/ILedger.sol";
import "./types/DataTypes.sol";

contract Configurator is Initializable, AccessControlUpgradeable {

    uint256 public constant VERSION = 3;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    ILedger public ledger;

    event SetLedger(address indexed ledger);
    event SetLeverageFactor(uint256 leverageFactor);
    event SetTradeFee(uint256 tradeFee);
    event SetLiquidationRatio(uint256 liquidationRatio);
    event SetSwapBufferLimitPercentage(uint256 liquidationRatio);
    event SetTreasury(address indexed treasury);
    event InitializedAsset(uint256 indexed assetId, address indexed asset, DataTypes.AssetConfig configuration);
    event SetAssetMode(address indexed asset, DataTypes.AssetMode mode);
    event SetAssetSwapAdapter(address indexed asset, address indexed swapAdapter);
    event SetAssetOracle(address indexed asset, address indexed oracle);
    event InitializedReserve(uint256 indexed pid, address indexed asset);
    event InitializedCollateral(uint256 indexed pid, address indexed asset, address indexed reinvestment);
    event SetReserveDepositFee(address indexed asset, uint32 depositFeeMantissa);
    event SetReserveState(address indexed asset, DataTypes.AssetState state);
    event SetReserveMode(address indexed asset, DataTypes.AssetMode mode);
    event SetCollateralDepositFee(address indexed asset, address indexed reinvestment, uint32 depositFeeMantissa);
    event SetCollateralLTV(address indexed asset, address indexed reinvestment, uint256 ltv);
    event SetCollateralMinBalance(address indexed asset, address indexed reinvestment, uint256 minBalance);
    event SetCollateralState(address indexed asset, address indexed reinvestment, DataTypes.AssetState state);
    event SetReserveReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetReserveLongReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetCollateralReinvestment(address indexed asset, address indexed oldReinvestment, address indexed newReinvestment);
    event SetReserveBonusPool(address indexed asset, address indexed oldBonusPool, address indexed newBonusPool);

    function initialize() external initializer onlyInitializing {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, msg.sender), Errors.CALLER_NOT_OPERATOR);
        _;
    }

    /**
     * @notice Set protocol ledger
     * @param ledger_ Ledger
     */
    function setLedger(address ledger_) external onlyOperator {
        require(address(ledger) == address(0), Errors.LEDGER_INITIALIZED);
        ledger = ILedger(ledger_);
        emit SetLedger(ledger_);
    }

    /**
     * @notice Set protocol leverage factor
     * @param leverageFactor leverage factor
     */
    function setLeverageFactor(uint256 leverageFactor) external onlyOperator {
        require(leverageFactor >= 1e18, Errors.INVALID_LEVERAGE_FACTOR);
        require(leverageFactor <= 10e18, Errors.INVALID_LEVERAGE_FACTOR);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.leverageFactor = leverageFactor;
        ledger.setProtocolConfig(config);
        emit SetLeverageFactor(leverageFactor);
    }

    /**
     * @notice Set protocol trade fee
     * @param tradeFeeMantissa trade fee mantissa
     */
    function setTradeFee(uint256 tradeFeeMantissa) external onlyOperator {
        require(tradeFeeMantissa <= 0.1e18, Errors.INVALID_TRADE_FEE);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.tradeFeeMantissa = tradeFeeMantissa;
        ledger.setProtocolConfig(config);
        emit SetTradeFee(tradeFeeMantissa);
    }

    /**
     * @notice Set protocol liquidation ratio
     * @param liquidationRatioMantissa liquidation ratio mantissa
     */
    function setLiquidationRatio(uint256 liquidationRatioMantissa) external onlyOperator {
        require(liquidationRatioMantissa >= 0.5e18, Errors.INVALID_LIQUIDATION_RATIO);
        require(liquidationRatioMantissa <= 0.9e18, Errors.INVALID_LIQUIDATION_RATIO);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.liquidationRatioMantissa = liquidationRatioMantissa;
        ledger.setProtocolConfig(config);
        emit SetLiquidationRatio(liquidationRatioMantissa);
    }

    /**
     * @notice Set swap buffer limit percentage
     * @param swapBufferLimitPercentage swap buffer limit percentage
     */
    function setSwapBufferLimitPercentage(uint256 swapBufferLimitPercentage) external onlyOperator {
        require(swapBufferLimitPercentage > 1e18, Errors.INVALID_SWAP_BUFFER_LIMIT);
        require(swapBufferLimitPercentage <= 1.2e18, Errors.INVALID_SWAP_BUFFER_LIMIT);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.swapBufferLimitPercentage = swapBufferLimitPercentage;
        ledger.setProtocolConfig(config);
        emit SetSwapBufferLimitPercentage(swapBufferLimitPercentage);
    }

    function setTreasury(address treasury) external onlyOperator {
        require(treasury != address(0), Errors.INVALID_ZERO_ADDRESS);
        DataTypes.ProtocolConfig memory config = ledger.getProtocolConfig();
        config.treasury = treasury;
        ledger.setProtocolConfig(config);
        emit SetTreasury(treasury);
    }

    /**
     * @notice Initialize Asset
     * @param asset Asset address
     * @param decimals Asset decimals
     * @param kind Asset's kind
     * @param swapAdapter ISwapAdapter data
     * @param oracle IPriceOracle data
    */
    function initAsset(
        address asset,
        uint256 decimals,
        DataTypes.AssetKind kind,
        ISwapAdapter swapAdapter,
        IPriceOracleGetter oracle
    ) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);

        require(configuration.assetId == 0, Errors.ASSET_INITIALIZED);

        uint256 assetId = ledger.initAssetConfiguration(asset);

        configuration = DataTypes.AssetConfig(
            assetId,
            uint8(decimals),
            kind,
            swapAdapter,
            oracle
        );

        ledger.setAssetConfiguration(asset, configuration);

        emit InitializedAsset(assetId, asset, configuration);
    }

    /**
    * @notice Setter of Asset SwapAdapter
    * @param asset Address
    * @param swapAdapter ISwapAdapter Data
    */
    function setAssetSwapAdapter(address asset, ISwapAdapter swapAdapter) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);
        configuration.swapAdapter = swapAdapter;
        ledger.setAssetConfiguration(asset, configuration);
        emit SetAssetSwapAdapter(asset, address(swapAdapter));
    }

    /**
    * @notice Setter of Asset Oracle
    * @param asset Address
    * @param oracle IPriceOracleGetter Data
    */
    function setAssetOracle(address asset, IPriceOracleGetter oracle) external onlyOperator {
        DataTypes.AssetConfig memory configuration = ledger.getAssetConfiguration(asset);
        configuration.oracle = oracle;
        ledger.setAssetConfiguration(asset, configuration);
        emit SetAssetOracle(asset, address(oracle));
    }

    /**
    * @notice Initialize Reserve
    * @param asset Asset address
    * @param data InitReserveData object
    */
    function initReserve(address asset, DataTypes.InitReserveData memory data) external onlyOperator {
        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        require(assetConfig.assetId != 0, Errors.ASSET_NOT_INITIALIZED);

        uint256 pid = ledger.initReserve(asset);

        ledger.setReserveReinvestment(pid, data.reinvestment);
        ledger.setReserveBonusPool(pid, data.bonusPool);
        ledger.setReserveLongReinvestment(pid, data.longReinvestment);

        ledger.setReserveConfiguration(
            pid,
            DataTypes.ReserveConfiguration(
                data.depositFeeMantissa,
                data.protocolRateMantissaRay,
                data.utilizationBaseRateMantissaRay,
                data.kinkMantissaRay,
                data.multiplierAnnualRay,
                data.jumpMultiplierAnnualRay,
                data.state,
                data.mode
            )
        );

        emit InitializedReserve(pid, asset);
    }

    /**
    * @notice Setter of Reserve Interest Parameters
    * @param asset Address
    * @param protocolRateMantissa Protocol Rate
    * @param utilizationBaseRateMantissa Utilization Base Rate
    * @param kinkMantissa Kink
    * @param multiplierAnnual Multiplier Annual
    * @param jumpMultiplierAnnual Jump Multiplier Annual
    */
    function setReserveInterestParams(
        address asset,
        uint32 protocolRateMantissa,
        uint32 utilizationBaseRateMantissa,
        uint32 kinkMantissa,
        uint32 multiplierAnnual,
        uint32 jumpMultiplierAnnual
    ) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        reserve.configuration.protocolRateMantissaGwei = protocolRateMantissa;
        reserve.configuration.utilizationBaseRateMantissaGwei = utilizationBaseRateMantissa;
        reserve.configuration.kinkMantissaGwei = kinkMantissa;
        reserve.configuration.multiplierAnnualGwei = multiplierAnnual;
        reserve.configuration.jumpMultiplierAnnualGwei = jumpMultiplierAnnual;

        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
    }

    /**
    * @notice Setter Reserve Fee
    * @param asset Address
    * @param fee Deposit Fee
    */
    function setReserveFee(address asset, uint32 fee) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.depositFeeMantissaGwei = fee;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveDepositFee(asset, fee);
    }

    function setReserveState(address asset, DataTypes.AssetState state) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.state = state;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveState(asset, state);
    }

    function setReserveMode(address asset, DataTypes.AssetMode mode) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);
        reserve.configuration.mode = mode;
        ledger.setReserveConfiguration(reserve.poolId, reserve.configuration);
        emit SetReserveMode(asset, mode);
    }

    /**
    * @notice Setter Reserve Fee
    * @param asset Address
    * @param bonusPool Bonus Pool address
    */
    function setReserveBonusPool(address asset, address bonusPool) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        ledger.setReserveBonusPool(reserve.poolId, bonusPool);

        emit SetReserveBonusPool(asset, reserve.ext.bonusPool, bonusPool);
    }

    /**
    * @notice Initialize Collateral
    * @param asset Address
    * @param reinvestment Address
    * @param depositFeeMantissa Deposit Fee
    * @param ltv LTV
    * @param minBalance Min Balance
    */
    function initCollateral(
        address asset,
        address reinvestment,
        uint32 depositFeeMantissa,
        uint32 ltv,
        uint128 minBalance
    ) external onlyOperator {
        DataTypes.AssetConfig memory assetConfig = ledger.getAssetConfiguration(asset);

        require(assetConfig.assetId != 0, Errors.ASSET_NOT_INITIALIZED);

        uint256 pid = ledger.initCollateral(asset, reinvestment);

        ledger.setCollateralConfiguration(
            pid,
            DataTypes.CollateralConfiguration(
                depositFeeMantissa,
                ltv,
                minBalance,
                DataTypes.AssetState.Active
            ));

        emit InitializedCollateral(pid, asset, reinvestment);
    }

    /**
    * @notice Setter of Collateral Deposit Fee
    * @param asset Address
    * @param reinvestment Address
    * @param depositFeeMantissa Deposit Fee
    */
    function setCollateralDepositFee(
        address asset,
        address reinvestment,
        uint32 depositFeeMantissa
    ) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.depositFeeMantissaGwei = depositFeeMantissa;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralDepositFee(asset, reinvestment, depositFeeMantissa);
    }

    /**
    * @notice Setter Collateral LTV
    * @param asset Address
    * @param reinvestment Address
    * @param ltv LTV
    */
    function setCollateralLTV(
        address asset,
        address reinvestment,
        uint32 ltv
    ) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.ltvGwei = ltv;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralLTV(asset, reinvestment, ltv);
    }

    /**
    * @notice Setter of Collateral Minimum Balance
    * @param asset Address
    * @param reinvestment Address
    * @param minBalance Min Balance
    */
    function setCollateralMinBalance(address asset, address reinvestment, uint128 minBalance) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.minBalance = minBalance;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralMinBalance(asset, reinvestment, minBalance);
    }

    /**
    * @notice Setter of Collateral State
    * @param asset Address
    * @param reinvestment Address
    * @param state AssetState Data
    */
    function setCollateralState(address asset, address reinvestment, DataTypes.AssetState state) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);
        collateral.configuration.state = state;
        ledger.setCollateralConfiguration(collateral.poolId, collateral.configuration);
        emit SetCollateralState(asset, reinvestment, state);
    }

    /**
    * @notice Setter of Reserve Reinvestment
    * @param asset Address
    * @param newReinvestment Address
    */
    function setReserveReinvestment(address asset, address newReinvestment) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        require(reserve.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(reserve.ext.reinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        (,,,uint256 currentSupply,) = ledger.reserveSupplies(asset);

        if (reserve.ext.reinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(0, reserve.poolId);
        }

        ledger.setReserveReinvestment(reserve.poolId, newReinvestment);

        if (newReinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(1, reserve.poolId);
        }

        emit SetReserveReinvestment(asset, reserve.ext.reinvestment, newReinvestment);
    }

    /**
    * @notice Setter of Reserve Reinvestment
    * @param asset Address
    * @param newReinvestment Address
    */
    function setReserveLongReinvestment(address asset, address newReinvestment) external onlyOperator {
        DataTypes.ReserveData memory reserve = ledger.getReserveData(asset);

        require(reserve.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(reserve.ext.longReinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        if (reserve.ext.longReinvestment != address(0) && reserve.longSupply > 0) {
            ledger.managePoolReinvestment(4, reserve.poolId);
        }

        ledger.setReserveLongReinvestment(reserve.poolId, newReinvestment);

        if (newReinvestment != address(0) && reserve.longSupply > 0) {
            ledger.managePoolReinvestment(5, reserve.poolId);
        }

        emit SetReserveLongReinvestment(asset, reserve.ext.longReinvestment, newReinvestment);
    }

    /**
    * @notice Setter Collateral Reinvestment
    * @param asset Address
    * @param reinvestment Address
    * @param newReinvestment address
    */
    function setCollateralReinvestment(address asset, address reinvestment, address newReinvestment) external onlyOperator {
        DataTypes.CollateralData memory collateral = ledger.getCollateralData(asset, reinvestment);

        require(collateral.configuration.state == DataTypes.AssetState.Disabled, Errors.POOL_ACTIVE);
        require(collateral.reinvestment != newReinvestment, Errors.INVALID_POOL_REINVESTMENT);

        uint256 currentSupply = ledger.collateralTotalSupply(asset, reinvestment);

        // withdraw from curr reinvestment
        if (collateral.reinvestment != address(0) && currentSupply > 0) {
            ledger.managePoolReinvestment(2, collateral.poolId);
        }

        // set new reinvestment
        ledger.setCollateralReinvestment(collateral.poolId, newReinvestment);

        if (newReinvestment != address(0) && currentSupply > 0) {
            // reinvest to new reinvestment
            ledger.managePoolReinvestment(3, collateral.poolId);
        }

        emit SetCollateralReinvestment(asset, reinvestment, newReinvestment);
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

interface IPriceOracleGetter {
    function getAssetPrice(address asset) external view returns (uint256, uint256);
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