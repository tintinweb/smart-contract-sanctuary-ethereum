/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

pragma solidity ^0.4.17;

contract Vote {

    string public message;

    constructor(string _message) public{
        message=_message;
    }

    function setMessage(string _message) public{
        message=_message;
    }

    function getMessage() public view returns(string){
        return message;
    }

}