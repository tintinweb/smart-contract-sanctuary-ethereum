/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

contract Factory {
    mapping(bytes32 => address) private _histories;

    event Deploy(address addr);

    function getAddress(bytes32 key) external view returns (address) {
        return _histories[key];
    }

    function deploy(bytes32 salt, bytes memory bytecode) public payable returns (address addr) {
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        _histories[salt] = addr;

        emit Deploy(addr);
    }
}