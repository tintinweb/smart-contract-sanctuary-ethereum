//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./acl/OmniteAccessControl.sol";

contract AccessControlList is OmniteAccessControl {
    constructor(address admin) OmniteAccessControl() {
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(CONTROL_LIST_ADMIN_ROLE, admin);
        _setupRole(SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(TOKEN_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(FEE_COLLECTOR_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ACCESS_CONTROL_ROLE, address(this));
        _setupRole(BRIDGE_ROLE, address(this));
        _setupRole(BRIDGE_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(FACETS_REGISTRY_EDITOR_DEFAULT_ADMIN_ROLE, admin);
        _setupRole(FACETS_REGISTRY_EDITOR_ROLE, admin);

        // CONTROL_LIST_ADMIN_ROLE is an admin of other administration roles
        _setRoleAdmin(
            SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE,
            CONTROL_LIST_ADMIN_ROLE
        );
        _setRoleAdmin(BRIDGE_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(
            COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE,
            CONTROL_LIST_ADMIN_ROLE
        );
        _setRoleAdmin(
            FEE_COLLECTOR_DEFAULT_ADMIN_ROLE,
            CONTROL_LIST_ADMIN_ROLE
        );
        _setRoleAdmin(TOKEN_UNLOCK_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(TOKEN_DEFAULT_ADMIN_ROLE, CONTROL_LIST_ADMIN_ROLE);
        _setRoleAdmin(SYSTEM_CONTEXT_ROLE, CONTROL_LIST_ADMIN_ROLE);

        // SYSTEM_CONTEXT_ROLE is an admin of other system contract roles
        _setRoleAdmin(BRIDGE_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(CONTRACT_FACTORY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(COLLECTION_REGISTRY_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(ACCESS_CONTROL_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(OWNER_VERIFIER_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(OMNITE_TOKEN_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(FEE_COLLECTOR_ROLE, SYSTEM_CONTEXT_ROLE);
        _setRoleAdmin(
            FACETS_REGISTRY_EDITOR_ROLE,
            FACETS_REGISTRY_EDITOR_DEFAULT_ADMIN_ROLE
        );

        // Contract factory is an admin of NATIVE_TOKEN_ROLE and NON_NATIVE_TOKEN_ROLE
        _setRoleAdmin(NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
        _setRoleAdmin(NON_NATIVE_TOKEN_ROLE, CONTRACT_FACTORY_ROLE);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/accessControlList/IAccessControlBytes.sol";
import "../utils/ContextBytes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/BytesLib.sol";

abstract contract OmniteAccessControl is
    IAccessControlBytes,
    ERC165,
    ContextBytes
{
    bytes32 public constant CONTROL_LIST_ADMIN_ROLE =
        keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE =
        keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE =
        keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant FEE_COLLECTOR_DEFAULT_ADMIN_ROLE =
        keccak256("FEE_COLLECTOR_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE =
        keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");
    bytes32 public constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
    bytes32 public constant TOKEN_DEFAULT_ADMIN_ROLE =
        keccak256("TOKEN_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE =
        keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE =
        keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE =
        keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE =
        keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE =
        keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant OMNITE_TOKEN_ROLE = keccak256("OMNITE_TOKEN_ROLE");

    bytes32 public constant FEE_COLLECTOR_ROLE =
        keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE =
        keccak256("NON_NATIVE_TOKEN_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    bytes32 public constant FACETS_REGISTRY_EDITOR_DEFAULT_ADMIN_ROLE =
        keccak256("FACETS_REGISTRY_EDITOR_ROLE");

    struct RoleData {
        mapping(bytes => bool) members;
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
        _checkRole(role, _msgSenderBytes());
        _;
    }

    function checkRole(bytes32 role, address account)
        external
        view
        virtual
        override
    {
        return _checkRole(role, toBytes(account));
    }

    function checkRoleBytes(bytes32 role, bytes memory account) external view {
        return _checkRole(role, account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return hasRoleBytes(role, toBytes(account));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, bytes memory account) internal view {
        if (!hasRoleBytes(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "OmniteAccessControl: account ",
                        toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function toHexString(bytes memory account)
        internal
        pure
        returns (string memory)
    {
        if (account.length == 20) {
            // all eth based addresses
            return
                Strings.toHexString(
                    uint256(uint160(BytesLib.toAddress(account, 0)))
                );
        } else if (account.length <= 32) {
            // most of other addresses if not all of them
            return Strings.toHexString(uint256(BytesLib.toBytes32(account, 0)));
        }
        return string(account); // not supported, just return raw bytes (shouldn't happen)
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRoleBytes(role, account);
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from bytes `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRoleBytes(role, account);
    }

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        // solhint-disable-next-line reason-string
        require(
            keccak256(toBytes(account)) == keccak256(_msgSenderBytes()),
            "OmniteAccessControl: can only renounce roles for self"
        );

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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _grantRoleBytes(bytes32 role, bytes memory account) private {
        if (!hasRoleBytes(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGrantedBytes(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRoleBytes(bytes32 role, bytes memory account) private {
        if (hasRoleBytes(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevokedBytes(role, account, _msgSender());
        }
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, addr);
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, addr);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        external
        onlyRole(CONTROL_LIST_ADMIN_ROLE)
    {
        _setRoleAdmin(role, adminRole);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/IAccessControl.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlBytes is IAccessControl {
    /**
     * @dev Emitted when bytes `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGrantedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when bytes `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevokedBytes(
        bytes32 indexed role,
        bytes indexed account,
        address indexed sender
    );

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        external
        view
        returns (bool);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account) external;

    function checkRole(bytes32 role, address account) external view;
}

//SPDX-License-Identifier: Business Source License 1.1

import "@openzeppelin/contracts/utils/Context.sol";

pragma solidity ^0.8.9;

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
contract ContextBytes is Context {
    function _msgSenderBytes() internal view virtual returns (bytes memory) {
        return abi.encodePacked(msg.sender);
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

// SPDX-License-Identifier: Unlicense

pragma solidity >=0.8.0 <0.9.0;

library BytesLib {
    function concat(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bytes memory)
    {
        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Store the length of the first bytes array at the beginning of
            // the memory for tempBytes.
            let length := mload(_preBytes)
            mstore(tempBytes, length)

            // Maintain a memory counter for the current write location in the
            // temp bytes array by adding the 32 bytes for the array length to
            // the starting location.
            let mc := add(tempBytes, 0x20)
            // Stop copying when the memory counter reaches the length of the
            // first bytes array.
            let end := add(mc, length)

            for {
                // Initialize a copy counter to the start of the _preBytes data,
                // 32 bytes into its memory.
                let cc := add(_preBytes, 0x20)
            } lt(mc, end) {
                // Increase both counters by 32 bytes each iteration.
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                // Write the _preBytes data into the tempBytes memory 32 bytes
                // at a time.
                mstore(mc, mload(cc))
            }

            // Add the length of _postBytes to the current length of tempBytes
            // and store it as the new length in the first 32 bytes of the
            // tempBytes memory.
            length := mload(_postBytes)
            mstore(tempBytes, add(length, mload(tempBytes)))

            // Move the memory counter back from a multiple of 0x20 to the
            // actual end of the _preBytes data.
            mc := end
            // Stop copying when the memory counter reaches the new combined
            // length of the arrays.
            end := add(mc, length)

            for {
                let cc := add(_postBytes, 0x20)
            } lt(mc, end) {
                mc := add(mc, 0x20)
                cc := add(cc, 0x20)
            } {
                mstore(mc, mload(cc))
            }

            // Update the free-memory pointer by padding our last write location
            // to 32 bytes: add 31 bytes to the end of tempBytes to move to the
            // next 32 byte block, then round down to the nearest multiple of
            // 32. If the sum of the length of the two arrays is zero then add
            // one before rounding down to leave a blank 32 bytes (the length block with 0).
            mstore(
                0x40,
                and(
                    add(add(end, iszero(add(length, mload(_preBytes)))), 31),
                    not(31) // Round down to the nearest 32 bytes.
                )
            )
        }

        return tempBytes;
    }

    function concatStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Read the first 32 bytes of _preBytes storage, which is the length
            // of the array. (We don't need to use the offset into the slot
            // because arrays use the entire slot.)
            let fslot := sload(_preBytes.slot)
            // Arrays of 31 bytes or less have an even value in their slot,
            // while longer arrays have an odd value. The actual length is
            // the slot divided by two for odd values, and the lowest order
            // byte divided by two for even values.
            // If the slot is even, bitwise and the slot with 255 and divide by
            // two to get the length. If the slot is odd, bitwise and the slot
            // with -1 and divide by two.
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)
            let newlength := add(slength, mlength)
            // slength can contain both the length and contents of the array
            // if length < 32 bytes so let's prepare for that
            // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
            switch add(lt(slength, 32), lt(newlength, 32))
            case 2 {
                // Since the new array still fits in the slot, we just need to
                // update the contents of the slot.
                // uint256(bytes_storage) = uint256(bytes_storage) + uint256(bytes_memory) + new_length
                sstore(
                    _preBytes.slot,
                    // all the modifications to the slot are inside this
                    // next block
                    add(
                        // we can just add to the slot contents because the
                        // bytes we want to change are the LSBs
                        fslot,
                        add(
                            mul(
                                div(
                                    // load the bytes from memory
                                    mload(add(_postBytes, 0x20)),
                                    // zero all bytes to the right
                                    exp(0x100, sub(32, mlength))
                                ),
                                // and now shift left the number of bytes to
                                // leave space for the length in the slot
                                exp(0x100, sub(32, newlength))
                            ),
                            // increase length by the double of the memory
                            // bytes length
                            mul(mlength, 2)
                        )
                    )
                )
            }
            case 1 {
                // The stored value fits in the slot, but the combined value
                // will exceed it.
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // The contents of the _postBytes array start 32 bytes into
                // the structure. Our first read should obtain the `submod`
                // bytes that can fit into the unused space in the last word
                // of the stored array. To get this, we read 32 bytes starting
                // from `submod`, so the data we read overlaps with the array
                // contents by `submod` bytes. Masking the lowest-order
                // `submod` bytes allows us to add that value directly to the
                // stored value.

                let submod := sub(32, slength)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(
                    sc,
                    add(
                        and(
                            fslot,
                            0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff00
                        ),
                        and(mload(mc), mask)
                    )
                )

                for {
                    mc := add(mc, 0x20)
                    sc := add(sc, 1)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
            default {
                // get the keccak hash to get the contents of the array
                mstore(0x0, _preBytes.slot)
                // Start copying to the last used word of the stored array.
                let sc := add(keccak256(0x0, 0x20), div(slength, 32))

                // save new length
                sstore(_preBytes.slot, add(mul(newlength, 2), 1))

                // Copy over the first `submod` bytes of the new data as in
                // case 1 above.
                let slengthmod := mod(slength, 32)
                let mlengthmod := mod(mlength, 32)
                let submod := sub(32, slengthmod)
                let mc := add(_postBytes, submod)
                let end := add(_postBytes, mlength)
                let mask := sub(exp(0x100, submod), 1)

                sstore(sc, add(sload(sc), and(mload(mc), mask)))

                for {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } lt(mc, end) {
                    sc := add(sc, 1)
                    mc := add(mc, 0x20)
                } {
                    sstore(sc, mload(mc))
                }

                mask := exp(0x100, sub(mc, end))

                sstore(sc, mul(div(mload(mc), mask), mask))
            }
        }
    }

    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");

        bytes memory tempBytes;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(
                    add(tempBytes, lengthmod),
                    mul(0x20, iszero(lengthmod))
                )
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(
                        add(
                            add(_bytes, lengthmod),
                            mul(0x20, iszero(lengthmod))
                        ),
                        _start
                    )
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)
                //zero out the 32 bytes slice we are about to return
                //we need to do it because Solidity does not garbage collect
                mstore(tempBytes, 0)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }

    function toAddress(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (address)
    {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempAddress := div(
                mload(add(add(_bytes, 0x20), _start)),
                0x1000000000000000000000000
            )
        }

        return tempAddress;
    }

    function toUint8(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint8)
    {
        require(_bytes.length >= _start + 1, "toUint8_outOfBounds");
        uint8 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }

        return tempUint;
    }

    function toBool(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bool)
    {
        return toUint8(_bytes, _start) == 0;
    }

    function toUint16(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint16)
    {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }

    function toUint32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint32)
    {
        require(_bytes.length >= _start + 4, "toUint32_outOfBounds");
        uint32 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x4), _start))
        }

        return tempUint;
    }

    function toUint64(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint64)
    {
        require(_bytes.length >= _start + 8, "toUint64_outOfBounds");
        uint64 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x8), _start))
        }

        return tempUint;
    }

    function toUint96(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint96)
    {
        require(_bytes.length >= _start + 12, "toUint96_outOfBounds");
        uint96 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0xc), _start))
        }

        return tempUint;
    }

    function toUint128(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint128)
    {
        require(_bytes.length >= _start + 16, "toUint128_outOfBounds");
        uint128 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x10), _start))
        }

        return tempUint;
    }

    function toUint256(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (uint256)
    {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");
        uint256 tempUint;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempUint := mload(add(add(_bytes, 0x20), _start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory _bytes, uint256 _start)
        internal
        pure
        returns (bytes32)
    {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function equal(bytes memory _preBytes, bytes memory _postBytes)
        internal
        pure
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let length := mload(_preBytes)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(_postBytes))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(_preBytes, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(_postBytes, 0x20)
                    // the next line is the loop condition:
                    // while(uint256(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }

    function equalStorage(bytes storage _preBytes, bytes memory _postBytes)
        internal
        view
        returns (bool)
    {
        bool success = true;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // we know _preBytes_offset is 0
            let fslot := sload(_preBytes.slot)
            // Decode the length of the stored array like in concatStorage().
            let slength := div(
                and(fslot, sub(mul(0x100, iszero(and(fslot, 1))), 1)),
                2
            )
            let mlength := mload(_postBytes)

            // if lengths don't match the arrays are not equal
            switch eq(slength, mlength)
            case 1 {
                // slength can contain both the length and contents of the array
                // if length < 32 bytes so let's prepare for that
                // v. http://solidity.readthedocs.io/en/latest/miscellaneous.html#layout-of-state-variables-in-storage
                if iszero(iszero(slength)) {
                    switch lt(slength, 32)
                    case 1 {
                        // blank the last byte which is the length
                        fslot := mul(div(fslot, 0x100), 0x100)

                        if iszero(eq(fslot, mload(add(_postBytes, 0x20)))) {
                            // unsuccess:
                            success := 0
                        }
                    }
                    default {
                        // cb is a circuit breaker in the for loop since there's
                        //  no said feature for inline assembly loops
                        // cb = 1 - don't breaker
                        // cb = 0 - break
                        let cb := 1

                        // get the keccak hash to get the contents of the array
                        mstore(0x0, _preBytes.slot)
                        let sc := keccak256(0x0, 0x20)

                        let mc := add(_postBytes, 0x20)
                        let end := add(mc, mlength)

                        // the next line is the loop condition:
                        // while(uint256(mc < end) + cb == 2)
                        // solhint-disable-next-line no-empty-blocks
                        for {

                        } eq(add(lt(mc, end), cb), 2) {
                            sc := add(sc, 1)
                            mc := add(mc, 0x20)
                        } {
                            if iszero(eq(sload(sc), mload(mc))) {
                                // unsuccess:
                                success := 0
                                cb := 0
                            }
                        }
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
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

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../libraries/diamond/LibMeta.sol";
import "../../../../interfaces/diamond/ERC721/IERC721MintableFacet.sol";
import "../../common/libraries/LibERC721.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../../../../acl/OmniteAccessControl.sol";
import "../../common/libraries/LibAccessControlList.sol";

contract ERC721NonNativeMintableFacet is IERC721MintableFacet {
    AppStorage internal s;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function mintTo(address to, uint256 tokenId) public virtual override {
        address sender = LibMeta.msgSender();
        OmniteAccessControl oac = ISystemContext(s.systemContextAddress)
            .omniteAccessControl();
        if (oac.hasRole(oac.BRIDGE_ROLE(), sender)) {
            if (
                LibERC721.isOwner(s.diamondAddress, s.diamondAddress, tokenId)
            ) {
                LibERC721.transferFrom(
                    s.diamondAddress,
                    address(this),
                    to,
                    tokenId
                );
            } else {
                _mint(s.diamondAddress, to, tokenId);
            }
        } else {
            _validateMintForNonBridgeCaller(sender);
            _mint(s.diamondAddress, to, tokenId);
        }
    }

    function _validateMintForNonBridgeCaller(address sender) internal view {
        LibAccessControlList.checkRole(
            s.diamondAddress,
            keccak256("MINTER_ROLE"),
            sender
        );
    }

    function _mint(
        address tokenAddr,
        address to,
        uint256 tokenId
    ) internal {
        address sender = LibMeta.msgSender();
        LibERC721.isApprovedOrOwner(tokenAddr, sender, tokenId);

        address owner = s.erc721Base.owners[tokenId];
        // Clear approvals
        LibERC721.approve(tokenAddr, address(0), tokenId);

        s.erc721Base.balances[owner] += 1;
        delete s.erc721Base.owners[tokenId];

        emit Transfer(address(0), to, tokenId);
    }

    function mintToWithUri(
        address to,
        uint256 tokenId,
        string memory tokenUri
    ) external virtual override {
        mintTo(to, tokenId);
        s.erc721Base.tokenURIs[tokenId] = tokenUri;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import {ERC721Storage} from "../common/storage/ERC721Base.sol";
import {RoleData, DEFAULT_ADMIN_ROLE, ACLStorage} from "../common/storage/AccessControl.sol";

pragma solidity ^0.8.9;

bytes32 constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
bytes32 constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");

struct AppStorage {
    bool initialized;
    address diamondAddress;
    address systemContextAddress;
    string contractURIOptional;
    ERC721Storage erc721Base;
    ACLStorage acl;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721MintableFacet {
    function mintTo(address to, uint256 tokenId) external;

    function mintToWithUri(
        address to,
        uint256 tokenId,
        string memory tokenUri
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/ERC721/IERC721Facet.sol";
import "../../../../libraries/BytesLib.sol";

library LibERC721 {
    modifier ensureIsContract(address tokenAddr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(tokenAddr)
        }

        require(size > 0, "LibERC721: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                revert("LibERC721 silent error");
            }
        }
    }

    function transferFrom(
        address tokenAddr,
        address from,
        address to,
        uint256 value
    ) internal ensureIsContract(tokenAddr) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.call(
            abi.encodeWithSelector(
                IERC721Facet.transferFrom.selector,
                from,
                to,
                value
            )
        );
        handleTransferReturn(success, result);
    }

    function ownerOf(address tokenAddr, uint256 tokenId_)
        public
        view
        ensureIsContract(tokenAddr)
        returns (address addr)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.staticcall(
            abi.encodeWithSelector(IERC721Facet.ownerOf.selector, tokenId_)
        );

        requireSuccess(success, result);
        return BytesLib.toAddress(result, 0);
    }

    function isOwner(
        address tokenAddr,
        address _address,
        uint256 _tokenId
    ) internal view ensureIsContract(tokenAddr) returns (bool) {
        return ownerOf(tokenAddr, _tokenId) == _address;
    }

    function approve(
        address tokenAddr,
        address to,
        uint256 tokenId
    ) internal ensureIsContract(tokenAddr) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.call(
            abi.encodeWithSelector(IERC721Facet.approve.selector, to, tokenId)
        );

        requireSuccess(success, result);
    }

    function isApprovedOrOwner(
        address tokenAddr,
        address owner,
        uint256 tokenId
    )
        internal
        view
        ensureIsContract(tokenAddr)
        returns (bool _isApprovedOrOwner)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.staticcall(
            abi.encodeWithSelector(
                IERC721Facet.isApprovedOrOwner.selector,
                owner,
                tokenId
            )
        );

        requireSuccess(success, result);
        return BytesLib.toBool(result, 0);
    }

    function name(address tokenAddr)
        internal
        view
        ensureIsContract(tokenAddr)
        returns (string memory)
    {
        (bool success, bytes memory result) = tokenAddr.staticcall(
            abi.encodeWithSelector(IERC721Facet.name.selector)
        );

        requireSuccess(success, result);
        return abi.decode(result, (string));
    }

    function exists(address tokenAddr, uint256 tokenId)
        internal
        view
        ensureIsContract(tokenAddr)
        returns (bool)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.staticcall(
            abi.encodeWithSelector(IERC721Facet.exists.selector, tokenId)
        );

        requireSuccess(success, result);
        return BytesLib.toBool(result, 0);
    }

    // solhint-disable-next-line avoid-low-level-calls
    function handleTransferReturn(bool _success, bytes memory _result)
        internal
        pure
    {
        if (_success) {
            if (_result.length > 0) {
                // solhint-disable-next-line reason-string
                require(
                    abi.decode(_result, (bool)),
                    "LibERC721: contract call returned false"
                );
            }
        } else {
            if (_result.length > 0) {
                // bubble up any reason for revert
                revert(abi.decode(_result, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibERC721: contract call reverted");
            }
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../acl/OmniteAccessControl.sol";

interface ISystemContext {
    event ContractRegistered(string indexed name, address addr);
    event ContractUpdated(
        string indexed name,
        address lastAddr,
        address newAddr
    );
    event ContractRemoved(string indexed name);

    error ContractAlreadyRegistered(string name, address addr);
    error ContractNotRegistered(string name);

    function getContractAddress(string calldata _contractName)
        external
        view
        returns (address);

    function registerContract(string calldata _contractName, address _addr)
        external;

    function overrideContract(string calldata _contractName, address _addr)
        external;

    function removeContract(string calldata _contractName) external;

    function contractRegistered(string calldata _contractName)
        external
        returns (bool);

    function setAccessControlList(OmniteAccessControl accessControlList_)
        external;

    function contractUriBase() external view returns (string memory);

    function chainId() external view returns (uint16);

    function chainName() external view returns (string memory);

    function omniteAccessControl() external returns (OmniteAccessControl);

    function multisigWallet() external returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/IAccessControlListFacet.sol";
import "../../../../libraries/BytesLib.sol";

library LibAccessControlList {
    modifier ensureIsContract(address addr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(addr)
        }

        require(size > 0, "LibERC721: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibAccessControlList: invokings error");
            }
        }
    }

    function hasRole(
        address aclAddress,
        bytes32 role,
        address account
    ) internal view ensureIsContract(aclAddress) returns (bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.staticcall(
            abi.encodeWithSelector(
                IAccessControlListFacet.hasRole.selector,
                role,
                account
            )
        );

        requireSuccess(success, result);
        return BytesLib.toBool(result, 0);
    }

    function getRoleAdmin(address aclAddress, bytes32 role)
        internal
        view
        ensureIsContract(aclAddress)
        returns (bytes32)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.staticcall(
            abi.encodeWithSelector(
                IAccessControlListFacet.getRoleAdmin.selector,
                role
            )
        );

        requireSuccess(success, result);
        return BytesLib.toBytes32(result, 0);
    }

    function grantRole(
        address aclAddress,
        bytes32 role,
        address account
    ) internal ensureIsContract(aclAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.delegatecall(
            abi.encodeWithSelector(
                IAccessControlListFacet.grantRole.selector,
                role,
                account
            )
        );

        requireSuccess(success, result);
    }

    function checkRole(
        address aclAddress,
        bytes32 role,
        address account
    ) internal view ensureIsContract(aclAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.staticcall(
            abi.encodeWithSelector(
                IAccessControlListFacet.checkRole.selector,
                role,
                account
            )
        );

        requireSuccess(success, result);
    }

    function revokeRole(
        address aclAddress,
        bytes32 role,
        address account
    ) internal ensureIsContract(aclAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.delegatecall(
            abi.encodeWithSelector(
                IAccessControlListFacet.grantRole.selector,
                role,
                account
            )
        );

        requireSuccess(success, result);
    }

    function renounceRole(
        address aclAddress,
        bytes32 role,
        address account
    ) internal ensureIsContract(aclAddress) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = aclAddress.delegatecall(
            abi.encodeWithSelector(
                IAccessControlListFacet.grantRole.selector,
                role,
                account
            )
        );

        requireSuccess(success, result);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

struct ERC721Storage {
    string name;
    string symbol;
    string baseURI;
    mapping(uint256 => address) owners;
    mapping(address => uint256) balances;
    mapping(uint256 => address) tokenApprovals;
    mapping(address => mapping(address => bool)) operatorApprovals;
    mapping(uint256 => string) tokenURIs;
    string contractURIOptional;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

struct RoleData {
    mapping(address => bool) members;
    bytes32 adminRole;
}

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;

struct ACLStorage {
    mapping(bytes32 => RoleData) roles;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721Facet {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function getApproved(uint256 tokenId_) external returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function isApprovedOrOwner() external returns (bool);

    function exists(uint256 tokenId) external returns (string memory);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IAccessControlListFacet {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool);

    function checkRole(bytes32 role, address account) external view;

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../libraries/diamond/LibMeta.sol";
import "../../common/libraries/LibAccessControlList.sol";
import "../../../../interfaces/diamond/ERC721/IERC721MintableFacet.sol";
import "../../common/libraries/LibERC721.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../../../../acl/OmniteAccessControl.sol";

contract ERC721NativeMintableFacet is IERC721MintableFacet {
    AppStorage internal s;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function mintTo(address to, uint256 tokenId) public virtual override {
        OmniteAccessControl oac = ISystemContext(s.systemContextAddress)
            .omniteAccessControl();
        address sender = LibMeta.msgSender();

        if (oac.hasRole(oac.BRIDGE_ROLE(), sender)) {
            if (
                LibERC721.isOwner(s.diamondAddress, s.diamondAddress, tokenId)
            ) {
                LibERC721.transferFrom(
                    s.diamondAddress,
                    s.diamondAddress,
                    to,
                    tokenId
                );
            } else {
                _mint(to, tokenId);
            }
        } else {
            _validateMintForNonBridgeCaller(sender, tokenId);
            _mint(to, tokenId);
        }
    }

    function _mint(address to, uint256 tokenId) internal {
        s.erc721Base.balances[to] += 1;
        s.erc721Base.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function mintToWithUri(
        address to,
        uint256 tokenId,
        string memory tokenUri
    ) external virtual override {
        mintTo(to, tokenId);
        if (bytes(s.baseTokenURI).length == 0) {
            require(bytes(tokenUri).length > 0, "tokenURI required.");
            // solhint-disable-next-line reason-string
            require(
                LibERC721.exists(s.diamondAddress, tokenId),
                "ERC721URIStorage: URI set of nonexistent token"
            );
            s.erc721Base.tokenURIs[tokenId] = tokenUri;
        }
    }

    function _validateMintForNonBridgeCaller(address sender, uint256 tokenId)
        internal
        view
    {
        LibAccessControlList.checkRole(
            s.diamondAddress,
            keccak256("MINTER_ROLE"),
            sender
        );

        require(
            s.slotsStart <= tokenId && tokenId <= s.slotsEnd,
            "Mint id outside of slot range"
        );
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import {ERC721Storage} from "../common/storage/ERC721Base.sol";
import {RoleData, DEFAULT_ADMIN_ROLE, ACLStorage} from "../common/storage/AccessControl.sol";

pragma solidity ^0.8.9;

struct AppStorage {
    bool initialized;
    address diamondAddress;
    address systemContextAddress;
    string contractURIOptional;
    ERC721Storage erc721Base;
    ACLStorage acl;
    uint256 slotsStart;
    uint256 slotsEnd;
    string baseTokenURI;
    string data;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../storage/AppStorage.sol";
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";
import "../../../../interfaces/diamond/ERC721/IERC721UnlockableFacet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../libraries/LibERC721.sol";

contract ERC721UnlockableFacet is IERC721UnlockableFacet {
    AppStorage internal s;

    function unlockToken(address _to, uint256 _tokenId)
        external
        virtual
        override
    {
        address sender = LibMeta.msgSender();
        OmniteAccessControl oac = ISystemContext(s.systemContextAddress)
            .omniteAccessControl();
        oac.checkRole(oac.TOKEN_UNLOCK_ROLE(), sender);

        require(
            LibERC721.isApprovedOrOwner(s.diamondAddress, sender, _tokenId),
            "Caller not owner nor approved"
        );

        LibERC721.transferFrom(s.diamondAddress, address(this), _to, _tokenId);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import {ERC721Storage} from "./ERC721Base.sol";
import {RoleData, DEFAULT_ADMIN_ROLE, ACLStorage} from "./AccessControl.sol";

pragma solidity ^0.8.9;

struct AppStorage {
    bool initialized;
    address diamondAddress;
    address systemContextAddress;
    string contractURIOptional;
    ERC721Storage erc721Base;
    ACLStorage acl;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721UnlockableFacet {
    function unlockToken(address _to, uint256 _tokenId) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../interfaces/diamond/ERC721/IERC721TokenURIFacet.sol";
import "../../common/libraries/LibERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721NonNativeTokenURIFacet is IERC721TokenURIFacet {
    AppStorage internal s;

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            LibERC721.exists(s.diamondAddress, tokenId),
            "URI query for nonexistent token"
        );
        return s.erc721Base.tokenURIs[tokenId];
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721TokenURIFacet {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../interfaces/diamond/ERC721/IERC721TokenURIFacet.sol";
import "../../common/libraries/LibERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721NativeTokenURIFacet is IERC721TokenURIFacet {
    AppStorage internal s;

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            LibERC721.exists(s.diamondAddress, tokenId),
            "URI query for nonexistent token"
        );
        if (bytes(s.baseTokenURI).length > 0) {
            return
                string(
                    abi.encodePacked(s.baseTokenURI, Strings.toString(tokenId))
                );
        } else return s.erc721Base.tokenURIs[tokenId];
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/ERC721/IERC721TokenURIFacet.sol";

library LibERC721TokenURI {
    modifier ensureIsContract(address tokenAddr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(tokenAddr)
        }

        require(size > 0, "LibERC721: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibERC721TokenURI: invoking error");
            }
        }
    }

    function tokenURI(address tokenAddress, uint256 tokenId)
        internal
        view
        ensureIsContract(tokenAddress)
        returns (string memory)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddress.staticcall(
            abi.encodeWithSelector(
                IERC721TokenURIFacet.tokenURI.selector,
                tokenId
            )
        );

        requireSuccess(success, result);
        return abi.decode(result, (string));
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";
import "../../../../interfaces/diamond/ERC721/IERC721LayerZeroBridgedableFacet.sol";
import "../storage/AppStorage.sol";
import "../libraries/LibERC721.sol";
import "../libraries/LibERC721TokenURI.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../../../../interfaces/layerzero/IOmniteLayerZeroBridgeSender.sol";

contract ERC721LayerZeroBridgedableFacet is IERC721LayerZeroBridgedableFacet {
    AppStorage internal s;

    function requireIsApprovedOrOwner(address addr, uint256 _tokenId)
        internal
        view
    {
        require(
            LibERC721.isApprovedOrOwner(s.diamondAddress, addr, _tokenId),
            "Caller not owner nor approved"
        );
    }

    function moveToViaLayerZero(
        uint16 _l0ChainId,
        bytes calldata _destinationBridge,
        uint256 _tokenId,
        uint256 _gasAmount
    ) external payable virtual override {
        address sender = LibMeta.msgSender();
        requireIsApprovedOrOwner(sender, _tokenId);

        LibERC721.transferFrom(
            s.diamondAddress,
            sender,
            address(this),
            _tokenId
        );

        IOmniteLayerZeroBridgeSender l0Sender = IOmniteLayerZeroBridgeSender(
            ISystemContext(s.systemContextAddress).getContractAddress(
                "OMNITE_LAYER_ZERO_BRIDGE_SENDER"
            )
        );

        l0Sender.mintOnTargetChain{value: msg.value}(
            _l0ChainId,
            _destinationBridge,
            sender,
            sender,
            _tokenId,
            LibERC721TokenURI.tokenURI(s.diamondAddress, _tokenId),
            _gasAmount
        );
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721LayerZeroBridgedableFacet {
    function moveToViaLayerZero(
        uint16 _l0ChainId,
        bytes calldata _destinationBridge,
        uint256 _tokenId,
        uint256 _gasAmount
    ) external payable;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./IOmniteLayerZeroBridge.sol";
import "./ILayerZeroEndpoint.sol";
import "./ILayerZeroReceiver.sol";

interface IOmniteLayerZeroBridgeSender is IOmniteLayerZeroBridge {
    struct SendMessageWithValueParams {
        uint16 chainId;
        bytes bridge;
        bytes buffer;
        address refundAddress;
        uint256 value;
        uint256 gasAmount;
    }

    struct DeployExternalParams {
        address originalCollection;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_) external;

    function setMinGas(uint256 minGas_) external;

    function setMaxNetworks(uint64 maxNetworks_) external;

    function mintOnTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) external returns (bytes memory);

    function mintOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) external payable;

    function callOnTargetChainEncode(
        bytes32 collectionId_,
        bytes calldata callData_
    ) external returns (bytes memory);

    function callOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        bytes32 collectionId_,
        address refundAddress_,
        bytes calldata callData_,
        uint256 gasAmount_
    ) external payable;

    function deployTokenContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        string calldata collectionName_,
        address owner_
    ) external returns (bytes memory);

    function deployCrowdsaleContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        address owner_,
        GrantRoleParams calldata grantRoleParams_
    ) external returns (bytes memory);

    function deployExternalCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../IBridge.sol";

interface IOmniteLayerZeroBridge is IBridge {
    event SendEvent(uint16 destChainId, bytes destBridge, uint64 nonce);
    event ReceiveEvent(
        uint16 chainId,
        bytes fromAddress,
        uint64 nonce,
        Operation operation
    );
    event CallSuccess(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address calledContract,
        bytes returnData,
        uint16 index
    );
    event CallFailed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address calledContract,
        uint16 index,
        string error
    );
    event ContractDeployed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        address newContract
    );
    event ContractNotDeployed(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        string error
    );
    event UndefinedCall(
        uint16 indexed chainId,
        bytes indexed fromAddress,
        uint64 indexed nonce,
        Operation operation,
        uint256 apiVersion,
        bytes rawData
    );

    struct DeploymentParams {
        uint16 chainId;
        bytes bridgeAddress;
        uint256 value;
        bytes ctorParams;
        address originalContractAddress;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ILayerZeroEndpoint {
    // the send() method which sends a bytes payload to a another chain
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable refundAddress,
        address _zroPaymentAddress,
        bytes calldata txParameters
    ) external payable;

    function estimateFees(
        uint16 chainId,
        address userApplication,
        bytes calldata payload,
        bool payInZRO,
        bytes calldata adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function getInboundNonce(uint16 _chainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    function getOutboundNonce(uint16 _chainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ILayerZeroReceiver {
    // the method which your contract needs to implement to receive messages
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IBridge {
    enum Operation {
        CALL,
        DEPLOY_TOKEN,
        DEPLOY_CROWDSALE,
        MULTI_CALL,
        ERC721_BRIDGE
    }

    struct Data {
        Operation operation;
        uint256 apiVersion;
        bytes rawData;
    }

    struct CallData {
        bytes32 collectionId;
        bytes packedData;
    }

    struct MultiCallData {
        address[] destinationContracts;
        bytes[] packedData;
    }

    struct DeployTokenData {
        string blueprintName;
        bytes ctorParams;
        bytes32 collectionId;
        string collectionName;
        address owner;
    }

    struct DeployCrowdsaleData {
        string blueprintName;
        bytes ctorParams;
        bytes32 collectionId;
        address owner;
        GrantRoleParams grantRoleParams;
    }

    struct GrantRoleParams {
        bytes grantRoleWithSignature;
        address roleReceiver;
        bytes32 role;
        uint256 signedAt;
        address signer;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/layerzero/ILayerZeroReceiver.sol";
import "./interfaces/layerzero/ILayerZeroEndpoint.sol";
import "./interfaces/layerzero/IOmniteLayerZeroBridgeSender.sol";
import "./interfaces/ISystemContext.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/INonNativeWrapperInitializable.sol";
import "./interfaces/IFeeCollector.sol";
import "./interfaces/IGrantRoleWithSignature.sol";
import "./interfaces/token/ITokenBridgeable.sol";
import "./interfaces/IInitializable.sol";

contract OmniteLayerZeroBridgeSender is IOmniteLayerZeroBridgeSender {
    using Address for address;

    uint64 public constant MAX_URL_LEN = 512;
    uint64 public constant MAX_CALL_DATA_LEN = 8096;
    uint64 public maxNetworks = 16;

    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;
    ISystemContext public immutable systemContext;

    uint256 public apiVersion;
    uint256 public minGas;

    string public constant ERC721_NON_NATIVE_BLUEPRINT_NAME = "ERC721NonNative";
    string public constant ERC721_NATIVE_BLUEPRINT_NAME = "ERC721Native";
    string public constant ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME =
        "NonNativeWrapper";
    string public constant CROWDSALE_BLUEPRINT_NAME = "SimpleNftCrowdsale";

    struct DeployNativeParams {
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    constructor(ISystemContext systemContext_) {
        apiVersion = 0;
        systemContext = systemContext_;
        minGas = 100000;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        endpoint = endpoint_;
    }

    function setMinGas(uint256 minGas_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        minGas = minGas_;
    }

    function setMaxNetworks(uint64 maxNetworks_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        maxNetworks = maxNetworks_;
    }

    function _deployNonNativeWrapper(
        DeployExternalParams memory deployData,
        bytes32 collectionId
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        INonNativeWrapperInitializable wrapperBlueprint = INonNativeWrapperInitializable(
                factory.getLatestBlueprint(
                    ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME
                )
            );
        factory.createTokenInstanceByName(
            ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME,
            wrapperBlueprint.encodeInitializer(deployData.originalCollection),
            collectionId,
            deployData.collectionName,
            deployData.owner
        );
        factory.registerOriginalContract(
            collectionId,
            deployData.originalCollection
        );
    }

    function _sendMessageWithValue(SendMessageWithValueParams memory params_)
        internal
    //    nativePayment(params_.refundAddress, params_.value)
    {
        require(params_.gasAmount >= minGas, "Gas limit too little");
        // solhint-disable-next-line check-send-result
        endpoint.send{value: params_.value}(
            params_.chainId,
            params_.bridge,
            params_.buffer,
            payable(params_.refundAddress),
            address(this),
            abi.encodePacked(uint16(1), uint256(params_.gasAmount))
        );

        emit SendEvent(
            params_.chainId,
            params_.bridge,
            endpoint.getOutboundNonce(params_.chainId, address(this))
        );
    }

    modifier nativePayment(address refundAddress_, uint256 valueSent_) {
        IFeeCollector feeCollector = IFeeCollector(
            systemContext.getContractAddress("FEE_COLLECTOR")
        );
        uint256 currentAmount_ = feeCollector.nativeBalance();
        _;
        // check value after user payment
        uint256 diff_ = feeCollector.nativeBalance() - currentAmount_;

        feeCollector.applyFeeAndRefund(
            diff_,
            msg.value,
            payable(refundAddress_)
        );
    }

    function _sendMessage(
        uint16 chainId_,
        bytes calldata bridge_,
        bytes memory buffer_,
        address refundAddress_,
        uint256 gasAmount_
    ) internal {
        _sendMessageWithValue(
            SendMessageWithValueParams({
                chainId: chainId_,
                bridge: bridge_,
                buffer: buffer_,
                refundAddress: refundAddress_,
                value: msg.value,
                gasAmount: gasAmount_
            })
        );
    }

    function mintOnTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public view virtual override returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: abi.encodeWithSelector(
                                ITokenBridgeable.mintToWithUri.selector,
                                owner_,
                                mintId_,
                                tokenUri_
                            )
                        })
                    )
                })
            );
    }

    function mintOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        address refundAddress_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_,
        uint256 gasAmount_
    ) public payable virtual override {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        bytes32 collectionId_ = registry.collections(msg.sender);

        // solhint-disable-next-line reason-string
        require(
            collectionId_ != bytes32(0),
            "Only collection contract can call"
        );
        require(bytes(tokenUri_).length <= MAX_URL_LEN, "token uri to long");
        _sendMessage(
            chainId_,
            bridge_,
            mintOnTargetChainEncode(collectionId_, owner_, mintId_, tokenUri_),
            refundAddress_,
            gasAmount_
        );
    }

    function callOnTargetChainEncode(
        bytes32 collectionId_,
        bytes calldata callData_
    ) public view virtual override returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: callData_
                        })
                    )
                })
            );
    }

    function callOnTargetChain(
        uint16 chainId_,
        bytes calldata bridge_,
        bytes32 collectionId_,
        address refundAddress_,
        bytes calldata callData_,
        uint256 gasAmount_
    ) public payable virtual override {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        // solhint-disable-next-line reason-string

        require(
            registry.addressOf(collectionId_) == msg.sender,
            "Only collection contract can call"
        );
        require(callData_.length <= MAX_CALL_DATA_LEN, "calldata to long");
        _sendMessage(
            chainId_,
            bridge_,
            callOnTargetChainEncode(collectionId_, callData_),
            refundAddress_,
            gasAmount_
        );
    }

    function deployTokenContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        string calldata collectionName_,
        address owner_
    ) public view virtual override returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.DEPLOY_TOKEN,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        DeployTokenData({
                            blueprintName: blueprintName_,
                            ctorParams: ctorParams_,
                            collectionId: collectionId_,
                            collectionName: collectionName_,
                            owner: owner_
                        })
                    )
                })
            );
    }

    function deployCrowdsaleContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        address owner_,
        GrantRoleParams calldata grantRoleParams_
    ) public view virtual override returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.DEPLOY_TOKEN,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        DeployCrowdsaleData({
                            blueprintName: blueprintName_,
                            ctorParams: ctorParams_,
                            collectionId: collectionId_,
                            owner: owner_,
                            grantRoleParams: grantRoleParams_
                        })
                    )
                })
            );
    }

    function _deployExternalCollection(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );

        ERC721 orig = ERC721(params.originalCollection);
        bytes memory ctorParams = abi.encode( // TODO what to do with contractURI_???
            orig.name(),
            orig.symbol(),
            systemContext.multisigWallet()
        );

        ctorParams = abi.encodeWithSelector(
            IInitializable.initialize.selector,
            ctorParams
        );

        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow
            require(
                deploymentParams_[i].chainId != systemContext.chainId(),
                "Cannot deploy locally"
            );
            _sendMessageWithValue(
                SendMessageWithValueParams({
                    chainId: deploymentParams_[i].chainId,
                    bridge: deploymentParams_[i].bridgeAddress,
                    buffer: deployTokenContractEncode(
                        ERC721_NON_NATIVE_BLUEPRINT_NAME,
                        collectionId_,
                        ctorParams,
                        params.collectionName,
                        systemContext.multisigWallet()
                    ),
                    refundAddress: params.refundAddress,
                    value: deploymentParams_[i].value,
                    gasAmount: params.gasAmount
                })
            );
        }
    }

    function deployExternalCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        // solhint-disable not-rely-on-time
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );

        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        require(
            registry.externalToCollection(params.originalCollection) ==
                bytes32(0),
            "Collection already registered"
        );
        // solhint-disable-next-line reason-string
        require(
            IERC721(params.originalCollection).supportsInterface(
                type(IERC721).interfaceId
            ),
            "Original collection is not ERC721"
        );
        // solhint-disable-next-line reason-string
        require(
            IERC721(params.originalCollection).supportsInterface(
                type(IERC721Metadata).interfaceId
            ),
            "Original collection is not IERC721Metadata"
        );

        _deployNonNativeWrapper(params, collectionId_);

        _deployExternalCollection(collectionId_, deploymentParams_, params);
    }

    function deployExternalCollectionOnNewChains(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        ICollectionRegistry collectionRegistry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        require(
            collectionRegistry.externalToCollection(
                params.originalCollection
            ) == collectionId_,
            "Collection not registered yet"
        );

        _deployExternalCollection(collectionId_, deploymentParams_, params);
    }

    function deployNativeCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) public payable {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );
        uint256 totalValue = msg.value;
        bool localDeploy = false;
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            if (deploymentParams_[i].chainId == systemContext.chainId()) {
                factory.createTokenInstanceByName(
                    ERC721_NATIVE_BLUEPRINT_NAME,
                    deploymentParams_[i].ctorParams,
                    collectionId_,
                    params.collectionName,
                    params.owner
                );
                localDeploy = true;
            } else {
                _sendMessageWithValue(
                    SendMessageWithValueParams({
                        chainId: deploymentParams_[i].chainId,
                        bridge: deploymentParams_[i].bridgeAddress,
                        buffer: deployTokenContractEncode(
                            ERC721_NATIVE_BLUEPRINT_NAME,
                            collectionId_,
                            deploymentParams_[i].ctorParams,
                            params.collectionName,
                            params.owner
                        ),
                        refundAddress: params.refundAddress,
                        value: deploymentParams_[i].value,
                        gasAmount: params.gasAmount
                    })
                );
            }
        }
        require(localDeploy, "Local deploy is obligatory");
    }

    // function deployCrowdsale(
    //     DeploymentParams calldata deploymentParams_,
    //     GrantRoleParams calldata grantRoleParams_,
    //     address refundAddress_,
    //     uint256 gasAmount_,
    //     address owner_,
    //     bytes32 crowdsaleSalt_
    // ) public payable {
    //     // solhint-disable-next-line no-empty-blocks
    //     if (deploymentParams_.chainId == systemContext.chainId()) {
    //         // address crowdsaleAddress = systemContext
    //         //     .contractFactory()
    //         //     .createSimpleContractInstanceByName(
    //         //         CROWDSALE_BLUEPRINT_NAME,
    //         //         deploymentParams_.ctorParams,
    //         //         crowdsaleSalt_
    //         //     );
    //         //            IGrantRoleWithSignature(deploymentParams_.originalContractAddress).grantRoleWithSignature(crowdsaleAddress, grantRoleParams_.role, grantRoleParams_.signedAt, grantRoleParams_.signer, grantRoleParams_.grantRoleWithSignature);
    //     } else {
    //         _sendMessageWithValue(
    //             SendMessageWithValueParams({
    //                 chainId: deploymentParams_.chainId,
    //                 bridge: deploymentParams_.bridgeAddress,
    //                 buffer: deployCrowdsaleContractEncode(
    //                     CROWDSALE_BLUEPRINT_NAME,
    //                     crowdsaleSalt_,
    //                     deploymentParams_.ctorParams,
    //                     owner_,
    //                     grantRoleParams_
    //                 ),
    //                 refundAddress: refundAddress_,
    //                 value: deploymentParams_.value,
    //                 gasAmount: gasAmount_
    //             })
    //         );
    //     }
    // }

    function recoverGasDecode(bytes calldata adapterParams)
        public
        pure
        returns (uint256)
    {
        require(adapterParams.length >= 34, "Decode gas failed");
        bytes memory tmp = adapterParams[2:34];
        return abi.decode(tmp, (uint256));
    }

    function getOutboundNonce() public view returns (uint64) {
        return
            endpoint.getOutboundNonce(systemContext.chainId(), address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./ICreate2ContractsFactory.sol";

interface ICreate2BlueprintContractsFactory is ICreate2ContractsFactory {
    event NewBlueprintRegistered(
        address indexed blueprintAddress,
        string blueprintName
    );
    event NewBlueprintVersionRegistered(
        address indexed blueprintAddress,
        string blueprintName,
        uint16 version
    );

    event NewProxyDeployed(string indexed blueprintName, address proxyAddress);

    function registerNewBlueprint(
        address blueprintAddress,
        string memory blueprintName,
        bool isNative
    ) external;

    function registerNewBlueprintVersion(
        address blueprintAddress,
        string memory blueprintName,
        uint16 version,
        bool forceUpdate
    ) external;

    function deregisterLatestBlueprint(string memory name, bool forceUpdate)
        external;

    function blueprintExists(string memory name) external view returns (bool);

    function getBeaconProxyCreationCode() external pure returns (bytes memory);

    function createTokenInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) external returns (address);

    function createSimpleContractInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) external returns (address);

    function registerOriginalContract(
        bytes32 collectionId,
        address originalAddress
    ) external;

    function getLatestBlueprint(string calldata blueprintName_)
        external
        view
        returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICollectionRegistry {
    // Logged when new record is created.
    event NewCollection(
        bytes32 indexed collectionId,
        string name,
        address owner,
        address addr,
        string contractName,
        uint16 contractVersion
    );

    // Logged when the owner of a node transfers ownership to a new account.
    event TransferOwnership(bytes32 indexed collectionId, address owner);

    // Logged when the resolver for a node changes.
    event NewAddress(bytes32 indexed collectionId, address addr);

    function registerCollection(
        bytes32 collectionId_,
        string calldata name_,
        address owner_,
        address collectionAddress_,
        string calldata contractName_,
        uint16 contractVersion_
    ) external;

    function registerOriginalAddress(
        bytes32 collectionId_,
        address originalAddress_
    ) external;

    function setOwner(bytes32 collectionId_, address owner_) external;

    function ownerOf(bytes32 collectionId_) external view returns (address);

    function addressOf(bytes32 collectionId_) external view returns (address);

    function recordExists(bytes32 collectionId_) external view returns (bool);

    function collections(address addr) external view returns (bytes32);

    function externalToCollection(address addr) external view returns (bytes32);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface INonNativeWrapperInitializable {
    function encodeInitializer(address originalContract_)
        external
        pure
        returns (bytes memory);

    function decodeInitializer_NonNativeWrapper(
        bytes memory initializerEncoded_
    ) external pure returns (address originalContract_);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IFeeCollector {
    function applyFeeAndRefund(
        uint256 diff_,
        uint256 valueReturned_,
        address payable refundAddress_
    ) external;

    function setMinimumFee(uint256 minimumFee_) external;

    function setFeeInPercents(uint256 feeInPercents_) external;

    function nativeBalance() external view returns (uint256);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IGrantRoleWithSignature {
    function grantRoleWithSignature(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ITokenBridgeable {
    function collectionId() external returns (bytes32);

    function moveToViaLayerZero(
        uint16 _l0ChainId,
        bytes calldata _destinationBridge,
        uint256 _tokenId,
        uint256 _gasAmount
    ) external payable;

    function mintToWithUri(
        address _to,
        uint256 _tokenId,
        string memory _tokenURI
    ) external;

    function unlockToken(address _to, uint256 _tokenId) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IInitializable {
    error AlreadyInitialized();

    function initialize(bytes memory initializerEncoded_) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface ICreate2ContractsFactory {
    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) external returns (address);

    function deployCreate2(bytes memory bytecode, bytes32 salt)
        external
        returns (address);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./AppStorage.sol";
import "../../../interfaces/diamond/IDiamondLoupe.sol";
import "../../../interfaces/diamond/IDiamondCut.sol";
import "../../../libraries/diamond/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../../interfaces/IInitializable.sol";

contract ERC721NonNative is IInitializable {
    AppStorage internal s;

    modifier onlyIfNotInitialized() {
        if (s.initialized) {
            revert AlreadyInitialized();
        }
        _;

        s.initialized = true;
    }

    function encode(
        address _systemContextAddress,
        string memory _name,
        string memory _symbol,
        address _owner,
        string memory _contractURI,
        IDiamondCut.FacetCut[] memory _diamondCut
    ) public pure returns (bytes memory) {
        bytes memory encodedParams = abi.encode(
            _systemContextAddress,
            _name,
            _symbol,
            _owner,
            _contractURI,
            _diamondCut
        );

        return abi.encodeWithSelector(this.initialize.selector, encodedParams);
    }

    function initialize(bytes memory _initializerEncoded)
        external
        onlyIfNotInitialized
    {
        (
            address _systemContextAddress,
            string memory _name,
            string memory _symbol,
            address _owner,
            string memory _contractURI,
            IDiamondCut.FacetCut[] memory _diamondCut
        ) = abi.decode(
                _initializerEncoded,
                (
                    address,
                    string,
                    string,
                    address,
                    string,
                    IDiamondCut.FacetCut[]
                )
            );

        LibDiamond.diamondCutWithoutInit(_diamondCut);
        // TODO:  who should be the owner of the contract?
        LibDiamond.setContractOwner(_owner);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;

        s.systemContextAddress = _systemContextAddress;
        s.erc721Base.symbol = _symbol;
        s.erc721Base.name = _name;
        s.diamondAddress = address(this);
        s.acl.roles[keccak256("MINTER_ROLE")].members[_owner] = true;
        s.acl.roles[DEFAULT_ADMIN_ROLE].members[_owner] = true;
        s.acl.roles[keccak256("MINTER_ROLE")].adminRole = DEFAULT_ADMIN_ROLE;

        if (bytes(_contractURI).length > 0) {
            s.contractURIOptional = _contractURI;
        }
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function diamondCutWithoutInit(FacetCut[] calldata _diamondCut) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../../interfaces/diamond/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(
            msg.sender == diamondStorage().contractOwner,
            "LibDiamond: Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        handleDiamondCut(_diamondCut);
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function diamondCutWithoutInit(IDiamondCut.FacetCut[] memory _diamondCut)
        internal
    {
        handleDiamondCut(_diamondCut);
        emit DiamondCut(_diamondCut, address(0), "");
    }

    function handleDiamondCut(IDiamondCut.FacetCut[] memory _diamondCut)
        internal
    {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress == address(0),
                "LibDiamondCut: Can't add function that already exists"
            );
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Add facet can't be address(0)"
        );
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            require(
                oldFacetAddress != _facetAddress,
                "LibDiamondCut: Can't replace function with same function"
            );
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        require(
            _functionSelectors.length > 0,
            "LibDiamondCut: No selectors in facet to cut"
        );
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(
            _facetAddress == address(0),
            "LibDiamondCut: Remove facet address must be address(0)"
        );
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress)
        internal
    {
        enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        require(
            _facetAddress != address(0),
            "LibDiamondCut: Can't remove function that doesn't exist"
        );
        // an immutable function is a function defined directly in a diamond
        require(
            _facetAddress != address(this),
            "LibDiamondCut: Can't remove immutable function"
        );
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "LibDiamondCut: _init is address(0) but_calldata is not empty"
            );
        } else {
            require(
                _calldata.length > 0,
                "LibDiamondCut: _calldata is empty but _init is not address(0)"
            );
            if (_init != address(this)) {
                enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./AppStorage.sol";
import "../../../interfaces/diamond/IDiamondLoupe.sol";
import "../../../interfaces/diamond/IDiamondCut.sol";
import "../../../libraries/diamond/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../../interfaces/IInitializable.sol";

contract ERC721NonNativeWrapper is IInitializable {
    AppStorage internal s;

    modifier onlyIfNotInitialized() {
        if (s.initialized) {
            revert AlreadyInitialized();
        }
        _;

        s.initialized = true;
    }

    function encode(
        address _systemContextAddress,
        address _originalAddress,
        IDiamondCut.FacetCut[] memory _diamondCut
    ) public pure returns (bytes memory) {
        bytes memory encodedParams = abi.encode(
            _systemContextAddress,
            _originalAddress,
            _diamondCut
        );

        return abi.encodeWithSelector(this.initialize.selector, encodedParams);
    }

    function initialize(bytes memory initializerEncoded_)
        external
        onlyIfNotInitialized
    {
        (
            address _systemContextAddress,
            address _originalAddress,
            IDiamondCut.FacetCut[] memory _diamondCut
        ) = abi.decode(
                initializerEncoded_,
                (address, address, IDiamondCut.FacetCut[])
            );

        LibDiamond.diamondCutWithoutInit(_diamondCut);
        // TODO: who should be the owner of the contract?
        // TODO: owner
        LibDiamond.setContractOwner(msg.sender);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;

        s.systemContextAddress = _systemContextAddress;
        s.wrappedContract = IERC721(_originalAddress);
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct AppStorage {
    bool initialized;
    address diamondAddress;
    address systemContextAddress;
    IERC721 wrappedContract;
}

//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract ERC721WrapperFacet {
    AppStorage internal s;

    function originalContract() external view returns (IERC721) {
        return s.wrappedContract;
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address wrapperAddress = address(s.wrappedContract);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(
                gas(),
                wrapperAddress,
                0,
                calldatasize(),
                0,
                0
            )
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../storage/AppStorage.sol";
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

// solhint-disable no-empty-blocks
contract ERC721Facet {
    using Address for address;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    AppStorage internal s;

    function balanceOf(address owner) public view virtual returns (uint256) {
        // solhint-disable-next-line reason-string
        require(
            owner != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return s.erc721Base.balances[owner];
    }

    function ownerOf(uint256 tokenId_) public view virtual returns (address) {
        address owner = s.erc721Base.owners[tokenId_];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function name() public view virtual returns (string memory) {
        return s.erc721Base.name;
    }

    function symbol() public view virtual returns (string memory) {
        return s.erc721Base.symbol;
    }

    function exists(uint256 tokenId_) public view virtual returns (bool) {
        return s.erc721Base.owners[tokenId_] != address(0);
    }

    function _requireMinted(uint256 tokenId_) internal view virtual {
        require(exists(tokenId_), "ERC721: invalid token ID");
    }

    function getApproved(uint256 tokenId_)
        public
        view
        virtual
        returns (address)
    {
        _requireMinted(tokenId_);

        return s.erc721Base.tokenApprovals[tokenId_];
    }

    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        s.erc721Base.operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        address sender = LibMeta.msgSender();
        _setApprovalForAll(sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        returns (bool)
    {
        return s.erc721Base.operatorApprovals[owner][operator];
    }

    function isApprovedOrOwner(address spender, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        address owner = ownerOf(tokenId_);
        return (spender == owner ||
            isApprovedForAll(owner, spender) ||
            getApproved(tokenId_) == spender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        // solhint-disable-next-line reason-string
        require(
            ownerOf(tokenId_) == from_,
            "ERC721: transfer from incorrect owner"
        );

        // solhint-disable-next-line reason-string
        require(to_ != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, tokenId_);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId_);

        s.erc721Base.balances[from_] -= 1;
        s.erc721Base.balances[to_] += 1;
        s.erc721Base.owners[tokenId_] = to_;

        emit Transfer(from_, to_, tokenId_);

        _afterTokenTransfer(from_, to_, tokenId_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        address sender = LibMeta.msgSender();

        //solhint-disable-next-line reason-string
        require(
            isApprovedOrOwner(sender, tokenId_),
            "ERC721: caller is not token owner nor approved"
        );

        _transfer(from_, to_, tokenId_);
    }

    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        address sender = LibMeta.msgSender();
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    sender,
                    from,
                    tokenId,
                    data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    // solhint-disable-next-line reason-string
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _safeTransfer(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data
    ) internal virtual {
        _transfer(from_, to_, tokenId_);
        // solhint-disable-next-line reason-string
        require(
            _checkOnERC721Received(from_, to_, tokenId_, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual {
        address sender = LibMeta.msgSender();
        // solhint-disable-next-line reason-string
        require(
            isApprovedOrOwner(sender, tokenId_),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from_, to_, tokenId_, data_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        s.erc721Base.balances[to] += 1;
        s.erc721Base.owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        // solhint-disable-next-line reason-string
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = LibMeta.msgSender();

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        s.erc721Base.balances[owner] -= 1;
        delete s.erc721Base.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        s.erc721Base.tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address sender = LibMeta.msgSender();
        address owner = ownerOf(tokenId_);
        // solhint-disable-next-line reason-string
        require(to_ != owner, "ERC721: approval to current owner");
        // solhint-disable-next-line reason-string
        require(
            sender == owner || isApprovedForAll(owner, sender),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to_, tokenId_);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import "./interfaces/IPartnershipRegistry.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "./interfaces/ISystemContext.sol";

pragma solidity ^0.8.9;

contract PartnershipRegistry is IPartnershipRegistry, Context {
    ISystemContext public systemContext;
    using EnumerableSet for EnumerableSet.Bytes32Set;

    bytes32 public constant DEFAULT_PARTNERSHIP_ADMIN_ROLE = 0x00;
    string internal constant PARTNERHSIP_ADMIN_PREFIX = "ADMIN_";

    constructor(ISystemContext systemContext_) {
        systemContext = systemContext_;
        _roles[DEFAULT_PARTNERSHIP_ADMIN_ROLE]
            .adminRole = DEFAULT_PARTNERSHIP_ADMIN_ROLE;
        _roles[DEFAULT_PARTNERSHIP_ADMIN_ROLE].members[_msgSender()] = true;
    }

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;
    EnumerableSet.Bytes32Set internal _partners;

    modifier _onlyPartnershipAdminRole(string memory _partnerName) {
        require(
            isPartnershipAdmin(_partnerName, _msgSender()),
            "PartnershipRegistry: not admin"
        );
        _;
    }

    modifier _onlyDefaultPartnershipAdminRole() {
        // solhint-disable-next-line reason-string
        require(
            _hasRole(DEFAULT_PARTNERSHIP_ADMIN_ROLE, _msgSender()),
            "PartnershipRegistry: not default admin"
        );
        _;
    }

    modifier _onlyIfPartnershipDoesNotExist(string memory _partnerName) {
        // solhint-disable-next-line reason-string
        require(
            !partnershipExist(_partnerName),
            "PartnershipRegistry: partnership exists"
        );
        _;
    }

    modifier _onlyIfPartnershipExists(string memory _partnerName) {
        // solhint-disable-next-line reason-string
        require(
            partnershipExist(_partnerName),
            "PartnershipRegistry: partnership does not exists"
        );
        _;
    }

    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function partnershipExist(string memory _partnerName)
        public
        virtual
        override
        returns (bool)
    {
        return _partners.contains(keccak256(bytes(_partnerName)));
    }

    function addPartnership(string memory _partnerName, address _admin)
        external
        virtual
        override
        _onlyDefaultPartnershipAdminRole
        _onlyIfPartnershipDoesNotExist(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);

        _roles[partnerAdmin].adminRole = partnerAdmin;
        _roles[partnerAdmin].members[_admin] = true;

        _roles[partner].adminRole = partnerAdmin;
        _roles[partner].members[_admin] = true;

        _partners.add(partner);

        emit PartnerhipRegistered(_partnerName, _admin);
    }

    function removePartnership(string memory _partnerName)
        external
        virtual
        override
        _onlyDefaultPartnershipAdminRole
        _onlyIfPartnershipExists(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        delete _roles[partner];
        delete _roles[partnerAdmin];

        emit PartnerhipRemoved(_partnerName);
    }

    function changePartnershipAdmin(
        string memory _partnerName,
        address _newAdmin
    ) external virtual override _onlyPartnershipAdminRole(_partnerName) {
        address currentAdmin = _msgSender();
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        bytes32 partner = _partnershipRole(_partnerName);

        delete _roles[partnerAdmin].members[currentAdmin];

        _roles[partnerAdmin].members[_newAdmin] = true;
        _roles[partner].members[_newAdmin] = true;

        emit PartnerhipAdminChanged(_partnerName, currentAdmin, _newAdmin);
    }

    function addPartnershipMemeber(string memory _partnerName, address _addr)
        external
        virtual
        override
        _onlyPartnershipAdminRole(_partnerName)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        _roles[partner].members[_addr] = true;

        emit PartnershipMemberAdded(_partnerName, _addr);
    }

    function isPartnershipAdmin(string memory _partnerName, address _addr)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes32 partnerAdmin = _partnershipAdminRole(_partnerName);
        return _hasRole(partnerAdmin, _addr);
    }

    function isPartnershipMember(string memory _partnerName, address _addr)
        public
        view
        virtual
        override
        returns (bool)
    {
        bytes32 partner = _partnershipRole(_partnerName);
        return _hasRole(partner, _addr);
    }

    function _partnershipAdminRole(string memory _partnerName)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(abi.encodePacked(PARTNERHSIP_ADMIN_PREFIX, _partnerName));
    }

    function _partnershipRole(string memory _partnerName)
        internal
        pure
        returns (bytes32)
    {
        return keccak256(bytes(_partnerName));
    }
}

//SPDX-License-Identifier: Business Source License 1.1

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

pragma solidity ^0.8.9;

interface IPartnershipRegistry {
    event PartnerhipRegistered(string indexed name, address admin);
    event PartnerhipRemoved(string indexed name);
    event PartnerhipAdminChanged(
        string indexed name,
        address currentAdmin,
        address newAdmin
    );
    event PartnershipMemberAdded(string indexed name, address member);

    function partnershipExist(string memory _partnerName)
        external
        returns (bool);

    function addPartnership(string memory _partnerName, address _admin)
        external;

    function removePartnership(string memory _partnerName) external;

    function changePartnershipAdmin(
        string memory _partnerName,
        address _newAdmin
    ) external;

    function addPartnershipMemeber(string memory _partnerName, address _member)
        external;

    function isPartnershipMember(string memory _partnerName, address _addr)
        external
        returns (bool);

    function isPartnershipAdmin(string memory _partnerName, address _addr)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./interfaces/ISystemContext.sol";
import "./acl/OmniteAccessControl.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Bytes32ToAddress {
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => address) _values;
    }

    function set(
        Bytes32ToAddress storage map,
        bytes32 key,
        address value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    function remove(Bytes32ToAddress storage map, bytes32 key)
        internal
        returns (bool)
    {
        delete map._values[key];
        return map._keys.remove(key);
    }

    function contains(Bytes32ToAddress storage map, bytes32 key)
        internal
        view
        returns (bool)
    {
        return map._keys.contains(key);
    }

    function length(Bytes32ToAddress storage map)
        internal
        view
        returns (uint256)
    {
        return map._keys.length();
    }

    function at(Bytes32ToAddress storage map, uint256 index)
        internal
        view
        returns (bytes32, address)
    {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    function tryGet(Bytes32ToAddress storage map, bytes32 key)
        internal
        view
        returns (bool, address)
    {
        address value = map._values[key];
        if (value == address(0)) {
            return (contains(map, key), address(0));
        } else {
            return (true, value);
        }
    }

    function get(Bytes32ToAddress storage map, bytes32 key)
        internal
        view
        returns (address)
    {
        address value = map._values[key];
        require(
            value != address(0) || contains(map, key),
            "EnumerableMap: nonexistent key"
        );
        return value;
    }

    function get(
        Bytes32ToAddress storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (address) {
        address value = map._values[key];
        require(value != address(0) || contains(map, key), errorMessage);
        return value;
    }
}

contract SystemContext is ISystemContext {
    using EnumerableMap for EnumerableMap.Bytes32ToAddress;
    EnumerableMap.Bytes32ToAddress internal contractAddresses_;

    uint16 public override chainId;
    address public immutable override multisigWallet;
    string public override contractUriBase;
    string public override chainName;

    OmniteAccessControl public override omniteAccessControl;

    constructor(OmniteAccessControl accessControlList_, address multisigWallet_)
    {
        omniteAccessControl = accessControlList_;
        multisigWallet = multisigWallet_;
    }

    modifier onlySystemContextDefaultAdminRole() {
        omniteAccessControl.checkRole(
            omniteAccessControl.SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE(),
            msg.sender
        );
        _;
    }

    function setChainId(uint16 _chainId)
        external
        onlySystemContextDefaultAdminRole
    {
        chainId = _chainId;
    }

    function setContractUriBase(string memory _contractUriBase)
        external
        onlySystemContextDefaultAdminRole
    {
        contractUriBase = _contractUriBase;
    }

    function setChainName(string memory _chainName)
        external
        onlySystemContextDefaultAdminRole
    {
        chainName = _chainName;
    }

    function getContractAddress(string calldata _contractName)
        public
        view
        override
        returns (address)
    {
        return contractAddresses_.get(keccak256(bytes(_contractName)));
    }

    function registerContract(string calldata _contractName, address _addr)
        public
        override
        onlySystemContextDefaultAdminRole
    {
        bytes32 contractId = keccak256(bytes(_contractName));
        if (_contractRegistered(contractId)) {
            revert ContractAlreadyRegistered(
                _contractName,
                contractAddresses_.get(contractId)
            );
        }
        contractAddresses_.set(keccak256(bytes(_contractName)), _addr);

        emit ContractRegistered(_contractName, _addr);
    }

    function overrideContract(string calldata _contractName, address _addr)
        external
        virtual
        onlySystemContextDefaultAdminRole
    {
        bytes32 contractId = keccak256(bytes(_contractName));
        if (!_contractRegistered(contractId)) {
            revert ContractNotRegistered(_contractName);
        }

        emit ContractUpdated(
            _contractName,
            getContractAddress(_contractName),
            _addr
        );

        contractAddresses_.set(contractId, _addr);
    }

    function removeContract(string calldata _contractName)
        external
        override
        onlySystemContextDefaultAdminRole
    {
        if (!contractRegistered(_contractName)) {
            revert ContractNotRegistered(_contractName);
        }

        contractAddresses_.remove(keccak256(bytes(_contractName)));

        emit ContractRemoved(_contractName);
    }

    function contractRegistered(string calldata _contractName)
        public
        view
        override
        returns (bool)
    {
        return _contractRegistered(keccak256(bytes(_contractName)));
    }

    function _contractRegistered(bytes32 _contractId)
        internal
        view
        returns (bool)
    {
        return contractAddresses_.contains(_contractId);
    }

    function setAccessControlList(OmniteAccessControl accessControlList_)
        external
        override
        onlySystemContextDefaultAdminRole
    {
        omniteAccessControl = accessControlList_;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/ISystemContext.sol";

contract CollectionsRegistry is ICollectionRegistry {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    struct Record {
        address owner;
        address addr;
        string userName;
        string contractName;
        uint16 contractVersion;
    }

    // mapping from collectionId into collection address
    mapping(bytes32 => Record) public records;
    // mapping from address into collection id
    mapping(address => bytes32) public _collections;
    // allows to iterate over records
    mapping(address => EnumerableSet.Bytes32Set) internal userCollections;
    // mapping for non-native original addresses to collection IDs;
    mapping(address => bytes32) public _externalToCollection;

    ISystemContext public systemContext;

    constructor(ISystemContext systemContext_) {
        systemContext = systemContext_;
    }

    function collections(address addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _collections[addr];
    }

    function externalToCollection(address addr)
        external
        view
        virtual
        override
        returns (bytes32)
    {
        return _externalToCollection[addr];
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyRecordOwner(bytes32 collectionId_) {
        // solhint-disable-next-line reason-string
        require(
            records[collectionId_].owner == msg.sender,
            "Ownable: caller is not the record owner"
        );
        _;
    }

    modifier onlyFactoryRole() {
        OmniteAccessControl acl = systemContext.omniteAccessControl();
        acl.checkRole(acl.CONTRACT_FACTORY_ROLE(), msg.sender);
        _;
    }

    /**
     * @dev Adds a new record for a collection.
     * @param collectionId_ The new collection to set.
     * @param owner_ The address of the owner.
     * @param collectionAddress_ The address of the collection contract.
     */
    function registerCollection(
        bytes32 collectionId_,
        string calldata userName_,
        address owner_,
        address collectionAddress_,
        string calldata contractName_,
        uint16 contractVersion_
    ) external virtual override onlyFactoryRole {
        require(!recordExists(collectionId_), "Collection already exists");
        require(
            _collections[collectionAddress_] == bytes32(0x0),
            "Address already in collection"
        );
        _setOwner(collectionId_, owner_);
        _setAddress(collectionId_, collectionAddress_);
        records[collectionId_].userName = userName_;
        records[collectionId_].contractName = contractName_;
        records[collectionId_].contractVersion = contractVersion_;
        _collections[collectionAddress_] = collectionId_;
        emit NewCollection(
            collectionId_,
            userName_,
            owner_,
            collectionAddress_,
            contractName_,
            contractVersion_
        );
    }

    /**
     * @dev Registers mapping from non-native address into collection.
     * @param collectionId_ Id of existing collection.
     * @param originalAddress_ The address of the original NFT contract.
     */
    function registerOriginalAddress(
        bytes32 collectionId_,
        address originalAddress_
    ) external virtual override onlyFactoryRole {
        // solhint-disable-next-line reason-string
        require(
            _externalToCollection[originalAddress_] == bytes32(0),
            "External collection already registered"
        );
        _externalToCollection[originalAddress_] = collectionId_;
    }

    /**
     * @dev Transfers ownership of a collection to a new address. May only be called by the current owner of the node.
     * @param collectionId_ The collection to transfer ownership of.
     * @param owner_ The address of the new owner.
     */
    function setOwner(bytes32 collectionId_, address owner_)
        external
        virtual
        override
        onlyRecordOwner(collectionId_)
    {
        _setOwner(collectionId_, owner_);
        emit TransferOwnership(collectionId_, owner_);
    }

    /**
     * @dev Returns the address that owns the specified node.
     * @param collectionId_ The specified node.
     * @return address of the owner.
     */
    function ownerOf(bytes32 collectionId_)
        external
        view
        virtual
        override
        returns (address)
    {
        address addr = records[collectionId_].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    /**
     * @dev Returns the collection address for the specified collection.
     * @param collectionId_ The specified collection.
     * @return address of the collection.
     */
    function addressOf(bytes32 collectionId_)
        external
        view
        virtual
        override
        returns (address)
    {
        return records[collectionId_].addr;
    }

    /**
     * @dev Returns whether a record has been imported to the registry.
     * @param collectionId_ The specified node.
     * @return Bool if record exists.
     */
    function recordExists(bytes32 collectionId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return records[collectionId_].owner != address(0x0);
    }

    struct RecordWithId {
        address addr;
        string name;
        bytes32 id;
    }

    /**
     * @dev Returns a list of owned user collections.
     * @param userAddress_ The specified user.
     * @return A list of RecordWithId
     */
    function listCollectionsPerOwner(address userAddress_)
        external
        view
        returns (RecordWithId[] memory)
    {
        bytes32[] memory _collectionIds = userCollections[userAddress_]
            .values();
        RecordWithId[] memory _recordsResult = new RecordWithId[](
            _collectionIds.length
        );
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _recordsResult[i].addr = records[_collectionIds[i]].addr;
            _recordsResult[i].name = records[_collectionIds[i]].userName;
            _recordsResult[i].id = _collectionIds[i];
        }
        return _recordsResult;
    }

    function getCollectionIds(address[] memory collectionAddresses_)
        external
        view
        returns (bytes32[] memory)
    {
        bytes32[] memory _collectionIds = new bytes32[](
            collectionAddresses_.length
        );
        for (uint256 i = 0; i < _collectionIds.length; i++) {
            _collectionIds[i] = _collections[collectionAddresses_[i]];
            if (_collectionIds[i] == bytes32(0)) {
                _collectionIds[i] = _externalToCollection[
                    collectionAddresses_[i]
                ];
            }
        }

        return _collectionIds;
    }

    function _setOwner(bytes32 collectionId_, address owner_) internal virtual {
        address prevOwner = records[collectionId_].owner;
        if (prevOwner != address(0x0)) {
            userCollections[prevOwner].remove(collectionId_);
        }

        userCollections[owner_].add(collectionId_);
        records[collectionId_].owner = owner_;
    }

    function _setAddress(bytes32 collectionId_, address collectionAddress_)
        internal
    {
        records[collectionId_].addr = collectionAddress_;
    }

    function getRecord(bytes32 collectionId_)
        public
        view
        returns (Record memory)
    {
        return records[collectionId_];
    }

    function setSystemContext(ISystemContext systemContext_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        systemContext = systemContext_;
    }

    function updateRecord(Record calldata record_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        records[collectionId_] = record_;
    }

    function updateCollection(address addr_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        _collections[addr_] = collectionId_;
    }

    function updateExternalToCollection(address addr_, bytes32 collectionId_)
        public
        onlyRole(
            systemContext
                .omniteAccessControl()
                .COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE()
        )
    {
        _externalToCollection[addr_] = collectionId_;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/layerzero/IOmniteLayerZeroBridgeReceiver.sol";
import "./interfaces/ISystemContext.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import "./CollectionsRegistry.sol";
import "./interfaces/INonNativeWrapperInitializable.sol";
import "./interfaces/IBridge.sol";

contract OmniteLayerZeroBridgeReceiver is IOmniteLayerZeroBridgeReceiver {
    using Address for address;

    // required: the LayerZero endpoint which is passed in the constructor
    ILayerZeroEndpoint public endpoint;
    ISystemContext public immutable systemContext;

    uint256 public apiVersion;

    constructor(ISystemContext systemContext_) {
        apiVersion = 0;
        systemContext = systemContext_;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        endpoint = endpoint_;
    }

    function _handleCall(
        CallData memory callData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (bytes memory) {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        address target = registry.addressOf(callData.collectionId);
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(
            callData.packedData
        );
        if (success) {
            emit CallSuccess(
                srcChainId,
                fromAddress,
                nonce,
                target,
                returnData,
                0
            );
        } else {
            emit CallFailed(
                srcChainId,
                fromAddress,
                nonce,
                target,
                0,
                _getRevertMsg(returnData)
            );
        }
        return returnData;
    }

    function _handleMultiCall(
        MultiCallData memory multiCallData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (bytes[] memory) {
        bytes[] memory multipleReturnData = new bytes[](10);
        for (
            uint256 i = 0;
            i < multiCallData.destinationContracts.length;
            i++
        ) {
            address target = multiCallData.destinationContracts[i];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = target.call(
                multiCallData.packedData[i]
            );
            if (success) {
                emit CallSuccess(
                    srcChainId,
                    fromAddress,
                    nonce,
                    target,
                    returnData,
                    uint16(i)
                );
                multipleReturnData[i] = returnData;
            } else {
                emit CallFailed(
                    srcChainId,
                    fromAddress,
                    nonce,
                    target,
                    uint16(i),
                    _getRevertMsg(returnData)
                );
                break;
            }
        }
        return multipleReturnData;
    }

    function _handleDeployToken(
        DeployTokenData memory deployData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        bytes memory rawCallData = abi.encodeWithSelector(
            factory.createTokenInstanceByName.selector,
            deployData.blueprintName,
            deployData.ctorParams,
            deployData.collectionId,
            deployData.collectionName,
            deployData.owner
        );

        _handleDeployInternal(rawCallData, srcChainId, fromAddress, nonce);
    }

    function _handleDeployCrowdsale(
        DeployCrowdsaleData memory deployData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        bytes memory rawCallData = abi.encodeWithSelector(
            factory.createSimpleContractInstanceByName.selector,
            deployData.blueprintName,
            deployData.ctorParams,
            deployData.collectionId
        );
        _handleDeployInternal(rawCallData, srcChainId, fromAddress, nonce);
    }

    function _handleDeployInternal(
        bytes memory rawCallData,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal returns (address) {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(factory).call(
            rawCallData
        );
        address deployedContract = abi.decode(returnData, (address));
        if (success) {
            emit ContractDeployed(
                srcChainId,
                fromAddress,
                nonce,
                deployedContract
            );
        } else {
            emit ContractNotDeployed(
                srcChainId,
                fromAddress,
                nonce,
                _getRevertMsg(returnData)
            );
        }
        return deployedContract;
    }

    function _handleUndefined(
        Data memory data,
        uint16 srcChainId,
        bytes memory fromAddress,
        uint64 nonce
    ) internal {
        // some handler that error happened
        emit UndefinedCall(
            srcChainId,
            fromAddress,
            nonce,
            data.operation,
            data.apiVersion,
            data.rawData
        );
    }

    function _handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal {
        Data memory data = abi.decode(_payload, (Data));

        emit ReceiveEvent(_srcChainId, _fromAddress, _nonce, data.operation);
        if (data.operation == Operation.CALL) {
            CallData memory callData = abi.decode(data.rawData, (CallData));
            _handleCall(callData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.DEPLOY_TOKEN) {
            DeployTokenData memory deployData = abi.decode(
                data.rawData,
                (DeployTokenData)
            );
            _handleDeployToken(deployData, _srcChainId, _fromAddress, _nonce);
        } else if (data.operation == Operation.DEPLOY_CROWDSALE) {
            DeployCrowdsaleData memory deployData = abi.decode(
                data.rawData,
                (DeployCrowdsaleData)
            );
            _handleDeployCrowdsale(
                deployData,
                _srcChainId,
                _fromAddress,
                _nonce
            );
        } else if (data.operation == Operation.MULTI_CALL) {
            MultiCallData memory callData = abi.decode(
                data.rawData,
                (MultiCallData)
            );
            _handleMultiCall(callData, _srcChainId, _fromAddress, _nonce);
        } else {
            _handleUndefined(data, _srcChainId, _fromAddress, _nonce);
        }
    }

    function handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external virtual override {
        require(msg.sender == address(this), "Not self");
        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
    }

    function handleAllEstimate(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external virtual override {
        uint256 startGas = gasleft();
        _handleAll(_srcChainId, _fromAddress, _nonce, _payload);
        require(false, Strings.toString(startGas - gasleft()));
    }

    function estimateReceiveGas(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        bytes memory _payload
    ) external override returns (string memory) {
        bool success;
        bytes memory revertMsg;
        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAllEstimate.selector,
                _srcChainId,
                _fromAddress,
                0,
                _payload
            )
        );

        return _getRevertMsg(revertMsg);
    }

    // overrides lzReceive function in ILayerZeroReceiver.
    // automatically invoked on the receiving chain after the source chain calls endpoint.send(...)
    function lzReceive(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        // solhint-disable-next-line reason-string
        require(msg.sender == address(endpoint));
        if (systemContext.chainId() < 10000) {
            systemContext.omniteAccessControl().checkRoleBytes(
                systemContext.omniteAccessControl().BRIDGE_ROLE(),
                _fromAddress
            );
        }
        bool success;
        bytes memory revertMsg;

        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAll.selector,
                _srcChainId,
                _fromAddress,
                _nonce,
                _payload
            )
        );
    }

    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Tx reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }

    function forceResume(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        endpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./IOmniteLayerZeroBridge.sol";
import "./ILayerZeroReceiver.sol";
import "./ILayerZeroEndpoint.sol";
import "../IGrantRoleWithSignature.sol";

interface IOmniteLayerZeroBridgeReceiver is
    IOmniteLayerZeroBridge,
    ILayerZeroReceiver
{
    struct DeployNativeParams {
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    struct DeployExternalParams {
        address originalCollection;
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
        bytes ctorParams;
    }

    struct SendMessageWithValueParams {
        uint16 chainId;
        bytes bridge;
        bytes buffer;
        address refundAddress;
        uint256 value;
        uint256 gasAmount;
    }

    function setEndpoint(ILayerZeroEndpoint endpoint_) external;

    function forceResume(uint16 _srcChainId, bytes calldata _srcAddress)
        external;

    function handleAllEstimate(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;

    function handleAll(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;

    function estimateReceiveGas(
        uint16 _srcChainId,
        bytes memory _fromAddress,
        bytes memory _payload
    ) external returns (string memory);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;
import "../../../../interfaces/IGrantRoleWithSignature.sol";

library LibGrantRuleWithSignature {
    modifier ensureIsContract(address tokenAddr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(tokenAddr)
        }
        // solhint-disable-next-line reason-string
        require(size > 0, "LibERC721Burnable: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibERC721Burnable: invoking error");
            }
        }
    }

    function grantRoleWithSignature(
        address addr,
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        bytes memory signature
    ) internal ensureIsContract(addr) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = addr.delegatecall(
            abi.encodeWithSelector(
                IGrantRoleWithSignature.grantRoleWithSignature.selector,
                roleReceiver,
                role,
                signedAt,
                signer,
                signature
            )
        );

        requireSuccess(success, result);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../IGrantRoleWithSignature.sol";
import "../token/ITokenBridgeable.sol";

interface IERC721Sellable is ITokenBridgeable, IGrantRoleWithSignature {
    function getSlots() external view returns (uint256, uint256);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../IInitializable.sol";
import "./ITokenBridgeable.sol";
import "../IGrantRoleWithSignature.sol";

interface ITokenSellable is ITokenBridgeable, IGrantRoleWithSignature {
    function getSlots() external view returns (uint256, uint256);
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../interfaces/token/ITokenSellable.sol";
import "../interfaces/crowdsale/ISimpleNftCrowdsaleInitializable.sol";

//SPDX-License-Identifier: Business Source License 1.1

/**
 * @title NftCrowdsale
 * @dev Crowdsale for mintable and tradable ERC721 token.
 */
contract SimpleNftCrowdsale is
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    ISimpleNftCrowdsaleInitializable
{
    //Emitted when received transfer is forwarded to the wallet
    event Sent(address indexed payee, uint256 amount);
    //Emitted when token purchased
    event Received(
        address indexed payer,
        uint256 tokenId,
        uint256 amount,
        uint256 balance
    );

    //Address of deployed token contract
    ITokenSellable public nftTokenAddress;

    //Price of single token in wei
    uint256 public currentPrice;
    //Max amount of token to be minted
    uint256 public maxCap;
    // Address where funds are collected
    address payable public wallet;

    uint256 public publicSaleTime;

    uint256 public currentTokenId;

    uint256 public startingId;

    bytes32 internal constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // solhint-disable not-rely-on-time
    modifier whenPublicSaleStarted() {
        require(
            block.timestamp >= publicSaleTime,
            "Public Sale time is yet to come"
        );
        _;
    }

    function initialize(bytes memory initializerEncoded_)
        public
        override(IInitializable)
        initializer
    {
        RegularInitParams memory params_ = decodeInitializer(
            initializerEncoded_
        );

        __SimpleNftCrowdsale_init_unchained(
            params_.currentPrice,
            params_.maxCap,
            params_.startingId,
            params_.wallet,
            params_.nftAddress,
            params_.publicSaleTime,
            params_.owner
        );

        if (params_.extensionType == ParamsExtension.GRANT_ROLE) {
            GrantRoleInitParams
                memory grantRoleParams_ = decodeGrantRoleExtension(
                    params_.extensionData
                );
            __SimpleNftCrowdsaleWithGrantRole_init_unchained(
                grantRoleParams_.roleReceiver,
                grantRoleParams_.role,
                grantRoleParams_.signedAt,
                grantRoleParams_.signer,
                grantRoleParams_.signature
            );
        }
    }

    // solhint-disable func-name-mixedcase
    function __SimpleNftCrowdsale_init_unchained(
        uint256 currentPrice_,
        uint256 maxCap_,
        uint256 startingId_,
        address payable wallet_,
        address nftAddress_,
        uint256 publicSaleTime_,
        address owner_
    ) internal {
        // solhint-disable-next-line reason-string
        require(currentPrice_ > 0, "NftCrowdsale: price is less than 1.");
        // solhint-disable-next-line reason-string
        require(maxCap_ > 0, "NftCrowdsale: maxCap is less than 1.");
        // solhint-disable-next-line reason-string
        require(
            wallet_ != address(0),
            "NftCrowdsale: wallet is the zero address."
        );
        // solhint-disable-next-line reason-string
        require(
            nftAddress_ != address(0),
            "NftCrowdsale: nftAddress is the zero address."
        );
        nftTokenAddress = ITokenSellable(nftAddress_);
        uint256 slot1;
        uint256 slot2;
        (slot1, slot2) = nftTokenAddress.getSlots();

        require(
            startingId_ >= slot1 && startingId_ <= slot2,
            "Ids are not inside slots range"
        );
        currentTokenId = startingId_;
        startingId = startingId_;
        currentPrice = currentPrice_;
        maxCap = maxCap_;
        wallet = wallet_;
        publicSaleTime = publicSaleTime_;
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        _transferOwnership(owner_);
    }

    function __SimpleNftCrowdsaleWithGrantRole_init_unchained(
        address roleReceiver_,
        bytes32 role_,
        uint256 signedAt_,
        address signer_,
        bytes memory signature_
    ) internal {
        nftTokenAddress.grantRoleWithSignature(
            roleReceiver_,
            role_,
            signedAt_,
            signer_,
            signature_
        );
    }

    function decodeInitializer(bytes memory initializerEncoded_)
        public
        pure
        override
        returns (RegularInitParams memory)
    {
        return abi.decode(initializerEncoded_, (RegularInitParams));
    }

    function decodeGrantRoleExtension(bytes memory extensionData_)
        public
        pure
        returns (GrantRoleInitParams memory)
    {
        GrantRoleInitParams memory data_ = abi.decode(
            extensionData_,
            (GrantRoleInitParams)
        );
        return
            GrantRoleInitParams({
                roleReceiver: data_.roleReceiver,
                role: data_.role,
                signedAt: data_.signedAt,
                signer: data_.signer,
                signature: data_.signature
            });
    }

    function encodeGrantRoleExtension(
        address roleReceiver_,
        bytes32 role_,
        uint256 signedAt_,
        address signer_,
        bytes memory signature_
    ) public pure override returns (bytes memory) {
        return
            abi.encode(
                GrantRoleInitParams({
                    roleReceiver: roleReceiver_,
                    role: role_,
                    signedAt: signedAt_,
                    signer: signer_,
                    signature: signature_
                })
            );
    }

    function encodeInitializerParams(
        uint256 currentPrice_,
        uint256 maxCap_,
        uint256 startingId_,
        address payable wallet_,
        address nftAddress_,
        uint256 publicSaleTime_,
        address owner_,
        ParamsExtension extensionType_,
        bytes memory extensionData_
    ) public pure returns (bytes memory) {
        return
            abi.encode(
                RegularInitParams({
                    currentPrice: currentPrice_,
                    maxCap: maxCap_,
                    startingId: startingId_,
                    wallet: wallet_,
                    nftAddress: nftAddress_,
                    publicSaleTime: publicSaleTime_,
                    owner: owner_,
                    extensionType: extensionType_,
                    extensionData: extensionData_
                })
            );
    }

    function encodeInitializer(
        uint256 currentPrice_,
        uint256 maxCap_,
        uint256 startingId_,
        address payable wallet_,
        address nftAddress_,
        uint256 publicSaleTime_,
        address owner_,
        ParamsExtension extensionType_,
        bytes memory extensionData_
    ) public pure override returns (bytes memory) {
        bytes memory params = encodeInitializerParams(
            currentPrice_,
            maxCap_,
            startingId_,
            wallet_,
            nftAddress_,
            publicSaleTime_,
            owner_,
            extensionType_,
            extensionData_
        );
        return abi.encodeWithSelector(this.initialize.selector, params);
    }

    /**
     * @dev Purchase for receiver
     * mints 1 token for the specified address
     */
    function purchaseTokenFor(address payable receiver)
        public
        payable
        whenNotPaused
        whenPublicSaleStarted
        nonReentrant
    {
        _purchaseTokenFor(receiver);
    }

    function _purchaseTokenFor(address payable receiver) private {
        require(receiver != address(0), "Receiver cannot be zero address");
        require(receiver != address(this), "Receiver cannot be this contract");
        // solhint-disable-next-line reason-string
        require(
            msg.value == currentPrice,
            "NftCrowdsale: value not equal to price."
        );
        require(
            currentTokenId < maxCap + startingId,
            "NftCrowdsale: max cap reached."
        );

        _mintTokenFor(receiver, currentTokenId);
        _forwardFunds();
    }

    /**
     * @dev mints token to receiver
     *  This method DOES NOT do any validations and should not be called directly!
     * mints a new token for the specified address
     */
    function _mintTokenFor(address payable receiver, uint256 tokenId) private {
        nftTokenAddress.mintToWithUri(receiver, tokenId, "");
        currentTokenId++;
        emit Received(receiver, tokenId, msg.value, address(this).balance);
    }

    /**
     *the address where funds are collected.
     */
    function getWallet() public view returns (address payable) {
        return wallet;
    }

    /**
     *  changes the address where funds are collected.
     */
    function setWallet(address payable _newWallet)
        public
        onlyOwner
        nonReentrant
    {
        wallet = _newWallet;
    }

    function _forwardFunds() internal {
        wallet.transfer(msg.value);
        emit Sent(wallet, msg.value);
    }

    function setPublicSaleTime(uint256 _publicSaleTime) public onlyOwner {
        publicSaleTime = _publicSaleTime;
    }

    function setCurrentPrice(uint256 currentPrice_) public onlyOwner {
        currentPrice = currentPrice_;
    }

    receive() external payable {
        require(false, "Receive on crowdsale contract");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../IInitializable.sol";

interface ISimpleNftCrowdsaleInitializable is IInitializable {
    enum ParamsExtension {
        NONE,
        GRANT_ROLE
    }

    struct RegularInitParams {
        uint256 currentPrice;
        uint256 maxCap;
        uint256 startingId;
        address payable wallet;
        address nftAddress;
        uint256 publicSaleTime;
        address owner;
        ParamsExtension extensionType;
        bytes extensionData;
    }

    struct GrantRoleInitParams {
        address roleReceiver;
        bytes32 role;
        uint256 signedAt;
        address signer;
        bytes signature;
    }

    function decodeInitializer(bytes memory initializerEncoded_)
        external
        pure
        returns (RegularInitParams memory);

    function decodeGrantRoleExtension(bytes memory extensionData_)
        external
        pure
        returns (GrantRoleInitParams memory);

    function encodeInitializer(
        uint256 currentPrice_,
        uint256 maxCap_,
        uint256 startingId_,
        address payable wallet_,
        address nftAddress_,
        uint256 publicSaleTime_,
        address owner_,
        ParamsExtension extensionType_,
        bytes memory extensionData_
    ) external pure returns (bytes memory);

    function encodeGrantRoleExtension(
        address roleReceiver_,
        bytes32 role_,
        uint256 signedAt_,
        address signer_,
        bytes memory signature_
    ) external pure returns (bytes memory);
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

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

/* solium-disable */
import "../interfaces/layerzero/ILayerZeroReceiver.sol";
import "../interfaces/layerzero/ILayerZeroEndpoint.sol";

// mocked LayerZero endpoint to facilitate same chain testing of two UserApplications
contract LayerZeroEndpointMock is ILayerZeroEndpoint {
    mapping(uint16 => mapping(address => uint64)) public nonceMap;

    constructor() {}

    // send() is the primary function of this mock contract.
    //   its really the only reason you will use this contract in local testing.
    //
    // The user application on chain A (the source, or "from" chain) sends a message
    // to the communicator. It includes the following information:
    //      _chainId            - the destination chain identifier
    //      _destination        - the destination chain address (in bytes)
    //      _payload            - a the custom data to send
    //      _refundAddress      - address to send remainder funds to
    //      _zroPaymentAddress  - if 0x0, implies user app is paying in native token. otherwise
    //      txParameters        - optional data passed to the relayer via getPrices()
    // solhint-disable no-unused-vars
    function send(
        uint16 _chainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata txParameters
    ) external payable override {
        // txParameters
        address destAddr = packedBytesToAddr(_destination);
        uint64 nonce;
        {
            nonce = nonceMap[_chainId][destAddr]++;
        }
        bytes memory bytesSourceUserApplicationAddr = addrToPackedBytes(
            address(msg.sender)
        );
        // cast this address to bytes
        ILayerZeroReceiver(destAddr).lzReceive(
            _chainId,
            bytesSourceUserApplicationAddr,
            nonce,
            _payload
        );
        // invoke lzReceive
    }

    // send() helper function
    function packedBytesToAddr(bytes calldata _b)
        public
        pure
        returns (address)
    {
        address addr;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, sub(_b.offset, 2), add(_b.length, 2))
            addr := mload(sub(ptr, 10))
        }
        return addr;
    }

    // send() helper function
    function addrToPackedBytes(address _a) public pure returns (bytes memory) {
        bytes memory data = abi.encodePacked(_a);
        return data;
    }

    // override from ILayerZeroEndpoint
    function estimateFees(
        uint16 chainId,
        address userApplication,
        bytes calldata payload,
        bool payInZRO,
        bytes calldata adapterParams
    ) external pure override returns (uint256 nativeFee, uint256 zroFee) {
        return (0, 0);
    }

    // override from ILayerZeroEndpoint
    function getInboundNonce(uint16 _chainId, bytes calldata _srcAddress)
        external
        view
        override
        returns (uint64)
    {
        return nonceMap[_chainId][packedBytesToAddr(_srcAddress)];
    }

    // override from ILayerZeroEndpoint
    function getOutboundNonce(uint16 _chainId, address _srcAddress)
        external
        view
        override
        returns (uint64)
    {
        return nonceMap[_chainId][_srcAddress];
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
    {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../IBridge.sol";

interface IOmniteAxelarBridge is IBridge {
    event SendEvent(string indexed soruceChain, string indexed destChain);

    event ReceiveEvent(
        string indexed soruceChain,
        string indexed fromAddress,
        Operation operation
    );

    event CallSuccess(
        string indexed srcChain,
        string indexed fromAddress,
        address calledContract,
        bytes returnData,
        uint16 index
    );

    event CallFailed(
        string indexed chainId,
        string indexed fromAddress,
        address calledContract,
        string error,
        uint16 index
    );

    event ContractDeployed(
        string indexed chain,
        string indexed fromAddress,
        address newContract
    );

    event ContractNotDeployed(
        string indexed chain,
        string indexed fromAddress,
        string error
    );

    event UndefinedCall(
        string indexed chain,
        string indexed fromAddress,
        Operation operation,
        uint256 apiVersion,
        bytes rawData
    );

    struct DeploymentParams {
        string chain;
        string bridgeAddress;
        uint256 value;
        bytes ctorParams;
        address originalContractAddress;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./IOmniteAxelarBridge.sol";

interface IOmniteAxelarBridgeSender is IOmniteAxelarBridge {
    event SendEvent(string destChain, bytes destAddress);

    struct DeployExternalParams {
        address originalCollection;
        string collectionName;
        uint256 gasAmount;
        address owner;
        bytes ctorParams;
    }

    struct DeployNativeParams {
        string collectionName;
        address refundAddress;
        uint256 gasAmount;
        address owner;
    }

    function setMinimumGas(uint256 minGas_) external;

    function setMaxNetworks(uint64 maxNetworks_) external;

    function mintOnTargetChain(
        string calldata chain,
        string calldata bridge_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) external payable;

    function deployExternalCollection(
        DeploymentParams[] memory deploymentParams_,
        DeployExternalParams calldata params
    ) external payable;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";
import "../../../../interfaces/diamond/ERC721/IERC721AxelarBridgedableFacet.sol";
import "../storage/AppStorage.sol";
import "../libraries/LibERC721.sol";
import "../libraries/LibERC721TokenURI.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../../../../interfaces/axelar/IOmniteAxelarBridgeSender.sol";

contract ERC721AxelarBridgedableFacet is IERC721AxelarBridgedableFacet {
    AppStorage internal s;

    function requireIsApprovedOrOwner(address addr, uint256 _tokenId)
        internal
        view
    {
        require(
            LibERC721.isApprovedOrOwner(s.diamondAddress, addr, _tokenId),
            "Caller not owner nor approved"
        );
    }

    function moveToViaAxelar(
        string calldata _chain,
        string memory _destinationBridge,
        uint256 _tokenId
    ) external payable virtual override {
        address sender = LibMeta.msgSender();
        requireIsApprovedOrOwner(sender, _tokenId);

        LibERC721.transferFrom(
            s.diamondAddress,
            sender,
            address(this),
            _tokenId
        );

        IOmniteAxelarBridgeSender AxelarSender = IOmniteAxelarBridgeSender(
            ISystemContext(s.systemContextAddress).getContractAddress(
                "OMNITE_Axelar_BRIDGE_SENDER"
            )
        );

        AxelarSender.mintOnTargetChain{value: msg.value}(
            _chain,
            _destinationBridge,
            sender,
            _tokenId,
            LibERC721TokenURI.tokenURI(s.diamondAddress, _tokenId)
        );
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721AxelarBridgedableFacet {
    function moveToViaAxelar(
        string calldata _chain,
        string memory _bridgeAddress,
        uint256 _tokenId
    ) external payable;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/IGrantRuleWithSignatureFacet.sol";
import "../libraries/LibAccessControlList.sol";
import "../storage/AppStorage.sol";
import "../../../../libraries/LibSignatureService.sol";

contract GrantRoleWithSignatureFacet is IGrantRuleWithSignatureFacet {
    AppStorage internal s;

    function grantRoleWithSignature(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        bytes memory signature
    ) external override {
        address signerRetrieved = LibSignatureService
            .recoverGrantRoleWithSignature(
                roleReceiver,
                role,
                signedAt,
                signer,
                address(this),
                signature
            );

        LibAccessControlList.checkRole(
            s.diamondAddress,
            DEFAULT_ADMIN_ROLE,
            signerRetrieved
        );

        LibAccessControlList.grantRole(s.diamondAddress, role, roleReceiver);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IGrantRuleWithSignatureFacet {
    function grantRoleWithSignature(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        bytes memory signature
    ) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

library LibSignatureService {
    function eip712DomainHash() public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version, address verifyingContract, uint256 signedAt)"
                    )
                )
            );
    }

    function getGrantRoleWithSignatureHash(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        address target
    ) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    uint16(0x1901),
                    eip712DomainHash(),
                    keccak256(
                        abi.encode(
                            keccak256(
                                "grantRoleWithSignature(address addr, bytes32 role, uint256 signedAt, address signer)"
                            ),
                            roleReceiver,
                            role,
                            signedAt,
                            signer,
                            target
                        )
                    )
                )
            );
    }

    function getGrantRoleWithSignatureHashForRecover(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        address target
    ) public pure returns (bytes32) {
        return
            ECDSA.toEthSignedMessageHash(
                getGrantRoleWithSignatureHash(
                    roleReceiver,
                    role,
                    signedAt,
                    signer,
                    target
                )
            );
    }

    function recoverGrantRoleWithSignature(
        address roleReceiver,
        bytes32 role,
        uint256 signedAt,
        address signer,
        address target,
        bytes memory signature
    ) public pure returns (address) {
        bytes32 hash = getGrantRoleWithSignatureHashForRecover(
            roleReceiver,
            role,
            signedAt,
            signer,
            target
        );
        return ECDSA.recover(hash, signature);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/ERC721/IERC721OmniteFacet.sol";
import "../../../../interfaces/ISystemContext.sol";
import "../../../../interfaces/ICollectionRegistry.sol";

import "../storage/AppStorage.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract ERC721OmniteFacet is IERC721OmniteFacet {
    AppStorage internal s;

    function collectionId() public view virtual override returns (bytes32) {
        return
            ICollectionRegistry(
                ISystemContext(s.systemContextAddress).getContractAddress(
                    "COLLECTIONS_REGISTRY"
                )
            ).collections(s.diamondAddress);
    }

    function contractURI()
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (bytes(s.contractURIOptional).length > 0) {
            return s.contractURIOptional;
        }
        return
            string(
                abi.encodePacked(
                    ISystemContext(s.systemContextAddress).contractUriBase(),
                    Strings.toHexString(uint256(collectionId()), 32)
                )
            );
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721OmniteFacet {
    function collectionId() external returns (bytes32);

    function contractURI() external returns (string memory);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./interfaces/axelar/IOmniteAxelarBridgeSender.sol";
import "./interfaces/diamond/ERC721/IERC721MintableFacet.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import "./interfaces/IFeeCollector.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/ISystemContext.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/INonNativeWrapperInitializable.sol";
import "./interfaces/IInitializable.sol";
import "./interfaces/ISystemContext.sol";
import "./interfaces/diamond/ERC721/IERC721MintableFacet.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";

contract OmniteAxelarBridgeSender is
    IOmniteAxelarBridgeSender,
    IAxelarExecutable
{
    uint64 public constant MAX_URL_LEN = 512;
    uint64 public constant MAX_CALL_DATA_LEN = 8096;
    uint64 public maxNetworks = 16;
    ISystemContext public immutable systemContext;
    IAxelarGasService internal gasReceiver;

    uint256 public apiVersion;
    uint256 public minGas;

    string public constant ERC721_NON_NATIVE_BLUEPRINT_NAME = "ERC721NonNative";
    string public constant ERC721_NATIVE_BLUEPRINT_NAME = "ERC721Native";
    string public constant ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME =
        "NonNativeWrapper";

    constructor(
        address systemContextAddress_,
        address axelarGatewayAddress_,
        address axelarGasReceiverAddress_
    ) IAxelarExecutable(axelarGatewayAddress_) {
        systemContext = ISystemContext(systemContextAddress_);
        gasReceiver = IAxelarGasService(axelarGasReceiverAddress_);
        apiVersion = 0;
        minGas = 100000;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    modifier tokenURIisValid(string calldata uri) {
        require(bytes(uri).length <= MAX_URL_LEN, "token uri to long");
        _;
    }

    function setMinimumGas(uint256 minGas_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        minGas = minGas_;
    }

    function setMaxNetworks(uint64 maxNetworks_)
        external
        virtual
        override
        onlyRole(
            systemContext.omniteAccessControl().BRIDGE_DEFAULT_ADMIN_ROLE()
        )
    {
        maxNetworks = maxNetworks_;
    }

    function _sendMessage(
        string memory _chainName,
        string memory _targetAddress,
        bytes memory _data,
        uint256 _value
    ) public payable {
        require(_value > 0 && msg.value >= _value, "");

        gasReceiver.payNativeGasForContractCall{value: _value}(
            address(this),
            _chainName,
            _targetAddress,
            _data,
            msg.sender
        );

        gateway.callContract(_chainName, _targetAddress, _data);
        emit SendEvent(_chainName, _targetAddress);
    }

    function deployExternalCollection(
        DeploymentParams[] memory deploymentParams_,
        DeployExternalParams calldata params
    ) external payable override {
        // solhint-disable not-rely-on-time
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );

        ICollectionRegistry collectionRegistry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );

        require(
            collectionRegistry.externalToCollection(
                params.originalCollection
            ) == bytes32(0),
            "Collection already registered"
        );

        ERC721 orig = ERC721(params.originalCollection);

        bytes memory ctorParams = abi.encode( // TODO what to do with contractURI_???
            orig.name(),
            orig.symbol(),
            systemContext.multisigWallet()
        );

        ctorParams = abi.encodeWithSelector(
            IInitializable.initialize.selector,
            ctorParams
        );

        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow
            string memory chain = deploymentParams_[i].chain;
            require(
                keccak256(bytes(chain)) !=
                    keccak256(bytes(systemContext.chainName())),
                "Cannot deploy locally"
            );

            _sendMessage(
                chain,
                deploymentParams_[i].bridgeAddress,
                deployTokenContractEncode(
                    ERC721_NON_NATIVE_BLUEPRINT_NAME,
                    collectionId_,
                    ctorParams,
                    params.collectionName,
                    systemContext.multisigWallet()
                ),
                deploymentParams_[i].value
            );
        }
    }

    function deployTokenContractEncode(
        string memory blueprintName_,
        bytes32 collectionId_,
        bytes memory ctorParams_,
        string calldata collectionName_,
        address owner_
    ) public view returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.DEPLOY_TOKEN,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        DeployTokenData({
                            blueprintName: blueprintName_,
                            ctorParams: ctorParams_,
                            collectionId: collectionId_,
                            collectionName: collectionName_,
                            owner: owner_
                        })
                    )
                })
            );
    }

    modifier nativePayment(address refundAddress_, uint256 valueSent_) {
        IFeeCollector feeCollector_ = IFeeCollector(
            systemContext.getContractAddress("FEE_COLLECTOR")
        );
        uint256 currentAmount_ = feeCollector_.nativeBalance();
        _;
        // check value after user payment
        uint256 diff_ = feeCollector_.nativeBalance() - currentAmount_;

        feeCollector_.applyFeeAndRefund(
            diff_,
            msg.value,
            payable(refundAddress_)
        );
    }

    function _deployNonNativeWrapper(
        DeployExternalParams memory deployData,
        bytes32 collectionId
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        INonNativeWrapperInitializable wrapperBlueprint = INonNativeWrapperInitializable(
                factory.getLatestBlueprint(
                    ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME
                )
            );
        factory.createTokenInstanceByName(
            ERC721_NON_NATIVE_WRAPPER_BLUEPRINT_NAME,
            wrapperBlueprint.encodeInitializer(deployData.originalCollection),
            collectionId,
            deployData.collectionName,
            deployData.owner
        );
        factory.registerOriginalContract(
            collectionId,
            deployData.originalCollection
        );
    }

    function mintOnTargetChainEncode(
        bytes32 collectionId_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public view virtual returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: abi.encodeWithSelector(
                                IERC721MintableFacet.mintToWithUri.selector,
                                owner_,
                                mintId_,
                                tokenUri_
                            )
                        })
                    )
                })
            );
    }

    function mintOnTargetChain(
        string calldata chain,
        string calldata bridge_,
        address owner_,
        uint256 mintId_,
        string calldata tokenUri_
    ) public payable virtual override {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        bytes32 collectionId_ = registry.collections(msg.sender);

        // solhint-disable-next-line reason-string
        require(
            collectionId_ != bytes32(0),
            "Only collection contract can call"
        );
        require(bytes(tokenUri_).length <= MAX_URL_LEN, "token uri to long");

        _sendMessage(
            chain,
            bridge_,
            mintOnTargetChainEncode(collectionId_, owner_, mintId_, tokenUri_),
            msg.value
        );
    }

    function callOnTargetChainEncode(
        bytes32 collectionId_,
        bytes calldata callData_
    ) public view returns (bytes memory) {
        return
            abi.encode(
                Data({
                    operation: Operation.CALL,
                    apiVersion: apiVersion,
                    rawData: abi.encode(
                        CallData({
                            collectionId: collectionId_,
                            packedData: callData_
                        })
                    )
                })
            );
    }

    function callOnTargetChain(
        string calldata chain,
        string calldata bridge_,
        bytes32 collectionId_,
        bytes calldata callData_
    ) public payable {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        // solhint-disable-next-line reason-string
        require(
            registry.addressOf(collectionId_) == msg.sender,
            "Only collection contract can call"
        );
        require(callData_.length <= MAX_CALL_DATA_LEN, "calldata to long");
        _sendMessage(
            chain,
            bridge_,
            callOnTargetChainEncode(collectionId_, callData_),
            msg.value
        );
    }

    function _deployExternalCollection(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );

        ERC721 orig = ERC721(params.originalCollection);
        bytes memory ctorParams = abi.encode( // TODO what to do with contractURI_???
            orig.name(),
            orig.symbol(),
            systemContext.multisigWallet()
        );

        ctorParams = abi.encodeWithSelector(
            IInitializable.initialize.selector,
            ctorParams
        );

        uint256 totalValue = msg.value;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            string memory chain = systemContext.chainName();
            require(
                keccak256(bytes(deploymentParams_[i].chain)) !=
                    keccak256(bytes(chain)),
                "Cannot deploy locally"
            );

            _sendMessage(
                chain,
                deploymentParams_[i].bridgeAddress,
                deployTokenContractEncode(
                    ERC721_NON_NATIVE_BLUEPRINT_NAME,
                    collectionId_,
                    ctorParams,
                    params.collectionName,
                    systemContext.multisigWallet()
                ),
                deploymentParams_[i].value
            );
        }
    }

    function deployExternalCollectionOnNewChains(
        bytes32 collectionId_,
        DeploymentParams[] calldata deploymentParams_,
        DeployExternalParams calldata params
    ) public payable {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        require(
            registry.externalToCollection(params.originalCollection) ==
                collectionId_,
            "Collection not registered yet"
        );

        _deployExternalCollection(collectionId_, deploymentParams_, params);
    }

    function deployNativeCollection(
        DeploymentParams[] calldata deploymentParams_,
        DeployNativeParams calldata params
    ) public payable {
        require(
            deploymentParams_.length <= maxNetworks,
            "networks config to long"
        );
        bytes32 collectionId_ = keccak256(
            abi.encodePacked(block.timestamp, msg.sender)
        );
        uint256 totalValue = msg.value;
        bool localDeploy = false;
        for (uint256 i = 0; i < deploymentParams_.length; i++) {
            totalValue -= deploymentParams_[i].value; // raises exception in case of underflow

            if (
                keccak256(bytes(deploymentParams_[i].chain)) ==
                keccak256(bytes(systemContext.chainName()))
            ) {
                ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                        systemContext.getContractAddress(
                            "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                        )
                    );
                factory.createTokenInstanceByName(
                    ERC721_NATIVE_BLUEPRINT_NAME,
                    deploymentParams_[i].ctorParams,
                    collectionId_,
                    params.collectionName,
                    params.owner
                );
                localDeploy = true;
            } else {
                _sendMessage(
                    systemContext.chainName(),
                    deploymentParams_[i].bridgeAddress,
                    deployTokenContractEncode(
                        ERC721_NATIVE_BLUEPRINT_NAME,
                        collectionId_,
                        deploymentParams_[i].ctorParams,
                        params.collectionName,
                        params.owner
                    ),
                    deploymentParams_[i].value
                );
            }
        }
        require(localDeploy, "Local deploy is obligatory");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import { IAxelarGateway } from './IAxelarGateway.sol';

abstract contract IAxelarExecutable {
    error NotApprovedByGateway();

    IAxelarGateway public gateway;

    constructor(address gateway_) {
        gateway = IAxelarGateway(gateway_);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash)) revert NotApprovedByGateway();
        _execute(sourceChain, sourceAddress, payload);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCallAndMint(commandId, sourceChain, sourceAddress, payloadHash, tokenSymbol, amount))
            revert NotApprovedByGateway();

        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload,
        string memory tokenSymbol,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetDailyMintLimitsParams();
    error ExceedDailyMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenDailyMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function tokenDailyMintLimit(string memory symbol) external view returns (uint256);

    function tokenDailyMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenDailyMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './IUpgradable.sol';

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService is IUpgradable {
    error NothingReceived();
    error TransferFailed();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(address payable receiver, address[] calldata tokens) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external view returns (bytes32);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./interfaces/ISystemContext.sol";
import "./interfaces/axelar/IOmniteAxelarBridgeReceiver.sol";
import "./interfaces/ICollectionRegistry.sol";
import "./interfaces/factory/ICreate2BlueprintContractsFactory.sol";
import {IAxelarExecutable} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarExecutable.sol";
import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";

contract OmniteAxelarBridgeReceiver is
    IAxelarExecutable,
    IOmniteAxelarBridgeReceiver
{
    ISystemContext public immutable systemContext;
    uint256 public apiVersion;

    constructor(
        address systemContextAddress_,
        address AxelarGatewayAddress_,
        uint256 apiVersion_
    ) IAxelarExecutable(AxelarGatewayAddress_) {
        systemContext = ISystemContext(systemContextAddress_);
        apiVersion = apiVersion_;
    }

    function handleAll(
        string memory _srcChainId,
        string memory _fromAddress,
        bytes calldata _payload
    ) external virtual override {
        require(msg.sender == address(this), "Not self");
        _handleAll(_srcChainId, _fromAddress, _payload);
    }

    function _handleDeployToken(
        DeployTokenData memory deployData,
        string memory _srcChain,
        string memory _fromAddress
    ) internal {
        ICreate2BlueprintContractsFactory factory = ICreate2BlueprintContractsFactory(
                systemContext.getContractAddress(
                    "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
                )
            );
        bytes memory rawCallData = abi.encodeWithSelector(
            factory.createTokenInstanceByName.selector,
            deployData.blueprintName,
            deployData.ctorParams,
            deployData.collectionId,
            deployData.collectionName,
            deployData.owner
        );

        _handleDeployInternal(rawCallData, _srcChain, _fromAddress);
    }

    function estimateReceiveGas(
        string memory _chainName,
        string memory _targetAddress,
        bytes memory _data
    ) external override returns (string memory) {
        bool success;
        bytes memory revertMsg;
        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAllEstimate.selector,
                _chainName,
                _targetAddress,
                _data
            )
        );

        return _getRevertMsg(revertMsg);
    }

    function handleAllEstimate(
        string memory _chainName,
        string memory _targetAddress,
        bytes calldata _data
    ) external virtual override {
        uint256 startGas = gasleft();
        _handleAll(_chainName, _targetAddress, _data);
        require(false, Strings.toString(startGas - gasleft()));
    }

    function _handleDeployInternal(
        bytes memory _rawCallData,
        string memory _srcChain,
        string memory _fromAddress
    ) internal returns (address) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(
            systemContext.getContractAddress(
                "CREATE_2_BLUEPRINT_CONTRACTS_FACTORY"
            )
        ).call(_rawCallData);
        address deployedContract;
        if (success) {
            deployedContract = abi.decode(returnData, (address));
            emit ContractDeployed(_srcChain, _fromAddress, deployedContract);
        } else {
            emit ContractNotDeployed(
                _srcChain,
                _fromAddress,
                _getRevertMsg(returnData)
            );
        }
        return deployedContract;
    }

    function _handleAll(
        string memory _srcChain,
        string memory _fromAddress,
        bytes calldata _payload
    ) internal {
        Data memory data = abi.decode(_payload, (Data));
        emit ReceiveEvent(_srcChain, _fromAddress, data.operation);

        if (data.operation == Operation.CALL) {
            CallData memory callData = abi.decode(data.rawData, (CallData));
            _handleCall(_srcChain, _fromAddress, callData);
        } else if (data.operation == Operation.DEPLOY_TOKEN) {
            DeployTokenData memory deployData = abi.decode(
                data.rawData,
                (DeployTokenData)
            );
            _handleDeployToken(deployData, _srcChain, _fromAddress);
        } else if (data.operation == Operation.MULTI_CALL) {
            MultiCallData memory callData = abi.decode(
                data.rawData,
                (MultiCallData)
            );
            _handleMultiCall(callData, _srcChain, _fromAddress);
        } else {
            _handleUndefined(data, _srcChain, _fromAddress);
        }

        // emit ReceiveEvent(_srcChainId, _fromAddress, _nonce, data.operation);
    }

    function _handleUndefined(
        Data memory data,
        string memory _srcChain,
        string memory _fromAddress
    ) internal {
        // some handler that error happened
        emit UndefinedCall(
            _srcChain,
            _fromAddress,
            data.operation,
            data.apiVersion,
            data.rawData
        );
    }

    function _handleCall(
        string memory _srcChain,
        string memory _fromAddress,
        CallData memory _callData
    ) internal returns (bytes memory) {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        address target = registry.addressOf(_callData.collectionId);

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = target.call(
            _callData.packedData
        );

        if (success) {
            emit CallSuccess(
                _srcChain,
                _fromAddress,
                target,
                returnData,
                uint16(0)
            );
        } else {
            emit CallFailed(
                _srcChain,
                _fromAddress,
                target,
                _getRevertMsg(returnData),
                uint16(0)
            );
        }
        return returnData;
    }

    function _handleMultiCall(
        MultiCallData memory _multiCallData,
        string memory _srcChain,
        string memory _fromAddress
    ) internal returns (bytes[] memory) {
        // TODO: why 10?
        bytes[] memory multipleReturnData = new bytes[](10);
        for (
            uint256 i = 0;
            i < _multiCallData.destinationContracts.length;
            i++
        ) {
            address target = _multiCallData.destinationContracts[i];
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, bytes memory returnData) = target.call(
                _multiCallData.packedData[i]
            );
            if (success) {
                emit CallSuccess(
                    _srcChain,
                    _fromAddress,
                    target,
                    returnData,
                    uint16(i)
                );
                multipleReturnData[i] = returnData;
            } else {
                emit CallFailed(
                    _srcChain,
                    _fromAddress,
                    target,
                    _getRevertMsg(returnData),
                    uint16(i)
                );
                break;
            }
        }
        return multipleReturnData;
    }

    function _execute(
        string memory sourceChain,
        string memory sourceAddress,
        bytes calldata payload
    ) internal virtual override {
        require(msg.sender == address(gateway), "");
        // TODO: check on acl the source Address has role to call the contract

        bool success;
        bytes memory revertMsg;

        // solhint-disable-next-line avoid-low-level-calls
        (success, revertMsg) = address(this).call(
            abi.encodeWithSelector(
                this.handleAll.selector,
                sourceChain,
                sourceAddress,
                payload
            )
        );
    }

    // TODO: common or lib
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Tx reverted silently";
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string));
        // All that remains is the revert string
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./IOmniteAxelarBridge.sol";

interface IOmniteAxelarBridgeReceiver is IOmniteAxelarBridge {
    function handleAll(
        string calldata _srcChainId,
        string calldata _fromAddress,
        bytes calldata _payload
    ) external;

    function handleAllEstimate(
        string memory _chainName,
        string memory _targetAddress,
        bytes memory _data
    ) external;

    function estimateReceiveGas(
        string memory _chainName,
        string memory _targetAddress,
        bytes memory _data
    ) external returns (string memory);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/factory/ICreate2ContractsFactory.sol";

contract Create2ContractsFactory is ICreate2ContractsFactory {
    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param constructorParams - ctor params encoded with abi.encode
     * @param salt - salt required by create2
     */
    function deployCreate2WithParams(
        bytes memory bytecode,
        bytes memory constructorParams,
        bytes32 salt
    ) public virtual override returns (address) {
        return
            deployCreate2(abi.encodePacked(bytecode, constructorParams), salt);
    }

    /**
     * @dev Deploys any contract using create2 asm opcode creating the same address for same bytecode
     * @param bytecode - bytecode packed with params to deploy
     * @param salt - salt required by create2
     */
    function deployCreate2(bytes memory bytecode, bytes32 salt)
        public
        virtual
        override
        returns (address)
    {
        address newContract;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            newContract := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        require(_isContract(newContract), "Deploy failed");

        return newContract;
    }

    /**
     * @dev Returns True if provided address is a contract
     * @param account Prospective contract address
     * @return True if there is a contract behind the provided address
     */
    function _isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./proxy/BeaconProxy.sol";
import "./proxy/UpgradeableBeacon.sol";
import "../interfaces/ISystemContext.sol";
import "../interfaces/ICollectionRegistry.sol";
import "./Create2ContractsFactory.sol";
import "../interfaces/factory/ICreate2BlueprintContractsFactory.sol";

/**
 * @dev This contract enables creation of smart contracts following the Upgradable Proxy pattern
 */
contract Create2BlueprintContractsFactory is
    Create2ContractsFactory,
    ICreate2BlueprintContractsFactory
{
    mapping(string => uint16) public latestBlueprintVersion;

    mapping(string => mapping(uint16 => address)) public blueprints; //name => version => blueprint address

    mapping(string => UpgradeableBeacon) public beacons; //name -> beacon

    mapping(string => bool) public blueprintNative;
    ISystemContext public systemContext;

    string internal constant WRONG_BLUEPRINT_NAME = "Check blueprint name";
    string internal constant WRONG_BLUEPRINT_VERSION =
        "Check blueprint version or addr";

    constructor(ISystemContext systemContext_) {
        systemContext = systemContext_;
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    modifier onlyBridgeRole() {
        systemContext.omniteAccessControl().checkRole(
            systemContext.omniteAccessControl().BRIDGE_ROLE(),
            msg.sender
        );
        _;
    }

    /**
     * @dev Registers a new blueprint and its name
     * @param blueprintAddress - address of the blueprint contract
     * @param blueprintName - human readable name of a blueprint.
     */
    function registerNewBlueprint(
        address blueprintAddress,
        string memory blueprintName,
        bool isNative
    )
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(!blueprintExists(blueprintName), WRONG_BLUEPRINT_NAME);
        UpgradeableBeacon beacon = new UpgradeableBeacon(blueprintAddress);
        blueprints[blueprintName][1] = blueprintAddress;
        latestBlueprintVersion[blueprintName] = 1;
        blueprintNative[blueprintName] = isNative;
        beacons[blueprintName] = beacon;

        emit NewBlueprintRegistered(blueprintAddress, blueprintName);
    }

    /**
     * @dev Registers a new version of a blueprint
     * @param blueprintAddress - address of the blueprint contract
     * @param blueprintName - human readable name of a blueprint.
     * @param version - next iterative version.
     * @param forceUpdate - if true, implementation should be updated in the next block
     */
    function registerNewBlueprintVersion(
        address blueprintAddress,
        string memory blueprintName,
        uint16 version,
        bool forceUpdate
    )
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(blueprintExists(blueprintName), WRONG_BLUEPRINT_NAME);
        require(
            blueprints[blueprintName][version - 1] != address(0),
            WRONG_BLUEPRINT_VERSION
        );
        require(
            blueprints[blueprintName][version - 1] != blueprintAddress,
            WRONG_BLUEPRINT_VERSION
        );
        require(
            version == latestBlueprintVersion[blueprintName] + 1,
            WRONG_BLUEPRINT_VERSION
        );
        latestBlueprintVersion[blueprintName] = version;
        blueprints[blueprintName][version] = blueprintAddress;

        beacons[blueprintName].upgradeTo(blueprintAddress, forceUpdate);

        emit NewBlueprintVersionRegistered(
            blueprintAddress,
            blueprintName,
            version
        );
    }

    /**
     * @dev Removes latest blueprint version
     */
    function deregisterLatestBlueprint(string memory name, bool forceUpdate)
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().CONTROL_LIST_ADMIN_ROLE())
    {
        require(blueprintExists(name), WRONG_BLUEPRINT_NAME);
        if (latestBlueprintVersion[name] > 1) {
            delete blueprints[name][latestBlueprintVersion[name]];
            latestBlueprintVersion[name]--;
            beacons[name].upgradeTo(
                blueprints[name][latestBlueprintVersion[name]],
                forceUpdate
            );
        } else {
            delete blueprints[name][1];
            delete latestBlueprintVersion[name];
            delete blueprintNative[name];
            beacons[name].deregister();
        }
    }

    function blueprintExists(string memory name)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            latestBlueprintVersion[name] != 0 &&
            blueprints[name][1] != address(0);
    }

    /**
     * @dev Deploys proxy smart contract using given params.
     * @param blueprintName - name of a blueprint to be used for proxy.
     * @param initParams - abi packed params for contract initialization.
     */
    function _deployProxy(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) internal returns (address) {
        address newContract = deployCreate2WithParams(
            type(BeaconProxy).creationCode,
            abi.encode(address(beacons[blueprintName]), new bytes(0)),
            salt
        );
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newContract.call(initParams);
        require(success, "Initialize failed");

        return newContract;
    }

    function getBeaconProxyCreationCode()
        public
        pure
        virtual
        override
        returns (bytes memory)
    {
        return type(BeaconProxy).creationCode;
    }

    /**
     * @dev Creates native contract instance for whitelisted byteCode.
     * @param blueprintName -name of the blueprint.
     * @param initParams - encoded constructor params.
     * @param collectionId - unique collection identifier.
     * @param name - human readable collection name.
     * @param owner - owner of the collection.
     */
    function createTokenInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) external virtual override onlyBridgeRole returns (address) {
        require(
            blueprints[blueprintName][latestBlueprintVersion[blueprintName]] !=
                address(0),
            WRONG_BLUEPRINT_NAME
        );

        address newContract = _deployProxy(
            blueprintName,
            initParams,
            collectionId
        );
        emit NewProxyDeployed(blueprintName, newContract);

        if (blueprintNative[blueprintName]) {
            systemContext.omniteAccessControl().grantNativeTokenRole(
                newContract
            );
        } else {
            systemContext.omniteAccessControl().grantNonNativeTokenRole(
                newContract
            );
        }

        _registerToken(newContract, blueprintName, collectionId, name, owner);
        return newContract;
    }

    /**
     * @dev Creates contract instance for whitelisted byteCode.
     * @param blueprintName -name of the blueprint.
     * @param initParams - encoded constructor params.
     * @param salt - salt for create2
     */
    function createSimpleContractInstanceByName(
        string memory blueprintName,
        bytes memory initParams,
        bytes32 salt
    ) external virtual override onlyBridgeRole returns (address) {
        require(
            blueprints[blueprintName][latestBlueprintVersion[blueprintName]] !=
                address(0),
            WRONG_BLUEPRINT_NAME
        );

        address newContract = _deployProxy(blueprintName, initParams, salt);
        emit NewProxyDeployed(blueprintName, newContract);
        return newContract;
    }

    function registerOriginalContract(
        bytes32 collectionId,
        address originalAddress
    ) external virtual override onlyBridgeRole {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        registry.registerOriginalAddress(collectionId, originalAddress);
    }

    function _registerToken(
        address newContract,
        string memory blueprintName,
        bytes32 collectionId,
        string calldata name,
        address owner
    ) internal {
        ICollectionRegistry registry = ICollectionRegistry(
            systemContext.getContractAddress("COLLECTIONS_REGISTRY")
        );
        registry.registerCollection(
            collectionId,
            name,
            owner,
            newContract,
            blueprintName,
            latestBlueprintVersion[blueprintName]
        );
    }

    function getLatestBlueprint(string calldata blueprintName_)
        public
        view
        virtual
        override
        returns (address)
    {
        return
            blueprints[blueprintName_][latestBlueprintVersion[blueprintName_]];
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./ERC1967UpgradeSimplified.sol";
import "./Proxy.sol";
import "./UpgradeableBeacon.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from a {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967UpgradeSimplified {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializating the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {UpgradeableBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        require(
            _BEACON_SLOT ==
                bytes32(uint256(keccak256("eip1967.proxy.beacon")) - 1),
            "BeaconProxy: _BEACON_SLOT err"
        );
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
    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return UpgradeableBeacon(_getBeacon()).implementation();
    }

    function _beforeFallback() internal virtual override {
        UpgradeableBeacon(_getBeacon()).switchImplementationIfReady();
    }
}

//SPDX-License-Identifier: Business Source License 1.1
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @dev This contract is used in conjunction with one or more instances of {BeaconProxy} to determine their
 * implementation contract, which is where they will delegate all function calls.
 *
 * An owner is able to change the implementation the beacon points to, thus upgrading the proxies that use this beacon.
 */
contract UpgradeableBeacon is Ownable, IBeacon {
    address private _implementation;
    address private _implementationCandidate;

    uint256 internal immutable _implementationSwitchWindow;
    uint256 internal immutable _implementationSwitchDelay;
    uint256 internal _nextSwitch;

    /**
     * @dev Emitted when the implementation returned by the beacon is changed.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Emitted when new implementation candidate is registered.
     */
    event NewCandidate(address indexed implementation);

    /**
     * @dev Sets the address of the initial implementation, and the deployer account as the owner who can upgrade the
     * beacon.
     */
    constructor(address implementation_) {
        _setImplementation(implementation_);

        _implementationSwitchWindow = 60 * 60 * 24; // switch implementation once per day
        _implementationSwitchDelay = 0; // just after midnight UTC
    }

    function _switchIfRequired() internal {
        // solhint-disable not-rely-on-time
        if (
            _implementationCandidate != address(0) &&
            block.timestamp >= _nextSwitch
        ) {
            _implementation = _implementationCandidate;
            _implementationCandidate = address(0);
            _nextSwitch = 0;
        }
    }

    /**
     * @dev Returns (and update if required) the current implementation address.
     */
    function implementation() public view virtual override returns (address) {
        return _implementation;
    }

    function switchImplementationIfReady() public virtual {
        _switchIfRequired();
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
    function upgradeTo(address newImplementation, bool forceUpdate)
        public
        virtual
        onlyOwner
    {
        _setCandidate(newImplementation);
        if (forceUpdate) {
            _nextSwitch = block.timestamp + 1;
        } else {
            uint256 window = ((block.timestamp + _implementationSwitchDelay) /
                _implementationSwitchWindow) + 1;
            _nextSwitch = window * _implementationSwitchWindow;
        }
        emit NewCandidate(newImplementation);
    }

    /**
     * @dev Changes implementation of a blueprint to zero address
     *
     * Emits an {Upgraded} event.
     *
     * Requirements:
     *
     * - msg.sender must be the owner of the contract.
     */
    function deregister() public virtual onlyOwner {
        _implementation = address(0);
        emit Upgraded(address(0));
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setImplementation(address newImplementation) private {
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newImplementation),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementation = newImplementation;
    }

    /**
     * @dev Sets the implementation contract address for this beacon
     *
     * Requirements:
     *
     * - `newImplementation` must be a contract.
     */
    function _setCandidate(address newImplementationCandidate) private {
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newImplementationCandidate),
            "UpgradeableBeacon: implementation is not a contract"
        );
        _implementationCandidate = newImplementationCandidate;
    }
}

//SPDX-License-Identifier: Business Source License 1.1
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeSimplified {
    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

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
        // solhint-disable-next-line reason-string
        require(
            Address.isContract(newBeacon),
            "ERC1967: new beacon is not a contract"
        );
        // solhint-disable-next-line reason-string
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
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(
                IBeacon(newBeacon).implementation(),
                data
            );
        }
    }
}

//SPDX-License-Identifier: Business Source License 1.1
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/Proxy.sol)

pragma solidity ^0.8.9;

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
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )

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
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
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
     * If overriden should call `super._beforeFallback()`.
     */

    // solhint-disable no-empty-blocks
    function _beforeFallback() internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./interfaces/ISystemContext.sol";
import "./interfaces/IFeeCollector.sol";

contract FeeCollector is IFeeCollector {
    uint256 public minimumFee;
    uint256 public feeInPercents;
    ISystemContext public immutable systemContext;

    event Received(address indexed from, uint256 value);

    constructor(
        ISystemContext systemContext_,
        uint256 minimumFee_,
        uint256 feeInPercents_
    ) {
        systemContext = systemContext_;
        minimumFee = minimumFee_;
        feeInPercents = feeInPercents_;
    }

    function applyFeeAndRefund(
        uint256 diff_,
        uint256 valueReturned_,
        address payable refundAddress_
    )
        external
        virtual
        override
        onlyRole(systemContext.omniteAccessControl().BRIDGE_ROLE())
    {
        uint256 fee = (diff_ * feeInPercents) / 100;
        if (fee < minimumFee) {
            fee = minimumFee;
        }

        //TODO: it should be impossible for user to not pay the fee. Additional check in OmniteBridgeSender required
        if (valueReturned_ < fee) {
            refundAddress_.transfer(valueReturned_ - fee);
        }
    }

    /**
     * @dev Returns balance of native asset.
     */
    function nativeBalance() external view virtual override returns (uint256) {
        return address(this).balance;
    }

    function withdrawTo(address payable receiver)
        external
        onlyRole(
            systemContext
                .omniteAccessControl()
                .FEE_COLLECTOR_DEFAULT_ADMIN_ROLE()
        )
    {
        require(receiver != address(0), "incorrect address.");
        receiver.transfer(payable(address(this)).balance);
    }

    modifier onlyRole(bytes32 role_) {
        systemContext.omniteAccessControl().checkRole(role_, msg.sender);
        _;
    }

    function setMinimumFee(uint256 minimumFee_)
        external
        virtual
        override
        onlyRole(
            systemContext
                .omniteAccessControl()
                .FEE_COLLECTOR_DEFAULT_ADMIN_ROLE()
        )
    {
        minimumFee = minimumFee_;
    }

    function setFeeInPercents(uint256 feeInPercents_)
        external
        virtual
        override
        onlyRole(
            systemContext
                .omniteAccessControl()
                .FEE_COLLECTOR_DEFAULT_ADMIN_ROLE()
        )
    {
        feeInPercents = feeInPercents_;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/ERC721/IERC721OmniteFacet.sol";
import "../../../../libraries/BytesLib.sol";

library LibERC721Omnite {
    modifier ensureIsContract(address tokenAddr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(tokenAddr)
        }
        // solhint-disable-next-line reason-string
        require(size > 0, "LibERC721Omnite: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibERC721Omnite: invoking error");
            }
        }
    }

    function collectionId(address tokenAddress)
        internal
        view
        ensureIsContract(tokenAddress)
        returns (bytes32 _collectionId)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddress.staticcall(
            abi.encodeWithSelector(IERC721OmniteFacet.collectionId.selector)
        );

        requireSuccess(success, result);
        return BytesLib.toBytes32(result, 0);
    }

    function contractURI(address tokenAddress)
        external
        view
        ensureIsContract(tokenAddress)
        returns (string memory uri)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddress.staticcall(
            abi.encodeWithSelector(IERC721OmniteFacet.collectionId.selector)
        );

        requireSuccess(success, result);
        return abi.decode(result, (string));
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../interfaces/accessControlList/IAccessControlBytes.sol";
import "../utils/ContextBytes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../libraries/BytesLib.sol";

abstract contract OmniteAccessControl is
    IAccessControlBytes,
    ERC165,
    ContextBytes
{
    bytes32 public constant CONTROL_LIST_ADMIN_ROLE =
        keccak256("CONTROL_LIST_ADMIN_ROLE");
    bytes32 public constant BRIDGE_DEFAULT_ADMIN_ROLE =
        keccak256("BRIDGE_DEFAULT_ADMIN_ROLE");
    bytes32 public constant SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE =
        keccak256("SYSTEM_CONTEXT_DEFAULT_ADMIN_ROLE");
    bytes32 public constant FEE_COLLECTOR_DEFAULT_ADMIN_ROLE =
        keccak256("FEE_COLLECTOR_DEFAULT_ADMIN_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE =
        keccak256("COLLECTION_REGISTRY_DEFAULT_ADMIN_ROLE");
    bytes32 public constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
    bytes32 public constant TOKEN_DEFAULT_ADMIN_ROLE =
        keccak256("TOKEN_DEFAULT_ADMIN_ROLE");

    bytes32 public constant SYSTEM_CONTEXT_ROLE =
        keccak256("SYSTEM_CONTEXT_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant CONTRACT_FACTORY_ROLE =
        keccak256("CONTRACT_FACTORY_ROLE");
    bytes32 public constant COLLECTION_REGISTRY_ROLE =
        keccak256("COLLECTION_REGISTRY_ROLE");
    bytes32 public constant ACCESS_CONTROL_ROLE =
        keccak256("ACCESS_CONTROL_ROLE");
    bytes32 public constant OWNER_VERIFIER_ROLE =
        keccak256("OWNER_VERIFIER_ROLE");
    bytes32 public constant OMNITE_TOKEN_ROLE = keccak256("OMNITE_TOKEN_ROLE");

    bytes32 public constant FEE_COLLECTOR_ROLE =
        keccak256("FEE_COLLECTOR_ROLE");
    bytes32 public constant NATIVE_TOKEN_ROLE = keccak256("NATIVE_TOKEN_ROLE");
    bytes32 public constant NON_NATIVE_TOKEN_ROLE =
        keccak256("NON_NATIVE_TOKEN_ROLE");

    struct RoleData {
        mapping(bytes => bool) members;
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
        _checkRole(role, _msgSenderBytes());
        _;
    }

    function checkRole(bytes32 role, address account)
        external
        view
        virtual
        override
    {
        return _checkRole(role, toBytes(account));
    }

    function checkRoleBytes(bytes32 role, bytes memory account) external view {
        return _checkRole(role, account);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        override
        returns (bool)
    {
        return hasRoleBytes(role, toBytes(account));
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRoleBytes(bytes32 role, bytes memory account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    function toBytes(address a) public pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, bytes memory account) internal view {
        if (!hasRoleBytes(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "OmniteAccessControl: account ",
                        toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    function toHexString(bytes memory account)
        internal
        pure
        returns (string memory)
    {
        if (account.length == 20) {
            // all eth based addresses
            return
                Strings.toHexString(
                    uint256(uint160(BytesLib.toAddress(account, 0)))
                );
        } else if (account.length <= 32) {
            // most of other addresses if not all of them
            return Strings.toHexString(uint256(BytesLib.toBytes32(account, 0)));
        }
        return string(account); // not supported, just return raw bytes (shouldn't happen)
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGrantedBytes}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRoleBytes(role, account);
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
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from bytes `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevokedBytes} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRoleBytes(bytes32 role, bytes memory account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRoleBytes(role, account);
    }

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
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        // solhint-disable-next-line reason-string
        require(
            keccak256(toBytes(account)) == keccak256(_msgSenderBytes()),
            "OmniteAccessControl: can only renounce roles for self"
        );

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

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _grantRoleBytes(bytes32 role, bytes memory account) private {
        if (!hasRoleBytes(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGrantedBytes(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[toBytes(account)] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function _revokeRoleBytes(bytes32 role, bytes memory account) private {
        if (hasRoleBytes(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevokedBytes(role, account, _msgSender());
        }
    }

    function bytesToAddress(bytes memory bys)
        public
        pure
        returns (address addr)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := mload(add(bys, 20))
        }
    }

    function grantNativeTokenRole(address addr) external {
        grantRole(NATIVE_TOKEN_ROLE, addr);
    }

    function grantNonNativeTokenRole(address addr) external {
        grantRole(NON_NATIVE_TOKEN_ROLE, addr);
    }

    function setRoleAdmin(bytes32 role, bytes32 adminRole)
        external
        onlyRole(CONTROL_LIST_ADMIN_ROLE)
    {
        _setRoleAdmin(role, adminRole);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../storage/AppStorage.sol";
import "../libraries/LibERC721.sol";
import "../../../../interfaces/diamond/ERC721/IERC721BurnableFacet.sol";
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";

contract ERC721BurnableFacet is IERC721BurnableFacet {
    AppStorage internal s;

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    function burn(address tokenAddr, uint256 tokenId)
        external
        virtual
        override
    {
        address sender = LibMeta.msgSender();
        LibERC721.isApprovedOrOwner(tokenAddr, sender, tokenId);

        address owner = s.erc721Base.owners[tokenId];
        // Clear approvals
        LibERC721.approve(tokenAddr, address(0), tokenId);

        s.erc721Base.balances[owner] -= 1;
        delete s.erc721Base.owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721BurnableFacet {
    function burn(address tokenAddr, uint256 tokenId) external;
}

//SPDX-License-Identifier: Business Source License 1.1

import {AppStorage} from "../storage/AppStorage.sol";
import {LibMeta} from "../../../../libraries/diamond/LibMeta.sol";
import "../../../../interfaces/diamond/IAccessControlListFacet.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

pragma solidity ^0.8.9;

contract AccessControlListFacet is IAccessControlListFacet {
    AppStorage internal s;

    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return s.acl.roles[role].members[account];
    }

    function checkRole(bytes32 role, address account)
        public
        view
        virtual
        override
    {
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

    function checkRole(bytes32 role) internal view virtual {
        address sender = LibMeta.msgSender();
        checkRole(role, sender);
    }

    modifier onlyRole(bytes32 role) {
        checkRole(role);
        _;
    }

    function _grantRole(bytes32 role, address account) internal virtual {
        address sender = LibMeta.msgSender();
        if (!hasRole(role, account)) {
            s.acl.roles[role].members[account] = true;
            emit RoleGranted(role, account, sender);
        }
    }

    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return s.acl.roles[role].adminRole;
    }

    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        address sender = LibMeta.msgSender();
        // solhint-disable-next-line reason-string
        require(
            account == sender,
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    function _revokeRole(bytes32 role, address account) internal virtual {
        address sender = LibMeta.msgSender();
        if (hasRole(role, account)) {
            s.acl.roles[role].members[account] = false;
            emit RoleRevoked(role, account, sender);
        }
    }

    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        s.acl.roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../../../../interfaces/diamond/ERC721/IERC721BurnableFacet.sol";

library LibERC721Burnable {
    modifier ensureIsContract(address tokenAddr) {
        uint256 size;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(tokenAddr)
        }
        // solhint-disable-next-line reason-string
        require(size > 0, "LibERC721Burnable: Address has no code");

        _;
    }

    function requireSuccess(bool success, bytes memory err) internal pure {
        if (!success) {
            if (bytes(err).length > 0) {
                revert(abi.decode(err, (string)));
            } else {
                // solhint-disable-next-line reason-string
                revert("LibERC721Burnable: invoking error");
            }
        }
    }

    function burn(address tokenAddr, uint256 tokenId)
        internal
        ensureIsContract(tokenAddr)
    {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory result) = tokenAddr.call(
            abi.encodeWithSelector(IERC721BurnableFacet.burn.selector, tokenId)
        );

        requireSuccess(success, result);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {AppStorage} from "../AppStorage.sol";
import "../../../../interfaces/diamond/ERC721/IERC721WithSlotsFacet.sol";

contract ERC721WithSlotsFacet is IERC721WithSlotsFacet {
    AppStorage internal s;

    function getSlots()
        external
        view
        virtual
        override
        returns (uint256, uint256)
    {
        return (s.slotsStart, s.slotsEnd);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

interface IERC721WithSlotsFacet {
    function getSlots() external view returns (uint256, uint256);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./AppStorage.sol";
import "../../../interfaces/diamond/IDiamondLoupe.sol";
import "../../../interfaces/diamond/IDiamondCut.sol";
import "../../../libraries/diamond/LibDiamond.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../../../interfaces/IInitializable.sol";

contract ERC721Native is IInitializable {
    AppStorage internal s;

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    modifier onlyIfNotInitialized() {
        if (s.initialized) {
            revert AlreadyInitialized();
        }
        _;

        s.initialized = true;
    }

    function encode(
        address _systemContextAddress,
        string memory _name,
        string memory _symbol,
        address _owner,
        string memory _contractURI,
        string memory _baseTokenURI,
        uint256 _slotStart,
        uint256 _slotEnd,
        IDiamondCut.FacetCut[] memory _diamondCut
    ) public pure returns (bytes memory) {
        bytes memory encodedParams = abi.encode(
            _systemContextAddress,
            _name,
            _symbol,
            _owner,
            _contractURI,
            _baseTokenURI,
            _slotStart,
            _slotEnd,
            _diamondCut
        );

        return abi.encodeWithSelector(this.initialize.selector, encodedParams);
    }

    function initialize(bytes memory initializerEncoded_)
        external
        onlyIfNotInitialized
    {
        (
            address _systemContextAddress,
            string memory _name,
            string memory _symbol,
            address _owner,
            string memory _contractURI,
            string memory _baseTokenURI,
            uint256 _slotStart,
            uint256 _slotEnd,
            IDiamondCut.FacetCut[] memory _diamondCut
        ) = abi.decode(
                initializerEncoded_,
                (
                    address,
                    string,
                    string,
                    address,
                    string,
                    string,
                    uint256,
                    uint256,
                    IDiamondCut.FacetCut[]
                )
            );

        LibDiamond.diamondCutWithoutInit(_diamondCut);
        // TODO:  who should be the owner of the contract?
        LibDiamond.setContractOwner(_owner);

        s.erc721Base.symbol = _symbol;
        s.erc721Base.name = _name;
        s.diamondAddress = address(this);
        s.systemContextAddress = _systemContextAddress;
        s.acl.roles[keccak256("MINTER_ROLE")].members[_owner] = true;
        s.acl.roles[DEFAULT_ADMIN_ROLE].members[_owner] = true;
        s.acl.roles[keccak256("MINTER_ROLE")].adminRole = DEFAULT_ADMIN_ROLE;
        s.slotsStart = _slotStart;
        s.slotsEnd = _slotEnd;
        s.baseTokenURI = _baseTokenURI;

        if (bytes(_contractURI).length > 0) {
            s.contractURIOptional = _contractURI;
        }

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Metadata).interfaceId] = true;
        ds.supportedInterfaces[type(IERC721Receiver).interfaceId] = true;
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "../../libraries/diamond/LibDiamond.sol";

contract OwnershipFacet {
    function transferOwnership(address _newOwner) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {LibDiamond} from "../../libraries/diamond/LibDiamond.sol";
import {IDiamondLoupe} from "../../interfaces/diamond/IDiamondLoupe.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";

// The functions in DiamondLoupeFacet MUST be added to a diamond.
// The EIP-2535 Diamond standard requires these functions.

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }

    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numFacets = ds.facetAddresses.length;
        facets_ = new Facet[](numFacets);
        for (uint256 i; i < numFacets; i++) {
            address facetAddress_ = ds.facetAddresses[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = ds
                .facetFunctionSelectors[facetAddress_]
                .functionSelectors;
        }
    }

    /// @notice Gets all the function selectors provided by a facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet)
        external
        view
        override
        returns (bytes4[] memory facetFunctionSelectors_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetFunctionSelectors_ = ds
            .facetFunctionSelectors[_facet]
            .functionSelectors;
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = ds.facetAddresses;
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector)
        external
        view
        override
        returns (address facetAddress_)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        override
        returns (bool)
    {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

//SPDX-License-Identifier: Business Source License 1.1
import "./diamond/IDiamondCut.sol";

pragma solidity ^0.8.9;

interface IDiamondFacetsRegistry {
    error FacetsNotRegistered(bytes32 facetsId);
    error FacetsAlreadyRegistered(bytes32 facetsId);
    error FacetsDataEmpty();

    event FacetsRegistered(bytes32 _facetId);
    event FacetsUpdated(bytes32 _facetId);
    event FacetsUnregistered(bytes32 _facetId);
    struct FacetCutData {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    struct FacetCutDataPack {
        bytes32 id;
        FacetCutData[] facets;
    }

    function registerFacets(bytes32 _facetId, FacetCutData[] memory _facetData)
        external;

    function addToRegistry(bytes32 _facetId, FacetCutData[] memory _facetData)
        external;

    function registerFacetPacks(FacetCutDataPack[] memory packs) external;

    function overrideFacetPacks(FacetCutDataPack[] memory packs) external;

    function facetRegistered(bytes32 _facetId) external view returns (bool);

    function unregisterFacets(bytes32 _facetId) external;
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "./interfaces/IDiamondFacetsRegistry.sol";
import "./acl/OmniteAccessControl.sol";

contract DiamondFacetsRegistry is IDiamondFacetsRegistry {
    OmniteAccessControl internal acl_;
    mapping(bytes32 => FacetCutData[]) internal facetsData_;

    constructor(OmniteAccessControl _acl) {
        acl_ = _acl;
    }

    function facetRegistered(bytes32 _facetId) public view returns (bool) {
        return facetsData_[_facetId].length != 0;
    }

    function getFacetCutData(bytes32 _facetId)
        external
        view
        returns (FacetCutDataPack memory)
    {
        FacetCutData[] memory facetCutData = facetsData_[_facetId];
        return FacetCutDataPack({id: _facetId, facets: facetCutData});
    }

    modifier facetsAreNotRegistered(bytes32 _facetId) {
        if (facetRegistered(_facetId)) {
            revert FacetsAlreadyRegistered(_facetId);
        }
        _;
    }

    function enusreFacetAreRegistered(bytes32 _facetId) internal view {
        if (!facetRegistered(_facetId)) {
            revert FacetsNotRegistered(_facetId);
        }
    }

    modifier facetsAreRegistered(bytes32 _facetId) {
        enusreFacetAreRegistered(_facetId);
        _;
    }

    modifier hasFacetsRegistryEditorRole() {
        acl_.checkRole(acl_.FACETS_REGISTRY_EDITOR_ROLE(), msg.sender);
        _;
    }

    function registerFacets(bytes32 _facetId, FacetCutData[] memory _facetData)
        public
        override
        hasFacetsRegistryEditorRole
    {
        registerFacets_(_facetId, _facetData);
    }

    function registerFacets_(bytes32 _facetId, FacetCutData[] memory _facetData)
        internal
        facetsAreNotRegistered(_facetId)
    {
        FacetCutData[] storage facetsData = facetsData_[_facetId];
        for (uint128 i = 0; i < _facetData.length; ++i) {
            facetsData.push(_facetData[i]);
        }

        emit FacetsRegistered(_facetId);
    }

    function addToRegistry(bytes32 _facetId, FacetCutData[] memory _facetData)
        external
        override
        facetsAreRegistered(_facetId)
        hasFacetsRegistryEditorRole
    {
        if (_facetData.length == 0) {
            revert FacetsDataEmpty();
        }

        FacetCutData[] storage facets = facetsData_[_facetId];

        for (uint256 i = 0; i < _facetData.length; ++i) {
            facets.push(_facetData[i]);
        }

        emit FacetsUpdated(_facetId);
    }

    function registerFacetPacks(FacetCutDataPack[] memory packs)
        external
        override
        hasFacetsRegistryEditorRole
    {
        for (uint256 i = 0; i < packs.length; ++i) {
            FacetCutDataPack memory pack = packs[i];
            registerFacets_(pack.id, pack.facets);
        }
    }

    function overrideFacetPacks(FacetCutDataPack[] memory packs)
        external
        override
        hasFacetsRegistryEditorRole
    {
        if (packs.length == 0) {
            revert FacetsDataEmpty();
        }

        for (uint256 packIndex = 0; packIndex < packs.length; ++packIndex) {
            FacetCutDataPack memory pack = packs[packIndex];
            enusreFacetAreRegistered(pack.id);

            FacetCutData[] memory facets = pack.facets;
            for (
                uint256 facetIndex = 0;
                facetIndex < facets.length;
                ++facetIndex
            ) {
                facetsData_[pack.id].push(facets[facetIndex]);
            }
        }
    }

    function unregisterFacets(bytes32 _facetId)
        external
        override
        hasFacetsRegistryEditorRole
        facetsAreRegistered(_facetId)
    {
        delete facetsData_[_facetId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import {IDiamondCut} from "../../interfaces/diamond/IDiamondCut.sol";
import {LibDiamond} from "../../libraries/diamond/LibDiamond.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }

    function diamondCutWithoutInit(FacetCut[] calldata _diamondCut)
        external
        override
    {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.diamondCutWithoutInit(_diamondCut);
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../IInitializable.sol";

interface IERC721NativeInitializable is IInitializable {
    function encodeInitializer(
        string memory name_,
        string memory symbol_,
        address owner_,
        uint256 slotStart_,
        uint256 slotEnd_,
        string memory baseTokenURI_,
        string memory contractURI_
    ) external view returns (bytes memory);

    // solhint-disable-next-line func-name-mixedcase
    function decodeInitializer_ERC721Native(bytes calldata initializerEncoded_)
        external
        view
        returns (
            string memory,
            string memory,
            address,
            uint256,
            uint256,
            string memory,
            string memory
        );
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import "../IInitializable.sol";

interface IERC721NonNativeInitializable is IInitializable {
    function encodeInitializer(
        string memory name_,
        string memory symbol_,
        address owner_,
        string memory contractURI_
    ) external pure returns (bytes memory);

    // solhint-disable-next-line func-name-mixedcase
    function decodeInitializer_ERC721NonNative(
        bytes calldata initializerEncoded_
    )
        external
        pure
        returns (
            string memory,
            string memory,
            address,
            string memory
        );
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            //solhint-disable-next-line no-inline-assembly
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string public constant ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        //solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

contract Initializable {
    bool public inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) internal nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        //solhint-disable-next-line reason-string
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        //solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        //solhint-disable-next-line reason-string
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.9;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

interface ILayerZeroBridge is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

//SPDX-License-Identifier: Business Source License 1.1

pragma solidity ^0.8.9;

bytes32 constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
bytes32 constant TOKEN_UNLOCK_ROLE = keccak256("TOKEN_UNLOCK_ROLE");
bytes32 constant MINTER_ROLE = keccak256("MINTER_ROLE");

struct ERC721MintableStorage {
    string contractURIOptional;
}