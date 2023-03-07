// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract Assessment_4_Solution {

	function solution(address owner, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) public pure 
    returns (bool isSignedByOwner) {
            bytes32 h = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
            return (ecrecover(h, v, r, s) == owner);
    }
}