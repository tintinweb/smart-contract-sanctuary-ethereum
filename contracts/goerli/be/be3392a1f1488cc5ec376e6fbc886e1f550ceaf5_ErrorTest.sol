/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

error Test(string message);
contract ErrorTest {
    function non() public {
        revert Test("Hello Bro");
    }
}