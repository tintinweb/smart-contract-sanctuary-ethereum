/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

pragma solidity ^0.4.13;

contract Test{
    uint public number;
    function setNumber(uint _num) view public{
        number = _num;
    }
    function () public payable {}
}