/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract TestBytes {

    constructor(uint _uint){
        _num = _uint;
    }
    uint public _num ; 
    bytes public _bytes ; 
    // byte = bytes1
    function getByte(uint8 _uint)external pure returns(bytes1){
        return bytes1(_uint);
    }
    function getBytes32(uint _uint) external pure returns(bytes32){
        return bytes32(_uint);
    }

    function getBytes(uint _uint) external pure returns(bytes memory){
        return abi.encode(_uint);
    }

    function getLength(uint8 _uint)external pure returns(uint){
        return bytes1(_uint).length;
    }

    function pushBytes(bytes1  _byte)external returns(bytes memory){
        _bytes.push(_byte);
        return _bytes;
    }
}