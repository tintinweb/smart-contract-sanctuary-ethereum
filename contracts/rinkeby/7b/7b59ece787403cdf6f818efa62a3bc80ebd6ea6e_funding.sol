/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//To collect funds for a project
pragma solidity ^0.4.26;

contract funding {
    string public title = "Crowd Funding";
   uint256 public investors = 0;
    int256 public Amount = 0;

    function pay (int256 _money) public{
        Amount = Amount + _money;
        investors++;
    }  
}