/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.4.17;
contract messageBaird{
    string public message;
    int public persons=0;
    constructor(string memory initMessage) public {
        message = initMessage;
    }
    function editMessage(string memory _editMessage) public{
        message =  _editMessage;
    }
    function showMessage () public view returns (string memory){
        return message;
    }
    function pay () public payable{
        persons=persons+1;
    }
}