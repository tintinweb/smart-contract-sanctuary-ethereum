// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC1967Proxy } from "openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { Auth } from "../dependencies/solmate/Auth.sol";
import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";

import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";
import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { ISubscribeDeployer } from "../interfaces/ISubscribeDeployer.sol";
import { IEssenceDeployer } from "../interfaces/IEssenceDeployer.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { ProfileNFT } from "./ProfileNFT.sol";
import { CyberEngineStorage } from "../storages/CyberEngineStorage.sol";
import { UpgradeableBeacon } from "../upgradeability/UpgradeableBeacon.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

/**
 * @title CyberEngine
 * @author CyberConnect
 * @notice This is the main entry point for the CyberConnect contract.
 */
contract CyberEngine is
    Initializable,
    Auth,
    UUPSUpgradeable,
    CyberEngineStorage,
    IUpgradeable,
    ICyberEngine
{
    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks if the sender is authorized to upgrade the contract.
     */
    modifier canUpgrade() {
        require(
            isAuthorized(msg.sender, Constants._AUTHORIZE_UPGRADE),
            "UNAUTHORIZED"
        );

        _;
    }

    /**
     * @notice Checks that the namespace owner is the sender address.
     */
    modifier onlyNamespaceOwner(address namespace) {
        bytes memory byteName = bytes(_namespaceInfo[namespace].name);
        require(byteName.length > 0, "INVALID_NAMESPACE");
        require(
            IProfileNFT(namespace).getNamespaceOwner() == msg.sender,
            "ONLY_NAMESPACE_OWNER"
        );
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberEngine
    function initialize(address _owner, RolesAuthority _rolesAuthority)
        external
        override
        initializer
    {
        Auth.__Auth_Init(_owner, _rolesAuthority);
        emit Initialize(_owner, address(_rolesAuthority));
    }

    /// @inheritdoc ICyberEngine
    function allowProfileMw(address mw, bool allowed)
        external
        override
        requiresAuth
    {
        bool preAllowed = _profileMwAllowlist[mw];
        _profileMwAllowlist[mw] = allowed;
        emit AllowProfileMw(mw, preAllowed, allowed);
    }

    /// @inheritdoc ICyberEngine
    function allowSubscribeMw(address mw, bool allowed)
        external
        override
        requiresAuth
    {
        bool preAllowed = _subscribeMwAllowlist[mw];
        _subscribeMwAllowlist[mw] = allowed;
        emit AllowSubscribeMw(mw, preAllowed, allowed);
    }

    /// @inheritdoc ICyberEngine
    function allowEssenceMw(address mw, bool allowed)
        external
        override
        requiresAuth
    {
        bool preAllowed = _essenceMwAllowlist[mw];
        _essenceMwAllowlist[mw] = allowed;
        emit AllowEssenceMw(mw, preAllowed, allowed);
    }

    /// @inheritdoc ICyberEngine
    function createNamespace(DataTypes.CreateNamespaceParams calldata params)
        external
        override
        requiresAuth
        returns (
            address profileProxy,
            address subBeacon,
            address essBeacon
        )
    {
        bytes memory byteName = bytes(params.name);
        bytes memory byteSymbol = bytes(params.symbol);

        bytes32 salt = keccak256(byteName);

        require(
            _namespaceByName[salt] == address(0),
            "NAMESPACE_ALREADY_EXISTS"
        );

        require(
            byteName.length <= Constants._MAX_NAME_LENGTH &&
                byteName.length > 0,
            "NAME_INVALID_LENGTH"
        );
        require(
            byteSymbol.length <= Constants._MAX_SYMBOL_LENGTH &&
                byteSymbol.length > 0,
            "SYMBOL_INVALID_LENGTH"
        );

        _namespaceInfo[params.addrs.profileProxy].name = params.name;
        _namespaceByName[salt] = params.addrs.profileProxy;

        {
            address subscribeImpl = ISubscribeDeployer(
                params.addrs.subscribeFactory
            ).deploySubscribe(salt, params.addrs.profileProxy);

            address essImpl = IEssenceDeployer(params.addrs.essenceFactory)
                .deployEssence(salt, params.addrs.profileProxy);

            subBeacon = address(
                new UpgradeableBeacon{ salt: salt }(
                    subscribeImpl,
                    address(this)
                )
            );
            essBeacon = address(
                new UpgradeableBeacon{ salt: salt }(essImpl, address(this))
            );

            address profileImpl = IProfileDeployer(params.addrs.profileFactory)
                .deployProfile(salt, address(this), subBeacon, essBeacon);

            bytes memory data = abi.encodeWithSelector(
                ProfileNFT.initialize.selector,
                params.owner,
                params.name,
                params.symbol
            );

            profileProxy = address(
                new ERC1967Proxy{ salt: salt }(profileImpl, data)
            );
        }
        require(
            profileProxy == params.addrs.profileProxy,
            "PROFILE_PROXY_WRONG_ADDRESS"
        );

        emit CreateNamespace(profileProxy, params.name, params.symbol);
    }

    /// @inheritdoc ICyberEngine
    function upgradeSubscribeNFT(address newImpl, address namespace)
        external
        override
        requiresAuth
    {
        address subscribeBeacon = ProfileNFT(namespace).SUBSCRIBE_BEACON();
        UpgradeableBeacon(subscribeBeacon).upgradeTo(newImpl);
    }

    /// @inheritdoc ICyberEngine
    function upgradeEssenceNFT(address newImpl, address namespace)
        external
        override
        requiresAuth
    {
        address essenceBeacon = ProfileNFT(namespace).ESSENCE_BEACON();
        UpgradeableBeacon(essenceBeacon).upgradeTo(newImpl);
    }

    /// @inheritdoc ICyberEngine
    function setProfileMw(
        address namespace,
        address mw,
        bytes calldata data
    ) external override onlyNamespaceOwner(namespace) {
        require(
            mw == address(0) || _profileMwAllowlist[mw],
            "PROFILE_MW_NOT_ALLOWED"
        );
        _namespaceInfo[namespace].profileMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = IProfileMiddleware(mw).setProfileMwData(
                namespace,
                data
            );
        }
        emit SetProfileMw(namespace, mw, returnData);
    }

    /// @inheritdoc ICyberEngine
    function isEssenceMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _essenceMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function isSubscribeMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _subscribeMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function isProfileMwAllowed(address mw)
        external
        view
        override
        returns (bool)
    {
        return _profileMwAllowlist[mw];
    }

    /// @inheritdoc ICyberEngine
    function getNameByNamespace(address namespace)
        external
        view
        override
        returns (string memory)
    {
        return _namespaceInfo[namespace].name;
    }

    /// @inheritdoc ICyberEngine
    function getProfileMwByNamespace(address namespace)
        external
        view
        override
        returns (address)
    {
        return _namespaceInfo[namespace].profileMw;
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    // UUPS upgradeability
    function _authorizeUpgrade(address) internal override canUpgrade {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822.sol";
import "../ERC1967/ERC1967Upgrade.sol";

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
abstract contract UUPSUpgradeable is IERC1822Proxiable, ERC1967Upgrade {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Adapted from Solmate's Auth.sol with initializer replacing the constructor.

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
abstract contract Auth {
    event OwnerUpdated(address indexed user, address indexed newOwner);

    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    address public owner;

    Authority public authority;

    function __Auth_Init(address _owner, Authority _authority) internal {
        owner = _owner;
        authority = _authority;

        emit OwnerUpdated(msg.sender, _owner);
        emit AuthorityUpdated(msg.sender, _authority);
    }

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig)) || user == owner;
    }

    function setAuthority(Authority newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(msg.sender == owner || authority.canCall(msg.sender, address(this), msg.sig));

        authority = newAuthority;

        emit AuthorityUpdated(msg.sender, newAuthority);
    }

    function setOwner(address newOwner) public virtual requiresAuth {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import { Auth, Authority } from "./Auth.sol";

/// @notice Adapted from Solmate's RolesAuthority.sol using Auth's initializer instead of constructor.

/// @notice Role based Authority that supports up to 256 roles.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-roles/blob/master/src/roles.sol)
contract RolesAuthority is Auth, Authority {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UserRoleUpdated(address indexed user, uint8 indexed role, bool enabled);

    event PublicCapabilityUpdated(address indexed target, bytes4 indexed functionSig, bool enabled);

    event RoleCapabilityUpdated(uint8 indexed role, address indexed target, bytes4 indexed functionSig, bool enabled);

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner, Authority _authority) {
        Auth.__Auth_Init(_owner, _authority);
    }

    /*//////////////////////////////////////////////////////////////
                            ROLE/USER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => bytes32) public getUserRoles;

    mapping(address => mapping(bytes4 => bool)) public isCapabilityPublic;

    mapping(address => mapping(bytes4 => bytes32)) public getRolesWithCapability;

    function doesUserHaveRole(address user, uint8 role) public view virtual returns (bool) {
        return (uint256(getUserRoles[user]) >> role) & 1 != 0;
    }

    function doesRoleHaveCapability(
        uint8 role,
        address target,
        bytes4 functionSig
    ) public view virtual returns (bool) {
        return (uint256(getRolesWithCapability[target][functionSig]) >> role) & 1 != 0;
    }

    /*//////////////////////////////////////////////////////////////
                           AUTHORIZATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function canCall(
        address user,
        address target,
        bytes4 functionSig
    ) public view virtual override returns (bool) {
        return
            isCapabilityPublic[target][functionSig] ||
            bytes32(0) != getUserRoles[user] & getRolesWithCapability[target][functionSig];
    }

    /*//////////////////////////////////////////////////////////////
                   ROLE CAPABILITY CONFIGURATION LOGIC
    //////////////////////////////////////////////////////////////*/

    function setPublicCapability(
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        isCapabilityPublic[target][functionSig] = enabled;

        emit PublicCapabilityUpdated(target, functionSig, enabled);
    }

    function setRoleCapability(
        uint8 role,
        address target,
        bytes4 functionSig,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getRolesWithCapability[target][functionSig] |= bytes32(1 << role);
        } else {
            getRolesWithCapability[target][functionSig] &= ~bytes32(1 << role);
        }

        emit RoleCapabilityUpdated(role, target, functionSig, enabled);
    }

    /*//////////////////////////////////////////////////////////////
                       USER ROLE ASSIGNMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    function setUserRole(
        address user,
        uint8 role,
        bool enabled
    ) public virtual requiresAuth {
        if (enabled) {
            getUserRoles[user] |= bytes32(1 << role);
        } else {
            getUserRoles[user] &= ~bytes32(1 << role);
        }

        emit UserRoleUpdated(user, role, enabled);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { RolesAuthority } from "../dependencies/solmate/RolesAuthority.sol";

import { ICyberEngineEvents } from "../interfaces/ICyberEngineEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngine is ICyberEngineEvents {
    /**
     * @notice Initializes the CyberEngine.
     *
     * @param _owner Owner to set for CyberEngine.
     * @param _rolesAuthority RolesAuthority address to manage access control
     */
    function initialize(address _owner, RolesAuthority _rolesAuthority)
        external;

    /**
     * @notice Allows the profile middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowProfileMw(address mw, bool allowed) external;

    /**
     * @notice Allows the subscriber middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowSubscribeMw(address mw, bool allowed) external;

    /**
     * @notice Allows the essence middleware.
     *
     * @param mw The middleware address.
     * @param allowed The allowance state.
     */
    function allowEssenceMw(address mw, bool allowed) external;

    /**
     * @notice Creates a new namespace.
     *
     * @param params The namespace params:
     *  name: The namespace name.
     *  symbol: The namespace symbol.
     *  owner: The namespace owner.
     * @return profileProxy The profile proxy address.
     * @return subBeacon The Subscribe beacon address.
     * @return essBeacon The Essence beacon address.
     */
    function createNamespace(DataTypes.CreateNamespaceParams calldata params)
        external
        returns (
            address profileProxy,
            address subBeacon,
            address essBeacon
        );

    /**
     * @notice Upgrade SubscribeNFT to new version by namespace.
     *
     * @param newImpl The new SubscribeNFT implementation address.
     * @param namespace The namespace to upgrade.
     */
    function upgradeSubscribeNFT(address newImpl, address namespace) external;

    /**
     * @notice Upgrade EssenceNFT to new version by namespace.
     *
     * @param newImpl The new EssenceNFT implementation address.
     * @param namespace The namespace to upgrade.
     */
    function upgradeEssenceNFT(address newImpl, address namespace) external;

    /**
     * @notice Sets the profile middleware.
     *
     * @param namespace The namespace address.
     * @param mw The middleware address.
     * @param data The middleware data.
     * @dev the profile middleware needs to be allowed first.
     */
    function setProfileMw(
        address namespace,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Gets the profile name by the namespace.
     *
     * @param namespace The namespace address.
     * @return string The profile name.
     */
    function getNameByNamespace(address namespace)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile middleware by the namespace.
     *
     * @param namespace The namespace address.
     * @return address The middleware name.
     */
    function getProfileMwByNamespace(address namespace)
        external
        view
        returns (address);

    /**
     * @notice Checks if the essence middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isEssenceMwAllowed(address mw) external view returns (bool);

    /**
     * @notice Checks if the subscriber middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isSubscribeMwAllowed(address mw) external view returns (bool);

    /**
     * @notice Checks if the profile middleware is allowed.
     *
     * @param mw The middleware address.
     * @return bool The allowance state.
     */
    function isProfileMwAllowed(address mw) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileMiddleware {
    /**
     * @notice Sets namespace related data for middleware.
     *
     * @param namespace The related namespace address.
     * @param data Extra data to set.
     */
    function setProfileMwData(address namespace, bytes calldata data)
        external
        returns (bytes memory);

    /**
     * @notice Proccess that runs before the profileNFT creation happens.
     *
     * @param params The params for creating profile.
     * @param data Extra data to process.
     */
    function preProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external payable;

    /**
     * @notice Proccess that runs after the profileNFT creation happens.
     *
     * @param params The params for creating profile.
     * @param data Extra data to process.
     */
    function postProcess(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IProfileDeployer {
    /**
     * @notice Parameters when constructing a ProfileNFT.
     *
     * @return engine The CyberEngine address.
     * @return subBeacon The Subscribe Beacon address.
     * @return essenceBeacon The Essence Beacon address.
     */
    function profileParams()
        external
        view
        returns (
            address engine,
            address subBeacon,
            address essenceBeacon
        );

    /**
     * @notice Deploy a new ProfileNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param engine The CyberEngine address.
     * @param subscribeBeacon The Subscribe Beacon address.
     * @param essenceBeacon The Essence Beacon address.
     *
     * @return addr The newly deployed ProfileNFT address.
     */
    function deployProfile(
        bytes32 salt,
        address engine,
        address subscribeBeacon,
        address essenceBeacon
    ) external returns (address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IProfileNFTEvents } from "./IProfileNFTEvents.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFT is IProfileNFTEvents {
    /**
     * @notice Initializes the Profile NFT.
     *
     * @param _owner Owner of the Profile NFT.
     * @param name Name to set for the Profile NFT.
     * @param symbol Symbol to set for the Profile NFT.
     */
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external;

    /*
     * @notice Creates a profile and mints it to the recipient address.
     *
     * @param params contains all params.
     * @param data contains extra data.
     *
     * @dev The current function validates the caller address and the handle before minting
     * and the following conditions must be met:
     * - The caller address must be the engine address.
     * - The recipient address must be a valid Ethereum address.
     * - The handle must contain only a-z, A-Z, 0-9.
     * - The handle must not be already used.
     * - The handle must not be longer than 27 bytes.
     * - The handle must not be empty.
     */
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable returns (uint256);

    /**
     * @notice The subscription functionality.
     *
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @return uint256[] The subscription nft ids.
     * @dev the function requires the stated to be not paused.
     */
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external returns (uint256[] memory);

    /**
     * @notice Subscribe to an address(es) with a signature.
     *
     * @param sender The sender address.
     * @param params The params for subscription.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     * @param sig The EIP712 signature.
     * @dev the function requires the stated to be not paused.
     * @return uint256[] The subscription nft ids.
     */
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256[] memory);

    /**
     * @notice Collect a profile's essence.
     *
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @return uint256 The collected essence nft id.
     */
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external returns (uint256);

    /**
     * @notice Collect a profile's essence with signature.
     *
     * @param sender The sender address.
     * @param params The params for collect.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The collected essence nft id.
     */
    function collectWithSig(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Register an essence.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @return uint256 The new essence count.
     */
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) external returns (uint256);

    /**
     * @notice Register an essence with signature.
     *
     * @param params The params for registration.
     * @param initData The registration initial data.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     * @return uint256 The new essence count.
     */
    function registerEssenceWithSig(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        DataTypes.EIP712Signature calldata sig
    ) external returns (uint256);

    /**
     * @notice Changes the pause state of the profile nft.
     *
     * @param toPause The pause state.
     */
    function pause(bool toPause) external;

    /**
     * @notice Set new namespace owner.
     *
     * @param owner The new owner.
     */
    function setNamespaceOwner(address owner) external;

    /**
     * @notice Sets the Profile NFT Descriptor.
     *
     * @param descriptor The new descriptor address to set.
     */
    function setNFTDescriptor(address descriptor) external;

    /**
     * @notice Sets the NFT metadata as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to set.
     */
    function setMetadata(uint256 profileId, string calldata metadata) external;

    /**
     * @notice Sets the profile metadata with a signture.
     *
     * @param profileId The profile ID.
     * @param metadata The new metadata to be set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setSubscribeData(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setSubscribeDataWithSig(
        uint256 profileId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     */
    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data
    ) external;

    /**
     * @notice Sets subscribe middleware for a profile with signature.
     *
     * @param profileId The profile ID.
     * @param essenceId The profile ID.
     * @param tokenURI The new token URI.
     * @param mw The new middleware to be set.
     * @param data The data for middleware.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setEssenceDataWithSig(
        uint256 profileId,
        uint256 essenceId,
        string calldata tokenURI,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the primary profile for the user.
     *
     * @param profileId The profile ID that is set to be primary.
     */
    function setPrimaryProfile(uint256 profileId) external;

    /**
     * @notice Sets the primary profile for the user with signature.
     *
     * @param profileId The profile ID that is set to be primary.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setPrimaryProfileWithSig(
        uint256 profileId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     */
    function setAvatar(uint256 profileId, string calldata avatar) external;

    /**
     * @notice Sets the NFT avatar as IPFS hash with signature.
     *
     * @param profileId The profile ID.
     * @param avatar The new avatar to set.
     * @param sig The EIP712 signature.
     * @dev Only owner's signature works.
     */
    function setAvatarWithSig(
        uint256 profileId,
        string calldata avatar,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Sets the operator approval.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The approval status.
     */
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external;

    /**
     * @notice Sets the operator approval with a signature.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @param approved The new state of the approval.
     * @param sig The EIP712 signature.
     */
    function setOperatorApprovalWithSig(
        uint256 profileId,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Gets the profile metadata.
     *
     * @param profileId The profile ID.
     * @return string The metadata of the profile.
     */
    function getMetadata(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile NFT descriptor.
     *
     * @return address The descriptor address.
     */
    function getNFTDescriptor() external view returns (address);

    /**
     * @notice Gets the profile avatar.
     *
     * @param profileId The profile ID.
     * @return string The avatar of the profile.
     */
    function getAvatar(uint256 profileId) external view returns (string memory);

    /**
     * @notice Gets the operator approval status.
     *
     * @param profileId The profile ID.
     * @param operator The operator address.
     * @return bool The approval status.
     */
    function getOperatorApproval(uint256 profileId, address operator)
        external
        view
        returns (bool);

    /**
     * @notice Gets the profile handle by ID.
     *
     * @param profileId The profile ID.
     * @return string the profile handle.
     */
    function getHandleByProfileId(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the profile ID by handle.
     *
     * @param handle The profile handle.
     * @return uint256 the profile ID.
     */
    function getProfileIdByHandle(string calldata handle)
        external
        view
        returns (uint256);

    /**
     * @notice Gets a profile subscribe middleware address.
     *
     * @param profileId The profile id.
     * @return address The middleware address.
     */
    function getSubscribeMw(uint256 profileId) external view returns (address);

    /**
     * @notice Gets the primary profile of the user.
     *
     * @param user The wallet address of the user.
     * @return profileId The primary profile of the user.
     */
    function getPrimaryProfile(address user)
        external
        view
        returns (uint256 profileId);

    /**
     * @notice Gets the Subscribe NFT token URI.
     *
     * @param profileId The profile ID.
     * @return string The Subscribe NFT token URI.
     */
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Subscribe NFT address.
     *
     * @param profileId The profile ID.
     * @return address The Subscribe NFT address.
     */
    function getSubscribeNFT(uint256 profileId) external view returns (address);

    /**
     * @notice Gets the Essence NFT token URI.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return string The Essence NFT token URI.
     */
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        returns (string memory);

    /**
     * @notice Gets the Essence NFT address.
     *
     * @param profileId The profile ID.
     * @param essenceId The Essence ID.
     * @return address The Essence NFT address.
     */
    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets a profile essence middleware address.
     *
     * @param profileId The profile id.
     * @param essenceId The Essence ID.
     * @return address The middleware address.
     */
    function getEssenceMw(uint256 profileId, uint256 essenceId)
        external
        view
        returns (address);

    /**
     * @notice Gets the profile namespace owner.
     *
     * @return address The owner of this profile namespace.
     */
    function getNamespaceOwner() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeDeployer {
    /**
     * @notice Parameters when constructing a SubscribeNFT.
     *
     * @return profileProxy The ProfileNFT proxy address.
     */
    function subParams() external view returns (address profileProxy);

    /**
     * @notice Deploy a new SubscribeNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param profileProxy The ProfileNFT proxy address.
     *
     * @return addr The newly deployed SubscribeNFT address.
     */
    function deploySubscribe(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceDeployer {
    /**
     * @notice Parameters when constructing a EssenceNFT.
     *
     * @return profileProxy The ProfileNFT proxy address.
     */
    function essParams() external view returns (address profileProxy);

    /**
     * @notice Deploy a new EssenceNFT.
     *
     * @param salt The salt used to generate contract address in a deterministic way.
     * @param profileProxy The CyberEngine address.
     *
     * @return addr The newly deployed EssenceNFT address.
     */
    function deployEssence(bytes32 salt, address profileProxy)
        external
        returns (address addr);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IUpgradeable {
    /**
     * @notice Contract version number.
     *
     * @return uint256 The version number.
     */
    function version() external pure returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library Constants {
    // Access Control for CyebreEngine
    uint8 internal constant _ENGINE_GOV_ROLE = 1;
    bytes4 internal constant _AUTHORIZE_UPGRADE =
        bytes4(keccak256(bytes("_authorizeUpgrade(address)")));

    // EIP712 TypeHash
    bytes32 internal constant _PERMIT_TYPEHASH =
        keccak256(
            "permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _CREATE_PROFILE_TYPEHASH =
        keccak256(
            "createProfile(address to,string handle,string avatar,string metadata,address operator,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SUBSCRIBE_TYPEHASH =
        keccak256(
            "subscribeWithSig(uint256[] profileIds,bytes[] preDatas,bytes[] postDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _COLLECT_TYPEHASH =
        keccak256(
            "collectWithSig(address collector,uint256 profileId,uint256 essenceId,bytes data,bytes postDatas,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _REGISTER_ESSENCE_TYPEHASH =
        keccak256(
            "registerEssenceWithSig(uint256 profileId,string name,string symbol,string essenceTokenURI,address essenceMw,bytes initData,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_METADATA_TYPEHASH =
        keccak256(
            "setMetadataWithSig(uint256 profileId,string metadata,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_OPERATOR_APPROVAL_TYPEHASH =
        keccak256(
            "setOperatorApprovalWithSign(uint256 profileId,address operator,bool approved,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_SUBSCRIBE_DATA_TYPEHASH =
        keccak256(
            "setSubscribeDataWithSig(uint256 profileId,string tokenURI,address mw,bytes data,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_ESSENCE_DATA_TYPEHASH =
        keccak256(
            "setEssenceDataWithSig(uint256 profileId,uint256 essenceId,string tokenURI,address mw,bytes data,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_AVATAR_TYPEHASH =
        keccak256(
            "setAvatarWithSig(uint256 profileId,string avatar,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _SET_PRIMARY_PROFILE_TYPEHASH =
        keccak256(
            "setPrimaryProfileWithSig(uint256 profileId,uint256 nonce,uint256 deadline)"
        );
    bytes32 internal constant _CLAIM_BOX_TYPEHASH =
        keccak256("claimBox(address to,uint256 nonce,uint256 deadline)");

    // Parameters
    uint8 internal constant _MAX_HANDLE_LENGTH = 20;
    uint8 internal constant _MAX_NAME_LENGTH = 20;
    uint8 internal constant _MAX_SYMBOL_LENGTH = 20;
    uint16 internal constant _MAX_URI_LENGTH = 2000;
    uint16 internal constant _MAX_BPS = 10000;

    // Access Control for UpgradeableBeacon
    bytes4 internal constant _BEACON_UPGRADE_TO =
        bytes4(keccak256(bytes("upgradeTo(address)")));

    // Subscribe NFT
    string internal constant _SUBSCRIBE_NFT_NAME_SUFFIX = "_subscriber";
    string internal constant _SUBSCRIBE_NFT_SYMBOL_SUFFIX = "_SUB";
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

library DataTypes {
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    struct CreateProfileParams {
        address to;
        string handle;
        string avatar;
        string metadata;
        address operator;
    }

    struct CreateNamespaceParams {
        string name;
        string symbol;
        address owner;
        ComputedAddresses addrs;
    }

    struct RegisterEssenceParams {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bool transferable;
    }

    struct SubscribeParams {
        uint256[] profileIds;
    }

    struct CollectParams {
        address collector;
        uint256 profileId;
        uint256 essenceId;
    }

    struct RegisterEssenceData {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        bytes initData;
        address essenceMw;
        bool transferable;
    }

    struct SubscribeData {
        address sender;
        uint256[] profileIds;
        bytes[] preDatas;
        bytes[] postDatas;
        address subBeacon;
    }

    struct CollectData {
        address collector;
        uint256 profileId;
        uint256 essenceId;
        bytes preData;
        bytes postData;
        address essBeacon;
    }

    struct ProfileStruct {
        string handle;
        string avatar;
        uint256 essenceCount;
    }

    struct SubscribeStruct {
        string tokenURI;
        address subscribeNFT;
        address subscribeMw;
    }

    struct EssenceStruct {
        address essenceNFT;
        address essenceMw;
        string name;
        string symbol;
        string tokenURI;
        bool transferable;
    }

    struct NamespaceStruct {
        address profileMw;
        string name;
    }

    struct ConstructTokenURIParams {
        uint256 tokenId;
        string handle;
        uint256 subscribers;
    }

    struct ComputedAddresses {
        address profileProxy;
        address profileFactory;
        address subscribeFactory;
        address essenceFactory;
    }

    struct ProfileDeployParameters {
        address engine;
        address subBeacon;
        address essenceBeacon;
    }

    struct SubscribeDeployParameters {
        address profileProxy;
    }

    struct EssenceDeployParameters {
        address profileProxy;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { UUPSUpgradeable } from "openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import { ReentrancyGuard } from "../dependencies/openzeppelin/ReentrancyGuard.sol";
import { Pausable } from "../dependencies/openzeppelin/Pausable.sol";

import { IProfileNFT } from "../interfaces/IProfileNFT.sol";
import { IUpgradeable } from "../interfaces/IUpgradeable.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { IProfileMiddleware } from "../interfaces/IProfileMiddleware.sol";
import { IProfileDeployer } from "../interfaces/IProfileDeployer.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";
import { Actions } from "../libraries/Actions.sol";

import { CyberNFTBase } from "../base/CyberNFTBase.sol";
import { ProfileNFTStorage } from "../storages/ProfileNFTStorage.sol";

/**
 * @title Profile NFT
 * @author CyberConnect
 * @notice This contract is used to create a profile NFT.
 */
contract ProfileNFT is
    Pausable,
    ReentrancyGuard,
    CyberNFTBase,
    UUPSUpgradeable,
    ProfileNFTStorage,
    IUpgradeable,
    IProfileNFT
{
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/

    /* solhint-disable var-name-mixedcase */

    address public immutable SUBSCRIBE_BEACON;
    address public immutable ESSENCE_BEACON;
    address public immutable ENGINE;

    /* solhint-enable var-name-mixedcase */

    /*//////////////////////////////////////////////////////////////
                              MODIFIERS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Checks that the profile owner is the sender address.
     */
    modifier onlyProfileOwner(uint256 profileId) {
        require(ownerOf(profileId) == msg.sender, "ONLY_PROFILE_OWNER");
        _;
    }

    /**
     * @notice Checks that the profile owner or operator is the sender address.
     */
    modifier onlyProfileOwnerOrOperator(uint256 profileId) {
        require(
            ownerOf(profileId) == msg.sender ||
                getOperatorApproval(profileId, msg.sender),
            "ONLY_PROFILE_OWNER_OR_OPERATOR"
        );
        _;
    }

    /**
     * @notice Checks that the namespace owner is the sender address.
     */
    modifier onlyNamespaceOwner() {
        require(_namespaceOwner == msg.sender, "ONLY_NAMESPACE_OWNER");
        _;
    }

    /**
     * @notice Checks that the CyberEngine is the sender address.
     */
    modifier onlyEngine() {
        require(ENGINE == msg.sender, "ONLY_ENGINE");
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        (
            address engine,
            address subBeacon,
            address essenceBeacon
        ) = IProfileDeployer(msg.sender).profileParams();
        require(engine != address(0), "ENGINE_NOT_SET");
        require(subBeacon != address(0), "SUBSCRIBE_BEACON_NOT_SET");
        require(essenceBeacon != address(0), "ESSENCE_BEACON_NOT_SET");
        ENGINE = engine;
        SUBSCRIBE_BEACON = subBeacon;
        ESSENCE_BEACON = essenceBeacon;
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IProfileNFT
    function initialize(
        address _owner,
        string calldata name,
        string calldata symbol
    ) external override initializer {
        require(_owner != address(0), "ZERO_ADDRESS");
        _namespaceOwner = _owner;
        CyberNFTBase._initialize(name, symbol);
        ReentrancyGuard.__ReentrancyGuard_init();
        _pause();
        emit Initialize(_owner, name, symbol);
    }

    /// @inheritdoc IProfileNFT
    function createProfile(
        DataTypes.CreateProfileParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external payable override nonReentrant returns (uint256 tokenID) {
        address profileMw = ICyberEngine(ENGINE).getProfileMwByNamespace(
            address(this)
        );

        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).preProcess{ value: msg.value }(
                params,
                preData
            );
        }

        tokenID = _createProfile(params);
        if (profileMw != address(0)) {
            IProfileMiddleware(profileMw).postProcess(params, postData);
        }
    }

    /// @inheritdoc IProfileNFT
    function subscribe(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) external override returns (uint256[] memory) {
        return _subscribe(msg.sender, params, preDatas, postDatas);
    }

    /// @inheritdoc IProfileNFT
    function subscribeWithSig(
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external override returns (uint256[] memory) {
        // let _subscribe handle length check
        uint256 preLength = preDatas.length;
        bytes32[] memory preHashes = new bytes32[](preLength);
        for (uint256 i = 0; i < preLength; ) {
            preHashes[i] = keccak256(preDatas[i]);
            unchecked {
                ++i;
            }
        }
        uint256 postLength = postDatas.length;
        bytes32[] memory postHashes = new bytes32[](postLength);
        for (uint256 i = 0; i < postLength; ) {
            postHashes[i] = keccak256(postDatas[i]);
            unchecked {
                ++i;
            }
        }

        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SUBSCRIBE_TYPEHASH,
                        keccak256(abi.encodePacked(params.profileIds)),
                        keccak256(abi.encodePacked(preHashes)),
                        keccak256(abi.encodePacked(postHashes)),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _subscribe(sender, params, preDatas, postDatas);
    }

    /// @inheritdoc IProfileNFT
    function collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) external override returns (uint256 tokenId) {
        return _collect(params, preData, postData);
    }

    /// @inheritdoc IProfileNFT
    function collectWithSig(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData,
        address sender,
        DataTypes.EIP712Signature calldata sig
    ) external override returns (uint256 tokenId) {
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        params.collector,
                        params.profileId,
                        params.essenceId,
                        keccak256(preData),
                        keccak256(postData),
                        nonces[sender]++,
                        sig.deadline
                    )
                )
            ),
            sender,
            sig
        );
        return _collect(params, preData, postData);
    }

    /// @inheritdoc IProfileNFT
    function registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    )
        external
        override
        onlyProfileOwnerOrOperator(params.profileId)
        returns (uint256)
    {
        return _registerEssence(params, initData);
    }

    /// @inheritdoc IProfileNFT
    function registerEssenceWithSig(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData,
        DataTypes.EIP712Signature calldata sig
    ) external override returns (uint256 tokenId) {
        address owner = ownerOf(params.profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        params.profileId,
                        keccak256(bytes(params.name)),
                        keccak256(bytes(params.symbol)),
                        keccak256(bytes(params.essenceTokenURI)),
                        params.essenceMw,
                        keccak256(initData),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        return _registerEssence(params, initData);
    }

    /// @inheritdoc IProfileNFT
    function pause(bool toPause) external override onlyNamespaceOwner {
        if (toPause) {
            super._pause();
        } else {
            super._unpause();
        }
    }

    /// @inheritdoc IProfileNFT
    function setNamespaceOwner(address owner)
        external
        override
        onlyNamespaceOwner
    {
        require(owner != address(0), "ZERO_ADDRESS");
        _namespaceOwner = owner;

        emit SetNamespaceOwner(msg.sender, owner);
    }

    /// @inheritdoc IProfileNFT
    function setNFTDescriptor(address descriptor)
        external
        override
        onlyNamespaceOwner
    {
        require(descriptor != address(0), "ZERO_ADDRESS");
        _nftDescriptor = descriptor;
        emit SetNFTDescriptor(descriptor);
    }

    /// @inheritdoc IProfileNFT
    function setAvatar(uint256 profileId, string calldata avatar)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setAvatar(profileId, avatar);
    }

    /// @inheritdoc IProfileNFT
    function setAvatarWithSig(
        uint256 profileId,
        string calldata avatar,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_AVATAR_TYPEHASH,
                        profileId,
                        keccak256(bytes(avatar)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setAvatar(profileId, avatar);
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) external override onlyProfileOwner(profileId) {
        _setOperatorApproval(profileId, operator, approved);
    }

    /// @inheritdoc IProfileNFT
    function setOperatorApprovalWithSig(
        uint256 profileId,
        address operator,
        bool approved,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_OPERATOR_APPROVAL_TYPEHASH,
                        profileId,
                        operator,
                        approved,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setOperatorApproval(profileId, operator, approved);
    }

    /// @inheritdoc IProfileNFT
    function setMetadata(uint256 profileId, string calldata metadata)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function setMetadataWithSig(
        uint256 profileId,
        string calldata metadata,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_METADATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(metadata)),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setMetadata(profileId, metadata);
    }

    /// @inheritdoc IProfileNFT
    function setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlyProfileOwnerOrOperator(profileId) {
        _setSubscribeData(profileId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setSubscribeDataWithSig(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_SUBSCRIBE_DATA_TYPEHASH,
                        profileId,
                        keccak256(bytes(uri)),
                        mw,
                        keccak256(data),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setSubscribeData(profileId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) external override onlyProfileOwnerOrOperator(profileId) {
        _setEssenceData(profileId, essenceId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setEssenceDataWithSig(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_ESSENCE_DATA_TYPEHASH,
                        profileId,
                        essenceId,
                        keccak256(bytes(uri)),
                        mw,
                        keccak256(data),
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setEssenceData(profileId, essenceId, uri, mw, data);
    }

    /// @inheritdoc IProfileNFT
    function setPrimaryProfile(uint256 profileId)
        external
        override
        onlyProfileOwnerOrOperator(profileId)
    {
        _setPrimaryProfile(msg.sender, profileId);
    }

    /// @inheritdoc IProfileNFT
    function setPrimaryProfileWithSig(
        uint256 profileId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(profileId);
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._SET_PRIMARY_PROFILE_TYPEHASH,
                        profileId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );
        _setPrimaryProfile(owner, profileId);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IUpgradeable
    function version() external pure virtual override returns (uint256) {
        return _VERSION;
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeMw(uint256 profileId)
        external
        view
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeMw;
    }

    /// @inheritdoc IProfileNFT
    function getPrimaryProfile(address user)
        external
        view
        override
        returns (uint256)
    {
        return _addressToPrimaryProfile[user];
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeNFT(uint256 profileId)
        external
        view
        override
        returns (address)
    {
        return _subscribeByProfileId[profileId].subscribeNFT;
    }

    /// @inheritdoc IProfileNFT
    function getSubscribeNFTTokenURI(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        return _subscribeByProfileId[profileId].tokenURI;
    }

    /// @inheritdoc IProfileNFT
    function getMetadata(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _metadataById[profileId];
    }

    /// @inheritdoc IProfileNFT
    function getAvatar(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].avatar;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceNFT(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (address)
    {
        return _essenceByIdByProfileId[profileId][essenceId].essenceNFT;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceNFTTokenURI(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (string memory)
    {
        return _essenceByIdByProfileId[profileId][essenceId].tokenURI;
    }

    /// @inheritdoc IProfileNFT
    function getEssenceMw(uint256 profileId, uint256 essenceId)
        external
        view
        override
        returns (address)
    {
        return _essenceByIdByProfileId[profileId][essenceId].essenceMw;
    }

    /// @inheritdoc IProfileNFT
    function getNFTDescriptor() external view override returns (address) {
        return _nftDescriptor;
    }

    /// @inheritdoc IProfileNFT
    function getHandleByProfileId(uint256 profileId)
        external
        view
        override
        returns (string memory)
    {
        _requireMinted(profileId);
        return _profileById[profileId].handle;
    }

    /// @inheritdoc IProfileNFT
    function getProfileIdByHandle(string calldata handle)
        external
        view
        override
        returns (uint256)
    {
        return _profileIdByHandleHash[keccak256(bytes(handle))];
    }

    /// @inheritdoc IProfileNFT
    function getNamespaceOwner() external view override returns (address) {
        return _namespaceOwner;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Transfers the profile nft.
     *
     * @param from The initial owner address.
     * @param to The receipient address.
     * @param id The nft id.
     * @dev It requires the state to be unpaused
     */
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override whenNotPaused {
        super.transferFrom(from, to, id);
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Generates the metadata json object.
     *
     * @param tokenId The profile NFT token ID.
     * @return string The metadata json object.
     * @dev It requires the tokenId to be already minted.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        _requireMinted(tokenId);
        return
            Actions.generateTokenURI(
                tokenId,
                _nftDescriptor,
                _profileById,
                _subscribeByProfileId
            );
    }

    /// @inheritdoc IProfileNFT
    function getOperatorApproval(uint256 profileId, address operator)
        public
        view
        returns (bool)
    {
        _requireMinted(profileId);
        return _operatorApproval[profileId][operator];
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _authorizeUpgrade(address) internal override onlyEngine {}

    function _subscribe(
        address sender,
        DataTypes.SubscribeParams calldata params,
        bytes[] calldata preDatas,
        bytes[] calldata postDatas
    ) internal returns (uint256[] memory) {
        for (uint256 i = 0; i < params.profileIds.length; i++) {
            _requireMinted(params.profileIds[i]);
        }

        return
            Actions.subscribe(
                DataTypes.SubscribeData(
                    sender,
                    params.profileIds,
                    preDatas,
                    postDatas,
                    SUBSCRIBE_BEACON
                ),
                _subscribeByProfileId,
                _profileById
            );
    }

    function _collect(
        DataTypes.CollectParams calldata params,
        bytes calldata preData,
        bytes calldata postData
    ) internal returns (uint256) {
        _requireMinted(params.profileId);

        return
            Actions.collect(
                DataTypes.CollectData(
                    params.collector,
                    params.profileId,
                    params.essenceId,
                    preData,
                    postData,
                    ESSENCE_BEACON
                ),
                _essenceByIdByProfileId
            );
    }

    function _createProfile(DataTypes.CreateProfileParams calldata params)
        internal
        returns (uint256 tokenID)
    {
        bytes32 handleHash = keccak256(bytes(params.handle));
        require(!_exists(_profileIdByHandleHash[handleHash]), "HANDLE_TAKEN");

        tokenID = _mint(params.to);

        _profileById[_currentIndex].handle = params.handle;
        _profileById[_currentIndex].avatar = params.avatar;
        _metadataById[_currentIndex] = params.metadata;
        _profileIdByHandleHash[handleHash] = _currentIndex;

        emit CreateProfile(
            params.to,
            tokenID,
            params.handle,
            params.avatar,
            params.metadata
        );

        if (_addressToPrimaryProfile[params.to] == 0) {
            _addressToPrimaryProfile[params.to] = tokenID;
            emit SetPrimaryProfile(params.to, tokenID);
        }

        if (params.operator != address(0)) {
            require(params.to != params.operator, "INVALID_OPERATOR");
            _setOperatorApproval(_currentIndex, params.operator, true);
        }
    }

    function _registerEssence(
        DataTypes.RegisterEssenceParams calldata params,
        bytes calldata initData
    ) internal returns (uint256) {
        return
            Actions.registerEssence(
                DataTypes.RegisterEssenceData(
                    params.profileId,
                    params.name,
                    params.symbol,
                    params.essenceTokenURI,
                    initData,
                    params.essenceMw,
                    params.transferable
                ),
                ENGINE,
                _profileById,
                _essenceByIdByProfileId
            );
    }

    function _setMetadata(uint256 profileId, string calldata metadata)
        internal
    {
        require(
            bytes(metadata).length <= Constants._MAX_URI_LENGTH,
            "METADATA_INVALID_LENGTH"
        );
        _metadataById[profileId] = metadata;
        emit SetMetadata(profileId, metadata);
    }

    function _setOperatorApproval(
        uint256 profileId,
        address operator,
        bool approved
    ) internal {
        require(operator != address(0), "ZERO_ADDRESS");
        bool prev = _operatorApproval[profileId][operator];
        _operatorApproval[profileId][operator] = approved;
        emit SetOperatorApproval(profileId, operator, prev, approved);
    }

    function _setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) internal {
        Actions.setSubscribeData(
            profileId,
            uri,
            mw,
            data,
            ENGINE,
            _subscribeByProfileId
        );
    }

    function _setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data
    ) internal {
        Actions.setEssenceData(
            profileId,
            essenceId,
            uri,
            mw,
            data,
            ENGINE,
            _essenceByIdByProfileId
        );
    }

    function _setAvatar(uint256 profileId, string calldata avatar) internal {
        require(
            bytes(avatar).length <= Constants._MAX_URI_LENGTH,
            "AVATAR_INVALID_LENGTH"
        );
        _profileById[profileId].avatar = avatar;
        emit SetAvatar(profileId, avatar);
    }

    function _setPrimaryProfile(address owner, uint256 profileId) internal {
        _requireMinted(profileId);

        _addressToPrimaryProfile[owner] = profileId;
        emit SetPrimaryProfile(owner, profileId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract CyberEngineStorage {
    // constant
    string internal constant _VERSION_STRING = "1"; // for 712, should never  change
    uint256 internal constant _VERSION = 1;

    // storage
    mapping(address => bool) internal _profileMwAllowlist;
    mapping(address => bool) internal _essenceMwAllowlist;
    mapping(address => bool) internal _subscribeMwAllowlist;
    mapping(bytes32 => address) internal _namespaceByName;
    mapping(address => DataTypes.NamespaceStruct) internal _namespaceInfo;
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/UpgradeableBeacon.sol)

pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/proxy/beacon/IBeacon.sol";
import "openzeppelin-contracts/contracts/utils/Address.sol";

/**
 * @dev Adapted from Openzepelin's UpgradeableBeacon.sol with RolesAuthority auth
 *
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is IBeacon {
    address private _implementation;
    address public immutable OWNER;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_, address owner) {
        _setImplementation(implementation_);
        OWNER = owner;
    }

    /**
     * @dev Returns the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    /**
     * @dev Upgrades the beacon to a new implementation.
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     * - `newImplementation` must be a contract.
     */
    function upgradeTo(address newImplementation) public virtual {
        require(msg.sender == address(OWNER), "ONLY_OWNER");
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableBeacon: implementation is not a contract");
        _implementation = newImplementation;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

/**
 * Inspired by Openzeppelin's Initializable contract, but simplified for our use case.
 * Explicitly removed support for modifier `initializer` on constructor.
 * Only use `initializer` modifier on the outermost contract and use `onlyInitializing` on the
 * dependencies's init functions.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract Parent, Initializable {
 *     uint256 key;
 *     function __Parent_Init(uint256 _key) onlyInitializing public {
 *         key = _key;
 *     }
 * }
 * contract Child is Parent, Initializable {
 *     function initialize(uint256 _key) initializer external {
 *         __Parent_Init(_key);
 *     }
 * }
 * ```
 */
abstract contract Initializable {
    uint8 private _initialized;
    bool private _initializing;

    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            isTopLevelCall && _initialized < 1,
            "Contract already initialized"
        );
        _initialized = 1;
        _initializing = true;
        _;
        _initializing = false;
    }

    // For internal base contracts' initialize function
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    // For constructor
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
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
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
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
            Address.functionDelegateCall(newImplementation, data);
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
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
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
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
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
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
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
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberEngineEvents {
    /**
     * @notice Emiited when the engine is initialized
     *
     * @param owner The address of the engine owner.
     * @param rolesAuthority The address of the role authority.
     */
    event Initialize(address indexed owner, address indexed rolesAuthority);

    /**
     * @notice Emitted when a profile middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowProfileMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a profile middleware has been set.
     *
     * @param namespace The namespace address.
     * @param mw The middleware address.
     * @param returnData The profile middeware data.
     */
    event SetProfileMw(address indexed namespace, address mw, bytes returnData);

    /**
     * @notice Emitted when a subscription middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowSubscribeMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a essence middleware has been allowed.
     *
     * @param mw The middleware address.
     * @param preAllowed The previously allow state.
     * @param newAllowed The newly set allow state.
     */
    event AllowEssenceMw(
        address indexed mw,
        bool indexed preAllowed,
        bool indexed newAllowed
    );

    /**
     * @notice Emitted when a namespace has been created
     *
     * @param namespace The namespace address.
     * @param name The namespace name.
     * @param symbol The namespace symbol.
     */
    event CreateNamespace(
        address indexed namespace,
        string name,
        string symbol
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTEvents {
    /**
     * @dev Emitted when the ProfileNFT is initialized.
     *
     * @param owner Namespace owner.
     */
    event Initialize(address indexed owner, string name, string symbol);

    /**
     * @notice Emitted when a new Profile NFT Descriptor has been set.
     *
     * @param newDescriptor The newly set descriptor address.
     */
    event SetNFTDescriptor(address indexed newDescriptor);

    /**
     * @notice Emitted when a new namespace owner has been set.
     *
     * @param preOwner The previous owner address.
     * @param newOwner The newly set owner address.
     */
    event SetNamespaceOwner(address indexed preOwner, address indexed newOwner);

    /**
     * @notice Emitted when a new metadata has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newMetadata The newly set metadata.
     */
    event SetMetadata(uint256 indexed profileId, string newMetadata);

    /**
     * @notice Emitted when a new avatar has been set to a profile.
     *
     * @param profileId The profile id.
     * @param newAvatar The newly set avatar.
     */
    event SetAvatar(uint256 indexed profileId, string newAvatar);

    /**
     * @notice Emitted when a primary profile has been set.
     *
     * @param profileId The profile id.
     */
    event SetPrimaryProfile(address indexed user, uint256 indexed profileId);

    /**
     * @notice Emitted when the operator approval has been set.
     *
     * @param profileId The profile id.
     * @param operator The operator address.
     * @param prevApproved The previously set bool value for operator approval.
     * @param approved The newly set bool value for operator approval.
     */
    event SetOperatorApproval(
        uint256 indexed profileId,
        address indexed operator,
        bool prevApproved,
        bool approved
    );

    /**
     * @notice Emitted when a subscription middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetSubscribeData(
        uint256 indexed profileId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a essence middleware has been set to a profile.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param tokenURI The new token URI.
     * @param mw The new middleware.
     * @param prepareReturnData The data used to prepare middleware.
     */
    event SetEssenceData(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a new profile been created.
     *
     * @param to The receiver address.
     * @param profileId The newly generated profile id.
     * @param handle The newly set handle.
     * @param avatar The newly set avatar.
     * @param metadata The newly set metadata.
     */
    event CreateProfile(
        address indexed to,
        uint256 indexed profileId,
        string handle,
        string avatar,
        string metadata
    );

    /**
     * @notice Emitted when a new essence been created.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param name The essence name.
     * @param symbol The essence symbol.
     * @param essenceTokenURI the essence tokenURI.
     * @param essenceMw The essence middleware.
     * @param prepareReturnData The data returned from prepare.
     */
    event RegisterEssence(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string essenceTokenURI,
        address essenceMw,
        bytes prepareReturnData
    );

    /**
     * @notice Emitted when a subscription has been created.
     *
     * @param sender The sender address.
     * @param profileIds The profile ids subscribed to.
     * @param preDatas The subscription data for preprocess.
     * @param postDatas The subscription data for postprocess.
     */
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] preDatas,
        bytes[] postDatas
    );

    /**
     * @notice Emitted when a new subscribe nft has been deployed.
     *
     * @param profileId The profile id.
     * @param subscribeNFT The newly deployed subscribe nft address.
     */
    event DeploySubscribeNFT(
        uint256 indexed profileId,
        address indexed subscribeNFT
    );

    /**
     * @notice Emitted when a new essence nft has been deployed.
     *
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param essenceNFT The newly deployed subscribe nft address.
     */
    event DeployEssenceNFT(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed essenceNFT
    );

    /**
     * @notice Emitted when an essence has been collected.
     *
     * @param collector The collector address.
     * @param profileId The profile id.
     * @param essenceId The essence id.
     * @param tokenId The token id of the newly minted essent NFT.
     * @param preData The collect data for preprocess.
     * @param postData The collect data for postprocess.
     */
    event CollectEssence(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 tokenId,
        bytes preData,
        bytes postData
    );
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.7.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev modified from OpenZeppelin ReentrancyGuard.sol adding initialize func
 *
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
abstract contract ReentrancyGuard {
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


    function __ReentrancyGuard_init() internal {
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
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev modified from OpenZeppelin Pausable.sol, removing Context
 *
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { IEssenceNFTEvents } from "./IEssenceNFTEvents.sol";

interface IEssenceNFT is IEssenceNFTEvents {
    /**
     * @notice Mints the Essence NFT.
     *
     * @param to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Initializes the Essence NFT.
     *
     * @param profileId The profile ID for the Essence NFT.
     * @param essenceId The essence ID for the Essence NFT.
     * @param name The name for the Essence NFT.
     * @param symbol The symbol for the Essence NFT.
     * @param transferable Whether the Essence NFT is transferable.
     */
    function initialize(
        uint256 profileId,
        uint256 essenceId,
        string calldata name,
        string calldata symbol,
        bool transferable
    ) external;

    /**
     * @notice Check if this essence NFT is transferable.
     *
     * @return bool Whether this Essence NFT is transferable.
     */
    function isTransferable() external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { BeaconProxy } from "openzeppelin-contracts/contracts/proxy/beacon/BeaconProxy.sol";

import { ISubscribeNFT } from "../interfaces/ISubscribeNFT.sol";
import { IEssenceNFT } from "../interfaces/IEssenceNFT.sol";
import { ISubscribeMiddleware } from "../interfaces/ISubscribeMiddleware.sol";
import { IEssenceMiddleware } from "../interfaces/IEssenceMiddleware.sol";
import { ICyberEngine } from "../interfaces/ICyberEngine.sol";
import { IProfileNFTDescriptor } from "../interfaces/IProfileNFTDescriptor.sol";

import { DataTypes } from "./DataTypes.sol";
import { Constants } from "./Constants.sol";
import { LibString } from "./LibString.sol";
import { CyberNFTBase } from "../base/CyberNFTBase.sol";

library Actions {
    /**
     * @dev Watch ProfileNFT contract for events, see comments in IProfileNFTEvents.sol for the
     * following events
     */
    event DeploySubscribeNFT(
        uint256 indexed profileId,
        address indexed subscribeNFT
    );
    event RegisterEssence(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        string essenceTokenURI,
        address essenceMw,
        bytes prepareReturnData
    );
    event DeployEssenceNFT(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        address indexed essenceNFT
    );
    event CollectEssence(
        address indexed collector,
        uint256 indexed profileId,
        uint256 indexed essenceId,
        uint256 tokenId,
        bytes preData,
        bytes postData
    );
    event Subscribe(
        address indexed sender,
        uint256[] profileIds,
        bytes[] preDatas,
        bytes[] postDatas
    );

    event SetSubscribeData(
        uint256 indexed profileId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    event SetEssenceData(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string tokenURI,
        address mw,
        bytes prepareReturnData
    );

    function subscribe(
        DataTypes.SubscribeData calldata data,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) external returns (uint256[] memory result) {
        require(data.profileIds.length > 0, "NO_PROFILE_IDS");
        require(
            data.profileIds.length == data.preDatas.length &&
                data.preDatas.length == data.postDatas.length,
            "LENGTH_MISMATCH"
        );

        result = new uint256[](data.profileIds.length);

        for (uint256 i = 0; i < data.profileIds.length; i++) {
            address subscribeNFT = _subscribeByProfileId[data.profileIds[i]]
                .subscribeNFT;
            address subscribeMw = _subscribeByProfileId[data.profileIds[i]]
                .subscribeMw;
            // lazy deploy subscribe NFT
            if (subscribeNFT == address(0)) {
                subscribeNFT = _deploySubscribeNFT(
                    data.subBeacon,
                    data.profileIds[i],
                    _subscribeByProfileId,
                    _profileById
                );
                emit DeploySubscribeNFT(data.profileIds[i], subscribeNFT);
            }
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).preProcess(
                    data.profileIds[i],
                    data.sender,
                    subscribeNFT,
                    data.preDatas[i]
                );
            }
            result[i] = ISubscribeNFT(subscribeNFT).mint(data.sender);
            if (subscribeMw != address(0)) {
                ISubscribeMiddleware(subscribeMw).postProcess(
                    data.profileIds[i],
                    data.sender,
                    subscribeNFT,
                    data.postDatas[i]
                );
            }
        }
        emit Subscribe(
            data.sender,
            data.profileIds,
            data.preDatas,
            data.postDatas
        );
    }

    function collect(
        DataTypes.CollectData calldata data,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external returns (uint256 tokenId) {
        require(
            bytes(
                _essenceByIdByProfileId[data.profileId][data.essenceId].tokenURI
            ).length != 0,
            "ESSENCE_NOT_REGISTERED"
        );
        address essenceNFT = _essenceByIdByProfileId[data.profileId][
            data.essenceId
        ].essenceNFT;
        address essenceMw = _essenceByIdByProfileId[data.profileId][
            data.essenceId
        ].essenceMw;

        // lazy deploy essence NFT
        if (essenceNFT == address(0)) {
            bytes memory initData = abi.encodeWithSelector(
                IEssenceNFT.initialize.selector,
                data.profileId,
                data.essenceId,
                _essenceByIdByProfileId[data.profileId][data.essenceId].name,
                _essenceByIdByProfileId[data.profileId][data.essenceId].symbol,
                _essenceByIdByProfileId[data.profileId][data.essenceId]
                    .transferable
            );
            essenceNFT = address(
                new BeaconProxy{ salt: bytes32(data.profileId) }(
                    data.essBeacon,
                    initData
                )
            );
            _essenceByIdByProfileId[data.profileId][data.essenceId]
                .essenceNFT = essenceNFT;
            emit DeployEssenceNFT(data.profileId, data.essenceId, essenceNFT);
        }
        // run middleware before collecting essence
        if (essenceMw != address(0)) {
            IEssenceMiddleware(essenceMw).preProcess(
                data.profileId,
                data.essenceId,
                data.collector,
                essenceNFT,
                data.preData
            );
        }
        tokenId = IEssenceNFT(essenceNFT).mint(data.collector);
        if (essenceMw != address(0)) {
            IEssenceMiddleware(essenceMw).postProcess(
                data.profileId,
                data.essenceId,
                data.collector,
                essenceNFT,
                data.postData
            );
        }
        emit CollectEssence(
            data.collector,
            data.profileId,
            data.essenceId,
            tokenId,
            data.preData,
            data.postData
        );
    }

    function registerEssence(
        DataTypes.RegisterEssenceData calldata data,
        address engine,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external returns (uint256) {
        require(
            data.essenceMw == address(0) ||
                ICyberEngine(engine).isEssenceMwAllowed(data.essenceMw),
            "ESSENCE_MW_NOT_ALLOWED"
        );

        require(bytes(data.name).length != 0, "EMPTY_NAME");
        require(bytes(data.symbol).length != 0, "EMPTY_SYMBOL");
        require(bytes(data.essenceTokenURI).length != 0, "EMPTY_URI");

        uint256 id = ++_profileById[data.profileId].essenceCount;
        _essenceByIdByProfileId[data.profileId][id].name = data.name;
        _essenceByIdByProfileId[data.profileId][id].symbol = data.symbol;
        _essenceByIdByProfileId[data.profileId][id].tokenURI = data
            .essenceTokenURI;
        _essenceByIdByProfileId[data.profileId][id].transferable = data
            .transferable;
        bytes memory returnData;
        if (data.essenceMw != address(0)) {
            _essenceByIdByProfileId[data.profileId][id].essenceMw = data
                .essenceMw;
            returnData = IEssenceMiddleware(data.essenceMw).setEssenceMwData(
                data.profileId,
                id,
                data.initData
            );
        }

        emit RegisterEssence(
            data.profileId,
            id,
            data.name,
            data.symbol,
            data.essenceTokenURI,
            data.essenceMw,
            returnData
        );
        return id;
    }

    function setSubscribeData(
        uint256 profileId,
        string calldata uri,
        address mw,
        bytes calldata data,
        address engine,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId
    ) external {
        require(
            mw == address(0) || ICyberEngine(engine).isSubscribeMwAllowed(mw),
            "SUB_MW_NOT_ALLOWED"
        );
        _subscribeByProfileId[profileId].subscribeMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = ISubscribeMiddleware(mw).setSubscribeMwData(
                profileId,
                data
            );
        }
        _subscribeByProfileId[profileId].tokenURI = uri;
        emit SetSubscribeData(profileId, uri, mw, returnData);
    }

    function setEssenceData(
        uint256 profileId,
        uint256 essenceId,
        string calldata uri,
        address mw,
        bytes calldata data,
        address engine,
        mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
            storage _essenceByIdByProfileId
    ) external {
        require(
            mw == address(0) || ICyberEngine(engine).isEssenceMwAllowed(mw),
            "ESSENCE_MW_NOT_ALLOWED"
        );
        _essenceByIdByProfileId[profileId][essenceId].essenceMw = mw;
        bytes memory returnData;
        if (mw != address(0)) {
            returnData = IEssenceMiddleware(mw).setEssenceMwData(
                profileId,
                essenceId,
                data
            );
        }
        _essenceByIdByProfileId[profileId][essenceId].tokenURI = uri;
        emit SetEssenceData(profileId, essenceId, uri, mw, returnData);
    }

    function generateTokenURI(
        uint256 tokenId,
        address nftDescriptor,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId
    ) external view returns (string memory) {
        require(address(nftDescriptor) != address(0), "NFT_DESCRIPTOR_NOT_SET");
        address subscribeNFT = _subscribeByProfileId[tokenId].subscribeNFT;
        uint256 subscribers;
        if (subscribeNFT != address(0)) {
            subscribers = CyberNFTBase(subscribeNFT).totalSupply();
        }

        return
            IProfileNFTDescriptor(nftDescriptor).tokenURI(
                DataTypes.ConstructTokenURIParams({
                    tokenId: tokenId,
                    handle: _profileById[tokenId].handle,
                    subscribers: subscribers
                })
            );
    }

    function _deploySubscribeNFT(
        address subBeacon,
        uint256 profileId,
        mapping(uint256 => DataTypes.SubscribeStruct)
            storage _subscribeByProfileId,
        mapping(uint256 => DataTypes.ProfileStruct) storage _profileById
    ) private returns (address) {
        string memory name = string(
            abi.encodePacked(
                _profileById[profileId].handle,
                Constants._SUBSCRIBE_NFT_NAME_SUFFIX
            )
        );
        string memory symbol = string(
            abi.encodePacked(
                LibString.toUpper(_profileById[profileId].handle),
                Constants._SUBSCRIBE_NFT_SYMBOL_SUFFIX
            )
        );
        address subscribeNFT = address(
            new BeaconProxy{ salt: bytes32(profileId) }(
                subBeacon,
                abi.encodeWithSelector(
                    ISubscribeNFT.initialize.selector,
                    profileId,
                    name,
                    symbol
                )
            )
        );

        _subscribeByProfileId[profileId].subscribeNFT = subscribeNFT;
        return subscribeNFT;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ERC721 } from "../dependencies/solmate/ERC721.sol";

import { ICyberNFTBase } from "../interfaces/ICyberNFTBase.sol";

import { Constants } from "../libraries/Constants.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

import { EIP712 } from "./EIP712.sol";
import { Initializable } from "../upgradeability/Initializable.sol";

/**
 * @title Cyber NFT Base
 * @author CyberConnect
 * @notice This contract is the base for all NFT contracts.
 */
abstract contract CyberNFTBase is Initializable, EIP712, ERC721, ICyberNFTBase {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    uint256 internal _currentIndex;
    uint256 internal _burnCount;
    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() {
        _disableInitializers();
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external override {
        address owner = ownerOf(tokenId);
        require(owner != spender, "CANNOT_PERMIT_OWNER");
        _requiresExpectedSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Constants._PERMIT_TYPEHASH,
                        spender,
                        tokenId,
                        nonces[owner]++,
                        sig.deadline
                    )
                )
            ),
            owner,
            sig
        );

        getApproved[tokenId] = spender;
        emit Approval(owner, spender, tokenId);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function totalSupply() external view virtual override returns (uint256) {
        return _currentIndex - _burnCount;
    }

    /// @inheritdoc ICyberNFTBase
    function totalMinted() external view virtual override returns (uint256) {
        return _currentIndex;
    }

    /// @inheritdoc ICyberNFTBase
    function totalBurned() external view virtual override returns (uint256) {
        return _burnCount;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc ICyberNFTBase
    function burn(uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(
            msg.sender == owner ||
                msg.sender == getApproved[tokenId] ||
                isApprovedForAll[owner][msg.sender],
            "NOT_OWNER_OR_APPROVED"
        );
        super._burn(tokenId);
        _burnCount++;
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _initialize(string calldata _name, string calldata _symbol)
        internal
        onlyInitializing
    {
        ERC721.__ERC721_Init(_name, _symbol);
    }

    function _mint(address _to) internal virtual returns (uint256) {
        super._safeMint(_to, ++_currentIndex);
        return _currentIndex;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "NOT_MINTED");
    }

    function _domainSeperatorName()
        internal
        view
        virtual
        override
        returns (string memory)
    {
        return name;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract ProfileNFTStorage {
    // constant
    uint256 internal constant _VERSION = 1;

    // storage
    address internal _nftDescriptor;
    address internal _namespaceOwner;
    mapping(uint256 => DataTypes.ProfileStruct) internal _profileById;
    mapping(bytes32 => uint256) internal _profileIdByHandleHash;
    mapping(uint256 => string) internal _metadataById;
    mapping(uint256 => mapping(address => bool)) internal _operatorApproval;
    mapping(address => uint256) internal _addressToPrimaryProfile;
    mapping(uint256 => DataTypes.SubscribeStruct)
        internal _subscribeByProfileId;
    mapping(uint256 => mapping(uint256 => DataTypes.EssenceStruct))
        internal _essenceByIdByProfileId;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
library StorageSlot {
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceNFTEvents {
    /**
     * @notice Emiited when the essence NFT is initialized
     *
     * @param profileId The profile ID for the Essence NFT.
     * @param essenceId The essence ID for the Essence NFT.
     * @param name The name for the Essence NFT.
     * @param symbol The symbol for the Essence NFT.
     * @param transferable Whether the Essence NFT is transferable.
     */
    event Initialize(
        uint256 indexed profileId,
        uint256 indexed essenceId,
        string name,
        string symbol,
        bool transferable
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { ISubscribeNFTEvents } from "./ISubscribeNFTEvents.sol";

interface ISubscribeNFT is ISubscribeNFTEvents {
    /**
     * @notice Mints the Subscribe NFT.
     *
     * @param to The recipient address.
     * @return uint256 The token id.
     */
    function mint(address to) external returns (uint256);

    /**
     * @notice Initializes the Subscribe NFT.
     *
     * @param profileId The profile ID to set for the Subscribe NFT.
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    function initialize(
        uint256 profileId,
        string calldata name,
        string calldata symbol
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeMiddleware {
    /**
     * @notice Sets subscribe related data for middleware.
     *
     * @param profileId The profile id that owns this middleware.
     * @param data Extra data to set.
     */
    function setSubscribeMwData(uint256 profileId, bytes calldata data)
        external
        returns (bytes memory);

    /**
     * @notice Proccess that runs before the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data Extra data to process.
     */
    function preProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Proccess that runs after the subscribeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param subscriber The subscriber address.
     * @param subscrbeNFT The subscribe nft address.
     * @param data Extra data to process.
     */
    function postProcess(
        uint256 profileId,
        address subscriber,
        address subscrbeNFT,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface IEssenceMiddleware {
    /**
     * @notice Sets essence related data for middleware.
     *
     * @param profileId The profile id that owns this middleware.
     * @param essenceId The essence id that owns this middleware.
     * @param data Extra data to set.
     */
    function setEssenceMwData(
        uint256 profileId,
        uint256 essenceId,
        bytes calldata data
    ) external returns (bytes memory);

    /**
     * @notice Proccess that runs before the essenceeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function preProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;

    /**
     * @notice Proccess that runs after the essenceeNFT mint happens.
     *
     * @param profileId The profile Id.
     * @param essenceId The essence Id.
     * @param collector The collector address.
     * @param essenceNFT The essence nft address.
     * @param data Extra data to process.
     */
    function postProcess(
        uint256 profileId,
        uint256 essenceId,
        address collector,
        address essenceNFT,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface IProfileNFTDescriptor {
    /**
     * @notice Sets the profile NFT animation template.
     *
     * @param template The new template.
     */
    function setAnimationTemplate(string calldata template) external;

    /**
     * @notice Generate the Profile NFT Token URI.
     *
     * @param params The dependences of token URI.
     * @return string The token URI.
     */
    function tokenURI(DataTypes.ConstructTokenURIParams calldata params)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

// adapted from 721A contracts
library LibString {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)
            // Cache the end of the memory to calculate the length later.
            let end := ptr
            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }
            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need length * 2 bytes for the digits, 2 bytes for the prefix,
            // and 32 bytes for the length. We add 32 to the total and round down
            // to a multiple of 32. (32 + 2 + 32) = 66.
            str := add(start, and(add(shl(1, length), 66), not(31)))

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            let temp := value
            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
            } length {
                length := sub(length, 1)
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            if temp {
                mstore(0x00, "\x08\xc3\x79\xa0") // Function selector of the error method.
                mstore(0x04, 0x20) // Offset of the error string.
                mstore(0x24, 23) // Length of the error string.
                mstore(0x44, "HEX_LENGTH_INSUFFICIENT") // The error string.
                revert(0x00, 0x64) // Revert with (offset, size).
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(uint256 value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 64 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 64) is 128.
            str := add(start, 128)

            // Cache the end to calculate the length later.
            let end := str

            // Allocate the memory.
            mstore(0x40, str)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            } temp {
                // prettier-ignore
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            // Compute the string's length.
            let strLength := add(sub(end, str), 2)
            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, strLength)
        }
    }

    function toHexString(address value)
        internal
        pure
        returns (string memory str)
    {
        assembly {
            let start := mload(0x40)
            // We need 32 bytes for the length, 2 bytes for the prefix,
            // and 40 bytes for the digits.
            // The next multiple of 32 above (32 + 2 + 40) is 96.
            str := add(start, 96)

            // Allocate the memory.
            mstore(0x40, str)

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            for {
                // Initialize and perform the first pass without check.
                let length := 20
                let temp := value
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
                length := sub(length, 1)
            } length {
                length := sub(length, 1)
            } {
                str := sub(str, 2)
                mstore8(add(str, 1), byte(and(temp, 15), "0123456789abcdef"))
                mstore8(str, byte(and(shr(4, temp), 15), "0123456789abcdef"))
                temp := shr(8, temp)
            }

            // Move the pointer and write the "0x" prefix.
            str := sub(str, 32)
            mstore(str, 0x3078)
            // Move the pointer and write the length.
            str := sub(str, 2)
            mstore(str, 42)
        }
    }

    function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= "A") && (bStr[i] <= "Z")) {
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

    function toUpper(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint256 i = 0; i < bStr.length; i++) {
            if ((bStr[i] >= "a") && (bStr[i] <= "z")) {
                bLower[i] = bytes1(uint8(bStr[i]) - 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

/// @notice Adapted from Solmate's ERC721.sol with initializer replacing the constructor.

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    function __ERC721_Init(string calldata _name, string calldata _symbol)
        internal
    {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        if (to.code.length != 0)
            require(
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

interface ICyberNFTBase {
    /**
     * @notice Gets total number of tokens in existence, burned tokens will reduce the count.
     *
     * @return uint256 The total supply.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the total number of minted tokens.
     *
     * @return uint256 The total minted tokens.
     */
    function totalMinted() external view returns (uint256);

    /**
     * @notice Gets the total number of burned tokens.
     *
     * @return uint256 The total burned tokens.
     */
    function totalBurned() external view returns (uint256);

    /**
     * @notice The EIP-712 permit function.
     *
     * @param spender The spender address.
     * @param tokenId The token ID to approve.
     * @param sig Must produce valid EIP712 signature with `s`, `r`, `v` and `deadline`.
     */
    function permit(
        address spender,
        uint256 tokenId,
        DataTypes.EIP712Signature calldata sig
    ) external;

    /**
     * @notice Burns a token.
     *
     * @param tokenId The token ID to burn.
     */
    function burn(uint256 tokenId) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

import { DataTypes } from "../libraries/DataTypes.sol";

abstract contract EIP712 {
    /*//////////////////////////////////////////////////////////////
                                STATES
    //////////////////////////////////////////////////////////////*/
    bytes32 internal constant _HASHED_VERSION = keccak256("1");
    bytes32 private constant _TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /*//////////////////////////////////////////////////////////////
                            PUBLIC VIEW
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the contract's {EIP712} domain separator.
     *
     * @return bytes32 the contract's {EIP712} domain separator.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    _TYPE_HASH,
                    keccak256(bytes(_domainSeperatorName())),
                    _HASHED_VERSION,
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                              INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        uint8 v,
        bytes32 r,
        bytes32 s,
        uint256 deadline
    ) internal view {
        require(deadline >= block.timestamp, "DEADLINE_EXCEEDED");
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == expectedSigner, "INVALID_SIGNATURE");
    }

    function _requiresExpectedSigner(
        bytes32 digest,
        address expectedSigner,
        DataTypes.EIP712Signature calldata sig
    ) internal view {
        _requiresExpectedSigner(
            digest,
            expectedSigner,
            sig.v,
            sig.r,
            sig.s,
            sig.deadline
        );
    }

    function _hashTypedDataV4(bytes32 structHash)
        internal
        view
        virtual
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR(), structHash)
            );
    }

    function _domainSeperatorName()
        internal
        view
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.14;

interface ISubscribeNFTEvents {
    /**
     * @notice Emiited when the subscribe NFT is initialized
     *
     * @param profileId The profile ID for the Susbcribe NFT.
     * @param name The name for the Subscribe NFT.
     * @param symbol The symbol for the Subscribe NFT.
     */
    event Initialize(uint256 indexed profileId, string name, string symbol);
}