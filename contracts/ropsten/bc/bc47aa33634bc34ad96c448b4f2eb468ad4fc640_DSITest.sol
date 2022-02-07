/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

contract DSITest {

    struct Record {
        address owner;
    }

    mapping (bytes32 => Record) records;
    mapping (address => bytes32) users;
    mapping (bytes32 => mapping(string => string)) texts;
    mapping (bytes32 => mapping(uint => bytes)) addresses;

    modifier authorised(bytes32 node) {
        address _owner = records[node].owner;
        require(_owner == msg.sender || _owner == address(0x0));
        _;
    }

    event RecordCreated(bytes32 _node, address _owner);
    event TextAdded(string key, string value);
    event AddressAdded(uint256 coinType, address _addr);

    constructor() {
        records[0x0].owner = msg.sender;
    }


    function setDSIRecord(bytes32 node) public {
        setDSIOwner(node, msg.sender);
    }

    
    function setDSIOwner(bytes32 node, address _owner) public authorised(node) {
        if(!recordExists(node)){
            records[node].owner = _owner;
            users[_owner]=node;
            emit RecordCreated(node, _owner);
        }
    }

   
    function getOwner(bytes32 node) public  view returns (address) {
        address _addr = records[node].owner;
        if (_addr == address(this)) {
            return address(0x0);
        }

        return _addr;
    }

    
    function recordExists(bytes32 node) public  view returns (bool) {
        return records[node].owner != address(0x0);
    }
    
    function userExists(address _addr) public  view returns (bool, bytes32) {
        bool exists = users[_addr] != bytes32(0x0);
        bytes32 a = users[_addr];
        return (exists, a);
    }

    function setText(bytes32 node, string calldata key, string calldata value) public authorised(node) {
        texts[node][key] = value;
        emit TextAdded(key, value);
    }

    function text(bytes32 node, string calldata key) public view returns (string memory) {
        return texts[node][key];
    }

    function setAddr(bytes32 node, uint coinType, bytes memory a) virtual public authorised(node) {
        addresses[node][coinType] = a;
        emit AddressAdded(coinType, bytesToAddress(a));
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