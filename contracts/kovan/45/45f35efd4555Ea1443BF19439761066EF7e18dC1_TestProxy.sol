/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

contract TestProxy {
    // Made variables public to compare with
    // the finding's metadata
    bytes32 public role;
    bytes32 public previousAdminRole;
    bytes32 public newAdminRole;
    address public account;
    address public sender;

    address public implementation;

    function setArguments(
        bytes32 _role,
        bytes32 _previousAdminRole,
        bytes32 _newAdminRole,
        address _account,
        address _sender
    ) external {
        role = _role;
        previousAdminRole = _previousAdminRole;
        newAdminRole = _newAdminRole;
        account = _account;
        sender = _sender;
    }

    function setImplementation(address _implementation) external {
        implementation = _implementation;
    }

    /**
     * @dev Fallback function.
     * Implemented entirely in `_fallback`.
     */
    fallback() external {
        _fallback(implementation);
    }
    
    /**
     * @dev Delegates execution to an implementation contract.
     * This is a low level function that doesn't return to its internal call site.
     * It will return to the external caller whatever the implementation returns.
     * @param _implementation Address to delegate.
     */
    function _delegate(address _implementation) internal {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
                // delegatecall returns 0 on error.
                case 0 {
                revert(0, returndatasize())
                }
                default {
                return(0, returndatasize())
                }
        }
    }
    
    /**
     * @dev fallback implementation.
     * Extracted to enable manual triggering.
     */
    function _fallback(address _implementation) internal {
        _delegate(_implementation);
    }
}