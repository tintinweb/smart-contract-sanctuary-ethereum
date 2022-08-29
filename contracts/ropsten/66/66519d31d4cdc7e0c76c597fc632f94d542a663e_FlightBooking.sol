/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract FlightBooking {

    //state variables
    uint constant public INSURANCE_AMOUNT = 10000 wei;
    uint constant public INSURANCE_PRICE = 500 wei;

    address immutable public INSURANCE_COMPANY;

    mapping (address => bool) public hasBoughtInsurance;
    address[]  allInsuranceBuyers; 


   // modifiers
    modifier onlyOwner(){
        require(msg.sender == INSURANCE_COMPANY, "you are not the owner!");

        _;
    }


    
    //functions
    constructor() payable{
        require(msg.value >= 1 ether, "add more ethers");
        INSURANCE_COMPANY = msg.sender;
    }


    function buyInsurance() public payable {
        require(hasBoughtInsurance[msg.sender] == false, "you have already booked insurance!");

        hasBoughtInsurance[msg.sender] = true;
        allInsuranceBuyers.push(msg.sender);

        payable(INSURANCE_COMPANY).transfer(INSURANCE_PRICE);

    }



    function setFlightLate() public onlyOwner(){
        for(uint i=0; i < allInsuranceBuyers.length; i++){
            hasBoughtInsurance[allInsuranceBuyers[i]] = false;

            (bool sent, bytes memory data) = payable(allInsuranceBuyers[i]).call{value: INSURANCE_AMOUNT + INSURANCE_PRICE}("sent");
            require(sent, "there is a problem in the transiction!");

        }

        delete allInsuranceBuyers;
    }


    function showAllInsuranceBuyers() public view returns(address[] memory){
        return allInsuranceBuyers;
    }

    fallback() payable external{}

    
}