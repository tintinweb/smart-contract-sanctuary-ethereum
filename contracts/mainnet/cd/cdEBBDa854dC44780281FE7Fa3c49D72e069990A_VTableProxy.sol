// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '@openzeppelin/contracts/proxy/Proxy.sol';

import './VTable.sol';
import './modules/VTableUpdateModule.sol';

/**
 * @title VTableProxy
 */
contract VTableProxy is Proxy {
    using VTable for VTable.VTableStore;

    bytes4 private constant _FALLBACK_SIGN = 0xffffffff;

    constructor(address updatemodule) {
        VTable.VTableStore storage vtable = VTable.instance();

        vtable.setOwner(msg.sender);
        vtable.setFunction(VTableUpdateModule(updatemodule).updateVTable.selector, updatemodule);
    }

    function _implementation() internal view virtual override returns (address module) {
        VTable.VTableStore storage vtable = VTable.instance();

        module = vtable.getFunction(msg.sig);
        if (module != address(0)) return module;

        module = vtable.getFunction(_FALLBACK_SIGN);
        if (module != address(0)) return module;

        revert('VTableProxy: No implementation found');
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
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
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @title VTable
 */
library VTable {
    // bytes32 private constant _VTABLE_SLOT = bytes32(uint256(keccak256("openzeppelin.vtable.location")) - 1);
    bytes32 private constant _VTABLE_SLOT = 0x13f1d5ea37b1d7aca82fcc2879c3bddc731555698dfc87ad6057b416547bc657;

    struct VTableStore {
        address _owner;
        mapping(bytes4 => address) _delegates;
    }

    /**
     * @dev Get singleton instance
     */
    function instance() internal pure returns (VTableStore storage vtable) {
        bytes32 position = _VTABLE_SLOT;
        assembly {
            vtable.slot := position
        }
    }

    /**
     * @dev Ownership management
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function getOwner(VTableStore storage vtable) internal view returns (address) {
        return vtable._owner;
    }

    function setOwner(VTableStore storage vtable, address newOwner) internal {
        emit OwnershipTransferred(vtable._owner, newOwner);
        vtable._owner = newOwner;
    }

    /**
     * @dev VTableManagement
     */
    event VTableUpdate(bytes4 indexed selector, address oldImplementation, address newImplementation);

    function getFunction(VTableStore storage vtable, bytes4 selector) internal view returns (address) {
        return vtable._delegates[selector];
    }

    function setFunction(
        VTableStore storage vtable,
        bytes4 selector,
        address module
    ) internal {
        emit VTableUpdate(selector, vtable._delegates[selector], module);
        vtable._delegates[selector] = module;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import '../VTable.sol';

contract VTableUpdateModule {
    using VTable for VTable.VTableStore;

    event VTableUpdate(bytes4 indexed selector, address oldImplementation, address newImplementation);

    struct ModuleDefinition {
        address implementation;
        bytes4[] selectors;
    }

    /**
     * @dev Updates the vtable
     */
    function updateVTable(ModuleDefinition[] calldata modules) public {
        VTable.VTableStore storage vtable = VTable.instance();
        require(VTable.instance().getOwner() == msg.sender, 'VTableOwnership: caller is not the owner');

        for (uint256 i = 0; i < modules.length; ++i) {
            ModuleDefinition memory module = modules[i];
            for (uint256 j = 0; j < module.selectors.length; ++j) {
                vtable.setFunction(module.selectors[j], module.implementation);
            }
        }
    }
}