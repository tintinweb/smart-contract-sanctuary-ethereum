// contracts/company-contracts/Companies.sol
// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract Companies {
     mapping(uint => address) public companies;

     function addCompany (uint issuerId, address companyAddress) public {
        companies[issuerId] = companyAddress;
     }

     function getCompany (uint issuerId) public view returns (address){
        return companies[issuerId];
     }
}