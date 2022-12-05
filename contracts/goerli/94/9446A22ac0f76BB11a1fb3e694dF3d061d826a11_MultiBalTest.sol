// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

contract MultiBalTest {
    function read(address[] calldata accounts) external view returns (uint256 sum) {
        uint256 length = accounts.length;

        for (uint256 i = 0; i < length; ) {
            sum += address(accounts[i]).balance;
            unchecked {
                i++;
            }
        }
    }
}