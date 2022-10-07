// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/
import { LibDiamond } from "../shared/libs/LibDiamond.sol";
import { DiamondCutFacet } from "../shared/facets/DiamondCutFacet.sol";
import { DiamondLoupeFacet } from "../shared/facets/DiamondLoupeFacet.sol";
import { NaymsOwnershipFacet } from "src/diamonds/shared/facets/NaymsOwnershipFacet.sol";
// import { OwnershipFacet } from "src/diamonds/shared/facets/OwnershipFacet.sol";
import { AppStorage } from "./AppStorage.sol";

contract Nayms {
    constructor(address _contractOwner) payable {
        LibDiamond.setContractOwner(_contractOwner);
        LibDiamond.addDiamondFunctions(address(new DiamondCutFacet()), address(new DiamondLoupeFacet()), address(new NaymsOwnershipFacet()));
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    // solhint-disable no-complex-fallback
    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = address(bytes20(ds.facets[msg.sig]));
        LibDiamond.enforceHasContractCode(facet, "Diamond: Facet has no code");
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    // solhint-disable no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

library LibDiamond {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    function addDiamondFunctions(
        address _diamondCutFacet,
        address _diamondLoupeFacet,
        address _ownershipFacet
    ) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](3);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({ facetAddress: _diamondCutFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](5);
        functionSelectors[0] = IDiamondLoupe.facets.selector;
        functionSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        functionSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        functionSelectors[3] = IDiamondLoupe.facetAddress.selector;
        functionSelectors[4] = IERC165.supportsInterface.selector;
        cut[1] = IDiamondCut.FacetCut({ facetAddress: _diamondLoupeFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        functionSelectors = new bytes4[](2);
        functionSelectors[0] = IERC173.transferOwnership.selector;
        functionSelectors[1] = IERC173.owner.selector;
        cut[2] = IDiamondCut.FacetCut({ facetAddress: _ownershipFacet, action: IDiamondCut.FacetCutAction.Add, functionSelectors: functionSelectors });
        diamondCut(cut, address(0), "");
    }

    event DiamondCut(IDiamondCut.FacetCut[] diamondCut, address init, bytes _calldata);

    bytes32 internal constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 internal constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8"
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8"
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot = (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) | (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { LibDiamond } from "../libs/LibDiamond.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex = 0; facetIndex < _diamondCut.length; facetIndex++) {
            (selectorCount, selectorSlot) = LibDiamond.addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8"
        if (selectorCount & 7 > 0) {
            // "selectorCount >> 3" is a gas efficient division by 8 "selectorCount / 8"
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        LibDiamond.initializeDiamondCut(_init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { LibDiamond } from "../libs/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    // Diamond Loupe Functions
    ////////////////////////////////////////////////////////////////////
    /// These functions are expected to be called frequently by tools.
    //
    // struct Facet {
    //     address facetAddress;
    //     bytes4[] functionSelectors;
    // }
    /// @notice Gets all facets and their selectors.
    /// @return facets_ Facet
    function facets() external view override returns (Facet[] memory facets_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facets_ = new Facet[](ds.selectorCount);
        uint8[] memory numFacetSelectors = new uint8[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facets_[facetIndex].facetAddress == facetAddress_) {
                        facets_[facetIndex].functionSelectors[numFacetSelectors[facetIndex]] = selector;
                        // probably will never have more than 256 functions from one facet contract
                        require(numFacetSelectors[facetIndex] < 255);
                        numFacetSelectors[facetIndex]++;
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facets_[numFacets].facetAddress = facetAddress_;
                facets_[numFacets].functionSelectors = new bytes4[](ds.selectorCount);
                facets_[numFacets].functionSelectors[0] = selector;
                numFacetSelectors[numFacets] = 1;
                numFacets++;
            }
        }
        for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
            uint256 numSelectors = numFacetSelectors[facetIndex];
            bytes4[] memory selectors = facets_[facetIndex].functionSelectors;
            // setting the number of selectors
            assembly {
                mstore(selectors, numSelectors)
            }
        }
        // setting the number of facets
        assembly {
            mstore(facets_, numFacets)
        }
    }

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return _facetFunctionSelectors The selectors associated with a facet address.
    function facetFunctionSelectors(address _facet) external view override returns (bytes4[] memory _facetFunctionSelectors) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors;
        _facetFunctionSelectors = new bytes4[](ds.selectorCount);
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facet = address(bytes20(ds.facets[selector]));
                if (_facet == facet) {
                    _facetFunctionSelectors[numSelectors] = selector;
                    numSelectors++;
                }
            }
        }
        // Set the number of selectors in the array
        assembly {
            mstore(_facetFunctionSelectors, numSelectors)
        }
    }

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view override returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddresses_ = new address[](ds.selectorCount);
        uint256 numFacets;
        uint256 selectorIndex;
        // loop through function selectors
        for (uint256 slotIndex; selectorIndex < ds.selectorCount; slotIndex++) {
            bytes32 slot = ds.selectorSlots[slotIndex];
            for (uint256 selectorSlotIndex; selectorSlotIndex < 8; selectorSlotIndex++) {
                selectorIndex++;
                if (selectorIndex > ds.selectorCount) {
                    break;
                }
                bytes4 selector = bytes4(slot << (selectorSlotIndex << 5));
                address facetAddress_ = address(bytes20(ds.facets[selector]));
                bool continueLoop;
                for (uint256 facetIndex; facetIndex < numFacets; facetIndex++) {
                    if (facetAddress_ == facetAddresses_[facetIndex]) {
                        continueLoop = true;
                        break;
                    }
                }
                if (continueLoop) {
                    continue;
                }
                facetAddresses_[numFacets] = facetAddress_;
                numFacets++;
            }
        }
        // Set the number of facet addresses in the array
        assembly {
            mstore(facetAddresses_, numFacets)
        }
    }

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = address(bytes20(ds.facets[_functionSelector]));
    }

    // This implements ERC-165.
    function supportsInterface(bytes4 _interfaceId) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        return ds.supportedInterfaces[_interfaceId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibACL } from "src/diamonds/nayms/libs/LibACL.sol";
import { LibHelpers } from "src/diamonds/nayms/libs/LibHelpers.sol";
import { LibConstants } from "src/diamonds/nayms/libs/LibConstants.sol";
import { LibDiamond } from "src/diamonds/shared/libs/LibDiamond.sol";
import { OwnershipFacet } from "src/diamonds/shared/facets/OwnershipFacet.sol";

contract NaymsOwnershipFacet is OwnershipFacet {
    function transferOwnership(address _newOwner) public override {
        super.transferOwnership(_newOwner);

        bytes32 systemID = LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
        bytes32 oldAcc1Id = LibHelpers._getIdForAddress(msg.sender);
        bytes32 newAcc1Id = LibHelpers._getIdForAddress(_newOwner);

        LibACL._assignRole(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.ROLE_SYSTEM_ADMIN));
        require(LibACL._isInGroup(newAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)), "NEW owner NOT in sys admin group");

        LibACL._unassignRole(oldAcc1Id, systemID);
        require(!LibACL._isInGroup(oldAcc1Id, systemID, LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)), "OLD owner STILL in sys admin group");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice storage for nayms v3 decentralized insurance platform

import "./interfaces/FreeStructs.sol";

import { LibMeta } from "../shared/libs/LibMeta.sol";

import { LibAdmin } from "./libs/LibAdmin.sol";
import { LibConstants } from "./libs/LibConstants.sol";
import { LibHelpers } from "./libs/LibHelpers.sol";
import { LibObject } from "./libs/LibObject.sol";

import { LibACL } from "./libs/LibACL.sol";

struct AppStorage {
    //// NAYMS ERC20 TOKEN ////
    mapping(address => uint256) nonces; //is this used?
    mapping(address => mapping(address => uint256)) allowance;
    uint256 totalSupply;
    mapping(bytes32 => bool) internalToken;
    mapping(address => uint256) balances;
    //// Object ////
    mapping(bytes32 => bool) existingObjects; // objectId => is an object?
    mapping(bytes32 => bytes32) objectParent; // objectId => parentId
    mapping(bytes32 => bytes32) objectDataHashes;
    mapping(bytes32 => bytes32) objectTokenSymbol;
    mapping(bytes32 => bool) existingEntities; // entityId => is an entity?
    mapping(bytes32 => bool) existingSimplePolicies; // simplePolicyId => is a simple policy?
    //// ENTITY ////
    mapping(bytes32 => Entity) entities; // objectId => Entity struct
    //// SIMPLE POLICY ////
    mapping(bytes32 => SimplePolicy) simplePolicies; // objectId => SimplePolicy struct
    // External Tokens
    // mapping(bytes32 => bool) externalTokens; // bytes32 ID of external token => is external token?
    mapping(address => bool) externalTokenSupported;
    address[] supportedExternalTokens;
    //// TokenizedObject ////
    mapping(bytes32 => mapping(bytes32 => uint256)) tokenBalances; // tokenId => (ownerId => balance)
    mapping(bytes32 => uint256) tokenSupply; // tokenId => Total Token Supply
    //    mapping(address => uint256) permitExternalDepositNonce; // Is this used?
    // limit to three when updating???

    //// Dividends ////
    uint8 maxDividendDenominations;
    mapping(bytes32 => bytes32[]) dividendDenominations; // object => tokenId of the dividend it allows
    mapping(bytes32 => mapping(bytes32 => uint8)) dividendDenominationIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(uint8 => bytes32)) dividendDenominationAtIndex; // entity ID => (token ID => index of dividend denomination)
    mapping(bytes32 => mapping(bytes32 => uint256)) totalDividends; // token ID => (denomination ID => total dividend)
    mapping(bytes32 => mapping(bytes32 => mapping(bytes32 => uint256))) withdrawnDividendPerOwner; // entity => (tokenId => (owner => total withdrawn dividend)) NOT per share!!! this is TOTAL
    // // Keep track of the different dividends issued on chain
    // mapping(bytes32 => mapping(bytes32 => uint8)) issuedDividendsTokensIndex; // ownerId => dividendTokenId => index
    // mapping(bytes32 => mapping(uint8 => bytes32)) issuedDividendTokens; // ownerId => index => dividendTokenId
    // mapping(bytes32 => uint8) numIssuedDividends; //starts at 1. 0 means no dividends issued
    // //// DIVIDEND PAYOUT LOGIC ////
    // mapping(bytes32 => mapping(bytes32 => uint256)) divPerTokens; // entity ID => token ID => dividend per token ratio
    // mapping(bytes32 => mapping(bytes32 => EntityDividendInfo)) dividendInfos; // entity ID => token ID => dividend info

    // When a dividend is payed, you divide by the total supply and add it to the totalDividendPerToken
    // Dividends are held by the diamond contract LibHelpers._getIdForAddress(address(this))
    // When dividends are paid, they are transfered OUT of the diamond contract.
    //
    //
    // To calculate withdrawableDividiend = ownedTokens * totalDividendPerToken - totalWithdrawnDividendPerOwner
    //
    // When a dividend is collected you set the totalWithdrawnDividendPerOwner to the total amount the owner withdrew
    //
    // When you trasnsfer, you pay out all dividends to previous owner first, then transfer ownership
    // !!!YOU ALSO TRANSFER totalWithdrawnDividendPerOwner for those shares!!!
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesTransfered * totalDividendPerToken
    // totalWithdrawnDividendPerOwner(for previous owner) -= numberOfSharesTransfered * totalDividendPerToken (can be optimized)
    //
    // When minting
    // Add the token balance to the new owner
    // totalWithdrawnDividendPerOwner(for new owner) += numberOfSharesMinted * totalDividendPerToken
    //
    // When doing the division theser will be dust. Leave the dust in the diamond!!!

    //// ACL Configuration////
    mapping(bytes32 => mapping(bytes32 => bool)) groups; //role => (group => isRoleInGroup)
    mapping(bytes32 => bytes32) canAssign; //role => Group that can assign/unassign that role
    string[][] groupsConfig;
    string[][] canAssignConfig;
    //// User Data ////
    mapping(bytes32 => mapping(bytes32 => bytes32)) roles; // userId => (contextId => role)
    //// ACL Non Essential ////
    //these are only for user viewing. They can be removed.

    //// MARKET ////
    uint256 lastOfferId;
    mapping(uint256 => MarketInfo) offers; // offer Id => MarketInfo struct
    mapping(bytes32 => mapping(bytes32 => uint256)) bestOfferId; // sell token => buy token => best offer Id
    mapping(bytes32 => mapping(bytes32 => uint256)) span; // sell token => buy token => span
    ////  STAKING  ////
    mapping(bytes32 => LockedBalance) userLockedBalances; // userID => LockedBalance struct todo NOT YET READY TO BE REMOVED
    mapping(bytes32 => uint256) userLockedEndTime; // userID => locked end time
    mapping(uint256 => StakingCheckpoint) globalStakingCheckpointHistory; // epoch => StakingCheckpoint struct
    mapping(bytes32 => mapping(uint256 => StakingCheckpoint)) userStakingCheckpointHistory; // userID => epoch => StakingCheckpoint
    mapping(bytes32 => uint256) userStakingCheckpointEpoch; // userID => user_epoch
    mapping(uint256 => int128) stakingSlopeChanges; // timestamp => signed slope change
    uint256 stakingEpoch;
    // Keep track of the different tokens owned on chain
    mapping(bytes32 => mapping(bytes32 => uint8)) ownedTokenIndex; // ownerId => tokenId => index
    mapping(bytes32 => mapping(uint8 => bytes32)) ownedTokenAtIndex; // ownerId => index => tokenId
    mapping(bytes32 => uint8) numOwnedTokens; //starts at 1. 0 means no tokens owned
    // issuedDividendsIndex
    // issuedDividendsAtIndex
    // numIssuedDividends

    // mapping(ownerid => tokenid => index =) issuedDividends
    // mapping() numIssuedDividends //starts at 0

    ////
    //// FROM HERE ON, EVERYTHING IS DEPRECATED. MOVE TO USING THE SAME VARIABLE IN THE "Settings" STRUCTURE
    //// Use LibAdminFunctions._getSettings() to get the instance of settings you need
    ////

    // //// FEE BANK ////
    // bytes32 feeBankId;
    // bytes32 naymsLtdId;
    // bytes32 brokerFeeBankId; // the internal address that the fees all brokers have earned get distribuited to
    // bytes32 marketplaceBankId;
    // bytes32 dividendBankId;
    // bytes32 ndfBankId;
    ////  NDF  ////
    uint256 equilibriumLevel;
    uint256 actualDiscount;
    uint256 maxDiscount;
    uint256 actualNaymsAllocation;
    uint256 targetNaymsAllocation;
    address discountToken;
    uint24 poolFee;
    //// SSF ////
    uint256 rewardsCoefficient;
    mapping(bytes32 => uint256) userRewards;
    //// LP ////
    address lpAddress;
    ////  NAYMS  ////
    string wrappedTokenName;
    string wrappedTokenSymbol;
    uint8 wrappedTokenDecimals;
    address naymsToken; // represents the address key for this NAYMS token in AppStorage 1155 system
    bytes32 naymsTokenId; // represents the bytes32 key for this NAYMS token in AppStorage 1155 system
    //Token addresses for quotes and swaps
    address token0;
    address token1;
    //address token2;
    address pool;
    address uniswapFactory;
    /// Trading Commissions (all in basis points) ///
    uint16 tradingCommissionTotalBP; // the total amount that is deducted for trading commissions (BP)
    // The total commission above is further divided as follows:
    uint16 tradingCommissionNaymsLtdBP;
    uint16 tradingCommissionNDFBP;
    uint16 tradingCommissionSTMBP;
    uint16 tradingCommissionMakerBP;
    // Premium Commissions
    uint16 premiumCommissionNaymsLtdBP;
    uint16 premiumCommissionNDFBP;
    uint16 premiumCommissionSTMBP;
    // A policy can pay out additional commissions on premiums to entities having a variety of roles on the policy

    mapping(bytes32 => mapping(bytes32 => uint256)) marketLockedBalances; // to keep track of an owner's tokens that are on sale in the marketplace, ownerId => lockedTokenId => amount
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier assertSysAdmin() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_ADMINS)),
            "not a system admin"
        );
        _;
    }

    modifier assertSysMgr() {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), LibAdmin._getSystemId(), LibHelpers._stringToBytes32(LibConstants.GROUP_SYSTEM_MANAGERS)),
            "not a system manager"
        );
        _;
    }

    modifier assertEntityAdmin(bytes32 _context) {
        require(
            LibACL._isInGroup(LibHelpers._getIdForAddress(LibMeta.msgSender()), _context, LibHelpers._stringToBytes32(LibConstants.GROUP_ENTITY_ADMINS)),
            "not the entity's admin"
        );
        _;
    }

    modifier assertIsInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _group
    ) {
        require(LibACL._isInGroup(_objectId, _contextId, _group), "not in group");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

interface IERC165 {
    /// @notice Query if a contract implements an interface
    /// @param interfaceId The interface identifier, as specified in ERC-165
    /// @dev Interface identification is specified in ERC-165. This function
    ///  uses less than 30,000 gas.
    /// @return `true` if the contract implements `interfaceID` and
    ///  `interfaceID` is not 0xffffffff, `false` otherwise
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0 is ERC165
interface IERC173 {
    /// @dev This emits when ownership of a contract changes.
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Get the address of the owner
    /// @return owner_ The address of the owner.
    function owner() external view returns (address owner_);

    /// @notice Set the address of the new owner of the contract
    /// @dev Set _newOwner to address(0) to renounce any ownership.
    /// @param _newOwner The address of the new owner of the contract
    function transferOwnership(address _newOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage, Modifiers } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";
import { LibObject } from "./LibObject.sol";

library LibACL {
    /**
     * @dev Emitted when a role gets updated. Empty roleId is assigned upon role removal
     * @param objectId The user or object that was assigned the role.
     * @param contextId The context where the role was assigned to.
     * @param roleId The ID of the role which got unassigned. (empty ID when unassigned)
     * @param functionName The function performing the action
     */
    event RoleUpdate(bytes32 indexed objectId, bytes32 contextId, bytes32 roleId, string functionName);

    function _assignRole(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.roles[_objectId][_contextId] = _roleId;
        emit RoleUpdate(_objectId, _contextId, _roleId, "_assignRole");
    }

    function _unassignRole(bytes32 _objectId, bytes32 _contextId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        emit RoleUpdate(_objectId, _contextId, s.roles[_objectId][_contextId], "_unassignRole");
        delete s.roles[_objectId][_contextId];
    }

    function _isInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool ret) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Check for the role in the context
        bytes32 objectRoleInContext = s.roles[_objectId][_contextId];

        if (s.groups[objectRoleInContext][_groupId]) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            bytes32 objectRoleInSystem = s.roles[_objectId][LibAdmin._getSystemId()];

            if (s.groups[objectRoleInSystem][_groupId]) {
                ret = true;
            }
        }
    }

    function _isParentInGroup(
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _groupId
    ) internal view returns (bool) {
        bytes32 parentId = LibObject._getParent(_objectId);
        return _isInGroup(parentId, _contextId, _groupId);
    }

    /// Can a user (or object) assign a role in a given context
    function _canAssign(
        bytes32 _assignerId,
        bytes32 _objectId,
        bytes32 _contextId,
        bytes32 _roleId
    ) internal view returns (bool) {
        // we might impose additional restrictions on _objectId in the future
        require(_objectId != "", "invalid object ID");
        bool ret = false;
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 assignerGroup = s.canAssign[_roleId];

        // Check for group membership in the given context
        if (_isInGroup(_assignerId, _contextId, assignerGroup)) {
            ret = true;
        } else {
            // A role in the context of the system covers all objects
            if (_isParentInGroup(_assignerId, LibAdmin._getSystemId(), assignerGroup)) {
                ret = true;
            }
        }
        return ret;
    }

    function _getRoleInContext(bytes32 _objectId, bytes32 _contextId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.roles[_objectId][_contextId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

/// @notice Pure functions
library LibHelpers {
    function _getIdForObjectAtIndex(uint256 _index) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_index));
    }

    function _getIdForAddress(address _addr) internal pure returns (bytes32) {
        return bytes32(bytes20(_addr));
    }

    function _getSenderId() internal view returns (bytes32) {
        return _getIdForAddress(msg.sender);
    }

    function _getAddressFromId(bytes32 _id) internal pure returns (address) {
        return address(bytes20(_id));
    }

    // Conversion Utilities

    function _addressToBytes32(address addr) internal pure returns (bytes32 result) {
        return _bytesToBytes32(abi.encode(addr));
    }

    function _stringToBytes32(string memory strIn) internal pure returns (bytes32 result) {
        return _bytesToBytes32(bytes(strIn));
    }

    function _bytes32ToString(bytes32 bytesIn) internal pure returns (string memory) {
        return string(_bytes32ToBytes(bytesIn));
    }

    function _bytesToBytes32(bytes memory source) internal pure returns (bytes32 result) {
        if (source.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function _bytes32ToBytes(bytes32 input) internal pure returns (bytes memory) {
        bytes memory b = new bytes(32);
        assembly {
            mstore(add(b, 32), input)
        }
        return b;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibHelpers } from "./LibHelpers.sol";

/**
 * @dev Settings keys.
 */
library LibConstants {
    //Reserved IDs
    string internal constant EMPTY_IDENTIFIER = "";
    string internal constant SYSTEM_IDENTIFIER = "System";
    string internal constant NDF_IDENTIFIER = "NDF";
    string internal constant STM_IDENTIFIER = "Staking Mechanism";
    string internal constant SSF_IDENTIFIER = "SSF";
    string internal constant NAYM_TOKEN_IDENTIFIER = "NAYM"; //This is the ID in the system as well as the token ID
    string internal constant DIVIDEND_BANK_IDENTIFIER = "Dividend Bank"; //This will hold all the dividends
    string internal constant NAYMS_LTD_IDENTIFIER = "Nayms Ltd";

    //Roles
    string internal constant ROLE_SYSTEM_ADMIN = "System Admin";
    string internal constant ROLE_SYSTEM_MANAGER = "System Manager";
    string internal constant ROLE_ENTITY_ADMIN = "Entity Admin";
    string internal constant ROLE_ENTITY_MANAGER = "Entity Manager";
    string internal constant ROLE_BROKER = "Broker";
    string internal constant ROLE_INSURED_PARTY = "Insured";
    string internal constant ROLE_UNDERWRITER = "Underwriter";
    string internal constant ROLE_CAPITAL_PROVIDER = "Capital Provider";
    string internal constant ROLE_CLAIMS_ADMIN = "Claims Admin";
    string internal constant ROLE_TRADER = "Trader";

    //Groups
    string internal constant GROUP_SYSTEM_ADMINS = "System Admins";
    string internal constant GROUP_SYSTEM_MANAGERS = "System Managers";
    string internal constant GROUP_ENTITY_ADMINS = "Entity Admins";
    string internal constant GROUP_ENTITY_MANAGERS = "Entity Managers";
    string internal constant GROUP_APPROVED_USERS = "Approved Users";
    string internal constant GROUP_BROKERS = "Brokers";
    string internal constant GROUP_INSURED_PARTIES = "Insured Parties";
    string internal constant GROUP_UNDERWRITERS = "Underwriters";
    string internal constant GROUP_CAPITAL_PROVIDERS = "Capital Providers";
    string internal constant GROUP_CLAIMS_ADMINS = "Claims Admins";
    string internal constant GROUP_TRADERS = "Traders";

    /*///////////////////////////////////////////////////////////////////////////
                        Market Fee Schedules
    ///////////////////////////////////////////////////////////////////////////*/

    /**
     * @dev Standard fee is charged.
     */
    uint256 internal constant FEE_SCHEDULE_STANDARD = 1;
    /**
     * @dev Platform-initiated trade, e.g. token sale or buyback.
     */
    uint256 internal constant FEE_SCHEDULE_PLATFORM_ACTION = 2;

    /*///////////////////////////////////////////////////////////////////////////
                        MARKET OFFER STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant OFFER_STATE_ACTIVE = 1;
    uint256 internal constant OFFER_STATE_CANCELLED = 2;
    uint256 internal constant OFFER_STATE_FULFILLED = 3;

    uint256 internal constant DUST = 1;

    /*///////////////////////////////////////////////////////////////////////////
                        SIMPLE POLICY STATES
    ///////////////////////////////////////////////////////////////////////////*/

    uint256 internal constant SIMPLE_POLICY_STATE_CREATED = 0;
    uint256 internal constant SIMPLE_POLICY_STATE_APPROVED = 1;
    uint256 internal constant SIMPLE_POLICY_STATE_ACTIVE = 2;
    uint256 internal constant SIMPLE_POLICY_STATE_MATURED = 3;
    uint256 internal constant SIMPLE_POLICY_STATE_CANCELLED = 4;
    uint256 internal constant STAKING_WEEK = 7 days;
    uint256 internal constant STAKING_MINTIME = 60 days; // 60 days min lock
    uint256 internal constant STAKING_MAXTIME = 4 * 365 days; // 4 years max lock
    uint256 internal constant SCALE = 1e18; //10 ^ 18

    /// _depositFor Types for events
    int128 internal constant STAKING_DEPOSIT_FOR_TYPE = 0;
    int128 internal constant STAKING_CREATE_LOCK_TYPE = 1;
    int128 internal constant STAKING_INCREASE_LOCK_AMOUNT = 2;
    int128 internal constant STAKING_INCREASE_UNLOCK_TIME = 3;

    string internal constant VE_NAYM_NAME = "veNAYM";
    string internal constant VE_NAYM_SYMBOL = "veNAYM";
    uint8 internal constant VE_NAYM_DECIMALS = 18;
    uint8 internal constant INTERNAL_TOKEN_DECIMALS = 18;
    address internal constant DAI_CONSTANT = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { LibDiamond } from "../libs/LibDiamond.sol";
import { IERC173 } from "../interfaces/IERC173.sol";

contract OwnershipFacet is IERC173 {
    function transferOwnership(address _newOwner) public virtual override {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.setContractOwner(_newOwner);
    }

    function owner() external view override returns (address owner_) {
        owner_ = LibDiamond.contractOwner();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

struct MarketInfo {
    bytes32 creator; // entity ID
    bytes32 sellToken;
    uint256 sellAmount;
    uint256 sellAmountInitial;
    bytes32 buyToken;
    uint256 buyAmount;
    uint256 buyAmountInitial;
    // uint256 averagePrice;
    uint256 feeSchedule;
    uint256 state;
    uint256 rankNext;
    uint256 rankPrev;
}

struct TokenAmount {
    bytes32 token;
    uint256 amount;
}

struct MultiToken {
    string tokenUri;
    // kp NOTE todo: what is this struct for?
    mapping(uint256 => mapping(bytes32 => uint256)) tokenBalances; // token ID to account balance
    mapping(bytes32 => mapping(bytes32 => bool)) tokenOpApprovals; // account to operator approvals
}

/**
 * @param maxCapacity Maxmimum allowable amount of capacity that an entity is given. Denominated by assetId.
 * @param utilizedCapacity The utilized capacity of the entity. Denominated by assetId.
 */
struct Entity {
    bytes32 assetId;
    uint256 collateralRatio;
    uint256 maxCapacity;
    uint256 utilizedCapacity;
    bool simplePolicyEnabled;
}

struct SimplePolicy {
    uint256 startDate;
    uint256 maturationDate;
    bytes32 asset;
    uint256 limit;
    bool fundsLocked;
    uint256 claimsPaid;
    uint256 premiumsPaid;
    bytes32[] commissionReceivers;
    uint256[] commissionBasisPoints;
    uint256 sponsorCommissionBasisPoints; //underwriter is parent
}

struct Stakeholders {
    bytes32[] roles;
    bytes32[] entityIds;
    bytes[] signatures;
}

// Used in StakingFacet
struct LockedBalance {
    uint256 amount;
    uint256 endTime;
}

struct StakingCheckpoint {
    int128 bias;
    int128 slope; // - dweight / dt
    uint256 ts; // timestamp
    uint256 blk; // block number
}

struct FeeRatio {
    uint256 brokerShareRatio;
    uint256 naymsLtdShareRatio;
    uint256 ndfShareRatio;
}

struct TradingCommissions {
    uint256 roughCommissionPaid;
    uint256 commissionNaymsLtd;
    uint256 commissionNDF;
    uint256 commissionSTM;
    uint256 commissionMaker;
    uint256 totalCommissions;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

library LibMeta {
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibConstants } from "../libs/LibConstants.sol";
import { LibHelpers } from "../libs/LibHelpers.sol";
import { LibObject } from "../libs/LibObject.sol";

library LibAdmin {
    event BalanceUpdated(uint256 oldBalance, uint256 newBalance);
    event EquilibriumLevelUpdated(uint256 oldLevel, uint256 newLevel);
    event MaxDividendDenominationsUpdated(uint8 oldMax, uint8 newMax);
    event MaxDiscountUpdated(uint256 oldDiscount, uint256 newDiscount);
    event TargetNaymsAllocationUpdated(uint256 oldTarget, uint256 newTarget);
    event DiscountTokenUpdated(address oldToken, address newToken);
    event PoolFeeUpdated(uint256 oldFee, uint256 newFee);
    event CoefficientUpdated(uint256 oldCoefficient, uint256 newCoefficient);
    event RoleGroupUpdated(string role, string group, bool roleInGroup);
    event RoleCanAssignUpdated(string role, string group);
    event SupportedTokenAdded(address tokenAddress);

    function _getSystemId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.SYSTEM_IDENTIFIER);
    }

    function _getEmptyId() internal pure returns (bytes32) {
        return LibHelpers._stringToBytes32(LibConstants.EMPTY_IDENTIFIER);
    }

    function _updateMaxDividendDenominations(uint8 _newMaxDividendDenominations) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(_newMaxDividendDenominations > s.maxDividendDenominations, "_updateMaxDividendDenominations: cannot reduce");
        uint8 old = s.maxDividendDenominations;
        s.maxDividendDenominations = _newMaxDividendDenominations;

        emit MaxDividendDenominationsUpdated(old, _newMaxDividendDenominations);
    }

    function _getMaxDividendDenominations() internal view returns (uint8) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.maxDividendDenominations;
    }

    function _setEquilibriumLevel(uint256 _newLevel) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldLevel = s.equilibriumLevel;
        s.equilibriumLevel = _newLevel;

        emit EquilibriumLevelUpdated(oldLevel, _newLevel);
    }

    function _setMaxDiscount(uint256 _newDiscount) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldDiscount = s.maxDiscount;
        s.maxDiscount = _newDiscount;

        emit MaxDiscountUpdated(oldDiscount, _newDiscount);
    }

    function _setTargetNaymsAllocation(uint256 _newTarget) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldTarget = s.targetNaymsAllocation;
        s.targetNaymsAllocation = _newTarget;

        emit TargetNaymsAllocationUpdated(oldTarget, _newTarget);
    }

    function _setDiscountToken(address _newToken) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        address oldToken = s.discountToken;
        s.discountToken = _newToken;

        emit DiscountTokenUpdated(oldToken, _newToken);
    }

    function _setPoolFee(uint24 _newFee) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        uint256 oldFee = s.poolFee;
        s.poolFee = _newFee;

        emit PoolFeeUpdated(oldFee, _newFee);
    }

    function _setCoefficient(uint256 _newCoefficient) internal {
        require(_newCoefficient <= 1000, "Coefficient too high");

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 oldCoefficient = s.rewardsCoefficient;

        s.rewardsCoefficient = _newCoefficient;

        emit CoefficientUpdated(oldCoefficient, s.rewardsCoefficient);
    }

    function _updateRoleAssigner(string memory _role, string memory _assignerGroup) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.canAssign[LibHelpers._stringToBytes32(_role)] = LibHelpers._stringToBytes32(_assignerGroup);
        emit RoleCanAssignUpdated(_role, _assignerGroup);
    }

    function _updateRoleGroup(
        string memory _role,
        string memory _group,
        bool _roleInGroup
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.groups[LibHelpers._stringToBytes32(_role)][LibHelpers._stringToBytes32(_group)] = _roleInGroup;
        emit RoleGroupUpdated(_role, _group, _roleInGroup);
    }

    function _isSupportedExternalToken(bytes32 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.externalTokenSupported[LibHelpers._getAddressFromId(_tokenId)];
    }

    function _addSupportedExternalToken(address _tokenAddress) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        bool alreadyAdded;
        s.externalTokenSupported[_tokenAddress] = true;

        // Supported tokens cannot be removed because they may exist in the system!
        for (uint256 i = 0; i < s.supportedExternalTokens.length; i++) {
            if (s.supportedExternalTokens[i] == _tokenAddress) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            LibObject._createObject(LibHelpers._getIdForAddress(_tokenAddress));
            s.supportedExternalTokens.push(_tokenAddress);

            emit SupportedTokenAdded(_tokenAddress);
        }
    }

    function _getSupportedExternalTokens() internal view returns (address[] memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // Supported tokens cannot be removed because they may exist in the system!
        return s.supportedExternalTokens;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.13;

import { AppStorage, LibAppStorage } from "../AppStorage.sol";
import { LibHelpers } from "./LibHelpers.sol";
import { LibAdmin } from "./LibAdmin.sol";

/// @notice Contains internal methods for core Nayms system functionality
library LibObject {
    function _createObject(
        bytes32 _objectId,
        bytes32 _parentId,
        bytes32 _dataHash
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        // check if the id has been used (has a parent account associated with it) and revert if it has
        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectParent[_objectId] = _parentId;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _createObject(bytes32 _objectId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(!s.existingObjects[_objectId], "object already exists");

        s.existingObjects[_objectId] = true;
    }

    function _setDataHash(bytes32 _objectId, bytes32 _dataHash) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(s.existingObjects[_objectId], "setDataHash: object doesn't exist");
        s.objectDataHashes[_objectId] = _dataHash;
    }

    function _getDataHash(bytes32 _objectId) internal view returns (bytes32 objectDataHash) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectDataHashes[_objectId];
    }

    function _getParent(bytes32 _objectId) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.objectParent[_objectId];
    }

    function _getParentFromAddress(address addr) internal view returns (bytes32) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        bytes32 objectId = LibHelpers._getIdForAddress(addr);
        return s.objectParent[objectId];
    }

    function _setParent(bytes32 _objectId, bytes32 _parentId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.objectParent[_objectId] = _parentId;
    }

    function _isObjectTokenizable(bytes32 _objectId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return (s.objectTokenSymbol[_objectId] != LibAdmin._getEmptyId());
    }

    function _enableObjectTokenization(bytes32 _objectId, string memory _symbol) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        require(bytes(_symbol).length < 16, "symbol more than 16 characters");
        require(s.objectTokenSymbol[_objectId] == LibAdmin._getEmptyId(), "object already tokenized");

        s.objectTokenSymbol[_objectId] = LibHelpers._stringToBytes32(_symbol);
    }
}