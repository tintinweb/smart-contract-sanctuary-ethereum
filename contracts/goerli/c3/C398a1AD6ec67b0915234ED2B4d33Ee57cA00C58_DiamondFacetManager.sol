// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* A Management contract for a dimaond of which the facets are provided by an
* external contract.
/******************************************************************************/

import {IFacetProvider} from "./interfaces/IFacetProvider.sol";

// solhint-disable max-line-length

contract DiamondFacetManager is IFacetProvider {
    event DiamondUpgrade(IFacetProvider.FacetCut[] _diamondCut);
    // maps function selector to the facet address and
    // the position of the selector in the _facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) private _selectorToFacetAndPosition;
    // maps selector to facet
    mapping(bytes4 => address) public selectorToFacet;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) private _facetFunctionSelectors;
    // facet addresses
    address[] private _facetAddresses;
    // Used to query if a contract implements an interface.
    // Used to implement ERC-165.
    mapping(bytes4 => bool) public supportedInterfaces;
    // Used to query if a facet exits
    mapping(address => bool) private _facetExists;
    // owner of the contract
    address public contractOwner;

    function facetExists(address facetAddress) external view returns (bool) {
        return _facetExists[facetAddress];
    }

    function checkIfInvalidFacets(address[] memory facets) external view returns (bool isInvalid) {
        for (uint256 i; i < facets.length; ) {
            if (!_facetExists[facets[i]]) return true;
            unchecked {
                i++;
            }
        }
    }

    function selectorToFacetAndPosition(bytes4 selector) external view returns (FacetAddressAndPosition memory) {
        return _selectorToFacetAndPosition[selector];
    }

    function selectorsToFacets(bytes4[] memory selectors) external view returns (address[] memory facetAddressList) {
        for (uint256 i = 0; i < selectors.length; i++) {
            facetAddressList[i] = selectorToFacet[selectors[i]];
        }
    }

    function facetFunctionSelectors(address functionAddress) external view returns (FacetFunctionSelectors memory) {
        return _facetFunctionSelectors[functionAddress];
    }

    function facetAddresses() external view returns (address[] memory addresses) {
        addresses = _facetAddresses;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        contractOwner = msg.sender;
    }

    modifier enforceIsContractOwner() {
        require(msg.sender == contractOwner, "FacetManager: Must be contract owner");
        _;
    }

    function setContractOwner(address _newOwner) external enforceIsContractOwner {
        address previousOwner = contractOwner;
        contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    // External function version of diamondCut
    // It has no initializer as the diamond is not supposed to require storage that has to be initialized
    function diamondCut(IFacetProvider.FacetCut[] memory _diamondCut) external enforceIsContractOwner {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IFacetProvider.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IFacetProvider.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IFacetProvider.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IFacetProvider.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("DiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondUpgrade(_diamondCut);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        require(_facetAddress != address(0), "DiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "DiamondCut: Can't add function that already exists");
            addFunction(selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        require(_facetAddress != address(0), "DiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(_facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "DiamondCut: Can't replace function with same function");
            removeFunction(oldFacetAddress, selector);
            addFunction(selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) private {
        require(_functionSelectors.length > 0, "DiamondCut: No selectors in facet to cut");
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "DiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = _selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(oldFacetAddress, selector);
        }
    }

    function addFacet(address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "DiamondCut: New facet has no code");
        _facetFunctionSelectors[_facetAddress].facetAddressPosition = _facetAddresses.length;
        _facetAddresses.push(_facetAddress);
        _facetExists[_facetAddress] = true;
    }

    function addFunction(
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        _selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        _facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        _selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
        selectorToFacet[_selector] = _facetAddress;
    }

    function removeFunction(address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "DiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "DiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = _selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = _facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = _facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            _facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            _selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        _facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete _selectorToFacetAndPosition[_selector];
        delete selectorToFacet[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = _facetAddresses.length - 1;
            uint256 facetAddressPosition = _facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = _facetAddresses[lastFacetAddressPosition];
                _facetAddresses[facetAddressPosition] = lastFacetAddress;
                _facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            _facetAddresses.pop();
            delete _facetFunctionSelectors[_facetAddress].facetAddressPosition;
            _facetExists[_facetAddress] = false;
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

pragma solidity ^0.8.0;

interface IFacetProvider {
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

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    function selectorToFacetAndPosition(bytes4 selector) external view returns (FacetAddressAndPosition memory);

    function facetFunctionSelectors(address functionAddress) external view returns (FacetFunctionSelectors memory);

    function facetAddresses() external view returns (address[] memory);

    function supportedInterfaces(bytes4 _interface) external view returns (bool);

    function selectorToFacet(bytes4 selector) external view returns (address);

    function selectorsToFacets(bytes4[] memory selectors) external view returns (address[] memory facetAddressList);

    function facetExists(address facetAddress) external view returns (bool);

    function checkIfInvalidFacets(address[] memory facets) external view returns (bool);
}