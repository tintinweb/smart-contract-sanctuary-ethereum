/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity >0.5.0;

contract My_5{  

    string public message;
    
    function setMessage(string memory _newMessage)public{
        message = _newMessage;
    }
    
    function getMessage()public view returns(string memory){
    return message;
    }
    
}