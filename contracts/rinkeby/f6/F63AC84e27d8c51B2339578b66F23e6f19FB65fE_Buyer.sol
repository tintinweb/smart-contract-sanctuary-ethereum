// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.0;

interface Shop {
    function isSold() external view returns (bool);

    function buy() external;
}

contract Buyer {
    Shop shopie = Shop(0xb6a213C1763C25ca7c0058e842D1BE5e42d8157f);

    function price() public view returns (uint256) {
        bool sold = shopie.isSold();

        if (sold) {
            return 5;
        } else {
            return 100;
        }
    }

    function buying() public {
        shopie.buy();
    }
}