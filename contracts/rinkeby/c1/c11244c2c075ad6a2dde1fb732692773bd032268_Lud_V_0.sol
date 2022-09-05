/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.16;


contract  Lud_V_0{

    uint softCap;
    uint amountBlocks;
    bool contractPause;
    address owner;
    uint minPay;
    mapping (address => uint) tickets;

    constructor (bool _pause) {
        owner = msg.sender;
        contractPause = _pause;
    }

    function whoIsOwner () public view returns (address){
        return owner;
    }

    function howMuchIsSoftCap () public view returns (uint){
        return softCap;
    }

    function howMuchAreAmountBlocks () public view returns (uint){
        return amountBlocks;
    }

    function isPause () public view returns (bool){
        return contractPause;
    }

    function showMinPay () public view returns (uint){
        return minPay;
    }



    modifier Ownable () {
        require(msg.sender == owner, "Caller is not owner!");
        _;
    }

    modifier IsPauseble () {
        require(!contractPause, "Contract is pause!");
        _;
    }



    function setSoftCap (uint _softCap) public Ownable IsPauseble {
        softCap = _softCap;
    }

    function setAmountBlocks (uint _amountBlocks) public Ownable IsPauseble {
        amountBlocks = _amountBlocks;
    }

    function pauseble (bool _pause) public Ownable {
        contractPause = _pause;
    }

    function setMinPay (uint _minPay) public Ownable {
        minPay = _minPay;
    }


    function calc (uint _am) private pure returns (uint) {
        uint res = (_am / 100);
        return res;
    }

    function getChance (uint _payAmount) public payable IsPauseble {
        require(msg.value >= minPay);
        uint _tickets = calc(_payAmount);
        tickets[msg.sender] = _tickets;
    }

    function getAmountTicketsByOwner (address _address) public view returns (uint) {
        uint vari = tickets[_address];
        return vari;
    }

    function withdraw() public Ownable {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }


}