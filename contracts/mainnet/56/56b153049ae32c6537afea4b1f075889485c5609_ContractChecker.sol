/**
 *Submitted for verification at Etherscan.io on 2022-11-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ContractChecker {
    function isContract(address account) public view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function isMultipleContracts(address[] calldata accounts)
        external
        view
        returns (bool[] memory)
    {
        bool[] memory result = new bool[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++) {
            result[i] = isContract(accounts[i]);
        }
        return result;
    }
}