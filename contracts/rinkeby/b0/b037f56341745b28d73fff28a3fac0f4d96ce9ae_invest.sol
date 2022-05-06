/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.4.26;

contract invest{
 string Title = "Crowd-Funding";
 uint public investors = 0;

 function pay() public payable{
  investors++;
 } 

}