///SPDX-License-Identifier:UNLICENSED
pragma solidity 0.8.13;

contract TransparentProxy {
    //keccak256("ADMIN");
    bytes32 private constant adminSlot = 0xdf8b4c520ffe197c5343c6f5aec59570151ef9a492f2c624fd45ddde6135ec42;
    //keccak256("IMPLEMENTATION")
    bytes32 private constant implementationSlot = 0x74ceeca74f185d5d317f418ff315e8c94da8b801521b3a3c5bb03d6895c28952;

    constructor(address _implementationAddress, bytes memory data) {
        if (data.length > 0) {
            (bool success, ) = _implementationAddress.delegatecall(data);
            require(success, "failed");
        }
        bytes32 _adminSlot = adminSlot;
        bytes32 _implementationSlot = implementationSlot;
        assembly {
            sstore(_adminSlot, caller())
            sstore(_implementationSlot, _implementationAddress)
        }
    }

    function changeImplementation(address newImplementation, bytes memory data)
        external
        shouldDelegate
    {
        if (data.length > 0) {
            (bool success, ) = newImplementation.delegatecall(data);
            require(success, "failed");
        }
        bytes32 _implementationSlot = implementationSlot;
        assembly {
            sstore(_implementationSlot, newImplementation)
        }
    }

    function changeAdmin(address newAdmin) external shouldDelegate {
        bytes32 _adminSlot = adminSlot;
        assembly {
            sstore(_adminSlot, newAdmin)
        }
    }

    function adminDelegate(bytes memory data) external payable shouldDelegate {
        bytes32 _implementation = implementationSlot;
        assembly {
            let implementation := sload(_implementation)

            let success := delegatecall(
                gas(),
                implementation,
                add(data, 32),
                mload(data),
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

    function _fallback() private {
        bytes32 _implementation = implementationSlot;
        assembly {
            let implementation := sload(_implementation)
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

    fallback() external payable {
        _fallback();
    }

    modifier shouldDelegate() {
        bytes4 sign = msg.sig;
        address admin;
        bytes32 _adminSlot = adminSlot;
        assembly {
            admin := sload(_adminSlot)
        }
        if (msg.sender == admin) {
            _;
        } else {
            _fallback();
        }
    }
}