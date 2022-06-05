/**
 *Submitted for verification at Etherscan.io on 2022-06-04
*/

pragma solidity 0.8.7;

contract Messages {

    string message = "";

    function setMesage(string calldata newMessage) public {
        message = newMessage;
    }

    function getMessage() public view returns (string memory) {
        return message;
    }
}