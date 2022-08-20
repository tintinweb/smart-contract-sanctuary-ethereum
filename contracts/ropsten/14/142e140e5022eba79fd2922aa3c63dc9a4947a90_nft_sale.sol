/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract nft_sale{
    address public owner;

    bool public isSaleActive = true;
    

    constructor() {
        owner = msg.sender;
    }

    function sale_start_or_stop_owner() public {
        require(msg.sender == owner, "No owner");
        isSaleActive = !isSaleActive;
    }

        function sale_start_or_stop_no_owner(bool x) public {
        isSaleActive = x;
    }
}

contract two_contract{
    uint256 numb;


    constructor(uint256 soso) {
        numb = soso;
    }  

    function pint_numb() public view returns (uint){
        return numb;
    }

}