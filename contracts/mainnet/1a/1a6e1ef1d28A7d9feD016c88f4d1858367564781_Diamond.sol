//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./libraries/LibStorage.sol";
import "./interfaces/IDiamondCutter.sol";

contract Diamond {

    constructor(address _diamondCutterFacet) {
        // set ownership to deployer
        LibStorage.DiamondStorage storage ds = LibStorage.diamond();
        ds.contractOwner = msg.sender;

        // Add the diamondCut function to the deployed diamondCutter
        bytes4 cutterSelector = IDiamondCutter.diamondCut.selector;
        ds.selectors.push(cutterSelector);
        ds.facets[cutterSelector] = LibStorage.Facet({
            facetAddress: _diamondCutterFacet,
            selectorPosition: 0
        });
    }

    // Search address associated with the selector and delegate execution
    fallback() external payable {
        LibStorage.DiamondStorage storage ds;
        bytes32 position = LibStorage.DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.facets[msg.sig].facetAddress;
        require(facet != address(0), "Signature not found");
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
            case 0 {revert(0, returndatasize())}
            default {return (0, returndatasize())}
        }
    }

    receive() external payable {}

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("xyz.swidge.storage.diamond");
    bytes32 constant PROVIDERS_STORAGE_POSITION = keccak256("xyz.swidge.storage.app");

    struct DiamondStorage {
        mapping(bytes4 => Facet) facets;
        bytes4[] selectors;
        address contractOwner;
        address relayerAddress;
    }

    struct ProviderStorage {
        mapping(uint8 => Provider) bridgeProviders;
        mapping(uint8 => Provider) swapProviders;
        uint16 totalBridges;
        uint16 totalSwappers;
    }

    struct Facet {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct Provider {
        uint8 code;
        bool enabled;
        address implementation;
        address handler;
    }

    function diamond() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function providers() internal pure returns (ProviderStorage storage ps) {
        bytes32 position = PROVIDERS_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamond().contractOwner, "Must be contract owner");
    }

    function enforceIsRelayer() internal view {
        require(msg.sender == diamond().relayerAddress, "Must be relayer");
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

/*************************************************************\
Forked from https://github.com/mudgen/diamond
/*************************************************************/

interface IDiamondCutter {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        FacetCutAction action;
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions
    /// @param _diamondCut Contains the facet addresses and function selectors
    function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;
}