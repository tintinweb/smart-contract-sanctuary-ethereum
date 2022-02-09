// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

contract AstraDispenser {
    function dispense(address payable[] memory recipients) external payable {
        assembly {
            let len := mload(recipients)
            let amount_per := div(callvalue(), len)
            
            let data := add(recipients, 0x20)
            for
                { let end := add(data, mul(len, 0x20)) }
                lt(data, end)
                { data := add(data, 0x20) }
            {
                pop(call(
                    21000,
                    mload(data),
                    amount_per,
                    0,
                    0,
                    0,
                    0
                ))
            }

            // Check if there is any leftover funds
            let leftover := selfbalance()
            if eq(leftover, 0) {
                return(0, 0)
            }

            pop(call(
                21000,
                caller(),
                leftover,
                0,
                0,
                0,
                0
            ))
        }
    }
}