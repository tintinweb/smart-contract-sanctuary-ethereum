// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import "./libraries/ValidatorLibrary.sol";

import "./interfaces/IOrdererV2.sol";
import "./interfaces/IPhutureJob.sol";
import "./interfaces/IIndexRegistry.sol";
import "./interfaces/external/IKeep3r.sol";

/// @title Phuture job
/// @notice Contains signature verification and order execution logic
contract PhutureJob is IPhutureJob, Pausable {
    using ERC165Checker for address;
    using Counters for Counters.Counter;
    using ValidatorLibrary for ValidatorLibrary.Sign;

    /// @notice Validator role
    bytes32 internal immutable VALIDATOR_ROLE;
    /// @notice Order executor role
    bytes32 internal immutable ORDER_EXECUTOR_ROLE;
    /// @notice Role allows configure ordering related data/components
    bytes32 internal immutable ORDERING_MANAGER_ROLE;

    /// @notice Nonce
    Counters.Counter internal _nonce;

    address public immutable override keep3r;
    /// @inheritdoc IPhutureJob
    address public immutable override registry;

    /// @inheritdoc IPhutureJob
    uint256 public override minAmountOfSigners = 1;

    /// @notice Checks if msg.sender has the given role's permission
    modifier onlyRole(bytes32 role) {
        require(IAccessControl(registry).hasRole(role, msg.sender), "PhutureJob: FORBIDDEN");
        _;
    }

    /// @notice Pays keeper for work
    modifier payKeeper(address _keeper) {
        require(IKeep3r(keep3r).isKeeper(_keeper), "PhutureJob: !KEEP3R");
        _;
        IKeep3r(keep3r).worked(_keeper);
    }

    constructor(address _keep3r, address _registry) {
        bytes4[] memory interfaceIds = new bytes4[](2);
        interfaceIds[0] = type(IAccessControl).interfaceId;
        interfaceIds[1] = type(IIndexRegistry).interfaceId;
        require(_registry.supportsAllInterfaces(interfaceIds), "PhutureJob: INTERFACE");

        VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
        ORDER_EXECUTOR_ROLE = keccak256("ORDER_EXECUTOR_ROLE");
        ORDERING_MANAGER_ROLE = keccak256("ORDERING_MANAGER_ROLE");

        keep3r = _keep3r;
        registry = _registry;

        _pause();
    }

    /// @inheritdoc IPhutureJob
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external override onlyRole(ORDERING_MANAGER_ROLE) {
        require(_minAmountOfSigners != 0, "PhutureJob: INVALID");

        minAmountOfSigners = _minAmountOfSigners;
    }

    /// @inheritdoc IPhutureJob
    function pause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _pause();
    }

    /// @inheritdoc IPhutureJob
    function unpause() external override onlyRole(ORDERING_MANAGER_ROLE) {
        _unpause();
    }

    /// @inheritdoc IPhutureJob
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
        whenNotPaused
        payKeeper(msg.sender)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
        whenNotPaused
        payKeeper(msg.sender)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function internalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.internalSwap.selector, _info));
        orderer.internalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function externalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external
        override
        onlyRole(ORDER_EXECUTOR_ROLE)
    {
        IOrdererV2 orderer = IOrdererV2(IIndexRegistry(registry).orderer());
        _validate(_signs, abi.encodeWithSelector(orderer.externalSwap.selector, _info));
        orderer.externalSwap(_info);
    }

    /// @inheritdoc IPhutureJob
    function nonce() external view override returns (uint256) {
        return _nonce.current();
    }

    /// @notice Verifies that list of signatures provided by validator have signed given `_data` object
    /// @param _signs List of signatures
    /// @param _data Data object to verify signature
    function _validate(ValidatorLibrary.Sign[] calldata _signs, bytes memory _data) internal {
        uint signsCount = _signs.length;
        require(signsCount >= minAmountOfSigners, "PhutureJob: !ENOUGH_SIGNERS");

        address lastAddress = address(0);
        for (uint i; i < signsCount; ) {
            address signer = _signs[i].signer;
            require(uint160(signer) > uint160(lastAddress), "PhutureJob: UNSORTED");
            require(
                _signs[i].verify(_data, _useNonce()) && IAccessControl(registry).hasRole(VALIDATOR_ROLE, signer),
                string.concat("PhutureJob: SIGN ", Strings.toHexString(uint160(signer), 20))
            );

            lastAddress = signer;

            unchecked {
                i = i + 1;
            }
        }
    }

    /// @notice Return the current value of nonce and increment
    /// @return current Current nonce of signer
    function _useNonce() internal virtual returns (uint256 current) {
        current = _nonce.current();
        _nonce.increment();
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
        emit Paused(_msgSender());
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
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.8.13;

/// @title Validator library
/// @notice Library containing set of utilities related to Phuture job validation
library ValidatorLibrary {
    struct Sign {
        uint8 v;
        bytes32 r;
        bytes32 s;
        address signer;
        uint deadline;
    }

    /// @notice Verifies if the given `_data` object was signed by proper signer
    /// @param self Sign object reference
    /// @param _data Data object to verify signature
    function verify(
        Sign calldata self,
        bytes memory _data,
        uint _nonce
    ) internal view returns (bool) {
        require(block.timestamp <= self.deadline, "ValidatorLibrary: EXPIRED");

        bytes32 eip712DomainHash = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,uint256 nonce,uint256 deadline)"
                ),
                keccak256(bytes("PhutureJob")),
                keccak256(bytes("1")),
                block.chainid,
                address(this),
                _nonce,
                self.deadline
            )
        );

        return
            self.signer ==
            ecrecover(
                keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, keccak256(_data))),
                self.v,
                self.r,
                self.s
            );
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Orderer interface
/// @notice Describes methods for reweigh execution, order creation and execution
interface IOrdererV2 {
    struct InternalSwapV2 {
        address sellAccount;
        address buyAccount;
        address sellAsset;
        address buyAsset;
        uint maxSellShares;
    }

    struct ExternalSwapV2 {
        address account;
        address sellAsset;
        address buyAsset;
        uint sellShares;
        address swapTarget;
        bytes swapData;
    }

    /// @notice Initializes orderer with the given params (overrides IOrderer's initialize)
    /// @param _registry Index registry address
    /// @param _orderLifetime Order lifetime in which it stays valid
    /// @param _maxSlippageInBP Max slippage in BP
    function initialize(
        address _registry,
        uint64 _orderLifetime,
        uint16 _maxSlippageInBP
    ) external;

    /// @notice Sets max allowed slippage
    /// @param _maxSlippageInBP Max allowed slippage
    function setMaxSlippageInBP(uint16 _maxSlippageInBP) external;

    /// @notice Swap shares between given indexes
    /// @param _info Swap info objects with exchange details
    function internalSwap(InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _info Swap info objects with exchange details
    function externalSwap(ExternalSwapV2 calldata _info) external;

    /// @notice Max allowed exchange price impact
    /// @return Returns max allowed exchange price impact
    function maxSlippageInBP() external view returns (uint16);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "../libraries/ValidatorLibrary.sol";

import "./IOrdererV2.sol";

/// @title Phuture job interface
/// @notice Contains signature verification and order execution logic
interface IPhutureJob {
    /// @notice Pause order execution
    function pause() external;

    /// @notice Unpause order execution
    function unpause() external;

    /// @notice Sets minimum amount of signers required to sign a job
    /// @param _minAmountOfSigners Minimum amount of signers required to sign a job
    function setMinAmountOfSigners(uint256 _minAmountOfSigners) external;

    /// @notice Swap shares internally
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info) external;

    /// @notice Swap shares using DEX
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwap(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info) external;

    /// @notice Swap shares internally (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function internalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.InternalSwapV2 calldata _info)
        external;

    /// @notice Swap shares using DEX (manual)
    /// @param _signs List of signatures
    /// @param _info Swap info object
    function externalSwapManual(ValidatorLibrary.Sign[] calldata _signs, IOrdererV2.ExternalSwapV2 calldata _info)
        external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice Keep3r address
    /// @return Returns address of keep3r network
    function keep3r() external view returns (address);

    /// @notice Nonce of signer
    /// @return Returns nonce of given signer
    function nonce() external view returns (uint256);

    /// @notice Minimum amount of signers required to sign a job
    /// @return Returns minimum amount of signers required to sign a job
    function minAmountOfSigners() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

import "./IIndexFactory.sol";

/// @title Index registry interface
/// @notice Contains core components, addresses and asset market capitalizations
interface IIndexRegistry {
    event SetIndexLogic(address indexed account, address indexLogic);
    event SetMaxComponents(address indexed account, uint maxComponents);
    event UpdateAsset(address indexed asset, uint marketCap);
    event SetOrderer(address indexed account, address orderer);
    event SetFeePool(address indexed account, address feePool);
    event SetPriceOracle(address indexed account, address priceOracle);

    /// @notice Initializes IndexRegistry with the given params
    /// @param _indexLogic Index logic address
    /// @param _maxComponents Maximum assets for an index
    function initialize(address _indexLogic, uint _maxComponents) external;

    /// @notice Sets maximum assets for an index
    /// @param _maxComponents Maximum assets for an index
    function setMaxComponents(uint _maxComponents) external;

    /// @notice Index logic address
    /// @return Returns index logic address
    function indexLogic() external returns (address);

    /// @notice Sets index logic address
    /// @param _indexLogic Index logic address
    function setIndexLogic(address _indexLogic) external;

    /// @notice Sets adminRole as role's admin role.
    /// @param _role Role
    /// @param _adminRole AdminRole of given role
    function setRoleAdmin(bytes32 _role, bytes32 _adminRole) external;

    /// @notice Registers new index
    /// @param _index Index address
    /// @param _nameDetails Name details (name and symbol) for provided index
    function registerIndex(address _index, IIndexFactory.NameDetails calldata _nameDetails) external;

    /// @notice Registers asset in the system, updates it's market capitalization and assigns required roles
    /// @param _asset Asset to register
    /// @param _marketCap It's current market capitalization
    function addAsset(address _asset, uint _marketCap) external;

    /// @notice Removes assets from the system
    /// @param _asset Asset to remove
    function removeAsset(address _asset) external;

    /// @notice Updates market capitalization for the given asset
    /// @param _asset Asset address to update market capitalization for
    /// @param _marketCap Market capitalization value
    function updateAssetMarketCap(address _asset, uint _marketCap) external;

    /// @notice Sets price oracle address
    /// @param _priceOracle Price oracle address
    function setPriceOracle(address _priceOracle) external;

    /// @notice Sets orderer address
    /// @param _orderer Orderer address
    function setOrderer(address _orderer) external;

    /// @notice Sets fee pool address
    /// @param _feePool Fee pool address
    function setFeePool(address _feePool) external;

    /// @notice Maximum assets for an index
    /// @return Returns maximum assets for an index
    function maxComponents() external view returns (uint);

    /// @notice Market capitalization of provided asset
    /// @return _asset Returns market capitalization of provided asset
    function marketCapOf(address _asset) external view returns (uint);

    /// @notice Returns total market capitalization of the given assets
    /// @param _assets Assets array to calculate market capitalization of
    /// @return _marketCaps Corresponding capitalizations of the given asset
    /// @return _totalMarketCap Total market capitalization of the given assets
    function marketCapsOf(address[] calldata _assets)
        external
        view
        returns (uint[] memory _marketCaps, uint _totalMarketCap);

    /// @notice Total market capitalization of all registered assets
    /// @return Returns total market capitalization of all registered assets
    function totalMarketCap() external view returns (uint);

    /// @notice Price oracle address
    /// @return Returns price oracle address
    function priceOracle() external view returns (address);

    /// @notice Orderer address
    /// @return Returns orderer address
    function orderer() external view returns (address);

    /// @notice Fee pool address
    /// @return Returns fee pool address
    function feePool() external view returns (address);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

interface IKeep3r {
    function isKeeper(address _keeper) external returns (bool _isKeeper);

    function worked(address _keeper) external;
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

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity >=0.8.13;

/// @title Index factory interface
/// @notice Contains logic for initial fee management for indexes which will be created by this factory
interface IIndexFactory {
    struct NameDetails {
        string name;
        string symbol;
    }

    event SetVTokenFactory(address vTokenFactory);
    event SetDefaultMintingFeeInBP(address indexed account, uint16 mintingFeeInBP);
    event SetDefaultBurningFeeInBP(address indexed account, uint16 burningFeeInBP);
    event SetDefaultAUMScaledPerSecondsRate(address indexed account, uint AUMScaledPerSecondsRate);

    /// @notice Sets default index minting fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _mintingFeeInBP New minting fee value
    function setDefaultMintingFeeInBP(uint16 _mintingFeeInBP) external;

    /// @notice Sets default index burning fee in base point (BP) format
    /// @dev Will be set in FeePool on index creation
    /// @param _burningFeeInBP New burning fee value
    function setDefaultBurningFeeInBP(uint16 _burningFeeInBP) external;

    /// @notice Sets reweighting logic address
    /// @param _reweightingLogic Reweighting logic address
    function setReweightingLogic(address _reweightingLogic) external;

    /// @notice Sets default AUM scaled per seconds rate that will be used for fee calculation
    /**
        @dev Will be set in FeePool on index creation.
        Effective management fee rate (annual, in percent, after dilution) is calculated by the given formula:
        fee = (rpow(scaledPerSecondRate, numberOfSeconds, 10*27) - 10**27) * totalSupply / 10**27, where:

        totalSupply - total index supply;
        numberOfSeconds - delta time for calculation period;
        scaledPerSecondRate - scaled rate, calculated off chain by the given formula:

        scaledPerSecondRate = ((1 + k) ** (1 / 365 days)) * AUMCalculationLibrary.RATE_SCALE_BASE, where:
        k = (aumFeeInBP / BP) / (1 - aumFeeInBP / BP);

        Note: rpow and RATE_SCALE_BASE are provided by AUMCalculationLibrary
        More info: https://docs.enzyme.finance/fee-formulas/management-fee

        After value calculated off chain, scaledPerSecondRate is set to setDefaultAUMScaledPerSecondsRate
    */
    /// @param _AUMScaledPerSecondsRate New AUM scaled per seconds rate
    function setDefaultAUMScaledPerSecondsRate(uint _AUMScaledPerSecondsRate) external;

    /// @notice Withdraw fee balance to fee pool for a given index
    /// @param _index Index to withdraw fee balance from
    function withdrawToFeePool(address _index) external;

    /// @notice Index registry address
    /// @return Returns index registry address
    function registry() external view returns (address);

    /// @notice vTokenFactory address
    /// @return Returns vTokenFactory address
    function vTokenFactory() external view returns (address);

    /// @notice Minting fee in base point (BP) format
    /// @return Returns minting fee in base point (BP) format
    function defaultMintingFeeInBP() external view returns (uint16);

    /// @notice Burning fee in base point (BP) format
    /// @return Returns burning fee in base point (BP) format
    function defaultBurningFeeInBP() external view returns (uint16);

    /// @notice AUM scaled per seconds rate
    ///         See setDefaultAUMScaledPerSecondsRate method description for more details.
    /// @return Returns AUM scaled per seconds rate
    function defaultAUMScaledPerSecondsRate() external view returns (uint);

    /// @notice Reweighting logic address
    /// @return Returns reweighting logic address
    function reweightingLogic() external view returns (address);
}