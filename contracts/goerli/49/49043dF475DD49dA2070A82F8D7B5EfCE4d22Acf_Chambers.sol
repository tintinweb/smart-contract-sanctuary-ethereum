// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "./Temple.sol";


contract Chambers {
    address internal templeAddress;

    constructor(address _templeAddress) {
        templeAddress = _templeAddress;
    }

    function getAbiEncode() public pure returns(bytes memory){
        return abi.encode(3);
    }

    function getAbiEncodeKeccak256() public pure returns(bytes32) {
        return keccak256(abi.encode(3));
    }

    function computeChamberAddress() public pure returns(uint) {
        return uint(keccak256(abi.encode(3))) + 5;
    }

    function computeChamberAddressBytes32() public pure returns(bytes32[2] memory) {
        bytes32 x = keccak256(abi.encode(3));
        bytes32 addr = bytes32(uint(keccak256(abi.encode(3))) + 5);
        bytes32[2] memory res = [x, addr];
        return res;
    }

    function writeToChambers(bytes32 data) public {
        Temple(templeAddress).write(computeChamberAddress(), data);
    }
}