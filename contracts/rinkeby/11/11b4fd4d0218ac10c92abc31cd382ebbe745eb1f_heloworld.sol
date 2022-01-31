/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

pragma solidity >=0.5.0 <0.6.0;
contract heloworld{
    string private message;
    constructor( string memory _message) public{
        message = _message;   
    }
    function getterMessage() public view returns(string memory) {
        return message ;
    }   
    function setterMessage(string memory _message) public {
       message= _message;    
    }
    }