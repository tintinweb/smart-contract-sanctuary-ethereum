// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

interface IHEXStakeInstanceManager {
    function approve(address to, uint256 tokenId) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function getApproved(uint256 tokenId) external view returns (address);
}

contract HSIMarketplace {
    address public HSIMtoken;
    address public owner;
    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }

    address private hedronFlowWallet;
    address private HDRNWallet;
    address private HDRNStakersWallet;
    address private bonusWallet;
    address private HexMarketWallet;
    address[] public feeCollectors;
    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;
    mapping(address => uint256) public feeShare;

    //events
    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
    event itemSold(uint256 id, address buyer, uint256 price);
    event itemDelisted(uint256 id, uint256 tokenId, bool isActive);

    //constructor
    constructor(address _token) {
        HSIMtoken = _token;
        owner = msg.sender;
    }

    //modifier

    modifier OnlyItemOwner(uint256 tokenId) {
        require(
            IHEXStakeInstanceManager(HSIMtoken).ownerOf(tokenId) == msg.sender,
            "Sender does not own the item"
        );
        _;
    }

    modifier HasTransferApproval(uint256 tokenId) {
        require(
            IHEXStakeInstanceManager(HSIMtoken).getApproved(tokenId) ==
                address(this),
            "Market is not approved"
        );
        _;
    }

    modifier ItemExists(uint256 id) {
        require(
            id < itemsForSale.length && itemsForSale[id].id == id,
            "Could not find item"
        );

        _;
    }

    modifier IsForSale(uint256 id) {
        require(!itemsForSale[id].isSold, "Item is already sold");
        require(
            activeItems[itemsForSale[id].tokenId],
            "Item is delisted for sale"
        );
        _;
    }

    /* ======== USER FUNCTIONS ======== */

    /*
     *  @notice put nft on sale
     *  @param tokenId uint256
     *  @param price(in wei) uint256
     *  @return uint(newItemId )
     */
    function putItemForSale(uint256 tokenId, uint256 price)
        external
        OnlyItemOwner(tokenId)
        HasTransferApproval(tokenId)
        returns (uint256)
    {
        require(!activeItems[tokenId], "Item is already up for sale");

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
        emit itemAddedForSale(newItemId, tokenId, price);
        return newItemId;
    }

    /*
     *  @notice buy a nft
     *  @param id(index of nft) uint256
     */

    function buyItem(uint256 id)
        external
        payable
        ItemExists(id)
        IsForSale(id)
        HasTransferApproval(itemsForSale[id].tokenId)
    {
        require(msg.value >= itemsForSale[id].price, "Not enough funds sent");
        require(msg.sender != itemsForSale[id].seller);

        itemsForSale[id].isSold = true;
        activeItems[itemsForSale[id].tokenId] = false;
        IHEXStakeInstanceManager(HSIMtoken).safeTransferFrom(
            itemsForSale[id].seller,
            msg.sender,
            itemsForSale[id].tokenId
        );

        uint256 sellerShare = feeCollector(msg.value);
        itemsForSale[id].seller.transfer(sellerShare);

        emit itemSold(id, msg.sender, itemsForSale[id].price);
    }

    /*
     *  @notice get total number of items on sale
     *  @return uint
     */
    function totalItemsForSale() external view returns (uint256) {
        return itemsForSale.length;
    }

    /*
     *  @notice get all  items on sale
     *  @return tuple
     */
    function getListedItems() external view returns (ItemForSale[] memory) {
        return itemsForSale;
    }

    /*
     *  @notice remove an item from sale
     *  @param id(index of nft) uint
     *  @param tokenid uint
     *  @return uint
     */
    function delistItem(uint256 id, uint256 tokenId)
        external
        OnlyItemOwner(tokenId)
        IsForSale(id)
        returns (uint256)
    {
        itemsForSale[id].isSold = false;
        activeItems[itemsForSale[id].tokenId] = false;

        emit itemDelisted(id, tokenId, activeItems[itemsForSale[id].tokenId]);
        return tokenId;
    }

    /*
     *  @notice set the wallet address with percentage of share for each wallet
     *  @param payable wallet address
     *  @param percentage uint
     */
    function setFeeShare(address payable wallet, uint256 percentage) external {
        require(
            msg.sender == owner,
            "Only owner of contract can set the fee share"
        );
        feeShare[wallet] = percentage;
        feeCollectors.push(wallet);
    }

    /*
     *  @notice internal function to distribute the share to wallet and return the remaining amount in eth
     *  @param amount
     *  @return  uint
     */

    function feeCollector(uint256 amount) internal returns (uint256) {
        uint256 amountInETH = amount;
        for (uint256 i; i < feeCollectors.length; i++) {
            uint256 share = feeShare[feeCollectors[i]];
            uint256 shareInAmount = (amount * share) / 10000; // 1% = 10000 e.g. for 0.5555% set 5555
            payable(feeCollectors[i]).transfer(shareInAmount);
            amountInETH = amountInETH - (shareInAmount);
        }

        return amountInETH;
    }
}