// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Youwish {
    bytes32 public merkleRoot = 0x8c25a840e439ca38e212e32aa802e0f4708cda00caa887b8d783d146e2ded410;
    
    function setMerkleRoot(bytes32 merkleRoot_) external {
        merkleRoot = merkleRoot_;
    }
}