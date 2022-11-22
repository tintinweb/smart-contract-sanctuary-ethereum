// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* Title:  1Delta margin Trading Account
* Implementation of a diamond that fetches its facets from another contract.
/******************************************************************************/

import {GeneralStorage, LibGeneral} from "./libraries/LibGeneral.sol";
import {IFacetProvider} from "./interfaces/IFacetProvider.sol";

contract OneDeltaAccount {

    // provider is immutable and therefore stored in the bytecode
    IFacetProvider private immutable _facetProvider;

    function facetProvider() external view returns (IFacetProvider) {
        return _facetProvider;
    }

    // the constructor only initializes the facet provider
    // the facets are provided by views in this facet provider contract
    // the diamond cut facet is not existing in this contract, it is implemented in the provider
    constructor(address _diamondFacetProvider) {
        GeneralStorage storage ds = LibGeneral.generalStorage();
         // we put the provider in the diamond storage, too
        ds.facetProvider = _diamondFacetProvider;
        ds.factory = msg.sender;

        // assign immutable
        _facetProvider = IFacetProvider(_diamondFacetProvider);
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        // get facet from function selector
        address facet = _facetProvider.selectorToFacetAndPosition(msg.sig).facetAddress;
        require(facet != address(0), "OneDeltaAccount: Function does not exist");
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

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

struct GeneralStorage {
    address factory;
    address facetProvider;
}

library LibGeneral {
    bytes32 constant GENERAL_STORAGE = keccak256("1DeltaAccount.storage.general");

    function generalStorage() internal pure returns (GeneralStorage storage gs) {
        bytes32 position = GENERAL_STORAGE;
        assembly {
            gs.slot := position
        }
    }
}

abstract contract WithGeneralStorage {
    function gs() internal pure returns (GeneralStorage storage) {
        return LibGeneral.generalStorage();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFacetProvider {
    enum FacetCutAction {Add, Replace, Remove}
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
}