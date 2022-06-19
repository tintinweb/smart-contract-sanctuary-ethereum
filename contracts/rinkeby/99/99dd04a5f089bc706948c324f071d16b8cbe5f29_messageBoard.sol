/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

pragma solidity ^0.4.23;

contract messageBoard{
    string public message;
    int public num = 129;
    
    //函式傳參數
    function messageBoard(string initMessage) public {
        message = initMessage;
    }
    function editMessage(string _editMessage) public {
        message = _editMessage;
    }
}