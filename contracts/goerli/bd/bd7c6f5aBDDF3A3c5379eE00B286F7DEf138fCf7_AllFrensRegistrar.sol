pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

interface ENS {
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

interface Resolver {
    function setABI(bytes32 node, uint256 contentType, bytes calldata data) external;
    function setAddr(bytes32 node, address addr) external;
    function setAddr(bytes32 node, uint coinType, bytes calldata a) external;
    function setContenthash(bytes32 node, bytes calldata hash) external;
    function setDnsrr(bytes32 node, bytes calldata data) external;
    function setName(bytes32 node, string calldata _name) external;
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) external;
    function setText(bytes32 node, string calldata key, string calldata value) external;
    function setInterface(bytes32 node, bytes4 interfaceID, address implementer) external;
    function multicall(bytes[] calldata data) external returns(bytes[] memory results);
}

interface IERC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

/**
 * A registrar that allocates subdomains to the first person to claim them.
 */
contract AllFrensRegistrar {
    address _registrarController;
    address ens = 0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e;
    bytes32 rootNode = 0x74cbd8f80abd80c5c263aa593689992512542566d6497e05d32312194af95e4e;
    address publicResolver = 0x4B1488B7a6B320d2D721406204aBc3eeAa9AD329;
    address nft = 0x4E16ba160BAFa69Efa77c10bE94FF33150FCB4c2;
    uint256 FEE = 0.1 ether;
    mapping(address => bool) whitelist;

    modifier only_owner(bytes32 label) {
        address currentOwner = ENS(ens).owner(keccak256(abi.encodePacked(rootNode, label)));
        require(currentOwner == address(0x0) || currentOwner == msg.sender);
        _;
    }

    modifier hodler() {
        require(IERC721(nft).balanceOf(msg.sender) != 0, "Not Fren Yet");
        _;
    }

    constructor() {
        _registrarController = msg.sender;
    }

    /**
     * Register a name, or change the owner of an existing registration.
     * @param label The hash of the label to register.
     */
    function register(bytes32 label) payable public hodler {
        bytes32 nodehash = keccak256(abi.encodePacked(rootNode, label));
        require(!ENS(ens).recordExists(nodehash), "TAKEN");
        require(msg.value >= FEE);
        if (msg.value > FEE) {
            payable(msg.sender).transfer(msg.value - FEE);
        }
        payable(_registrarController).transfer(FEE);
        ENS(ens).setSubnodeRecord(rootNode, label, address(this), publicResolver, 5);
        Resolver(publicResolver).setAddr(nodehash, msg.sender);
        ENS(ens).setSubnodeOwner(rootNode, label, msg.sender);
    }
}