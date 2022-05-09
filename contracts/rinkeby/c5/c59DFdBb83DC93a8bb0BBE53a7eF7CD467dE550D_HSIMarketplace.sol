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

interface IFeeCollection{
    function feeCollector(uint256 amount) external returns (uint256) ;
      function setFeeShare(address payable wallet, uint256 percentage) external;
}

contract HSIMarketplace {
    address public HSIMtoken;
    IFeeCollection fee;
    address public owner;
    struct ItemForSale {
        uint256 id;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        bool isSold;
    }
    
    ItemForSale[] public itemsForSale;
    mapping(uint256 => bool) public activeItems;


    //Events
    event itemAddedForSale(uint256 id, uint256 tokenId, uint256 price);
    event itemSold(uint256 id, address buyer, uint256 price);
    event itemDelisted(uint256 id, uint256 tokenId, bool isActive);

    //Constructor
    constructor(address _token,address _fee) {
        HSIMtoken = _token;
        owner = msg.sender;
        fee = IFeeCollection(_fee);
    }

    //Modifier
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

    modifier isOwner() {
        require(msg.sender == owner);
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
     *  @notice Transfer contract ownership.
     *  @param _newOwner address
     */

    function transferOwnerShip(address _newOwner) external isOwner {
        owner = _newOwner;
    }

    /*
     *@notice Put nft on sale
     *@param tokenId uint256
     *@param price(in wei) uint256
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
        emit itemAddedForSale(newItemId, tokenId, price);
        return newItemId;
    }

    /*
     *  @notice Buy a nft
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

         uint256 sellerShare = fee.feeCollector(msg.value);
        itemsForSale[id].seller.transfer(sellerShare);

        emit itemSold(id, msg.sender, itemsForSale[id].price);
    }

    /*
     *  @notice Get total number of items on sale
     *  @return uint
     */
    function totalItemsForSale() external view returns (uint256) {
        return itemsForSale.length;
    }

    /*
     *  @notice Get all  items on sale
     *  @return tuple
     */
    function getListedItems() external view returns (ItemForSale[] memory) {
        return itemsForSale;
    }

    /*
     *  @notice Remove an item from sale
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
     *  @notice Set the wallet address with percentage of share for each wallet
     *  @param payable wallet address
     *  @param percentage uint
     */
       function setFee(address payable wallet, uint256 percentage) public isOwner{
 fee.setFeeShare(wallet,percentage);
       }

}