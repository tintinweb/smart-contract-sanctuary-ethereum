/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity ^0.5.0;


contract Compute{

    function getnode(bytes32 node, bytes32 label) public view returns(bytes32) {
        bytes32 subnode = keccak256(abi.encodePacked(node, label));
        return subnode;
    }

    function getnode(string memory name) public view returns(bytes32) {
        bytes32 label = keccak256(bytes(name));
        return label;
    }

}