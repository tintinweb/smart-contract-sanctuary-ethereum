// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Registry{
    address[] public registryOfLoans; 
    mapping (address => bool) public loanExists;
    event loanAddedToRegistry(address newloan);

    constructor()
    {
        
    }

    function addLoan(address _address) internal returns (bool){
        registryOfLoans.push(_address);
        loanExists[_address] = true;
        emit loanAddedToRegistry(_address);
        return true;
    }
}