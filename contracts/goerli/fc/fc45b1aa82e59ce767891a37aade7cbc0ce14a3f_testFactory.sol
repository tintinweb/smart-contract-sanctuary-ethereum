/**
 *Submitted for verification at Etherscan.io on 2022-07-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract childContract {
    function hello() public {}
}

contract testFactory {

    childContract public child;

function deployChild() public
    {
    child = new childContract();
    }
}