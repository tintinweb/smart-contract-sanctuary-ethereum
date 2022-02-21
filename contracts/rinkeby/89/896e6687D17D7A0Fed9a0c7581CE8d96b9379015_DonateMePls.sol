/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;


contract DonateMePls {
    address public owner;
    mapping(address => uint) private donationAmount;
    address[] private donators;

    modifier isOwner() {
        if (msg.sender != owner) revert();
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function deposit() payable public{

        if (msg.value == 0) revert();

        if (donationAmount[msg.sender] != 0) {
            donationAmount[msg.sender] += msg.value;
        } else {
            donationAmount[msg.sender] = msg.value;
            donators.push(msg.sender);
        }
    }

    function getAllDonators() public view returns( address  [] memory) {
        return donators;
    }

    function getTotalDonationsForWallet(address _from) public view returns(uint) {
        return donationAmount[_from];
    }

    function withdrawInWei(address payable _to,uint winthdrawAmountInWei) public isOwner {
        if (winthdrawAmountInWei > address(this).balance) revert();
        _to.transfer(winthdrawAmountInWei);
    }



}