// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDelegatedDiamond} from "./libraries/LibDelegatedDiamond.sol";
import {IFacetProvider} from "./interfaces/IFacetProvider.sol";

contract DelegatedDiamond {

    // provider is immutable and therefore stored in the bytecode
    IFacetProvider private immutable _facetProvider;

    function facetProvider() external view returns (IFacetProvider) {
        return _facetProvider;
    }

    // the constructor only initializes the facet provider
    // the facets are provided by views in this facet provider contract
    // the diamond cut facet is not existing in this contract, it is implemented in the provider
    constructor(address _diamondFacetProvider) {
        LibDelegatedDiamond.DelegatedDiamondStorage storage ds = LibDelegatedDiamond.diamondStorage();
         // we put the provider in the diamond storage
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

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

// THis diamond variant only
library LibDelegatedDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DelegatedDiamondStorage {
        address facetProvider;
        address factory;
    }

    function diamondStorage() internal pure returns (DelegatedDiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
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