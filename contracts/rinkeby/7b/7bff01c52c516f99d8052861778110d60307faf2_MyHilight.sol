/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

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

// File: MyHilight.sol


pragma solidity >= 0.7.0 < 0.9.0;



contract MyHilight {
    // States
    IERC20 token;
    address private owner;

    // Constructor
    constructor(address _token) {
        token = IERC20(_token);
        owner = msg.sender;
    }

    // Enums
    enum ListingStatus { Active, Sold, Delisted }

    // Structs
    struct Listing { ListingStatus status; address seller; address collection; uint nftID; uint price; }

    // Events
    event Listed( uint listingID, address seller, address collection, uint nftID, uint price );

    event Sale( uint listingID, address buyer, address collection, uint nftID, uint price );

    event Delist( uint listingID, address seller );

    uint private _listingID = 0;
	mapping(uint => Listing) private _listings;

    // Modifiers
    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Token: Functions
    function getUserTokenBalance() public view returns(uint256) { 
       return token.balanceOf(msg.sender);
    }

    function approveTokens(uint256 _tokenAmount) public {
       token.approve(address(this), _tokenAmount);
    }

    function getAllowance() public view returns(uint256) {
       return token.allowance(msg.sender, address(this));
    }

    function getContractTokenBalance() public OnlyOwner view returns(uint256) {
       return token.balanceOf(address(this));
    }

    // Marketplace: Functions
    function listNFT(address collection, uint nftID, uint price) public {
		IERC721(collection).transferFrom(msg.sender, address(this), nftID);

		Listing memory listing = Listing(
			ListingStatus.Active,
			msg.sender,
			collection,
			nftID,
			price
		);

		_listingID++;

		_listings[_listingID] = listing;

		emit Listed(
			_listingID,
			msg.sender,
			collection,
			nftID,
			price
		);
	}

    function getListing(uint listingID) public view returns (Listing memory) {
		return _listings[listingID];
	}

    function buyNFT(uint listingID, uint256 _tokenAmount) public {
		Listing storage listing = _listings[listingID];

		require(msg.sender != listing.seller, "MSG: Seller cannot be buyer");
		require(listing.status == ListingStatus.Active, "MSG. Listing is not active");

        approveTokens(_tokenAmount);
        
        require(_tokenAmount >= getAllowance(), "MSG: Tokens are not approved");
		require(_tokenAmount >= listing.price, "MSG: Insufficient funds");        

        token.transferFrom(msg.sender, owner, _tokenAmount * 5 / 100);
        token.transferFrom(msg.sender, listing.seller, _tokenAmount * 95 / 100);

		listing.status = ListingStatus.Sold;

		IERC721(listing.collection).transferFrom(address(this), msg.sender, listing.nftID);

		emit Sale(
			listingID,
			msg.sender,
			listing.collection,
			listing.nftID,
			listing.price
		);
	}

    function delistNFT(uint listingID) public {
		Listing storage listing = _listings[listingID];

		require(msg.sender == listing.seller, "MSG: Only seller can cancel listing");
		require(listing.status == ListingStatus.Active, "MSG: Listing is not active");

		listing.status = ListingStatus.Delisted;
	
		IERC721(listing.collection).transferFrom(address(this), msg.sender, listing.nftID);

		emit Delist(listingID, listing.seller);
	}

    function withdraw() public payable OnlyOwner {
        token.transferFrom(address(this), owner, token.balanceOf(address(this)));
    }
}