// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

/// @title   IProxy
/// @notice  interface to access _gswImpl on-chain
interface IGSWProxy {
    function _gswImpl() external view returns (address);
}

error GSWProxy__InvalidParams();

/// @title      GSWProxy
/// @notice     Proxy for GaslessSmartWallets as deployed by the GSWFactory.
///             Basic Proxy with fallback to delegate and address for implementation contract at storage 0x0
/// @dev        Note that if this contract changes then the deployment addresses for GSW change too
///             Relayers might want to pass in version as new param then to forward to the correct factory
contract GSWProxy {
    /// @notice address of the GSW logic / implementation contract. IMPORTANT: SAME STORAGE SLOT AS FOR PROXY
    /// @dev    _gswImpl MUST ALWAYS be the first declared variable here in the proxy and in the logic contract
    ///         when upgrading, the storage at memory address 0x0 is upgraded (first slot).
    ///         To reduce deployment costs this variable is internal but can still be retrieved with
    ///         _gswImpl(), see code and comments in fallback below
    address internal _gswImpl;

    /// @notice sets _gswImpl address
    /// @param  gswImpl_ initial _gswImpl address.
    constructor(address gswImpl_) {
        if (gswImpl_ == address(0)) {
            revert GSWProxy__InvalidParams();
        }
        _gswImpl = gswImpl_;
    }

    /// @notice Delegates the current call to `_gswImpl` unless _gswImpl() is called
    ///         if _gswImpl() is called then the address for _gswImpl is returned
    /// @dev    Mostly based on OpenZeppelin Proxy.sol
    fallback() external payable {
        assembly {
            // load address gswImpl_ from storage
            let gswImpl_ := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)

            // first 4 bytes of calldata specify which function to call.
            // if those first 4 bytes == 3fcf708a (function selector for _gswImpl) then we return the _gswImpl address
            // The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0x3fcf708a00000000000000000000000000000000000000000000000000000000) {
                mstore(0, gswImpl_) // store address gswImpl_ at memory address 0x0
                return(0, 0x20) // send first 20 bytes of address at memory address 0x0
            }

            // @dev code below is taken from OpenZeppelin Proxy.sol _delegate function

            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), gswImpl_, 0, calldatasize(), 0, 0)

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
}