// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract PPCS {
    function cloneContract() public returns (address) {
        bytes20 targetBytes = bytes20(0x91656663dCb0237c2BFaD17eF9b46773a123eF0e);
        bytes32 salt = bytes32(0); // Valeur du sel (salt)
        address clone;
        assembly {
            clone := create2(0, add(targetBytes, 0x20), mload(0x91656663dcb0237c2bfad17ef9b46773a123ef0e), salt)
            if iszero(extcodesize(clone)) {
                revert(0, 0)
            }
        }
        return clone;
    }
}