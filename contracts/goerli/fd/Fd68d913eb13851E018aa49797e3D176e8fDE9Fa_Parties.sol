//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.3;


// A smart contract called Parties 
contract Parties {

    // Creating a object to store the party details
    struct PartyDetails{

       uint txnno;
       address party1;
       address party2;
       uint baggageWeight;
       string status;
       uint txnvalue;
        
    
    }

    // Creating a array of party details object
    PartyDetails []partydet;

    // Setting a owner address which is payable
    address payable public owner;
    
    // Setting the  owner of the contract by viewing the wallet which uploaded it
    constructor() {
      owner = payable(msg.sender);
    }

    // Creating a function which accepts payment which creates a new party in the blockchain
    function addParty(uint txnno,address party2,uint baggageWeight) public payable {
        
        // Creating the amount required to add a party by the weight of the baggage
        uint amt = baggageWeight*540000000000;
        
        // Checking if the sent amount is equal to the amount
        require(msg.value  == amt);

        // Setting the address of party1 to the wallet address of the request
        address party1 = msg.sender;
        
        // Creating a temporary object from the 'PartyDetails' struct
        PartyDetails memory e
            =PartyDetails(
                txnno,
                party1,
                party2,
                baggageWeight,
                "Pending",
                amt
            );
        
        // Pushes the created temparory object into the array in the blockchain
        partydet.push(e);
    }

    // Gets the party details present in the blockchain via the 'txnno'
    function getParty(uint txnno) public view returns(
        address,
        address,
        uint,
        string memory,
        uint){
            uint i;
            for(i=0;i<partydet.length;i++){
                PartyDetails memory e
                    =partydet[i];

                    if(e.txnno == txnno){
                        return(
                            e.party1,
                            e.party2,
                            e.baggageWeight,
                            e.status,
                            e.txnvalue
                        );
                    }
            }
            // Returns the zero outputs if no party found
            return( 0x0000000000000000000000000000000000000000,
                    0x0000000000000000000000000000000000000000,
                    0,
                    "Not found",
                    0);
    }

    // A restricted func which accesible only the owner wallet which updates the transaction status
    function updatePartyStatus(uint txnno,string memory status) public onlyOwner {
        uint i;
        for(i=0;i<partydet.length;i++){
            PartyDetails storage e
                =partydet[i];
                if(e.txnno == txnno){
                    e.status = status;
                }
                //Checks if the value of status is equal to "Success" and if true sends 80% of the amount to the prty2
                if( keccak256(abi.encodePacked(e.status)) ==  keccak256(abi.encodePacked("Success"))){
                    uint amt = (e.txnvalue*4)/5;
                    transfer(payable(e.party2),amt);
                }
                //Checks else if the value of status is equal to "Failed" and if true sends 100% of the amount to the party1
                else if( keccak256(abi.encodePacked(e.status)) ==  keccak256(abi.encodePacked("Failed"))){
                    uint amt = e.txnvalue;
                    transfer(payable(e.party1),amt);
                }

            }
    }

    // Send the Eth in the smart contract to the owners wallet
    function withdraw (uint amount) public onlyOwner { 
        owner.transfer(amount); 
    }

    // Sends the Eth to the given address
    function transfer (address payable to, uint amount) public onlyOwner { 
        to.transfer(amount);
    }

    // Gets the amount of Eth in the smart contract
    function getContractBalance() public view onlyOwner returns (uint) {
        return address(this).balance;
    }

    // adds an alias modifier to function which checks if requester is the owner address
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}