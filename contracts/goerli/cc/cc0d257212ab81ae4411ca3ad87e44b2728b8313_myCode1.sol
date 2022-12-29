/**
 *Submitted for verification at Etherscan.io on 2022-12-29
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;


contract myCode1
{
    uint256 public store;
    function write(uint256 _store) public
    { //1003e2d2 = 1003e2d200000000000000000000000000000000000000000000000000000001 =21188-21336
        store=_store;
    }

    function read() public view returns (uint256 _store)
    { //57de26a4 = 57de26a400000000000000000000000000000000000000000000000000000000 =21176-23613
        return(store);
    }
}