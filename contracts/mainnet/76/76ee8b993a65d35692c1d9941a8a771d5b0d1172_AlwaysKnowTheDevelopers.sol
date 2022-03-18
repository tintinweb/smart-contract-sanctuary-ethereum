/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: Whoops

pragma solidity ^0.8.7;

contract AlwaysKnowTheDevelopers {
    address constant one   = address(0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae);
    address constant two   = address(0xef764BAC8a438E7E498c2E5fcCf0f174c3E3F8dB);
    address constant three = address(0x9D221b2100CbE5F05a0d2048E2556a6Df6f9a6C3);
    address constant four  = address(0xA4Fe8067cC11d5D6513DAD75a215988e43e6E3C5);
    address constant five  = address(0x520885De1075712818D0435371A116F6d8566C67);
    address constant six   = address(0x7435a9D165dEC083f4D61D572c65e6d898e6b606);
    address constant seven = address(0x11e52c75998fe2E7928B191bfc5B25937Ca16741);

    mapping(address => bool) hasShare;

    uint256 share;

    constructor() payable {
        share = msg.value / 6;

        hasShare[one]   = true;
        hasShare[two]   = true;
        hasShare[three] = true;
        hasShare[four]  = true;
        hasShare[five]  = true;
        hasShare[six]   = true;
    }

    function getMeOutOfHere() public {
        require(hasShare[msg.sender]);
        hasShare[msg.sender] = false;

        payable(msg.sender).transfer(share);
    }

    function recover() public {
        require(msg.sender == seven);
        payable(seven).transfer(address(this).balance);
    }
}