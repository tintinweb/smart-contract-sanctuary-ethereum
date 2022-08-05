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
import "@le7el/web3_crs/contracts/resolver/Multicallable.sol";
import "./profile/ManagedResolver.sol";

contract WorldResolver is 
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
    ManagedResolver
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
            "ERC1155: setting approval status for self"
        );

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

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
        ManagedResolver
    ) pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
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
import "./ISupportsInterface.sol";

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
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
    IProxyConfigResolver
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
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IAddressResolver.sol";

abstract contract AddressResolver is IAddressResolver, BaseResolver {
    uint constant private COIN_TYPE_ETH = 1;

    mapping(bytes32=>mapping(uint=>bytes)) internal _addresses;

    /**
     * Returns the address associated with an CRS node.
     * @param node The CRS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) virtual public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if(a.length == 0) {
            return payable(0);
        }
        return bytesToAddress(a);
    }
    function addr(bytes32 node, uint coinType) virtual override public view returns(bytes memory) {
        return _addresses[node][coinType];
    }

    /**
     * Sets the address associated with an CRS node.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, addressToBytes(a));
    }

    /**
     * Sets the address associated with an CRS node.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param coinType Chain id to set address.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        emit AddressChanged(node, coinType, a);
        _addresses[node][coinType] = a;
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IAddressResolver).interfaceId || super.supportsInterface(interfaceID);
    }

    function bytesToAddress(bytes memory b) internal pure returns(address payable a) {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function addressToBytes(address a) internal pure returns(bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IContentHashResolver.sol";

abstract contract ContentHashResolver is IContentHashResolver, BaseResolver {
    mapping(bytes32=>bytes) internal hashes;

    /**
     * Sets the contenthash associated with an CRS node.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param hash The contenthash to set
     */
    function setContenthash(bytes32 node, bytes calldata hash) virtual external authorised(node) {
        hashes[node] = hash;
        emit ContenthashChanged(node, hash);
    }

    /**
     * Returns the contenthash associated with an CRS node.
     * @param node The CRS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) virtual external override view returns (bytes memory) {
        return hashes[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IContentHashResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./INameResolver.sol";

abstract contract NameResolver is INameResolver, BaseResolver {
    mapping(bytes32=>string) internal names;

    /**
     * Sets the name associated with an CRS node, for reverse records.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     */
    function setName(bytes32 node, string calldata newName) virtual external authorised(node) {
        names[node] = newName;
        emit NameChanged(node, newName);
    }

    /**
     * Returns the name associated with an CRS node, for reverse records.
     * Defined in EIP181.
     * @param node The CRS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) virtual override external view returns (string memory) {
        return names[node];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(INameResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./ITextResolver.sol";

abstract contract TextResolver is ITextResolver, BaseResolver {
    mapping(bytes32=>mapping(string=>string)) internal texts;

    /**
     * Sets the text data associated with an CRS node and key.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param key The key to set.
     * @param value The text data value to set.
     */
    function setText(bytes32 node, string calldata key, string calldata value) virtual external authorised(node) {
        texts[node][key] = value;
        emit TextChanged(node, key, key);
    }

    /**
     * Returns the text data associated with an CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) virtual override external view returns (string memory) {
        return texts[node][key];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ITextResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ISupportsInterface.sol";
import "./AddressResolver.sol";
import "./IInterfaceResolver.sol";

abstract contract InterfaceResolver is IInterfaceResolver, AddressResolver {
    mapping(bytes32=>mapping(bytes4=>address)) internal interfaces;

    /**
     * Sets an interface associated with a name.
     * Setting the address to 0 restores the default behaviour of querying the contract at `addr()` for interface support.
     * @param node The node to update.
     * @param interfaceID The EIP 165 interface ID.
     * @param implementer The address of a contract that implements this interface for this node.
     */
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) virtual external authorised(node) {
        interfaces[node][interfaceID] = implementer;
        emit InterfaceChanged(node, interfaceID, implementer);
    }

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
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

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IInterfaceResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IABIResolver.sol";

abstract contract ABIResolver is IABIResolver, BaseResolver {
    mapping(bytes32=>mapping(uint256=>bytes)) internal abis;

    /**
     * Sets the ABI associated with an CRS node.
     * Nodes may have one ABI of each content type. To remove an ABI, set it to
     * the empty string.
     * @param node The node to update.
     * @param contentType The content type of the ABI
     * @param data The ABI data.
     */
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) virtual external authorised(node) {
        // Content types must be powers of 2
        require(((contentType - 1) & contentType) == 0);

        abis[node][contentType] = data;
        emit ABIChanged(node, contentType);
    }

    /**
     * Returns the ABI associated with an CRS node.
     * Defined in EIP205.
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

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IABIResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IPubkeyResolver.sol";

abstract contract PubkeyResolver is IPubkeyResolver, BaseResolver {
    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    mapping(bytes32=>PublicKey) internal pubkeys;

    /**
     * Sets the SECP256k1 public key associated with an CRS node.
     * @param node The CRS node to query
     * @param x the X coordinate of the curve point for the public key.
     * @param y the Y coordinate of the curve point for the public key.
     */
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) virtual external authorised(node) {
        pubkeys[node] = PublicKey(x, y);
        emit PubkeyChanged(node, x, y);
    }

    /**
     * Returns the SECP256k1 public key associated with an CRS node.
     * Defined in EIP 619.
     * @param node The CRS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) virtual override external view returns (bytes32 x, bytes32 y) {
        return (pubkeys[node].x, pubkeys[node].y);
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IPubkeyResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IRoyaltiesResolver.sol";

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
     * @dev Sets the royalties associated with an CRS node, for reverse records.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param beneficiary The associated beneficiary to recieve royalties.
     * @param amount The associated royalty amount.
     * @param token ERC20 token to charge royalites, address(0) to use gas coin.
     * @param forAddress Address which gets this exact 
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
     * @dev Returns the name associated with an CRS node, for reverse records.
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

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IRoyaltiesResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../BaseResolver.sol";
import "./IProxyConfigResolver.sol";

abstract contract ProxyConfigResolver is IProxyConfigResolver, BaseResolver {
    mapping(bytes32=>mapping(address=>mapping(bytes4=>address))) internal proxyConfigs;

    /**
     * Sets proxy contract controlled by a 3rd party with data related to this CRS.
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
     * Returns proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @return Address which implements proxy interface.
     */
    function proxyConfig(bytes32 node, address controller, bytes4 selector) virtual override external view returns (address) {
        return proxyConfigs[node][controller][selector];
    }

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IProxyConfigResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMulticallable.sol";
import "./SupportsInterface.sol";

abstract contract Multicallable is IMulticallable, SupportsInterface {
    function multicall(bytes[] calldata data) external override returns(bytes[] memory results) {
        results = new bytes[](data.length);
        for(uint i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);
            require(success);
            results[i] = result;
        }
        return results;
    }

    function supportsInterface(bytes4 interfaceID) public override virtual pure returns(bool) {
        return interfaceID == type(IMulticallable).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MPL-2.0
pragma solidity ^0.8.10;

import "@le7el/web3_crs/contracts/resolver/BaseResolver.sol";
import "./IManagedResolver.sol";

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

    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(IManagedResolver).interfaceId || super.supportsInterface(interfaceID);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * Interface for addr function.
 */
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an CRS node, for reverse records.
     * Defined in EIP181.
     * @param node The CRS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an CRS node and key.
     * @param node The CRS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an CRS node.
     * @param node The CRS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IABIResolver {
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    /**
     * Returns the ABI associated with an ENS node.
     * Defined in EIP205.
     * @param node The ENS node to query
     * @param contentTypes A bitwise OR of the ABI formats accepted by the caller.
     * @return contentType The content type of the return value
     * @return data The ABI data
     */
    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IInterfaceResolver {
    event InterfaceChanged(bytes32 indexed node, bytes4 indexed interfaceID, address implementer);

    /**
     * Returns the address of a contract that implements the specified interface for this name.
     * If an implementer has not been set for this interfaceID and name, the resolver will query
     * the contract at `addr()`. If `addr()` is set, a contract exists at that address, and that
     * contract implements EIP165 and returns `true` for the specified interfaceID, its address
     * will be returned.
     * @param node The ENS node to query.
     * @param interfaceID The EIP 165 interface ID to check for.
     * @return The address that implements this interface, or 0 if the interface is unsupported.
     */
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an CRS node.
     * Defined in EIP 619.
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
     * @dev Returns the SECP256k1 public key associated with an CRS node.
     * Defined in EIP 619.
     * @param node The CRS node to query
     * @param addr Specific address for which royalties apply, address(0) for any address.
     * @return beneficiary address for royalties.
     * @return amount of roylties.
     * @return token, address(0) for gas coin
     */
    function royalty(bytes32 node, address addr) external view returns (address, uint256, address);

    /**
     * @dev Sets the royalties associated with an CRS node, for reverse records.
     * May only be called by the owner of that node in the CRS registry.
     * @param node The node to update.
     * @param beneficiary The associated beneficiary to recieve royalties.
     * @param amount The associated royalty amount.
     * @param token ERC20 token to charge royalites, address(0) to use gas coin.
     * @param forAddress Address which gets this exact 
     */
    function setRoyalties(bytes32 node, address beneficiary, uint256 amount, address token, address forAddress) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IProxyConfigResolver {
    event ProxyConfigChanged(bytes32 indexed node, address indexed controller, bytes4 indexed selector, address proxy);

    /**
     * Returns proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @return Address which implements proxy interface.
     */
    function proxyConfig(bytes32 node, address controller, bytes4 selector) external view returns (address);

    /**
     * Sets proxy contract address which resolves into some content.
     * @param node The CRS node to query.
     * @param controller Address of proxy controller.
     * @param selector Function selector to be called on proxy contract.
     * @param proxy Address which implements proxy interface.
     */
    function setProxyConfig(bytes32 node, address controller, bytes4 selector, address proxy) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) external pure returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SupportsInterface.sol";

abstract contract BaseResolver is SupportsInterface {
    function isAuthorised(bytes32 node) internal virtual view returns(bool);
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
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ISupportsInterface.sol";

abstract contract SupportsInterface is ISupportsInterface {
    function supportsInterface(bytes4 interfaceID) virtual override public pure returns(bool) {
        return interfaceID == type(ISupportsInterface).interfaceId;
    }
}

// SPDX-License-Identifier: MPL-2.0
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