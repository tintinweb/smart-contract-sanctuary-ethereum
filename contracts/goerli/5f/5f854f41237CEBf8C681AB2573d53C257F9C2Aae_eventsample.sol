/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.7;

 contract eventsample
 {
       event ProductAdded(uint productID, uint price);

       function addproduct(uint prodId, uint price) public {
           emit ProductAdded(prodId, price);
       }
    
 }