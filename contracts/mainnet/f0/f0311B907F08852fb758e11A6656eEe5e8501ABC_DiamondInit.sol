/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: MIT

// Part: IDiamondLoupe

interface IDiamondLoupe {
    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

  
  function facets() external view returns (Facet[] memory facets_);

    function facetFunctionSelectors(address _facet)
        external
        view
        returns (bytes4[] memory facetFunctionSelectors_);

    function facetAddresses()
        external
        view
        returns (address[] memory facetAddresses_);

    function facetAddress(bytes4 _functionSelector)
        external
        view
        returns (address facetAddress_);
}

// Part: IERC165

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// Part: IERC173

interface IERC173 {
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function owner() external view returns (address owner_);

    function transferOwnership(address _newOwner) external;
}


// Part: IERC20

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



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

    function diamondStorage()
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
                address oldFacetAddress = address(bytes20(oldFacet));
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
                if 
(oldSelectorsSlotCount != selectorSlotCount) {
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
            if (_init != address(this)) {
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

// File: DiamondInit.sol

contract DiamondInit {
    function init() external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;
        ds.supportedInterfaces[type(IERC20).interfaceId] = true;
    }
}