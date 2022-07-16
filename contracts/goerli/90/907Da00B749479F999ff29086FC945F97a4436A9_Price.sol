/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Price {

    modifier correctQuantity(uint256 quantity){
        require(quantity >= 1, "Cannot get a price less than one");
        _;
    }

    function cardPrice(uint256 copies) external pure correctQuantity(copies) returns(uint256) {
        if (copies <= 4) {
            return 4.667*10**18*copies;
        }else if (copies <= 10) {
            return 3.667*10**18*copies;
        }else if (copies <= 20) {
            return 2.980*10**18*copies;
        }else if (copies <= 100) {
            return 2.3*10**18*copies;
        }else{
            return 2*10**18;
        }
    }

    function stampPrice() external pure returns(uint256) {
        return 0.5*10**18;
    }
}