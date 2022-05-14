/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT LICENSED

pragma solidity ^0.7.0;

contract USDB{

    string public name = "USDB";         //token name
    string public symbol = "UB";      // token symbol
    uint public tokenSupply;           //token supply , it will be equal to total investment in ether and base ether is One;
    address public owner;              // contract owner
    mapping(address=>uint) holderBook; // record of all investors with their investment
    address[] public usdbHolders;        // all investors in array
    
    function assignToken(address _to, uint amt) public {
        tokenSupply+=amt;
        holderBook[_to] += amt; 
    }

    constructor(){
        owner = msg.sender;
    }

    function unassignToken(address _to, uint amt) public {
        tokenSupply-=amt;
        holderBook[_to] -= amt;
    }

}

contract BANK{
    string public name = "BANK";          //token name
    string public symbol = "BNK";      // token symbol
    uint public tokenSupply;           //token supply , it will be equal to total investment in ether and base ether is One;
    address public owner;              // contract owner
    uint public profitPerToken;        // how many multipal of investment
    mapping(address=>uint) recordBook; // record of all investors with their investment
    address[] public investers;        // all investors in array
    address public usdbAddress;
    mapping(address=>uint) stakeBook;

    constructor(){
        owner = msg.sender;            // assign owner
    }

    function invest() payable public{
        require(msg.value >= 10**10 wei,"0.0000001 ether min req");
        require(msg.value/(10**10) + tokenSupply <= 1000000000,"token cant be mint over 1 billion");
        if(recordBook[msg.sender]==0)
        investers.push(msg.sender);
        recordBook[msg.sender] += msg.value/(10**10);
        tokenSupply += msg.value/(10**10);
    }

    function MyBalanceOf() public view returns(uint){
       return recordBook[msg.sender];
    }

    function revenueShare() public {
    require(msg.sender==owner,"only owner can run this function");
     for(uint256 i=0; i<investers.length; i++){
         address payable x = payable(investers[i]);
         x.transfer(profitPerToken * recordBook[investers[i]]);
       }
       profitPerToken = 0;
    }

    function sendProfit() public payable{
       require(msg.sender==owner,"only owner can run this function");
       profitPerToken = msg.value/tokenSupply;
   }

    function contractBalance() public view returns(uint){
       return address(this).balance;
    }

    function setUsdbAddress(address x) public {
        require(msg.sender == owner,"you are not owner");
        usdbAddress = x;
    } 

    function stakeBank(uint amt) public {
        require(recordBook[msg.sender]>=amt,"not enough token to stake");
        USDB usdb = USDB(usdbAddress);
        recordBook[msg.sender] -= amt;
        stakeBook[msg.sender] += amt;
        usdb.assignToken(msg.sender,amt);
    }

    function unStakeBank(uint amt) public{
    require(stakeBook[msg.sender]>=amt,"not have this much stake bank");
        USDB usdb = USDB(usdbAddress);
        stakeBook[msg.sender] -= amt;
        recordBook[msg.sender] += amt;
        usdb.unassignToken(msg.sender,amt);
    }
    
    function myStaking() view public returns(uint){
        return stakeBook[msg.sender];
    }

}