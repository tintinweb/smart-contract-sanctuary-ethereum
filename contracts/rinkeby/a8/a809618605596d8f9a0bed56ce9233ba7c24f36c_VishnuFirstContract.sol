/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract VishnuFirstContract {

    uint256 product_quantity;

    constructor() {
        product_quantity = 100;
    }
    
    function get_quantity() public view returns(uint256) {
        return product_quantity;
    }

    function update_quantity(uint256 value) public {
        product_quantity = product_quantity + value;
    }

}