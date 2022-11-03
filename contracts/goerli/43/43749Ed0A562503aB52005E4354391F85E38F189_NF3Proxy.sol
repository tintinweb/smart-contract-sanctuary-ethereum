// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/proxy/Proxy.sol";

/// @title NF3 Proxy
/// @author Jack Jin
/// @author Priyam Anand
/// @dev This is the proxy contract for public facing functions of NF3 platform.

contract NF3Proxy is Proxy {
    /// -----------------------------------------------------------------------
    /// Constant variables
    /// -----------------------------------------------------------------------

    /// @notice Storage position of the address of the current implementation
    bytes32 private constant implementationPosition =
        keccak256("NF3.proxy.implementation.address");

    /// @notice Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = keccak256("NF3.proxy.owner");

    /// -----------------------------------------------------------------------
    /// Modifiers
    /// -----------------------------------------------------------------------

    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), "Not Proxy owner");
        _;
    }

    /* ===== INIT ===== */

    /// @dev Constructor
    constructor() {
        _setUpgradeabilityOwner(msg.sender);
    }

    /// -----------------------------------------------------------------------
    /// Owner Actions
    /// -----------------------------------------------------------------------

    /// @dev Transfer the ownership.
    /// @param _newOwner New proxy owner
    function transferProxyOwnership(address _newOwner) public onlyProxyOwner {
        require(_newOwner != address(0));
        _setUpgradeabilityOwner(_newOwner);
    }

    /// @dev Allows the proxy owner to upgrade the implementation contract.
    /// @param _newImplementation Address of the new implementation contract
    function upgradeTo(address _newImplementation) public onlyProxyOwner {
        _upgradeTo(_newImplementation);
    }

    /// -----------------------------------------------------------------------
    /// Internal Actions
    /// -----------------------------------------------------------------------

    /// @dev Upgrades the implementation contract address.
    /// @param _newImplementation Address of the new implementation contract
    function _upgradeTo(address _newImplementation) internal {
        require(_newImplementation != address(0));
        address currentImplementation = _implementation();
        require(currentImplementation != _newImplementation);
        _setImplementation(_newImplementation);
    }

    /// @dev Sets the implementation contract address.
    /// @param _newImplementation Address of the new implementation contract
    function _setImplementation(address _newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, _newImplementation)
        }
    }

    /// @dev Returns the address of the current implementation contract address.
    /// @return impl Address of the current implementation contract
    function _implementation() internal view override returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /// @dev Sets the address of the proxy owner.
    /// @param _newProxyOwner Address of new proxy owner
    function _setUpgradeabilityOwner(address _newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, _newProxyOwner)
        }
    }

    /// -----------------------------------------------------------------------
    /// View actions
    /// -----------------------------------------------------------------------

    /// @dev Returns the address of the current implementation contract address.
    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @dev Returns the proxy owner address.
    /// @return owner Address of proxy contract
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

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
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}