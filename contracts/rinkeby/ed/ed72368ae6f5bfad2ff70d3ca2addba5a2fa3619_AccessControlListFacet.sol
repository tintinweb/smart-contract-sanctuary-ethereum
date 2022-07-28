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