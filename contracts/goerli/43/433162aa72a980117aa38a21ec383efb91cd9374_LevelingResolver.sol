// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: BSD-2-Clause
pragma solidity ^0.8.0;

interface ICRS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SupportsInterface.sol";

/**
 * @dev All resolver profiles inherit from BaseResolver to make auth checks.
 */
abstract contract BaseResolver is SupportsInterface {
    /**
     * @dev Checks if caller is either an owner of a node or approved by the owner.
     * @param node 3rd party controller of metadata.
     * @return true if access is authorized.
     */
    function isAuthorised(bytes32 node) internal virtual view returns(bool);

    /**
     * @dev Allow 3rd parties to store isolated records for the node.
     * @param controller 3rd party controller of metadata.
     * @return true if access is authorized.
     */
    function isDelegated(bytes32 node, address controller) internal virtual view returns(bool);

    modifier authorised(bytes32 node) {
        require(isAuthorised(node), "access denied");
        _;
    }

    modifier delegated(bytes32 node, address controller) {
        require(isDelegated(node, controller), "not a delegate");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMulticallable {
    /**
     * @dev Execute several resolver calls in a batch.
     * @param data Array of ABI-encoded calls to resolver.
     * @return results array of call results in the same order as input.
     */
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./profile/IAddressResolver.sol";
import "./profile/INameResolver.sol";
import "./profile/ITextResolver.sol";
import "./profile/IContentHashResolver.sol";
import "./profile/IABIResolver.sol";
import "./profile/IInterfaceResolver.sol";
import "./profile/IPubkeyResolver.sol";
import "./profile/IRoyaltiesResolver.sol";
import "./profile/IProxyConfigResolver.sol";
import "./profile/IManagedResolver.sol";
import "./profile/IKeyHashResolver.sol";
import "./ISupportsInterface.sol";

/**
 * @dev A generic resolver interface which includes all the functions including the ones deprecated.
 */
interface IResolver is
    ISupportsInterface,
    IAddressResolver,
    INameResolver,
    ITextResolver,
    IContentHashResolver,
    IABIResolver,
    IInterfaceResolver,
    IPubkeyResolver,
    IRoyaltiesResolver,
    IProxyConfigResolver,
    IManagedResolver,
    IKeyHashResolver
{
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address a) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setName(bytes32 node, string calldata _name) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function setRoyalties(bytes32 node, address beneficiary, uint256 amount) external;
    function setProxyConfig(bytes32 node, address controller, bytes4 selector, address proxy) external;
    function setRole(bytes32 node, bytes4 roleSig, address manager, bool active) external;
    function setKeyHash(bytes32 node, bytes4 key, bytes32 keyhash) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupportsInterface {
    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMulticallable.sol";
import "./SupportsInterface.sol";

/**
 * @dev Make it possible to batch several resolver calls into a one transaction.
 */
abstract contract Multicallable is IMulticallable, SupportsInterface {
    /**
     * @dev Execute several resolver calls in a batch.
     * @param data Array of ABI-encoded calls to resolver.
     * @return results array of call results in the same order as input.
     */
    function multicall(bytes[] calldata data) external override returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            // solhint-disable avoid-low-level-calls
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success, "batched call failed");
            results[i] = result;
        }
        return results;
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) public override virtual pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISupportsInterface.sol";

/**
 * @dev EIP-165 implementation.
 */
abstract contract SupportsInterface is ISupportsInterface {
    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IABIResolver.sol";

/**
 * @dev See {https://eips.ethereum.org/EIPS/eip-205}.
 */
abstract contract ABIResolver is IABIResolver, BaseResolver {
    mapping(bytes32=>mapping(uint256=>bytes)) internal abis;

    /**
     * @dev Sets the ABI associated with a CRS node.
     *      Nodes may have one ABI of each content type. To remove an ABI, set it to
     *      the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) virtual external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0, "invalid bitmask");

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * @dev Returns the ABI associated with a CRS node.
     *      Defined in EIP205.
     * @param node The CRS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) virtual override external view returns (uint256, bytes memory) {
        mapping(uint256=>bytes) storage abiset = abis[node];

        for (uint256 contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && abiset[contentType].length > 0) {
                return (contentType, abiset[contentType]);
            }
        }

        return (0, bytes(""));
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IAddressResolver.sol";

/**
 * @dev Human-reable name for wallets on different networks.
 */
abstract contract AddressResolver is IAddressResolver, BaseResolver {
    uint constant private COIN_TYPE_MATIC = 137;

    mapping(bytes32=>mapping(uint=>bytes)) internal _addresses;

    /**
     * @dev Returns the address associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) virtual public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_MATIC);
        if(a.length == 0) {
            return payable(0);
        }
        return _bytesToAddress(a);
    }
    function addr(bytes32 node, uint coinType) virtual override public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    /**
     * @dev Sets the address associated with a CRS node.
     *      May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_MATIC, _addressToBytes(a));
    }

    /**
     * @dev Sets the address associated with a CRS node.
     *      May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param coinType Chain id to set address.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IAddressResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    /**
     * @dev Convert from bytes to address type.
     * @param b Address encoded as bytes.
     * @return a decoded address.
     */
    function _bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20, "not an address");
        // solhint-disable no-inline-assembly
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    /**
     * @dev Convert from address to bytes type.
     * @param a Address to encode
     * @return b encoded address.
     */
    function _addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        // solhint-disable no-inline-assembly
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IContentHashResolver.sol";

/**
 * @dev URL / content hash associated with a node, usually a website or IPFS link.
 */
abstract contract ContentHashResolver is IContentHashResolver, BaseResolver {
    mapping(bytes32=>bytes) internal hashes;

    /**
     * @dev Sets the contenthash associated with a CRS node.
     *      May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) virtual external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * @dev Returns the contenthash associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) virtual external override view returns (bytes memory) {
        return hashes[node];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IContentHashResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    
    /**
     * @dev Returns the ABI associated with an ENS node.
     *      Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface for addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    /**
     * @dev Returns the address associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * @dev Returns the contenthash associated with a CRS node.
     * @param node The CRS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * @dev Returns the address of a contract that implements the specified interface for this name.
     *      If an implementer has not been set for this interfaceID and name, the resolver will query
     *      the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     *      contract implements EIP165 and returns `true` for the specified interfaceID, its address
     *      will be returned.
     * @param node The CRS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IKeyHashResolver {
    event KeyHashChanged(bytes32 indexed node, bytes4 indexed key, bytes32 keyhash);

    /**
     * @dev Returns the hash associated with a CRS node for a key.
     * @param node The CRS node to query.
     * @param key bytes4 signature of a key generated like bytes4(keccak256("KEY")).
     * @return The associated hash.
     */
    function keyHash(bytes32 node, bytes4 key) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IManagedResolver {
    event RoleChanged(
        bytes32 indexed node,
        bytes4 indexed roleSig,
        address indexed manager,
        bool active
    );

    /**
     * @dev Check if manager address has some role.
     * @param _node the node to update.
     * @param _roleSig bytes4 signature of a role generated like bytes4(keccak256("ROLE_NAME")).
     * @param _manager address which will get the role.
     * @return true if manager address has role.
     */
    function hasRole(bytes32 _node, bytes4 _roleSig, address _manager) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * @dev Returns the name associated with a CRS node, for reverse records.
     *      Defined in EIP181.
     * @param node The CRS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyConfigResolver {
    event ProxyConfigChanged(bytes32 indexed node, address indexed controller, bytes4 indexed selector, address proxy);

    /**
     * @dev Returns proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @return Address which implements proxy interface.
     */
    function proxyConfig(bytes32 node, address controller, bytes4 selector) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * @dev Returns the SECP256k1 public key associated with a CRS node.
     *      Defined in EIP 619.
     * @param node The CRS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltiesResolver {
    event RoyaltiesChanged(
        bytes32 indexed node,
        address indexed beneficiary,
        uint256 amount,
        address token,
        address indexed forAddress
    );

    /**
     * @dev Returns the royalties associated with a CRS node.
     * @param node The CRS node to query
     * @param addr Specific address for which royalties apply, address(0) for any address.
     * @return beneficiary address for royalties.
     * @return amount of roylties.
     * @return token, address(0) for gas coin
     */
    function royalty(bytes32 node, address addr) external view returns (address, uint256, address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string value);

    /**
     * Returns the text data associated with a CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ISupportsInterface.sol";
import "./AddressResolver.sol";
import "./IInterfaceResolver.sol";

/**
 * @dev Defines a proxy address which implements specific EIP 165 interface associated with a node.
 */
abstract contract InterfaceResolver is IInterfaceResolver, AddressResolver {
    mapping(bytes32=>mapping(bytes4=>address)) internal interfaces;

    /**
     * @dev Sets an interface associated with a name.
     *      Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) virtual external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * @dev Returns the address of a contract that implements the specified interface for this name.
     *      If an implementer has not been set for this interfaceID and name, the resolver will query
     *      the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     *      contract implements EIP165 and returns `true` for the specified interfaceID, its address
     *      will be returned.
     * @param node The CRS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) virtual override external view returns (address) {
        address implementer = interfaces[node][interfaceID];
        if(implementer != address(0)) {
            return implementer;
        }

        address a = addr(node);
        if(a == address(0)) {
            return address(0);
        }

        (bool success, bytes memory returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", type(ISupportsInterface).interfaceId));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // EIP 165 not supported by target
            return address(0);
        }

        (success, returnData) = a.staticcall(abi.encodeWithSignature("supportsInterface(bytes4)", interfaceID));
        if(!success || returnData.length < 32 || returnData[31] == 0) {
            // Specified interface not supported by target
            return address(0);
        }

        return a;
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IKeyHashResolver.sol";

/**
 * @dev Storage-optimised key-value storage for bytes32 hashes.
 *      The main intended usage is storage of compressed IPFS hashes
 *      associated with different records for a node.
 *      Check `ContentHashResolver` if node needs only one record.
 */
abstract contract KeyHashResolver is IKeyHashResolver, BaseResolver {
    mapping(bytes32=>mapping(bytes4=>bytes32)) internal keyHashes;

    /**
     * @dev Sets the contenthash associated with a CRS node.
     *      May only be called by the owner of that node in the CRS registry.
     * @param _node The node to update.
     * @param _key bytes4 signature of a key generated like bytes4(keccak256("KEY")).
     * @param _keyhash Hash to store, trimmed to bytes32 storage type.
     */
    function setKeyHash(bytes32 _node, bytes4 _key, bytes32 _keyhash) virtual external authorised(_node) {
        keyHashes[_node][_key] = _keyhash;
        emit KeyHashChanged(_node, _key, _keyhash);
    }

    /**
     * @dev Returns the hash associated with a CRS node for a key.
     * @param _node The CRS node to query.
     * @param _key bytes4 signature of a key generated like bytes4(keccak256("KEY")).
     * @return The associated hash.
     */
    function keyHash(bytes32 _node, bytes4 _key) virtual external override view returns (bytes32) {
        return keyHashes[_node][_key];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IKeyHashResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "../BaseResolver.sol";
import "./IManagedResolver.sol";

/**
 * @dev Define roles or permissions associated with a node.
 */
abstract contract ManagedResolver is IManagedResolver, BaseResolver {
    mapping(bytes32 => mapping(bytes4 => mapping(address => bool))) internal managementRoles; 
    
    /**
     * @dev Assign some role to an address.
     * @param _node the node to update.
     * @param _roleSig bytes4 signature of a role generated like bytes4(keccak256("ROLE_NAME")).
     * @param _manager address which will get the role.
     * @param _active true to set role, false to revoke it.
     */
    function setRole(bytes32 _node, bytes4 _roleSig, address _manager, bool _active) virtual external authorised(_node) {
        managementRoles[_node][_roleSig][_manager] = _active;
        emit RoleChanged(_node, _roleSig, _manager, _active);
    }

    /**
     * @dev Check if manager address has some role.
     * @param _node the node to update.
     * @param _roleSig bytes4 signature of a role generated like bytes4(keccak256("ROLE_NAME")).
     * @param _manager address which will get the role.
     * @return true if manager address has role.
     */
    function hasRole(bytes32 _node, bytes4 _roleSig, address _manager) virtual override external view returns (bool) {
        return managementRoles[_node][_roleSig][_manager];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IManagedResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./INameResolver.sol";

/**
 * @dev Full name associated with a node.
 */
abstract contract NameResolver is INameResolver, BaseResolver {
    mapping(bytes32=>string) internal names;

    /**
     * Sets the name associated with a CRS node, for reverse records.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName) virtual external authorised(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with a CRS node, for reverse records.
     * Defined in EIP181.
     * @param node The CRS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) virtual override external view returns (string memory) {
        return names[node];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IProxyConfigResolver.sol";

/**
 * @dev Allows 3rd parties to associate their own records related to this node.
 *      It can be used to set game profiles, reputation scores or other data, which
 *      shouldn't be controlled by the owner of a node.
 */
abstract contract ProxyConfigResolver is IProxyConfigResolver, BaseResolver {
    mapping(bytes32=>mapping(address=>mapping(bytes4=>address))) internal proxyConfigs;

    /**
     * @dev Sets proxy contract controlled by a 3rd party with data related to this CRS.
     *      Use InterfaceResolver to define proxies for more complex interfaces.
     * @param node The node to update.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @param proxy Address which implements proxy interface.
     */
    function setProxyConfig(
        bytes32 node,
        address controller,
        bytes4 selector,
        address proxy
    ) virtual external delegated(node, controller) {
        proxyConfigs[node][controller][selector] = proxy;
        emit ProxyConfigChanged(node, controller, selector, proxy);
    }

    /**
     * @dev Returns proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @return Address which implements proxy interface.
     */
    function proxyConfig(bytes32 node, address controller, bytes4 selector) virtual override external view returns (address) {
        return proxyConfigs[node][controller][selector];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IProxyConfigResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IPubkeyResolver.sol";

/**
 * @dev Publish public key associated with a node.
 */
abstract contract PubkeyResolver is IPubkeyResolver, BaseResolver {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) internal pubkeys;

    /**
     * @dev Sets the SECP256k1 public key associated with a CRS node.
     * @param node The CRS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) virtual external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * @dev Returns the SECP256k1 public key associated with a CRS node.
     *      Defined in EIP 619.
     * @param node The CRS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IPubkeyResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IRoyaltiesResolver.sol";

/**
 * @dev Defines royalties associated with a node. Supports default and
 *      individual roylties for specific callers. Token or gas coin, amount and
 *      beneficiary are configurable, but interpetation and implementation are
 *      on a side of a caller.
 */
abstract contract RoyaltiesResolver is IRoyaltiesResolver, BaseResolver {
    struct Royalties {
        address beneficiary;
        uint256 amount;
        address token;
    }

    address public constant ZERO_ADDRESS = address(0);

    mapping(bytes32=>Royalties) internal royalties;
    mapping(bytes32=>mapping(address=>Royalties)) internal addressRoyalties;
    
    /**
     * @dev Sets the royalties associated with a CRS node, for reverse records.
     *      May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param beneficiary The associated beneficiary to recieve royalties.
     * @param amount The associated royalty amount.
     * @param token ERC20 token to charge royalites, address(0) to use gas coin.
     * @param forAddress Address which individual settings are used, address(0) for default settings.
     */
    function setRoyalties(bytes32 node, address beneficiary, uint256 amount, address token, address forAddress) virtual external authorised(node) {
        if (forAddress == address(0)) {
            royalties[node] = Royalties(beneficiary, amount, token);
        } else {
            addressRoyalties[node][forAddress] = Royalties(beneficiary, amount, token);
        }
        emit RoyaltiesChanged(node, beneficiary, amount, token, forAddress);
    }

    /**
     * @dev Returns the royalties associated with a CRS node.
     * @param node The CRS node to query.
     * @param addr Address for which royalty was set.
     * @return The associated beneficiary to recieve royalties.
     * @return The associated royalty amount.
     * @return The associated royalty token or address(0) for gas coin.
     */
    function royalty(bytes32 node, address addr) virtual override external view returns(address, uint256, address) {
        if (addr == ZERO_ADDRESS) {
            return _defaultRoyalty(node);
        } else {
            address _beneficiary = addressRoyalties[node][addr].beneficiary;
            if (_beneficiary == ZERO_ADDRESS) {
                return _defaultRoyalty(node);
            } else {
                return (_beneficiary, addressRoyalties[node][addr].amount, addressRoyalties[node][addr].token);
            }
        }
    }

    /**
     * @dev Returns default royalties
     * @param node The CRS node to query.
     * @return The associated beneficiary to recieve royalties.
     * @return The associated royalty amount.
     * @return The associated royalty token or address(0) for gas coin.
     */
    function _defaultRoyalty(bytes32 node) internal view returns(address, uint256, address) {
        return (royalties[node].beneficiary, royalties[node].amount, royalties[node].token);
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IRoyaltiesResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./ITextResolver.sol";

/**
 * @dev Flexible key-value storage for string or byte data.
 */
abstract contract TextResolver is ITextResolver, BaseResolver {
    mapping(bytes32=>mapping(string=>string)) internal texts;

    /**
     * @dev Sets the text data associated with a CRS node and key.
     *      May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, value);
    }

    /**
     * @dev Returns the text data associated with a CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) virtual override external view returns (string memory) {
        return texts[node][key];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ITextResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface IERC1155Burnable {
    function burn(address account, uint256 id, uint256 value) external; // 0xf5298aca
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface IERC20 {
    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface IERC20BurnableV1 {
    function burnFrom(address account, uint256 value) external; // 0x79cc6790
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface IERC20BurnableV2 {
    function burn(address account, uint256 value) external; // 0x9dc29fac
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@le7el/web3_crs/contracts/registry/ICRS.sol";
import "@le7el/web3_crs/contracts/resolver/IResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/AddressResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/ContentHashResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/NameResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/TextResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/InterfaceResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/ABIResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/PubkeyResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/RoyaltiesResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/ProxyConfigResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/ManagedResolver.sol";
import "@le7el/web3_crs/contracts/resolver/profile/KeyHashResolver.sol";
import "@le7el/web3_crs/contracts/resolver/Multicallable.sol";
import "./profile/LevelResolver.sol";

/** 
 * @dev All default features of CRS resolver, with leveling system, controllable by 3rd party,
 *      see `profile/LevelResolver.sol` for details.
 */
contract LevelingResolver is 
    Multicallable,
    AddressResolver,
    ContentHashResolver,
    NameResolver,
    TextResolver,
    InterfaceResolver,
    ABIResolver,
    PubkeyResolver,
    RoyaltiesResolver,
    ProxyConfigResolver,
    ManagedResolver,
    KeyHashResolver,
    LevelResolver
{
    ICRS crs;

    /**
     * A mapping of operators. An address that is authorised for an address
     * may make any changes to the name that the owner could, but may not update
     * the set of authorisations.
     * (owner, operator) => approved
     */
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    constructor(ICRS _crs) {
        crs = _crs;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) external {
        require(
            msg.sender != operator,
            "ERC1155: can't self-approve"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev Checks if caller is either an owner of a node or approved by the owner.
     * @param node 3rd party controller of metadata.
     * @return true if access is authorized.
     */
    function isAuthorised(bytes32 node) internal override view returns(bool) {
        address owner = crs.owner(node);
        return owner == msg.sender || isApprovedForAll(owner, msg.sender);
    }

    /**
     * @dev Allow 3rd parties to store isolated records for the node.
     * @param controller 3rd party controller of metadata.
     * @return true if access is authorized.
     */
    function isDelegated(bytes32, address controller) internal override view returns(bool) {
        return controller == msg.sender;
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) public override(
        Multicallable,
        AddressResolver,
        ContentHashResolver,
        NameResolver,
        TextResolver,
        InterfaceResolver,
        ABIResolver,
        PubkeyResolver,
        RoyaltiesResolver,
        ProxyConfigResolver,
        ManagedResolver,
        KeyHashResolver,
        LevelResolver
    ) pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface ILevelResolver {
    event AdvancedToNextLevel(
        bytes32 indexed project,
        bytes32 indexed node,
        uint256 newExperience,
        uint256 totalExperience
    );

    event ProjectLevelingRulesChanged(
        bytes32 indexed project,
        bytes4 indexed burnInterface,
        address indexed experienceToken,
        uint256 experienceTokenId,
        address levelingFormulaProxy
    );

    /**
     * @dev Level based on experience.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return level based on experience
     */
    function level(bytes32 _project, bytes32 _node) external view returns (uint256);

    /**
     * @dev Experience in scope of project.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return project experience
     */
    function experience(bytes32 _project, bytes32 _node) external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

interface ILevelingFormula {
    /**
     * @dev Get level based on experience.
     * @param _experience experience points.
     * @return user level based on experience.
     */
    function expToLevel(uint256 _experience) external view returns (uint256);
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@le7el/web3_crs/contracts/resolver/BaseResolver.sol";
import "../../interface/IERC20.sol";
import "../../interface/IERC1155Burnable.sol";
import "../../interface/IERC20BurnableV1.sol";
import "../../interface/IERC20BurnableV2.sol";
import "./ILevelingFormula.sol";
import "./ILevelResolver.sol";

/** 
 * @dev Any owner of a node can configure own leveling system for other NFT owners.
 *      He configures his node as project for external usage, defining experience token and leveling formula.
 *      NFT owner needs to burn experience tokens set for such a project to level up.
 *      Leveling formula can be set as an oracle conract, or default formula
 *      500*level^2-500*level=exp will be used.
 */
abstract contract LevelResolver is ILevelResolver, BaseResolver {
    // parabolic equation coeficients for the default leveling formula.
    uint256 public constant DEF_LEVELING_COF1 = 500;
    uint256 public constant DEF_LEVELING_COF2 = 250000;
    uint256 public constant DEF_LEVELING_COF3 = 2000;
    uint256 public constant DEF_LEVELING_COF4 = 1000;

    bytes4 public constant IERC1155_BURNABLE = 0xf5298aca;
    bytes4 public constant IERC20_BURNABLE_V1 = 0x79cc6790;
    bytes4 public constant IERC20_BURNABLE_V2 = 0x9dc29fac;
    
    struct Project{
        address formula;
        address experienceToken;
        uint256 experienceTokenId;
        bytes4 burnInterface;
    }

    mapping(bytes32=>mapping(bytes32=>uint256)) internal levelingExperience;
    mapping(bytes32=>Project) public levelingProjects;

    /**
     * @dev Burn experience tokens to advance in leveling.
     * @param _project node for a project which issue experience.
     * @param _node the node to update.
     * @param _burnExperienceTokenAmount amount of experience tokens to burn.
     * @return updated experience.
     */
    function advanceToNextLevel(
        bytes32 _project,
        bytes32 _node,
        uint256 _burnExperienceTokenAmount
    ) virtual external authorised(_node) returns (uint256) {
        require(_burnExperienceTokenAmount > 0, "no advance in leveling");
        Project memory _levelingProject = levelingProjects[_project];
        require(_levelingProject.experienceToken != address(0), "unregistered project");

        if (_levelingProject.burnInterface == IERC1155_BURNABLE) {
            IERC1155Burnable(_levelingProject.experienceToken).burn(msg.sender, _levelingProject.experienceTokenId, _burnExperienceTokenAmount);
        } else if (_levelingProject.burnInterface == IERC20_BURNABLE_V2) {
            IERC20BurnableV2(_levelingProject.experienceToken).burn(msg.sender, _burnExperienceTokenAmount);
        } else {
            IERC20BurnableV1(_levelingProject.experienceToken).burnFrom(msg.sender, _burnExperienceTokenAmount);
        }
        uint256 _currentExp = levelingExperience[_node][_project];
        uint256 _newExp = _currentExp + _burnExperienceTokenAmount;
        levelingExperience[_node][_project] = _newExp;
        emit AdvancedToNextLevel(_project, _node, _burnExperienceTokenAmount, _newExp);
        return _newExp;
    }

    /**
     * @dev Project controller can update leveling system and experience token.
     * @param _project node for a project which issue experience.
     * @param _levelingFormulaProxy address of proxy contract which implements ILevelingFormula, pass address(0) for default formula.
     * @param _experienceToken address of experience token. 
     * @param _experienceTokenId experience token id in case of ERC1155, pass 0 for ERC20.
     * @param _burnInterface signature of burning function: 0xf5298aca, 0x9dc29fac or 0x79cc6790 (default).
     */
    function setProjectLevelingRules(
        bytes32 _project,
        address _levelingFormulaProxy,
        address _experienceToken,
        uint256 _experienceTokenId,
        bytes4 _burnInterface
    ) virtual external authorised(_project) {
        levelingProjects[_project] = Project(_levelingFormulaProxy, _experienceToken, _experienceTokenId, _burnInterface);
        emit ProjectLevelingRulesChanged(_project, _burnInterface, _experienceToken, _experienceTokenId, _levelingFormulaProxy);
    }

    /**
     * @dev Level based on experience.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return level based on experience
     */
    function level(bytes32 _project, bytes32 _node) virtual override external view returns (uint256) {
        uint256 _exp = levelingExperience[_node][_project];
        if (_exp == 0) return 1;
        if (levelingProjects[_project].formula == address(0)) {
            if (levelingProjects[_project].burnInterface != IERC1155_BURNABLE) {
                return _defaultLevelingFormula(_exp, IERC20(levelingProjects[_project].experienceToken).decimals());
            }
            return _defaultLevelingFormula(_exp, 0);
        } else {
            return ILevelingFormula(levelingProjects[_project].formula).expToLevel(_exp);
        }
    }

    /**
     * @dev Experience in scope of project.
     * @param _project node for a project which issue experience.
     * @param _node the node to query.
     * @return project experience
     */
    function experience(bytes32 _project, bytes32 _node) virtual override external view returns (uint256) {
        return levelingExperience[_node][_project];
    }

    /**
     * @dev Check if specific interface is implemented.
     * @param interfaceID Keccak of matched interface.
     * @return true if implemented.
     */
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns (bool) {
        return interfaceID == type(ILevelResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    /**
     * @dev Parabolic leveling formula similar to DnD 3.5 leveling system: 500*level^2-500*level=exp.
     * @param _exp total experience.
     * @param _decimals experience token decimals.
     * @return level based on experience
     */
    function _defaultLevelingFormula(uint256 _exp, uint256 _decimals) internal pure returns (uint256) {
        if (_decimals > 0) _exp = _exp / (10 ** _decimals); 
        return (DEF_LEVELING_COF1 + _sqrt(DEF_LEVELING_COF2 + (DEF_LEVELING_COF3 * _exp))) / DEF_LEVELING_COF4;
    }

    /**
     * @dev Square root, taken from Uniswap 2.0.
     * @param y argument for square root.
     * @return z a rounded square root result.
     */
    function _sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}