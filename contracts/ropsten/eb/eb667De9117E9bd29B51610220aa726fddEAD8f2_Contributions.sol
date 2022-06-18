/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Contributions {

    uint public percentageCost = 0.005 ether; 
    address owner = 0x688495449167974aba93dBAAcEc3872Ed5EDDb69;
    bool public isSaleLive = false;

    mapping(address => uint) percentageBought;

    function DisplayPercentage(address _adrs) public view returns (uint) {
        return percentageBought[_adrs];
    }
    function BuyPercentage(uint _percentage) public payable {
        require(msg.value >= _percentage * percentageCost, "Incorrect Ether value");
        require(isSaleLive, "Not accepting contributions at the moment");
        percentageBought[msg.sender] += _percentage;
    }
    function flipSaleState() public {
        require(msg.sender == owner, "You are not the owner");
        isSaleLive = !isSaleLive;
    }
    function withdraw() external {
        require(msg.sender == owner, "You are not the owner");
        uint256 bal = address(this).balance;
        payable(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4).transfer(bal);
    }
    function changePercentageCost(uint _cost) public{
        require(msg.sender == owner, "You are not the owner");
        percentageCost = _cost;
    }
}