// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract ConfessionDapp {
    address public immutable i_deployer;
    string[] public confessions; // store only confessions string in an array

    event newConfession(string confession);

    constructor() {
        i_deployer = msg.sender;
        confessions.push(
            "Hi, this is the genesis confession produced by the creator of this contract. WAGMI!"
        );
    }

    function confess(string memory confession) public {
        confessions.push(confession);
        emit newConfession(confession);
    }

    /** Getters */
    function getDeployer() public view returns (address) {
        return i_deployer;
    }

    function getConfessions() public view returns (string[] memory) {
        return confessions;
    }
}