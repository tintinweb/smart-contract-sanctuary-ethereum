/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Agent executes arbitrary logics
contract Agent {
    address private immutable _implementation;

    constructor(address implementation) {
        _implementation = implementation;
        (bool ok, ) = implementation.delegatecall(abi.encodeWithSignature('initialize()'));
        require(ok);
    }

    receive() external payable {}

    /// @notice All the function will be delegated to `_implementation`
    fallback() external payable {
        _delegate(_implementation);
    }

    /// @notice Referenced from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.8.1/contracts/proxy/Proxy.sol#L22
    function _delegate(address implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}