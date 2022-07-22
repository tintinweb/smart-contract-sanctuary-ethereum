// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Proxy.sol";

contract HSKProxy is Proxy {
    bytes32 internal constant IMPLEMENTATION_SLOT = keccak256("hsk.proxy.implementation");

    bytes32 internal constant ADMIN_SLOT = keccak256("hsk.proxy.admin");

    bytes32 internal constant ACTIVE_SLOT = keccak256("hsk.proxy.active");

    /// @dev Emitted when the implementation is upgraded.
    event Upgraded(address indexed implementation);

    /// @dev Emitted when the administration has been transferred.
    /// @param previousAdmin Address of the previous admin.
    /// @param newAdmin Address of the new admin.
    event AdminChanged(address previousAdmin, address newAdmin);

    /// @dev Proxy status is updated.
    event StatusUpdated(bool status);

    modifier isProxyAdmin() {
        require(msg.sender == _admin(), "Proxy: is not admin");
        _;
    }

    constructor(address _impl) {
        _setImplementation(_impl);
        _setAdmin(msg.sender);
        _setStatus(true);
    }

    function _implementation() internal view override returns (address impl) {
        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    function _beforeFallback() internal view override {
        bool active = _status();
        require(active, "Proxy: proxy is not active");
    }

    /// @dev Sets the implementation address of the proxy.
    /// @param _impl Address of the new implementation.
    function _setImplementation(address _impl) internal {
        require(_impl.code.length > 0, "Proxy: not a contract address");

        bytes32 slot = IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _impl)
        }
    }

    /**
    * @dev Upgrades the proxy to a new implementation.
    * @param newImplementation Address of the new implementation.
    */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /// @dev Return the admin slot.
    function _admin() internal view returns (address account) {
        bytes32 slot = ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            account := sload(slot)
        }
    }

    /// @dev Set new admin
    function _setAdmin(address _newAdmin) internal {
        require(_newAdmin != address(0), "Admin should not be zero");

        bytes32 slot = ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, _newAdmin)
        }
    }

    /// @dev Return proxy status
    function _status() internal view returns (bool active) {
        bytes32 slot = ACTIVE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            active := sload(slot)
        }
    }

    /// @dev Set proxy status
    function _setStatus(bool active) internal {
        bytes32 slot = ACTIVE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, active)
        }
    }

    /// @dev Return implementation
    function implementation() external view returns (address) {
        return _implementation();
    }

    /// @dev Perform implementation upgrade
    function upgradeTo(address _impl) external isProxyAdmin {
        _upgradeTo(_impl);
    }

    /// @dev Perform implementation upgrade with additional setup call.
    function upgradeToAndCall(address _impl, bytes memory data) external payable isProxyAdmin {
        _upgradeTo(_impl);
        if (data.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool ok, ) = _impl.delegatecall(data);
            require(ok, "Proxy: delegateCall failed");
        }
    }

    /// @dev Returns the current admin.
    function admin() external view returns (address) {
        return _admin();
    }

    /// @dev Changes the admin of the proxy.
    function changeAdmin(address _newAdmin) external isProxyAdmin {
        address _oldAdmin = _admin();
        _setAdmin(_newAdmin);
        emit AdminChanged(_oldAdmin, _newAdmin);
    }

    /// @dev Get proxy status.
    function status() external view returns (bool) {
        return _status();
    }

    /// @dev Set proxy status.
    function setStatus(bool active) external isProxyAdmin {
        _setStatus(active);
        emit StatusUpdated(active);
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