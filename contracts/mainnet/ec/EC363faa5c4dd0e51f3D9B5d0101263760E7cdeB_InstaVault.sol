// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../infiniteProxy/proxy.sol";

contract InstaVault is Proxy {
    constructor(address admin_, address dummyImplementation_)
        Proxy(admin_, dummyImplementation_)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./events.sol";

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`.
 */
contract Internals is Events {
    struct AddressSlot {
        address value;
    }

    struct SigsSlot {
        bytes4[] value;
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Storage slot with the address of the current dummy-implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _DUMMY_IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the storage slot which stores the sigs array set for the implementation.
     */
    function _getImplSigsSlot(address implementation_)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode("eip1967.proxy.implementation", implementation_)
            );
    }

    /**
     * @dev Returns the storage slot which stores the implementation address for the function sig.
     */
    function _getSigsImplSlot(bytes4 sig_) internal pure returns (bytes32) {
        return keccak256(abi.encode("eip1967.proxy.implementation", sig_));
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot_)
        internal
        pure
        returns (AddressSlot storage _r)
    {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Returns an `SigsSlot` with member `value` located at `slot`.
     */
    function getSigsSlot(bytes32 slot_)
        internal
        pure
        returns (SigsSlot storage _r)
    {
        assembly {
            _r.slot := slot_
        }
    }

    /**
     * @dev Sets new implementation and adds mapping from implementation to sigs and sig to implementation.
     */
    function _setImplementationSigs(
        address implementation_,
        bytes4[] memory sigs_
    ) internal {
        require(sigs_.length != 0, "no-sigs");
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        bytes4[] memory sigsCheck_ = getSigsSlot(slot_).value;
        require(sigsCheck_.length == 0, "implementation-already-exist");
        for (uint256 i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSigsImplSlot(sigs_[i]);
            require(
                getAddressSlot(sigSlot_).value == address(0),
                "sig-already-exist"
            );
            getAddressSlot(sigSlot_).value = implementation_;
        }
        getSigsSlot(slot_).value = sigs_;
        emit setImplementationLog(implementation_, sigs_);
    }

    /**
     * @dev Removes implementation and the mappings corresponding to it.
     */
    function _removeImplementationSigs(address implementation_) internal {
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        bytes4[] memory sigs_ = getSigsSlot(slot_).value;
        require(sigs_.length != 0, "implementation-not-exist");
        for (uint256 i = 0; i < sigs_.length; i++) {
            bytes32 sigSlot_ = _getSigsImplSlot(sigs_[i]);
            delete getAddressSlot(sigSlot_).value;
        }
        delete getSigsSlot(slot_).value;
        emit removeImplementationLog(implementation_);
    }

    /**
     * @dev Returns bytes4[] sigs from implementation address. If implemenatation is not registered then returns empty array.
     */
    function _getImplementationSigs(address implementation_)
        internal
        view
        returns (bytes4[] memory)
    {
        bytes32 slot_ = _getImplSigsSlot(implementation_);
        return getSigsSlot(slot_).value;
    }

    /**
     * @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function _getSigImplementation(bytes4 sig_)
        internal
        view
        returns (address implementation_)
    {
        bytes32 slot_ = _getSigsImplSlot(sig_);
        return getAddressSlot(slot_).value;
    }

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Returns the current dummy-implementation.
     */
    function _getDummyImplementation() internal view returns (address) {
        return getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin_) internal {
        address oldAdmin_ = _getAdmin();
        require(
            newAdmin_ != address(0),
            "ERC1967: new admin is the zero address"
        );
        getAddressSlot(_ADMIN_SLOT).value = newAdmin_;
        emit setAdminLog(oldAdmin_, newAdmin_);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setDummyImplementation(address newDummyImplementation_) internal {
        address oldDummyImplementation_ = _getDummyImplementation();
        getAddressSlot(_DUMMY_IMPLEMENTATION_SLOT)
            .value = newDummyImplementation_;
        emit setDummyImplementationLog(
            oldDummyImplementation_,
            newDummyImplementation_
        );
    }

    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation_) internal {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(
                gas(),
                implementation_,
                0,
                calldatasize(),
                0,
                0
            )

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
     * @dev Delegates the current call to the address returned by Implementations registry.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback(bytes4 sig_) internal {
        address implementation_ = _getSigImplementation(sig_);
        require(
            implementation_ != address(0),
            "Liquidity: Not able to find implementation_"
        );
        _delegate(implementation_);
    }
}

contract AdminStuff is Internals {
    /**
     * @dev Only admin gaurd.
     */
    modifier onlyAdmin() {
        require(msg.sender == _getAdmin(), "not-the-admin");
        _;
    }

    /**
     * @dev Sets new admin.
     */
    function setAdmin(address newAdmin_) external onlyAdmin {
        _setAdmin(newAdmin_);
    }

    /**
     * @dev Sets new dummy-implementation.
     */
    function setDummyImplementation(address newDummyImplementation_)
        external
        onlyAdmin
    {
        _setDummyImplementation(newDummyImplementation_);
    }

    /**
     * @dev Adds new implementation address.
     */
    function addImplementation(address implementation_, bytes4[] calldata sigs_)
        external
        onlyAdmin
    {
        _setImplementationSigs(implementation_, sigs_);
    }

    /**
     * @dev Removes an existing implementation address.
     */
    function removeImplementation(address implementation_) external onlyAdmin {
        _removeImplementationSigs(implementation_);
    }

    constructor(address admin_, address dummyImplementation_) {
        _setAdmin(admin_);
        _setDummyImplementation(dummyImplementation_);
    }
}

abstract contract Proxy is AdminStuff {
    constructor(address admin_, address dummyImplementation_)
        AdminStuff(admin_, dummyImplementation_)
    {}

    /**
     * @dev Returns admin's address.
     */
    function getAdmin() external view returns (address) {
        return _getAdmin();
    }

    /**
     * @dev Returns dummy-implementations's address.
     */
    function getDummyImplementation() external view returns (address) {
        return _getDummyImplementation();
    }

    /**
     * @dev Returns bytes4[] sigs from implementation address If not registered then returns empty array.
     */
    function getImplementationSigs(address impl_)
        external
        view
        returns (bytes4[] memory)
    {
        return _getImplementationSigs(impl_);
    }

    /**
     * @dev Returns implementation address from bytes4 sig. If sig is not registered then returns address(0).
     */
    function getSigsImplementation(bytes4 sig_)
        external
        view
        returns (address)
    {
        return _getSigImplementation(sig_);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    fallback() external payable {
        _fallback(msg.sig);
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by Implementations registry.
     */
    receive() external payable {
        if (msg.sig != 0x00000000) {
            _fallback(msg.sig);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Events {
    event setAdminLog(address oldAdmin_, address newAdmin_);

    event setDummyImplementationLog(
        address oldDummyImplementation_,
        address newDummyImplementation_
    );

    event setImplementationLog(address implementation_, bytes4[] sigs_);

    event removeImplementationLog(address implementation_);
}