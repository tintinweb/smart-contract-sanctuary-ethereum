/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

pragma solidity ^0.8.0;

contract Byte32ArrayContract {
    bytes32[] public byte32Array;

    function getByte32Array() public view returns (bytes32[] memory) {
        return byte32Array;
    }

    function setByte32Array(bytes32[] memory newArray) public {
        byte32Array = newArray;
    }
}