// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: Halfstep Labs Inc.

import {Partner, Modifiers} from "../libraries/AppStorage.sol";
import {LibPartners} from "../libraries/LibPartners.sol";

contract PartnersFacet is Modifiers {
    /// @notice Adds a partner to the Pleb Network
    /// @param _name the name of the partner we are adding
    /// @param _uri the unique resource identifier that corresponds to that partner specific metadata
    /// @param _tokenLimit the number of tokens that consumers can mint through that partner
    function addPartner(
        string calldata _name,
        string calldata _uri,
        uint128 _tokenLimit
    ) external onlyOwner {
        Partner memory newPartner = Partner({
            name: _name,
            uri: _uri,
            tokenLimit: _tokenLimit,
            tokensMinted: 0,
            valid: true
        });

        s.currentNumPartners++;
        s.partnersAdded++;

        s.partners[s.partnersAdded] = newPartner;
    }

    /// @notice Allows for removing partners, if a partner chooses to leave the network
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// - partner must be valid
    /// @param _partnerId the partner that we want to remove from the network
    function removePartner(uint128 _partnerId) external onlyOwner {
        require(
            isPartnerValid(_partnerId),
            "Partner has already been removed"
        );

        s.currentNumPartners--;

        delete s.partners[_partnerId].valid;
    }

    /// @notice Allows for increasing the number of tokens that can be minted through a specific partner.
    /// This would only be used if a partner's growth demanded an increase in tokens for their community.
    /// @dev Will throw if the partner is not valid
    /// @param _partnerId the ID of the partner
    /// @param _poolAddition the number of tokens that would be added to the partners existing token count
    function increasePartnerTokenPool(uint128 _partnerId, uint128 _poolAddition)
        external
        onlyOwner
    {
        require(
            isPartnerValid(_partnerId),
            "Partner has been removed"
        );
        s.partners[_partnerId].tokenLimit =
            _poolAddition +
            s.partners[_partnerId].tokenLimit;
    }

    /// @notice Allows for changing a partner's URI
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// - partner must be valid
    /// @param _partnerId the ID of the partner
    /// @param _uri the new URI being set
    function changePartnersURI(uint128 _partnerId, string memory _uri)
        external
        onlyOwner
    {
        require(
            isPartnerValid(_partnerId),
            "Partner has been removed"
        );
        s.partners[_partnerId].uri = _uri;
    }

    /// @notice Returns whether a partner is an active member of the Pleb network
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return whether the partner is valid
    function isPartnerValid(uint128 _partnerId) internal view returns (bool) {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId].valid;
    }

    /// @notice Returns the number of partners in the Pleb Network
    function getNumPartners() external view returns (uint256) {
        return s.currentNumPartners;
    }

    /// @notice Returns the number of tokens minted for a given partner
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return the number of tokens minted through the partner
    function getPartnerTokensMinted(uint128 _partnerId)
        external
        view
        returns (uint128)
    {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId].tokensMinted;
    }

    /// @notice Returns the number of tokens allotted to a given partner
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return the number of tokens alloted to the partner
    function getPartnerTokenLimit(uint128 _partnerId)
        external
        view
        returns (uint128)
    {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId].tokenLimit;
    }

    /// @notice Returns the name of a given partner
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return the name of the partner
    function getPartnerName(uint128 _partnerId)
        external
        view
        returns (string memory)
    {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId].name;
    }

    /// @notice Returns the URI of a given partner
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return the URI of the partner
    function getPartnerURI(uint128 _partnerId)
        external
        view
        returns (string memory)
    {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId].uri;
    }

    /// @notice Returns a given partner struct
    /// @dev Requirements:
    /// - '_partnerId' must exist
    /// @param _partnerId the ID of the partner
    /// @return the partner struct
    function getPartner(uint128 _partnerId)
        external
        view
        returns (Partner memory)
    {
        require(
            LibPartners.partnerExists(_partnerId),
            "Partner does not exist"
        );
        return s.partners[_partnerId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";

// Mint price is USD as an integer with 8 digits of precision
uint256 constant PRICE_USD = 15000000000;
// Maximum number of mints per transaction
uint256 constant MAX_MINT_PER_TX = 5;

struct AddressStats {
    // Current token balance at the address
    uint128 balance;
    // Total number of tokens minted at the address
    uint128 totalMints;
}

struct TokenStats {
    // ID of the partner the token is currently set to
    uint128 partnerId;
    // Address of the token owner
    address owner;
}

struct Staked {
    // Start time the token began being staked
    uint128 startTimeStamp;
    // Address of the token owner
    address owner;
}

struct Partner {
    // Number of tokens that have been minted through the partner
    uint128 tokensMinted;
    // Number of tokens that can be minted through the partner
    uint128 tokenLimit;
    // URI associated with the partner
    string uri;
    // Partner name
    string name;
    // Whether the partner is currently part of the Pleb network
    bool valid;
}

struct AppStorage {
    // Token name
    string name;
    // Token symbol
    string symbol;
    // Metadata URI extension
    string baseExtension;
    // The tokenId of the next token to be minted
    uint256 currentTokenCount;
    // Total supply of Keg Pleb tokens minted
    uint256 kpTokenCount;
    // Current mint price
    uint256 mintPrice;
        // Last time the price was saved
    uint256 priceTimestamp;
    // Mapping from token ID to staking details
    mapping(uint256 => Staked) stakedTokens;
    // Mapping from token ID to token details
    mapping(uint256 => TokenStats) tokenStats;
    // Mapping from token ID to address details
    mapping(address => AddressStats) addressStats;
    // Mapping from nonce to address used
    mapping(uint256 => address) usedNonces;
    // Mapping from token ID to approved address
    mapping(uint256 => address) tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) operatorApprovals;
    // Mapping from partner ID to partner details
    mapping(uint256 => Partner) partners;
    // Mapping from token ID to claim status
    mapping(uint256 => bool) claimedTokens;
    // Number of partners added ever
    uint128 partnersAdded;
    // Number of partners that are currently valid
    uint128 currentNumPartners;
    // Duration for the token staking period
    uint128 stakeDuration;
    // Frequency the price will be updated
    uint128 priceFrequency;
    // Address of the Keg Plebs contract
    address kpContract;
    // Address of the validator account
    address validator;
    // Whether staking is currently allowed
    bool stakingAllowed;
    // Whether the minting is active
    bool isActive;
    // Whether the Diamond contract has been initialized
    bool initialized;
}

library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {
    AppStorage internal s;

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AppStorage, LibAppStorage} from "./AppStorage.sol";

// Author: Halfstep Labs Inc.

library LibPartners {

    /// @notice Returns whether a given partner exists
    /// @param _partnerId the ID of the partner
    /// @return whether the partner exists
    function partnerExists(uint128 _partnerId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return _partnerId < s.partnersAdded + 1;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct DiamondStorage {
        // maps function selectors to the facets that execute the functions.
        // and maps the selectors to their position in the selectorSlots array.
        // func selector => address facet, selector position
        mapping(bytes4 => bytes32) facets;
        // array of slots of function selectors.
        // each slot holds 8 function selectors.
        mapping(uint256 => bytes32) selectorSlots;
        // The number of function selectors in selectorSlots
        uint16 selectorCount;
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

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    bytes32 constant CLEAR_ADDRESS_MASK = bytes32(uint256(0xffffffffffffffffffffffff));
    bytes32 constant CLEAR_SELECTOR_MASK = bytes32(uint256(0xffffffff << 224));

    // Internal function version of diamondCut
    // This code is almost the same as the external diamondCut,
    // except it is using 'Facet[] memory _diamondCut' instead of
    // 'Facet[] calldata _diamondCut'.
    // The code is duplicated to prevent copying calldata to memory which
    // causes an error for a two dimensional array.
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 originalSelectorCount = ds.selectorCount;
        uint256 selectorCount = originalSelectorCount;
        bytes32 selectorSlot;
        // Check if last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // get last selectorSlot
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
            selectorSlot = ds.selectorSlots[selectorCount >> 3];
        }
        // loop through diamond cut
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
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
        // If last selector slot is not full
        // "selectorCount & 7" is a gas efficient modulo by eight "selectorCount % 8" 
        if (selectorCount & 7 > 0) {
            // "selectorSlot >> 3" is a gas efficient division by 8 "selectorSlot / 8"
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
        require(_selectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        if (_action == IDiamondCut.FacetCutAction.Add) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Add facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                require(address(bytes20(oldFacet)) == address(0), "LibDiamondCut: Can't add function that already exists");
                // add facet for selector
                ds.facets[selector] = bytes20(_newFacetAddress) | bytes32(_selectorCount);
                // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
                uint256 selectorInSlotPosition = (_selectorCount & 7) << 5;
                // clear selector position in slot and add selector
                _selectorSlot = (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> selectorInSlotPosition)) | (bytes32(selector) >> selectorInSlotPosition);
                // if slot is full then write it to storage
                if (selectorInSlotPosition == 224) {
                    // "_selectorSlot >> 3" is a gas efficient division by 8 "_selectorSlot / 8"
                    ds.selectorSlots[_selectorCount >> 3] = _selectorSlot;
                    _selectorSlot = 0;
                }
                _selectorCount++;
            }
        } else if (_action == IDiamondCut.FacetCutAction.Replace) {
            enforceHasContractCode(_newFacetAddress, "LibDiamondCut: Replace facet has no code");
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                bytes4 selector = _selectors[selectorIndex];
                bytes32 oldFacet = ds.facets[selector];
                address oldFacetAddress = address(bytes20(oldFacet));
                // only useful if immutable functions exist
                require(oldFacetAddress != address(this), "LibDiamondCut: Can't replace immutable function");
                require(oldFacetAddress != _newFacetAddress, "LibDiamondCut: Can't replace function with same function");
                require(oldFacetAddress != address(0), "LibDiamondCut: Can't replace function that doesn't exist");
                // replace old facet address
                ds.facets[selector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(_newFacetAddress);
            }
        } else if (_action == IDiamondCut.FacetCutAction.Remove) {
            require(_newFacetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
            // "_selectorCount >> 3" is a gas efficient division by 8 "_selectorCount / 8"
            uint256 selectorSlotCount = _selectorCount >> 3;
            // "_selectorCount & 7" is a gas efficient modulo by eight "_selectorCount % 8" 
            uint256 selectorInSlotIndex = _selectorCount & 7;
            for (uint256 selectorIndex; selectorIndex < _selectors.length; selectorIndex++) {
                if (_selectorSlot == 0) {
                    // get last selectorSlot
                    selectorSlotCount--;
                    _selectorSlot = ds.selectorSlots[selectorSlotCount];
                    selectorInSlotIndex = 7;
                } else {
                    selectorInSlotIndex--;
                }
                bytes4 lastSelector;
                uint256 oldSelectorsSlotCount;
                uint256 oldSelectorInSlotPosition;
                // adding a block here prevents stack too deep error
                {
                    bytes4 selector = _selectors[selectorIndex];
                    bytes32 oldFacet = ds.facets[selector];
                    require(address(bytes20(oldFacet)) != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
                    // only useful if immutable functions exist
                    require(address(bytes20(oldFacet)) != address(this), "LibDiamondCut: Can't remove immutable function");
                    // replace selector with last selector in ds.facets
                    // gets the last selector
                    lastSelector = bytes4(_selectorSlot << (selectorInSlotIndex << 5));
                    if (lastSelector != selector) {
                        // update last selector slot position info
                        ds.facets[lastSelector] = (oldFacet & CLEAR_ADDRESS_MASK) | bytes20(ds.facets[lastSelector]);
                    }
                    delete ds.facets[selector];
                    uint256 oldSelectorCount = uint16(uint256(oldFacet));
                    // "oldSelectorCount >> 3" is a gas efficient division by 8 "oldSelectorCount / 8"
                    oldSelectorsSlotCount = oldSelectorCount >> 3;
                    // "oldSelectorCount & 7" is a gas efficient modulo by eight "oldSelectorCount % 8" 
                    oldSelectorInSlotPosition = (oldSelectorCount & 7) << 5;
                }
                if (oldSelectorsSlotCount != selectorSlotCount) {
                    bytes32 oldSelectorSlot = ds.selectorSlots[oldSelectorsSlotCount];
                    // clears the selector we are deleting and puts the last selector in its place.
                    oldSelectorSlot =
                        (oldSelectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                    // update storage with the modified slot
                    ds.selectorSlots[oldSelectorsSlotCount] = oldSelectorSlot;
                } else {
                    // clears the selector we are deleting and puts the last selector in its place.
                    _selectorSlot =
                        (_selectorSlot & ~(CLEAR_SELECTOR_MASK >> oldSelectorInSlotPosition)) |
                        (bytes32(lastSelector) >> oldSelectorInSlotPosition);
                }
                if (selectorInSlotIndex == 0) {
                    delete ds.selectorSlots[selectorSlotCount];
                    _selectorSlot = 0;
                }
            }
            _selectorCount = selectorSlotCount * 8 + selectorInSlotIndex;
        } else {
            revert("LibDiamondCut: Incorrect FacetCutAction");
        }
        return (_selectorCount, _selectorSlot);
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

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