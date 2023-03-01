/**
 *Submitted for verification at Etherscan.io on 2023-03-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

contract Test {
    string quote;

    function setQuote(string memory _quote) public {
        quote = _quote;
    }
}