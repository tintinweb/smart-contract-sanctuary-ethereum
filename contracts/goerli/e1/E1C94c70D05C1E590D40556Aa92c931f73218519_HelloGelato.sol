/**
 *Submitted for verification at Etherscan.io on 2022-09-29
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IResolver {
    function checker() external view returns (bool canExec, bytes memory execPayload);
}

contract HelloGelato is IResolver {
    uint256 public counter;

    function checker() external view override returns (bool canExec, bytes memory execPayload) {
        if (counter < 10) {
            execPayload = abi.encodeWithSelector(HelloGelato.increment.selector);
            return (true, execPayload);
        } else {
            return (false, bytes("over 10"));
        }
    }

    function increment() external {
        counter++;
    }
}