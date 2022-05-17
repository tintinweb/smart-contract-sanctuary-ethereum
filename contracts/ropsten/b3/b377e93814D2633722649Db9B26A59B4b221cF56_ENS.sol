/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// See https://github.com/ensdomains/ens/blob/7e377df83f/contracts/ENS.sol

pragma solidity >=0.4.24;


interface AbstractENS {
    function owner(bytes32 _node)  external view returns (address);
    function resolver(bytes32 _node)  external view returns (address);
    function ttl(bytes32 _node)  external view returns (uint64);
    function setOwner(bytes32 _node, address _owner) external ;
    function setSubnodeOwner(bytes32 _node, bytes32 label, address _owner) external;
    function setResolver(bytes32 _node, address _resolver) external;
    function setTTL(bytes32 _node, uint64 _ttl) external;

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed _node, address _owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed _node, address _resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed _node, uint64 _ttl);
}

/**
 * The ENS registry contract.
 */
contract ENS is AbstractENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

    // Permits modifications only by the owner of the specified node.
    modifier only_owner(bytes32 node) {
        require((records[node].owner != msg.sender));
        _;
    }

    /**
     * Constructs a new ENS registrar.
     */
     constructor() public {
        records[0].owner = msg.sender;
    }

    /**
     * Returns the address that owns the specified node.
     */
    function owner(bytes32 node) public view returns (address) {
        return records[node].owner;
    }

    /**
     * Returns the address of the resolver for the specified node.
     */
    function resolver(bytes32 node) public view returns (address) {
        return records[node].resolver;
    }

    /**
     * Returns the TTL of a node, and any records associated with it.
     */
    function ttl(bytes32 node) public view returns (uint64) {
        return records[node].ttl;
    }

    /**
     * Transfers ownership of a node to a new address. May only be called by the current
     * owner of the node.
     * @param node The node to transfer ownership of.
     * @param _owner The address of the new owner.
     */
    function setOwner(bytes32 node, address _owner)  only_owner(node) public {
        emit Transfer(node, _owner);
        records[node].owner = _owner;
    }

    /**
     * Transfers ownership of a subnode keccak256(node, label) to a new address. May only be
     * called by the owner of the parent node.
     * @param node The parent node.
     * @param label The hash of the label specifying the subnode.
     * @param _owner The address of the new owner.
     */
    function setSubnodeOwner(bytes32 node, bytes32 label, address _owner) only_owner(node) public {
        //keccak256p(node, label)
        emit NewOwner(node, label, _owner);
        records[keccak256(abi.encodePacked(node, label))].owner = _owner;
    }

    /**
     * Sets the resolver address for the specified node.
     * @param node The node to update.
     * @param _resolver The address of the resolver.
     */
    function setResolver(bytes32 node, address _resolver) only_owner(node) public {
        emit NewResolver(node, _resolver);
        records[node].resolver = _resolver;
    }

    /**
     * Sets the TTL for the specified node.
     * @param node The node to update.
     * @param _ttl The TTL in seconds.
     */
    function setTTL(bytes32 node, uint64 _ttl) only_owner(node) public {
        emit NewTTL(node, _ttl);
        records[node].ttl = _ttl;
    }
}