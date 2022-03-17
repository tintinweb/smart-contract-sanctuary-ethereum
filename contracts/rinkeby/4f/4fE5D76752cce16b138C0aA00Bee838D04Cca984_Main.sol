/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

pragma solidity ^0.8.11;

contract Main {
    bool public live;
    address private owner;

    constructor() {
        owner = msg.sender;
        live = false;
    }

    function setLive(bool set) public {
        require(msg.sender == owner, "You are not the contract owner.");
        live = set;
    }

    function return_msg(bytes memory hey) public returns (bytes memory) {
        return hey;
    }

}