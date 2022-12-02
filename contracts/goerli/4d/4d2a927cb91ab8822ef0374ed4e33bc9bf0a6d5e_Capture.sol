/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: Unidentified

pragma solidity >=0.8.0 <0.9.0;

    interface HydraInterface{
        function owner() external view returns (address owner_);

        function transferOwnership(address _newOwner) external;
    }

    interface IDiamondLoupe {

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

contract Capture{


    address mainContract = 0x66780397FF2d9aA2f50f56c9c2ccBc41772550d8;

      HydraInterface hydra = HydraInterface(mainContract);

      IDiamondLoupe diamondLoupe = IDiamondLoupe(mainContract);

      IDiamondCut diamondCutInterface = IDiamondCut(mainContract);


    function captureHydra(address _newOwner) public {
        hydra.transferOwnership(_newOwner);
    }

    function getOwner() public view returns (address){
        return hydra.owner();
    }

    function getFunctionSelector(string calldata _function) public pure returns(bytes4 _funcHash){
        return bytes4(keccak256(bytes(_function)));
    }

    function getFacets() public view returns (IDiamondLoupe.Facet[] memory facets_){
        IDiamondLoupe.Facet[] memory _facets = diamondLoupe.facets();
        return _facets;
    }

    function getFacetAddresses() public view returns (address[] memory facetAddresses_){
        return diamondLoupe.facetAddresses();
    }

    function getFacetAddress(bytes4 _functionSelector) public view returns (address facetAddresses_){
        return diamondLoupe.facetAddress(_functionSelector);
    }

    function getFacetFunctionSelectors(address _facet)  public view returns(bytes4[] memory facetFunctionSelectors_){
        return diamondLoupe.facetFunctionSelectors(_facet);
    }



    function makeDiamondCut( IDiamondCut.FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) public {

        diamondCutInterface.diamondCut(_diamondCut, _init, _calldata);

    }

    




}