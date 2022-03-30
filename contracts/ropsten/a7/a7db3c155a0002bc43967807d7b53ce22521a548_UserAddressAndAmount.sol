/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract UserAddressAndAmount {
    struct data {
        uint256 amount;
        uint256 date;
    }
    mapping(address=>data) public Address;
    function addData(address[] memory userAddress, uint256[] memory amount, uint256[] memory date) public {
        require(userAddress.length <= 100, "Length is not greater than 100!");
        require(userAddress.length == amount.length, "Length has mistmatch!");
        require(amount.length == date.length, "Length has mistmatch!");
        for(uint256 i=0; i<userAddress.length; i++){
            Address[userAddress[i]]=data(amount[i], date[i]);
        }
    }
}