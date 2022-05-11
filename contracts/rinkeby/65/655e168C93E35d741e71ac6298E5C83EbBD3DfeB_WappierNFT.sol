// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

import "./WP721Marketplace.sol";
// import "./WappierResettable.sol";

// Wappiers smart contract inherits ERC721 interface
contract WappierNFT is WP721Marketplace {
    /** @dev The user readable name of the signing domain. This is the first parameter of the EIP712 constructor. */
    string private constant SIGNING_DOMAIN = "Wappier-NFT-Voucher";
    /** @dev The current major version of the signing domain. This is the second parameter of the EIP712 constructor. */
    string private constant SIGNATURE_VERSION = "1";

    /**
     * @dev Initializes the contract by calling the WP721Marketplace constructor passing:
     * - The address of the `minter`.
     * - The `baseURI`.
     * - The collection name of NFTs.
     * - The collection symbol of NFTs.
     * - The signing domain.
     * - The version of the signing domain.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     */
    constructor(address payable minter, string memory baseURI, address managerAddr)
        WP721Marketplace(
            minter,
            baseURI,
            "Wappiers Collection",
            "WP",
            SIGNING_DOMAIN,
            SIGNATURE_VERSION,
            managerAddr
        )
    {}

function resetContractData(
    uint256[] calldata tokenIds,
    string[] calldata tokenNames,
    string[] calldata voucherIds
  ) public {
    require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
    require(
      tokenIds.length == tokenNames.length,
      "The token ids and token names are not matching"
    );

    for (uint256 index = 0; index < tokenIds.length; index++) {
      delete allWappierNFTs[tokenIds[index]];
      delete tokenNameExists[tokenNames[index]];
      _burn(tokenIds[index]);
    }

    for (uint256 index = 0; index < voucherIds.length; index++) {
      delete voucherIdExists[voucherIds[index]];
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.3;

/** @dev Represents a Dutch auction, a market where prices
     generally start high and incrementally drop until a bidder 
     accepts the going price. */
struct DutchAuctionListingData {
    uint256 endingPrice;
    uint256 priceDropStep;
    uint256 priceDropFreq; // in seconds
}

struct Listing {
    uint256 listingId;
    uint256 startAt; // in seconds
    uint256 expiresAt; // in seconds
    uint256 price;
    address owner;
    //uint64 maxMintAmount;
    uint64 transactionLimit;
    uint64 userLimit;
    bool isLazy;
    bool active;
    ListingTypes listingType;
    DutchAuctionListingData dutchData;
}

enum ListingTypes {
    DUTCH,
    NORMAL
}

struct ListingArguments {
    uint256 listingId;
    uint256 startDate; // in seconds
    uint256 endDate; // in seconds
    uint256 initialPrice;
    //uint64 maxMintAmount;
    uint64 transactionLimit;
    uint64 userLimit;
    uint256[] tokenIds;
    uint256 endingPrice;
    uint256 priceDropStep;
    uint256 priceDropFreq;
    ListingTypes listingType;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.3;

import { ListingTypes, Listing, DutchAuctionListingData, ListingArguments } from "./../types/WappierStructs.sol";

interface IMarketplaceManager {
    /** @dev Emitted when `listingId` dutch listing ends */
    event ListingEnded(uint256 indexed listingId, uint256 requestId);

    /** @dev Emitted when `listingId` listing created */
    event ListingCreated(uint256 indexed listingId, uint256 requestId);

    /** @dev Emitted when `listingId` listing updates */
    event ListingUpdated(uint256 indexed listingId, uint256 requestId);

    /** @dev Emitted when `listingId` listing deleted */
    event ListingDeleted(uint256 indexed listingId, uint256 requestId);

    /**
     * @dev Creates the `listingId` Listing.
     *
     * It creates the `Listing` struct based on type
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE` if the listing is lazy
     * - The caller must be the token owner if listing is not lazy
     *
     * Emits a {ListingCreated} event.
     * @param listingArgs A `ListingArguments` struct that has the listing information.
     */
    function createListing(ListingArguments calldata listingArgs, uint256 requestId) external;

    /**
     * @dev Updates the `listingId` Listing.
     *
     * It creates the `Listing` struct based on type
     *
     * Requirements:
     * - The caller must be the listing owner
     *
     * Emits a {ListingUpdated} event.
     * @param listingArgs A `ListingArguments` struct that has the listing information.
     */
    function updateListing(ListingArguments calldata listingArgs, uint256 requestId) external;

    /**
     * @dev Deletes the `listingId` Listing.
     *
     * Deletes the `listingId` listing.
     *
     * Requirements:
     * - `listingId` must exist.
     *
     * If listing has a token and the token is not sold to another user then removes this token from sale.
     *
     * Emits a {ListingDeleted} event.
     *
     * @param listingId The listingId ID of the listing to delete.
     */
    function deleteListing(
        uint256 listingId,
        ListingTypes listingType,
        uint256 requestId
    ) external;

    /**
     * @dev Ends the `listingId` Dutch auction.
     *
     * Deactivates the `listingId` auction by setting `auction.active` to `false`.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `listingId` must exist.
     *
     * Emits a {ListingEnded} event.
     *
     * @param listingId The listing ID of the dutch listing to end.
     */
    function endDutchListing(uint256 listingId, uint256 requestId) external;

    /**
     * @dev Gets the data of `listingId` Dutch auction.
     *
     * `timePassed` is the time passed from the start of the auction.
     * `totalDrops` is the number of times for auction's token price to drop.
     * `totalDropValue` is the the total value for auction's token price to drop.
     * `curPrice` is the new auction's token price that occurs after the price drop.
     * If `curPrice` is less or equal than `auction.endingPrice`, then the auction has reached its ending price.
     * Otherwirse, the `nextPriceDropTs` and the `nextPrice` are calculated and finally returned.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `listingId` must exist.
     * - The auction must be active.
     * - The auction must not have been expired.
     * - The auction must have been started.
     *
     * Emits a {ListingEnded} event.
     *
     * @param listingId The auction ID of the auction to get data from.
     *
     * @return (uint256, uint256, uint256) The current price of auction's token, the
     */
    function getDutchListingPriceData(uint256 listingId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /**
    @dev Allows the operator of the marketplaceManager to configure to collection contract
    the collection contract will also be given the COLLECTION_ROLE
     */
    function setWappierNFT(address wappierNFTAddress) external;

    /**
    @dev Allows contracts and EOA wallets to retrieve the a listing by its id
     */
    function getListingById(uint256 id) external view returns (Listing memory);

    /**
    @dev Allow a collection contract to update the user limits for a certain user
    the caller requires the the COLLECTION_ROLE role.
    */
    function updateListingLimits(
        address user,
        uint256 _listingId,
        uint256 amount
    ) external;

    /**
    @dev This method allows external contracts if they
    have the COLLECTION_ROLE to update whether a token is sold or not
     */
    function updateTokenSold(uint256 _listingId, uint256 _tokenId) external;

    /**
    @dev Push a tokenId in a specific listing.
     */
    function pushTokenIdInListing(uint256 _listingId, uint256 _tokenId) external;

    /**
    @dev Deletes a token to listing mapping by Id
     */
    function deleteTokenToListingById(uint256 _tokenId) external;

    /**
    @dev this is a template function that exists to surface the default getter of the tokenToListing mapping 
    of the marketplaceManager
     */
    function tokenToListing(uint256 _tokenId) external returns (uint256);

    /**
    @dev this is a template function that exists to surface the default getter of the listingIdExists mapping 
    of the marketplaceManager
     */
    function listingIdExists(uint256 listingId) external view returns (bool);

    /**
    @dev this is a template function that exists to surface the default getter of the listingUserLimits mapping 
    of the marketplaceManager
     */
    function listingUserLimits(address userAddress, uint256 listingId)
        external
        view
        returns (uint256);

    /**
    @dev this is a template function that exists to surface the default getter of the isTokenSold mapping 
    of the marketplaceManager
     */
    function isTokenSold(uint256 _listingId, uint256 _tokenId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

// import ERC721 iterface
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

// Wappiers smart contract inherits ERC721 interface
abstract contract WPERC721 is ERC721URIStorage, AccessControl {
    /**
     * @notice A unique 32 byte hash that represents the minter role.
     * @dev keccak256() is a cryptographic function built into solidity that takes in any amount of inputs and converts it to 32 byte hash.
     */
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;

    /** @dev The total number of wappiers minted. It determines the given token IDs. */
    Counters.Counter _currTokenId;

    /** @dev the base URI set via _setBaseURI. This will be automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID. */
    string public baseTokenURI;

    /** @dev Represents a minted NFT.*/
    struct WappierNFT {
        uint256 numberOfTransfers;
        string tokenName;
        address mintedBy;
        address payable currentOwner;
        address previousOwner;
    }

    /** @dev Mapping from token ID to WappierNFT struct */
    mapping(uint256 => WappierNFT) public allWappierNFTs;
    /** @dev Mapping from token name to whether exists or not */
    mapping(string => bool) public tokenNameExists;

    /** @dev Emitted when `mintedBy` mints the `tokenId` token with `tokenName` name, `tokenURI` uri and the current owner is `to` */
    event Mint(
        address indexed mintedBy,
        address indexed to,
        uint256 indexed tokenId,
        string tokenName,
        string tokenURI,
        uint256 requestId
    );

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     * Sets up the `MINTER_ROLE` of the `minter`.
     * Sets the `baseTokenURI` to `baseURI`.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     * @param collectionName The collection name
     * @param collectionSymbol The collection symbol
     */
    constructor(
        address payable minter,
        string memory baseURI,
        string memory collectionName,
        string memory collectionSymbol
    ) ERC721(collectionName, collectionSymbol) {
        _setupRole(MINTER_ROLE, minter);
        baseTokenURI = baseURI;
    }

    /**
     * @dev Sets the base URI for all token IDs.
     * It is automatically added as a prefix to the value returned in tokenURI, or to the token ID if tokenURI is empty.
     *
     * Requirements:
     * - Only authorized minter role can pause
     *
     */
    function setBaseURI(string memory baseURI) external {
        require(
            hasRole(MINTER_ROLE, msg.sender),
            "Only authorized minter role can set a new baseURI"
        );
        baseTokenURI = baseURI;
    }

    // override function
    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

     /**
     * @dev Mints `wnft.tokenId` and transfers it to `wnft.mintedBy`.
     *
     * It adds the `WappierNFT` struct to `allWappierNFTs` mapping,
     * makes `wnft.tokenURI` and `wnft.tokenName` as exists,
     * calls ERC721 `_mint()`,
     * sets the metadata by calling ERC721Storage `_setTokenURI()`.
     *
     * Emits a {Mint} event.
     *
     * @param wnft A WappierNFT struct.
     */
    function _mintNFT(WappierNFT memory wnft, uint256 requestId) internal {
        _currTokenId.increment();
        uint256 tokenId = _currTokenId.current();

        // first assign the token to the signer, to establish provenance on-chain
        // add the token id and it's WJMC to all WJMCNFTs mapping
        allWappierNFTs[tokenId] = wnft;

        // make token name passed as exists
        tokenNameExists[wnft.tokenName] = true;

        _safeMint(wnft.mintedBy, tokenId, "");
        _setTokenURI(tokenId, Strings.toString(tokenId));

        string memory tokenURI_ = tokenURI(tokenId);

        // make msg.sender passed token URI as exists

        // emit mint event
        emit Mint(wnft.mintedBy, wnft.currentOwner, tokenId, wnft.tokenName, tokenURI_, requestId);

    }

    /**
     * @dev Returns the chain id of the current blockchain.
     * This is used to workaround an issue with ganache returning different values from the on-chain chainid() function and
     * the eth_chainId RPC method. See https://github.com/protocol/nft-website/issues/121 for context.
     */
    function getChainID() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC721)
        returns (bool)
    {
        return
            ERC721.supportsInterface(interfaceId) || AccessControl.supportsInterface(interfaceId);
    }

     function wappierCounter() public view returns(uint256) {
        return _currTokenId.current();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

abstract contract WPEIP712 is EIP712 {
    /** @dev Represents an un-minted NFT, which has not yet been recorded into the blockchain. A signed voucher can be redeemed for a real NFT using the redeem function. */
    struct NFTVoucher {
        string id;
        string[] tokenNames;
        address eligibleWallet;
        uint256 price;
        uint256 expires_at;
        uint256 listingId;
        uint256 saleId;
        bytes signature;
    }

    /**
     * @dev Initializes the contract by setting domain separator and parameter caches of EIP712 contract.
     *
     * @param signingDomain The domain name
     * @param signatureVersion The signature version
     */
    constructor(string memory signingDomain, string memory signatureVersion)
        EIP712(signingDomain, signatureVersion)
    {}

    /**
     * @dev Returns a hash of the given NFTVoucher, prepared using EIP712 typed data hashing rules.
     * @param voucher An `NFTVoucher` to hash.
     */
    function _hash(NFTVoucher calldata voucher) internal view returns (bytes32) {

        bytes32[] memory _array = new bytes32[](voucher.tokenNames.length);
        for (uint256 i = 0; i < voucher.tokenNames.length; ++i) {
            _array[i] = keccak256(bytes(voucher.tokenNames[i]));
        }
        bytes32 tokenNames = keccak256(abi.encodePacked(_array));

        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256(
                            "NFTVoucher(string id,string[] tokenNames,uint256 listingId,uint256 saleId,address eligibleWallet,uint256 price,uint256 expires_at)"
                        ),
                        keccak256(bytes(voucher.id)),
                        tokenNames,
                        voucher.listingId,
                        voucher.saleId,
                        voucher.eligibleWallet,
                        voucher.price,
                        voucher.expires_at
                    )
                )
            );
    }

    /**
     * @dev Verifies the signature for a given NFTVoucher, returning the address of the signer.
     * Will revert if the signature is invalid. Does not verify that the signer is authorized to mint NFTs.
     * @param voucher An `NFTVoucher` describing an unminted NFT.
     */
    function _verify(NFTVoucher calldata voucher) internal view returns (address) {
        bytes32 digest = _hash(voucher);
        return ECDSA.recover(digest, voucher.signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;
pragma abicoder v2;

// import wappier abstract contracts
import "./WPEIP712.sol";
import "./WPERC721.sol";

import "@openzeppelin/contracts/security/Pausable.sol";
import { ListingTypes, Listing, DutchAuctionListingData } from "./types/WappierStructs.sol";
import { IMarketplaceManager } from "./interfaces/IMarketplaceManager.sol";

abstract contract WP721Marketplace is WPEIP712, WPERC721, Pausable {
    IMarketplaceManager wappierManager;
    /** @dev Royalty Percentage tax*/
    // uint256 private royaltyPercentageTax = 0;

    //Mappings
    /** @dev Mapping from address to the pending withdrawal balance */
    mapping(address => uint256) pendingWithdrawals;
    /** @dev Mapping from voucher ID to whether exists or not */
    mapping(string => bool) public voucherIdExists;
    using Counters for Counters.Counter;

    /**
     * @dev Initializes the contract by by calling the constructors of the inherited contracts.
     *
     * @param minter The address that will have the minter role
     * @param baseURI The base URI automatically added as a prefix in tokenURI to each token’s URI, or to the token ID if no specific URI is set for that token ID.
     * @param collectionName The collection name
     * @param collectionSymbol The collection symbol
     * @param domainName The domain name
     * @param signatureVersion The signature version
     */
    constructor(
        address payable minter,
        string memory baseURI,
        string memory collectionName,
        string memory collectionSymbol,
        string memory domainName,
        string memory signatureVersion,
        address managerAddr
    )
        WPERC721(minter, baseURI, collectionName, collectionSymbol)
        WPEIP712(domainName, signatureVersion)
    {
        wappierManager = IMarketplaceManager(managerAddr);
        _setupRole(MINTER_ROLE, managerAddr);
    }

    /**
     * @dev Mints `++wappierCounter` token and transfers it to the caller.
     *
     * It creates the `WappierNFT` struct and calls `_mintNFT()`.
     *
     * Requirements:
     * - The caller must have `MINTER_ROLE`.
     * - `_name` must not exist.
     *
     * Emits a {Mint} event.
     *
     * @param _name The name of the token.
     */
    function mintWappier(string calldata _name, uint256 requestId) external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Sender has not minter role");
        require(!tokenNameExists[_name], "This token name already exists");

        _mintNFT(
            WappierNFT(0, _name, payable(msg.sender), payable(msg.sender), payable(address(0))),
            requestId
        );
    }

    /**
     * @dev Returns whether `tokenId` exists by calling ERC721 `_exists()`.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     *
     * @param _tokenId The token ID.
     * @return true if `_tokenId` token exists, otherwise false.
     */
    function getTokenExists(uint256 _tokenId) external view whenNotPaused returns (bool) {
        return _exists(_tokenId);
    }

    /**
     * @dev Transfers `tokenId` from current owner `sendTo` to the caller and
     * sends `msg.value` of ethers to the `sendTo`.
     *
     * It creates the `WappierNFT` struct and calls `_mintNFT()`.
     *
     * Requirements:
     * - The caller cannot be the zero address.
     * - `tokenId` must exist.
     * - The caller cannot be the owner of the token.
     * - The sending value `msg.value` of ethers should be greater or equal than the `listing.price`.
     * - The token must be for sale.
     *
     * @param _tokenId The token ID to transfer.
     */
    function buyToken(uint256 _tokenId) external payable whenNotPaused {
        address tokenOwner = ownerOf(_tokenId);
        require(tokenOwner != msg.sender, "Sender address is same as the token owner");
        uint256 listingId = wappierManager.tokenToListing(_tokenId);
        require(wappierManager.listingIdExists(listingId), "No Listing exists for this token");
        Listing memory listing = wappierManager.getListingById(listingId);
        require(msg.value >= listing.price, "Insufficient funds to buy token");
        require(
            listing.expiresAt > block.timestamp && listing.startAt <= block.timestamp,
            "Token listing has expired or not started"
        );
        //Q: this is a correct message? -> maybe we should inform the user that the token is no longer "part" to that listing.
        require(!wappierManager.isTokenSold(listing.listingId, _tokenId), "Token is not for sale");

        // get that token from all wappiers mapping and create a memory of it defined as (struct => Wappier)
        WappierNFT memory wappier = allWappierNFTs[_tokenId];
        // get owner of the token
        address payable sendTo = wappier.currentOwner;
        // update the token's previous owner
        wappier.previousOwner = wappier.currentOwner;
        // update the token's current owner
        wappier.currentOwner = payable(msg.sender);
        // update the how many times this token was transfered
        wappier.numberOfTransfers += 1;

        wappierManager.updateTokenSold(listing.listingId, _tokenId);
        wappierManager.deleteTokenToListingById(_tokenId);

        // set and update that token in the mapping
        allWappierNFTs[_tokenId] = wappier;

        //TODO: commented out for now to be within limit - royalties will be refactored
        // uint256 ethToTransfer = _calculateRoyaltyTax(wappier, msg.value);

        // transfer the token from owner to the caller of the function (buyer)
        _safeTransfer(tokenOwner, msg.sender, _tokenId, "");

        // send token's worth of ethers to the owner
        // sendTo.transfer(ethToTransfer);
        sendTo.transfer(msg.value);
    }

    /**
     * @dev Redeems an `NFTVoucher` for an actual NFT, minting `++wappierCounter` token and transfering it
     * first to the `signer` and then to the caller, using Dutch auction style.
     *
     * It verifies the `voucher` by getting the `signer`, creates the `WappierNFT` struct,
     * makes `voucher.id` as exists, calls `_mintNFT()` and
     * increases the pending withdrawal balance of the `signer` by `msg.value`.
     *
     * Requirements:
     * - `voucher.tokenName` must not exist.
     * - `voucher.id` must not exist.
     * - The caller must be the `voucher.eligibleWallet`.
     * - `voucher.listingId` must exist.
     * - `voucher.listingId` struct must be active.
     * - The current datetime must be before `voucher.expires_at` datetime.
     * - The current datetime must be before `auction.expiresAt` datetime.
     * - The current datetime must be after `auction.startAt` datetime.
     * - `msg.value` must be greater or equal than `voucher.price`.
     * - `signer` must have `MINTER_ROLE`.
     *
     * Emits a {Mint} event.
     *
     * @param voucher A signed `NFTVoucher` that describes the token to be redeemed.
     */
    function redeemVoucher(NFTVoucher calldata voucher, uint256 requestId)
        external
        payable
        whenNotPaused
    {
        require(!voucherIdExists[voucher.id], "This Voucher id already exists");
        require(wappierManager.listingIdExists(voucher.listingId), "Listing does not exist");
        require(block.timestamp <= voucher.expires_at, "Voucher has expired");

        // make sure signature is valid and get the address of the signer

        address signer = _verify(voucher);
        require(hasRole(MINTER_ROLE, signer), "Signature invalid or unauthorized");
        require(
            voucher.eligibleWallet == msg.sender,
            "You are not eligible to redeem this voucher"
        );
        // make sure that the signer is authorized to mint NFTs
        require(
            msg.value >= voucher.price * voucher.tokenNames.length,
            "Insufficient funds to redeem voucher"
        );

        Listing memory listing = wappierManager.getListingById(voucher.listingId);
        require(listing.isLazy, "Listing is not lazy");
        require(listing.active, "Listing is inactive");
        require(
            block.timestamp < listing.expiresAt && block.timestamp > listing.startAt,
            "Listing expired or not started"
        );
        require(
            voucher.tokenNames.length <= listing.transactionLimit,
            "Voucher tokens > transactionLimit"
        );
        require(
            wappierManager.listingUserLimits(msg.sender, voucher.listingId) +
                voucher.tokenNames.length <=
                listing.userLimit,
            "User limit exceeded"
        );
        // require(
        //     listingTokenIds[listing.listingId].length + voucher.tokenNames.length <=
        //         listing.maxMintAmount,
        //     "All tokens minted"
        // );
        if (listing.listingType == ListingTypes.NORMAL) {
            require(voucher.price == listing.price, "Voucher price != listing price");
        }

        voucherIdExists[voucher.id] = true;

        // record payment to signer's withdrawal balance
        pendingWithdrawals[signer] += msg.value;

        wappierManager.updateListingLimits(msg.sender, voucher.listingId, voucher.tokenNames.length);

        for (uint256 index = 0; index < voucher.tokenNames.length; index++) {
            require(!tokenNameExists[voucher.tokenNames[index]], "Token name already exists");

            //update listing with lazy minted token
            wappierManager.pushTokenIdInListing(listing.listingId,_currTokenId.current());

            wappierManager.updateTokenSold(listing.listingId, _currTokenId.current());

            _mintNFT(
                WappierNFT(
                    1,
                    voucher.tokenNames[index],
                    payable(signer),
                    payable(msg.sender),
                    payable(signer)
                ),
                requestId
            );
            // transfer the token to the redeemer
            _safeTransfer(signer, msg.sender, _currTokenId.current(), "");
        }
    }

    /**
     * @dev Transfers all pending withdrawal balance to the caller. Reverts if the caller is not an authorized minter.
     *
     * It gets the amount of ethers to be transfered by `pendingWithdrawals` mapping and transfers the amout.
     *
     * Requirements:
     * - The caller must have the MINTER ROLE.
     *
     */
    function withdraw() external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can withdraw");

        // IMPORTANT: casting msg.sender to a payable address is only safe if ALL members of the minter role are payable addresses.
        address payable receiver = payable(msg.sender);

        uint256 amount = pendingWithdrawals[receiver];
        // zero account before transfer to prevent re-entrancy attack
        pendingWithdrawals[receiver] = 0;
        receiver.transfer(amount);
    }

    /**
     * @dev Retuns the amount of Ether available to the caller to withdraw via `pendingWithdrawals` mapping.
     * @return The pending withdrawal balance of the caller.
     */
    function availableToWithdraw() external view whenNotPaused returns (uint256) {
        return pendingWithdrawals[msg.sender];
    }

    /**
     * @dev Sets the `royaltyPercentageTax`.
     *
     * Requirements:
     * - Only authorized minters can set royalty percentage.
     * - `_percentage` must be below 100.
     *
     * @param _percentage The new percentage assigned to `royalyPecentageTax`.
     */
    //TODO: commented out for now to be within limit - royalties will be refactored
    // function setRoyaltyPercentage(uint256 _percentage) external {
    //     require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can set royalty");
    //     require(_percentage < 100, "Percentage must be bellow 100");

    //     royaltyPercentageTax = _percentage;
    // }

    /**
     * @dev Retuns the `royaltyPercentageTax`.
     *
     * Requirements:
     * - Only authorized minters can get royalty percentage.
     *
     * @return (uint256) The `royaltyPercentageTax`.
     */

    //TODO: commented out for now to be within limit - royalties will be refactored
    // function getRoyaltyPercentage() external view returns (uint256) {
    //     require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minters can get royalty");
    //     return royaltyPercentageTax;
    // }

    /**
     * @dev Triggers stop state.
     *
     * Requirements:
     * - The contract must not be paused.
     * - Only authorized minter role can pause
     *
     */
    function pause() external whenNotPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minter role can pause");
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     * - The contract must be paused.
     * - Only authorized minter role can pause
     *
     */
    function unpause() external whenPaused {
        require(hasRole(MINTER_ROLE, msg.sender), "Only authorized minter role can unpause");
        _unpause();
    }

    /**
     * @dev Calculates the royalty tax given `wappier` `WappierNFT` struct and `ethToTransfer`.
     *
     * If `royaltyPercentageTax` is set and `wappier.numberOfTransfers` is greater that 2, that is the case when the creator of the
     * token has a royalty amount of ether for each token's ownership transfer. The percentage is calculated using the `royaltyPercentageTax`.
     * The calculated `tax` is added to token's creator (`wappier.mintedBy`) `pendingWithdrawals`.
     *
     * @param wappier The WappierNFT to calculate royalty tax for.
     * @param ethToTransfer The msg.value eth to transfer.
     *
     * @return (uint256) The eth to transfer decremented by calculated `tax`, if it is the case.
     */

    //TODO: commented out for now to be within limit - royalties will be refactored
    // function _calculateRoyaltyTax(WappierNFT memory wappier, uint256 ethToTransfer)
    //     internal
    //     returns (uint256)
    // {
    //     if (royaltyPercentageTax > 0 && wappier.numberOfTransfers >= 2) {
    //         uint256 tax = uint256((int256(ethToTransfer) * int256(royaltyPercentageTax)) / 100);
    //         pendingWithdrawals[wappier.mintedBy] += tax;
    //         return uint256(int256(ethToTransfer) - int256(tax));
    //     }
    //     return ethToTransfer;
    // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}