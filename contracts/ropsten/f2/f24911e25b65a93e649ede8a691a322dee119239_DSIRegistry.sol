/**
 *Submitted for verification at Etherscan.io on 2022-02-05
*/

pragma solidity >=0.8.4;

// import "./DSI.sol";

contract DSIRegistry {

    struct Record {
        address owner;
    }

    mapping (bytes32 => Record) public records;
    mapping (bytes32 => mapping(string => string)) public texts;
    mapping (bytes32 => mapping(uint => bytes)) public addresses;

    modifier authorised(bytes32 node) {
        address owner = records[node].owner;
        require(owner == msg.sender || owner == address(0x0));
        _;
    }

    bytes32 public hash;

    constructor() public {
        records[0x0].owner = msg.sender;
        hash = 0x0000000000000000000000000000000000000000000000000000000000000000;
        hash = keccak256(abi.encodePacked(hash, keccak256(abi.encodePacked('eth'))));
    }


    function setDSIRecord(bytes32 node, address owner) public {
        setDSIOwner(node, owner);
    }

    
    function setDSIOwner(bytes32 node, address owner) public authorised(node) {
        _setOwner(node, owner);
    }

   
    function owner(bytes32 node) public  view returns (address) {
        address addr = records[node].owner;
        if (addr == address(this)) {
            return address(0x0);
        }

        return addr;
    }

    
    function recordExists(bytes32 node) public  view returns (bool) {
        return records[node].owner != address(0x0);
    }
    
    function nameExists(string memory name) public view returns (bool) {
        return records[hashnode(name)].owner != address(0x0);
    }


    function _setOwner(bytes32 node, address owner) internal  {
        records[node].owner = owner;
    }

    

    function hashnode(string memory name) public view returns(bytes32){
        // hash = keccak256(bytes("eth"));
        // label = keccak256(bytes(name));
        // nodehash = keccak256(abi.encodePacked(hash, label));
        // nodehash = keccak256(hash+label);
        
        bytes32 nodehash = keccak256(abi.encodePacked(hash, keccak256(abi.encodePacked(name))));
        
        return nodehash;
    }

    function setText(bytes32 node, string calldata key, string calldata value) public authorised(node) {
        texts[node][key] = value;
    }

    function text(bytes32 node, string calldata key) public view returns (string memory) {
        return texts[node][key];
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType) virtual public view returns(address) {
        return bytesToAddress(addresses[node][coinType]);
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