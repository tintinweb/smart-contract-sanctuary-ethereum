// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;
pragma experimental ABIEncoderV2;

import {IForwarderRegistry} from "./../../metatx/interfaces/IForwarderRegistry.sol";
import {IDiamondCut} from "./../interfaces/IDiamondCut.sol";
import {IDiamondCutBatchInit} from "./../interfaces/IDiamondCutBatchInit.sol";
import {DiamondStorage} from "./../libraries/DiamondStorage.sol";
import {ProxyAdminStorage} from "./../../proxy/libraries/ProxyAdminStorage.sol";
import {ForwarderRegistryContextBase} from "./../../metatx/base/ForwarderRegistryContextBase.sol";

/// @title Diamond Cut (facet version).
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: This facet depends on {ProxyAdminFacet} and {InterfaceDetectionFacet}.
contract DiamondCutFacet is IDiamondCut, IDiamondCutBatchInit, ForwarderRegistryContextBase {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;
    using DiamondStorage for DiamondStorage.Layout;

    constructor(IForwarderRegistry forwarderRegistry) ForwarderRegistryContextBase(forwarderRegistry) {}

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondCut, DiamondCutBatchInit.
    /// @dev Reverts if the sender is not the proxy admin.
    function initDiamondCutStorage() external {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.initDiamondCut();
    }

    /// @inheritdoc IDiamondCut
    /// @dev Reverts if the sender is not the proxy admin.
    function diamondCut(FacetCut[] calldata cuts, address target, bytes calldata data) external override {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.layout().diamondCut(cuts, target, data);
    }

    /// @inheritdoc IDiamondCutBatchInit
    /// @dev Reverts if the sender is not the proxy admin.
    function diamondCut(FacetCut[] calldata cuts, Initialization[] calldata initializations) external override {
        ProxyAdminStorage.layout().enforceIsProxyAdmin(_msgSender());
        DiamondStorage.layout().diamondCut(cuts, initializations);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./IDiamondCutCommon.sol";

/// @title ERC2535 Diamond Standard, Diamond Cut.
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: the ERC-165 identifier for this interface is 0x1f931c1c
interface IDiamondCut is IDiamondCutCommon {
    /// @notice Add/replace/remove facet functions and optionally execute a function with delegatecall.
    /// @dev Emits a {DiamondCut} event.
    /// @param cuts The list of facet addresses, actions and function selectors to apply to the diamond.
    /// @param target The address of the contract to execute `data` on.
    /// @param data The encoded function call to execute on `target`.
    function diamondCut(FacetCut[] calldata cuts, address target, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./IDiamondCutCommon.sol";

/// @title ERCXXX Diamond Standard, Diamond Cut Batch Init extension.
/// @dev See https://eips.ethereum.org/EIPS/eip-XXXX
/// @dev Note: the ERC-165 identifier for this interface is 0xb2afc5b5
interface IDiamondCutBatchInit is IDiamondCutCommon {
    /// @notice Add/replace/remove facet functions and execute a batch of functions with delegatecall.
    /// @dev Emits a {DiamondCut} event.
    /// @param cuts The list of facet addresses, actions and function selectors to apply to the diamond.
    /// @param initializations The list of addresses and encoded function calls to execute with delegatecall.
    function diamondCut(FacetCut[] calldata cuts, Initialization[] calldata initializations) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

interface IDiamondCutCommon {
    enum FacetCutAction {
        ADD,
        REPLACE,
        REMOVE
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facet;
        FacetCutAction action;
        bytes4[] selectors;
    }

    struct Initialization {
        address target;
        bytes data;
    }

    /// @notice Emitted when at least a cut action is operated on the diamond.
    /// @param cuts The list of facet addresses, actions and function selectors applied to the diamond.
    /// @param target The address of the contract where `data` was executed.
    /// @param data The encoded function call executed on `target`.
    event DiamondCut(FacetCut[] cuts, address target, bytes data);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

/// @title ERC2535 Diamond Standard, Diamond Loupe.
/// @dev See https://eips.ethereum.org/EIPS/eip-2535
/// @dev Note: the ERC-165 identifier for this interface is 0x48e2b093
interface IDiamondLoupe {
    struct Facet {
        address facet;
        bytes4[] selectors;
    }

    /// @notice Gets all the facet addresses used by the diamond and their function selectors.
    /// @return diamondFacets The facet addresses used by the diamond and their function selectors.
    function facets() external view returns (Facet[] memory diamondFacets);

    /// @notice Gets all the function selectors supported by a facet.
    /// @param facetAddress The facet address.
    /// @return selectors The function selectors supported by `facet`.
    function facetFunctionSelectors(address facetAddress) external view returns (bytes4[] memory selectors);

    /// @notice Get all the facet addresses used by the diamond.
    /// @return diamondFacetsAddresses The facet addresses used by the diamond.
    function facetAddresses() external view returns (address[] memory diamondFacetsAddresses);

    /// @notice Gets the facet address that supports a given function selector.
    /// @param functionSelector The function selector.
    /// @return diamondFacetAddress The facet address that supports `functionSelector`, or the zero address if the facet is not found.
    function facetAddress(bytes4 functionSelector) external view returns (address diamondFacetAddress);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
pragma experimental ABIEncoderV2;

import {IDiamondCutCommon} from "./../interfaces/IDiamondCutCommon.sol";
import {IDiamondCut} from "./../interfaces/IDiamondCut.sol";
import {IDiamondCutBatchInit} from "./../interfaces/IDiamondCutBatchInit.sol";
import {IDiamondLoupe} from "./../interfaces/IDiamondLoupe.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {InterfaceDetectionStorage} from "./../../introspection/libraries/InterfaceDetectionStorage.sol";

/// @dev derived from https://github.com/mudgen/diamond-2 (MIT licence) and https://github.com/solidstate-network/solidstate-solidity (MIT licence)
library DiamondStorage {
    using Address for address;
    using DiamondStorage for DiamondStorage.Layout;
    using InterfaceDetectionStorage for InterfaceDetectionStorage.Layout;

    struct Layout {
        // selector => (facet address, selector slot position)
        mapping(bytes4 => bytes32) diamondFacets;
        // number of selectors registered in selectorSlots
        uint16 selectorCount;
        // array of selector slots with 8 selectors per slot
        mapping(uint256 => bytes32) selectorSlots;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.Diamond.storage")) - 1);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    event DiamondCut(IDiamondCutCommon.FacetCut[] cuts, address target, bytes data);

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondCut, DiamondCutBatchInit.
    function initDiamondCut() internal {
        InterfaceDetectionStorage.Layout storage interfaceDetectionLayout = InterfaceDetectionStorage.layout();
        interfaceDetectionLayout.setSupportedInterface(type(IDiamondCut).interfaceId, true);
        interfaceDetectionLayout.setSupportedInterface(type(IDiamondCutBatchInit).interfaceId, true);
    }

    /// @notice Marks the following ERC165 interface(s) as supported: DiamondLoupe.
    function initDiamondLoupe() internal {
        InterfaceDetectionStorage.layout().setSupportedInterface(type(IDiamondLoupe).interfaceId, true);
    }

    function diamondCut(Layout storage s, IDiamondCutCommon.FacetCut[] memory cuts, address target, bytes memory data) internal {
        cutFacets(s, cuts);
        emit DiamondCut(cuts, target, data);
        initializationCall(target, data);
    }

    function diamondCut(
        Layout storage s,
        IDiamondCutCommon.FacetCut[] memory cuts,
        IDiamondCutCommon.Initialization[] memory initializations
    ) internal {
        unchecked {
            s.cutFacets(cuts);
            emit DiamondCut(cuts, address(0), "");
            uint256 length = initializations.length;
            for (uint256 i; i != length; ++i) {
                initializationCall(initializations[i].target, initializations[i].data);
            }
        }
    }

    function cutFacets(Layout storage s, IDiamondCutCommon.FacetCut[] memory facetCuts) internal {
        unchecked {
            uint256 originalSelectorCount = s.selectorCount;
            uint256 selectorCount = originalSelectorCount;
            bytes32 selectorSlot;

            // Check if last selector slot is not full
            if (selectorCount & 7 > 0) {
                // get last selectorSlot
                selectorSlot = s.selectorSlots[selectorCount >> 3];
            }

            uint256 length = facetCuts.length;
            for (uint256 i; i != length; ++i) {
                IDiamondCutCommon.FacetCut memory facetCut = facetCuts[i];
                IDiamondCutCommon.FacetCutAction action = facetCut.action;

                require(facetCut.selectors.length != 0, "Diamond: no function selectors");

                if (action == IDiamondCutCommon.FacetCutAction.ADD) {
                    (selectorCount, selectorSlot) = s.addFacetSelectors(selectorCount, selectorSlot, facetCut);
                } else if (action == IDiamondCutCommon.FacetCutAction.REPLACE) {
                    s.replaceFacetSelectors(facetCut);
                } else {
                    (selectorCount, selectorSlot) = s.removeFacetSelectors(selectorCount, selectorSlot, facetCut);
                }
            }

            if (selectorCount != originalSelectorCount) {
                s.selectorCount = uint16(selectorCount);
            }

            // If last selector slot is not full
            if (selectorCount & 7 > 0) {
                s.selectorSlots[selectorCount >> 3] = selectorSlot;
            }
        }
    }

    function addFacetSelectors(
        Layout storage s,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondCutCommon.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            if (facetCut.facet != address(this)) {
                // allows immutable functions to be added from a constructor
                require(facetCut.facet.isContract(), "Diamond: facet has no code"); // reverts if executed from a constructor
            }

            uint256 length = facetCut.selectors.length;
            for (uint256 i; i != length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];

                require(address(bytes20(oldFacet)) == address(0), "Diamond: selector already added");

                // add facet for selector
                s.diamondFacets[selector] = bytes20(facetCut.facet) | bytes32(selectorCount);
                uint256 selectorInSlotPosition = (selectorCount & 7) << 5;

                // clear selector position in slot and add selector
                selectorSlot = (selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);

                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    s.selectorSlots[selectorCount >> 3] = selectorSlot;
                    selectorSlot = 0;
                }

                ++selectorCount;
            }

            return (selectorCount, selectorSlot);
        }
    }

    function removeFacetSelectors(
        Layout storage s,
        uint256 selectorCount,
        bytes32 selectorSlot,
        IDiamondCutCommon.FacetCut memory facetCut
    ) internal returns (uint256, bytes32) {
        unchecked {
            require(facetCut.facet == address(0), "Diamond: non-zero address facet");

            uint256 selectorSlotCount = selectorCount >> 3;
            uint256 selectorInSlotIndex = selectorCount & 7;

            for (uint256 i; i != facetCut.selectors.length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];

                require(address(bytes20(oldFacet)) != address(0), "Diamond: selector not found");
                require(address(bytes20(oldFacet)) != address(this), "Diamond: immutable function");

                if (selectorSlot == 0) {
                    selectorSlotCount--;
                    selectorSlot = s.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }

                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

                // adding a block here prevents stack too deep error
                {
                    // replace selector with last selector in l.facets
                    lastSelector = bytes4(selectorSlot << (selectorInSlotIndex << 5));

                    if (lastSelector != selector) {
                        // update last selector slot position info
                        s.diamondFacets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(s.diamondFacets[lastSelector]);
                    }

                    delete s.diamondFacets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }

                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = s.selectorSlots[oldSelectorsSlotCount];

                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);

                    // update storage with the modified slot
                    s.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    selectorSlot =
                        (selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }

                if (selectorInSlotIndex == 0) {
                    delete s.selectorSlots[selectorSlotCount];
                    selectorSlot = 0;
                }
            }

            selectorCount = (selectorSlotCount << 3) | selectorInSlotIndex;

            return (selectorCount, selectorSlot);
        }
    }

    function replaceFacetSelectors(Layout storage s, IDiamondCutCommon.FacetCut memory facetCut) internal {
        unchecked {
            require(facetCut.facet.isContract(), "Diamond: facet has no code");

            uint256 length = facetCut.selectors.length;
            for (uint256 i; i != length; ++i) {
                bytes4 selector = facetCut.selectors[i];
                bytes32 oldFacet = s.diamondFacets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));

                require(oldFacetAddress != address(0), "Diamond: selector not found");
                require(oldFacetAddress != address(this), "Diamond: immutable function");
                require(oldFacetAddress != facetCut.facet, "Diamond: identical function");

                // replace old facet address
                s.diamondFacets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(facetCut.facet);
            }
        }
    }

    function initializationCall(address target, bytes memory data) internal {
        if (target == address(0)) {
            require(data.length == 0, "Diamond: data is not empty");
        } else {
            require(data.length != 0, "Diamond: data is empty");
            if (target != address(this)) {
                require(target.isContract(), "Diamond: target has no code");
            }

            (bool success, bytes memory returndata) = target.delegatecall(data);
            if (!success) {
                uint256 returndataLength = returndata.length;
                if (returndataLength != 0) {
                    assembly {
                        revert(add(32, returndata), returndataLength)
                    }
                } else {
                    revert("Diamond: init call reverted");
                }
            }
        }
    }

    function facets(Layout storage s) internal view returns (IDiamondLoupe.Facet[] memory diamondFacets) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            diamondFacets = new IDiamondLoupe.Facet[](selectorCount);

            uint256[] memory numFacetSelectors = new uint256[](selectorCount);
            uint256 numFacets;
            uint256 selectorIndex;

            // loop through function selectors
            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                    address facet = address(bytes20(s.diamondFacets[selector]));

                    bool continueLoop;

                    for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                        if (diamondFacets[facetIndex].facet == facet) {
                            diamondFacets[facetIndex].selectors[numFacetSelectors[facetIndex]] = selector;
                            ++numFacetSelectors[facetIndex];
                            continueLoop = true;
                            break;
                        }
                    }

                    if (continueLoop) {
                        continue;
                    }

                    diamondFacets[numFacets].facet = facet;
                    diamondFacets[numFacets].selectors = new bytes4[](selectorCount);
                    diamondFacets[numFacets].selectors[0] = selector;
                    numFacetSelectors[numFacets] = 1;
                    ++numFacets;
                }
            }

            for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                uint256 numSelectors = numFacetSelectors[facetIndex];
                bytes4[] memory selectors = diamondFacets[facetIndex].selectors;

                // setting the number of selectors
                assembly {
                    mstore(selectors, numSelectors)
                }
            }

            // setting the number of facets
            assembly {
                mstore(diamondFacets, numFacets)
            }
        }
    }

    function facetFunctionSelectors(Layout storage s, address facet) internal view returns (bytes4[] memory selectors) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            selectors = new bytes4[](selectorCount);

            uint256 numSelectors;
            uint256 selectorIndex;

            // loop through function selectors
            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));

                    if (facet == address(bytes20(s.diamondFacets[selector]))) {
                        selectors[numSelectors] = selector;
                        ++numSelectors;
                    }
                }
            }

            // set the number of selectors in the array
            assembly {
                mstore(selectors, numSelectors)
            }
        }
    }

    function facetAddresses(Layout storage s) internal view returns (address[] memory addresses) {
        unchecked {
            uint16 selectorCount = s.selectorCount;
            addresses = new address[](selectorCount);
            uint256 numFacets;
            uint256 selectorIndex;

            for (uint256 slotIndex; selectorIndex < selectorCount; ++slotIndex) {
                bytes32 slot = s.selectorSlots[slotIndex];

                for (uint256 selectorSlotIndex; selectorSlotIndex != 8; ++selectorSlotIndex) {
                    ++selectorIndex;

                    if (selectorIndex > selectorCount) {
                        break;
                    }

                    bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                    address facet = address(bytes20(s.diamondFacets[selector]));

                    bool continueLoop;

                    for (uint256 facetIndex; facetIndex != numFacets; ++facetIndex) {
                        if (facet == addresses[facetIndex]) {
                            continueLoop = true;
                            break;
                        }
                    }

                    if (continueLoop) {
                        continue;
                    }

                    addresses[numFacets] = facet;
                    ++numFacets;
                }
            }

            // set the number of facet addresses in the array
            assembly {
                mstore(addresses, numFacets)
            }
        }
    }

    function facetAddress(Layout storage s, bytes4 selector) internal view returns (address facet) {
        facet = address(bytes20(s.diamondFacets[selector]));
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title ERC165 Interface Detection Standard.
/// @dev See https://eips.ethereum.org/EIPS/eip-165.
/// @dev Note: The ERC-165 identifier for this interface is 0x01ffc9a7.
interface IERC165 {
    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId the interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(bytes4 interfaceId) external view returns (bool supported);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IERC165} from "./../interfaces/IERC165.sol";

library InterfaceDetectionStorage {
    struct Layout {
        mapping(bytes4 => bool) supportedInterfaces;
    }

    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("animoca.core.introspection.InterfaceDetection.storage")) - 1);

    bytes4 internal constant ILLEGAL_INTERFACE_ID = 0xffffffff;

    /// @notice Sets or unsets an ERC165 interface.
    /// @dev Reverts if `interfaceId` is `0xffffffff`.
    /// @param interfaceId the interface identifier.
    /// @param supported True to set the interface, false to unset it.
    function setSupportedInterface(Layout storage s, bytes4 interfaceId, bool supported) internal {
        require(interfaceId != ILLEGAL_INTERFACE_ID, "InterfaceDetection: wrong value");
        s.supportedInterfaces[interfaceId] = supported;
    }

    /// @notice Returns whether this contract implements a given interface.
    /// @dev Note: This function call must use less than 30 000 gas.
    /// @param interfaceId The interface identifier to test.
    /// @return supported True if the interface is supported, false if `interfaceId` is `0xffffffff` or if the interface is not supported.
    function supportsInterface(Layout storage s, bytes4 interfaceId) internal view returns (bool supported) {
        if (interfaceId == ILLEGAL_INTERFACE_ID) {
            return false;
        }
        if (interfaceId == type(IERC165).interfaceId) {
            return true;
        }
        return s.supportedInterfaces[interfaceId];
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {IForwarderRegistry} from "./../interfaces/IForwarderRegistry.sol";
import {ERC2771Calldata} from "./../libraries/ERC2771Calldata.sol";

/// @title Meta-Transactions Forwarder Registry Context (proxiable version).
/// @dev This contract is to be used via inheritance in a proxied implementation.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
abstract contract ForwarderRegistryContextBase {
    IForwarderRegistry internal immutable _forwarderRegistry;

    constructor(IForwarderRegistry forwarderRegistry) {
        _forwarderRegistry = forwarderRegistry;
    }

    /// @notice Returns the message sender depending on the ForwarderRegistry-based meta-transaction context.
    function _msgSender() internal view virtual returns (address) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.sender;
        }

        address sender = ERC2771Calldata.msgSender();

        // Return the EIP-2771 calldata-appended sender address if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(sender, msg.sender)) {
            return sender;
        }

        return msg.sender;
    }

    /// @notice Returns the message data depending on the ForwarderRegistry-based meta-transaction context.
    function _msgData() internal view virtual returns (bytes calldata) {
        // Optimised path in case of an EOA-initiated direct tx to the contract or a call from a contract not complying with EIP-2771
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender == tx.origin || msg.data.length < 24) {
            return msg.data;
        }

        // Return the EIP-2771 calldata (minus the appended sender) if the message was forwarded by the ForwarderRegistry or an approved forwarder
        if (msg.sender == address(_forwarderRegistry) || _forwarderRegistry.isApprovedForwarder(ERC2771Calldata.msgSender(), msg.sender)) {
            return ERC2771Calldata.msgData();
        }

        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @title Universal Meta-Transactions Forwarder Registry.
/// @dev Derived from https://github.com/wighawag/universal-forwarder (MIT licence)
interface IForwarderRegistry {
    /// @notice Checks whether an account is as an approved meta-transaction forwarder for a sender account.
    /// @param sender The sender account.
    /// @param forwarder The forwarder account.
    /// @return isApproved True if `forwarder` is an approved meta-transaction forwarder for `sender`, false otherwise.
    function isApprovedForwarder(address sender, address forwarder) external view returns (bool isApproved);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

/// @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT licence)
/// @dev See https://eips.ethereum.org/EIPS/eip-2771
library ERC2771Calldata {
    /// @notice Returns the sender address appended at the end of the calldata, as specified in EIP-2771.
    function msgSender() internal pure returns (address sender) {
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
    }

    /// @notice Returns the calldata while omitting the appended sender address, as specified in EIP-2771.
    function msgData() internal pure returns (bytes calldata data) {
        unchecked {
            return msg.data[:msg.data.length - 20];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";
import {ProxyInitialization} from "./ProxyInitialization.sol";

library ProxyAdminStorage {
    using ProxyAdminStorage for ProxyAdminStorage.Layout;

    struct Layout {
        address admin;
    }

    // bytes32 public constant PROXYADMIN_STORAGE_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;
    bytes32 internal constant LAYOUT_STORAGE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);
    bytes32 internal constant PROXY_INIT_PHASE_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin.phase")) - 1);

    event AdminChanged(address previousAdmin, address newAdmin);

    /// @notice Initializes the storage with an initial admin (immutable version).
    /// @dev Note: This function should be called ONLY in the constructor of an immutable (non-proxied) contract.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function constructorInit(Layout storage s, address initialAdmin) internal {
        require(initialAdmin != address(0), "ProxyAdmin: no initial admin");
        s.admin = initialAdmin;
        emit AdminChanged(address(0), initialAdmin);
    }

    /// @notice Initializes the storage with an initial admin (proxied version).
    /// @notice Sets the proxy initialization phase to `1`.
    /// @dev Note: This function should be called ONLY in the init function of a proxied contract.
    /// @dev Reverts if the proxy initialization phase is set to `1` or above.
    /// @dev Reverts if `initialAdmin` is the zero address.
    /// @dev Emits an {AdminChanged} event.
    /// @param initialAdmin The initial payout wallet.
    function proxyInit(Layout storage s, address initialAdmin) internal {
        ProxyInitialization.setPhase(PROXY_INIT_PHASE_SLOT, 1);
        s.constructorInit(initialAdmin);
    }

    /// @notice Sets a new proxy admin.
    /// @dev Reverts if `sender` is not the proxy admin.
    /// @dev Emits an {AdminChanged} event if `newAdmin` is different from the current proxy admin.
    /// @param newAdmin The new proxy admin.
    function changeProxyAdmin(Layout storage s, address sender, address newAdmin) internal {
        address previousAdmin = s.admin;
        require(sender == previousAdmin, "ProxyAdmin: not the admin");
        if (previousAdmin != newAdmin) {
            s.admin = newAdmin;
            emit AdminChanged(previousAdmin, newAdmin);
        }
    }

    /// @notice Gets the proxy admin.
    /// @return admin The proxy admin
    function proxyAdmin(Layout storage s) internal view returns (address admin) {
        return s.admin;
    }

    /// @notice Ensures that an account is the proxy admin.
    /// @dev Reverts if `account` is not the proxy admin.
    /// @param account The account.
    function enforceIsProxyAdmin(Layout storage s, address account) internal view {
        require(account == s.admin, "ProxyAdmin: not the admin");
    }

    function layout() internal pure returns (Layout storage s) {
        bytes32 position = LAYOUT_STORAGE_SLOT;
        assembly {
            s.slot := position
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {StorageSlot} from "@openzeppelin/contracts/utils/StorageSlot.sol";

/// @notice Multiple calls protection for storage-modifying proxy initialization functions.
library ProxyInitialization {
    /// @notice Sets the initialization phase during a storage-modifying proxy initialization function.
    /// @dev Reverts if `phase` has been reached already.
    /// @param storageSlot the storage slot where `phase` is stored.
    /// @param phase the initialization phase.
    function setPhase(bytes32 storageSlot, uint256 phase) internal {
        StorageSlot.Uint256Slot storage currentVersion = StorageSlot.getUint256Slot(storageSlot);
        require(currentVersion.value < phase, "Storage: phase reached");
        currentVersion.value = phase;
    }
}