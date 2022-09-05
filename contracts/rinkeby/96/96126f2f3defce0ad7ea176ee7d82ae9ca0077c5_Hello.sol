/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

contract Hello
{
    string message;
    constructor()
    {
        message = "Hello world";
    }
    function setMessage(string memory _str)public payable 
    {
        require(msg.value > 0.0001 ether,"Not enough amount");
        message = _str;

    }

    function getMessage()public view returns(string memory)
    {
        return message;
    }

    function getSender()public view returns(address)
    {
        return msg.sender;
    }
}