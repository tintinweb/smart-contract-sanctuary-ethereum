/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

contract Test2 {
    address public deployer;

    constructor() {
        deployer = msg.sender;
    }
    function killme() public {
        selfdestruct(payable(address(this)));
    }
}