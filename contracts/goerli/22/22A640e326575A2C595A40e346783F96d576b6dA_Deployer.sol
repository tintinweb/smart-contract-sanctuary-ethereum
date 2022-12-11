//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Deployer {
    // deploy contract with create2 with same salt
    event Deployed(address addr, bytes32 salt);

    function deployContract(
        bytes memory _code,
        uint8 _saltId
    ) public returns (address addr) {
        bytes32 salt = keccak256(abi.encodePacked(msg.sender, _saltId));
        assembly {
            addr := create2(0, add(_code, 32), mload(_code), salt)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        emit Deployed(addr, salt);
    }
}