/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// Specifies the version of Solidity, using semantic versioning.
// Learn more: https://solidity.readthedocs.io/en/v0.5.10/layout-of-source-files.html#pragma
pragma solidity ^0.8.13;

contract HelloWorld {
    string public message;
    int public numRun;

    constructor(string memory initMessage) {
        message = initMessage;
        numRun = 0;
    }

    function update(string memory newMessage) public {
        message = newMessage;
        numRun++;
    }


}