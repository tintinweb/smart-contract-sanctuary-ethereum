/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

//SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)


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

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)


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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)



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

// File: @openzeppelin/contracts/interfaces/IERC1155.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)



// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: IERC1155Minter.sol




interface IERC1155Minter is IERC1155,IERC2981{
    function getArtist(uint256 tokenId) external view returns (address);
    function burn(address from, uint256 id, uint256 amounts) external; 
    function mint(address to, uint256 tokenId, uint256 amount, uint256 _royaltyFraction, string memory uri,bytes memory data)external;
    function _isExist(uint256 tokenId) external returns (bool);
    
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)



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

// File: @openzeppelin/contracts/interfaces/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)



// File: IERC721Minter.sol




interface IERC721Minter is IERC721,IERC2981{
    function mint(address to, uint256 tokenId, uint256 royaltyFraction, string memory _uri)external;
    function burn(uint256 tokenId) external;
    function _isExist(uint256 tokenId)external view returns(bool);
    function isApprovedOrOwner(address spender, uint256 tokenId)external view returns(bool);
    function getArtist(uint256 tokenId)external view returns(address);
}
// File: Market.sol



contract EpikoMarketplace is Ownable{
    using Counters for Counters.Counter;
    Counters.Counter private _itemids;
    Counters.Counter private _itemSold;
    Counters.Counter private _auctionItemIds;
    Counters.Counter private _auctionItemSold;
    Counters.Counter private _tokenIds;

    address private _nftAddress;
    address private _batchNftAddress;

    IERC20 private _erc20Token;
    IERC1155Minter private _erc1155Token;
    IERC721Minter private _erc721Token;

    uint256 private _buyTax  = 110;//divide by 100
    uint256 private _sellTax = 110;//divide by 100

    struct ItemForSellOrForAuction{
        uint256 tokenId;
        uint256 startTime;
        uint256 endTime;
        uint256 basePrice;
        uint256 highestBid;
        uint256 amount;//quantity
        uint256 time;
        address seller;
        address highestBidder;
        address[] bidders;
        bool cancelled;
        bool sold;
        bool onSell;
        bool onAuction;
    }
 
    modifier onlySellerOrOwner (uint256 tokenId, address user) {
        ItemForSellOrForAuction storage sell = _itemOnSellAuction[tokenId][user];

        require((sell.seller == msg.sender) || owner() == msg.sender, "Market: Only seller or owner can cancel sell");

        _;
    }

    modifier checkTokenAmount (uint256 tokenId, uint256 amount) {
        require(tokenId <= _tokenIds.current(), "Market: not valid tokenId");

         if(_erc721Token._isExist(tokenId)){
            require(amount == 1, "Market: Amount must be one");

        }else if(_erc1155Token._isExist(tokenId)){
            require(amount > 0, "Market: Amount must be greater than 0");
        
        }else{
            revert ("Market: Token not Exists");
        }

        _;
    }

    //mapping to track item is on sell or auction
    mapping (uint256 => mapping (address => ItemForSellOrForAuction)) private _itemOnSellAuction;
    //mapping to track seller address
    mapping (uint256 => address) _sellerAddress;
    //mapping for bidders address
    mapping(uint256 => mapping (address => uint256)) fundsByBidder;
    //Mapping for royalty fee for artist
    mapping (address => uint256) private _royaltyForArtist;
    //Mapping for seller balance
    mapping (address => uint256) private _sellerBalance;
    //mapping from uri to bool
    mapping (string => bool) public _isUriExist;

    event MarketItemCreated(uint256 tokenId, address seller, uint256 price);
    event PlaceBid(address bidder, uint256 price);
    event Buy(address seller, address buyer, uint256 tokenId);
    event ApproveBid(address seller, address bidder, uint256 price);
    event AuctionCreated(uint256 auctionId, uint256 tokenId, address seller, uint256 price);

    constructor(address ERC721Address, address ERC1155Address, address ERC20Address){
        require(ERC721Address != address(0), "ERC721: address Zero provided");
        require(ERC1155Address != address(0), "ERC1155: address Zero provided");
        require(ERC20Address != address(0), "ERC20: address Zero provided");

        _erc721Token = IERC721Minter(ERC721Address);
        _erc1155Token = IERC1155Minter(ERC1155Address);
        _erc20Token = IERC20(ERC20Address);
    }

    /* Mint nft */
    function mint(uint256 amount, uint256 royaltyFraction, string memory uri, bool isErc721) external {

        require(amount > 0, "Market: amount zero provided");
        require(royaltyFraction <= 10000, "Market: invalid royaltyFraction provided");
        require(_isUriExist[uri] != true, "Market: uri already exist");

        address _user = msg.sender;
        if (isErc721) {
            require(amount == 1, "Market: amount must be 1");

            _tokenIds.increment();
            _erc721Token.mint(_user, _tokenIds.current(), royaltyFraction, uri);

        }else{
            require(amount > 0, "Market: amount must greater than 0");

            _tokenIds.increment();
            _erc1155Token.mint(_user, _tokenIds.current(), amount, royaltyFraction, uri, "0x00");
        }
        _isUriExist[uri] = true;
    }
    
    /* Burn nft (only contract Owner)*/
    function burn(uint256 tokenId) external onlyOwner {
        require(tokenId <= _tokenIds.current(), "Market: Not valid tokenId");

        _erc721Token.burn(tokenId);
    }

    /* Burn nft (only contract Owner)*/
    function burn(address from, uint256 tokenId, uint256 amount) external onlyOwner {
        require(tokenId <= _tokenIds.current(), "Not valid tokenId");

        _erc1155Token.burn(from, tokenId, amount);
    }

    /* Places item for sale on the marketplace */
    function sellitem(uint256 tokenId, uint256 amount, uint256 price) external checkTokenAmount(tokenId, amount) {

        require (tokenId <= _tokenIds.current(), "Market: Not valid tokenId");
        require(price > 0,"Market: Price must be greater than 0");

        address owner;
        address seller = msg.sender;
        
        _itemids.increment();

        ItemForSellOrForAuction storage sellItem = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            require ( _erc721Token.isApprovedOrOwner(address(this), tokenId), "Market: tokenId not approved to sell" );
            require (sellItem.onSell == false, "Market: Already on sell");
            require (sellItem.onAuction == false, "Market: Already on auction");
            require (sellItem.endTime < block.timestamp, "Market: Already on auction");
            
            owner = _erc721Token.getArtist(tokenId);

            _addItemtoSell(tokenId, price, 1 , seller);

            _sellerAddress[tokenId] = msg.sender;

            sellItem.onSell = true;
            sellItem.cancelled = false;

        } else if(_erc1155Token._isExist(tokenId)){

            require(_erc1155Token.isApprovedForAll(seller,address(this)), "Market: tokenId not approved to sell");
            require(amount <= _erc1155Token.balanceOf(seller,tokenId), "Market: Not Enough balance");
            require (sellItem.onSell == false, "Market: Already on sell");
            require (sellItem.onAuction == false, "Market: Already on auction");
            require (sellItem.endTime < block.timestamp, "Market: Already on auction");
              
            owner = _erc1155Token.getArtist(tokenId);
            _addItemtoSell(tokenId, price, amount, seller);

            _sellerAddress[tokenId] = msg.sender;

            sellItem.onSell = true;
            sellItem.cancelled = false;
    
        }else{
            revert("Token not exist");
        }
        
        emit MarketItemCreated(tokenId, seller, price);

    }

    /* Place buy order for Multiple item on marketplace */
    function buyItem(uint256 tokenId, uint256 amount) external checkTokenAmount(tokenId, amount) {

        require(tokenId <= _tokenIds.current(), "Market: Not valid tokenId");
        
        address buyer = msg.sender;
        address seller = _sellerAddress[tokenId];

        ItemForSellOrForAuction storage sellItem = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            require (sellItem.onSell == true, "Market: tokenId not on sell");
         
            uint256 totalNftValue = sellItem.basePrice * amount;

            (address user, uint256 royaltyAmount) = _erc721Token.royaltyInfo(sellItem.tokenId, totalNftValue);

            _transferTokens(totalNftValue, royaltyAmount, sellItem.seller, buyer, user);
            _erc721Token.transferFrom (sellItem.seller, buyer, sellItem.tokenId);
            
            sellItem.sold = true;
            sellItem.onSell = false;
            
            emit Buy(sellItem.seller, buyer, tokenId);

        }else if(_erc1155Token._isExist(tokenId)){

            require (sellItem.onSell == true, "Market: tokenId not on sell");
            
            uint256 totalNftValue = sellItem.basePrice * amount;

            (address user, uint256 royaltyAmount) = _erc1155Token.royaltyInfo(sellItem.tokenId, totalNftValue);

            _transferTokens(totalNftValue, royaltyAmount, sellItem.seller, buyer, user);
            _erc1155Token.safeTransferFrom(sellItem.seller, buyer, sellItem.tokenId, amount,"");

            sellItem.sold = true;
            sellItem.onSell = false;
            
            emit Buy(sellItem.seller, buyer, tokenId);

        }else{
            revert("Market: Token not exist");
        }

        _itemSold.increment();
    }

    /* Create Auction for item on marketplace */
    function createAuction(uint256 tokenId, uint256 amount, uint256 basePrice, uint256 startTime, uint256 endTime) external checkTokenAmount(tokenId, amount) {

        require (basePrice > 0 ,"Market: BasePrice must be greater than 0");
        require (tokenId <= _tokenIds.current(), "Market: Not valid tokenId");

        address seller = msg.sender;
        
        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)) {

            require (auction.onSell == false, "Market: Already on sell");
            require (auction.onAuction == false, "Market: Already on sell");

            require(_erc721Token.isApprovedOrOwner(seller, tokenId),"Market: not authorised or not owner");
        
            _addItemtoAuction(tokenId, amount, basePrice, startTime, endTime, seller);

            _sellerAddress[tokenId] = msg.sender;

        }else if(_erc1155Token._isExist(tokenId)){

            require (auction.onSell == false, "Market: Already on sell");
            require (auction.onAuction == false, "Market: Already on sell");
            require(_erc1155Token.isApprovedForAll(seller, address(this)), "Market: not authorised or not owner");
            require(amount <= _erc1155Token.balanceOf(seller, tokenId), "Market: Insufficient balance");
        
            _addItemtoAuction(tokenId, amount, basePrice, startTime, endTime, seller);

            _sellerAddress[tokenId] = msg.sender;

        }else{
            revert("Market: Token not Exist");
        }

        emit AuctionCreated(_auctionItemIds.current(), tokenId, seller, basePrice);

    }

    /* Place bid for item  on marketplace */
    function placeBid(uint256 tokenId, uint256 price) external  {
        address seller = _sellerAddress[tokenId];
        
        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)) {

            require(price >= auction.basePrice && price > auction.highestBid, "Market: palce highest bid");
            require(auction.seller != msg.sender, "Market: seller not allowed");
            require(_erc20Token.allowance(msg.sender, address(this)) >= price, "Market: please proivde asking price");

            if(auction.highestBid > 0) {
                _erc20Token.transfer(auction.highestBidder, auction.highestBid);
            }

            _erc20Token.transferFrom(msg.sender,address(this), price);            
            fundsByBidder[tokenId][msg.sender] = price;
            auction.bidders.push(msg.sender);

        } else if(_erc1155Token._isExist(tokenId)){

            require(price >= auction.basePrice && price > auction.highestBid, "Market: palce highest bid");
            require(auction.seller != msg.sender, "Market: seller not allowed");
            require(_erc20Token.allowance(msg.sender, address(this)) >= price, "Market: please proivde asking price");
            
            if(auction.highestBid > 0) {
                _erc20Token.transfer(auction.highestBidder, auction.highestBid);
            }

            _erc20Token.transferFrom(msg.sender,address(this), price);
            fundsByBidder[tokenId][msg.sender] = price;
            auction.bidders.push(msg.sender);


        } else {
            revert ("Market: Token not exist");
        }
        
        emit PlaceBid(msg.sender, price);
        
    }
    
    /* To Approve bid*/
    function approveBid(uint256 tokenId, address bidder) external {
        require (tokenId <= _tokenIds.current(),"Market: not valid id");
        require (bidder != address(0), "Market: Please enter valid address");
        require (fundsByBidder[tokenId][bidder] !=0, "Market: bidder not found");
        uint256 bidderValue = fundsByBidder[tokenId][bidder];
        address seller = _sellerAddress[tokenId];

        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            require(auction.seller == msg.sender, "Market: not authorised");
            require(auction.tokenId == tokenId, "Market: Auction not found");

            (address user,uint256 amount) = _erc721Token.royaltyInfo(auction.tokenId, bidderValue);

            _approveBid(bidderValue, amount, auction.seller, user);
            _erc721Token.transferFrom(auction.seller, bidder, auction.tokenId);

            auction.sold = true;
            auction.onAuction = false;
            _auctionItemSold.increment();

            emit ApproveBid(auction.seller, bidder, bidderValue);

        } else if(_erc1155Token._isExist(tokenId)){

            require(auction.seller == msg.sender, "Market: not authorised");
            require(auction.tokenId == tokenId, "Market: Auction not found");

            (address user,uint256 amount) = _erc1155Token.royaltyInfo(auction.tokenId, bidderValue);

            _approveBid(bidderValue, amount, auction.seller, user);
            _erc1155Token.safeTransferFrom(auction.seller, bidder, auction.tokenId, auction.amount, "");

            auction.sold = true;
            auction.onAuction = false;
            _auctionItemSold.increment();

            emit ApproveBid(auction.seller, bidder, bidderValue);
        } else {
            revert ("Market: Token not exist");
        }
    }

    /* To cancel Auction */
    function cancelAuction(uint256 tokenId) external onlySellerOrOwner (tokenId, msg.sender) {
        require (tokenId == _tokenIds.current(), "Market: not valid id");
        address seller = _sellerAddress[tokenId];

        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            _cancelAuction(auction, tokenId);

            auction.cancelled = true;
            auction.onAuction = false;

            delete _sellerAddress[tokenId];


        } else if(_erc1155Token._isExist(tokenId)) {
            
            _cancelAuction(auction, tokenId);

            auction.cancelled = true;
            auction.onAuction = false;

            delete _sellerAddress[tokenId];

        } else {
            revert ("Market: Token not exist");
        }
    }

    /* To cancel sell */
    function cancelSell(uint256 tokenId) external onlySellerOrOwner (tokenId, msg.sender) {
        require (tokenId <= _tokenIds.current(), "Market: not valid id");

        address seller = _sellerAddress[tokenId];

        ItemForSellOrForAuction storage sell = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            _cancelSell(sell, tokenId);

            sell.cancelled = true;
            sell.onSell = false;

            delete _sellerAddress[tokenId];

        } else if(_erc1155Token._isExist(tokenId)) {
            
            _cancelSell(sell, tokenId);

            sell.cancelled = true;
            sell.onSell = false;

            delete _sellerAddress[tokenId];

        } else {
            revert ("Market: Token not exist");
        }
        
    }

    /* To cancel auction bid */
    function cancelBid(uint256 tokenId) external {
        require(tokenId <= _tokenIds.current(), "Market: not valid id");
        require(fundsByBidder[tokenId][msg.sender] > 0, "Market: not bided on auction");

        // address seller = _sellerAddress[tokenId];

        // ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

           fundsByBidder[tokenId][msg.sender] = 0;
           _erc20Token.transfer(msg.sender, fundsByBidder[tokenId][msg.sender]);

        } else if(_erc1155Token._isExist(tokenId)) {
            
            fundsByBidder[tokenId][msg.sender] = 0;
           _erc20Token.transfer(msg.sender, fundsByBidder[tokenId][msg.sender]);

        } else {
            revert ("Market: Token not exist");
        }
        
    }

    /* To check list of bidder */
    function checkBidderList(uint256 tokenId) external view returns (address[] memory){
        require (tokenId <= _tokenIds.current(), "Market: not valid id");

        address seller = _sellerAddress[tokenId];
        
        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][seller];
        
        if(_erc721Token._isExist(tokenId)){

            require(auction.tokenId == tokenId,"Market: Auction not found");

            return auction.bidders;

        } else {            
            require(auction.tokenId == tokenId,"Market: Auction not found");
            
            return auction.bidders;

        }

    }

    function listOFItemOnMarket(uint256 tokenId) 
        external
        view 
        returns
        (
            uint256 _id, 
            uint256 _startTime, 
            uint256 _endTime,
            uint256 _price, 
            uint256 _quantity,
            uint256 _time, 
            address _seller, 
            bool _cancelled, 
            bool _sold,
            bool _onSell, 
            bool _onAuction
        )
     {
        require (tokenId <= _tokenIds.current(), "Market: tokenId not valid");
        
        address seller = _sellerAddress[tokenId];
        require (seller != address(0), "Market: seller not found");

        ItemForSellOrForAuction memory item = _itemOnSellAuction[tokenId][seller];
        
        _id = item.tokenId;
        _startTime =  item.startTime;
        _endTime = item.endTime;
        _price = item.basePrice;
        _quantity = item.amount;
        _time = item.time;
        _seller = item.seller;
        _cancelled = item.cancelled;
        _sold = item.sold;
        _onSell = item.onSell;
        _onAuction = item.onAuction;    
    }

    /* To Withdraw roaylty amount (only Creator) */
    function withdrawRoyaltyPoint(uint256 amount) external{
        require(_royaltyForArtist[msg.sender]!=0, "Market: Not Enough balance to withdtraw");
        require(amount <= _royaltyForArtist[msg.sender], "Market: Amount exceed total royalty Point");

        _erc20Token.transfer(msg.sender, amount);
        _royaltyForArtist[msg.sender] -= amount;
    }

    /* To transfer nfts from `from` to `to` */
    function transfer(address from, address to, uint256 tokenId, uint256 amount) external checkTokenAmount(tokenId, amount){
        require(to != address(0), "Market: Transfer to zero address");
        require(from != address(0), "Market: Transfer from zero address");
        require(tokenId <= _tokenIds.current(), "Market: Not valid tokenId");

        address _seller = _sellerAddress[tokenId];
        ItemForSellOrForAuction storage sellOrAuction = _itemOnSellAuction[tokenId][_seller];
        
        require(sellOrAuction.onSell ||  sellOrAuction.onAuction, "Market: Item on sell or auciton");

        if(_erc721Token._isExist(tokenId)){
            _erc721Token.transferFrom(from, to, tokenId);
        
        }else if(_erc1155Token._isExist(tokenId)){
            _erc1155Token.safeTransferFrom(from, to, tokenId, amount,"");
        }
    }

    function fetchNftOwner(uint256 tokenId) external view returns(address owner){
        require(tokenId <= _tokenIds.current(), "Market: Not valid tokenId");
        if(_erc721Token._isExist(tokenId)){
            return _erc721Token.ownerOf(tokenId);
        }else{
            revert("Market: tokenId not exist");
        }
    }

    /* owner can set selltax(fees) */
    function setSellTax(uint256 percentage) external onlyOwner{
        require(percentage >= 10000, "Market: percentage must be less than 100");
        _sellTax = percentage;
    }

    /* owner can set buytax(fees) */
    function setBuyTax(uint256 percentage) external onlyOwner{
        require(percentage >= 10000, "Market: percentage must be less than 100");
        _buyTax = percentage;
    }

    function _transferTokens (uint256 price, uint256 royaltyAmount, address _seller, address _buyer, address royaltyReceiver) private {
        uint256 amountForOwner;
        uint256 buyingValue = price + (((price * _sellTax) / 100) / 100) ;

        require(_erc20Token.allowance(_buyer,address(this)) >= buyingValue, "Market: please proivde asking price");

        uint256 amountForSeller = price - (((price * _buyTax)/ 100) / 100);
        
        amountForOwner = buyingValue - amountForSeller;
        
        _erc20Token.transferFrom(msg.sender,address(this), buyingValue);
        _erc20Token.transfer(owner(), amountForOwner);
        _erc20Token.transfer(_seller, amountForSeller);
        
        _royaltyForArtist[royaltyReceiver] += royaltyAmount;
    }

    function _approveBid (uint256 price, uint256 _amount, address _seller, address royaltyReceiver) private {
        
        uint256 amountForOwner;
        uint256 amountForSeller = price - (((price * (_buyTax + _sellTax))/ 100) / 100);
        
        amountForOwner = price - amountForSeller;
        
        _erc20Token.transfer(owner(), amountForOwner);
        _erc20Token.transfer(_seller, amountForSeller);
        
        _royaltyForArtist[royaltyReceiver] += _amount;
    }

    function _addItemtoAuction(uint256 tokenId, uint256 _amount, uint256 basePrice, uint256 startTime, uint256 endTime, address _seller) private {
        _auctionItemIds.increment();

        ItemForSellOrForAuction storage auction = _itemOnSellAuction[tokenId][_seller];

        auction.tokenId = tokenId;
        auction.basePrice = basePrice;
        auction.seller = _seller;
        auction.amount = _amount;
        auction.time = block.timestamp;
        auction.startTime = startTime;
        auction.endTime = endTime;
        auction.onAuction = true;
        auction.cancelled = false;
    }

    function _addItemtoSell(uint256 tokenId, uint256 price, uint256 amount, address _seller) private {

        ItemForSellOrForAuction storage sell = _itemOnSellAuction[tokenId][_seller];

        sell.tokenId = tokenId;
        sell.basePrice = price;
        sell.seller = _seller;
        sell.amount = amount;
        sell.time = block.timestamp;
        
    }

    function _cancelSell (ItemForSellOrForAuction memory sell, uint256 tokenId) private pure{

        require(sell.tokenId == tokenId, "Market: sell not found");
        require(sell.sold == false, "Market: already sold");
        require(sell.cancelled == false, "Market: Sell already Cancelled");

    }

    function _cancelAuction (ItemForSellOrForAuction memory auction, uint256 tokenId) private { 

        require(auction.tokenId == tokenId, "Market: auction not found");
        require(auction.onAuction == true, "Market: auction not found");
        require(auction.startTime <= block.timestamp, "Market: Auction not started");
        require(auction.endTime > block.timestamp, "Market: Auction ended");
        require(auction.cancelled == false, "Market: auction already cancelled");
        require(auction.sold == false, "Market: Already sold");

        if(auction.highestBid > 0){
            _erc20Token.transfer(auction.highestBidder, auction.highestBid);
        }
    }

    function checkRoyalty(address user) public view returns (uint256) {
        require(user != address(0), "Market: address zero provided");

        return _royaltyForArtist[user];
    } 
}