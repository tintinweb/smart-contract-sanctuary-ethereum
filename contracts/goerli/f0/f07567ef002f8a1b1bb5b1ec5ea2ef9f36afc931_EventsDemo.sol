/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

pragma solidity 0.8.10;

contract EventsDemo {
    event Message(
        address indexed from,
        address indexed to,
        string message
    );

    function sendMessage(address to, string memory message) public {
        emit Message(msg.sender, to, message);
    }
}