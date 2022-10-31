/* -*- c-basic-offset: 4 -*- */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../proxy/ForwardTarget.sol";

/** @title EcoInitializable
 *
 * This contract is used to hold a contract deployment address for future use.
 * A proxy contract is deployed and pointed at an instance of EcoInitializable,
 * which will allow the proxy target to be updated by the owner of the
 * EcoInitializable in the future. Addresses are not transferrable, so a custom
 * ownership implementation is used over the one provided by OpenZeppelin.
 */
contract EcoInitializable is ForwardTarget {
    /* Record who owns the address this contract is reserving.
     *
     * We use a custom ownable implementation because the addresses are not
     * intended to be transferrable. Only the account specified during the
     * deployment of EcoBootstrap is ever permitted to use one of these
     * addresses.
     */
    address payable public owner;

    /** Initialize contract */
    constructor(address payable _owner) {
        require(_owner != address(0), "must set owner");
        owner = _owner;
    }

    /** @notice Set delegation target and run initializer */
    function fuseImplementation(address _impl) external {
        // Make sure this can't be called by just anyone on the internet...
        require(msg.sender == owner, "Only owner can change implementation");

        /* Clear out the storage location &owner so we're not interfering with
         * the initializer we're about to run - it shares our address space and
         * we don't want the author to need to worry about that.
         */
        owner = payable(address(0));

        /* Clear out the implementation, so the safety checks in
         * initialize() do not get triggered.
         */
        setImplementation(address(0));

        /* Run the initializer of the new forwarding target to configure the
         * proxy's address space appropriately for the new target's runtime.
         */
        // solhint-disable-next-line avoid-low-level-calls
        (bool _success, ) = address(_impl).delegatecall(
            abi.encodeWithSelector(this.initialize.selector, _impl)
        );
        require(_success, "initialize call failed");
    }

    /** @notice Chained initializer to copy from origin contract */
    function initialize(address _self) public override onlyConstruction {
        super.initialize(_self);
        owner = EcoInitializable(_self).owner();
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