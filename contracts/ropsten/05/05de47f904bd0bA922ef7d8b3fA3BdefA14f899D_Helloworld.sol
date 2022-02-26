/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

pragma solidity 0.8.12;

contract Helloworld {

    address owner;
    string public message;

    constructor (string memory _message) {
        message = _message;
        owner = msg.sender;
    }

    function hello() public view returns(string memory) {
        return message;
    }

    function setMessage(string memory _message) public payable {
        require(msg.sender == owner);
        require(msg.value >= 1 ether);
        message = _message;
    }
}