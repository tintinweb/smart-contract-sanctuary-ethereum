/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

pragma solidity >=0.7.0 <0.9.0;

contract MOTD {

    string message;

    constructor() {
        message = "Prva poruka";
    }

    function updateMessage(string memory newMessage) public {
        message = newMessage;
    }
}