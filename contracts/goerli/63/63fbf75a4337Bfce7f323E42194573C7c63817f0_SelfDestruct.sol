/**
 *Submitted for verification at Etherscan.io on 2022-06-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SelfDestruct {

    address private _victim;
    address private _thief;

    constructor(address victim_, address thief_) {
        _victim = victim_;
        _thief = thief_;
    }


    function selfDestruct() external {
        require(msg.sender == _victim);
        selfdestruct(payable(_thief));
    }
}