/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface IExternalContract {
    function balanceOf(address owner) external view returns (uint256);
}

contract Caller {
    function balanceOf(address owner, address contractAddress) public view returns (uint256) {
        return IExternalContract(contractAddress).balanceOf(owner);
    }
}