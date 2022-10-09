// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Trust {
    address public owner;

    event MediaPost(address owner, string dataUri);

    constructor() {
       owner = msg.sender;
    }

    function postMedia(string memory dataUri) public {
        emit MediaPost(msg.sender, dataUri);
    }    
}