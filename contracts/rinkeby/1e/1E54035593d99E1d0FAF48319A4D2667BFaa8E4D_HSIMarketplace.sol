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
     function manageFees(uint256 value, uint256 fees) external;
 }

contract HSIMarketplace {
    address public HSIMtoken;
     IFeeCollection  feeCollection;
     address payable fee;
    address public owner;
    uint256 public totalFeeShare=2222;

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
    constructor(address _token,address  payable _feeCollection) {
        HSIMtoken = _token;
        owner = msg.sender;
        feeCollection=IFeeCollection(_feeCollection);
        fee=_feeCollection;
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
  
        uint256 addShare =(msg.value*totalFeeShare)/100000;
        
        uint256 sellerShare=msg.value-addShare;

     
        itemsForSale[id].seller.transfer(sellerShare);
        fee.transfer(addShare);
        feeCollection.manageFees(msg.value,addShare);

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

 
    function updateFeeCollection(address payable _fee) public isOwner{
          feeCollection=IFeeCollection(_fee);
        fee=_fee;
    }


    function updateTotalFeeShare(uint256 _newFeeShare) public isOwner {
         totalFeeShare=_newFeeShare;
    }
   
}