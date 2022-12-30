// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;



contract SeraphTest {
 

    function setVars(address _contract) public payable {
        (bool success, bytes memory data) = _contract.delegatecall(
            abi.encodeWithSignature("init()")
        );
    }
}