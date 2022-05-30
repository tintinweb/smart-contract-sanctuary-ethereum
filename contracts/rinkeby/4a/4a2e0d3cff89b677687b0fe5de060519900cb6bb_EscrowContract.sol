/**
 *Submitted for verification at Etherscan.io on 2022-05-30
*/

// SPDX-License-Identifier: MIT;
pragma solidity ^0.6.6;

contract EscrowContract {

    // Gamers account
    struct client_account{
        int client_id;
        address client_address;
        uint client_balance_in_ether;
    }
    
    client_account[] clients;
    int clientCounter;

    //Charity account
    address payable manager;
    
    //Modifier so only joined clients can make certain calls
    modifier onlyClients() {
        bool isclient = false;
        for(uint i=0;i<clients.length;i++){
            if(clients[i].client_address == msg.sender){
                isclient = true;
                break;
            }
        }
        require(isclient, "Only clients can call this!");
        _;
    }
    
    //Make Charity Account the owner/manager of contract
    constructor() public{
        manager = payable(msg.sender);
        clientCounter = 0;
    }
    
    receive() external payable { }
   
    //Function to join MetaChess community
    function joinAsClient() public payable returns(string memory){
        clients.push(client_account(clientCounter++, msg.sender, address(msg.sender).balance));
        return "You are part of MetaChess !!!";
    }

    //Function to pay challenge fee
    function deposit() public payable onlyClients{
        payable(address(this)).transfer(msg.value);
    }
    
    //Function to withdraw winnings
    function withdraw(uint amount) public payable onlyClients{
        //amount in gwei
        msg.sender.transfer(amount * 0.9 gwei);
        manager.transfer(amount * 0.1 gwei);
    }
    
    //Function to check contract balance
    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }
}