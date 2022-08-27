/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract PriceAggreate {

    string constant public  pair = "USD/INR";
    uint256 public price;
    address private owner;
    
    constructor (address _owner){
        owner = _owner;
    }

    function fullfillPrice(uint256 _price) external returns (bool) {
       require(msg.sender==owner,"price can't update beacuase you are not owner!");
       price = _price; 
       return true;
    }

    function changeOwner(address _owner) external returns (bool) {
        require(msg.sender==owner," you are not owner!");
        owner=_owner;
        return true;
    }
}