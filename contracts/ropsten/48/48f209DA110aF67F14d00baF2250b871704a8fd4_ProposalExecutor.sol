//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalExecutor {
    
    function createContract(bytes memory data,  bytes32 salt ) public returns(address) {
        bytes memory bytecode = data;
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Should have valid addr from deployment");
        return addr;
    }

    function makeCall(address target, bytes memory data) public returns (bool) {
        (bool success,) = target.call(data);
        require(success, "Low-level call failed");
        return success;
    }

    function makeDelegateCall(address target, bytes memory data) public returns(bool) {
        (bool success,) = target.delegatecall(data);
        require(success, "Low-level delegatecall failed");
        return success;
    }
    function makeStaticCall(address target, bytes memory data) public view returns(bytes memory) {
        (bool success, bytes memory retData) = target.staticcall(data);
        require(success, "Low-level delegatecall failed");
        return retData;
    }
}