/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

pragma solidity ^0.5.2;

contract HelloWorld{

    string public message;
    constructor(string memory initMessage) public{
        message = initMessage;
    }
    function update(string memory Newmessage) public{
        message = Newmessage;
    }

}