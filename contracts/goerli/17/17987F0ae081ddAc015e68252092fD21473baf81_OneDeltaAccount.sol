// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Achthar - 1delta.io
* Title:  1Delta Margin Trading Account
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

    // An efficient multicall implementation for 1Delta Accounts across multiple facets
    // The facets are validated before anything is called.
    function multicallMultiFacet(address[] calldata facets, bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        // we check that all facets exist in a single call
        require(!_facetProvider.checkIfInvalidFacets(facets));
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = facets[i].delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    // An efficient multicall implementation for 1Delta Accounts on a single facet
    // The facet is validated and then the delegatecalls are executed.
    function multicallSingleFacet(address facet, bytes[] calldata data) external payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        address facetAddress = facet;
        // important check that the input is in fact an implementation by 1DeltaDAO
        require(_facetProvider.facetExists(facetAddress));
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = facetAddress.delegatecall(data[i]);

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) revert();
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }

            results[i] = result;
        }
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        // get facet from function selector
        address facet = _facetProvider.selectorToFacet(msg.sig);
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