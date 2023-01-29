//SPDX-License-Identifier: MIT

pragma solidity >= 0.7.3;

contract HelloWorld {
    event UpdatedMsg(string oldMsg, string newMsg);

    string public message;
    
    constructor(string memory initMsg) {
        message = initMsg;
    }

    function update(string memory newMsg) public {
        // I will temp store the old msg before it is wiped out
        string memory oldMsg = message;
        message = newMsg;
        
        //now broadcast it
        emit UpdatedMsg(oldMsg, newMsg);
    }

}