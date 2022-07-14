// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "./interfaces/IFactory.sol";
import "./interfaces/IToken.sol";
import "./interfaces/ITokenUUPSUpgradeable.sol";
import "./interfaces/IDAOStaking.sol";
import "./interfaces/IDAOStakingUUPSUpgradeable.sol";
import "./interfaces/IGovernance.sol";
import "./interfaces/IRewardsEscrow.sol";
import "./interfaces/IRewardsEscrowUUPSUpgradeable.sol";
import "./interfaces/IRewards.sol";
import "./interfaces/IRewardsUUPSUpgradeable.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IStakingUUPSUpgradeable.sol";
import "./interfaces/IYieldFarm.sol";
import "./interfaces/IYieldFarmUUPSUpgradeable.sol";
import "./interfaces/IVesting.sol";
import "./interfaces/IVestingUUPSUpgradeable.sol";
import "./interfaces/IVestingCliffs.sol";
import "./interfaces/IVestingCliffsUUPSUpgradeable.sol";
import "./interfaces/IAirdrop.sol";
import "./interfaces/IAirdropUUPSUpgradeable.sol";
import "./interfaces/IAirdropGamified.sol";
import "./interfaces/IAirdropGamifiedUUPSUpgradeable.sol";
import "./Modules.sol";

contract OrganisationRegistry is Initializable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // todo: decide on org id; must be used to identify it in the backend
    // - do we use the address of the contract?
    // - do we want pretty names?
    IFactory public factory;

    struct DAOConfig {
        address staking;
        address governance;
        address[] rewards;
    }

    struct YFConfig {
        address staking;
        address[] pools;
    }

    struct VestingConfig {
        address[] epochs;
        address[] cliffs;
    }

    struct AirdropConfig {
        address[] simple;
        address[] gamified;
    }

    struct Organisation {
        bool exists;

        string name;
        address owner;

        string[] modules;

        address token;
        address rewardsEscrow;
        DAOConfig dao;
        YFConfig yieldFarming;
        VestingConfig vesting;
        AirdropConfig airdrop;
    }

    mapping(bytes32 => Organisation) public organisations;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address factoryAddress, address roleAdmin, address upgrader) public initializer {
        __AccessControl_init();

        require(factoryAddress != address(0), "OrganisationRegistry: invalid factory address");

        factory = IFactory(factoryAddress);

        _grantRole(DEFAULT_ADMIN_ROLE, roleAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
    }

    function createOrganisation(bytes32 id, string memory _name) public {
        require(organisations[id].exists == false, "OrganisationRegistry: organisation ID already exists");
        require(bytes(_name).length > 0, "OrganisationRegistry: organisation name cannot be empty");

        Organisation memory org;
        org.exists = true;
        org.name = _name;
        org.owner = msg.sender;

        organisations[id] = org;
    }

    function deployTokenV1(
        bytes32 id,
        ITokenUUPSUpgradeable.TokenConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleNotExists(org.token);

        address token;
        if (upgrader == address(0)) {
            token = factory.deployModuleClone{value : msg.value}(
                Modules.TOKEN_V1,
                abi.encodeWithSelector(
                    IToken.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            token = factory.deployModuleUUPS{value : msg.value}(
                Modules.TOKEN_V1,
                abi.encodeWithSelector(
                    ITokenUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        org.token = token;
        org.modules.push(Modules.TOKEN_V1);
    }

    function deployDAOV1Staking(
        bytes32 id,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleExists(org.token);
        _requireModuleNotExists(org.dao.staking);

        address daoStaking;
        if (upgrader == address(0)) {
            daoStaking = factory.deployModuleClone{value : msg.value}(
                Modules.DAO_V1_STAKING,
                abi.encodeWithSelector(
                    IDAOStaking.initialize.selector,
                    IDAOStaking.DAOStakingConfig(org.token),
                    roleAdmin
                )
            );
        } else {
            daoStaking = factory.deployModuleUUPS{value : msg.value}(
                Modules.DAO_V1_STAKING,
                abi.encodeWithSelector(
                    IDAOStakingUUPSUpgradeable.initializeUUPS.selector,
                    IDAOStaking.DAOStakingConfig(org.token),
                    roleAdmin,
                    upgrader
                )
            );
        }

        org.dao.staking = daoStaking;
        org.modules.push(Modules.DAO_V1_STAKING);
    }

    function deployDAOV1Governance(
        bytes32 id,
        IGovernance.GovernanceConfig memory cfg,
        bool upgradeable
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleExists(org.dao.staking);
        _requireModuleNotExists(org.dao.governance);

        cfg.daoStakingAddr = org.dao.staking;

        address governance;
        if (!upgradeable) {
            governance = factory.deployModuleClone{value : msg.value}(
                Modules.DAO_V1_GOVERNANCE,
                abi.encodeWithSelector(
                    IGovernance.initialize.selector,
                    cfg
                )
            );
        } else {
            governance = factory.deployModuleUUPS{value : msg.value}(
                Modules.DAO_V1_GOVERNANCE,
                abi.encodeWithSelector(
                    IGovernance.initialize.selector,
                    cfg
                )
            );
        }

        org.dao.governance = governance;
        org.modules.push(Modules.DAO_V1_GOVERNANCE);
    }

    function deployRewardsEscrowV1(
        bytes32 id,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleNotExists(org.rewardsEscrow);

        address rewardsEscrow;

        if (upgrader == address(0)) {
            rewardsEscrow = factory.deployModuleClone{value : msg.value}(
                Modules.REWARDS_ESCROW_V1,
                abi.encodeWithSelector(
                    IRewardsEscrow.initialize.selector,
                    roleAdmin
                )
            );
        } else {
            rewardsEscrow = factory.deployModuleUUPS{value : msg.value}(
                Modules.REWARDS_ESCROW_V1,
                abi.encodeWithSelector(
                    IRewardsEscrowUUPSUpgradeable.initializeUUPS.selector,
                    roleAdmin,
                    upgrader
                )
            );
        }

        org.rewardsEscrow = rewardsEscrow;
        org.modules.push(Modules.REWARDS_ESCROW_V1);
    }

    function deployDAOV1Rewards(
        bytes32 id,
        IRewards.RewardsConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleExists(org.dao.staking);

        cfg.daoStaking = org.dao.staking;

        address rewards;

        if (upgrader == address(0)) {
            rewards = factory.deployModuleClone{value : msg.value}(
                Modules.DAO_V1_REWARDS,
                abi.encodeWithSelector(
                    IRewards.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            rewards = factory.deployModuleUUPS{value : msg.value}(
                Modules.DAO_V1_REWARDS,
                abi.encodeWithSelector(
                    IRewardsUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.DAO_V1_REWARDS);
        org.dao.rewards.push(rewards);
    }

    function deployYFV1Staking(
        bytes32 id,
        IStaking.StakingConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleNotExists(org.yieldFarming.staking);

        address staking;
        if (upgrader == address(0)) {
            staking = factory.deployModuleClone{value : msg.value}(
                Modules.YF_V1_STAKING,
                abi.encodeWithSelector(
                    IStaking.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            staking = factory.deployModuleUUPS{value : msg.value}(
                Modules.YF_V1_STAKING,
                abi.encodeWithSelector(
                    IStakingUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        org.modules.push(Modules.YF_V1_STAKING);
        org.yieldFarming.staking = staking;
    }

    function deployYFV1Pool(
        bytes32 id,
        IYieldFarm.YieldFarmConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);
        _requireModuleExists(org.yieldFarming.staking);
        _requireModuleExists(org.rewardsEscrow);

        cfg.stakingAddress = org.yieldFarming.staking;
        cfg.rewardsEscrowAddress = org.rewardsEscrow;

        address pool;
        if (upgrader == address(0)) {
            pool = factory.deployModuleClone{value : msg.value}(
                Modules.YF_V1_POOL,
                abi.encodeWithSelector(
                    IYieldFarm.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            pool = factory.deployModuleUUPS{value : msg.value}(
                Modules.YF_V1_POOL,
                abi.encodeWithSelector(
                    IYieldFarmUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.YF_V1_POOL);
        org.yieldFarming.pools.push(pool);
    }

    function deployVestingV1(
        bytes32 id,
        IVesting.VestingConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);

        address vesting;
        if (upgrader == address(0)) {
            vesting = factory.deployModuleClone{value : msg.value}(
                Modules.VESTING_V1,
                abi.encodeWithSelector(
                    IVesting.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            vesting = factory.deployModuleUUPS{value : msg.value}(
                Modules.VESTING_V1,
                abi.encodeWithSelector(
                    IVestingUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.VESTING_V1);
        org.vesting.epochs.push(vesting);
    }

    function deployVestingCliffsV1(
        bytes32 id,
        IVestingCliffs.VestingCliffsConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);

        address vestingCliffs;
        if (upgrader == address(0)) {
            vestingCliffs = factory.deployModuleClone{value : msg.value}(
                Modules.VESTING_CLIFFS_V1,
                abi.encodeWithSelector(
                    IVestingCliffs.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            vestingCliffs = factory.deployModuleUUPS{value : msg.value}(
                Modules.VESTING_CLIFFS_V1,
                abi.encodeWithSelector(
                    IVestingCliffsUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.VESTING_CLIFFS_V1);
        org.vesting.cliffs.push(vestingCliffs);
    }

    function deployAirdropSimpleV1(
        bytes32 id,
        IAirdrop.AirdropConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);

        address airdropSimple;
        if (upgrader == address(0)) {
            airdropSimple = factory.deployModuleClone{value : msg.value}(
                Modules.AIRDROP_SIMPLE_V1,
                abi.encodeWithSelector(
                    IAirdrop.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            airdropSimple = factory.deployModuleUUPS{value : msg.value}(
                Modules.AIRDROP_SIMPLE_V1,
                abi.encodeWithSelector(
                    IAirdropUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.AIRDROP_SIMPLE_V1);
        org.airdrop.simple.push(airdropSimple);
    }

    function deployAirdropGamifiedV1(
        bytes32 id,
        IAirdropGamified.AirdropGamifiedConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) public payable {
        Organisation storage org = _getOrganisationWithOwnerOrRevert(id, msg.sender);

        address airdropGamified;
        if (upgrader == address(0)) {
            airdropGamified = factory.deployModuleClone{value : msg.value}(
                Modules.AIRDROP_GAMIFIED_V1,
                abi.encodeWithSelector(
                    IAirdropGamified.initialize.selector,
                    cfg,
                    roleAdmin
                )
            );
        } else {
            airdropGamified = factory.deployModuleUUPS{value : msg.value}(
                Modules.AIRDROP_GAMIFIED_V1,
                abi.encodeWithSelector(
                    IAirdropGamifiedUUPSUpgradeable.initializeUUPS.selector,
                    cfg,
                    roleAdmin,
                    upgrader
                )
            );
        }

        _pushModuleIfNotExists(org, Modules.AIRDROP_GAMIFIED_V1);
        org.airdrop.gamified.push(airdropGamified);
    }

    function getImplementation() external view returns (address) {
        return _getImplementation();
    }

    function getOrganisationModules(bytes32 id) external view returns (string[] memory) {
        return _getOrganisationOrRevert(id).modules;
    }

    function _pushModuleIfNotExists(Organisation storage org, string memory module) internal {
        for (uint256 i = 0; i < org.modules.length; i++) {
            if (keccak256(bytes(org.modules[i])) == keccak256(bytes(module))) {
                return;
            }
        }

        org.modules.push(module);
    }

    function _authorizeUpgrade(address) internal view override {
        require(hasRole(UPGRADER_ROLE, msg.sender), "OrganisationRegistry: caller does not have upgrader role");
    }

    function _getOrganisationWithOwnerOrRevert(bytes32 id, address owner) internal view returns (Organisation storage) {
        Organisation storage org = _getOrganisationOrRevert(id);
        require(org.owner == owner, "OrganisationRegistry: caller is not the owner");

        return org;
    }

    function _getOrganisationOrRevert(bytes32 id) internal view returns (Organisation storage) {
        Organisation storage org = organisations[id];
        require(org.exists == true, "OrganisationRegistry: organisation does not exist");

        return org;
    }

    function _requireModuleExists(address module) internal pure {
        require(module != address(0), "OrganisationRegistry: required module not deployed");
    }

    function _requireModuleNotExists(address module) internal pure {
        require(module == address(0), "OrganisationRegistry: module already deployed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IFactory {
    function deployModuleClone(string memory module, bytes memory initData) external payable returns (address);

    function deployModuleUUPS(string memory module, bytes memory initData) external payable returns (address);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IToken {
    struct TokenConfig {
        string name;
        string symbol;
        bool mintable;
        bool capped;
        uint256 initialSupply;
        address initialSupplyHolder;
        uint256 maxSupply;
        address minter;
    }

    function initialize(TokenConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IToken.sol";

interface ITokenUUPSUpgradeable is IToken {
    function initializeUUPS(IToken.TokenConfig memory cfg, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IDAOStaking {
    struct Checkpoint {
        uint256 timestamp;
        uint256 amount;
    }

    struct Stake {
        uint256 timestamp;
        uint256 amount;
        uint256 expiryTimestamp;
        address delegatedTo;
    }

    struct DAOStakingConfig {
        address govToken;
    }

    function initialize(DAOStakingConfig memory cfg, address roleAdmin) external;

    function deposit(uint256 amount) external;

    function delegate(address to) external;

    function govTokenStaked() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IDAOStaking.sol";

interface IDAOStakingUUPSUpgradeable is IDAOStaking {
    function initializeUUPS(
        DAOStakingConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IGovernance {
    struct GovernanceConfig {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
        uint256 activationThreshold;
        uint256 proposalMaxActions;
        uint256 creationThresholdPercentage;
        address daoStakingAddr;
    }

    enum ProposalState {
        WarmUp,
        Active,
        Canceled,
        Failed,
        Accepted,
        Queued,
        Grace,
        Expired,
        Executed,
        Abrogated
    }

    struct Receipt {
        // Whether or not a vote has been cast
        bool hasVoted;
        // The number of votes the voter had, which were cast
        uint256 votes;
        // support
        bool support;
    }

    struct AbrogationProposal {
        address creator;
        uint256 createTime;
        string description;

        uint256 forVotes;
        uint256 againstVotes;

        mapping(address => Receipt) receipts;
    }

    struct ProposalParameters {
        uint256 warmUpDuration;
        uint256 activeDuration;
        uint256 queueDuration;
        uint256 gracePeriodDuration;
        uint256 acceptanceThreshold;
        uint256 minQuorum;
    }

    struct Proposal {
        // proposal identifiers
        // unique id
        uint256 id;
        // Creator of the proposal
        address proposer;
        // proposal description
        string description;
        string title;

        // proposal technical details
        // ordered list of target addresses to be made
        address[] targets;
        // The ordered list of values (i.e. msg.value) to be passed to the calls to be made
        uint256[] values;
        // The ordered list of function signatures to be called
        string[] signatures;
        // The ordered list of calldata to be passed to each call
        bytes[] calldatas;

        // proposal creation time - 1
        uint256 createTime;

        // votes status
        // The timestamp that the proposal will be available for execution, set once the vote succeeds
        uint256 eta;
        // Current number of votes in favor of this proposal
        uint256 forVotes;
        // Current number of votes in opposition to this proposal
        uint256 againstVotes;

        bool canceled;
        bool executed;

        // Receipts of ballots for the entire set of voters
        mapping(address => Receipt) receipts;

        ProposalParameters parameters;
    }

    function initialize(GovernanceConfig memory cfg) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IRewardsEscrow {
    function initialize(address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IRewardsEscrow.sol";

interface IRewardsEscrowUUPSUpgradeable is IRewardsEscrow{
    function initializeUUPS(address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IRewards {
    struct Pull {
        address source;
        uint256 startTs;
        uint256 endTs;
        uint256 totalDuration;
        uint256 totalAmount;
    }

    struct RewardsConfig {
        address token;
        address daoStaking;
    }

    function initialize(RewardsConfig memory config, address roleAdmin) external;

    function registerUserAction(address user) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IRewards.sol";

interface IRewardsUUPSUpgradeable is IRewards {
    function initializeUUPS(RewardsConfig memory config, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IStaking {
    struct Pool {
        uint256 size;
        bool set;
    }

    // a checkpoint of the valid balance of a user for an epoch
    struct Checkpoint {
        uint128 epochId;
        uint128 multiplier;
        uint256 startBalance;
        uint256 newDeposits;
    }

    struct StakingConfig {
        uint256 epoch1Start;
        uint256 epochDuration;
    }

    function initialize(StakingConfig memory cfg, address roleAdmin) external;

    function getEpochUserBalance(address user, address token, uint128 epoch) external view returns(uint256);
    function getEpochPoolSize(address token, uint128 epoch) external view returns (uint256);
    function epoch1Start() external view returns (uint256);
    function epochDuration() external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IStaking.sol";

interface IStakingUUPSUpgradeable is IStaking {
    function initializeUUPS(StakingConfig memory cfg, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IYieldFarm {
    struct YieldFarmConfig {
        address[] poolTokenAddresses;
        address rewardTokenAddress;
        address stakingAddress;
        address rewardsEscrowAddress;
        uint256 totalDistributedAmount;
        uint256 numberOfEpochs;
        uint128 epochsDelayedFromStaking;
    }

    struct TokenDetails {
        address addr;
        uint8 decimals;
    }

    function initialize(YieldFarmConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IYieldFarm.sol";

interface IYieldFarmUUPSUpgradeable is IYieldFarm {
    function initializeUUPS(YieldFarmConfig memory cfg, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IVesting {
    struct VestingConfig {
        address claimant;
        address rewardToken;
        uint256 startTime;
        uint256 numberOfEpochs;
        uint256 epochDuration;
        uint256 totalDistributedAmount;
    }

    function initialize(VestingConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IVesting.sol";

interface IVestingUUPSUpgradeable is IVesting {
    function initializeUUPS(
        VestingConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IVestingCliffs {
    struct Cliff {
        uint256 ClaimablePercentage;
        uint256 RequiredTime;
    }

    struct VestingCliffsConfig {
        address claimant;
        address rewardToken;
        uint256 startTime;
        uint256 totalAmount;
        Cliff[] cliffs;
    }

    function initialize(VestingCliffsConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IVestingCliffs.sol";

interface IVestingCliffsUUPSUpgradeable is IVestingCliffs {
    function initializeUUPS(
        VestingCliffsConfig memory cfg,
        address roleAdmin,
        address upgrader
    ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IAirdrop {
    struct AirdropConfig {
        address token;
        bytes32 merkleRoot;
        uint256 totalAirdroppedAmount;
    }

    function initialize(AirdropConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IAirdrop.sol";

interface IAirdropUUPSUpgradeable is IAirdrop {
    function initializeUUPS(AirdropConfig memory cfg, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

interface IAirdropGamified {
    struct AirdropGamifiedConfig {
        address token;
        bytes32 merkleRoot;
        uint256 numberOfAccounts;
        uint256 totalAirdroppedAmount;
        uint256 gameStart;
        uint256 gameDuration;
    }

    function initialize(AirdropGamifiedConfig memory cfg, address roleAdmin) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

import "./IAirdropGamified.sol";

interface IAirdropGamifiedUUPSUpgradeable is IAirdropGamified {
    function initializeUUPS(AirdropGamifiedConfig memory cfg, address roleAdmin, address upgrader) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.14;

library Modules {
    string constant public TOKEN_V1 = "token_v1";
    string constant public DAO_V1_GOVERNANCE = "dao_v1_governance";
    string constant public DAO_V1_STAKING = "dao_v1_staking";
    string constant public DAO_V1_REWARDS = "dao_v1_rewards";
    string constant public REWARDS_ESCROW_V1 = "rewards_escrow_v1";
    string constant public YF_V1_STAKING = "yf_v1_staking";
    string constant public YF_V1_POOL = "yf_v1_pool";
    string constant public VESTING_V1 = "vesting_v1";
    string constant public VESTING_CLIFFS_V1 = "vesting_cliffs_v1";
    string constant public AIRDROP_SIMPLE_V1 = "airdrop_simple_v1";
    string constant public AIRDROP_GAMIFIED_V1 = "airdrop_gamified_v1";
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}