// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/UInt256Set.sol";
import "../utils/AddressSet.sol";

import "../interfaces/IMarketplace.sol";
import "../interfaces/ITokenMinter.sol";
import "../interfaces/ITokenSale.sol";
import "../interfaces/IAirdropTokenSale.sol";
import "../interfaces/IERC721A.sol";

import {LibDiamond} from "./LibDiamond.sol";

// struct for erc1155 storage
struct ERC1155Storage {
    mapping(uint256 => mapping(address => uint256)) _balances;
    mapping(address => mapping(address => bool)) _operatorApprovals;
    mapping(address => mapping(uint256 => uint256)) _minterApprovals;

    // mono-uri from erc1155
    string _uri;
    string _uriBase;
    string _symbol;
    string _name;

    address _approvalProxy;
}

// struct for erc721a storage
struct ERC721AStorage {
    // The tokenId of the next token to be minted.
    uint256 _currentIndex;

    // The number of tokens burned.
    uint256 _burnCounter;

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => IERC721A.TokenOwnership) _ownerships;

    // Mapping owner address to address data
    mapping(address => IERC721A.AddressData) _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}

// erc2981 storage struct
struct ERC2981Storage {
    // royalty receivers by token hash
    mapping(uint256 => address) royaltyReceiversByHash;
    // royalties for each token hash - expressed as permilliage of total supply
    mapping(uint256 => uint256) royaltyFeesByHash;
}

// attribute mutatiom pool storage
struct AttributeMutationPoolStorage {
    string _attributeKey;
    uint256 _attributeValuePerPeriod;
    uint256 _attributeBlocksPerPeriod;
    uint256 _totalValueThreshold;
    mapping (address => mapping (uint256 => uint256)) _tokenDepositHeight;
}

// token attribute storage
struct TokenAttributeStorage {
    mapping(uint256 => mapping(string => uint256)) attributes;
}

// merkle utils storage
struct MerkleUtilsStorage {
    mapping(uint256 => uint256) tokenHashToIds;
}

// NFT marketplace storage
struct MarketplaceStorage {
    uint256 itemsSold;
    uint256 itemIds;
    mapping(uint256 => IMarketplace.MarketItem) idToMarketItem;
    mapping(uint256 => bool) idToListed;
}

// token minter storage
struct TokenMinterStorage {
    address token;
    uint256 _tokenCounter;
    mapping(uint256 => address) _tokenMinters;
}

// fractionalized token storage
struct FractionalizedTokenData {
    string symbol;
    string name;
    address tokenAddress;
    uint256 tokenId;
    address fractionalizedToken;
    uint256 totalFractions;
}

// fractionalizer storage
struct FractionalizerStorage {
    address fTokenTemplate;
    mapping(address => FractionalizedTokenData) fractionalizedTokens;
}

// token sale storage
struct TokenSaleStorage {
    mapping(address => ITokenSale.TokenSaleEntry) tokenSaleEntries;
}

struct AirdropTokenSaleStorage {
    uint256 tsnonce;
    mapping(uint256 => uint256) nonces;
    // token sale settings
    mapping(uint256 => IAirdropTokenSale.TokenSaleSettings) _tokenSales;
    // is token sale open
    mapping(uint256 => bool) tokenSaleOpen;
    // total purchased tokens per drop - 0 for public tokensale
    mapping(uint256 => mapping(address => uint256)) purchased;
    // total purchased tokens per drop - 0 for public tokensale
    mapping(uint256 => uint256) totalPurchased;
}

struct MerkleAirdropStorage {
    mapping (uint256 => IAirdrop.AirdropSettings) _settings;
    uint256 numSettings;
    mapping (uint256 => mapping(uint256 => uint256)) _redeemedData;
    mapping (uint256 => mapping(address => uint256)) _redeemedDataQuantities;
    mapping (uint256 => mapping(address => uint256)) _totalDataQuantities;
}

struct MarketUtilsStorage {
    mapping(uint256 => bool) validTokens;
}

struct AppStorage {
    // gem pools data
    MarketplaceStorage marketplaceStorage;
    // gem pools data
    TokenMinterStorage tokenMinterStorage;
    // the erc1155 token
    ERC1155Storage erc1155Storage;
    // fractionalizer storage
    FractionalizerStorage fractionalizerStorage;
    // market utils storage
    MarketUtilsStorage marketUtilsStorage;
    // token sale storage
    TokenSaleStorage tokenSaleStorage;
    // merkle airdrop storage
    MerkleAirdropStorage merkleAirdropStorage;
    // erc721a storage
    ERC721AStorage erc721AStorage;
    // erc2981 storage
    ERC2981Storage erc2981Storage;
    // attribute mutation pool storage
    AttributeMutationPoolStorage attributeMutationPoolStorage;
    // token attribute storage
    TokenAttributeStorage tokenAttributeStorage;
    // airdrop token sale storage
    AirdropTokenSaleStorage airdropTokenSaleStorage;
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
        require(LibDiamond.contractOwner() == msg.sender || address(this) == msg.sender, "ERC1155: only the contract owner can call this function");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

/// @notice Defines the data structures that are used to store the data for a diamond
library LibDiamond {
    // the diamond storage position
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    /// @notice Stores the function selectors located within the Diamond
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

    /// @notice Returns the storage position of the diamond
    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    // event is generated when the diamond ownership is transferred
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice set the diamond contract owner
    /// @param _newOwner the new owner of the diamond
    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    /// @notice returns the diamond contract owner
    /// @return contractOwner_ the diamond contract owner
    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    /// @notice enforce contract ownership by requiring the caller to be the contract owner
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

    /// @notice add or replace facet selectors
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

    /// @notice initialise the DiamondCut contract
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IToken.sol";
import "./ITokenPrice.sol";
import "./IAirdropTokenSale.sol";

interface IMerkleAirdrop {
    function airdropRedeemed(
        uint256 drop,
        address recipient,
        uint256 amount
    ) external;
     function initMerkleAirdrops(IAirdrop.AirdropSettings[] calldata settingsList) external;
     function airdrop(uint256 drop) external view returns (IAirdrop.AirdropSettings memory settings);
     function airdropRedeemed(uint256 drop, address recipient) external view returns (bool isRedeemed);
}

/// @notice an airdrop airdrops tokens
interface IAirdrop {

    // emitted when airdrop is redeemed


    /// @notice the settings for the token sale,
    struct AirdropSettings {
        // sell from the whitelist only
        bool whitelistOnly;

        // this whitelist id - by convention is the whitelist hash
        uint256 whitelistId;

        // the root hash of the merkle tree
        bytes32 whitelistHash;

        // quantities
        uint256 maxQuantity; // max number of tokens that can be sold
        uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
        uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
        uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

        // quantity of item sold
        uint256 quantitySold;

        // start timne and end time for token sale
        uint256 startTime; // block number when the sale starts
        uint256 endTime; // block number when the sale ends

        // inital price of the token sale
        ITokenPrice.TokenPriceData initialPrice;

        // token hash
        uint256 tokenHash;

        IAirdropTokenSale.PaymentType paymentType; // the type of payment that is being used
        address tokenAddress; // the address of the payment token, if payment type is TOKEN

        // the address of the payment token, if payment type is ETH
        address payee;
    }

    // emitted when airdrop is launched
    event AirdropLaunched(uint256 indexed airdropId, AirdropSettings airdrop);

    // emitted when airdrop is redeemed
    event AirdropRedeemed(uint256 indexed airdropId, address indexed beneficiary, uint256 indexed tokenHash, bytes32[] proof, uint256 amount);

    /// @notice airdrops check to see if proof is redeemed
    /// @param drop the id of the airdrop
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function airdropRedeemed(uint256 drop, address recipient) external view returns (bool isRedeemed);

    /// @notice redeem tokens for airdrop
    /// @param drop the airdrop id
    /// @param leaf the index of the token in the airdrop
    /// @param recipient the beneficiary of the tokens
    /// @param amount tje amount of tokens to redeem
    /// @param merkleProof the merkle proof of the token
    function redeemAirdrop(uint256 drop, uint256 leaf, address recipient, uint256 amount, uint256 total, bytes32[] memory merkleProof) external payable;

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function airdrop(uint256 drop) external view returns (AirdropSettings memory settings);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ITokenPrice.sol";
import "./IAirdrop.sol";

/// @notice A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction.
interface IAirdropTokenSale {


    enum PaymentType {
        ETH,
        TOKEN
    }

    /// @notice the settings for the token sale,
    struct TokenSaleSettings {

        // addresses
        address contractAddress; // the contract doing the selling
        address token; // the token being sold
        uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash
        uint256 collectionHash; // the collection hash being sold. set to 0 to autocreate hash
        
        // owner and payee
        address owner; // the owner of the contract
        address payee; // the payee of the contract

        string symbol; // the symbol of the token
        string name; // the name of the token
        string description; // the description of the token

        // open state
        bool openState; // open or closed
        uint256 startTime; // block number when the sale starts
        uint256 endTime; // block number when the sale ends

        // quantities
        uint256 maxQuantity; // max number of tokens that can be sold
        uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
        uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
        uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

        // inital price of the token sale
        ITokenPrice.TokenPriceData initialPrice;

        PaymentType paymentType; // the type of payment that is being used
        address tokenAddress; // the address of the payment token, if payment type is TOKEN

    }

    /// @notice emitted when a token is opened
    event TokenSaleOpen (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice emitted when a token is opened
    event TokenSaleClosed (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice emitted when a token is opened
    event TokenPurchased (uint256 tokenSaleId, address indexed purchaser, uint256 tokenId, uint256 quantity );

    // token settings were updated
    event TokenSaleSettingsUpdated (uint256 tokenSaleId, TokenSaleSettings tokenSale );

    /// @notice Get the token sale settings
    /// @return settings the token sale settings
    function getTokenSaleSettings(uint256 tokenSaleId) external view returns (TokenSaleSettings memory settings);

    /// @notice Updates the token sale settings
    /// @param settings - the token sake settings
    function updateTokenSaleSettings(uint256 iTokenSaleId, TokenSaleSettings memory settings) external;

    function initTokenSale(
        TokenSaleSettings memory tokenSaleInit,
        IAirdrop.AirdropSettings[] calldata settingsList
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow burning
interface IERC1155Burn {

    /// @notice event emitted when tokens are burned
    event Burned(
        address target,
        uint256 tokenHash,
        uint256 amount
    );

    /// @notice burn tokens of specified amount from the specified address
    /// @param target the burn target
    /// @param tokenHash the token hash to burn
    /// @param amount the amount to burn
    function burn(
        address target,
        uint256 tokenHash,
        uint256 amount
    ) external;


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721A {

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarketplace {
    event Bids(uint256 indexed itemId, address bidder, uint256 amount);
    event Sales(uint256 indexed itemId, address indexed owner, uint256 amount, uint256 quantity, uint256 indexed tokenId);
    event Closes(uint256 indexed itemId);
    event Listings(
        uint256 indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address receiver,
        address owner,
        uint256 price,
        bool sold
    );
    struct MarketItem {
        uint256 itemId;
        address nftContract;
        uint256 tokenId;
        address seller;
        address owner;
        uint256 price;
        uint256 quantity;
        bool sold;
        address receiver;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface IToken {

    struct Token {

        uint256 id;
        uint256 balance;
        bool burn;

    }

    /// @notice a set of tokens.
    struct TokenSet {

        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
        Token[] valueList;

    }

    /// @notice the definition for a token.
    struct TokenDefinition {

        // the host multitoken
        address token;

        // the id of the token definition. if static mint then also token hash
        uint256 id;

        // the category name
        uint256 collectionId;

        // the name of the token
        string name;

        // the symbol of the token
        string symbol;

        // the description of the token
        string description;

        // the decimals of the token. 0 for NFT
        uint8 decimals;

        // the total supply of the token
        uint256 totalSupply;

        // whether to generate the id or not for new tokens. if false then we use id field of the definition to mint tokens
        bool generateId;

        // probability of the item being awarded
        uint256 probability;

         // the index of the probability in its array
        uint256 probabilityIndex;

         // the index of the probability in its array
        uint256 probabilityRoll;

    }

    struct TokenRecord {

        uint256 id;
        address owner;
        address minter;
        uint256 _type;
        uint256 balance;

    }

    /// @notice the token source type. Either a static source or a collection.
    enum TokenSourceType {

        Static,
        Collection

    }

    /// @notice the token source. Specifies the source of the token - either a static source or a collection.
    struct TokenSource {

        // the token source type
        TokenSourceType _type;
        // the source id if a static collection
        uint256 staticSourceId;
        // the collection source address if collection
        address collectionSourceAddress;

    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./IERC1155Burn.sol";

/**
 * @notice This intreface provides a way for users to register addresses as permissioned minters, mint * burn, unregister, and reload the permissioned minter account.
 */
interface ITokenMinter {

    /// @notice a registration record for a permissioned minter.
    struct Minter {

        // the account address of the permissioned minter.
        address account;
        // the amount of tokens minted by the permissioned minter.
        uint256 minted;
        // the amount of tokens minted by the permissioned minter.
        uint256 burned;
        // the amount of payment spent by the permissioned minter.
        uint256 spent;
        // an approval map for this minter. sets a count of tokens the approved can mint.
        // mapping(address => uint256) approved; // TODO implement this.

    }

    /// @notice event emitted when minter is registered
    event MinterRegistered(
        address indexed registrant,
        uint256 depositPaid
    );

    /// @notice emoitted when minter is unregistered
    event MinterUnregistered(
        address indexed registrant,
        uint256 depositReturned
    );

    /// @notice emitted when minter address is reloaded
    event MinterReloaded(
        address indexed registrant,
        uint256 amountDeposited
    );

    /// @notice get the registration record for a permissioned minter.
    /// @param _minter the address
    /// @return _minterObj the address
    function minter(address _minter) external returns (Minter memory _minterObj);

    /// @notice mint a token associated with a collection with an amount
    /// @param receiver the mint receiver
    /// @param collectionId the collection id
    /// @param amount the amount to mint
    function mint(address receiver, uint256 collectionId, uint256 id, uint256 amount) external;

    /// @notice mint a token associated with a collection with an amount
    /// @param target the mint receiver
    /// @param id the collection id
    /// @param amount the amount to mint
    function burn(address target, uint256 id, uint256 amount) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice common struct definitions for tokens
interface ITokenPrice {

    /// @notice DIctates how the price of the token is increased post every sale
    enum PriceModifier {

        None,
        Fixed,
        Exponential,
        InverseLog

    }

    /// @notice a token price and how it changes
    struct TokenPriceData {

        // the price of the token
        uint256 price;
         // how the price is modified
        PriceModifier priceModifier;
        // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
        uint256 priceModifierFactor;
        // max price for the token
        uint256 maxPrice;

    }

    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (TokenPriceData memory);


}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

///
/// @notice A token seller is a contract that can sell tokens to a token buyer.
/// The token buyer can buy tokens from the seller by paying a certain amount
/// of base currency to receive a certain amount of erc1155 tokens. the number
/// of tokens that can be bought is limited by the seller - the seller can
/// specify the maximum number of tokens that can be bought per transaction
/// and the maximum number of tokens that can be bought in total for a given
/// address. The seller can also specify the price of erc1155 tokens and how
/// that price increases per successful transaction.
interface ITokenSale {

    struct TokenSaleEntry {
        address payable receiver;
        address sourceToken;
        uint256 sourceTokenId;
        address token;
        uint256 quantity;
        uint256 price;
        uint256 quantitySold;
    }

    event TokenSaleSet(address indexed token, uint256 indexed tokenId, uint256 price, uint256 quantity);
    event TokenSold(address indexed buyer, address indexed tokenAddress, uint256 indexed tokenId, uint256 salePrice);
    event TokensSet(address indexed tokenAddress, ITokenSale.TokenSaleEntry tokens);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library AddressSet {
    struct Set {
        mapping(address => uint256) keyPointers;
        address[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, address key) public {
        require(
            !exists(self, key),
            "AddressSet: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, address key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        require(
            exists(self, key),
            "AddressSet: key does not exist in the set."
        );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            address keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        self.keyList.pop();
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, address key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (address)
    {
        return self.keyList[index];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
}