/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

/**
 *Submitted for verification at Etherscan.io on 2023-02-22
*/

// SPDX-License-Identifier: MIXED

// Sources flattened with hardhat v2.9.0 https://hardhat.org

// File @openzeppelin/contracts/utils/introspection/[email protected]

// License-Identifier: MIT

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


// File @openzeppelin/contracts/token/ERC721/[email protected]

// License-Identifier: MIT

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

    function mint(address _to) external;

    function _setTokenRoyalty(uint256 tokenId,address recipient,uint256 value) external;

    function royaltyInfo(uint256 tokenId,uint256 value) 
    external 
    view 
    returns (address receiver, uint256 royaltyAmount);
}


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT

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


// File @openzeppelin/contracts/access/[email protected]

// License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


// File @openzeppelin/contracts/utils/[email protected]

// License-Identifier: MIT

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


// File contracts/interfaces/IMarketplaceERC721ETH.sol

pragma solidity ^0.8.0;

interface IMarketplaceERC721ETH {

    event NewListing(uint256 indexed listId, uint256 indexed tokenId, address indexed seller, uint256 price, address currency, uint256 timestamp);
    event Sold(uint256 indexed tokenId, address indexed seller, address indexed buyer, uint256 price, address currency, uint256 timestamp);
    event PriceChanged(address indexed nft, address indexed setter, uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice);
    event ListingCanceled(address indexed nft, uint256 indexed tokenId);
    event NftSet(address indexed nft, address setter);

    function list(uint256 tokenId, uint256 price) external;

    function buy(uint256 tokenId) external payable;

}


// File contracts/interfaces/IBunzz.sol

pragma solidity ^0.8.0;

interface PkToken {

    function connectToOtherContracts(address[] calldata contracts) external;
}


// File contracts/MarketplaceERC721ETH.sol

pragma solidity ^0.8.0;





contract PKNFTMarketplaceERC721 is
    Ownable,
    IMarketplaceERC721ETH,
    PkToken
{
    using Counters for Counters.Counter;
    Counters.Counter private lastListingId;

    address public nft;

    struct Listing {
        address currency;
        uint256 tokenId;
        uint256 price;
        bool isSold;
        bool exist;
    }
    
     struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => uint256) public tokensListing;
    mapping(uint256 => RoyaltyInfo) public royalties;

    modifier onlyItemOwner(uint256 tokenId) {
        isItemOwner(tokenId);
        _;
    }

    modifier onlyTransferApproval(uint256 tokenId) {
        isTransferApproval(tokenId);
        _;
    }

    function isItemOwner(uint256 tokenId) internal view {
        IERC721 token = IERC721(nft);
        require(
            token.ownerOf(tokenId) == _msgSender(),
            "Marketplace: Not the item owner"
        );
    }

    function isTransferApproval(uint256 tokenId) internal view {
        IERC721 token = IERC721(nft);
        require(
            token.getApproved(tokenId) == address(this),
            "Marketplace: Marketplace is not approved to use this tokenId"
        );
    }

    function connectToOtherContracts(address[] calldata contracts)
        external
        override
        onlyOwner
    {
        setNFTContract(contracts[0]);
    }

    function setNFTContract(address _nft) internal {
        require(
            nft == address(0),
            "Marketplace: NFT contract address can only be set one time"
        );
        nft = _nft;
        emit NftSet(_nft, msg.sender);
    }

    function list(uint256 tokenId, uint256 price)
        external
        override
        onlyItemOwner(tokenId)
        onlyTransferApproval(tokenId)
    {
        lastListingId.increment();
        uint256 listingId = lastListingId.current();

        require(
            tokensListing[tokenId] == 0,
            "Marketplace: the token is already listed"
        );

        IERC721(nft).safeTransferFrom(msg.sender,address(this),tokenId);

        tokensListing[tokenId] = listingId;

        Listing memory newListing = Listing(
            address(0),
            tokenId,
            price,
            false,
            true
        );

        listings[listingId] = newListing;

        emit NewListing(
            listingId,
            tokenId,
            msg.sender,
            price,
            address(0),
            block.timestamp
        );
    }

    function createSale(uint256 price,uint256 royalty)
        external
    {
        IERC721(nft).mint(address(this));
        uint256 tokenId = IERC721(nft).balanceOf(
            address(this)
        );
        // set royalty if any
        if(royalty > 0) {
            IERC721(nft)._setTokenRoyalty(tokenId,msg.sender,royalty);
        }
        lastListingId.increment();
        uint256 listingId = lastListingId.current();

        require(
            tokensListing[tokenId] == 0,
            "Marketplace: the token is already listed"
        );

        tokensListing[tokenId] = listingId;

        Listing memory newListing = Listing(
            address(0),
            tokenId,
            price,
            false,
            true
        );

        listings[listingId] = newListing;

        emit NewListing(
            listingId,
            tokenId,
            msg.sender,
            price,
            address(0),
            block.timestamp
        );
    }

    function buy(uint256 tokenId) external payable override {
        Listing memory _list = listings[tokensListing[tokenId]];
        IERC721 token = IERC721(nft);
        address tokenOwner = token.ownerOf(tokenId);
        require(
            _list.price == msg.value,
            "Marketplace: The sent value doesn't equal the price"
        );
        require(_list.isSold == false, "Marketplace: item is already sold");
        require(
            _list.currency == address(0),
            "Marketplace: item currency is not the native one"
        );
        require(
            tokenOwner != msg.sender,
            "Marketplace: seller has the same address as buyer"
        );
        require(_list.exist == true, "Marketplace: list does not exist");
        
        listings[tokensListing[tokenId]].isSold = true;

        emit Sold(
            tokenId,
            tokenOwner,
            msg.sender,
            msg.value,
            address(0),
            block.timestamp
        );
        clearStorage(tokenId);
        token.safeTransferFrom(tokenOwner, msg.sender, tokenId, "");

        // get royalty info
        (address royaltyReceiver, uint256 royaltyAmount) = token.royaltyInfo(tokenId, 0);
        uint256 royaltyAmt = 0;
        uint256 totalAmt = msg.value;
        if(royaltyAmount > 0){
            royaltyAmt = (msg.value * royaltyAmount) / 10000;
            totalAmt = totalAmt - royaltyAmt;
            // transfer royalty
            payable(royaltyReceiver).transfer(msg.value);
        }
        payable(tokenOwner).transfer(totalAmt);
    }

    function changePrice(uint256 tokenId, uint256 newPrice) external onlyItemOwner(tokenId){
        Listing storage _list = listings[tokensListing[tokenId]];
        require(_list.isSold == false, "Marketplace: item is already sold");
        require(_list.price != newPrice, "Marketplace: newPrice is the same as old price");
        require(_list.exist == true, "Marketplace: list does not exist");
        emit PriceChanged(nft, msg.sender, tokenId, _list.price, newPrice);
        _list.price = newPrice;
    }

    function cancelListing(uint256 tokenId) external onlyItemOwner(tokenId){
        clearStorage(tokenId);
        emit ListingCanceled(nft, tokenId);
    }

    function clearStorage(uint256 tokenId) internal {
        delete listings[tokensListing[tokenId]];
        delete tokensListing[tokenId];
    }
}