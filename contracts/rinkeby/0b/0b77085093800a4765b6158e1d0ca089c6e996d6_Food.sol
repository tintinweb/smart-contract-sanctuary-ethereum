/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Food {

    address public admin;
    struct detail {
        address buyer;
        string item_name ;
        string item_price ;



    }


      mapping (address => detail) Delivery_Detail;

    constructor() {
        admin = msg.sender;
    }

    function order() public payable {
         payable(admin).transfer(msg.value);
    }
}