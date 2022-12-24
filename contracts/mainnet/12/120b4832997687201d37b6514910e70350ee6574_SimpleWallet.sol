/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract SimpleWallet {
    address public ownerAddress;

    constructor() {
        ownerAddress = tx.origin;
    }

    enum Operation {
        Call,
        DelegateCall
    }

    function execute(
        address to,
        uint256 value,
        bytes calldata data,
        Operation operation
    ) external returns (bool success) {
        require(msg.sender == ownerAddress, "Only owner");
        if (operation == Operation.Call) {
            success = executeCall(to, value, data);
        } else if (operation == Operation.DelegateCall) {
            success = executeDelegateCall(to, data);
        }
        require(success == true, "Transaction failed");
    }

    function executeCall(
        address to,
        uint256 value,
        bytes memory data
    ) internal returns (bool success) {
        assembly {
            success := call(
                gas(),
                to,
                value,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }

    function executeDelegateCall(address to, bytes memory data)
        internal
        returns (bool success)
    {
        assembly {
            success := delegatecall(
                gas(),
                to,
                add(data, 0x20),
                mload(data),
                0,
                0
            )
        }
    }
}