// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: Halfstep Labs Inc.

import {Modifiers, Staked} from "../libraries/AppStorage.sol";
import {LibMeta} from "../libraries/LibMeta.sol";
import {LibToken} from "../libraries/LibToken.sol";
import {LibStaking} from "../libraries/LibStaking.sol";

contract StakingFacet is Modifiers {

    /// @dev Emitted when a token is staked
    event Stake(uint256 indexed _tokenId);

    /// @dev Emitted when a token is unstaked
    event Unstake(uint256 indexed _tokenId);

    /// @notice Sets whether the tokens can be staked
    /// @param _staking the new staking state
    function allowStaking(bool _staking) external onlyOwner {
        s.stakingAllowed = _staking;
    }

    /// @notice Stakes a token for a period of time
    /// @dev Requirements:
    /// - 'stakingAllowed' must be set to true
    /// - '_tokenId' must exist
    /// - 'msgSender' must be the owner of the token specified
    /// - token must not already be staked
    /// @param _tokenId The id of the token a user wants to stake
    function stake(uint256 _tokenId) external {
        require(s.stakingAllowed, "Staking not allowed");
        require(LibToken.exists(_tokenId), "Token does not exist");
        require(
            LibMeta.msgSender() == LibToken.findOwner(_tokenId),
            "Token not owned by caller"
        );
        require(!LibStaking.isStaked(_tokenId), "Token already staked");

        s.stakedTokens[_tokenId] = Staked(uint128(block.timestamp), msg.sender);

        emit Stake(_tokenId);
    }

    /// @notice Unstakes a token after a period of time
    /// @dev Requirements:
    /// - '_tokenId' must exist
    /// - 'msgSender' must be the owner of the token specified
    /// - token must be staked
    /// - token must be staked for a designated amount of time (currently 6 months/24 weeks)
    /// @param _tokenId The id of the token a user wants to stake
    function unStake(uint256 _tokenId) external {
        require(LibToken.exists(_tokenId), "Token does not exist");
        require(
            LibMeta.msgSender() == LibToken.findOwner(_tokenId),
            "Token not owned by caller"
        );
        require(LibStaking.isStaked(_tokenId), "Token not staked");
        // Check to make sure time period has been completed
        require(
            block.timestamp >
                uint128(
                    s.stakedTokens[_tokenId].startTimeStamp + (s.stakeDuration)
                ),
            "Stake duration not met"
        );

        delete s.stakedTokens[_tokenId];

        emit Unstake(_tokenId);
    }

    /// @notice Sets the duration until a staked token can be unstaked
    /// @param _duration the duration in seconds
    function setStakeDuration(uint128 _duration) external onlyOwner {
        s.stakeDuration = _duration;
    }

    /// @notice Returns the staking duration requirement
    function getStakeDuration() external view returns (uint128) {
        return s.stakeDuration;
    }

    /// @notice Queries the duration that a token has been staked for thus far
    /// @dev Requirements:
    /// - '_tokenId' must exist
    /// - '_tokenId' must be staked
    /// @param _tokenId the token that is being queried
    /// @return the time in seconds a token has been staked for
    function currentStakeDuration(uint256 _tokenId)
        external
        view
        returns (uint128)
    {
        require(LibToken.exists(_tokenId), "Token does not exist");
        require(LibStaking.isStaked(_tokenId), "Token not staked");
        return
            uint128(block.timestamp) - s.stakedTokens[_tokenId].startTimeStamp;
    }

    /// @notice Returns whether a specific token is staked
    /// @dev Will throw if token does not exist
    /// @param _tokenId the token that is being queried
    /// @return whether the token is staked
    function isStaked(uint256 _tokenId) external view returns (bool) {
        require(LibToken.exists(_tokenId), "Token does not exist");
        return LibStaking.isStaked(_tokenId);
    }

    /// @notice Get whether staking is currenlty active for the Halfstep Diamond
    /// @return whether staking is allowed
    function isStakingAllowed() external view returns (bool) {
        return s.stakingAllowed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {LibDiamond} from "./LibDiamond.sol";

// Mint price is USD as an integer with 8 digits of precision
uint256 constant PRICE_USD = 15000000000;
// Maximum number of mints per transaction
uint256 constant MAX_MINT_PER_TX = 3;

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
    // Whether the partner is currently part of the Plebs network
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

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamond Standard: https://eips.ethereum.org/EIPS/eip-2535
*
* Modification of the LibMeta library part of Aavegotchi's contracts
/******************************************************************************/

library LibMeta {
    
    function msgSender() internal view returns (address sender_) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: Halfstep Labs Inc.

import {AppStorage, LibAppStorage, TokenStats, MAX_MINT_PER_TX} from "./AppStorage.sol";
import {LibStaking} from "../libraries/LibStaking.sol";
import {LibMeta} from "./LibMeta.sol";

library LibToken {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @notice Returns whether a given token exists
    /// @param _tokenId the ID of the token being queried
    function exists(uint256 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        return _tokenId < s.currentTokenCount;
    }

    /// @notice Internal helper function that determines the owner of a specific token id
    /// @dev Will throw if token ID doesn't exist
    /// Will revert if a non zero address is not found
    /// @param _tokenId the id for the token whose owner is being queried
    /// @return owner the address for the owner of the token passed into the function
    function findOwner(uint256 _tokenId) internal view returns (address) {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(exists(_tokenId), "LibToken: Token does not exist");

        TokenStats memory tempToken = s.tokenStats[_tokenId];
        if (tempToken.owner != address(0)) return tempToken.owner;

        uint256 lowest = 0;
        if (_tokenId > s.kpTokenCount) {
            lowest = _tokenId - MAX_MINT_PER_TX;
        }

        for (uint256 idx = _tokenId; idx + 1 > lowest; idx--) {
            address owner = s.tokenStats[idx].owner;
            if (owner != address(0)) return owner;
        }

        revert("LibToken: Owner not found");
    }

    /// @notice Internal tranfer function to transfer tokens from one address to another
    /// @dev Requirements:
    /// - '_from' must be the same address as the current owner of the token
    /// - '_tokenId' must not be staked at the time of tranfer
    /// - '_to' cannot be the zero address
    /// @param _from the address the token is being transferred from
    /// @param _to the address the token is being transferred to
    /// @param _tokenId the token that is to be transferred
    function transfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            findOwner(_tokenId) == _from,
            "LibToken: Transfer from incorrect owner"
        );
        require(
            !LibStaking.isStaked(_tokenId),
            "LibToken: Token has been staked by current owner"
        );
        require(_to != address(0), "LibToken: Transfer to the zero address");

        s.tokenApprovals[_tokenId] = address(0);

        s.addressStats[_from].balance--;
        s.addressStats[_to].balance++;

        s.tokenStats[_tokenId].owner = _to;

        if (s.tokenStats[_tokenId + 1].owner == address(0)) {
            if (exists(_tokenId + 1)) {
                s.tokenStats[_tokenId + 1].owner = _from;
            }
        }

        emit Transfer(_from, _to, _tokenId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {AppStorage, LibAppStorage} from "./AppStorage.sol";

// Author: Halfstep Labs Inc.

library LibStaking {
    /// @notice Returns whether the given token is staked
    /// @param _tokenId the ID pf the token
    function isStaked(uint256 _tokenId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.stakedTokens[_tokenId].owner != address(0);
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