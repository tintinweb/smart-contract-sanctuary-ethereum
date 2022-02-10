/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.8.0;

contract MessageBoard {
    string public message;
    int public num = 129;
    int public people = 0;

    constructor() {
        message = "Hello World";
    }

    function messageBoard(string memory initMessage) public {
        message = initMessage;
    }

    function editMessage(string memory _editMessage) public {
        message = _editMessage;
    }

    function pay() public payable {
        people++;
    }

    function get() public view returns (uint256) {
        return address(this).balance;
    }
}