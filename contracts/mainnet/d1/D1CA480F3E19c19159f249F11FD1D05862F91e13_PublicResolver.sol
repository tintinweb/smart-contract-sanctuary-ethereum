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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/IAddressResolver.sol";

abstract contract AddressResolver is IAddressResolver, ResolverBase {
    uint256 private constant COIN_TYPE_ETH = 60;

    mapping(bytes32 => mapping(uint256 => bytes)) _addresses;

    function setAddr(bytes32 node, address a)
        external
        authorized(node)
    {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    function addr(bytes32 node)
        public
        view
        override
        returns (address)
    {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return address(0);
        }
        return bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint256 coinType,
        bytes memory a
    ) public authorized(node) {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint256 coinType)
        public
        view
        override
        returns (bytes memory)
    {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(IAddressResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b)
        internal
        pure
        returns (address a)
    {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAddressResolver {
    event AddressChanged(
        bytes32 indexed node,
        uint256 coinType,
        bytes newAddress
    );

    function addr(bytes32 node)
        external
        view
        returns (address);

    function addr(bytes32 node, uint256 coinType)
        external
        view
        returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ITextResolver {
    event TextChanged(
        bytes32 indexed node,
        string indexed indexedKey,
        string key
    );

    function text(bytes32 node, string calldata key)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IWeb3Registry {
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/INameResolver.sol";

abstract contract NameResolver is INameResolver, ResolverBase {
    mapping(bytes32 => string) names;

    function setName(bytes32 node, string calldata newName)
        external
        virtual
        authorized(node)
    {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    function name(bytes32 node)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(INameResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./NameResolver.sol";
import "./TextResolver.sol";
import "./AddressResolver.sol";
import "./interfaces/IWeb3Registry.sol";

contract PublicResolver is NameResolver, AddressResolver, TextResolver {
    address immutable trustedReverseRegistrar;
    address immutable trustedETHController;
    IWeb3Registry public registry;

    mapping(address => mapping(address => bool)) private _operatorApprovals;

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    constructor(
        IWeb3Registry _registry,
        address _trustedETHController,
        address _trustedReverseRegistrar
    ) {
        registry = _registry;
        trustedETHController = _trustedETHController;
        trustedReverseRegistrar = _trustedReverseRegistrar;
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address account, address operator)
        public
        view
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    function isAuthorized(bytes32 node) internal view override returns (bool) {
        if (
            msg.sender == trustedETHController ||
            msg.sender == trustedReverseRegistrar
        ) {
            return true;
        }
        address owner = registry.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        override(NameResolver, AddressResolver, TextResolver)
        returns (bool)
    {
        return super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract ResolverBase is ERC165 {
    function isAuthorized(bytes32 node) internal view virtual returns (bool);

    modifier authorized(bytes32 node) {
        require(isAuthorized(node), "not authorized");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./ResolverBase.sol";
import "./interfaces/ITextResolver.sol";

abstract contract TextResolver is ITextResolver, ResolverBase {
    mapping(bytes32 => mapping(string => string)) texts;

    function setText(
        bytes32 node,
        string calldata key,
        string calldata value
    ) external virtual authorized(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    function text(bytes32 node, string calldata key)
        external
        view
        virtual
        override
        returns (string memory)
    {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceID == type(ITextResolver).interfaceId ||
            super.supportsInterface(interfaceID);
    }
}