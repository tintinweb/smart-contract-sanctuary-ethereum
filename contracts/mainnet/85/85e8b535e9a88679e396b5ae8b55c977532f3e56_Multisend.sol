/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Multisend {
    struct SendEth {
        address payable to;
        uint256 amount;
        bytes data;
    }

    function sendEth(SendEth[] memory sends) external payable {
        uint256 n = sends.length;
        uint256 totalSent = 0;
        for (uint256 i = 0; i < n; ++i) {
            uint256 amount = sends[i].amount;
            address to = sends[i].to;
            bytes memory data = sends[i].data;
            totalSent += amount;
            assembly {
                let s := call(gas(), to, amount, add(data, 0x20), mload(data), 0x00, 0)
                if iszero(s) {
                    returndatacopy(0x00, 0x00, returndatasize())
                    revert(0x00, returndatasize())
                }
            }
        }
        require(totalSent == msg.value, 'ETH leak');
    }
}