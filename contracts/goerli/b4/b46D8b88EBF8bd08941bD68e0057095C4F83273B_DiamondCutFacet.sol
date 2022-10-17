// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibOwnership} from "../libraries/LibOwnership.sol";

contract DiamondCutFacet is IDiamondCut {
    /// @notice Add/replace/remove any number of functions and optionally 
    /// execute a function with delegatecall
    /// @param _facetCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    /// _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _facetCut,
        address _init,
        bytes calldata _calldata
    ) external override {
        LibOwnership._enforceIsContractOwner();
        LibDiamond._diamondCut(_facetCut, _init, _calldata);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import {LibDiamondStorage} from "./LibDiamondStorage.sol";

error NoSelectorsProvidedForFacetForCut(address _facetAddress);
error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
error NoBytecodeAtAddress(address _contractAddress, string _message);
error IncorrectFacetCutAction(uint8 _action);
error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
    bytes4 _selector
);
error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
error CannotRemoveImmutableFunction(bytes4 _selector);
error InitializationFunctionReverted(
    address _initializationContractAddress,
    bytes _calldata
);
error ZeroInitAddressNonEmptyCalldata(
    address _initializationContractAddress,
    bytes _calldata
);
error EmptyCalldataNonZeroInitAddress(
    address _initializationContractAddress,
    bytes _calldata
);

library LibDiamond {
    event DiamondCut(
        IDiamondCut.FacetCut[] _facetCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function _diamondCut(
        IDiamondCut.FacetCut[] memory _facetCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _facetCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _facetCut[facetIndex]
                .functionSelectors;
            address facetAddress = _facetCut[facetIndex].facetAddress;
            if (functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _facetCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                _addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                _replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                _removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_facetCut, _init, _calldata);
        _initializeDiamondCut(_init, _calldata);
    }

    function _addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        }
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    // Replacing a function means removing a function and adding a new function
    // from a different facet but with the same function signature as the one
    // removed. In other words, replacing a function in a diamond just means
    // changing the facet address where it comes from.
    function _replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        }
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        if (_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(
                _functionSelectors
            );
        }
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            _addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(
                    selector
                );
            }
            _removeFunction(ds, oldFacetAddress, selector);
            _addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function _removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length == 0) {
            revert NoSelectorsProvidedForFacetForCut(_facetAddress);
        }
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            _removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function _addFacet(
        LibDiamondStorage.DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        _enforceHasContractCode(
            _facetAddress,
            "LibDiamondCut: New facet has no code"
        );
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function _addFunction(
        LibDiamondStorage.DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function _removeFunction(
        LibDiamondStorage.DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) {
            revert CannotRemoveFunctionThatDoesNotExist(_selector);
        }
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) {
            revert CannotRemoveImmutableFunction(_selector);
        }
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                    selectorPosition
                ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function _initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            if (_calldata.length > 0) {
                revert ZeroInitAddressNonEmptyCalldata(_init, _calldata);
            }
        } else {
            if (_calldata.length == 0) {
                revert EmptyCalldataNonZeroInitAddress(_init, _calldata);
            }
            if (_init != address(this)) {
                _enforceHasContractCode(
                    _init,
                    "LibDiamondCut: _init address has no code"
                );
            }
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
    }

    function _enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

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

    // Duplication of event defined in `LibDiamond.sol` as events emitted out of
    // library functions are not reflected in the contract ABI. Read more about it here:
    // https://web.archive.org/web/20180922101404/https://blog.aragon.org/library-driven-development-in-solidity-2bebcaf88736/
    event DiamondCut(
        FacetCut[] _facetCut,
        address _init,
        bytes _calldata
    );

    /// @notice Add/replace/remove any number of functions and optionally
    ///         execute a function with delegatecall
    /// @param _facetCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _facetCut,
        address _init,
        bytes calldata _calldata
    ) external;

}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

import {LibDiamondStorage} from "./LibDiamondStorage.sol";

// Thrown if `msg.sender` is not contract owner
error NotContractOwner(address _user, address _contractOwner);

library LibOwnership {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function _setContractOwner(address _newOwner) internal {
        LibDiamondStorage.DiamondStorage storage ds = LibDiamondStorage
            ._diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function _contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = LibDiamondStorage._diamondStorage().contractOwner;
    }

    function _enforceIsContractOwner() internal view {
        if (msg.sender != LibDiamondStorage._diamondStorage().contractOwner)
            revert NotContractOwner(
                msg.sender,
                LibDiamondStorage._diamondStorage().contractOwner
            );
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.6;

library LibDiamondStorage {
    // The hash for diamond storage position, which is:
    // keccak256("diamond.standard.diamond.storage")
    bytes32 constant DIAMOND_STORAGE_POSITION =
        0xc8fcad8db84d3cc18b4c41d551ea0ee66dd599cde068d998e57d5e09332c131c;

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // Maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // Maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // Facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // Owner of the contract
        address contractOwner;
    }

    function _diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}