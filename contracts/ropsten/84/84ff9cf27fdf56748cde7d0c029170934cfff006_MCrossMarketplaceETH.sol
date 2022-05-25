/**
 *Submitted for verification at Etherscan.io on 2022-05-25
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

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: contracts/MCrossMarketplaceEthereumChain.sol


pragma solidity ^0.8.9;




contract MCrossMarketplaceETH is Ownable {
    enum ListingStatus {
		Active,
		Sold,
		Cancelled
	}

    address private nftContract;
    address private creatorWallet;

    uint256 private itemCount = 0;
    uint256 private rateServiceFee = 3;
    uint256 private rateCreatorFee = 10;

    struct MarketItem {
        address nftContract;
        uint256 tokenId;
        address owner;
        uint256 price;
        ListingStatus status;
    }

    // List of all market items 
	uint256[] private marketitems;
    // Mapping between token id and their struct
    mapping(uint256 => MarketItem) private tokenIdMarketItems;

    event List(
        address nftContract,
        uint256 tokenId,
        address owner,
        uint256 price,
        ListingStatus status
    );

    event Sale(
        address nftContract,
        uint256 tokenId,
        address owner,
        address buyer,
        uint256 price,
        ListingStatus status
    );

    event Cancel(
        uint256 tokenId,
        address owner
    );

    constructor(
        address _nftContract,
        address _creatorWallet
    ){
        nftContract = _nftContract;
        creatorWallet = _creatorWallet;
    }

    function listItems(uint _tokenId, uint256 price) external {
        require(price > 0, "price must be at least 1 wei");
        require(_tokenId > 0, "token id must greater than 0");

        MarketItem memory item = tokenIdMarketItems[_tokenId];
        if(item.tokenId == _tokenId || item.status == ListingStatus.Sold){
            tokenIdMarketItems[_tokenId].price = price;
            tokenIdMarketItems[_tokenId].owner = msg.sender;
            tokenIdMarketItems[_tokenId].status = ListingStatus.Active;
        } else {
            item = MarketItem(
                nftContract,
                _tokenId,
                msg.sender,
                price,
                ListingStatus.Active
            );
            marketitems.push(_tokenId);
            tokenIdMarketItems[_tokenId] = item;
            itemCount++;
        }

        IERC721(nftContract).transferFrom(item.owner, address(this), item.tokenId);
        emit List(item.nftContract, _tokenId, msg.sender, price, item.status);
    }

    function getAllMarketItems() external view returns(MarketItem[] memory){
        MarketItem[] memory  items = new MarketItem[](itemCount);

        for(uint256 i = 0; i < marketitems.length; i++) {
            uint256 _tokenId = marketitems[i];
            items[i] = tokenIdMarketItems[_tokenId];
        }

        return items;
    }

    function getMyMarketplace(address _owner) external view returns(MarketItem[] memory) {
        MarketItem[] memory items = new MarketItem[](itemCount);

        for(uint i = 0; i < marketitems.length; i++) {

            uint256 _tokenId = marketitems[i];

            if(
                tokenIdMarketItems[_tokenId].owner == _owner && 
                tokenIdMarketItems[_tokenId].status == ListingStatus.Active
            ){
                items[i] = tokenIdMarketItems[_tokenId];
            }
        }
        return items;
    }

    function cancelListItem(uint _tokenId) external {
        require(tokenIdMarketItems[_tokenId].tokenId > 0, "item not exists");
        MarketItem storage item = tokenIdMarketItems[_tokenId];
        
        require(item.status == ListingStatus.Active, "item must be active");
        require(msg.sender == item.owner, "cancel not allow");
        
        tokenIdMarketItems[_tokenId].status = ListingStatus.Cancelled;

        IERC721(item.nftContract).transferFrom(address(this), item.owner, item.tokenId);
        emit Cancel (_tokenId, item.owner);
    }

    function calculateItemFee(uint256 price) public view returns(uint256, uint256) {
        uint256 serviceFee = price * rateServiceFee / 100;
        uint256 creatorFee = (price - serviceFee) * rateCreatorFee / 100;
        uint256 sellerRecieve = price - serviceFee - creatorFee;
        return (creatorFee, sellerRecieve);
    }

    function buyMarketItem(uint _tokenId) external payable {
        require(tokenIdMarketItems[_tokenId].tokenId > 0, "item not exists");
        MarketItem storage item = tokenIdMarketItems[_tokenId];

        require(msg.sender != item.owner, "buy own item not allow");
        require(item.status == ListingStatus.Active, "item status is not active");
        require(msg.value == item.price, "Invalid price");

        IERC721(nftContract).transferFrom(address(this), msg.sender, item.tokenId);

        (uint256 creatorFee, uint256 sellerRecieve) = calculateItemFee(item.price);

        payable(creatorWallet).transfer(creatorFee);
        payable(item.owner).transfer(sellerRecieve);

        tokenIdMarketItems[_tokenId].status = ListingStatus.Sold;
        tokenIdMarketItems[_tokenId].owner = item.owner;

        emit Sale(
            item.nftContract,
            item.tokenId,
            item.owner,
            msg.sender,
            item.price,
            item.status
        );
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function bulkTransferERC721() external onlyOwner {
        for(uint256 i = 0; i < marketitems.length; i++) {
            uint256 _tokenId = marketitems[i];
            
            MarketItem memory item = tokenIdMarketItems[_tokenId];

            tokenIdMarketItems[_tokenId].status = ListingStatus.Cancelled;
            IERC721(nftContract).safeTransferFrom(address(this), item.owner, _tokenId);
        }
    }

    function setNftContract(address _newNFTContract) external onlyOwner {
        nftContract = _newNFTContract;
    }

    function getNftContract() external onlyOwner view returns(address) {
        return nftContract;
    }

    function setCreatorWallet(address _creatorWallet) external onlyOwner {
        creatorWallet = _creatorWallet;
    }

    function getCreatorWallet() external onlyOwner view returns(address) {
        return creatorWallet;
    }
}