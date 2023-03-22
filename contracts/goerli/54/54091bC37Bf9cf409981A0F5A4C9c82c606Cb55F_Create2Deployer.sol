//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.16;

contract Create2Deployer {
    event Deployed(address addr, bytes32 salt);

    function deploy(bytes memory code, bytes32 salt) public returns (address) {
        address addr;
        require(code.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        emit Deployed(addr, salt);
        return addr;
    }
}