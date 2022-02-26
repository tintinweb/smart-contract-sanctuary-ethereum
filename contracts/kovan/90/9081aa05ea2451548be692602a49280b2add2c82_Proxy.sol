/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: Apache-2.0.
pragma solidity ^0.8.7;

contract Proxy {
    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }
    address private implementation;

    function setImplementation(address newImplementation) public {
        implementation = newImplementation;
    }
}