// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./Proxy.sol";

contract Factory {
    address public logicProxy;

    function createProxy(
        address logiAddress_,
        string memory tokenName_,
        string memory symbol_
    ) public {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(string,string)",
            tokenName_,
            symbol_
        );
        logicProxy = address(new Proxy(logiAddress_, _initializationCalldata));
    }

    function updateLogicProxy(address updataTemplate_) public {
        (bool _ok, bytes memory returnData) = logicProxy.call(
            abi.encodeWithSignature("upgradeVersion(address)", updataTemplate_)
        );

        require(_ok, string(returnData));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StorageSlotUpgradeable.sol";

contract Proxy {
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x5f62ce3c9aebd463c7a36ab1b244d2bb94f07a2c13889b3b687940ebc467b9b3;

    constructor(address logic, bytes memory initializationCalldata) {
        require(logic != address(0), "Proxy :: Wrong proxy contract address");
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = logic;
        (bool _ok, bytes memory returnData) = logic.delegatecall(
            initializationCalldata
        );
        require(_ok, string(returnData));
    }

    fallback() external payable {
        address _impl = StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    receive() external payable {}

    function upgradeVersion(address newAddress_) public {
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newAddress_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

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
library StorageSlotUpgradeable {
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
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}