/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// SPDX-License-Identifier: MIT
// Author iBlockchainer (Telegram)

pragma solidity ^0.8.7;

interface IBEP721{
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

    function tokenURI(uint256 tokenId) external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IPancakeRouter02 {
    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

contract NFTMarketplace{

    struct nft{
        uint256 listId;
        address firstOwner;
        address currentOwner;
        uint256 salePrice;
        uint256 saleType; //1: Instant Sale, 2: Auction Sale
        address contractAddress;
        uint256 tokenId;
        uint256 listDuration;
        uint256 status; //1: listed, 2: sold, 3: cancelled
        uint256 listedTime;
    }

    mapping (uint256 => nft) public nfts;
    mapping(address => mapping(uint256 => uint256)) public listIdMapping;
    mapping(address => uint256) public listedNFTCounter;

    function listNFT(address _contractAddress, uint256 _tokenId, uint256 _salePrice) external returns (bool){
        IBEP721 token = IBEP721(_contractAddress);

        require(msg.sender == token.ownerOf(_tokenId),'You are not the owner of this NFT');
        require(_salePrice > 0,'Sale price should be greater than 0');
        require(listIdMapping[_contractAddress][_tokenId] == 0,'This NFT is already listed');
        require(token.getApproved(_tokenId) == address(this),'Marketplace has no approval for this NFT');
        
        uint256 listId = ++listedNFTCounter[_contractAddress];
        listIdMapping[_contractAddress][_tokenId] = listId;
        listedNFTCounter[_contractAddress] = listId;

        nft memory listing_nft = nfts[listId];

        listing_nft.firstOwner = msg.sender;

        //uint256 list_id = _listId;
        uint256 listed_time = block.timestamp;
        listing_nft.listId = listId;
        listing_nft.currentOwner = msg.sender;
        listing_nft.salePrice = _salePrice;
        listing_nft.saleType = 1;
        listing_nft.status = 1;
        listing_nft.tokenId = _tokenId;
        listing_nft.contractAddress = _contractAddress;
        listing_nft.listedTime = listed_time;

        nfts[listId] = listing_nft;

        return true;
    }

    function cancelListing(address _contractAddress, uint256 _tokenId) external {
        IBEP721 token = IBEP721(_contractAddress);

        require(msg.sender == token.ownerOf(_tokenId),'You are not the owner of this NFT');
        uint256 listId = listIdMapping[_contractAddress][_tokenId];
        
        nft memory listing_nft = nfts[listId];
        
        require(listing_nft.status == 1,'This NFT listing can not be cancelled');
        listIdMapping[_contractAddress][_tokenId] = 0;
        listing_nft.status = 3;
        nfts[listId] = listing_nft;
    }

    function buyNFT(address _contractAddress, uint256 _tokenId) public payable returns (bool){
        uint256 listId = listIdMapping[_contractAddress][_tokenId];
        nft memory listed_nft = nfts[listId];

        IBEP721 token = IBEP721(listed_nft.contractAddress);
        require(listed_nft.status != 3,'This listing is cancelled');
        require(listed_nft.status != 2,'This listing is sold');
        require(listed_nft.status == 1,'Expired or Invalid listing');
        require(msg.value >= listed_nft.salePrice,'Price is less than sale price');

        address seller_owner = token.ownerOf(_tokenId);
        token.transferFrom(listed_nft.currentOwner,msg.sender,listed_nft.tokenId);
        
        listIdMapping[listed_nft.contractAddress][listed_nft.tokenId] = 0;

        listed_nft.status = 2;
        listed_nft.currentOwner = msg.sender;

        nfts[listId] = listed_nft;

        payable(seller_owner).transfer(listed_nft.salePrice);
        
        return true;
    }

    function getListedNFTId(address _contractAddress, uint256 _tokenId) external view returns(uint256){
        return (listIdMapping[_contractAddress][_tokenId]);
    }

    function getNFTAddressAndTokenidByListID(uint256 _listId) external view returns(address, uint256){
        nft memory listed_nft = nfts[_listId];
        return (listed_nft.contractAddress, listed_nft.tokenId);
    }

    function getListedNFTDetails(uint256 _listId) external view returns(address, uint256, uint256, uint256, uint256){
        nft memory listed_nft = nfts[_listId];
        require(listed_nft.listedTime > 0,'Invalid List Id');
        return (listed_nft.currentOwner, listed_nft.tokenId, listed_nft.salePrice, listed_nft.listedTime, listed_nft.status);
    }

    function getNFTowner(address _contractAddress, uint256 _tokenId) external view returns(address){
        IBEP721 token = IBEP721(_contractAddress);
        return token.ownerOf(_tokenId);
    }

    function getNFTUri(address _contractAddress, uint256 _tokenId) external view returns(string memory){
        IBEP721 token = IBEP721(_contractAddress);
        return token.tokenURI(_tokenId);
    }

    function getNFTTotalSupply(address _contractAddress) external view returns(uint256){
        IBEP721 token = IBEP721(_contractAddress);
        return token.totalSupply();
    }
}