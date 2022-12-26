// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface Confidential {
    function hash(bytes32 key1, bytes32 key2) external pure returns (bytes32);
    function checkthehash(bytes32 _hash) external view returns(bool);
}

contract Attack{
    address confidentialHashAddress = 0xf8E9327E38Ceb39B1Ec3D26F5Fad09E426888E66;
    bytes32 aliceHash = 0x448e5df1a6908f8d17fae934d9ae3f0c63545235f8ff393c6777194cae281478;
    bytes32 bobHash = 0x98290e06bee00d6b6f34095a54c4087297e3285d457b140128c1c2f3b62a41bd;
    
    bytes32 public hash;

    function getHash() public {
        hash = Confidential(confidentialHashAddress).hash(aliceHash,bobHash);
    }

    function checkthehash() public view returns(bool){
        return Confidential(confidentialHashAddress).checkthehash(hash);
    }

}