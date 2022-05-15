/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    string private message = "hello world";

    function getMessage() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory newMessage) public {
        message = newMessage;
    }
}