// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondFacet.sol
/******************************************************************************/

import "./DiamondStorageBase.sol";
import "./IDiamondCutter.sol";

contract DiamondCutter is DiamondStorageBase, IDiamondCutter {
    bytes32 constant CLEAR_ADDRESS_MASK = 0x0000000000000000000000000000000000000000ffffffffffffffffffffffff;
    bytes32 constant CLEAR_SELECTOR_MASK = 0xffffffff00000000000000000000000000000000000000000000000000000000;

    struct SlotInfo {
        uint256 originalSelectorSlotsLength;
        bytes32 selectorSlot;
        uint256 oldSelectorSlotsIndex;
        uint256 oldSelectorSlotIndex;
        bytes32 oldSelectorSlot;
        bool newSlot;
    }

    function diamondCut(bytes[] memory _diamondCut) public override {
        DiamondStorage storage ds = diamondStorage();
        SlotInfo memory slot;
        slot.originalSelectorSlotsLength = ds.selectorSlotsLength;
        uint256 selectorSlotsLength = uint128(slot.originalSelectorSlotsLength);
        uint256 selectorSlotLength = uint128(slot.originalSelectorSlotsLength >> 128);
        if (selectorSlotLength > 0) {
            slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
        }
        // loop through diamond cut
        for (uint256 diamondCutIndex; diamondCutIndex < _diamondCut.length; diamondCutIndex++) {
            bytes memory facetCut = _diamondCut[diamondCutIndex];
            require(facetCut.length > 20, "Missing facet or selector info.");
            bytes32 currentSlot;
            assembly {
                currentSlot := mload(add(facetCut, 32))
            }
            bytes32 newFacet = bytes20(currentSlot);
            uint256 numSelectors = (facetCut.length - 20) / 4;
            uint256 position = 52;

            // adding or replacing functions
            if (newFacet != 0) {
                // add and replace selectors
                for (uint256 selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut, position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
                    // add
                    if (oldFacet == 0) {
                        ds.facets[selector] = newFacet | (bytes32(selectorSlotLength) << 64) | bytes32(selectorSlotsLength);
                        slot.selectorSlot = (slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> (selectorSlotLength * 32))) | (bytes32(selector) >> (selectorSlotLength * 32));
                        selectorSlotLength++;
                        if (selectorSlotLength == 8) {
                            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
                            slot.selectorSlot = 0;
                            selectorSlotLength = 0;
                            selectorSlotsLength++;
                            slot.newSlot = false;
                        } else {
                            slot.newSlot = true;
                        }
                    }
                    // replace
                    else {
                        require(bytes20(oldFacet) != bytes20(newFacet), "Function cut to same facet.");
                        ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | newFacet;
                    }
                }
            }
            // remove functions
            else {
                for (uint256 selectorIndex; selectorIndex < numSelectors; selectorIndex++) {
                    bytes4 selector;
                    assembly {
                        selector := mload(add(facetCut, position))
                    }
                    position += 4;
                    bytes32 oldFacet = ds.facets[selector];
                    require(oldFacet != 0, "Function doesn't exist. Can't remove.");
                    if (slot.selectorSlot == 0) {
                        selectorSlotsLength--;
                        slot.selectorSlot = ds.selectorSlots[selectorSlotsLength];
                        selectorSlotLength = 8;
                    }
                    slot.oldSelectorSlotsIndex = uint64(uint256(oldFacet));
                    slot.oldSelectorSlotIndex = uint32(uint256(oldFacet >> 64));
                    bytes4 lastSelector = bytes4(slot.selectorSlot << ((selectorSlotLength - 1) * 32));
                    if (slot.oldSelectorSlotsIndex != selectorSlotsLength) {
                        slot.oldSelectorSlot = ds.selectorSlots[slot.oldSelectorSlotsIndex];
                        slot.oldSelectorSlot =
                            (slot.oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> (slot.oldSelectorSlotIndex * 32))) |
                            (bytes32(lastSelector) >> (slot.oldSelectorSlotIndex * 32));
                        ds.selectorSlots[slot.oldSelectorSlotsIndex] = slot.oldSelectorSlot;
                        selectorSlotLength--;
                    } else {
                        slot.selectorSlot =
                            (slot.selectorSlot & ~(CLEAR_SELECTOR_MASK >> (slot.oldSelectorSlotIndex * 32))) |
                            (bytes32(lastSelector) >> (slot.oldSelectorSlotIndex * 32));
                        selectorSlotLength--;
                    }
                    if (selectorSlotLength == 0) {
                        delete ds.selectorSlots[selectorSlotsLength];
                        slot.selectorSlot = 0;
                    }
                    if (lastSelector != selector) {
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                }
            }
        }
        uint256 newSelectorSlotsLength = (selectorSlotLength << 128) | selectorSlotsLength;
        if (newSelectorSlotsLength != slot.originalSelectorSlotsLength) {
            ds.selectorSlotsLength = newSelectorSlotsLength;
        }
        if (slot.newSlot) {
            ds.selectorSlots[selectorSlotsLength] = slot.selectorSlot;
        }
        emit DiamondCut(_diamondCut);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;
/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondStorageContract.sol
/******************************************************************************/

import "./EternalStorage.sol";

contract DiamondStorageBase is EternalStorage {
    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to the slot in the selectorSlots array.
        // and maps the selectors to the position in the slot.
        // func selector => address facet, uint64 slotsIndex, uint64 slotIndex
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // uint128 numSelectorsInSlot, uint128 selectorSlotsLength
        // selectorSlotsLength is the number of 32-byte slots in selectorSlots.
        // selectorSlotLength is the number of selectors in the last slot of
        // selectorSlots.
        uint256 selectorSlotsLength;
        // tracking initialization state
        // we use this to know whether a call to diamondCut() is part of the initial
        // construction or a later "upgrade" call
        bool initialized;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        // ds_slot = keccak256("diamond.standard.diamond.storage");
        assembly {
            ds.slot := 0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/******************************************************************************\
Forked from https://github.com/mudgen/Diamond/blob/master/contracts/DiamondHeaders.sol
/******************************************************************************/

interface IDiamondCutter {
    /// @notice _diamondCut is an array of bytes arrays.
    /// This argument is tightly packed for gas efficiency.
    /// That means no padding with zeros.
    /// Here is the structure of _diamondCut:
    /// _diamondCut = [
    ///     abi.encodePacked(facet, sel1, sel2, sel3, ...),
    ///     abi.encodePacked(facet, sel1, sel2, sel4, ...),
    ///     ...
    /// ]
    /// facet is the address of a facet
    /// sel1, sel2, sel3 etc. are four-byte function selectors.
    function diamondCut(bytes[] calldata _diamondCut) external;

    event DiamondCut(bytes[] _diamondCut);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

/**
 * @dev Base contract for any upgradeable contract that wishes to store data.
 */
contract EternalStorage {
    // scalars
    mapping(string => address) dataAddress;
    mapping(string => bytes32) dataBytes32;
    mapping(string => int256) dataInt256;
    mapping(string => uint256) dataUint256;
    mapping(string => bool) dataBool;
    mapping(string => string) dataString;
    mapping(string => bytes) dataBytes;
    // arrays
    mapping(string => address[]) dataManyAddresses;
    mapping(string => bytes32[]) dataManyBytes32s;
    mapping(string => int256[]) dataManyInt256;
    mapping(string => uint256[]) dataManyUint256;

    // helpers
    function __i(uint256 i1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, s));
    }

    function __a(address a1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, s));
    }

    function __aa(
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, a2, s));
    }

    function __b(bytes32 b1, string memory s) internal pure returns (string memory) {
        return string(abi.encodePacked(b1, s));
    }

    function __ii(
        uint256 i1,
        uint256 i2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, i2, s));
    }

    function __ia(
        uint256 i1,
        address a1,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, s));
    }

    function __iaa(
        uint256 i1,
        address a1,
        address a2,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, s));
    }

    function __iaaa(
        uint256 i1,
        address a1,
        address a2,
        address a3,
        string memory s
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(i1, a1, a2, a3, s));
    }

    function __ab(address a1, bytes32 b1) internal pure returns (string memory) {
        return string(abi.encodePacked(a1, b1));
    }
}