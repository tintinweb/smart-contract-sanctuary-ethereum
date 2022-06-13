/**
 *Submitted for verification at Etherscan.io on 2022-06-13
*/

pragma solidity 0.8.7;

contract Messages {

    string message = "";

    function setMessage(string calldata newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}