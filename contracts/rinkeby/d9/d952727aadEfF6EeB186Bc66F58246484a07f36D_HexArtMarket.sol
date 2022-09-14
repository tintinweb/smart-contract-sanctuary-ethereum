// SPDX-License-Identifier: None
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface HexArts {
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);

    function transferNFT(
        uint256 _tokenId,
        address _from,
        address _to
    ) external returns (bool);

    function getApproved(uint256 tokenId) external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface FeesCollector {
    function manageHexArtFees(uint256 value) external returns (bool);

    function manageArtistFees(uint256 value) external returns (bool);
}

contract HexArtMarket is Ownable {
    HexArts public hexArtAddress;
    FeesCollector public feeCollectorAddress;

    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }
    uint256 public totalFeeShare = 2222; // 2.222 Percentage
    address payable internal fee;

    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;
    mapping(uint256 => address) public nftBuyer;

    constructor(address _hexArt, address payable _feeCollector) {
        hexArtAddress = HexArts(_hexArt);
        feeCollectorAddress = FeesCollector(_feeCollector);
        fee = _feeCollector;
    }

    ///Modifier, Check if NFT listed for sale
    modifier ItemExists(uint256 id) {
        require(
            id < itemsForSale.length && itemsForSale[id].id == id,
            "NFT not listed for sale"
        );
        _;
    }

    ///Modifier, Check NFT ownership
    modifier OnlyItemOwner(uint256 tokenId) {
        require(
            hexArtAddress.ownerOf(tokenId) == msg.sender,
            "Sender is not the owner of this NFT"
        );
        _;
    }

    ///Modifier, Check if listed NFT is sold or not
    modifier IsForSale(uint256 id) {
        require(!itemsForSale[id].isSold, "Item is already sold");
        require(
            activeItems[itemsForSale[id].tokenId],
            "Item is delisted for sale"
        );
        _;
    }

    ///Modifier, Check if NFT is approved for this contract
    modifier HasTransferApproval(uint256 tokenId) {
        require(
            hexArtAddress.getApproved(tokenId) == address(this),
            "NFT not approved for this Marketplace"
        );
        _;
    }

    event itemAddedForSale(
        uint256 id,
        address seller,
        uint256 tokenId,
        uint256 price
    );
    event itemSold(uint256 id, address buyer, uint256 tokenId, uint256 price);
    event itemDelisted(uint256 id, uint256 tokenId, bool isActive);

    /**
     *@notice List NFT for sale
     *@param tokenId uint256, NFT ID
     *@param price(in wei) uint256, NFT selling price
     *@return uint(newItemId)
     */
    function putItemForSale(uint256 tokenId, uint256 price)
        external
        OnlyItemOwner(tokenId)
        HasTransferApproval(tokenId)
        returns (uint256)
    {
        require(!activeItems[tokenId], "Item is already up for sale");
        require(price > 0, "Price should be greater than 0");

        uint256 newItemId = itemsForSale.length;
        itemsForSale.push(
            ItemForSale({
                id: newItemId,
                tokenId: tokenId,
                seller: payable(msg.sender),
                price: price,
                isSold: false
            })
        );
        activeItems[tokenId] = true;
        assert(itemsForSale[newItemId].id == newItemId);
        emit itemAddedForSale(newItemId, msg.sender, tokenId, price);
        return newItemId;
    }

    /**
     *  @notice Buy a NFT
     *  @param  id, index of NFT
     */
    function buyItem(uint256 id) external payable ItemExists(id) IsForSale(id) {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);
        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;
        uint256 addShare = (msg.value * totalFeeShare) / 100000;
        uint256 sellerShare = msg.value - addShare;

        require(
            hexArtAddress.transferNFT(
                itemsForSale[id].tokenId,
                itemsForSale[id].seller,
                msg.sender
            ),
            "NFT purchase failed"
        );
        nftBuyer[itemsForSale[id].tokenId] = msg.sender;
        (address _receiver, uint256 _royaltyAmount) = hexArtAddress.royaltyInfo(
            itemsForSale[id].tokenId,
            sellerShare
        );
        uint256 _sellerShare = sellerShare - _royaltyAmount;
        uint256 _royaltyshare = (_royaltyAmount * 5) / 100;
        uint256 _finalRoyalty = _royaltyAmount - _royaltyshare;

        payable(_receiver).transfer(_finalRoyalty);
        itemsForSale[id].seller.transfer(_sellerShare);
        fee.transfer(addShare + _royaltyshare);
        require(feeCollectorAddress.manageHexArtFees(msg.value));
        require(feeCollectorAddress.manageArtistFees(_royaltyshare));
        emit itemSold(
            id,
            msg.sender,
            itemsForSale[id].tokenId,
            itemsForSale[id].price
        );
    }

    /**
     *  @notice Remove an NFT from sale
     *  @param  id, Index of NFT in itemsForSale
     *  @param  tokenId, NFT ID
     *  @return uint256
     */
    function delistItem(uint256 id, uint256 tokenId)
        external
        OnlyItemOwner(tokenId)
        IsForSale(id)
        returns (uint256)
    {
        activeItems[itemsForSale[id].tokenId] = false;
        emit itemDelisted(id, tokenId, activeItems[itemsForSale[id].tokenId]);
        return tokenId;
    }

    /**
    @notice Check if hexart is listed on sale.
    @param _tokenId, hexart tokenId
    @return bool
     */
    function isListed(uint256 _tokenId) external view returns (bool) {
        return activeItems[_tokenId];
    }

    /**
    @notice Distribute penalty for asset removal
    @return true
    */
    function distibuteRemovalFee() external payable returns (bool) {
        fee.transfer(msg.value);
        require(feeCollectorAddress.manageArtistFees(msg.value));
        return true;
    }

    /**
    @notice Get the last owner of a hexart.
    @param _tokenId, hexart tokenId
    @return address
     */
    function getLastOwnerOfNft(uint256 _tokenId)
        external
        view
        returns (address)
    {
        return nftBuyer[_tokenId];
    }

    /**
     *@notice Update Fee Collector contract  address
     *@param _fee, new fee collector address
     */
    function updateFeeCollector(address payable _fee) external onlyOwner {
        require(_fee != address(0), "Zero address is not allowed");
        require(_fee != fee, "Cannot add the same address as feeCollector");

        feeCollectorAddress = FeesCollector(_fee);
        fee = _fee;
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