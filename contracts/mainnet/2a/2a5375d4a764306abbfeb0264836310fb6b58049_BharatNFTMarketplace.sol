/**
 *Submitted for verification at Etherscan.io on 2022-09-14
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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





// File: @openzeppelin/contracts/utils/Counters.sol

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


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// @author Priyanshu Jain
// File: contracts/NEW.sol










pragma solidity ^0.8.4;


interface BharatNFT721{
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);
    function ownerOf(uint256 tokenId) external view returns (address);
    function getApproved(uint256 tokenId) external view returns (address);
    function totalSupply() external view returns(uint256);
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external ;
}
  
interface BharatNFT1155 {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns(address receiver, uint256 royaltyAmount);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address account, address operator) external view returns (bool);
    function ownerOf(uint256 tokenId) external view  returns (address);
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}


contract BharatNFTMarketplace is Ownable, ReentrancyGuard {


    using Counters for Counters.Counter;      

    Counters.Counter public _listingIds1155;
    
    uint8 public commission = 2;
    

    mapping(uint128 => Listing1155) public idToListing1155;

    // nft => tokenId => list struct
    mapping(address => mapping(uint256 => MarketItem721)) public listNfts;

    // nft => tokenId => offer struct
    mapping(address => mapping(uint256 => Offer)) public offerNfts;

    // nft => tokenId => acuton struct
    mapping(address => mapping(uint256 => tokenDetails721)) public auctionNfts;


    BharatNFT721 private BERC721;   

    BharatNFT1155 private BERC1155;

    IERC20 private BERC20;


    constructor(address _erc721, address _erc1155, address _erc20) {
    
        BERC721 = BharatNFT721(_erc721);
        BERC1155 = BharatNFT1155(_erc1155);
        BERC20 = IERC20(_erc20);
    }


    struct tokenDetails721 {

        address seller;
        uint128 price;
        uint32 duration;
        uint128 maxBid;
        address maxBidUser;
        bool isActive;
        uint128[] bidAmounts;
        address[] users;
    }


    struct MarketItem721 {

        address payable seller;
        uint128 price;
        bool sold;
    }


    struct Listing1155 {

        address nft;
        address seller;
        address[] buyer;
        uint128 tokenId;
        uint128 amount;
        uint128 price;
        uint128 tokensAvailable;
        bool privateListing;
        bool completed;
        uint listingId;
    }


    struct Offer {

        address[] offerers;
        uint128[] offerAmounts;
        address owner;
        bool isAccepted;
    }


    event TokenListed1155(                                                         
        address indexed seller, 
        uint128 indexed tokenId, 
        uint128 amount, 
        uint128 pricePerToken, 
        address[] privateBuyer, 
        bool privateSale, 
        uint indexed listingId
    );


    event TokenSold1155(
        address seller, 
        address buyer, 
        uint128 tokenId, 
        uint128 amount, 
        uint128 pricePerToken, 
        bool privateSale
    );


    event ListingDeleted1155(
        uint indexed listingId
    );


    function getRoyalties721(uint256 tokenId, uint256 price)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = BERC721.royaltyInfo(tokenId, price);
        if (receiver == address(0) || royaltyAmount == 0) {
            return (address(0), 0);
        }
        return (receiver, royaltyAmount);
    }


    function getRoyalties1155(uint256 tokenId, uint256 price)
        private
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = BERC1155.royaltyInfo(tokenId, price);
        if (receiver == address(0) || royaltyAmount == 0) {
            return (address(0), 0);
        }
        return (receiver, royaltyAmount);
    }



//-------------------------------------------------------------------------------ERC721(Offer)-------------------------------------------------------------------------------//

    // First, Bharat token approval is required for making offer.


    function makeOffer(address _nft, uint256 _tokenId, uint128 _offer) external nonReentrant  {

    require(BERC20.allowance(msg.sender, address(this)) >= _offer, "Bharat token not approved");

    Offer storage offer = offerNfts[_nft][_tokenId];

        if (offer.offerers.length == 0) {

            offerNfts[_nft][_tokenId] = Offer({

                offerers: new address[](0),
                offerAmounts: new uint128[](0),
                owner: IERC721(_nft).ownerOf(_tokenId),
                isAccepted: false
            });

            offer.offerers.push(msg.sender);
            offer.offerAmounts.push(_offer);


        } else {

       
        offer.offerers.push(msg.sender);
        offer.offerAmounts.push(_offer);

        }

    }


    //First, NFT approval is required to accept offer.

    function acceptOffer(address _nft, uint256 _tokenId, address _offerer) external nonReentrant {

        require(IERC721(_nft).ownerOf(_tokenId) == msg.sender, "Only the owner is allowed to accept offer");
        
        Offer memory offer = offerNfts[_nft][_tokenId];

        require(!offer.isAccepted, "Already completed");
        require(msg.sender == offer.owner, "Caller is not the seller");
        

        uint256 lastIndex = offer.offerers.length - 1;
        uint128 offerAmount;

        for (uint256 i; i <= lastIndex; i++) {

            if(offer.offerers[i] == _offerer) {

                offerAmount = offer.offerAmounts[i];

            }
        }

        require(BERC20.allowance(_offerer, address(this)) >= offerAmount, "Bharat token not approved");

        offer.isAccepted = true;

        if (address(_nft) == address(BERC721)) {

            (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
            _tokenId,
            offerAmount);

            BERC20.transferFrom(_offerer, offer.owner,  ((offerAmount - royaltyAmount)*(100 - commission))/100);

            BERC20.transferFrom(_offerer, address(this),  ((offerAmount - royaltyAmount)*(commission))/100);

            BERC20.transferFrom(_offerer, royaltyReceiver, royaltyAmount);


        } else {

            BERC20.transferFrom(_offerer, offer.owner,  (offerAmount*(100 - commission))/100);

            BERC20.transferFrom(_offerer, address(this),  (offerAmount*(commission))/100);
        }


        IERC721(_nft).safeTransferFrom(
            offer.owner,
            _offerer,
            _tokenId
        );
        
    }


    function rejectOffer(address _nft, uint256 _tokenId) external nonReentrant {
        
        Offer memory offer = offerNfts[_nft][_tokenId];

        require(msg.sender == offer.owner, "You can't reject offers to this token");
        require(!offer.isAccepted, "Offer already accepted or rejected");

        delete offerNfts[_nft][_tokenId];
    }


    function fetchOffers(address _nft, uint256 _tokenId) public view returns (Offer memory) {
        Offer memory offer = offerNfts[_nft][_tokenId];
        return offer;
    }



//-----------------------------------------------------------------------------ERC721--------------------------------------------------------------------------------//


    //First, NFT needs to be approved.

    function createMarketItem721(address _nft, uint128 _tokenId, uint128 _price)
        external 
        nonReentrant
    {
        require(
            IERC721(_nft).getApproved(_tokenId) == address(this),
           "Market is not approved"
        );

        IERC721 nft = IERC721(_nft);
        require(nft.ownerOf(_tokenId) == msg.sender, "not nft owner");

        listNfts[_nft][_tokenId] = MarketItem721({

            seller: payable(msg.sender),
            price: _price,
            sold: false
        });

    }


    function createMarketSale721(address _nft, uint256 _tokenId)
        external
        payable
        nonReentrant
    {

        require(
            IERC721(_nft).getApproved(_tokenId) == address(this),
           "Market is not approved, cannot sell."
        );

        IERC721 nft = IERC721(_nft);

        MarketItem721 storage listedNft = listNfts[_nft][_tokenId];

        require(msg.sender != listedNft.seller, "Seller can't be buyer");

        require(
        msg.value >= listedNft.price,
            "Please submit the asking price in order to complete the purchase"
        );

        listedNft.sold = true;

        if (address(nft) == address(BERC721)) {

            (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
            _tokenId,
            msg.value);

            (bool success, ) = listedNft.seller.call{value: ((listedNft.price - royaltyAmount)*(100 - commission))/100}("");
            require(success,"Unable to transfer funds to seller");

            (bool success0, ) = royaltyReceiver.call{value: royaltyAmount}("");
            require(success0,"Unable to transfer funds to royalty reciever"); 

        } else {

            (bool success, ) = listedNft.seller.call{value: (listedNft.price*(100 - commission))/100}("");
            require(success,"Unable to transfer funds to seller");
        }

        nft.transferFrom(listedNft.seller, msg.sender, _tokenId);
        
    }


    function cancelMarketItem721(address _nft, uint256 _tokenId)
        external
        nonReentrant
    {

        MarketItem721 storage listedNft  = listNfts[_nft][_tokenId];

        require(!listedNft.sold, "Already sold");

        require(listedNft.seller == msg.sender, "not listed owner");

        delete listNfts[_nft][_tokenId];

    }


    function fetchMarketItem721(address _nft, uint256 _tokenId) public view returns (MarketItem721 memory) {
        MarketItem721 memory listedNft  = listNfts[_nft][_tokenId];
        return listedNft;
    }

    

//------------------------------------------------------------------721 Auction-------------------------------------------------------------------------//



    function createTokenAuction721(
        address _nft,
        uint128 _tokenId,
        uint128 _price,  // In wei and in bharat token
        uint32 _duration
    ) external {

        require(
            IERC721(_nft).getApproved(_tokenId) == address(this),
           "Market is not approved"
        );

        require(msg.sender == IERC721(_nft).ownerOf(_tokenId), "Not the owner of tokenId");
        require(_price > 0, "Price should be more than 0");
        require(_duration > block.timestamp, "Invalid duration value");

        auctionNfts[_nft][_tokenId] = tokenDetails721({

            seller: msg.sender,
            price: uint128(_price),
            duration: _duration,
            maxBid: 0,
            maxBidUser: address(0),
            isActive: true,
            bidAmounts: new uint128[](0),
            users: new address[](0)
        });
        
    }


    function bid721(address _nft, uint256 _tokenId, uint128 _amount) external nonReentrant {

        tokenDetails721 storage auction = auctionNfts[_nft][_tokenId];

        require(_amount >= auction.price, "Bid less than price");
        require(BERC20.allowance(msg.sender, address(this)) >= _amount, "Bharat token not approved");
        require(auction.isActive, "auction not active");
        require(auction.duration > block.timestamp, "Deadline already passed");

        if (auction.bidAmounts.length == 0) {

            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;

        } else {

            uint256 lastIndex = auction.bidAmounts.length - 1;
            require(auction.bidAmounts[lastIndex] < _amount, "Current max bid is higher than your bid");
            auction.maxBid = _amount;
            auction.maxBidUser = msg.sender;

        }

        auction.users.push(msg.sender);
        auction.bidAmounts.push(_amount);
    }


    function executeSale721(address _nft, uint256 _tokenId) external nonReentrant {

        tokenDetails721 storage auction = auctionNfts[_nft][_tokenId];

        require(
            IERC721(_nft).getApproved(_tokenId) == address(this),
           "Market is not approved, cannot sell."
        );

        require(auction.maxBidUser == msg.sender || msg.sender == auction.seller, "You can't buy");
        require(auction.duration <= block.timestamp, "Deadline did not pass yet");
        require(auction.isActive, "auction not active");
        auction.isActive = false;


        if (address(_nft) == address(BERC721)) {

            require(BERC20.allowance(auction.maxBidUser, address(this)) >= auction.maxBid, "Bharat token not approved by bidder");

            (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties721(
                _tokenId,
                auction.maxBid
            );

            BERC20.transferFrom(auction.maxBidUser, auction.seller,  ((auction.maxBid - royaltyAmount)*(100 - commission))/100);

            BERC20.transferFrom(auction.maxBidUser, address(this),  ((auction.maxBid - royaltyAmount)*(commission))/100);

            BERC20.transferFrom(auction.maxBidUser, royaltyReceiver, royaltyAmount);


            BERC721.safeTransferFrom(
                auction.seller,
                auction.maxBidUser,
                _tokenId
            );

        } else {

            require(BERC20.allowance(auction.maxBidUser, address(this)) >= auction.maxBid, "Bharat token not approved by bidder");

            BERC20.transferFrom(auction.maxBidUser, auction.seller,  ((auction.maxBid)*(100 - commission))/100);

            BERC20.transferFrom(auction.maxBidUser, address(this),  ((auction.maxBid)*(commission))/100);

            IERC721(_nft).safeTransferFrom(
                auction.seller,
                auction.maxBidUser,
                _tokenId
            );
        }
    }
    

    function cancelAuction721(address _nft, uint256 _tokenId) external nonReentrant {

        tokenDetails721 storage auction = auctionNfts[_nft][_tokenId];
        
        require(auction.seller == msg.sender, "Not seller");
        require(auction.isActive, "auction not active");
        
        auction.isActive = false;

        delete  auctionNfts[_nft][_tokenId];
    }


    function getTokenAuctionDetails721(address _nft, uint256 _tokenId) public view returns (tokenDetails721 memory) {
        tokenDetails721 memory auction = auctionNfts[_nft][_tokenId];
        return auction;
    }

    receive() external payable {}


//-----------------------------------------------------------------------------ERC1155--------------------------------------------------------------------------------//


    function listToken1155(address _nft, uint128 tokenId, uint128 amount, uint128 price, address[] memory privateBuyer) public nonReentrant returns(uint256) {
        require(amount > 0, "Amount must be greater than 0!");
        require(IERC1155(_nft).balanceOf(msg.sender, tokenId) >= amount, "Caller must own given token!");
        require(IERC1155(_nft).isApprovedForAll(msg.sender, address(this)), "Contract must be approved!");

        bool privateListing = privateBuyer.length>0;
        _listingIds1155.increment();
        uint256 listingId = _listingIds1155.current();
        idToListing1155[uint128(listingId)] = Listing1155(_nft, msg.sender, privateBuyer, tokenId, amount, price, amount, privateListing, false, _listingIds1155.current());


        emit TokenListed1155(msg.sender, tokenId, amount, price, privateBuyer, privateListing, _listingIds1155.current());

        return _listingIds1155.current();
    }


    function purchaseToken1155(uint128 listingId, uint128 amount) public payable nonReentrant {
        
        if(idToListing1155[listingId].privateListing == true) {
            bool whitelisted = false;
            for(uint i=0; i<idToListing1155[listingId].buyer.length; i++){
                if(idToListing1155[listingId].buyer[i] == msg.sender) {
                    whitelisted = true;
                }
            }
            require(whitelisted == true, "Sale is private!");
        }

        require(msg.sender != idToListing1155[listingId].seller, "Can't buy your own tokens!");
        require(msg.value >= idToListing1155[listingId].price * amount, "Insufficient funds!");
        require(IERC1155(idToListing1155[listingId].nft).balanceOf(idToListing1155[listingId].seller, idToListing1155[listingId].tokenId) >= amount, "Seller doesn't have enough tokens!");
        require(idToListing1155[listingId].completed == false, "Listing not available anymore!");
        require(idToListing1155[listingId].tokensAvailable >= amount, "Not enough tokens left!");

        idToListing1155[listingId].tokensAvailable -= amount;
    
        if(idToListing1155[listingId].privateListing == false){

            idToListing1155[listingId].buyer.push(msg.sender);
        }

        if(idToListing1155[listingId].tokensAvailable == 0) {

            idToListing1155[listingId].completed = true;
        }

        if(address(idToListing1155[listingId].nft) == address(BERC1155)) {

            (address royaltyReceiver, uint256 royaltyAmount) = getRoyalties1155(
                idToListing1155[listingId].tokenId,
                idToListing1155[listingId].price
            );


            (bool success, ) = idToListing1155[listingId].seller.call{value: ((idToListing1155[listingId].price - royaltyAmount)*amount*(100 - commission))/100}("");
                require(success, "Unable to transfer funds to seller");

            (bool success0, ) = royaltyReceiver.call{value: royaltyAmount*amount}("");
                require(success0, "Unable to transfer funds to royalty reciever");    

            BERC1155.safeTransferFrom(idToListing1155[listingId].seller, msg.sender, idToListing1155[listingId].tokenId, amount, "");

            emit TokenSold1155(
                idToListing1155[listingId].seller,
                msg.sender,
                idToListing1155[listingId].tokenId,
                amount,
                idToListing1155[listingId].price,
                idToListing1155[listingId].privateListing
            );
        } else {
            
            (bool success, ) = idToListing1155[listingId].seller.call{value: ((idToListing1155[listingId].price)*amount*(100 - commission))/100}("");
                require(success, "Unable to transfer funds to seller");

  

            IERC1155(idToListing1155[listingId].nft).safeTransferFrom(idToListing1155[listingId].seller, msg.sender, idToListing1155[listingId].tokenId, amount, "");
        }

    }


    function deleteListing1155(uint128 _listingId) external nonReentrant{
        require(msg.sender == idToListing1155[_listingId].seller, "Not caller's listing!");
        require(idToListing1155[_listingId].completed == false, "Listing not available!");
        
        idToListing1155[_listingId].completed = true;

        emit ListingDeleted1155(_listingId);
    }


    function viewListing1155(uint128 _listId) public view returns(Listing1155 memory) {
        Listing1155 memory listing = idToListing1155[_listId];
        return listing;
    }
    

//----------------------------------------------------------------------OnlyOwner-------------------------------------------------------------------------------------//


    function withdraw(uint128 _amount) public payable onlyOwner {
        require (_amount < address(this).balance, "Try a smaller amount");
	    (bool success, ) = payable(msg.sender).call{value: _amount}("");
		require(success, "Unable to transfer funds");
	}


    function withdrawAnyToken(address _token, uint128 _amount) public onlyOwner {
        require (IERC20(_token).balanceOf(address(this)) > _amount, "Try a smaller amount");
        IERC20(_token).transfer(msg.sender, _amount);
    }


    function setCommission(uint8 _newRate) external onlyOwner {
        commission = _newRate;
    }

}