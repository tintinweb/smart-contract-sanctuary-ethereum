/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

// Verified using https://dapp.tools

// hevm: flattened sources of lib/forward-proxy/src/ForwardProxy.sol
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.5.12;

////// lib/forward-proxy/src/ForwardProxyLike.sol
/* pragma solidity >=0.5.12; */

interface ForwardProxyLike {
    /**
     * @notice Returns the address which calls to this contract must be forwarded to.
     * @return to The address of the target contract.
     */
    function __to() external view returns (address payable to);

    /**
     * @notice Updates the `to` address and returns the address this contract instance.
     * @dev This function is meant to be used for chaining calls like:
     *
     * ```solidity
     * Target(proxy._(address(target))).targetFunction();
     * ```
     *
     * @param to The contract to which calls to this contract must be forwarded to.
     * @return The address of this contract instance.
     */
    function _(address to) external returns (address payable);

    /**
     * @dev This function does not return to its internall call site, it will return directly to the external caller.
     */
    fallback() external payable;

    /**
     * @dev This function handles plain ether transfers to this contract.
     */
    receive() external payable;
}

////// lib/forward-proxy/src/ForwardProxy.sol
/* pragma solidity >=0.5.12; */

/* import {ForwardProxyLike} from "./ForwardProxyLike.sol"; */

/**
 * @author Henrique Barcelos <[email protected]>
 * @title ForwardProxy
 * @notice This contract provides a fallback function that forwards all calls to another contract using the EVM
 * instruction `call`. The success and return data of the call will be returned back to the caller of the proxy.
 * @dev This contract is mostly useful for testing permissioned smart contracts systems in environments where EOAs are not available (i.e.: tests written with `ds-test`) and there is a need to emulate different actors interacting with
 * components of the system.
 *
 * Example:

 * ```solidity
 * ForwardProxy usr1 = new ForwardProxy();
 * ForwardProxy usr2 = new ForwardProxy();
 *
 * System system = new System(/* ... *\/);
 * system.authorize(address(usr1), 'role-A');
 * system.authorize(address(usr2), 'role-B');
 *
 * // "Impersonate" a contract of type `System`
 * System(
 *  // Set the `system` contract as the target `__to` and gets the reference to the proxy address.
 *  usr1._(address(system))
 * )
 *  // Call a method in the proxy which will be forwarded to the system
 *  .authorizedMethodA();
 *
 * // Do the same for `usr2`:
 * System(usr2._(address(system))).authorizedMethodB();
 * ```
 *
 * The example above is roughly equivalent to the following using `ethers.js`:
 *
 * ```js
 * const usr1 = new ethers.Wallet('<private key 1>');
 * const usr2 = new ethers.Wallet('<private key 2>');
 *
 * const system = new ethers.Contract('<address>', '<abi>');
 *
 * const tx1 = await system.authorize(address(usr1), 'role-A');
 * await tx1.wait()
 * const tx2 = await system.authorize(address(usr2), 'role-B');
 * await tx2.wait()
 *
 * system.connect(usr1);
 * const tx3 = await system.authorizedMethodA();
 * await tx3.wait();
 *
 * system.connect(usr2);
 * const tx4 = await system.authorizedMethodB();
 * await tx4.wait();
 * ```
 */
contract ForwardProxy is ForwardProxyLike {
    /// @dev Uses an arbitrary storage slot to store the target contract.
    bytes32 internal constant TARGET_SLOT = keccak256(abi.encode("dev.henriquebarcelos.forwardproxy.target"));

    /**
     * @notice Returns the address which calls to this contract must be forwarded to.
     * @return to The address of the target contract.
     */
    function __to() external view virtual override returns (address payable to) {
        bytes32 pos = TARGET_SLOT;
        assembly {
            to := sload(pos)
        }
    }

    /**
     * @notice Updates the `to` address and returns the address this contract instance.
     * @dev This function is meant to be used for chaining calls like:
     *
     * ```solidity
     * Target(proxy._(address(target))).targetFunction();
     * ```
     *
     * @param to The contract to which calls to this contract must be forwarded to.
     * @return The address of this contract instance.
     */
    function _(address to) public virtual override returns (address payable) {
        bytes32 pos = TARGET_SLOT;
        assembly {
            sstore(pos, to)
        }
        return payable(this);
    }

    /**
     * @dev This function does not return to its internall call site, it will return directly to the external caller.
     */
    fallback() external payable virtual override {
        _fallback();
    }

    function _fallback() internal virtual {
        bytes32 pos = TARGET_SLOT;
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly block because it will not return to
            // Solidity code. We overwrite the Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the target.
            // out and outsize are 0 because we don't know the size yet.
            let result := call(gas(), sload(pos), callvalue(), 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // call returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This function handles plain ether transfers to this contract.
     */
    receive() external payable virtual override {
        revert("ForwardProxy/no-ether-accepted");
    }
}