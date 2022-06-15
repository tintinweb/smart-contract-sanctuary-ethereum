// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/**
 * @title WyvernAtomicizer
 * @author Wyvern Protocol Developers
 * @dev Execute multiple transactions, in order, atomically (if any fails, all revert).
 */
library WyvernAtomicizer {
    function atomicize(
        address[] calldata addrs,
        uint256[] calldata values,
        uint256[] calldata calldataLengths,
        bytes calldata calldatas
    ) external {
        require(
            addrs.length == values.length &&
                addrs.length == calldataLengths.length,
            "addrs, values and calldataLengths must have same length"
        );

        uint256 j = 0;
        for (uint256 i = 0; i < addrs.length; i++) {
            bytes memory cd = new bytes(calldataLengths[i]);
            for (uint256 k = 0; k < calldataLengths[i]; k++) {
                cd[k] = calldatas[j];
                j++;
            }
            (bool success, ) = addrs[i].call{value: values[i]}(cd);
            require(success, "Atomicizer subcall failed");
        }
    }
}