// SPDX-License-Identifier: MIT
// This contract was adapted from the ERC777 standard contract and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This following piece of code complements synpulseTokenGlobal contract. 
// It specifies the roles as well as the on / off function of the overall token contract.

pragma solidity ^0.8.0;



contract Bank {
    address public owner;
    mapping(address => bool) public isKYCAddress;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require( msg.sender == owner, "You are not the owner");
        _;
    }

    function addToKYC(address _address) public onlyOwner {
        isKYCAddress[_address] = true;
    }

    function removeFromKYC(address _address) public onlyOwner {
        isKYCAddress[_address] = false;
    }
}