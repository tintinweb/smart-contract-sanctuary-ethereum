/**
 *Submitted for verification at Etherscan.io on 2023-03-03
*/

// SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.7.0 <0.9.0;    //Version

contract Rental {                  //Smart Contract
    address payable houseOwner1;
    address payable houseOwner2;

    constructor(address payable owner1, address payable owner2) { //Constructor
        houseOwner1 = owner1;
        houseOwner2 = owner2;
    }

    function payRental() payable public  {
        //only 2 lines of code to split
        houseOwner1.transfer(msg.value/2);
        houseOwner2.transfer(msg.value/2);
    }

    function getOwners() public view returns (address,address) { //Function
        return (houseOwner1,houseOwner2);
    }
}