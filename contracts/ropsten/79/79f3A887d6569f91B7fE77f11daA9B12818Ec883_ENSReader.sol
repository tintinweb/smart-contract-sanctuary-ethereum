pragma solidity ^0.5.0;

import "@ensdomains/ens/contracts/ENS.sol";
import "../contracts/Resolver.sol";


// Wrapper contract for calling PublicResolver getters. First use the node to fetch the resolver
// address from the registry, then query the resolver function. Registry address needs to be
// provided on deployment.
contract ENSReader {
    ENS internal ens;

    constructor(address _ensAddr) public {
        ens = ENS(_ensAddr);
    }

    function abiOf(bytes32 _node, uint256 _contentTypes)
        internal
        view
        returns (uint256, bytes memory)
    {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0x2203ab56)); // ABIResolver
        return resolver.ABI(_node, _contentTypes);
    }

    function addressOf(bytes32 _node) internal view returns (address) {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0x3b3b57de)); // AddrResolver
        return resolver.addr(_node);
    }

    function contenthashOf(bytes32 _node) internal view returns (bytes memory) {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0xbc1c58d1)); // ContentHashResolver
        return resolver.contenthash(_node);
    }

    function interfaceImplementerOf(bytes32 _node, bytes4 _interfaceID)
        internal
        view
        returns (address)
    {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0x01ffc9a7)); // InterfaceResolver
        return resolver.interfaceImplementer(_node, _interfaceID);
    }

    function nameOf(bytes32 _node) internal view returns (string memory) {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0x691f3431)); // NameResolver
        return resolver.name(_node);
    }

    function pubkeyOf(bytes32 _node) internal view returns (bytes32 x, bytes32 y) {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0xc8690233)); // PubkeyResolver
        return resolver.pubkey(_node);
    }

    function textOf(bytes32 _node, string memory _key) internal view returns (string memory) {
        Resolver resolver = Resolver(ens.resolver(_node));
        require(resolver.supportsInterface(0x01ffc9a7)); // ResolverBase
        require(resolver.supportsInterface(0x59d1d43c)); // TextResolver
        return resolver.text(_node, _key);
    }
}

pragma solidity >=0.4.25;

/**
 * A generic resolver interface which includes all the functions including the ones deprecated
 */
interface Resolver{
    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);
    event ContenthashChanged(bytes32 indexed node, bytes hash);
    /* Deprecated events */
    event ContentChanged(bytes32 indexed node, bytes32 hash);

    function ABI(bytes32 node, uint256 contentTypes) external view returns (uint256, bytes memory);
    function addr(bytes32 node) external view returns (address);
    function addr(bytes32 node, uint coinType) external view returns(bytes memory);
    function contenthash(bytes32 node) external view returns (bytes memory);
    function dnsrr(bytes32 node) external view returns (bytes memory);
    function name(bytes32 node) external view returns (string memory);
    function pubkey(bytes32 node) external view returns (bytes32 x, bytes32 y);
    function text(bytes32 node, string calldata key) external view returns (string memory);
    function interfaceImplementer(bytes32 node, bytes4 interfaceID) external view returns (address);

    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;

    function supportsInterface(bytes4 interfaceID) external pure returns (bool);

    /* Deprecated functions */
    function content(bytes32 node) external view returns (bytes32);
    function multihash(bytes32 node) external view returns (bytes memory);
    function setContent(bytes32 node, bytes32 hash) external;
    function setMultihash(bytes32 node, bytes calldata hash) external;
}

pragma solidity >=0.4.24;

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);


    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);

}