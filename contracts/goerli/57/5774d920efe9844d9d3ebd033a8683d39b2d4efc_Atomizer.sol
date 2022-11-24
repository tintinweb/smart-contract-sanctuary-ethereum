/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Atomizer {
    function atomize(
        address[] memory addrs,
        bytes[] memory calldatas
    ) public {
        require(addrs.length == calldatas.length, "addrs.length == calldatas.length");

        for (uint256 i = 0; i < addrs.length; i++) {
            (bool success, ) = addrs[i].call(
                calldatas[i]
            );
            require(success, "function execution was not successfull");
        }
    }
}