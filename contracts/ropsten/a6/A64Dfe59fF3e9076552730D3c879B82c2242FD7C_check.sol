/**
 *Submitted for verification at Etherscan.io on 2022-02-06
*/

pragma solidity ^0.8.0;

contract check {
    function checkHash(address user) public pure returns (bytes32) {
        bytes32 res = keccak256(abi.encodePacked(user));
        return res;
    }
}