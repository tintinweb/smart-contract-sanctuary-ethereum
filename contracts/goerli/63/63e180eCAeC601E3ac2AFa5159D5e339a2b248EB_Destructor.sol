/**
 *Submitted for verification at Etherscan.io on 2022-12-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Destructor {
    constructor() payable {}

    function destroy() external {
        selfdestruct(payable(address(this)));
    }
}