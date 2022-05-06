/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

pragma solidity ^0.4.26;

contract invest {
    string Title = "Crowd-Founding";
    uint public investors = 0;
    int256 public investAmount = 0;

    function pay(int256 money) public payable {
        investors++;
        investAmount = investAmount + money;
    }
}