/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

pragma solidity 0.8.17;

contract SaveMessageContract {
    mapping(address => string) public messages;

     function updateMessages(string calldata message) public payable {
        require(msg.value == 0.001 ether);
        messages[msg.sender] = message;
    }
}