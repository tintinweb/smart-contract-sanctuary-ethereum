/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ForwardTarget.sol";

/* solhint-disable avoid-low-level-calls, no-inline-assembly */

/** @title Upgradable proxy */
contract ForwardProxy {
    // this is the storage slot to hold the target of the proxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    /** Construct a new proxy.
     *
     * @param _impl The default target address.
     */
    constructor(ForwardTarget _impl) {
        (bool _success, ) = address(_impl).delegatecall(
            abi.encodeWithSelector(_impl.initialize.selector, _impl)
        );
        require(_success, "initialize call failed");

        // Store forwarding target address at specified storage slot, copied
        // from ForwardTarget#IMPLEMENTATION_SLOT
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }

    /** @notice Default function that forwards call to proxy target
     */
    fallback() external payable {
        /* This default-function is optimized for minimum gas cost, to make the
         * proxy overhead as small as possible. As such, the entire function is
         * structured to optimize gas cost in the case of successful function
         * calls. As such, calls to e.g. calldatasize and calldatasize are
         * repeated, since calling them again is no more expensive than
         * duplicating them on stack.
         * This is also the only function in this contract, which avoids the
         * function dispatch overhead.
         */

        assembly {
            // Copy all call arguments to memory starting at 0x0
            calldatacopy(0x0, 0, calldatasize())

            // Forward to proxy target (loaded from IMPLEMENTATION_SLOT), using
            // arguments from memory 0x0 and having results written to
            // memory 0x0.
            let delegate_result := delegatecall(
                gas(),
                sload(IMPLEMENTATION_SLOT),
                0x0,
                calldatasize(),
                0x0,
                0
            )

            let result_size := returndatasize()

            //copy result into return buffer
            returndatacopy(0x0, 0, result_size)

            if delegate_result {
                // If the call was successful, return
                return(0x0, result_size)
            }

            // If the call was not successful, revert
            revert(0x0, result_size)
        }
    }
}

/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable no-inline-assembly */

/** @title Target for ForwardProxy and EcoInitializable */
abstract contract ForwardTarget {
    // Must match definition in ForwardProxy
    // keccak256("com.eco.ForwardProxy.target")
    uint256 private constant IMPLEMENTATION_SLOT =
        0xf86c915dad5894faca0dfa067c58fdf4307406d255ed0a65db394f82b77f53d4;

    modifier onlyConstruction() {
        require(
            implementation() == address(0),
            "Can only be called during initialization"
        );
        _;
    }

    constructor() {
        setImplementation(address(this));
    }

    /** @notice Storage initialization of cloned contract
     *
     * This is used to initialize the storage of the forwarded contract, and
     * should (typically) copy or repeat any work that would normally be
     * done in the constructor of the proxied contract.
     *
     * Implementations of ForwardTarget should override this function,
     * and chain to super.initialize(_self).
     *
     * @param _self The address of the original contract instance (the one being
     *              forwarded to).
     */
    function initialize(address _self) public virtual onlyConstruction {
        address _implAddress = address(ForwardTarget(_self).implementation());
        require(
            _implAddress != address(0),
            "initialization failure: nothing to implement"
        );
        setImplementation(_implAddress);
    }

    /** Get the address of the proxy target contract.
     */
    function implementation() public view returns (address _impl) {
        assembly {
            _impl := sload(IMPLEMENTATION_SLOT)
        }
    }

    /** @notice Set new implementation */
    function setImplementation(address _impl) internal {
        require(implementation() != _impl, "Implementation already matching");
        assembly {
            sstore(IMPLEMENTATION_SLOT, _impl)
        }
    }
}