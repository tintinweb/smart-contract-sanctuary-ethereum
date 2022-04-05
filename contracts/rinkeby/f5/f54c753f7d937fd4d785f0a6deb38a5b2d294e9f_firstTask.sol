/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity >=0.7.0 < 0.9.0;

contract firstTask{
    string public message = "Hello World";
    constructor(){}
 
    function getMessage() public{}

    function setMessage(string memory _UserString) public {
        message = _UserString;
    }
    }