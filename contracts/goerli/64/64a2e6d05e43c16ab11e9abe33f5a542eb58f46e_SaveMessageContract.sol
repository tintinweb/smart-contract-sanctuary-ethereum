/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

pragma solidity 0.8.17;

contract SaveMessageContract {
    mapping(address => string) public messages;

    event savedMessage(address indexed _from, string indexed _message);

     function updateMessages(string calldata message) public payable {
        require(msg.value == 0.001 ether);
        messages[msg.sender] = message;
        emit savedMessage(msg.sender, message);
    }
}