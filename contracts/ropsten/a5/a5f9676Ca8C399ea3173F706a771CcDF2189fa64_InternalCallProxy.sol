// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract InternalCallProxy {

    address public implementation;
    bytes public lastReturnValue;

    /**
    * @dev Set implementation address to be able to run delegate call on correct contract
    */
    function setImplementation(address implementation_) public {
        implementation = implementation_;
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal {
        bytes memory ret;
        uint256 dataSize;
        assembly {
        // Copy msg.data. We take full control of memory in this inline assembly
        // block because it will not return to Solidity code. We overwrite the
        // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

        // Call the implementation.
        // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation_, 0, calldatasize(), 0, 0)

        // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                ret := result
                dataSize := returndatasize()
            }
        }

        lastReturnValue = ret;
        assembly {
            return(0, dataSize)
        }
    }

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    fallback() external payable {
        _delegate(implementation);
    }
}