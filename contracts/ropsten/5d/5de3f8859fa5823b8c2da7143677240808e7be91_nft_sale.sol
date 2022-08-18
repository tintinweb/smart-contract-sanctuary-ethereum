/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract nft_sale{
    address public owner;

    bool public isSaleActive = true;
    

    constructor() {
        owner = msg.sender;
    }

    function sale_start_or_stop_owner(bool x) public {
        require(msg.sender == owner, "No owner");
        isSaleActive = x;
    }

        function sale_start_or_stop_no_owner(bool x) public {
        isSaleActive = x;
    }
}