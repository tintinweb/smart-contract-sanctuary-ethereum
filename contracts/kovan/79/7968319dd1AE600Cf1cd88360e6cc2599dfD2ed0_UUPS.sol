///SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

contract UUPS {
    //keccak256("IMPLEMENTATION")
    bytes32 private constant implementationSlot = 0x74ceeca74f185d5d317f418ff315e8c94da8b801521b3a3c5bb03d6895c28952;

    constructor(address implementation, bytes memory data) {
        bytes32 _implementationSlot = implementationSlot;
        assembly {
            sstore(_implementationSlot, implementation)
        }
        if (data.length > 0) {
            (bool success, ) = implementation.delegatecall(data);
            require(success, "failed");
        }
    }

    fallback() external payable {
        bytes32 _implementationSlot = implementationSlot;
        assembly {
            let implementation := sload(_implementationSlot)
            calldatacopy(0, 0, calldatasize())

            let success := delegatecall(
                gas(),
                implementation,
                0,
                calldatasize(),
                0,
                0
            )
            returndatacopy(0, 0, returndatasize())

            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}