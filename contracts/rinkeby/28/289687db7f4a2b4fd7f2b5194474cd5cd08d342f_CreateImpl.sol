/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


library Create {
    function deploy(
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }
}


contract CreateImpl {
    event addressOut(address addressOut);
    event result(bool result);
    bytes public hardcodedCallData = "0xaf8271f7";
    function deploy(
        bytes memory code
    ) public {
        address addr = Create.deploy(code);
        emit addressOut(addr);

    }

    function run(address addr) public {
        (bool success, bytes memory data) = addr.call(hardcodedCallData);
        emit result(success);
    }

    receive() external payable {}
}