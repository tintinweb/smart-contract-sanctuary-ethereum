/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

pragma solidity 0.8.7;

contract Message {

    string message = "";

    function setMessage(string calldata newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory){
        return message;
    }
}