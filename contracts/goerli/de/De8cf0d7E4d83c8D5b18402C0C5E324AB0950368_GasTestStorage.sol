/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

pragma solidity ^0.8.0;

contract GasTestStorage {
    mapping(uint=>uint) public store;
    function setStore(uint slot, uint value) public {
        store[slot] = value;
    }

    function lazyLoad(uint slot) public returns (bool) {
        return slot < 5 || store[slot] > 10;
    }

    function namehash(uint id) public pure returns (bytes32) {
        bytes32 eth = keccak256(abi.encodePacked(
            uint(0),
            keccak256(abi.encodePacked('eth'))
        ));
        return keccak256(abi.encodePacked(
            eth,
            id
        ));
    }

}