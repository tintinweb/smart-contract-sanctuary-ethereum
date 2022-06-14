// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/token/ERC721/IERC721Receiver.sol";

import "./SorareProxy.sol";

contract GatewayMinterProxy is IERC721Receiver, SorareProxy {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return IERC721Receiver(address(0)).onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.14;

import "openzeppelin-contracts-v4.6.0/contracts/proxy/Proxy.sol";
import "openzeppelin-contracts-v4.6.0/contracts/utils/StorageSlot.sol";

contract SorareProxy is Proxy {
    /**
     * @dev Storage slot with the address of the contract owner.
     * This is the keccak-256 hash of "eip1967.proxy.owner" substracted by 1.
     */
    bytes32 internal constant _OWNER_SLOT =
        0xa7b53796fd2d99cb1f5ae019b54f9e024446c3d12b483f733ccc62ed04eb126a;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" substracted by 1.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Storage slot with the address of the next implementation.
     * This is the keccak-256 hash of "eip1967.proxy.newImplementation" substracted by 1.
     */
    bytes32 internal constant _NEW_IMPLEMENTATION_SLOT =
        0xb2807e65651cf78fc42f02fcff09e658fe8f4348ed4045f384b73340cc2b2ed4;

    /**
     * @dev Storage slot with the address of the previous implementation.
     * This is the keccak-256 hash of "eip1967.proxy.previousImplementation" substracted by 1.
     */
    bytes32 internal constant _PREVIOUS_IMPLEMENTATION_SLOT =
        0x3c9edc7a779f64d3f7fb0d22622f534140e56cc88c6837fb7d176db726bc545f;

    /**
     * @dev Storage slot with the upgrade delay.
     * This is the keccak-256 hash of "eip1967.proxy.upgradeDelay" substracted by 1.
     */
    bytes32 internal constant _UPGRADE_DELAY_SLOT =
        0x64e0d2a56259c33c4c94a1ff6d8155cb45e6493e62cc30b12a16babe2b94d9a7;

    /**
     * @dev Storage slot with the new upgrade delay.
     * This is the keccak-256 hash of "eip1967.proxy.newUpgradeDelay" substracted by 1.
     */
    bytes32 internal constant _NEW_UPGRADE_DELAY_SLOT =
        0x1417c2fa4abda3c661f367d5a43b88ebf17f432f83bb44dbb96ed071ab7c3c84;

    /**
     * @dev Storage slot with the the block at which new implementation was added.
     * This is the keccak-256 hash of "eip1967.proxy.enabledBlock" substracted by 1.
     */
    bytes32 internal constant _ENABLED_BLOCK_SLOT =
        0x993d3725b2c4672e0157ea7c1b648a4ef2bb2a5e6be7af409ce8093139aa3e4a;

    constructor() {
        _setAddressSlot(_OWNER_SLOT, msg.sender);
    }

    modifier onlyOwner() {
        require(_owner() == msg.sender, "caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _setAddressSlot(_OWNER_SLOT, newOwner);
    }

    function addImplementation(
        address newImplementation,
        uint256 newUpgradeDelay
    ) public onlyOwner {
        _setAddressSlot(_NEW_IMPLEMENTATION_SLOT, newImplementation);
        _setUint256Slot(_NEW_UPGRADE_DELAY_SLOT, newUpgradeDelay);
        _setUint256Slot(_ENABLED_BLOCK_SLOT, block.number);
    }

    function upgradeImplementation() public onlyOwner {
        require(
            block.number - _enabledBlock() >= _upgradeDelay(),
            "upgrade delay not expired"
        );
        require(
            _newImplementation() != address(0),
            "new implementation missing"
        );

        _setAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT, _implementation());
        _setAddressSlot(_IMPLEMENTATION_SLOT, _newImplementation());
        _setUint256Slot(_UPGRADE_DELAY_SLOT, _newUpgradeDelay());

        _setAddressSlot(_NEW_IMPLEMENTATION_SLOT, address(0));
    }

    function rollbackImplementation() public onlyOwner {
        require(
            _previousImplementation() != address(0),
            "previous implementation missing"
        );
        _setAddressSlot(_IMPLEMENTATION_SLOT, _previousImplementation());
    }

    function purgePreviousImplementation() public onlyOwner {
        _setAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT, address(0));
    }

    function increaseUpgradeDelay(uint256 newUpgradeDelay) public onlyOwner {
        require(
            newUpgradeDelay > _upgradeDelay(),
            "can only increase upgrade delay"
        );

        _setUint256Slot(_UPGRADE_DELAY_SLOT, newUpgradeDelay);
    }

    function owner() public view returns (address) {
        return _owner();
    }

    function implementation() public view returns (address) {
        return _implementation();
    }

    function upgradeDelay() public view returns (uint256) {
        return _upgradeDelay();
    }

    function _owner() internal view returns (address) {
        return StorageSlot.getAddressSlot(_OWNER_SLOT).value;
    }

    function _implementation()
        internal
        view
        virtual
        override
        returns (address)
    {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    function _newImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_NEW_IMPLEMENTATION_SLOT).value;
    }

    function _previousImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_PREVIOUS_IMPLEMENTATION_SLOT).value;
    }

    function _upgradeDelay() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_UPGRADE_DELAY_SLOT).value;
    }

    function _newUpgradeDelay() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_NEW_UPGRADE_DELAY_SLOT).value;
    }

    function _enabledBlock() internal view returns (uint256) {
        return StorageSlot.getUint256Slot(_ENABLED_BLOCK_SLOT).value;
    }

    function _setAddressSlot(bytes32 slot, address value) internal {
        StorageSlot.getAddressSlot(slot).value = value;
    }

    function _setUint256Slot(bytes32 slot, uint256 value) internal {
        StorageSlot.getUint256Slot(slot).value = value;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}