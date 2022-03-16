/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "./Erc20.sol";

contract GachaGame {
    //common 40 rare 30 epic 20 legendary 10
    uint256[] private numbers;
    uint256[] private gachaPool;

    string[] numToRare = ["common","rare","epic","legendary"];

    struct account{
        string name;
        uint256 pull;
        uint[4] totalTicket;
    }

    struct ticket{
        string rare;
        uint256 timeStamp;
    }
       
    mapping(address => account) public accountInfo;

    mapping (address => ticket[]) public ticketlist;

    
    constructor(){
        genGachaPool();
    }

    // add address => account.name 
    function register(string memory newName)public{
        accountInfo[msg.sender].name = newName;
    }

    function onePullGacha()public payable{ 
        if(accountInfo[msg.sender].pull >= 10){
            revert();
        }
        address payable dev = payable(0x7334E2543D829aa7C2C8d955F4ba9B49a4eE065c);
        dev.transfer(10000000000000);
        accountInfo[msg.sender].pull += 1;
        ticket memory rollInfo ;
        uint rareNumber = gachaPool[random()];
        rollInfo.rare = numToRare[rareNumber];
        accountInfo[msg.sender].totalTicket[rareNumber] += 1;
        rollInfo.timeStamp = block.timestamp;
        ticketlist[msg.sender].push(rollInfo);

    }

    function showMyGachapull() public view returns(uint common,uint rare,uint epic,uint legendary){
        common = accountInfo[msg.sender].totalTicket[0];
        rare = accountInfo[msg.sender].totalTicket[1];
        epic = accountInfo[msg.sender].totalTicket[2];
        legendary = accountInfo[msg.sender].totalTicket[3];
    }


    function random()public view returns (uint256) {
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.difficulty,block.timestamp)));
        return randomHash%100;
    } 

    function showUserGachapull(address userAddress)public view returns(uint common,uint rare,uint epic,uint legendary){
        common = accountInfo[userAddress].totalTicket[0];
        rare = accountInfo[userAddress].totalTicket[1];
        epic = accountInfo[userAddress].totalTicket[2];
        legendary = accountInfo[userAddress].totalTicket[3];
        
    }
 
    function genGachaPool() private{
    // common 40
    for (uint i=0; i<40; i++) {
        gachaPool.push(0);
    }
    //rare 30 
    for (uint i=0; i<30; i++) {
        gachaPool.push(1);
    }
    //epic 20
    for (uint i=0; i<20; i++) { 
        gachaPool.push(2);
    }
    //legendary 10
    for (uint i=0; i<10; i++) {
        gachaPool.push(3);
    }
    }
    

}