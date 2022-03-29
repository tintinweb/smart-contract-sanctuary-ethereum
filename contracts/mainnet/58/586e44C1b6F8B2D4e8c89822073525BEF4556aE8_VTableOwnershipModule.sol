// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

import '../VTable.sol';

contract VTableOwnershipModule {
    using VTable for VTable.VTableStore;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, 'VTableOwnership: caller is not the owner');
        _;
    }

    /**
     * @dev Reads ownership for the vtable
     */
    function owner() public view virtual returns (address) {
        return VTable.instance().getOwner();
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        VTable.instance().setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'VTableOwnership: new owner is the zero address');
        VTable.instance().setOwner(newOwner);
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