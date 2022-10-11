// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library DiamondHelper {
    address constant public DIAMOND = 0x6fDBEc3E714B378F05275D496d0998f02746E2Dd;

    function diamond() public pure returns (address) {
        return DIAMOND;
    }
}