// SPDX-License-Identifier: Unlicense

pragma solidity^0.8.1;

contract CorruptionsDeveloperLog {
    event Message(string indexed message);
    
    address public owner;
    
    constructor() {
        owner = msg.sender;
    }
    
    function postMessage(string memory message) public {
        require(msg.sender == owner, "CorruptionsDeveloperLog: not owner");
        emit Message(message);
    }
}