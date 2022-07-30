// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// Contract @title: Pluto Pawn
/// Contract @author: Stinky (@nomamesgwei)
/// Description @dev: Pluto Pawn is an unadited prototype in development by Degen Dwarfs, DYOR before using.
/// Version @notice: 0.69

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IKerberusVault } from "./Interfaces/IKerberusVault.sol";
import { Listing } from "./Structs/Listing.sol";
import { Offer } from "./Structs/Offer.sol";

contract PlutoPawn is Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    /// @notice Counter for number of Listings
    Counters.Counter public listingCounter;
    /// @notice Loan Grace Period
    uint256 public gracePeriod = 12 hours;
    /// @dev KerberusVault Contract address
    address private kerberusContract;
    /// @notice Job History stored by jobId
    mapping(uint256 => Listing) public listings;
    /// @notice Status of Open
    bool public pawnOpen;
    /// @notice Length of maximum loan period measured in days
    uint256 public maxLoanPeriod;    
    /// @notice Array of Offers
    mapping(uint256 => mapping(uint256 => Offer)) public offers;
    /// @notice Mapping of Blacklisted ERC-721/1155 contracts
    mapping(address => bool) public nftBlacklist;
    /// @notice Mapping of Whitelisted ERC-20 token contracts
    mapping(address => bool) public tokenWhitelist;

    bytes4 private constant INTERFACE_ERC1155 = 0xd9b67a26;
    bytes4 private constant INTERFACE_ERC721 = 0x80ac58cd;    

    error Blacklisted();
    error InactiveListing();  
    error InvalidCollateral();
    error InvalidInterestRate();
    error InvalidLoanAmount();
    error InvalidLoanRequest();
    error InvalidSigner();     
    error InvalidOfferId();     
    error ListingActive();
    error ListingExpired();
    error PawnNotOpen();    
    error NotAuthorized();
    error NotListingCreator();
    error NotOfferCreator();
    error NotWhitelisted(); 

    /// @notice Declare Listing Created Event
    event ListingCreated(
        uint256 _id,
        address _creator,
        address _tokenAddress
    );

    /// @notice Declare Listing Deleted Event
    event ListingDeleted(
        address indexed _creator,
        uint256 indexed _creationDate,
        address _nftAddress
    );

    /// @notice Declare Listing Accepted Event
    event ListingAccepted(
        uint256 _id,
        address _lender,
        address _tokenAddress,
        uint256 _amount
    );

    /// @notice Declare Updated Protocol Value Event
    event UpdatedValue(
        bytes14 changeType,
        uint256 oldValue,
        uint256 newValue
    );

    /// @notice Construct PlutoPawn Contract
    /// @param kerberus Kerberus Contract Address
    constructor(address kerberus) {
        kerberusContract = kerberus;
        maxLoanPeriod = 366;
        pawnOpen = true;        
    }

    ///@notice Accept a Listing and create loan
    ///@param listingId the Job ID Number
    function acceptListing(uint256 listingId) external nonReentrant {
        if(!pawnOpen) revert PawnNotOpen();
        Listing memory listing = listings[listingId];
        if(!listing.isActive){ revert InactiveListing(); }
        if(_hasExpired(listingId, listing.listDate, listing.creator, listing.tokenAddress)){ revert ListingExpired();}
        if(!listing.isActive){ revert InactiveListing(); }
        if(!_verifyOwnership(listing.creator, listing.nftAddress, listing.nftId)){ revert InvalidCollateral(); }
        if(IERC20(listing.tokenAddress).balanceOf(_msgSender()) < listing.loanAmount){ revert InvalidLoanAmount(); }

        listings[listingId].isActive = false;
        emit ListingAccepted(listingId, _msgSender(), listing.tokenAddress, listing.loanAmount);

        if(listing.signer != _msgSender() && listing.signer != address(0))
        {
            revert NotAuthorized();
        } 
    
        IKerberusVault(kerberusContract).createLoan(
            listing.creator,
            _msgSender(),
            listing.tokenAddress,
            listing.loanAmount,
            listing.loanLength,
            listing.nftAddress,
            listing.nftId,
            listing.interestRate
        );
    }

    /// @notice Listing creator can accept counter offers
    /// @param listingId Listing Id number
    /// @param offerId Offer Id number
    function acceptOffer(uint256 listingId, uint256 offerId) external nonReentrant {
        if(!pawnOpen) { revert PawnNotOpen(); }       
        if(offerId == 0) revert InvalidOfferId();        
        Listing memory listing = listings[listingId];
        if(!listing.isActive){ revert InactiveListing(); }
        if(listing.signer != address(0)) { revert NotAuthorized(); }        
        if(_hasExpired(listingId, listing.listDate, listing.creator, listing.tokenAddress)){ revert ListingExpired();}
        Offer memory offer = offers[listingId][offerId];

        listings[listingId].isActive = false;
        if(!_verifyOwnership(listing.creator, listing.nftAddress, listing.nftId)){ revert InvalidCollateral(); }
        if(IERC20(listing.tokenAddress).balanceOf(offer.Lender) < listing.loanAmount){ revert InvalidLoanAmount(); }

        emit ListingAccepted(listingId, _msgSender(), listing.tokenAddress, listing.loanAmount);

        IKerberusVault(kerberusContract).createLoan(
            listing.creator,
            offer.Lender,
            offer.tokenAddress,
            offer.loanAmount,
            offer.loanLength,
            listing.nftAddress,
            listing.nftId,
            offer.interestRate
        );
    }

    /// @notice Cancel an open listing
    /// @param listingId Listing Id number
    function cancelListing(uint256 listingId) external nonReentrant {
        Listing memory listing = listings[listingId];
        if(!listing.isActive){ revert InactiveListing(); }        
        if(listing.creator != _msgSender()){ revert NotListingCreator(); }
        delete listings[listingId];
    }

    /// @notice Cancel an offer
    /// @param listingId Listing Id number    
    /// @param offerId Offer Id number
    function cancelOffer(uint256 listingId, uint256 offerId) external nonReentrant {
        Listing memory listing = listings[listingId];
        if(!listing.isActive){ revert InactiveListing(); }
        if(listing.signer != address(0)) { revert NotAuthorized(); }        
        Offer memory offer = offers[listingId][offerId];
        if(offer.Lender != _msgSender()){ revert NotOfferCreator(); }
        delete offers[listingId][offerId];
        listings[listingId].offerCount--;
    }

    /// @notice Send a counter offer to a specific active listing
    /// @param listingId The listing you are counter offering
    /// @param loanAmount Amount of Tokens to be loaned
    /// @param loanLength Length of the loan in days
    /// @param interestRate interest rate charged on loanAmount
    /// @param token The address for the token being loaned
    function counterOffer(
        uint256 listingId,
        uint256 loanAmount,
        uint256 loanLength,
        uint256 interestRate,
        address token
    ) external nonReentrant {
        if(loanAmount == 0) revert InvalidLoanAmount();
        if(interestRate == 0) revert InvalidInterestRate();
        if(loanLength == 0 || loanLength >= maxLoanPeriod) revert InvalidLoanRequest();        
        Listing memory listing = listings[listingId];
        if(listing.signer != address(0)) { revert NotAuthorized(); }
        if(!listing.isActive){ revert InactiveListing(); }
        if(_hasExpired(listingId, listing.listDate, listing.creator, listing.tokenAddress)){ revert ListingExpired();}        
        if(IERC20(listing.tokenAddress).balanceOf(_msgSender()) < loanAmount){ revert InvalidLoanAmount(); }

        listing.offerCount++;
        Offer storage newOffer = offers[listingId][listing.offerCount];
        newOffer.Lender = _msgSender();
        newOffer.loanAmount = loanAmount;
        newOffer.interestRate = interestRate;
        newOffer.loanLength = loanLength;
        newOffer.tokenAddress = token;

        listings[listingId] = listing;
    }

    /// @notice Create a listing for a Loan Request
    /// @param token ERC-20 Address
    /// @param loanAmount Loan amount in wei
    /// @param loanLength Days to repay loan
    /// @param nft Address of NFT
    /// @param tokenId tokenId of NFT
    /// @param interestRate loan interest rate
    /// @param signer the address you are directly offering to    
    function createListing(
        address token,
        uint256 loanAmount,
        uint256 loanLength,
        address nft,
        uint256 tokenId,
        uint256 interestRate,
        address signer
    ) external nonReentrant {
        if(!pawnOpen) { revert PawnNotOpen(); }
        if(nftBlacklist[token]) revert Blacklisted();
        if(loanLength == 0 || loanLength >= maxLoanPeriod) revert InvalidLoanRequest();
        if(!tokenWhitelist[token]) revert NotWhitelisted();        
        if(loanAmount <= 0) revert InvalidLoanAmount(); 
        if(!_verifyOwnership(_msgSender(), nft, tokenId)){ revert InvalidCollateral(); }
        uint256 currentId = listingCounter.current();
        Listing storage newListing = listings[currentId];
        newListing.id = currentId;
        newListing.creator = _msgSender();
        newListing.listDate = block.timestamp;
        newListing.isActive = true;
        newListing.loanAmount = loanAmount;
        newListing.tokenAddress = token;
        newListing.loanLength = loanLength;
        newListing.interestRate = interestRate;
        newListing.nftAddress = nft;
        newListing.nftId = tokenId;
        newListing.offerCount = 0;

        if(signer != address(0)) { newListing.signer = signer; }

        listings[currentId] = newListing;
        listingCounter.increment();
        emit ListingCreated(newListing.id, newListing.creator, newListing.tokenAddress);
    } 

    /// @notice Admin team can clear expired listings
    /// @param listingIds array of listing id's to clear
    function clearExpired(uint256[] calldata listingIds) external onlyOwner {
        uint256 length = listingIds.length;
        for (uint i = 0; i < length; ) {
            delete listings[listingIds[i]];
            // Cannot possibly overflow due to IDs size
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Sets the mininum and maximum loan periods
    /// @param max Maximum loan period measured in days
    function setLoanPeriods(uint256 max) external onlyOwner nonReentrant {
        emit UpdatedValue("MaxLoanPeriod", maxLoanPeriod, max);           
        maxLoanPeriod = max;
    }

    /// @notice Whitelists multiple ERC-20 tokens
    /// @dev This is done to control the tokens being used on the platform
    /// @param tokens List of token addresses
    function setWhitelist(address[] calldata tokens) external onlyOwner nonReentrant {
        uint256 length = tokens.length;
        for (uint i = 0; i < length; ) {
            tokenWhitelist[tokens[i]] = true;
            // Cannot possibly overflow due to size of array
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Blacklist multiple Collateral NFTs
    /// @dev NFT Pawn Ticket should to be blacklisted
    /// @param nfts List of NFT addresses
    function setBlacklist(address[] calldata nfts) external onlyOwner nonReentrant {
        uint256 length = nfts.length;
        for (uint i = 0; i < length; ) {
            nftBlacklist[nfts[i]] = true;
            // Cannot possibly overflow due to size of array
            unchecked {
                ++i;
            }
        }
    }

    /// @notice Toggles the pawn status from on/off
    function togglePawnOpen() external onlyOwner {
        if(pawnOpen)
            emit UpdatedValue("ListingStatus", 1, 0);
        else
            emit UpdatedValue("ListingStatus", 0, 1);        
        pawnOpen = !pawnOpen;
    }

    /// @notice Upgrade the Kerberus Vault Contract
    /// @param kerberus New Kererus Contract Address
    function upgradeContracts(address kerberus) external onlyOwner {
        kerberusContract = kerberus;
    }

    /// @notice Update the listing grace period
    /// @param time How long the grace period should be
    function UpgradeGracePeriod(uint256 time) external onlyOwner {
        emit UpdatedValue("GracePeriod", gracePeriod, time);        
        gracePeriod = time;
    }

    /// @notice Check if a listing has expired
    /// @dev Will delete a listing if expired
    /// @param id listing ID
    /// @param creationDate Datetime of creation
    /// @param creator Address of Listing Creator
    /// @param nft Address of NFT
    function _hasExpired(
        uint256 id,
        uint256 creationDate,
        address creator,
        address nft
    ) internal returns (bool expired) {
        // if listing expired without being filled, delete it.
        if (block.timestamp > creationDate + gracePeriod) {
            expired = true;
            delete listings[id];

            emit ListingDeleted(creator, creationDate, nft);
        }
    }

    /// @notice Verify ownership of the NFT collateral
    /// @param nftOwner Addres of owner in question
    /// @param nft Address of NFT
    /// @param tokenId tokenId of NFT
    function _verifyOwnership(
        address nftOwner,
        address nft,
        uint256 tokenId
    ) internal view returns (bool verified) {
        if(IERC721(nft).supportsInterface(INTERFACE_ERC721))
         {        
            //Verify ownership of ERC721
            if(IERC721(nft).ownerOf(tokenId) == nftOwner)
                return true;
         }

        if(ERC165(nft).supportsInterface(INTERFACE_ERC1155))
        {
            if(IERC1155(nft).balanceOf(nftOwner, tokenId) > 0)
                return true;
        }

        return false;
    }    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Loan } from '../Structs/Loan.sol';

interface IKerberusVault {
    /// @notice Create a loan based on accepting listing/offer specs
    /// @dev Loan Length is the only one that is not wei format. If you want a 1 day loan pass 1 not 1000000000000000000
    /// @param _borrow Address of Borrower
    /// @param _lender Address of Lender
    /// @param _token ERC-20 Address
    /// @param _loanAmount Loan amount in wei
    /// @param _loanLength Days to repay loan
    /// @param _nft Address of NFT
    /// @param _tokenId ID of the NFT token 
    /// @param _rate Interest rate on the loan       
    function createLoan(
        address _borrow,
        address _lender,
        address _token,
        uint256 _loanAmount,
        uint256 _loanLength,
        address _nft,
        uint256 _tokenId,
        uint256 _rate
    ) external;

    /// @notice Only the Pawn Ticket NFT holder can call this
    /// @dev Burn ticket NFT and transfer the collateral NFT
    /// @param _id Loan ID #
    function liquidateLoan(uint256 _id) external;

    /// @notice Settle an active loan by paying the amount plus interest
    /// @dev The Loan contract will need to be approved for the specific ERC-20
    /// @param _id Loan ID #
    function settleLoan(uint256 _id) external;

    /// @notice Returns the data for a specific Loan
    function loans(uint256) external view returns (Loan memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Listing {
    // Listing #ID
    uint256 id;
    // Listing Date
    uint256 listDate;
    // Listin creator Address
    address creator;
    // Status
    bool isActive;
    // Token for Loan
    address tokenAddress;
    // Token Loan Amount
    uint256 loanAmount;
    // Loan Length in Days
    uint256 loanLength;
    // Interest Rate
    uint256 interestRate;
    // NFT Collateral
    address nftAddress;
    // NFT ID
    uint256 nftId;
    // Offer Counts
    uint256 offerCount;
    // DirectLoan Signing Address
    address signer;    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

struct Offer {
    // Lenders Address
    address Lender;
    // Loan Length in Days
    uint256 loanLength;
    // Token Loan Amount
    uint256 loanAmount;
    // InterestRate
    uint256 interestRate;
    // tokenAddress
    address tokenAddress;
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
pragma solidity ^0.8.13;

struct Loan {
    // Loan #ID
    uint256 id;
    // Loan Date
    uint256 loanDate;
    // Borrower Address
    address borrower;
    // Lender Address
    address lender;
    // Status
    bool isActive;
    // Token for Loan
    address tokenAddress;
    // Token Loan Amount
    uint256 loanAmount;
    // Interest Rate
    uint256 interestRate;
    // NFT Collateral
    address nftAddress;
    // NFT ID
    uint256 nftId;
    // Loan Expiration
    uint256 expirationDate;
}