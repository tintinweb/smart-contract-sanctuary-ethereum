/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.0;

contract Proxy {
    address public implementation;

    constructor(address _implementation) {
        implementation = _implementation;
    }

    fallback() external payable {
        _fallback(implementation);
    }

    receive() external payable {
        _fallback(implementation);
    }

    function _fallback(address _implementation) internal {
        assembly {
            // fetching memory data
            calldatacopy(0, 0, calldatasize())

            // Delegate call to the implementation.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
 }