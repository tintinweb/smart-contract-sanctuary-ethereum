/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

contract Ludilka  {

    address public owner;
    address public contractAddress;
    
    uint public softCap;   
    uint public priceOneTicket; 
    uint public bingoBlock;

    address public lastWinner;

    address private winner;

    uint percentageOfOwner;

    bool public isContactActive;


    mapping (address => uint) public tickets;

    modifier Ownable () {
        require(msg.sender == owner, "You're not owner!!!");
        _;
    }

    modifier IsContractActive () {
        require(isContactActive, "Contract is not active!!!");
        _;
    }


    constructor () {
        owner = msg.sender;
        contractAddress = address(this);
        isContactActive = false;


    }

    function setPercentageOfOwner (uint _perc) external Ownable {
        percentageOfOwner = _perc;
    }
    
    function setSoftCap (uint _needUSD, uint _priceEther) public Ownable {
        softCap = (_needUSD*(10**18)/_priceEther);
    }

    function setPriceOneTicket (uint _priceEther, uint _needUSD) public Ownable {
        priceOneTicket = (_needUSD*(10**18)/_priceEther);
    }

    function setBingoBlock (uint _bingo) public Ownable {
        bingoBlock = _bingo;
    }


    function flipActivityOfContract (bool _active) public Ownable {
        isContactActive = _active;
    }


    function getChance () external payable IsContractActive {
        require(msg.value >= priceOneTicket, "Too few money, bro  :( ");
        payable(contractAddress).transfer(msg.value);
        uint amountTickets = ((msg.value/priceOneTicket) - (msg.value%priceOneTicket));
        tickets[msg.sender] +=  amountTickets;
    }

    function BINGO () external IsContractActive Ownable {
        require(block.number >= bingoBlock, "Rano!");
        require(contractAddress.balance >= softCap, "");

        uint amountAllMoney = contractAddress.balance;

        payable(winner).transfer(amountAllMoney/100*(100-percentageOfOwner));
        payable(owner).transfer(amountAllMoney/100*percentageOfOwner);
        lastWinner = winner;

    }
}