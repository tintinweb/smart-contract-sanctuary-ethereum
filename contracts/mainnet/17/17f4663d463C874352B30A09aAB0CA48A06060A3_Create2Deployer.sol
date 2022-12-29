// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.17;

contract Create2Deployer {
    event Deployed(address addr, bytes32 bytecodeHash);

    function deploy(bytes memory code, uint256 salt) public {
        address addr;
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, keccak256(abi.encodePacked(code)));
    }
}