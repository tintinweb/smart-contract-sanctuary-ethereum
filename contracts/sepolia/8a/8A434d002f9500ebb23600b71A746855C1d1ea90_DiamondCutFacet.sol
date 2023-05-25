// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamondCut} from "src/interfaces/diamond-core/IDiamondCut.sol";
import {LibDiamond} from "src/libraries/diamond-core/LibDiamond.sol";

/**
 * @title DiamondCutFacet
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required function selector modification to support EIP-2535
 */
contract DiamondCutFacet is IDiamondCut {
    /**
     * @notice Add/replace/remove any number of functions and optionally execute a function with delegatecall
     *
     * @dev    Throws if adding a function selector that is already assigned
     * @dev    Throws if adding or replacing and facet has no code
     * @dev    Throws if replacing with facet at address(0)
     * @dev    Throws if replacing function with same function from same facet
     * @dev    Throws if replacing or removing function that doesn't exist
     * @dev    Throws if replacing or removing an immutable facet
     * @dev    Throws if removing function and facet address is not address(0)
     * @dev    Throws if initialization contract provided does not contain code
     * @dev    Throws if initialization data is invalid
     * @dev    Throws if caller is not the contract owner
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. A `DiamondCut` event has been emitted
     * @dev    2. The provided selectors have been added, replaced or removed from the diamond
     * @dev    3. The initialization function has been called
     *
     * @param _diamondCut Contains the facet addresses and function selectors
     * @param _init The address of the contract or facet to execute _calldata
     * @param _calldata A function call, including function selector and arguments
     */
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override {
        LibDiamond.requireContractOwner();
        LibDiamond.diamondCut(_diamondCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDiamond {
    enum FacetCutAction {
        Add,     // 0
        Replace, // 1
        Remove   // 2
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    struct DiamondArgs {
        address owner;
        address init;
        bytes initCalldata;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamond} from "./IDiamond.sol";

/**
 * @title DiamondCutFacet
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Required function selector modification to support EIP-2535
 */
interface IDiamondCut is IDiamond {
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDiamond} from "src/interfaces/diamond-core/IDiamond.sol";

error NoSelectorsGivenToAdd();
error NotContractOwner(address _user, address _contractOwner);
error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceImmutableFunction(bytes4 _selector);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

/**
 * @title LibDiamond
 * @author Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * @notice Library of Diamond Functions
 */
library LibDiamond {

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
    }

    /// @dev Standard storage slot for the shared diamond storage
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /// @notice Emitted when Ownership of the diamond is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when a DiamondCut takes place
    event DiamondCut(IDiamond.FacetCut[] _diamondCut, address _init, bytes _calldata);


    /// @dev Returns data stored at the `DIAMOND_STORAGE_POSITION`
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Transfers ownership of the diamond to the provided owner
     *
     * @dev    Throws if caller is not the current owner
     *
     * @dev    <h4>Postconditions</h4>
     * @dev    1. The provided address is the new owner
     * @dev    2. The previous owner is no longer the owner
     *
     * @param  _newOwner address of the new owner
     */
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @dev Returns the contract owner of the Diamond
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /// @dev Internal function version of diamondCut
    function diamondCut(IDiamond.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamond.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    /**
     * @dev Associates a facet address with an array of function selectors
     *
     * @dev Throws if the facet address is address(0)
     * @dev Throws if the facet address does not contain code
     * @dev Throws if the function selector is already assigned a facet
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The facet address is associated with the list of function selectors
     */
    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    /**
     * @dev Replaces an array of function selectors with a new facet address
     *
     * @dev Throws if the provided facet address is the zero address
     * @dev Throws if the provided facet address does not contain code
     * @dev Throws if trying to replace an immutable function selector
     * @dev Throws if trying to replace with the same facet address and function selector
     * @dev Throws if any function selector in the `_functionSelectors` array does not exist
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The list of function selectors are replaced with the new facet address
     */
    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if (oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if (oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    /**
     * @dev Removes functions from the Diamond
     *
     * @dev Throws if the provided facet address is not address(0)
     * @dev Throws if any function in the `_functionSelectors` does not exist
     * @dev Throws if any function in the `_functionSelectors` array is immutable
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The provided array of function selectors have been removed from the Diamond
     */
    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition =
                ds.facetAddressAndSelectorPosition[selector];
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }

            // can't remove immutable functions -- functions defined directly in the diamond
            if (oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition =
                    oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    /**
     * @dev Calls the initialization address with the provide abi encoded calldata
     *
     * @dev Throws if invalid calldata is provided
     *
     * @dev <h4>Postconditions</h4>
     * @dev 1. The initialization address has performed any updates in the provided calldata
     */
    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    /// @dev Enforces the msg.sender is the contract owner, reverts if not
    function requireContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    /// @dev Enforces the provided address has code, reverts if not 
    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}