// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
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
// OpenZeppelin Contracts v4.4.0 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IMasterfileFactory} from "contracts/interfaces/IMasterfileFactory.sol";

contract FactoryVersion is IMasterfileFactory {
    address internal factoryRegistry;
    uint256 internal factoryVersion;

    modifier onlyRegistry {
        require(msg.sender == factoryRegistry, "Factory: Invalid registry");
        _;
    }

    constructor(address _registry) {
        factoryRegistry = _registry;
    }

    function getVersion() external view override returns (uint256 version_) {
        return factoryVersion;
    }

    function setVersion(uint256 _version) external onlyRegistry override returns (bool success) {
        require(factoryVersion == 0, "Factory: Version already set");
        factoryVersion = _version;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintingModuleProxy} from "contracts/proxies/MintingModuleProxy.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";
import {FactoryVersion} from "contracts/factories/FactoryVersion.sol";
import {IModuleFactory} from "contracts/interfaces/IModuleFactory.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title MintingModuleFactory
 */
contract MintingModuleFactory is FactoryVersion, IModuleFactory {

    SafeRegistry private _registry;
    address public implementation;

    address public registry;
    address public roleModule;
    address public collectionFactory;

    modifier onlyChannel() {
        require(
            _registry.isDeployment(keccak256("CHANNEL"), msg.sender),
            "Factory Error: Not a channel"
        );
        _;
    }

    constructor(
        address registry_,
        address _implementation,
        address _collectionFactory
    ) FactoryVersion(registry_) {
        _registry = SafeRegistry(registry_);
        implementation = _implementation;
        collectionFactory = _collectionFactory;
    }

    /**
     * @notice Deploy and initialize MintingModule. See `MintingModule.sol`
     * @dev deploy module using clones
     * @param moduleSalt 	Unique hex string
	   * @param _roleModule 	Role module of the channel
     * @return module   	Newly deployed minting module address
     */
    function deployMintingModule(
        bytes32 moduleSalt,
        address _roleModule
    ) public onlyChannel returns (address module) {

        registry = address(_registry);
        roleModule = _roleModule;

        require(
            !Address.isContract(getMintingModuleAddress(moduleSalt)),
            "MintingModuleFactory: Duplicate salt"
        );

        module = address(
            new MintingModuleProxy{salt: moduleSalt}()
        );

        delete registry;
        delete roleModule;

        emit ModuleDeployed(module, msg.sender, bytes4(keccak256("MINTING")));
    }

    function getMintingModuleAddress(bytes32 salt) public view returns (address mintingModuleAddress) {
        bytes memory bytecode = type(MintingModuleProxy).creationCode;

        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode))
        );

        return address(uint160(uint(hash)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterfileFactory {

    function getVersion() external view returns (uint256 version_);

    function setVersion(uint256 _version) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleFactory {
    event ModuleDeployed(
        address indexed module,
        address indexed deployer,
        bytes4 indexed moduleType
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {RoleModuleStorage} from "contracts/storage/RoleModuleStorage.sol";

contract RoleModule is RoleModuleStorage, IAccessControl {

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool _supportsInterface) {
        return interfaceId == type(IAccessControl).interfaceId;
    }

    /**
     * @notice Returns `true` if `account` has been granted `role`.
     * @param role      Account role
     * @param account   Account address
     */
    function hasRole(bytes32 role, address account) public view override returns (bool _hasRole) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @notice Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     * @dev To change a role's admin, use {_setRoleAdmin}.
     * @param role      Account role
     * @return admin    Admin account for the role
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32 admin) {
        return _roles[role].adminRole;
    }

    /**
     * @notice Grants `role` to `account`.
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
     * @notice Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * @param role      Account role to revoke
     * @param account   Account address
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @notice Revokes `role` from the calling account.
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
     * 
     * @param role      Account role to revoke
     * @param account   Account address
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == msg.sender, "AccessControl: can only renounce roles for self");

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
            emit RoleGranted(role, account, msg.sender);
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
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {MintingModuleStorage} from "contracts/storage/MintingModuleStorage.sol";
import {RoleModule} from "contracts/modules/RoleModule.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

interface IMintingModuleFactory {
    function registry() external returns(address);

    function roleModule() external returns(address);

    function collectionFactory() external returns(address);

    function implementation() external returns(address);
}

/**
 * @title MintingModuleProxy - Proxy for the Minting Module
 */
contract MintingModuleProxy is MintingModuleStorage {

    constructor() {

        registry = SafeRegistry(IMintingModuleFactory(msg.sender).registry());
        collectionFactory = IMintingModuleFactory(msg.sender).collectionFactory();
        roleModule = RoleModule(IMintingModuleFactory(msg.sender).roleModule());

        _implementation = IMintingModuleFactory(msg.sender).implementation();
    }

    fallback() external payable {
		address _impl = implementation();
		assembly {
			let ptr := mload(0x40)
			calldatacopy(ptr, 0, calldatasize())
			let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
			let size := returndatasize()
			returndatacopy(ptr, 0, size)

			switch result
				case 0 {
					revert(ptr, size)
				}
				default {
					return(ptr, size)
				}
		}
	}

    /**
     * @notice  Returns the implementation of this proxy
     * @return  implementation_     Implementation address
     */
    function implementation() public view returns(address implementation_) {
        return _implementation;
    }

    receive() external payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RegistryStorage} from "contracts/storage/RegistryStorage.sol";
import {IMasterfileFactory} from "contracts/interfaces/IMasterfileFactory.sol";
import {MintingModuleFactory} from "contracts/factories/MintingModuleFactory.sol";

/**
 * @title SafeRegistry
 */
contract SafeRegistry is RegistryStorage {

    event FactoryAdded(bytes32 indexed name, uint256 version, address factory);
    event DeployerWhitelisted(address deployer);
    event RegistryUpdated(address implementation);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyFactory(bytes32 factoryType) {
        require(
            isFactory[factoryType][msg.sender],
            "Registry: Invalid Factory"
        );
        _;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Registry: caller is not the owner");
        _;
    }

    function owner() public view returns (address owner_) {
        return _owner;
    }

    /**
     * @notice Add array of factories in the Registry
     * @dev checks if factory already exists to prevent unintentional overwrite
     * @param names             Array of factory names
     * @param newFactories      Array of new factory address
     */
    function addFactory(bytes32[] memory names, address[] memory newFactories) public onlyOwner {
        require(names.length == newFactories.length, "Registry: Factory length mismatch");
        for(uint256 i; i < names.length; i++) {
            uint256 version = factories[names[i]].length + 1;
            
            factories[names[i]].push(newFactories[i]);
            isFactory[names[i]][newFactories[i]] = true;

            require(IMasterfileFactory(newFactories[i]).setVersion(version), "Registry: Set factory version failed");

            emit FactoryAdded(names[i], version, newFactories[i]);
        }
    }

    function getFactory(bytes32 name, uint256 version) public view returns(address factory) {
        address[] memory _factories = factories[name];
        if(_factories.length == 0) {
            return address(0);
        }
        return _factories[version - 1];
    }

    function getFactory(bytes32 name) public view returns(address factory) {
        address[] memory _factories = factories[name];
        if(_factories.length == 0) {
            return address(0);
        }
        return _factories[_factories.length - 1];
    }

    function latestFactoryVersion(bytes32 name) public view returns(uint256) {
        return factories[name].length;
    }

    /**
     * @notice Register contract deployment
     * @dev Contract type and factory identifier will be the same. i.e. keccak256(CHANNEL)
     * @param contractType  Type of deployment, e.g. keccak256(CHANNEL)
     * @param deployment    Contract address to register
     */
    function addDeployment(bytes32 contractType, address deployment) public onlyFactory(contractType) {
        isDeployment[contractType][deployment] = true;
    }

    /**
     * @notice Whitelists an address as a deployer
     * @param deployer Address to whitelist
     */
    function whitelistDeployer(address deployer) public onlyOwner {
        whitelisted[deployer] = true;

        emit DeployerWhitelisted(deployer);
    }

    function updateRegistryImplementation(address _registry) public onlyOwner {
        _safeRegistry = _registry;
        emit RegistryUpdated(_registry);
    }

    // Ownable functions
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Registry: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {RoleModule} from "contracts/modules/RoleModule.sol";
import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

/**
 * @title MintingModuleStorage
 */
contract MintingModuleStorage {
    address internal _implementation;
    address public collectionFactory;
    SafeRegistry internal registry;
    RoleModule internal roleModule;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @notice RegistryStorage
 */
contract RegistryStorage {
    address internal _safeRegistry;
    address internal _owner;
    address public masterfile;
    mapping(address  => bool) public whitelisted;
    mapping(bytes32 => mapping(address => bool)) public isDeployment;
    mapping(bytes32 => address[]) internal factories;
    mapping(bytes32 => mapping(address => bool)) public isFactory;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeRegistry} from "contracts/registry/SafeRegistry.sol";

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

/**
 * @title RoleModuleStorage
 */
contract RoleModuleStorage {
    address internal _implementation;
    bool internal _initialized;
    SafeRegistry internal registry;
    mapping(bytes32 => RoleData) internal _roles;
    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;
}