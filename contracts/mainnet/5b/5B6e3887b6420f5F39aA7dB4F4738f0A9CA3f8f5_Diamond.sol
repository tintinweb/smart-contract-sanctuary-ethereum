/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

// Part: IDiamondCut

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// Part: LibDiamond

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION =
 
       keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        mapping(bytes4 => bytes32) facets;
        mapping(uint256 => bytes32) selectorSlots;
        uint16 selectorCount;
        mapping(bytes4 => bool) supportedInterfaces;
        address contractOwner;
        mapping(address => bool) isOwner;
    }

    function 
diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
       
     ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            msg.sender == diamondStorage().contractOwner,
            "Must be contract owner"
        );
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    bytes32 constant CLEAR_ADDRESS_MASK =
        bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        if (selectorCount & 7 > 0) {
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (
            uint256 facetIndex;
       
     facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            (selectorCount, selectorSlot) = addReplaceRemoveFacetSelectors(
                selectorCount,
                selectorSlot,
                _diamondCut[facetIndex].facetAddress,
                _diamondCut[facetIndex].action,
                _diamondCut[facetIndex].functionSelectors
            );
        }
        if (selectorCount != originalSelectorCount) {
            ds.selectorCount = uint16(selectorCount);
        }
        if (selectorCount & 7 > 0) {
            ds.selectorSlots[selectorCount >> 3] = selectorSlot;
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addReplaceRemoveFacetSelectors(
        uint256 _selectorCount,
        bytes32 _selectorSlot,
        address _newFacetAddress,
        IDiamondCut.FacetCutAction _action,
        bytes4[] memory _selectors
    ) internal returns (uint256, bytes32) {
        DiamondStorage storage ds = diamondStorage();
        require(_selectors.length > 0, "No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "Add facet has no code");
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
  
              bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(
                    address(bytes20(oldFacet)) == address(0),
                    "Can't add function that already exists"
                );
                ds.facets[selector] =
                    bytes20(_newFacetAddress) |
                    bytes32(_selectorCount);
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                _selectorSlot =

     (_selectorSlot &
                        ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) |
                    (bytes32(selector) >> selectorInSlotPosition);

 if (selectorInSlotPosition == 224) {
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }

       _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(
                _newFacetAddress,
 
               "Replace facet has no code"
            );
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;

      selectorIndex++
            ) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address 
oldFacetAddress = address(bytes20(oldFacet));
                require(
                    oldFacetAddress != address(this),
                    "Can't replace immutable function"
                );
                require(
                    oldFacetAddress != _newFacetAddress,
                    "Can't replace function with same function"

       );
                require(
                    oldFacetAddress != address(0),
                    "Can't replace function that doesn't exist"
                );
       
         ds.facets[selector] =
                    (oldFacet & CLEAR_ADDRESS_MASK) |
                    bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(
                _newFacetAddress == address(0),
                "Remove facet address must be address(0)"
            );
            uint256 selectorSlotCount = _selectorCount >> 3;
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (
                uint256 selectorIndex;
                selectorIndex < _selectors.length;
                selectorIndex++
            ) {
                if (_selectorSlot == 0) {
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;

  {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(

   address(bytes20(oldFacet)) != address(0),
                        "Can't remove function that doesn't exist"
                    );
                    require(

           address(bytes20(oldFacet)) != address(this),
                        "Can't remove immutable function"
                    );
                    lastSelector = bytes4(
                        _selectorSlot << (selectorInSlotIndex << 5)
                    );
                    if (lastSelector != selector) {
                        ds.facets[lastSelector] =
                            (oldFacet & CLEAR_ADDRESS_MASK) |
                            bytes20(ds.facets[lastSelector]);
                    }

   delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
        
            oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[
                        oldSelectorsSlotCount
                    ];
                    oldSelectorSlot =
                        (oldSelectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    _selectorSlot =

      (_selectorSlot &
                            ~(CLEAR_SELECTOR_MASK >>
                                oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];

       _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata)
        internal
    {
        if (_init == address(0)) {
            require(
                _calldata.length == 0,
                "_init is address(0) but_calldata is not empty"

 );
        } else {
            require(
                _calldata.length > 0,
                "_calldata is empty but _init is not address(0)"
            );
            if 
(_init != address(this)) {
                enforceHasContractCode(_init, "_init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    revert(string(error));
                } else {
                    revert("_init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(
        address _contract,
        string memory _errorMessage
    ) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// File: Diamond.sol

contract Diamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibDiamond.setContractOwner(_contractOwner);
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
      
      functionSelectors: functionSelectors
        });
        LibDiamond.diamondCut(cut, address(0), "");
    }

    fallback() external payable {
        LibDiamond.DiamondStorage storage ds;
        bytes32 position = LibDiamond.DIAMOND_STORAGE_POSITION;

        assembly {
            ds.slot := position
        }
        address facet = address(bytes20(ds.facets[msg.sig]));
        require(facet != address(0), "Diamond: Function does not exist");

        assembly {
            calldatacopy(0, 0, calldatasize())
     
       let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
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