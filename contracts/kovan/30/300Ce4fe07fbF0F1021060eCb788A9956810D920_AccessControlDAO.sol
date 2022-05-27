//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IAccessControlDAO.sol";

/// @title Access Control
/// @notice Use this contract for managing DAO role based permissions
contract AccessControlDAO is IAccessControlDAO, ERC165, UUPSUpgradeable {
    string public constant DAO_ROLE = "DAO_ROLE";
    string public constant OPEN_ROLE = "OPEN_ROLE";

    mapping(string => RoleData) private _roles;
    mapping(address => mapping(bytes4 => string[])) private _actionsToRoles;

    /// @notice Modifier that checks that an account has a specific role. Reverts
    /// with a standardized message including the required role.
    modifier onlyRole(string memory role) {
        _checkRole(role, msg.sender);
        _;
    }

    /// @notice Initialize DAO action and role permissions
    /// @param dao Address to receive DAO role
    /// @param roles What permissions are assigned to
    /// @param roleAdmins Roles which have the ability to remove or add members
    /// @param members Addresses to be granted the specified roles
    /// @param targets Contract addresses for actions to be defined on
    /// @param functionDescs Function descriptions used to define actions
    /// @param actionRoles Roles being granted permission for an action
    function initialize(
        address dao,
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members,
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory actionRoles
    ) external initializer {
        if (
            roles.length != roleAdmins.length ||
            roles.length != members.length ||
            targets.length != functionDescs.length ||
            targets.length != functionDescs.length
        ) revert UnequalArrayLengths();

        _grantRole(DAO_ROLE, dao);
        _grantRolesAndAdmins(roles, roleAdmins, members);
        _addActionsRoles(targets, functionDescs, actionRoles);
        __UUPSUpgradeable_init();
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param roleAdmins The roles being granted as admins of the specified of roles
    /// @param members Addresses being granted each specified role
    function grantRolesAndAdmins(
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members
    ) external onlyRole(DAO_ROLE) {
        _grantRolesAndAdmins(roles, roleAdmins, members);
    }

    /// @notice Grants roles to the specified addresses
    /// @param roles The roles being granted
    /// @param members Addresses being granted each specified role
    function grantRoles(string[] memory roles, address[][] memory members)
        external
        onlyRole(DAO_ROLE)
    {
        _grantRoles(roles, members);
    }

    /// @notice Grants a role to the specified address
    /// @param role The role being granted
    /// @param account The address being granted the specified role
    function grantRole(string memory role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /// @notice Revokes a role from the specified address
    /// @param role The role being revoked
    /// @param account The address the role is being revoked from
    function revokeRole(string memory role, address account)
        external
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /// @notice Enables an address to remove one of its own roles
    /// @param role The role being renounced
    /// @param account The address renouncing the role
    function renounceRole(string memory role, address account) external {
        if (account != msg.sender) {
            revert OnlySelfRenounce();
        }

        _revokeRole(role, account);
    }

    /// @notice Authorizes roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function descriptions used to define the actions
    /// @param roles Roles being granted permission for an action
    function addActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external onlyRole(DAO_ROLE) {
        _addActionsRoles(targets, functionDescs, roles);
    }

    /// @notice Removes autorization for roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function description used to define the actions
    /// @param roles Roles that action permissions are being removed on
    function removeActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external onlyRole(DAO_ROLE) {
        if (targets.length != functionDescs.length)
            revert UnequalArrayLengths();
        if (targets.length != roles.length) revert UnequalArrayLengths();
        uint256 actionsLength = targets.length;
        for (uint256 i = 0; i < actionsLength; ) {
            uint256 rolesLength = roles[i].length;
            for (uint256 j = 0; j < rolesLength; ) {
                _removeActionRole(targets[i], functionDescs[i], roles[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Checks if a caller has the permissions to execute the specific action
    /// @param caller Address attempting to execute the action
    /// @param target Contract address corresponding to the action
    /// @param sig The function signature used to define the action
    function actionIsAuthorized(
        address caller,
        address target,
        bytes4 sig
    ) external view returns (bool isAuthorized) {
        string[] memory roles = _actionsToRoles[target][sig];
        uint256 roleLength = roles.length;

        for (uint256 i = 0; i < roleLength; ) {
            if (hasRole(roles[i], caller)) {
                isAuthorized = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns the roles autorized to execute the specified action
    /// @param target Contract address corresponding to the action
    /// @param functionDesc The function description used to define the action
    function getActionRoles(address target, string memory functionDesc)
        external
        view
        returns (string[] memory roles)
    {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        return _actionsToRoles[target][encodedSig];
    }

    /// @notice Checks if a specific role is authorized for an action
    /// @param role Role that authorization is being checked on
    /// @param target Contract address corresponding to the action
    /// @param functionDesc Function description used to define the action
    /// @return isAuthorized Indicates whether the role is authorized to execute the action
    function isRoleAuthorized(
        string calldata role,
        address target,
        string memory functionDesc
    ) external view returns (bool isAuthorized) {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        string[] memory roles = _actionsToRoles[target][encodedSig];
        uint256 rolesLength = roles.length;

        for (uint256 i = 0; i < rolesLength; ) {
            if (
                keccak256(abi.encodePacked(role)) ==
                keccak256(abi.encodePacked(roles[i]))
            ) {
                isAuthorized = true;
                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Returns whether the account has been granted the role
    /// @param role Role that authorization is being checked on
    /// @param account Address that the role authorization is being check on
    /// @return boolean Indicates whether the address has been granted the role
    function hasRole(string memory role, address account)
        public
        view
        returns (bool)
    {
        if (
            keccak256(bytes(role)) ==
            keccak256(bytes(OPEN_ROLE))
        ) {
            return true;
        } else {
            return _roles[role].members[account];
        }
    }

    /// @notice Returns the role that is the admin of the specified role
    /// @param role Role that the admin role is being returned for
    /// @return string The admin role of the specified role
    function getRoleAdmin(string memory role)
        public
        view
        returns (string memory)
    {
        return _roles[role].adminRole;
    }

    /// @notice Returns whether a given interface ID is supported
    /// @param interfaceId An interface ID bytes4 as defined by ERC-165
    /// @return bool Indicates whether the interface is supported
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControlDAO).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Sets a role as the admin of another role
    /// @param role The role the admin is being set for
    /// @param adminRole The role that is being assigned as an admin
    function _setRoleAdmin(string memory role, string memory adminRole)
        internal
    {
        string memory previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /// @notice Grants a role to the specified address
    /// @param role The role being granted
    /// @param account The address being granted the specified role
    function _grantRole(string memory role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /// @notice Revokes a role from the specified address
    /// @param role The role being revoked
    /// @param account The address the role is being revoked from
    function _revokeRole(string memory role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param roleAdmins The roles being granted as admins of the specified of roles
    /// @param members Addresses being granted each specified role
    function _grantRolesAndAdmins(
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members
    ) internal {
        if (roles.length != roleAdmins.length) revert UnequalArrayLengths();
        if (roles.length != members.length) revert UnequalArrayLengths();

        uint256 rolesLength = roles.length;
        for (uint256 i = 0; i < rolesLength; ) {
            _setRoleAdmin(roles[i], roleAdmins[i]);

            uint256 membersLength = members[i].length;
            for (uint256 j = 0; j < membersLength; ) {
                _grantRole(roles[i], members[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param members Addresses being granted each specified role
    function _grantRoles(string[] memory roles, address[][] memory members)
        internal
    {
        if (roles.length != members.length) revert UnequalArrayLengths();

        uint256 rolesLength = roles.length;
        for (uint256 i = 0; i < rolesLength; ) {
            uint256 membersLength = members[i].length;
            for (uint256 j = 0; j < membersLength; ) {
                _grantRole(roles[i], members[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Authorizes roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function descriptions used to define the actions
    /// @param roles Roles being granted permission for an action
    function _addActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) internal {
        if (targets.length != functionDescs.length)
            revert UnequalArrayLengths();
        if (targets.length != roles.length) revert UnequalArrayLengths();

        uint256 targetsLength = targets.length;
        for (uint256 i = 0; i < targetsLength; ) {
            uint256 rolesLength = roles[i].length;
            for (uint256 j = 0; j < rolesLength; ) {
                _addActionRole(targets[i], functionDescs[i], roles[i][j]);
                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Authorizes a role to execute the specified action
    /// @param target The contract address that the action function is implemented on
    /// @param functionDesc The function description used to define the action
    /// @param role Role being granted permission for an action
    function _addActionRole(
        address target,
        string memory functionDesc,
        string memory role
    ) internal {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        _actionsToRoles[target][encodedSig].push(role);

        emit ActionRoleAdded(target, functionDesc, encodedSig, role);
    }

    /// @notice Removes authorization of a role to execute the specified action
    /// @param target The contract address that the action function is implemented on
    /// @param functionDesc The function description used to define the action
    /// @param role Role that the action authorization is being removed on
    function _removeActionRole(
        address target,
        string memory functionDesc,
        string memory role
    ) internal {
        bytes4 encodedSig = bytes4(keccak256(abi.encodePacked(functionDesc)));
        uint256 rolesLength = _actionsToRoles[target][encodedSig].length;
        for (uint256 i = 0; i < rolesLength; ) {
            if (
                keccak256(
                    abi.encodePacked(_actionsToRoles[target][encodedSig][i])
                ) == keccak256(abi.encodePacked(role))
            ) {
                _actionsToRoles[target][encodedSig][i] = _actionsToRoles[
                    target
                ][encodedSig][rolesLength - 1];
                _actionsToRoles[target][encodedSig].pop();

                emit ActionRoleRemoved(target, functionDesc, encodedSig, role);

                break;
            }
            unchecked {
                i++;
            }
        }
    }

    /// @notice Reverts when msg.sender is not authorized to upgrade the contract
    /// @notice Only addresses that have the DAO_ROLE role are authorized
    /// @notice Called by upgradeTo and upgradeToAndCall
    /// @param newImplementation New implementation contract address being upgraded to
    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyRole(DAO_ROLE)
    {}

    /// @notice Reverts with a standard message if account is missing role
    /// @param role Role being checked
    /// @param account Address that role is being checked on
    function _checkRole(string memory role, address account) internal view {
        if (!hasRole(role, account)) {
            revert MissingRole(account, role);
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAccessControlDAO {
    struct RoleData {
        mapping(address => bool) members;
        string adminRole;
    }

    error UnequalArrayLengths();
    error MissingRole(address account, string role);
    error OnlySelfRenounce();

    event ActionRoleAdded(
        address target,
        string functionDesc,
        bytes4 encodedSig,
        string role
    );
    event ActionRoleRemoved(
        address target,
        string functionDesc,
        bytes4 encodedSig,
        string role
    );
    event RoleAdminChanged(
        string role,
        string previousAdminRole,
        string adminRole
    );
    event RoleGranted(string role, address account, address admin);
    event RoleRevoked(string role, address account, address admin);

    /// @notice Initialize DAO action and role permissions
    /// @param dao Address to receive DAO role
    /// @param roles What permissions are assigned to
    /// @param roleAdmins Roles which have the ability to remove or add members
    /// @param members Addresses to be granted the specified roles
    /// @param targets Contract addresses for actions to be defined on
    /// @param functionDescs Function descriptions used to define actions
    /// @param actionRoles Roles being granted permission for an action
    function initialize(
        address dao,
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members,
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory actionRoles
    ) external;

    /// @notice Grants roles to the specified addresses and defines admin roles
    /// @param roles The roles being granted
    /// @param roleAdmins The roles being granted as admins of the specified of roles
    /// @param members Addresses being granted each specified role
    function grantRolesAndAdmins(
        string[] memory roles,
        string[] memory roleAdmins,
        address[][] memory members
    ) external;

    /// @notice Grants roles to the specified addresses
    /// @param roles The roles being granted
    /// @param members Addresses being granted each specified role
    function grantRoles(string[] memory roles, address[][] memory members)
        external;

    /// @notice Grants a role to the specified address
    /// @param role The role being granted
    /// @param account The address being granted the specified role
    function grantRole(string memory role, address account) external;

    /// @notice Revokes a role from the specified address
    /// @param role The role being revoked
    /// @param account The address the role is being revoked from
    function revokeRole(string memory role, address account) external;

    /// @notice Enables an address to remove one of its own roles
    /// @param role The role being renounced
    /// @param account The address renouncing the role
    function renounceRole(string memory role, address account) external;

    /// @notice Authorizes roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function descriptions used to define the actions
    /// @param roles Roles being granted permission for an action
    function addActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external;

    /// @notice Removes autorization for roles to execute the specified actions
    /// @param targets The contract addresses that the action functions are implemented on
    /// @param functionDescs The function description used to define the actions
    /// @param roles Roles that action permissions are being removed on
    function removeActionsRoles(
        address[] memory targets,
        string[] memory functionDescs,
        string[][] memory roles
    ) external;

    /// @notice Checks if a caller has the permissions to execute the specific action
    /// @param caller Address attempting to execute the action
    /// @param target Contract address corresponding to the action
    /// @param sig The function signature used to define the action
    function actionIsAuthorized(
        address caller,
        address target,
        bytes4 sig
    ) external view returns (bool isAuthorized);

    /// @notice Returns the roles autorized to execute the specified action
    /// @param target Contract address corresponding to the action
    /// @param functionDesc The function description used to define the action
    function getActionRoles(address target, string memory functionDesc)
        external
        view
        returns (string[] memory roles);

    /// @notice Checks if a specific role is authorized for an action
    /// @param role Role that authorization is being checked on
    /// @param target Contract address corresponding to the action
    /// @param functionDesc Function description used to define the action
    /// @return isAuthorized Indicates whether the role is authorized to execute the action
    function isRoleAuthorized(
        string calldata role,
        address target,
        string memory functionDesc
    ) external view returns (bool isAuthorized);

    /// @notice Returns whether the account has been granted the role
    /// @param role Role that authorization is being checked on
    /// @param account Address that the role authorization is being check on
    /// @return boolean Indicates whether the address has been granted the role
    function hasRole(string memory role, address account)
        external
        view
        returns (bool);

    /// @notice Returns the role that is the admin of the specified role
    /// @param role Role that the admin role is being returned for
    /// @return string The admin role of the specified role
    function getRoleAdmin(string memory role)
        external
        view
        returns (string memory);

    /// @return string The string "DAO_ROLE"
    function DAO_ROLE() external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
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
interface IERC165 {
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