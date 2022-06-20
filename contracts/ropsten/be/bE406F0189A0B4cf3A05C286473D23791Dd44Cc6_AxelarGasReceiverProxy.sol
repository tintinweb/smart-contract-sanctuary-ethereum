/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// Root file: src/gas-receiver/AxelarGasReceiverProxy.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

contract AxelarGasReceiverProxy {
    error SetupFailed();
    error EtherNotAccepted();

    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    constructor(address gasReceiverImplementation, bytes memory params) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, gasReceiverImplementation)
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = gasReceiverImplementation.delegatecall(
            //0x9ded06df is the setup selector.
            abi.encodeWithSelector(0x9ded06df, params)
        );

        if (!success) revert SetupFailed();
    }

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata data) public {}

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address implementaion_ = implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
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

    receive() external payable {
        revert EtherNotAccepted();
    }
}