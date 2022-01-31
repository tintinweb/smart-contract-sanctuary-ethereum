/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

pragma solidity 0.8.11;

contract HelloWorld {

    string public message;
    address public owner;

    constructor(string memory _message) {
        message = _message;
        owner = msg.sender;
    }
    function hello() public view returns (string memory) {
        return message;
    }

    function setMessage(string memory _message) public payable {
      require(msg.sender == owner, 'Only owner can set the message');
      message = _message;
    }

}