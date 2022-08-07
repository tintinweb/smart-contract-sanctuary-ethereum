/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

pragma solidity ^0.8.15;

contract bank{
    mapping(address=>uint256) balances;

    function deposit() payable public{
        balances[msg.sender] += msg.value;
    }
}