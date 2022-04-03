/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

pragma solidity >= 0.4.22 < 0.7.0;

contract mesageBoard {
    string public message;
    int public person = 0;
    constructor(string memory initMessage) public {
        message = initMessage;
    }
    function editMessage(string memory _editMessage) public{
        message = _editMessage;
    }
    function showMessage() public view returns(string memory) {
        return message;
    }
    function pay() public payable{
        person = person + 1;
    }
}