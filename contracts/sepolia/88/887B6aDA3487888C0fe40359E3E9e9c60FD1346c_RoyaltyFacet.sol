// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { Ownable } from "../libraries/LibDiamond.sol";
import { IERC2981 } from "../interfaces/IERC2981.sol";
import { LibRoyalties, RoyaltyInfo, RoyaltyDataLayout } from "../libraries/LibRoyalties.sol";

// solhint-disable reason-string
contract RoyaltyFacet is IERC2981, Ownable {
  /**
   * @dev Sets the royalty information that all ids in this contract will default to.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function setGlobalRoyalties(address receiver, uint96 feeNumerator) external onlyOwner {
    LibRoyalties.setGlobalRoyalties(receiver, feeNumerator);
  }

  /**
   * @dev Removes default royalty information.
   */
  function resetGlobalRoyalties() external onlyOwner {
    LibRoyalties.resetGlobalRoyalties();
  }

  /**
   * @dev Sets the royalty information for a specific token id, overriding the global default.
   *
   * Requirements:
   *
   * - `receiver` cannot be the zero address.
   * - `feeNumerator` cannot be greater than the fee denominator.
   */
  function setRoyaltiesForToken(uint256 tokenId, address receiver, uint96 feeNumerator) external onlyOwner {
    LibRoyalties.setRoyaltiesForToken(tokenId, receiver, feeNumerator);
  }

  /**
   * @dev Resets royalty information for the token id back to the global default.
   */
  function resetRoyaltiesForToken(uint256 tokenId) external onlyOwner {
    LibRoyalties.resetRoyaltiesForToken(tokenId);
  }

  function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view returns (address, uint256) {
    RoyaltyDataLayout storage royaltyData = LibRoyalties.getLayerStorage();
    RoyaltyInfo memory royalty = royaltyData.tokenRoyaltyInfo[_tokenId];

    if (royalty.receiver == address(0)) {
      royalty = royaltyData.defaultRoyaltyInfo;
    }

    uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / LibRoyalties._feeDenominator();

    return (royalty.receiver, royaltyAmount);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
  function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external;

  event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

/**
 *
 * @dev Interface for the NFT Royalty Standard.
 *
 */

interface IERC2981 {
  function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard
// solhint-disable reason-string, no-inline-assembly, avoid-low-level-calls

error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

library LibDiamond {
  bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

  struct FacetAddressAndPosition {
    address facetAddress;
    uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
  }

  struct FacetFunctionSelectors {
    bytes4[] functionSelectors;
    uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
  }

  struct DiamondStorage {
    // maps function selector to the facet address and
    // the position of the selector in the facetFunctionSelectors.selectors array
    mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
    // maps facet addresses to function selectors
    mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
    // facet addresses
    address[] facetAddresses;
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

  event DiamondCutEvent(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

  // Internal function version of diamondCut
  function diamondCut(IDiamondCut.FacetCut[] memory _diamondCut, address _init, bytes memory _calldata) internal {
    for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
      IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
      if (action == IDiamondCut.FacetCutAction.Add) {
        addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Replace) {
        replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else if (action == IDiamondCut.FacetCutAction.Remove) {
        removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
      } else {
        revert("LibDiamondCut: Incorrect FacetCutAction");
      }
    }
    emit DiamondCutEvent(_diamondCut, _init, _calldata);
    initializeDiamondCut(_init, _calldata);
  }

  function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
  }

  function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
    uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
    // add new facet address if it does not exist
    if (selectorPosition == 0) {
      addFacet(ds, _facetAddress);
    }
    address oldFacet;
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
      // replace function if it exists, else add new function
      if (oldFacetAddress != address(0)) {
        // cache old address for future clean up
        oldFacet = oldFacetAddress;
        removeFunction(ds, oldFacetAddress, selector);
      }
      addFunction(ds, selector, selectorPosition, _facetAddress);
      selectorPosition++;
    }
    // clean up non existing functions
    if (ds.facetFunctionSelectors[oldFacet].functionSelectors.length > 0) {
      for (uint256 sId = 0; sId < ds.facetFunctionSelectors[oldFacet].functionSelectors.length; sId++) {
        removeFunction(ds, oldFacet, ds.facetFunctionSelectors[oldFacet].functionSelectors[sId]);
      }
    }
  }

  function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
    require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
    DiamondStorage storage ds = diamondStorage();
    // if function does not exist then do nothing and return
    require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
    for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
      bytes4 selector = _functionSelectors[selectorIndex];
      address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
      removeFunction(ds, oldFacetAddress, selector);
    }
  }

  function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
    enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
    ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
    ds.facetAddresses.push(_facetAddress);
  }

  function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
    ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
    ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
  }

  function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
    require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
    // an immutable function is a function defined directly in a diamond
    require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
    // replace selector with last selector, then delete last selector
    uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
    uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
    // if not the same then replace _selector with lastSelector
    if (selectorPosition != lastSelectorPosition) {
      bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
      ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
      ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
    }
    // delete the last selector
    ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
    delete ds.selectorToFacetAndPosition[_selector];

    // if no more selectors for facet address then delete the facet address
    if (lastSelectorPosition == 0) {
      // replace facet address with last facet address and delete last facet address
      uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
      uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
      if (facetAddressPosition != lastFacetAddressPosition) {
        address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
        ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
        ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
      }
      ds.facetAddresses.pop();
      delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
    }
  }

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

  function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
    uint256 contractSize;
    assembly {
      contractSize := extcodesize(_contract)
    }
    require(contractSize > 0, _errorMessage);
  }
}

contract Ownable {
  modifier onlyOwner() {
    LibDiamond.enforceIsContractOwner();
    _;
  }

  function getContractOwner() internal view returns (address) {
    return LibDiamond.contractOwner();
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

struct RoyaltyInfo {
  address receiver;
  uint96 royaltyFraction;
}

struct RoyaltyDataLayout {
  RoyaltyInfo defaultRoyaltyInfo;
  mapping(uint256 => RoyaltyInfo) tokenRoyaltyInfo;
}

// solhint-disable no-inline-assembly, reason-string
library LibRoyalties {
  bytes32 internal constant ROYALTY_DATA_SLOT = keccak256("erc2981.royalty.info.data");

  function getLayerStorage() internal pure returns (RoyaltyDataLayout storage strg) {
    bytes32 slot = ROYALTY_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function setGlobalRoyalties(address receiver, uint96 feeNumerator) internal {
    require(feeNumerator <= _feeDenominator(), "LibRoyalties: royalty fee will exceed salePrice");
    require(receiver != address(0), "LibRoyalties: invalid receiver");

    getLayerStorage().defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
  }

  function setRoyaltiesForToken(uint256 tokenId, address receiver, uint96 feeNumerator) internal {
    require(feeNumerator <= _feeDenominator(), "LibRoyalties: royalty fee will exceed salePrice");
    require(receiver != address(0), "LibRoyalties: Invalid parameters");

    getLayerStorage().tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
  }

  function resetRoyaltiesForToken(uint256 tokenId) internal {
    delete getLayerStorage().tokenRoyaltyInfo[tokenId];
  }

  function resetGlobalRoyalties() internal {
    delete getLayerStorage().defaultRoyaltyInfo;
  }

  /**
   * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
   * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
   * override.
   */
  function _feeDenominator() internal pure returns (uint96) {
    return 10000;
  }
}