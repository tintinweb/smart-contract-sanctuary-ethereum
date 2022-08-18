/**
 *Submitted for verification at Etherscan.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract nft_sale{
    address public owner;

    bool public isSaleActive = true;
    

    constructor() {
        owner = msg.sender;
    }

    function sale_start_or_stop(bool x) public {
        require(msg.sender == owner, "No owner");
        isSaleActive = x;
    }

   
}