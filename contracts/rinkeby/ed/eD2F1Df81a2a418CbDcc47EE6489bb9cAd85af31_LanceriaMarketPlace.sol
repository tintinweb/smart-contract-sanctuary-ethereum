/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: contracts/Marketplace.sol


pragma solidity 0.8.13;




contract LanceriaMarketPlace is Ownable{
  enum ListingStatus {
		NoExist,
		FixedSale,
		Auction
	}

  // Structs
	struct Listing {
		ListingStatus status;
		address seller;
		IERC721 collection;
		uint tokenId;
		uint price;  // bottom bid price for Auction listing
    uint endtime;
	}

  //events
  event ListingCreated(
    address seller,
    IERC721 collection,
    uint256 tokenId,
    uint256 price,
    uint256 endTime,
    uint8 listingType
  );

  event ListingClosed(
    address seller,
    IERC721 collection,
    uint256 tokenId,
    uint8 listingType
  );

  event ListingPurchased(
    address seller, 
    address buyer, 
    IERC721 collection,
    uint256 tokenId,
    uint256 price,
    uint8 listingType
  );

  event CollectionApproChanged(
    IERC721 collection,
    bool approved
  );
  
  IERC20 public paymentToken;
  address public moderator;
  address public treasury; // wallet address which will get 10% fee for non-registered collection trading. 
  uint256 public feeRate = 100; // over 1000 => 10%

  string public constant name = 'LanceriaMarketplace';
  bytes32 public DOMAIN_SEPARATOR;
  // keccak256("set(address sender,address collection,uint tokenId,uint bidPrice)");
  bytes32 public constant SET_TYPEHASH = 0x9f6cb673c2aa78d532a869115bb2e64877ad3417c373fb9d6df4c4bfb1a29039;

  mapping(IERC721 => mapping(uint256 => Listing)) public listings; // order book
  mapping(IERC721 => bool) public wCollections; // whitelisted collections by marketplace admin

  constructor(
    IERC20 _token,
    address _moderator,
    address _treasury
  ) public {
    paymentToken = _token;
    moderator = _moderator;
    treasury = _treasury;

    uint chainId;
    assembly {
      chainId := chainid()
    }
    DOMAIN_SEPARATOR = keccak256(
      abi.encode(
        keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
        keccak256(bytes(name)),
        keccak256(bytes('1')),
        chainId,
        address(this)
      )
    );
  }

  function listToken(
    IERC721 _collection, 
    uint256 _tokenId, 
    uint256 _price,
    ListingStatus _type,
    uint256 _endTime
  ) external 
    onlyApprovedCollection(_collection)
  {
    // if auction opening, check endtime 
    if (_type == ListingStatus.Auction) {
      require(_endTime > block.timestamp, 'not_valid_timestamp');
    }

    // transfer NFT from user wallet to marketplace
    _collection.transferFrom(msg.sender, address(this), _tokenId);
    // update listing state
    Listing memory listing = Listing(
			_type,
			msg.sender,
			_collection,
			_tokenId,
			_price,
      _endTime
		);

    listings[_collection][_tokenId] = listing;

    // emit Event
    emit ListingCreated(
      msg.sender,
      _collection,
      _tokenId,
      _price,
      _endTime,
      uint8(_type)
    );
  }

  function closeListing(IERC721 _collection, uint256 _tokenId) external {
    // check if a Sale is opened
    Listing storage listing = listings[_collection][_tokenId];
    uint8 _type = uint8(listing.status);
    require(listing.status != ListingStatus.NoExist, 'sale_not_exist');

    // check if the caller is creator
    require(listing.seller == msg.sender, 'not_sale_creator');

    // remove sale from state
    delete listings[_collection][_tokenId];

    // refund NFT to the seller
    _collection.transferFrom(address(this), msg.sender, _tokenId);

    emit ListingClosed(msg.sender, _collection, _tokenId, _type);
  }

  function purchase(IERC721 _collection, uint256 _tokenId) external {
    // check if a Sale is opened
    Listing storage listing = listings[_collection][_tokenId];
    require(listing.status == ListingStatus.FixedSale, 'sale_not_exist');

    // check if the caller is creator
    require(listing.seller != msg.sender, 'self_purchase_not_allowed');

    uint256 price = listing.price;
    address seller = listing.seller;

    // remove sale from state
    delete listings[_collection][_tokenId];

    _purchase(_collection, _tokenId, price, seller, msg.sender);

    emit ListingPurchased(seller, msg.sender, _collection, _tokenId, price, 1);
  }

  function claimAuction(
    IERC721 _collection,
    uint256 _tokenId,
    uint256 _price,
    address _buyer,
    bytes calldata _userSign,
    bytes calldata _moderatorSign
  ) external {
    // check if an Auction is opened
    Listing storage listing = listings[_collection][_tokenId];
    require(listing.status == ListingStatus.Auction, 'auction_not_exist');

    // check if price is higher than bottom price
    require(_price >= listing.price, 'price_too_low');

    // check if auction endtime was passed
    require(block.timestamp > listing.endtime, 'auction_not_ended');

    // check user signature really valid
    bytes32 messageA = keccak256(
      abi.encodePacked(
        '\x19\x01',
        DOMAIN_SEPARATOR,
        keccak256(abi.encode(SET_TYPEHASH, _buyer, _collection, _tokenId, _price))
      )
    );

    require(recoverSigner(messageA, _userSign) == _buyer, 'user_sign_not_valid');

    // valid moderator signature
    bytes32 messageB = prefixed(keccak256(abi.encodePacked(
      _userSign
    )));

    require(recoverSigner(messageB, _moderatorSign) == moderator, 'moderator_sign_not_valid');

    address seller = listing.seller;
    // remove sale from state
    delete listings[_collection][_tokenId];

    _purchase(_collection, _tokenId, _price, seller, _buyer);

    emit ListingPurchased(seller, _buyer, _collection, _tokenId, _price, 2);
  }
  
  function updateModerator(address _moderator) external onlyOwner {
    moderator = _moderator;
  }

  function updateWhitelistCollection(IERC721 _collection, bool _whitelisted) external onlyOwner {
    if (_whitelisted != wCollections[_collection]) {
      wCollections[_collection] = _whitelisted;

      emit CollectionApproChanged(_collection, _whitelisted);
    }
  }

  function updateTreasury(address _treasury) external onlyOwner {
    treasury = _treasury;
  }

  function updatePaymentToken(IERC20 _token) external onlyOwner {
    paymentToken = _token;
  }

  function updatePlatformFee(uint256 _rate) external onlyOwner {
    require(_rate <= 300, 'to high tax'); // max fee 30%
    feeRate = _rate;
  }

  function _purchase(
    IERC721 _collection,
    uint256 _tokenId, 
    uint256 _price,
    address _seller,
    address _buyer
  ) internal {
    
    // Apply  10% fee
    uint256 fee = _price / 10;
    paymentToken.transferFrom(_buyer, treasury, fee);
    paymentToken.transferFrom(_buyer, _seller, _price - fee);
  
    
    // transfer NFT form marketplace to buyer
    _collection.transferFrom(address(this), _buyer, _tokenId);
  }

  modifier onlyApprovedCollection(IERC721 _collection) {
    require(wCollections[_collection], 'collection_not_approved');
    _;
  }

  // utility functions for message signature
  // --------------------------------------
  function prefixed(bytes32 hash) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(
      '\x19Ethereum Signed Message:\n32', 
      hash
    ));
  }

  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address)
  {
    uint8 v;
    bytes32 r;
    bytes32 s;
  
    (v, r, s) = splitSignature(sig);
  
    return ecrecover(message, v, r, s);
  }

  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32)
  {
    require(sig.length == 65);
  
    bytes32 r;
    bytes32 s;
    uint8 v;
  
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  
    return (v, r, s);
  }
}