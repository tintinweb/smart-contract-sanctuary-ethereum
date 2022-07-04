//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ProposalExecutor {
    event ContractCreated(address indexed newContractAddr);
    event ContractCalled(address indexed contractAddr, bytes retData);
    event ContractDelegateCalled(address indexed contractAddr, bytes retData);
    function createContract(bytes memory data,  bytes32 salt ) public {
        bytes memory bytecode = data;
        address addr;
        assembly {
            addr := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
            if iszero(extcodesize(addr)) {
             revert(0, 0)
            }
        }
        require(addr != address(0), "Should have valid addr from deployment");
        emit ContractCreated(addr);
    }

    function makeCall(address target, bytes memory data) public {
        (bool success, bytes memory retData) = target.call(data);
        require(success, "Low-level call failed");
        emit ContractCalled(target, retData);
    }

    function makeDelegateCall(address target, bytes memory data) public {
        (bool success, bytes memory retData) = target.delegatecall(data);
        require(success, "Low-level delegatecall failed");
        emit ContractDelegateCalled(target, retData);
    }
    function makeStaticCall(address target, bytes memory data) public view returns(bytes memory) {
        (bool success, bytes memory retData) = target.staticcall(data);
        require(success, "Low-level delegatecall failed");
        return retData;
    }
}