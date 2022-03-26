/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

//SPDX-License-Identifier: MIT
// Trust is a fundation part of Web3.0 The way wecan trust a Smart Contract is bybeing 
// Able to see the source. FOr this reason is importat to indicate the license  
// Used to indicate relevant license information of source code and how to reuse. 

//Docs are here: https://docs.soliditylang.org/

//Personaly, I would pick one version prior the latest one, better chances fo increasing stablility of Solidity 
// Will always enforce the compiler to avoid compiling my smart contract with different verions after deployment.
pragma solidity = 0.7.0;

//Name of the contract and show when is deployed. 
contract GoFundMe {

    //function deposit
    //function to withdraw
    //function to see balance


    
    //    Variables Types: 
    //   - Integers: int, uint, uint, int8, int16 // in 8th steps Bits; Default is 256bits 
    //   - Boolean
    //   - 
    
    //In solidity, float/double data types are not provided till yet. 
    //If you want to perform this calculation for ether, 
    //you should use the different units of ether.
    //example: https://eth-converter.com/

    uint minimunWei = 10000000000000000; // 10 ** 9 ; 10^9 to the power of 9
    address Bob = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    // FUctions Types:
    // - view: Read-only, dont alter the contract
    // - pure: Does nothing. 
    // - 


    // eth * 10^9 
    function fund() payable public {
        //THis will automatically check for the condition, if fails:
        //reverts back all the changes made to the contract and refund all the remaining gas fees we offered to pay.
        //msg is the address that is interacting with the contract.
        require(msg.sender != Bob, "Ok, Bob...");
        require(msg.value >= minimunWei, "Error: Minimun is 0.1E , please send more ETH. :)");   
    }

    function getBalance() public view returns(uint256) {
        // again this is the contract. 
        // balance is the balance of the contract
        return address(this).balance;
    }

    function withdraw() payable public {
        //this = Contract that you are interacting with.
        // Address and Balance
        require(msg.sender == Bob, "This is only for Bob");
        require(address(this).balance > 0, "No ETH available.");
        //Transfer will transfer the balance of the contract to the sender (account interacting with the contract)
        msg.sender.transfer(address(this).balance);
    }
}