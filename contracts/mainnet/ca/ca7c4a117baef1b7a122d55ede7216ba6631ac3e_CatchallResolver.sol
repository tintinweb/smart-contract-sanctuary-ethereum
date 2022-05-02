/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

/*               .:  :.                                                  */
/*             :--    :-:             _______  _        _______          */
/*           -==-      :==-.         (  ____ \( (    /|(  ____ \         */
/*         . ==:        .===:        | (    \/|  \  ( || (    \/         */
/*         +-..           -++        | (__    |   \ | || (_____          */
/*         ++=           ..-+        |  __)   | (\ \) |(_____  )         */
/*         -*++.        :++ :        | (      | | \   |      ) |         */
/*          :+**:      =**=          | (____/\| )  \  |/\____) |         */
/*            .-+=   .+*-.           (_______/|/    )_)\_______)         */
/*               :-  =:                                                  */
/*  )   ___                            _____                             */
/* (__/_____)          /)       /) /) (, /   )            /)             */
/*   /       _  _/_ _ (/   _   // //    /__ /  _  _   ___// _ _   _  __  */
/*  /       (_(_(__(__/ )_(_(_(/_(/_ ) /   \__(/_/_)_(_)(/_ (/___(/_/ (_ */
/* (______)                         (_/                                  */
/*                                                     by: royalfork.eth */
/*                            0xca7c4a117baef1b7a122d55ede7216ba6631ac3e */

interface IDNSRecordResolver {
    // DNSRecordChanged is emitted whenever a given node/name/resource's RRSET is updated.
    event DNSRecordChanged(bytes32 indexed node, bytes name, uint16 resource, bytes record);
    // DNSRecordDeleted is emitted whenever a given node/name/resource's RRSET is deleted.
    event DNSRecordDeleted(bytes32 indexed node, bytes name, uint16 resource);
    // DNSZoneCleared is emitted whenever a given node's zone information is cleared.
    event DNSZoneCleared(bytes32 indexed node);

    /**
     * Obtain a DNS record.
     * @param node the namehash of the node for which to fetch the record
     * @param name the keccak-256 hash of the fully-qualified name for which to fetch the record
     * @param resource the ID of the resource as per https://en.wikipedia.org/wiki/List_of_DNS_record_types
     * @return the DNS record in wire format if present, otherwise empty
     */
    function dnsRecord(bytes32 node, bytes32 name, uint16 resource) external view returns (bytes memory);
}

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

interface INameResolver {
    event NameChanged(bytes32 indexed node, string name);

    /**
     * Returns the name associated with an ENS node, for reverse records.
     * Defined in EIP181.
     * @param node The ENS node to query.
     * @return The associated name.
     */
    function name(bytes32 node) external view returns (string memory);
}

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

interface IContentHashResolver {
    event ContenthashChanged(bytes32 indexed node, bytes hash);

    /**
     * Returns the contenthash associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function contenthash(bytes32 node) external view returns (bytes memory);
}

interface IExtendedResolver {
    function resolve(bytes memory name, bytes memory data) external view returns(bytes memory);
}
interface IAddressResolver {
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
}

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

interface IAddrResolver {
    event AddrChanged(bytes32 indexed node, address a);

    /**
     * Returns the address associated with an ENS node.
     * @param node The ENS node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) external view returns (address payable);
}

interface IPubkeyResolver {
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);

    /**
     * Returns the SECP256k1 public key associated with an ENS node.
     * Defined in EIP 619.
     * @param node The ENS node to query
     * @return x The X coordinate of the curve point for the public key.
     * @return y The Y coordinate of the curve point for the public key.
     */
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
}

interface ENS {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

interface ITextResolver {
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    /**
     * Returns the text data associated with an ENS node and key.
     * @param node The ENS node to query.
     * @param key The text data key to query.
     * @return The associated text data.
     */
    function text(bytes32 node, string calldata key) external view returns (string memory);
}

interface IDNSZoneResolver {
    // DNSZonehashChanged is emitted whenever a given node's zone hash is updated.
    event DNSZonehashChanged(bytes32 indexed node, bytes lastzonehash, bytes zonehash);

    /**
     * zonehash obtains the hash for the zone.
     * @param node The ENS node to query.
     * @return The associated contenthash.
     */
    function zonehash(bytes32 node) external view returns (bytes memory);
}

interface Resolver is
    IERC165,
    IABIResolver,
    IAddressResolver,
    IAddrResolver,
    IContentHashResolver,
    IDNSRecordResolver,
    IDNSZoneResolver,
    IInterfaceResolver,
    INameResolver,
    IPubkeyResolver,
    ITextResolver {}

/**
 * @title Catch-all ENSIP-10 resolver.
 * @author royalfork.eth
 * @notice ENS resolver which proxies all resolver functions for any
 *         subdomain of a node to a set resolver.
 */
contract CatchallResolver is IExtendedResolver, Resolver {
    ENS public immutable registry;

    mapping(bytes32=>Resolver) resolvers;

    event NewCatchallResolver(bytes32 indexed node, address resolver);

    constructor(address _registry) {
        registry = ENS(_registry);
    }

    /**
     * @notice Set catchall resolver for node.  Node and all of its
     *         subdomains will use this resolver.  Message sender must
     *         be owner or operator for node.
     * @param _node Catchall resolver will be set for this node.
     * @param _resolver Catchall reoslver proxies all resolver
     *        functions to this address.
	 */
	function setResolver(bytes32 _node, Resolver _resolver) public {
        address owner = registry.owner(_node);
        require(owner == msg.sender || registry.isApprovedForAll(owner, msg.sender));
		resolvers[_node] = _resolver;
		emit NewCatchallResolver(_node, address(_resolver));
	}

    /**
	 * @notice ENSIP-10 defined wildcard resolution function.
     * @dev Resolve only works with resolver functions where the first
     *      argument is a bytes32 node (as of ENSIP-12, all resolver
     *      functions meet this criteria).
	 * @param _name DNS-encoded name to be resolved.
	 * @param _data ABI-encoded calldata for a resolver function.
	 * @return output ABI-encoded return output from function encoded
	 *         by _data.
	 */
    function resolve(bytes calldata _name, bytes memory _data) external override view returns(bytes memory) {
		(address r,,bytes32 node,) = resolver(_name, 0);

		// Replace node argument in data with parentNode
		for (uint8 i = 0; i < 32; i++) {
			_data[i+4] = node[i];
		}

		(bool ok, bytes memory out) = r.staticcall(_data);
		if (!ok) {
			revert("invalid call");
		}
		return out;
    }

    /**
     * @notice Returns ENSIP-10 resolver for name.
     * @param _name The name to resolve, in normalised and DNS-encoded form (eg: sub.example.eth)
     * @return resolverAddr Found resolver for name.
	 * @return resolverOwner DNS-encoded name which set the resolver (eg: example.eth).
	 */
	function resolver(bytes calldata _name) public view returns(address, bytes memory) {
		(address r,uint256 o,,) = resolver(_name, 0);
		return (r, _name[o:]);
	}

    function supportsInterface(bytes4 interfaceID) public pure override returns(bool) {
        return interfaceID == type(IExtendedResolver).interfaceId ||
			interfaceID == type(IERC165).interfaceId ||
			interfaceID == type(IABIResolver).interfaceId ||
			interfaceID == type(IAddressResolver).interfaceId ||
			interfaceID == type(IAddrResolver).interfaceId ||
			interfaceID == type(IContentHashResolver).interfaceId ||
			interfaceID == type(IDNSRecordResolver).interfaceId ||
			interfaceID == type(IDNSZoneResolver).interfaceId ||
			interfaceID == type(IInterfaceResolver).interfaceId ||
			interfaceID == type(INameResolver).interfaceId ||
			interfaceID == type(IPubkeyResolver).interfaceId ||
			interfaceID == type(ITextResolver).interfaceId;
    }

	function ABI(bytes32 node, uint256 contentTypes) external override view returns (uint256, bytes memory) {
		return resolvers[node].ABI(node, contentTypes);
	}
	function addr(bytes32 node) external override view returns (address payable) {
		return resolvers[node].addr(node);
	}
	function addr(bytes32 node, uint coinType) external override view returns(bytes memory) {
		return resolvers[node].addr(node, coinType);
	}
	function contenthash(bytes32 node) external override view returns (bytes memory) {
		return resolvers[node].contenthash(node);
	}
	function dnsRecord(bytes32 node, bytes32 _name, uint16 resource) external override view returns (bytes memory) {
		return resolvers[node].dnsRecord(node, _name, resource);
	}
	function interfaceImplementer(bytes32 node, bytes4 interfaceID) external override view returns (address) {
		return resolvers[node].interfaceImplementer(node, interfaceID);
	}
	function name(bytes32 node) external override view returns (string memory) {
		return resolvers[node].name(node);
	}
	function pubkey(bytes32 node) external override view returns (bytes32 x, bytes32 y) {
		return resolvers[node].pubkey(node);
	}
	function text(bytes32 node, string calldata key) external override view returns (string memory) {
		return resolvers[node].text(node, key);
	}
	function zonehash(bytes32 node) external override view returns (bytes memory) {
		return resolvers[node].zonehash(node);
	}

    /**
     * @dev Performs recursive ENSIP-10 lookup for a catchall resolver.
     * @param _name The name to resolve, in normalised and DNS-encoded
     *        form (eg: sub.example.eth)
     * @param _offset The offset within name on which a catchall
     *        resolver lookup is performed.
     * @return resolverAddr Found resolver for name.
     * @return resolverNameOffset Domain at this offset within name
     *         which set resolverAddr (eg: offset of example.eth).
     * @return resolverNode Namehash of name[resolverNameOffset:].
     * @return node Namehash of name.
     */
    function resolver(bytes calldata _name, uint256 _offset) internal view returns(address, uint256, bytes32, bytes32) {
        uint256 labelLength = uint256(uint8(_name[_offset]));
        if(labelLength == 0) {
            return (address(0), _name.length, bytes32(0), bytes32(0));
        }
        uint256 nextLabel = _offset + labelLength + 1;
        bytes32 labelHash = keccak256(_name[_offset + 1: nextLabel]);
        (address r, uint256 roffset, bytes32 rnode, bytes32 parentnode) = resolver(_name, nextLabel);
        bytes32 node = keccak256(abi.encodePacked(parentnode, labelHash));
        address newr = address(resolvers[node]);
        if(newr != address(0)) {
            return (newr, _offset, node, node);
        }
        return (r, roffset, rnode, node);
    }
}