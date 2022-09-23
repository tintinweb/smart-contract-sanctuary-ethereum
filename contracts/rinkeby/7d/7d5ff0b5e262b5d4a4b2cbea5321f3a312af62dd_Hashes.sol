/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Hashes{
    function SHA256(string memory _str) public pure returns(bytes32){
        return sha256(abi.encode(_str));
    }

    function KECCAK256(string memory _str) public pure returns(bytes32){
        return keccak256(abi.encode(_str));
    }

    function RIPEMD160(string memory _str) public pure returns(bytes32){
        return ripemd160(abi.encode(_str));
    }

    function SHA256PACKED(string memory _str) public pure returns(bytes32){
        return sha256(abi.encodePacked(_str));
    }

    function KECCAK256PACKED(string memory _str) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_str));
    }

    function RIPEMD160PACKED(string memory _str) public pure returns(bytes32){
        return ripemd160(abi.encodePacked(_str));
    }

    
}