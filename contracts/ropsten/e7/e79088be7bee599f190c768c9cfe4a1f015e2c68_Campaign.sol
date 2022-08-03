/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
contract Campaign {
    string public title;
    uint256 public requiredAmount;
    string public image;
    string public story;
    address payable public owner;
    uint256 public receivedAmount;
event donated(address indexed donar,uint indexed Amount,uint indexed timestamp);
constructor(){
    title="CampaignTitle";
    requiredAmount=100;
    image="imgURI";
    story="storyURI";
    owner=payable(msg.sender);
}
function donate()public payable{
    require(requiredAmount>receivedAmount,"Required Amount Fullfill !");
    owner.transfer(msg.value);
    receivedAmount+=msg.value;
    emit donated(msg.sender,msg.value,block.timestamp);
}
}