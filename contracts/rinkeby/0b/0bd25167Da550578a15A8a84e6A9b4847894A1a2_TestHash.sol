// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

contract TestHash {
    uint256 public index = 0;
    address public account = 0x1b324A4Ea3545d774b4c40A77ddf5F22370DE0a1;
    uint256 public amount = 0x1eca955e9b65e00000;

    function p_hash() public view returns (bytes32) {
        bytes32 h1 = keccak256(abi.encodePacked(index, account, amount));
        bytes32 h2 = keccak256(abi.encodePacked(index+1, account, amount));
        bytes32 s = keccak256(abi.encodePacked(h1, h2));
        return s;
    }
}