/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// Contract_invest.sol

pragma solidity ^0.4.26;

contract invest{
       string public Title = "Crowd-Funding";
       uint public investors = 0;


 function pay(int256 money) public{
       investors++;
 } 
}