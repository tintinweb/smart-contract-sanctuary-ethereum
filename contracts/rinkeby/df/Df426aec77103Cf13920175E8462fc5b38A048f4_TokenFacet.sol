// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Author: Halfstep Labs Inc.

import {Modifiers, PRICE_USD, MAX_MINT_PER_TX} from "../libraries/AppStorage.sol";
import {LibToken} from "../libraries/LibToken.sol";
import {LibMeta} from "../libraries/LibMeta.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibStaking} from "../libraries/LibStaking.sol";
import {ERC721A} from "../ERC721A.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract TokenFacet is ERC721A {
    using Strings for uint256;

    /// @dev Emitted when a token is first minted
    event Mint(
        address indexed _to,
        uint128 indexed _partnerId,
        uint128 indexed _tokensMinted,
        uint256 _price
    );

    /// @notice Queries the total number of Pleb tokens that have ever been minted
    /// @return uint256 the number of Pleb tokens minted
    function totalSupply() external view returns (uint256) {
        return s.currentTokenCount;
    }

    /// @notice Mints token(s) to a specified address
    /// @dev Requirements:
    /// - Minting must be active
    /// - '_to' cannot be the zero address
    /// - '_mintAmt' plus the amount of tokens already minted through a partner cannot exceed the partner's 'tokenLimit'
    /// - the 'msg.value' must be equal to the PRICE * '_mintAmt'
    /// - the '_mintAmt' must be less than or equal to s.transactionLimit
    /// - '_nonce' cannot be used multiple times
    /// - '_signature' must be a valid signature
    /// @param _to the address receiving the minted token
    /// @param _mintAmt the amount of tokens that are wished to be minted by the caller
    /// @param _partnerId the partner that the caller wishes to mint through
    /// @param _nonce unique nonce created for the transaction
    /// @param _signature validator signature
    /// @param _price price at mint
    function mintTo(
        address _to,
        uint128 _mintAmt,
        uint128 _partnerId,
        uint256 _nonce,
        bytes memory _signature,
        uint256 _price
    ) external payable {
        require(s.isActive, "Minting is unavailable");
        require(_to != address(0), "Invalid receiver");
        require(
            s.partners[_partnerId].tokensMinted + _mintAmt <
                s.partners[_partnerId].tokenLimit + 1,
            "Not enough tokens available"
        );
        require(_mintAmt * _price == msg.value, "Incorrect funds");
        require(_mintAmt < MAX_MINT_PER_TX + 1, "Exceeds mints per tx limit");
        require(s.usedNonces[_nonce] == address(0), "Signature already used");
        require(
            isSignedByValidator(
                ECDSA.toEthSignedMessageHash(
                    encodeForSignature(LibMeta.msgSender(), _nonce, _price)
                ),
                _signature
            ),
            "Invalid signature"
        );

        s.partners[_partnerId].tokensMinted += _mintAmt;
        s.usedNonces[_nonce] = _to;

        _safeMint(_to, _mintAmt, _partnerId);

        emit Mint(_to, _partnerId, s.partners[_partnerId].tokensMinted, _price);
    }

    /// @notice Checks if the provided signature is signed by the validator using the provided message hash
    /// @param _hash the hash of the message
    /// @param _signature the validator signed message hash
    /// @return whether the signature is that of the validator
    function isSignedByValidator(bytes32 _hash, bytes memory _signature)
        private
        view
        returns (bool)
    {
        return
            s.validator != address(0) &&
            s.validator == ECDSA.recover(_hash, _signature);
    }

    /// @notice Encodes and hashes message data
    /// @param _to address receiving the minted token
    /// @param _nonce unique nonce created for minting
    /// @param _price price at mint
    /// @return the recreated message hash
    function encodeForSignature(
        address _to,
        uint256 _nonce,
        uint256 _price
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_to, _nonce, _price));
    }

    /// @notice Mint tokens to the Diamond address. These are reserved for current Keg Pleb holders
    /// @dev Requirement:
    /// - cannot call this function if tokens have already been minted (this function can only be called once)
    function ownerReserveMint() external onlyOwner {
        require(s.currentTokenCount == 0, "Tokens have already been reserved");
        s.partners[1].tokensMinted = s.partners[1].tokenLimit;
        _safeMint(address(this), s.partners[1].tokenLimit, 1);
    }

    /// @notice Sets whether minting is active
    /// @param _active the new state of minting
    function active(bool _active) external onlyOwner {
        s.isActive = _active;
    }

    /// @notice Returns whether minting is active
    function isActive() external view returns (bool) {
        return s.isActive;
    }

    /// @notice Setter for validator address
    /// @dev Requirement:
    /// - '_validator' cannot be zero address
    /// @param _validator the address being set as the validator
    function setValidator(address _validator) external onlyOwner {
        require(_validator != address(0), "Validator cannot be zero address");
        s.validator = _validator;
    }

    /// @notice Getter for validator address
    /// @return address the validator address
    function getValidator() external view returns (address) {
        return s.validator;
    }

    /// @notice Withdraws the current contract balance to the owner
    function withdraw() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Withdraw Error");
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

    /// @notice internal helper function that determines the owner of a specific token id
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
    /// -> '_from' must be the same address as the current owner of the token
    /// -> '_tokenId' must not be staked at the time of tranfer
    /// -> '_to' cannot be the zero address
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
* Modified version of the original ERC721A (v1.0.0) https://www.erc721a.org/
/******************************************************************************/

import {AddressStats, TokenStats, AppStorage, Modifiers} from "./libraries/AppStorage.sol";
import {LibToken} from "./libraries/LibToken.sol";
import {LibMeta} from "./libraries/LibMeta.sol";
import {IERC721} from "./interfaces/IERC721.sol";
import {IERC721Receiver} from "./interfaces/IERC721Receiver.sol";

contract ERC721A is Modifiers, IERC721 {
    /// @notice Queries the number of Pleb tokens owned by an address
    /// @dev Requirements:
    /// - '_owner' cannot be the zero address
    /// @param _owner the address whose balance is being queried
    /// @return uint256 the current balance of the owner passed to the function
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "Query for the zero address");
        return s.addressStats[_owner].balance;
    }

    /// @notice Queries the owner of a specific token ID
    /// @param _tokenId the ID for the token whose owner is being queried
    /// @return address the address of the given token's owner
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        return LibToken.findOwner(_tokenId);
    }

    /// @notice Approves an address to manage/transfer a token owned by the caller
    /// @dev Requirements:
    /// - '_to' cannot be the current owner of the token
    /// - 'msgSender' must be the owner of the token being approved
    /// @param _approved the address requested to be approved
    /// @param _tokenId the token ID requested to add a manager to
    function approve(address _approved, uint256 _tokenId) external override {
        address owner = LibToken.findOwner(_tokenId);
        require(_approved != owner, "Approval to current owner");
        require(
            owner == LibMeta.msgSender() ||
                s.operatorApprovals[owner][LibMeta.msgSender()],
            "Approve caller is not owner nor approved for all"
        );
        s.tokenApprovals[_tokenId] = _approved;

        emit Approval(owner, _approved, _tokenId);
    }

    /// @notice Approves/removes approval of an address to manage all tokens owned by the caller
    /// @param _operator the address to be approved for managing all the caller's tokens
    /// @param _approved whether the operator address can manage the caller's tokens
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        s.operatorApprovals[LibMeta.msgSender()][_operator] = _approved;
        emit ApprovalForAll(LibMeta.msgSender(), _operator, _approved);
    }

    /// @notice Queries whether an address is approved to manage all tokens for another address
    /// @param _owner the address corresponding to the owner of the tokens
    /// @param _operator the address acting on behalf of the owner
    /// @return bool whether an operator has been given permission by the owner
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return s.operatorApprovals[_owner][_operator];
    }

    /// @notice Returns if an address has been approved or is an owner of a given token
    /// @dev Requirement:
    /// '_tokenId' must exist
    /// @param _spender the address that is being checked for approval or ownership
    /// @param _tokenId the token whose operator is being checked against
    /// @return bool whether a token is approved to be managed or owned by a specific address
    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            LibToken.exists(_tokenId),
            "Operator query for nonexistent token"
        );
        address owner = LibToken.findOwner(_tokenId);
        return (_spender == owner ||
            s.operatorApprovals[owner][_spender] ||
            _spender == s.tokenApprovals[_tokenId]);
    }

    /// @notice Returns the approved address of a token
    /// @dev Requirement:
    /// '_tokenId' must exist
    /// @param _tokenId the token to get the approved address for
    /// @return the approved address for the token
    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(
            LibToken.exists(_tokenId),
            "Approved query for nonexistent token"
        );
        return s.tokenApprovals[_tokenId];
    }

    /// @notice External tranfer function to transfer tokens from one address to another
    /// @dev Requirements:
    /// - 'msgSender' must be the token owner or and approved operator
    /// @param _from the address the token is being transferred from
    /// @param _to the address the token is being transferred to
    /// @param _tokenId the token that is to be transferred
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual override {
        require(
            isApprovedOrOwner(LibMeta.msgSender(), _tokenId),
            "Transfer caller is not owner nor approved"
        );
        LibToken.transfer(_from, _to, _tokenId);
    }

    /// @notice External tranfer function to transfer tokens from one address to another 'safely'
    /// @param _from the address the token is being transferred from
    /// @param _to the address the token is being transferred to
    /// @param _tokenId the token that is to be transferred
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external virtual override {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /// @notice External tranfer function to transfer tokens from one address to another 'safely'
    /// @param _from the address the token is being transferred from
    /// @param _to the address the token is being transferred to
    /// @param _tokenId the token that is to be transferred
    /// @param _data extra data param
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external virtual override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /// @notice Internal tranfer function to transfer tokens from one address to another 'safely'
    /// @dev Requirements:
    /// - 'msgSender' must be the token owner or and approved operator
    /// @param _from the address the token is being transferred from
    /// @param _to the address the token is being transferred to
    /// @param _tokenId the token that is to be transferred
    /// @param _data extra data param
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal virtual {
        require(
            isApprovedOrOwner(LibMeta.msgSender(), _tokenId),
            "Transfer caller is not owner nor approved"
        );
        LibToken.transfer(_from, _to, _tokenId);
        _checkOnERC721Received(_from, _to, _tokenId, _data);
    }

    /// @notice Mints token(s) to a specified address (internal)
    /// @dev Requirements:
    /// - '_to' cannot be the zero address
    /// - the token id cannot already exist
    /// the token must be transfered on mint to either a wallet address, or a contract that supports the ERC721Receiver implementaion
    /// @param _to the address to mint the tokens to
    /// @param _mintAmt the amount of tokens that are wished to be minted by the caller
    /// @param _partnerId the metadata uri for a given partner
    function _safeMint(
        address _to,
        uint256 _mintAmt,
        uint128 _partnerId
    ) internal {
        require(_to != address(0), "Mint to the zero address");
        uint256 firstTokenId = s.currentTokenCount;

        require(!LibToken.exists(firstTokenId), "Token already minted");

        AddressStats memory addressStats = s.addressStats[_to];
        s.addressStats[_to] = AddressStats(
            addressStats.balance + uint128(_mintAmt),
            addressStats.totalMints + uint128(_mintAmt)
        );
        s.tokenStats[firstTokenId] = TokenStats(_partnerId, _to);

        uint256 updatedIndex = firstTokenId;

        for (uint128 i = 0; i < _mintAmt; i++) {
            emit LibToken.Transfer(address(0), _to, updatedIndex);

            require(
                _checkOnERC721Received(address(0), _to, updatedIndex, ""),
                "Transfer to non-ERC721Receiver implementer"
            );
            updatedIndex++;
        }
        s.currentTokenCount = updatedIndex;
    }

    /// @notice Checks if the receiving address is an ERC721Receiver implementer
    /// @param _from the address that previously owned the token
    /// @param _to the address of the receiver
    /// @param _tokenId the ID of the token being transferred
    /// @param _data additional data with no specified format
    /// @return whether the transfer was received by an ERC721Receiver
    function _checkOnERC721Received(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(_to)
        }

        // Checks if _to is a contract
        if (size > 0) {
            try
                IERC721Receiver(_to).onERC721Received(
                    LibMeta.msgSender(),
                    _from,
                    _tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("Transfer to non-ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
interface IERC721 {
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

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param _data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @dev Note: the ERC-165 identifier for this interface is 0x150b7a02.
interface IERC721Receiver {
    /// @notice Handle the receipt of an NFT
    /// @dev The ERC721 smart contract calls this function on the recipient
    ///  after a `transfer`. This function MAY throw to revert and reject the
    ///  transfer. Return of other than the magic value MUST result in the
    ///  transaction being reverted.
    ///  Note: the contract address is always the message sender.
    /// @param _operator The address which called `safeTransferFrom` function
    /// @param _from The address which previously owned the token
    /// @param _tokenId The NFT identifier which is being transferred
    /// @param _data Additional data with no specified format
    /// @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    ///  unless throwing
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external returns (bytes4);
}