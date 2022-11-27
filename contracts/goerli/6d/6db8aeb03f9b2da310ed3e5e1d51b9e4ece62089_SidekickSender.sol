/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

pragma solidity ^0.4.25;
// An optimised version of Disperse's Contract for https://getsidekick.xyz
// Author: @sec0ndstate


contract SidekickSender {
    function deployFunds(address[] recipients, uint256[] values) external payable {
        assembly {
            let length := calldataload(4)
            let i := 0
            for { } lt(i, length) { i := add(i, 1) } {
                let recipient := calldataload(add(36, mul(i, 64)))
                let amount := calldataload(add(68, mul(i, 64)))
                let success := call(gas(), recipient, amount, 0, 0, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
            let bal := balance(address())
            if gt(bal, 0) {
                let success := call(gas(), caller(), bal, 0, 0, 0, 0)
                if iszero(success) {
                    revert(0, 0)
                }
            }
        }
    }
}