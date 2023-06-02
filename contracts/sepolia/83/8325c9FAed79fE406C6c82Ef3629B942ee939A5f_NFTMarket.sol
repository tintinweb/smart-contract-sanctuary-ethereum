// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/utils/ERC1155HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


///@author Dualmint
///@title NFTMarket
///@notice This is the declaration of the NFTMarket Contract for the Dualmint Markeplace that facilitates creation, buying, selling and auctions of tokenized versions of luxury items. 
///@dev This contract is upgradable to allow for expansion of the use cases and the features offered by the Dualmint Markeplace.
///NOTE: The transfers of assets and currencies do not need to be verified with the returned boolean value as per the new updates in ERC20 and ERC1155 transfer standards, since when the transfer fails the execution is reverted.
contract NFTMarket is Initializable,UUPSUpgradeable,ReentrancyGuardUpgradeable,OwnableUpgradeable,ERC1155HolderUpgradeable{
  using CountersUpgradeable for CountersUpgradeable.Counter;

  // The MarketItem helps store each item on the Marketplace along with the relevant details of the asset and its current state. 
  struct MarketItem {
    bool isOnMarket;        // true if the item is currently on sale or auction in the Marketplace.
    bool isOnAuction;       // true if an item is currently on auction in the Marketplace.
    uint itemId;            // the id of the item in the Marketplace
    address nftContract;    // the address of the ERC1155 contract where the item was minted.
    uint256 tokenId;        // the tokenId of the asset in the ERC1155 contract where the item was minted
    address owner;          // the address of the current owner of the asset in the Marketplace.
    uint price;             // the listing price of the item in the Marketplace (NOTE: This is the base price if the item is on auction).       
    uint256 saleCount;      // the number of times the item has been traded on the Marketplace.
    bool pendingClaim;      // this variable is only true when someone wins an auction but has not claimed the item yet.
  }
  
  //The Auction struct helps store the relevant information about any ongoing auction of an item.
  struct Auction {
    uint  endAt;                        // the timestamp at which the auction ends
    bool started;                       // true if the auction has started
    bool ended;                         // true if the auction has ended
    address highestBidder;              // stores the address of the current highest bidder
    uint highestBid;                    // stores the current highest bid made by the highest bidder
    uint bidCount;                      // stores the number of bids for the current auction of an item
  }

  // The BidStruct helps store the details linked with each bid.
  struct BidStruct {
      address bidder;         // stores the address of the user who has bid on an item
      uint256 bid;            // stores the value of the bid
  }

  // The IncompleteRoyalties struct helps store the snapshot of the sale information in case of insufficient gas while executing the royalty loop.
  struct IncompleteRoyalties {
    uint itemId;                      // the item id of the asset
    uint royaltyOwnerIndexReached;    // the index of the last owner who was given royalty as a part of the royalty loop
    uint saleCount;                   // the number of times the asset was sold when the execution of the royalty loop was incomplete
    uint intermediaryBalance;         // the royalty to be assigned to each intermediary owner as per the royalty structure
    bool isComplete;                  // true when the incomplete execution has been completed 
  }

  IERC20Upgradeable public tokenAddress; // The address of the ERC20 stablecoin contract on the ethereum blockchain network.
  CountersUpgradeable.Counter private _itemIds;// The number of items in the marketplace.
  CountersUpgradeable.Counter private _itemsOffMarket; // The number of items not currently on sale or auction.
  CountersUpgradeable.Counter public _incompleteRoyaltyIds; // This helps complete the unbounded royalty loop in case the user runs out of gas before the execution is completed. These IDs help store the snapshot of those sales to enable us to assign the promised royalties.

  ///  NOTE: The following royalty percentages are defined to be 10 * actual percentage to facilitate calculations with better precision and allowing definition of a wider range of values since floating point numbers are not supported.
  ///  This means that 10% is represented as 100 and the same has been accounted for when calculations are being made as the value is divided by 1000 instead of 100.
 
  uint256 public royaltiesPrecision;
  uint256 public royalties ;          // Percentage of sale amount distributed as royalties.
  uint256 public royaltyFirstOwner;   // Percentage of the the total royalty that is assigned to the first owner.
  uint256 public royaltyLastOwner;    // Percentage of the the total royalty that is assigned to the previous seller (NOTE: The last seller is the user who owned the asset before the current owner/seller, who has put it on sale). 
  //implicit royalty_intermediaries = 1 - percentage(royaltyFirstOwner) - percentage(royaltyLastOwner)// Percentage of the total royalty going to the the intermediaries*/
  address private deployer ;          // The address of the deployer of the marketplace (NOTE: Dualmint's wallet address, also referred to as admin). 
  uint256 public commissionPercent;   //  The percentage of commission received by Dualmint on each successful sale transaction.
  uint256 public gasThresholdForUserLoop; // Threshold of minimum gas required for the unbounded royalty loop when the user buys an asset to prevent DOS. 
  uint256 public gasThresholdForAdminLoop; // Threshold of minimum gas required for the unbounded royalty loop when the admin tries to complete the loop (to prevent DOS ).

  mapping (uint256 => IncompleteRoyalties) private incompleteRoyalties;   // stores the details of the incomplete royalty loops
  mapping (uint256 => Auction) private idToAuctionItem;                   // maps the item to its Auction Details
  mapping (uint256 => mapping(uint=>BidStruct)) public bids;              // maps the item to all its bids stored as BidStruct
  mapping(uint256 => MarketItem) private idToMarketItem;                  // maps each item in the MarketPlace to its details
  mapping (uint256 => mapping(uint256=>address)) public owners;           // stores all the owners of each item in the MarketPlace
  mapping (address => uint256) private pullableAmount;                    // maps the amount that can be withdrawn by the associated user (NOTE: PULL PAYMENT TO PREVENT SECURITY VULNERABILITIES)
  mapping (address => mapping(uint256=>bool)) public assets;              // mapping of already existing assets to prevent previously exsiting items to be introduced as new ones

  ///@notice An event that is triggered when a market item is created
  event MarketItemCreated ( 
    uint indexed itemId, 
    address nftContract, 
    uint256 tokenId, 
    address indexed seller, 
    uint256 price, 
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when a bid is received
  event Bid (
    uint indexed itemId, 
    address indexed sender, 
    uint amount
  );

  ///@notice An event that is triggered when an auction ends 
  event End(
    uint indexed itemId, 
    address indexed highestBidder, 
    uint highestBid
  );

  ///@notice An event that is triggered when a user balance is updated
  event Balances(
    uint indexed itemId, 
    address indexed puller, 
    uint indexed transactionType, //In event Balance transaction type// 0 is for withdrawing event // 1 is for direct sale // 2 is for royalty distribution
    uint256 amount
  ); 
  
  ///@notice An event that is triggered when a royalty distribution loop is not completed due to insufficient gas
  event IncompleteRoyalty(
    uint indexed royaltyId, 
    uint indexed itemId, 
    uint ownerReached, 
    uint lastOwnerForRoyaltyLoopIndex
  );

  ///@notice An event that is triggered when a previously incomplete royalty loop is run to completion by deployer
  event CompletedRoyalty(uint indexed royaltyId, uint indexed itemId);

  ///@notice An event that is triggered when a royalty percentage is changed
  event RoyaltiesReset(
    uint overallRoyalties, 
    uint firstOwnerRoyalty, 
    uint lastOwnerRoyalty
  );

  ///@notice An event that is triggered when an item is sold
  event CommissionsReset(uint commissionPercent);

  ///@notice An event that is triggered when a direct sale occurs
  event DirectSale(
    uint indexed itemId, 
    address indexed buyer, 
    address indexed seller, 
    uint price
  );

  ///@notice An event that is triggered when the auction winning user withdraws the item
  event WithdrawItem(uint indexed itemId, address indexed buyer);

  ///@notice An event that is triggered when an item is put on resale
  event ResellItem(
    uint indexed itemId, 
    address indexed seller, 
    uint price, 
    bool indexed isOnAuction
  );

  ///@notice An event that is triggered when user loop gas threshold is updated
  event UserGasThresholdChanged(uint newThreshold);

  ///@notice An event that is triggered when admin loop gas threshold is updated
  event AdminGasThresholdChanged(uint newThreshold);

  ///@notice Initializing the upgradable contract in the required format
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() {_disableInitializers();}
  

  function initialize (address _tokenAddress) external initializer{
      royaltiesPrecision = 1000;
      royalties = 100;
      royaltyFirstOwner = 500;
      royaltyLastOwner = 200;
      commissionPercent = 25;
      gasThresholdForUserLoop = 250000;
      gasThresholdForAdminLoop = 200000;
      deployer = _msgSender();
      __Ownable_init();      
      __UUPSUpgradeable_init();
      __ReentrancyGuard_init();
      __ERC1155Holder_init();
      tokenAddress = IERC20Upgradeable(_tokenAddress);
  }


  ///@notice  This function is used to set the threshold of minimum gas required for the unbounded royalty loop when the user buys an asset to prevent DOS. 
  ///@dev This function can only be called by the owner of the marketplace contract.
  ///@param newThreshold The threshold value to be set by the owner.
  function setGasThresholdForUserLoop (
    uint256 newThreshold
  ) 
    external 
    onlyOwner 
  {
    require(newThreshold > 0,"value too low");
    gasThresholdForUserLoop = newThreshold;
    emit UserGasThresholdChanged(newThreshold);
  }

  ///@notice  This function is used to set the threshold of minimum gas required for the unbounded royalty loop when the admin tries to complete the loop (to prevent DOS).
  ///@dev This function can only be called by the owner of the marketplace contract.
  ///@param newThreshold The threshold value to be set by the owner.
  function setGasThresholdForAdminLoop (
    uint256 newThreshold
  ) 
    external 
    onlyOwner 
  {
    require(newThreshold > 0,"value too low");
    gasThresholdForAdminLoop = newThreshold;
    emit AdminGasThresholdChanged(newThreshold);
  }

  
  ///@notice This function can be used to change the percentages of royalties
  ///@dev The function allows multiple or only one value to be changed. If a previous value of the variable is to be maintained, instead of passing the same value as an argument again, a value higher than 1000 can be passed as the case handling accounts for that
  ///@param _royalties The overall royalty percentage associated with the sale value.
  ///@param _royaltyFirstOwner The royalty of the first owner.
  ///@param _royaltyLastOwner  The royalty of the previous seller. 
  function setRoyalties(
    uint _royalties, 
    uint _royaltyFirstOwner, 
    uint _royaltyLastOwner
  ) 
    external 
    onlyOwner
  {
    require(_royalties+commissionPercent<royaltiesPrecision, "overall royalties too high");
    require(_royaltyFirstOwner+_royaltyLastOwner<royaltiesPrecision,"owner percentages too high");
    royalties = _royalties;
    royaltyFirstOwner = _royaltyFirstOwner;
    royaltyLastOwner = _royaltyLastOwner;
    emit RoyaltiesReset(royalties,royaltyFirstOwner,royaltyLastOwner);
  }

  
  ///@notice This function can be used to change the commision percentage of the Marketplace
  ///@param _commissionPercent  The new commision percentage 
  function setCommissionPercent(uint256 _commissionPercent) external onlyOwner {
    require(royalties+_commissionPercent<royaltiesPrecision, "commissionPercent too high");
    commissionPercent = _commissionPercent;
    emit CommissionsReset(commissionPercent);
  }

  
  ///@notice This function is called to put an asset on sale (or auction) on the Dualmint Marketplace
  ///@dev Approval from the nftContract is required before executing this function
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  function createMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays
  ) 
    external 
    nonReentrant 
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      isAuctionItem, 
      numDays, 
      _msgSender()
    );
  }

  
  ///@notice This function is called by Dualmint to put an asset on sale (or auction) on behalf of a customer
  ///@dev Approval from the nftContract is required before executing this function
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  ///@param assetOwner The desired owner of the item.
  function assistedCreateMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner
  ) 
    external 
    onlyOwner
  {
    creationOfMarketItem(
      nftContract, 
      tokenId, 
      price, 
      isAuctionItem, 
      numDays,
      assetOwner
    );
  }

  
  ///@notice The function to place a bid on an item that is currently on auction
  ///@dev Approval for the Marketplace is required from the bidder on the ERC20 contract stored at tokenAddress to transfer amount
  ///@param itemId The id of the item on which the bid is to be placed
  ///@param amount The bid amount.
  function createBid(uint256 itemId, uint256 amount) external nonReentrant{
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
    require(amount>idToAuctionItem[itemId].highestBid, "Lower bid than acceptable");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < idToAuctionItem[itemId].endAt, "ended"); // this condition ensures that the item is currently on auction and the bid is being made is the specified period
    require(tokenAddress.allowance(_msgSender(), address(this))>=amount,"insufficient allowance");
    bool transferSuccessful = tokenAddress.transferFrom(_msgSender(),address(this),amount); // transfer of funds to marketplace contract
    require(transferSuccessful,"transfer of tokens unsuccessful"); //)
    if (idToAuctionItem[itemId].highestBidder != address(0)) {  // if this is not the first bid, then the previous bid is saved and the previous bidder can withdraw their funds
      bids[itemId][idToAuctionItem[itemId].bidCount] = BidStruct(
        idToAuctionItem[itemId].highestBidder,
        idToAuctionItem[itemId].highestBid
      );//mapping (uint256 => mapping(uint=>BidStruct)) public bids;  
      pullableAmount[idToAuctionItem[itemId].highestBidder] += idToAuctionItem[itemId].highestBid;
    }
    idToAuctionItem[itemId].bidCount += 1;
    idToAuctionItem[itemId].highestBidder = _msgSender();
    idToAuctionItem[itemId].highestBid = amount;
    emit Bid(itemId,_msgSender(),amount);
  }

  
  ///@notice This is called once the auction period is over
  ///@dev For the auction to be completed and the funds and asset to be distributed, an external call is required
  ///@param itemId The itemId whose auction is over
  function endAuction(uint256 itemId) external {
        require(idToMarketItem[itemId].isOnAuction, "Currently not on auction");
        // solhint-disable-next-line not-rely-on-time
        require(block.timestamp >= idToAuctionItem[itemId].endAt, "not ended");
        require(!idToAuctionItem[itemId].ended, "ended");
        if (idToAuctionItem[itemId].highestBidder == address(0)) {  //in case there are no bids for the item the ownership is transferred back to the user who listed
            IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
              address(this), 
              idToMarketItem[itemId].owner, 
              idToMarketItem[itemId].tokenId,
              1,
              "No bids"
            );
            idToMarketItem[itemId].isOnMarket = false;
            _itemsOffMarket.increment();
        } else {  // if bids were made successfully, the normal distribution of royalty and transfer of assets and assignment of balances shall take place
            distributionOfFundsAndAssets(
              idToAuctionItem[itemId].highestBid,
              idToAuctionItem[itemId].highestBidder, 
              itemId
            );
            idToMarketItem[itemId].pendingClaim = true;
        }
        idToMarketItem[itemId].price = idToAuctionItem[itemId].highestBid;
        //resetting state variables to default values
        idToAuctionItem[itemId] = Auction(// solhint-disable-next-line not-rely-on-time
          block.timestamp,
          false,
          true,
          address(0),
          idToMarketItem[itemId].price,
          0
        );
        idToMarketItem[itemId].isOnAuction = false;
        emit End(itemId, idToAuctionItem[itemId].highestBidder, idToAuctionItem[itemId].highestBid);
  }

  
  ///@notice This function executes the direct sale of an asset 
  ///@dev This can only be called for an item that is not on auction
  ///@param itemId The itemId of the asset to be on sold
  function directMarketSale(uint256 itemId) external nonReentrant {
    require(!idToMarketItem[itemId].isOnAuction,"Sale type is auction");  
    require(idToMarketItem[itemId].isOnMarket, "Currently not on sale");
    require(
      tokenAddress.allowance(_msgSender(), address(this))
      >=idToMarketItem[itemId].price,"insufficient allowance"
    );
    bool transferSuccessful = tokenAddress.transferFrom(
      _msgSender(),
      address(this),
      idToMarketItem[itemId].price
    ); // transfer of funds from the buyer to the marketplace
    require(transferSuccessful,"transfer of tokens unsuccessful");
    distributionOfFundsAndAssets(idToMarketItem[itemId].price, _msgSender(), itemId);   // distribution of royalties and transfer of assets and assignment of balances shall take place
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      address(this), 
      _msgSender(), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "DirectSale"
    );  //Ownership transfer
    emit DirectSale(
      itemId, 
      _msgSender(), 
      owners[itemId][idToMarketItem[itemId].saleCount-1], 
      idToMarketItem[itemId].price
    );
  }
  
  ///@notice This function is called by the user to withdraw the asset purchased on the Marketplace.
  ///@dev This function is called to implement the pull payment mechanism for ERC1155 assets to avoid DOS.
  ///@param itemId The itemId of the asset purchased by the user on the Marketplace.
  function withdrawItem(uint256 itemId) external{
    require(idToMarketItem[itemId].pendingClaim==true,"cannot withdraw");
    require(idToMarketItem[itemId].owner==_msgSender(), "not your asset");
    idToMarketItem[itemId].pendingClaim=false;
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      address(this), 
      _msgSender(), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "AuctionWinner"
    );  //Ownership transfer
    emit WithdrawItem(itemId, _msgSender());
  }

  
  ///@notice This function executes the listing for sale of an asset previously purchased on the marketplace.
  ///@dev The approval from the nftContract is required for transferring the ownership of the asset to the marketplace contract.
  ///@param itemId The itemId of the asset to be resold
  ///@param price The price at which the item is listed for resale on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  function resellItem(uint256 itemId, uint256 price, bool isAuctionItem, uint256 numDays) external {
    require(!idToMarketItem[itemId].isOnMarket,"The Item is already on sale");
    require(_msgSender()==idToMarketItem[itemId].owner, "You are not allowed to resell");
    IERC1155Upgradeable(idToMarketItem[itemId].nftContract).safeTransferFrom(
      _msgSender(), 
      address(this), 
      idToMarketItem[itemId].tokenId, 
      1, 
      "ResellItem"
    );
    idToMarketItem[itemId].isOnMarket = true;
    idToMarketItem[itemId].isOnAuction = isAuctionItem;
    idToMarketItem[itemId].price = price;
    _itemsOffMarket.decrement();
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);
    }
    emit ResellItem(itemId, _msgSender(), price, isAuctionItem);
  }

  ///@notice This function is used to complete any incomplete royalty loops that had insufficient gas for execution
  ///@dev This function can only be called by the deployer and in case the gas is still not sufficient, this can be recalled and acounts for the stated condition by saving the state of its last execution.
  ///@param incompleteRoyaltyId The ID of the incomplete royalty event
  function completeRoyaltyLoop(uint incompleteRoyaltyId) external onlyOwner{
    require(!incompleteRoyalties[incompleteRoyaltyId].isComplete,"already completed");
    uint i = incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached+1;
    for (
      i; 
      i < incompleteRoyalties[incompleteRoyaltyId].saleCount - 2  && gasleft()>gasThresholdForAdminLoop;
      i++
    )
    { //royalty for intermediary owners who have not been assigned the royalty yet
      pullableAmount[owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i]]+=
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance;
      emit Balances(
        incompleteRoyalties[incompleteRoyaltyId].itemId, 
        owners[incompleteRoyalties[incompleteRoyaltyId].itemId][i], 
        2, 
        incompleteRoyalties[incompleteRoyaltyId].intermediaryBalance
      );
    }
    if(i!=incompleteRoyalties[incompleteRoyaltyId].saleCount-2){  // the case where there is not enough gas to complete the royalty loop, state of last execution is saved, event is emitted and can be called again
      emit IncompleteRoyalty(
        incompleteRoyaltyId, 
        incompleteRoyalties[incompleteRoyaltyId].itemId, 
        i-1, 
        incompleteRoyalties[incompleteRoyaltyId].saleCount
      );
      incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached = i;
    } else {  // in case the loop has reached the end
      incompleteRoyalties[incompleteRoyaltyId].royaltyOwnerIndexReached = i;// optional
      incompleteRoyalties[incompleteRoyaltyId].isComplete = true;
      emit CompletedRoyalty(incompleteRoyaltyId, incompleteRoyalties[incompleteRoyaltyId].itemId);
    }
  }


  ///@notice This function enables the user to withdraw the balances assigned to them
  ///@dev This function can be called by anyone on behalf of the user in case they do not have enough gas to execute it. Further, reentrancy has been secured against by changing the state variable before the execution of transfer.
  ///@param payee The address of the user whose balance is to be withdrawn
  function withdrawFunds(address payee) external {
    require(pullableAmount[payee]>0,"No balance to withdraw");
    uint256 currentBalance = pullableAmount[payee];
    pullableAmount[payee]=0;
    bool transferSuccessful = tokenAddress.transfer(payee,currentBalance);
    require(transferSuccessful,"transfer of tokens unsuccessful");
    emit Balances(0, payee, 0, currentBalance);
  }  


  ///@notice This function is used to get the items currently on sale or auction in the marketplace.
  ///@return MarketItems currently on sale or auction in the marketplace (i.e. items with isOnMarket value stored as true).
  function fetchMarketItems() external view returns (MarketItem[] memory) {
    uint itemCount = _itemIds.current();
    uint unsoldItemCount = _itemIds.current() - _itemsOffMarket.current();
    uint currentIndex = 0;
    MarketItem[] memory items = new MarketItem[](unsoldItemCount);
    for (uint i = 1; i <= itemCount; i++) {
      if(idToMarketItem[i].isOnMarket){
        uint currentId = i;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      } 
    }
    return items;
  }

  ///@notice This function is used to get all the items in the marketplace irrespective of whether they are on sale or not.
  ///@return MarketItems in the Marketplace (irrespective of whether they are on sale or not)
  function fetchAllItems() external view returns (MarketItem[] memory) {
    MarketItem[] memory items = new MarketItem[](_itemIds.current());
    for (uint i = 0; i < _itemIds.current(); ++i){
        MarketItem storage currentItem = idToMarketItem[i+1];
        items[i] = currentItem;
    }
    return items;
  }


  ///@notice This function is used to get all the items currently owned by the msg.sender
  ///@dev This includes the items put on sale by the msg.sender too which are not currently sold
  ///@return MarketItems currently owned by the msg.sender
  function fetchMyNFTs() external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (idToMarketItem[i + 1].owner == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }

  
  ///@notice This function is used to get all the items created by the msg.sender
  ///@return MarketItems created by the msg.sender
  function fetchItemsCreated() external view returns (MarketItem[] memory) {
    uint totalItemCount = _itemIds.current();
    uint itemCount = 0;
    uint currentIndex = 0;
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        itemCount += 1;
      }
    }
    MarketItem[] memory items = new MarketItem[](itemCount);
    for (uint i = 0; i < totalItemCount; i++) {
      if (owners[i+1][0] == _msgSender()) {
        uint currentId = i + 1;
        MarketItem storage currentItem = idToMarketItem[currentId];
        items[currentIndex] = currentItem;
        currentIndex += 1;
      }
    }
    return items;
  }
  

  ///@notice This function is used to get auction details of an item
  ///@param itemId The item id whose auction details are to be retrieved
  ///@return AuctionDetails of the itemId
  function fetchAuctionItemsDetails(uint256 itemId) external view returns (Auction memory) {
    return idToAuctionItem[itemId];
  }


  ///@notice This function is used to check the withdrawable balance of the user
  ///@param payee The address of the user
  ///@dev The balance is returned with the precision of the ERC20 currency
  ///@return Balance of the user
  function checkBalance(address payee) external view returns(uint256){
    return pullableAmount[payee];
  }


  ///@notice This function is called by both createMarketItem and assistedCreateMarketItem to put an asset on sale(or auction) on the Dualmint Marketplace, avoiding the duplication of code.
  ///@dev This function is an internal function.
  ///@param nftContract  The address of the ERC1155 contract where the item was minted.
  ///@param tokenId The tokenId of the asset in the ERC1155 contract where the item was minted
  ///@param price The price at which the item is listed on the marketplace (NOTE: In case of auction, this is the base price).
  ///@param isAuctionItem  True if item has been put on auction.
  ///@param numDays The number of seconds for which the item is on auction.
  ///@param assetOwner The desired owner of the item.
  function creationOfMarketItem(
    address nftContract, 
    uint256 tokenId, 
    uint256 price, 
    bool isAuctionItem, 
    uint256 numDays, 
    address assetOwner
  ) 
    internal
  {
    require(price > 1000000, "Price must be at least 1");
    require(assets[nftContract][tokenId]==false,"asset already exists");
    assets[nftContract][tokenId] = true;
    IERC1155Upgradeable(nftContract).safeTransferFrom(
      _msgSender(), 
      address(this), 
      tokenId, 
      1, 
      "MarketItemCreated"
    ); // transfer of token ownership to marketplace contract
    _itemIds.increment();
    uint256 itemId = _itemIds.current();
    idToMarketItem[itemId] = MarketItem(
      true, 
      isAuctionItem, 
      itemId, 
      nftContract, 
      tokenId, 
      assetOwner, 
      price, 
      0,
      false
    ); 
    owners[itemId][0] = assetOwner;
    if(isAuctionItem){
      // solhint-disable-next-line not-rely-on-time
      idToAuctionItem[itemId] = Auction(block.timestamp+numDays, true, false, address(0), price, 0);
    }
    emit MarketItemCreated(itemId, nftContract, tokenId, assetOwner, price, isAuctionItem);
  }


  ///@notice This function executes the royalty loop, transfer of assets, and assignment of balances
  ///@dev The unbounded loop condition is handled by storing the current state of the execution in case the gas is insufficient and can be completed by calling completeRoyaltyLoop
  ///@param price The final price at which the asset is purchased
  ///@param buyer The user about to receive the asset
  ///@param itemId The asset associated with the sale
  function distributionOfFundsAndAssets(uint price, address buyer, uint itemId) internal {
    idToMarketItem[itemId].saleCount+=1;
    uint saleCount = idToMarketItem[itemId].saleCount;
    uint256 marketplaceCommission = ((price * commissionPercent)/royaltiesPrecision);
    pullableAmount[deployer]+= marketplaceCommission; // assigning commission to the marketplace
    emit Balances(itemId, deployer, 1, marketplaceCommission);
    //allocation of sale price and royalties
    if(saleCount==1){
      // a -> b
      //if it is the first sale, the seller gets all the money
      uint256 sellerBalance = (((royaltiesPrecision-commissionPercent)*price)/royaltiesPrecision);
      pullableAmount[idToMarketItem[itemId].owner]+=sellerBalance;
      emit Balances(itemId, idToMarketItem[itemId].owner, 1, sellerBalance);
    } else if (saleCount==2){
      // a -> b -> c
      //if it is the second sale
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties)/royaltiesPrecision);
      pullableAmount[owners[itemId][0]]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance);
    } else if (saleCount==3){
      // a-> b -> c -> d
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][0]]+=firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*(royaltiesPrecision-royaltyFirstOwner))
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance);
      //seller gets the sale price ( - royalty - commission)
      uint256 sellerBalance = ((price*(royaltiesPrecision-royalties-commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId, owners[itemId][idToMarketItem[itemId].saleCount-1], 1 ,sellerBalance);
    } else { // this condition is hit when saleCount>3
      // a->b->c->.....->w->x->y->z
      //first owner gets royalty
      uint256 firstOwnerBalance = ((price*royalties*royaltyFirstOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][0]]+= firstOwnerBalance;
      emit Balances(itemId, owners[itemId][0], 2, firstOwnerBalance);
      // royalty to last seller
      uint256 lastOwnerBalance = ((price*royalties*royaltyLastOwner)
        /(royaltiesPrecision*royaltiesPrecision));
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-2]]+=lastOwnerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-2] , 2, lastOwnerBalance);
      // selling price - commission given to seller
      uint256 sellerBalance = ((price*(royaltiesPrecision - royalties - commissionPercent))
        /royaltiesPrecision);
      pullableAmount[owners[itemId][idToMarketItem[itemId].saleCount-1]]+=sellerBalance;
      emit Balances(itemId,owners[itemId][idToMarketItem[itemId].saleCount-1], 1,  sellerBalance);
      // intermediaries get royalty
      uint256 intermediaryBalance = ((price*royalties
        *(royaltiesPrecision-royaltyFirstOwner-royaltyLastOwner))
        /(royaltiesPrecision*royaltiesPrecision))
        /(idToMarketItem[itemId].saleCount-3);
      uint i=1;
      for (i;i< idToMarketItem[itemId].saleCount-2 && gasleft()>gasThresholdForUserLoop; i++){ //royalty distributed among intermediary owners
        pullableAmount[owners[itemId][i]] += intermediaryBalance;
        emit Balances(itemId, owners[itemId][i], 2, intermediaryBalance);
      }
      if(i!=idToMarketItem[itemId].saleCount-2){ // in case the gas is insufficient to complete the royalty loop, then the state is stored
        _incompleteRoyaltyIds.increment();
        uint royaltyId = _incompleteRoyaltyIds.current();
        incompleteRoyalties[royaltyId] = IncompleteRoyalties(
          itemId, 
          i-1, 
          idToMarketItem[itemId].saleCount, 
          intermediaryBalance, 
          false
        );
        emit IncompleteRoyalty(royaltyId, itemId, i, idToMarketItem[itemId].saleCount);
      }
    }
    owners[itemId][idToMarketItem[itemId].saleCount]= buyer; // the new owner is _msgSender()
    idToMarketItem[itemId].isOnMarket = false;  // resetting
    idToMarketItem[itemId].owner = buyer;
    _itemsOffMarket.increment();
  }


  // solhint-disable-next-line no-empty-blocks
  function _authorizeUpgrade(address newImplementation) internal override onlyOwner{}
}

// SPDX-License-Identifier: MIT
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155HolderUpgradeable is Initializable, ERC1155ReceiverUpgradeable {
    function __ERC1155Holder_init() internal onlyInitializing {
    }

    function __ERC1155Holder_init_unchained() internal onlyInitializing {
    }
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155ReceiverUpgradeable.sol";
import "../../../utils/introspection/ERC165Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155ReceiverUpgradeable is Initializable, ERC165Upgradeable, IERC1155ReceiverUpgradeable {
    function __ERC1155Receiver_init() internal onlyInitializing {
    }

    function __ERC1155Receiver_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC1155ReceiverUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}