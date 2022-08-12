// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Create2Factory {

    event Created(address addr);

    function createContract(bytes memory creationCode, bytes32 salt) public payable returns(address addr) {
        uint value = msg.value;
        assembly {
            addr := create2(value, add(creationCode, 32), mload(creationCode), salt)
        }
        require(addr != address(0), "create2 failed");
        emit Created(addr);
    }
}