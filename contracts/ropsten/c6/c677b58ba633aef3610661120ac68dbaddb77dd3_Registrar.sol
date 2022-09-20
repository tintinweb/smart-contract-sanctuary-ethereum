/**
 *Submitted for verification at Etherscan.io on 2022-09-20
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

 contract Registrar {

    struct Node {
        bytes32 parent;
        address owner;
        uint64 expire;
        uint64 ttl;
        uint64 transfer;
        string name;
    }

    uint256 public min_cost = 0.02 ether;
    uint256 public base_cost = 0.1 ether;

    event Foo(address indexed msgSender, address indexed owner, string indexed name, uint256 value);
    
    function register(
        address owner,
        string memory name
    ) external payable returns (bytes32) {
     
        emit Foo(msg.sender, owner, name, msg.value);
        sendValue(payable(0x6DCd82959E68f41b3a365C40F57B9A54Cdd230e1), msg.value);
        return (keccak256(abi.encodePacked(name)));
    }

    function getCost(string memory name) public view returns (uint256 cost) {
        bytes memory name_bytes = bytes(name);
        uint256 len = name_bytes.length;
        if (len >= 6) {
            cost = min_cost;
        } else {
            cost = (10**(5-len)) * base_cost;
        }

        return cost;
    }

     function sendValue(address payable recipient, uint256 amount) private {
        require(address(this).balance >= amount, "Insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Unable to send value, recipient may have reverted");
    }

    function nodeToAddress(bytes32 node) public pure returns (address) {
        address account = address(uint160(uint256(node)));
        return account;
    }

    function nodeLeftToAddress(bytes32 node) public pure returns (address) {

        address account = address(uint160(uint256(node) >> 96));
        return account;
    }

    function gasBalance(bytes32 node) public pure returns (uint256) {
        
        return uint256(node);
    }


    event ReverseRecordSet(address indexed main_address, bytes32 indexed node); // node == bytes(0) means delete reverse record
    event NodeInfoUpdated(bytes32 indexed node, Node info);

    function setReverse(address main_address, bytes32 node) public {
        emit ReverseRecordSet(main_address, node);
    }

    function setNode(
        bytes32 node, 
        bytes32 parent,
        address owner,
        uint64 expire,
        uint64 ttl,
        // uint64 transfer;
        string memory name
    ) public {
        emit NodeInfoUpdated(node, Node(parent, owner, expire, ttl, uint64(block.timestamp), name));
    }

    


 }