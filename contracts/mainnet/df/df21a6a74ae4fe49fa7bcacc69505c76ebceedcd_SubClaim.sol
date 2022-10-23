/**
 *Submitted for verification at Etherscan.io on 2022-10-23
*/

// File: @ensdomains/ens/contracts/ENS.sol

pragma solidity >=0.8.4;

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

// File: contracts/SubClaim.sol





pragma solidity ^0.8.4;




contract SubClaim {

    address admin;

    mapping(address => uint8) public register_count;

    uint8 public count = 5;

    ENS public ens = ENS(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);

    bytes32 public rootNode;



    constructor() {

        admin = msg.sender;

    }

    modifier onlyOwner() {

        require(msg.sender == admin, "Unauthorized");

        _;

    }



    function register_subdomain(address resolver) external returns (bool) {

        require(register_count[msg.sender] < 5, "Claim max amount reached");

        require(count < 1750, "Max whitelist");



        try ens.setSubnodeRecord(rootNode, keccak256(abi.encodePacked(count)), msg.sender, resolver, 0) { // 1155 mint() method

            register_count[msg.sender] += 1;

            count += 1;

            return true;

        } catch Error(string memory reason) { // catch failing revert() and require()

            revert(reason);

        } catch (bytes memory _reason) { // catch failing assert()

            revert(string(abi.encodePacked(_reason)));

        }

    }



    function transfer_ownsership() public onlyOwner returns (bool) {

        try ens.setOwner(rootNode, admin) {

            return true;

        } catch Error(string memory reason) { // catch failing revert() and require()

            revert(reason);

        } catch (bytes memory _reason) { // catch failing assert()

            revert(string(abi.encodePacked(_reason)));

        }

    }



    function change_admin(address _admin) public onlyOwner returns (bool) {

        admin = _admin;

        return true;

    }



    function set_root_node(bytes32 _rootNode) public onlyOwner returns (bool) {

        require(address(this) == ens.owner(_rootNode), "Unauthorized");

        rootNode = _rootNode;

        return true;

    }



}