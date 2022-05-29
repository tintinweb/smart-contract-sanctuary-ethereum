//SPDX-License-Identifier: GPL-3.0-or-later
// Created by Prasanna Venkatesh.S

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Counters.sol";

// A smart contract called Parties 
contract Parties {

    using Counters for Counters.Counter;

    Counters.Counter private _txnIdCounter;

    // Creating a object to store the party details
    struct PartyDetails{

       uint txnno;
       address party1;
       address party2;
       uint baggageWeight;
       uint128 baggageValue;
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
    function addParty(address party2,uint baggageWeight,uint128 baggageValue) public payable {
        
        uint256 txnno = _txnIdCounter.current();
        _txnIdCounter.increment();
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
                baggageValue,
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
                            e.baggageValue,
                            e.status,
                            e.txnvalue
                        );
                    }
            }
            // Returns the zero outputs if no party found
            return( 0x0000000000000000000000000000000000000000,
                    0x0000000000000000000000000000000000000000,
                    0,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}