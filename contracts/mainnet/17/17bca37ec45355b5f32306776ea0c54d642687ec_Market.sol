/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/*
'########::'########:'########::'##::::'##:
 ##.... ##: ##.....:: ##.... ##: ##:::: ##:
 ##:::: ##: ##::::::: ##:::: ##: ##:::: ##:
 ########:: ######::: ########:: ##:::: ##:
 ##.... ##: ##...:::: ##.. ##::: ##:::: ##:
 ##:::: ##: ##::::::: ##::. ##:: ##:::: ##:
 ########:: ########: ##:::. ##:. #######::
........:::........::..:::::..:::.......:::
*/

interface IModule {
  function getModule(uint module_) external view returns (address);
}

/**
  @notice Connection's interface with Roles SC
*/
interface IRoles {
  function isVerifiedUser(address user_) external returns (bool);
  function isModerator(address user_) external returns (bool);
  function isUser(address user_) external returns (bool);
}

/**
  @notice Connection's interface with ERC20 SC
*/
interface IERC20 {
  function balanceOf(address account) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to,uint256 amount) external returns (bool);
}

/**
  @notice Connection's interface with ERC721 SC
*/
interface IERC721 {
  function ownerOf(uint256 tokenId) external view returns (address owner);
  function isApprovedForAll(address owner, address operator) external view returns (bool);
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
  function getRoyalties() external view returns (uint);
  function deployer() external view returns (address);
}

/**
 * @notice The interface to implement in the market contract
 */
interface IMarket {
  event OfferCreated(uint256 id, string hiddenId);
  event OfferCompleted(uint id, string hiddenId, address buyer);
  event OfferApproved(uint256 offerId);
  event OfferCancelled(uint256 offerId);
}

/**
 * @notice Market logic
 */
contract Market is IMarket {
  /**
   * @notice The roles interface
   */
  IRoles rolesContract;

  /**
   * @notice Amount of offers (counter)
   */
  uint256 public offersCount;

  /**
   * @notice List of offers
   */
  mapping(uint256 => Offer) public offersList;

  /**
   * @notice List of actions winners
   */
  mapping(uint256 => address) public auctionWinners;

  /**
   * @notice List of approved offers
   */
  mapping(uint256 => bool) public approvedOffers;

  /**
   * @notice If of valid ERC20 tokens
   */
  mapping(address => bool) public validERC20;

  /**
   * @notice List of ERC721 approved
   */
  mapping(address => bool) public approvedERC721;

  /**
   * @notice Module Manager instance
   */
  IModule moduleManager;

  /**
   * @notice wallet to which royalties will be sent
  */
  address public beruWallet;

  /**
   *@notice percentaje of beru's royalties
  */
  uint public beruRoyalies;
  

  /**
   * @notice Struct created when at leas an ERC721 is put up for { sell / auction }
   * @param info encoded params {} 
   * @param collection  encoded collection's Ids
   * @param tokenId  encoded token's Ids
   * @param collectionAddress array of collectionAddreses 
   * @param paymentToken Token to accept for the listing
   * @param seller The address that sells the NFT (owner or approved)
   */
  struct Offer {
    uint256 info;
    uint256 tokenIds;
    address[] collectionAddresses;
    address paymentToken;
    address seller;
  }

  //! --------------------------------------------------------------------------- EVENTS ---------------------------------------------------------------------------

  /**
   * @notice Event triggered when someone bid in an auction
   */
  event BiddedForAuction(address who, uint256 offerId, uint256 amount, string id);

  /**
   * @notice Fired when an auction winner is changed because the wallet has no funds (or not sufficient)
   */
  event ChangedWinner(uint offerId, address newWinner);

  /**
   * @notice Event triggered when an offer changes status { approved / deprecated }
   */
  event ChangeStatusERC721(address ERC721, address who, bool newStatus);

  /**
   * @notice Event triggered when an offer is activated
   */
  event ApprovedOffer(uint offerId, address who);

  /**
   * @notice Event triggered when an ERC20 address is validated (or not)
   */
  event ERC20Validated(address token, bool valid);

  /**
   * @notice Event triggered when the funds were sent
   */
  event FundsSended(uint256 beruRoyalties , uint256 creatorsRoyalties , uint256 sellerFunds);

  /**
   *@notice Event triggered when the royalties wer sent
   */
  event RoyaltiesSended(address to, uint256 amount);

  /**
   * @notice Event triggered when beruWallet was set
   */
  event BeruWalletSet(address newBeruWallet); 

  /**
   * @notice Event triggered when beruRoyalties was set
  */
  event BeruRoyaliesSet(uint256 newRoyalties);

  /**
   *@notice Event triggered when a minBid was set in an auction
  */
  event MinBidSet(uint256 offerId, uint256 value);

  //! --------------------------------------------------------------------------- MODIFIERS ---------------------------------------------------------------------------

  /**
   * @notice Only offers that are approved or created by a moderator
   * @param offerId_ Offer id to check if approved
   */
  modifier onlyApprovedOffers(uint256 offerId_) {
    require(
      (approvedOffers[offerId_] == true) || 
      (rolesContract.isVerifiedUser(offersList[offerId_].seller)),
      'M101'
    );
    _;
  }

  /**
   *@notice the offer must be active
   *@param offerId_ the offer to check if is active
   */
  modifier onlyActiveOffers(uint256 offerId_) {
    require(isActive(offerId_), 'M113');
    _;
  }

  /**
   * @notice Only a moderator can call
   */
  modifier onlyModerator {
    require(rolesContract.isModerator(msg.sender), 'M120');
    _;
  }

  /**
   * @notice only offer must be an auction
   * @param offerId_ the offer to check if is an auction 
   */
  modifier onlyAuctions(uint256 offerId_) {
    require(isAuction(offerId_), 'M110');
    _;
  }

  /**
   *@notice only Votation Module can call 
   */
  modifier onlyVotationModule {
    require(msg.sender == moduleManager.getModule(3), 'M133');
    _;
  }

  /**
   * @notice Builder
   * @param module_ Module manager
   */
  constructor(address module_) {
    moduleManager = IModule(module_);
    address roles = moduleManager.getModule(0);
    rolesContract = IRoles(roles);
  }

  /**
   * @notice Function to refresh the addresses used in this contract
   */
  function refresh() public onlyVotationModule {
    address roles = moduleManager.getModule(0);
    rolesContract = IRoles(roles);
  }

  //! --------------------------------------------------------------------------- CREATE OFFER ---------------------------------------------------------------------------

  /**
   * @notice function to validate the params { all params } sent for create an offer
   * @param isAuction_ indicate if the offer is going to be an auction or not
   * @param endTime_ indicate the time when the offer will be end (just if is acution)
   * @param minBid_ Min bid allowed
   * @param tokenIds_ array of token's ids to sell
   * @param value_ Value of the offer
   * @param collectionAddresses_ array of collections's addresses
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
  */
  function _validateCreateParams( 
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_ 
  ) internal view {
    require (tokenIds_.length == collectionAddresses_.length , 'E806');
    require(tokenIds_.length < 6,'M127');
    require(value_ > 0, 'M102');
    require(isValidERC20(paymentToken_), 'M106');
    if (isAuction_){
      require(endTime_ > block.timestamp + 3600,'M134');
      require(value_ > minBid_, 'M103');
    } 
  }

  /**
   * @notice function to validate the ownership of the tokens of an offer
   * @param tokenIds_ array of token's ids
   * @param collectionAddresses_ array of collecti's addresesss
   * @return flag true if the offer have unapproved collection addresses
   */
  function _validateOwnership(uint256[] memory tokenIds_, address[] memory collectionAddresses_) internal view returns (bool flag) {
    for (uint256 i; i < collectionAddresses_.length; i++) {
      require(IERC721(collectionAddresses_[i]).ownerOf(tokenIds_[i]) == msg.sender, 'E413');
      require(IERC721(collectionAddresses_[i]).isApprovedForAll(msg.sender, address(this)), 'M118');
      if (!approvedERC721[collectionAddresses_[i]] && !flag) flag = true;
    }
  }

  /**
   * @notice Function to create offers 
   * @param isAuction_ If it is auction
   * @param endTime_ time when offers ends (just for auction)
   * @param minBid_ Min bid allowed
   * @param tokenIds_ array of token's ids to sell
   * @param value_ Value of the offer
   * @param collectionAddresses_ array of collections's addresses
   * @param paymentToken_ You can ask for USDT, DAI or Matic/Ether
   * @param hiddenId_ Offre's id in fireBase
   */
  function createOffer(
    bool isAuction_,
    uint48 endTime_,
    uint96 minBid_,
    uint96 value_,
    uint256[] memory tokenIds_,
    address[] memory collectionAddresses_,
    address paymentToken_,
    string memory hiddenId_
  ) public {
    _validateCreateParams(isAuction_, endTime_, minBid_, value_, tokenIds_, collectionAddresses_, paymentToken_);
    bool notApproved = _validateOwnership(tokenIds_, collectionAddresses_);
    if (!notApproved) approvedOffers[offersCount] = true;
    offersList[offersCount] = Offer(
      encodeInfo(isAuction_ ? 1 : 0, endTime_, minBid_, value_),
      encode(tokenIds_),
      collectionAddresses_,
      paymentToken_,
      msg.sender
    );
    emit OfferCreated(offersCount, hiddenId_);
    offersCount++;
  }

  //! --------------------------------------------------------------------------- BUY OFFER ---------------------------------------------------------------------------

  /**
  * @notice function to validate params from a purchase
  * @param offerId_ The offer id to check
  * @param directBuy_ Indicate if is a direct purchase {just for auctions} 
  */
  function _validateBuyParams(uint256 offerId_, bool directBuy_) internal view {
    Offer memory offer = offersList[offerId_];
    if (isAuction(offerId_) && !directBuy_) {
      require(!validateAuctionTime(offerId_), 'M111');
      require(msg.sender == auctionWinners[offerId_], 'M112');
    }
    if (offer.paymentToken == address(0)) {
      require(msg.value >= getValue(offerId_), 'M114');
    } else {
      require(IERC20(offer.paymentToken).allowance(msg.sender, address(this) ) >= getValue(offerId_),'M115');
    }
  }

  /**
   * @notice Function to transanc all tokens bought 
   * @param offerId_ The offer bought
   */
  function _transactAllTokens(uint256 offerId_) internal  {
    Offer memory offer = offersList[offerId_];
    uint256[] memory auxTokenIds = getDecodedTokenIds(offerId_);
    for (uint256 i = 0; i < offer.collectionAddresses.length; i++) {
      require(IERC721(offer.collectionAddresses[i]).ownerOf(auxTokenIds[i]) == offer.seller , 'E413');
      require(IERC721(offer.collectionAddresses[i]).isApprovedForAll(offer.seller, address(this)), 'M118');
      IERC721(offer.collectionAddresses[i]).safeTransferFrom(offer.seller, msg.sender, auxTokenIds[i], '');
    }
  }

  /** 
   * @notice For buying a fixed offer & closing an auction
   * @param offerId_ The offer to buy
   * @param directBuy_ This is just for auctions. Indicate if the if is a direct purchase
   * @param hiddenId_ The Offer's fireBase Id.
   */
  function buyOffer(uint256 offerId_, bool directBuy_, string memory hiddenId_) public payable onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) {
    _validateBuyParams(offerId_, directBuy_);
    setInactive(offerId_);
    _splitFunds(offerId_,getValue(offerId_)); //* ADDED
    _transactAllTokens(offerId_);
    emit OfferCompleted( offerId_, hiddenId_, msg.sender);
  }
  
  //! --------------------------------------------------------------------------- BID IN AUCTION ---------------------------------------------------------------------------

  /**
   * @notice Function to validate bid parameters to bid in an auction
   * @param offerId_ The auction to check
   * @param value_ The value to chek
   */
  function _validateBidParams(uint256 offerId_, uint256 value_) internal view {
    require((value_ > 0) && (getMinBid(offerId_) < value_), 'M121');
    require(validateAuctionTime(offerId_),'M107');
  }

  /**
   * @notice Function to validate if the msg.sender have enough balance to bid in an auction
   * @param offerId_ The auction to check
   * @param value_ The value to check
   */
  function _validateUserBalance(uint256 offerId_, uint256 value_) internal view {
    uint balance = getActualBalance(msg.sender, offersList[offerId_].paymentToken);
    require(value_ < balance, 'M123');
  }

  /**
   * @notice function that allows to bid in an auction
   * @param offerId_ The auction id
   * @param value_ The value to bid
   */
  function bidForAuction(uint256 offerId_, uint256 value_, string memory id) public onlyActiveOffers(offerId_) onlyApprovedOffers(offerId_) onlyAuctions(offerId_)  {
    _validateBidParams(offerId_, value_);
    _validateUserBalance(offerId_, value_);
    setMinBid(offerId_, value_);
    auctionWinners[offerId_] = msg.sender;
    emit BiddedForAuction(msg.sender, offerId_, value_, id);
  }

  //! ------------------------------------------------------------------------- ROYALTIES --------------------------------------------------------------------------

  /**
   * @notice function to send ERC20 founds
   * @param offerId_ offerId to check
   * @param to_ who will receive the funds
   * @param value_ the amount to send
  */
  function _sendFunds(uint256 offerId_,address to_, uint256 value_) internal {
    if (offersList[offerId_].paymentToken == address(0)) {
      (bool success, ) = payable(to_).call{ value: value_ }("");
      require(success, "M117");
    } else {
      require ( IERC20(offersList[offerId_].paymentToken).transferFrom(
        msg.sender,
        to_,
        value_
      ), 'M120');
    }
  }

  /**
  * @notice Function to transfer royalies to Beru { wallet }
  * @param value_ amount from which the commission percentage is calculated
  * @return toBeru amount tranfered to beru
  */
  function _sendRoyaltiesToBeru(uint256 offerId_, uint256 value_)  internal returns (uint256 toBeru) {
    toBeru = value_ * beruRoyalies / 1000 ; // %<0
    _sendFunds(offerId_,beruWallet,toBeru);
    emit RoyaltiesSended(beruWallet,toBeru);
  }


  /**
  * @notice Function to send royalties to the NFT's creators 
  * @param offerId_ offer involved
  * @param value_  price paid for the offer
  * @return toCreators amount of roayalities transfered to creators
  */
  function _sendRoyaltiesToCreators(uint256 offerId_, uint256 value_)  internal returns (uint256 toCreators) {
    address[] memory collectionAddrees_ = offersList[offerId_].collectionAddresses;
    uint256 aux = value_ / collectionAddrees_.length;
    for(uint i = 0; i < collectionAddrees_.length; i++) {
        IERC721 proxy = IERC721(collectionAddrees_[i]);
        if (proxy.getRoyalties() > 0) {
          uint256 toTransfer = aux * proxy.getRoyalties() /1000;
          _sendFunds(offerId_,proxy.deployer(), toTransfer);
          toCreators += toTransfer;
          emit RoyaltiesSended(proxy.deployer(), toTransfer);
        }
    }
  }

  /**
  * @notice function to send founsd and royalties to collectio's creators, beru and the seller
  * @param offerId_ the offer finished and bought
  * @param value_ price paid for the offer
  */
  function _splitFunds(uint256 offerId_, uint256 value_)  internal {
    uint256 royaltiesToBeru = _sendRoyaltiesToBeru(offerId_,value_);
    uint256 royaltiesToCreators = _sendRoyaltiesToCreators(offerId_,value_);
    uint256 fundsToSeller = value_ - royaltiesToBeru - royaltiesToCreators;
    _sendFunds(offerId_, offersList[offerId_].seller , fundsToSeller);
    emit FundsSended(royaltiesToBeru , royaltiesToCreators , fundsToSeller);
  }

  //! --------------------------------------------------------------------------- Encode  & Decode ---------------------------------------------------------------------------

  /**
   * @notice Function to encode {auction, endtime, min, value} in info's encoded parameter
   * @param isAuction_ True or false 0 / 1 if is auction
   * @param endTime_ time when auctions ends (just for auctions)
   * @param min_ min bid (just for auctions)
   * @param value_ the offer's value for purchase
   * @return finalValue_ the params encoded in a uint
   */
  function encodeInfo(
    uint isAuction_,
    uint48 endTime_,
    uint96 min_,
    uint96 value_
  ) internal pure returns (uint finalValue_) {
    finalValue_ = (1 * (10 ** 75)) + (1 * (10 ** 74)) + (isAuction_ * (10 ** 73)) + (uint(endTime_) * (10 ** 58)) + (uint(min_) * (10 ** 29)) + (value_);
  }

  /**
   * @notice This is made to encode an array of uints and return just a uint
   * @param array_ is an array that has the ids to encode
   * @return aux have the ids encoded
   */
  function encode(uint[] memory array_) public pure returns (uint256 aux) {
    for (uint i; i < array_.length; ++i) {
      aux += array_[i] * (10 ** (i * 15));
    }
    aux += array_.length * 1e75;
  }

  /** 
   * @notice This is made to decode a uint an retunrn an array of ids
   * @param encoded_ This uint has encoded up to 5 ids that correspond to an array
   * @return tokenIds This array have the ids decoded
   */
  function decode(uint encoded_) public pure returns (uint[] memory tokenIds){
    uint amount = (encoded_ / 1e75) % 1e15;
    tokenIds = new uint[](amount); 
    for (uint i; i < amount; ++i){
      tokenIds[i] = (encoded_ / (10 ** (i * 15)) % 1e15);
    }
  }

  //! --------------------------------------------------------------------------- SETTERS ---------------------------------------------------------------------------

  /**
   * @notice validate an ERC721 collection
   * @param erc721_ collection address
   * @param validated_ new status of this ERC721 collection
   */
  function validateERC721(address erc721_, bool validated_) public onlyModerator {
    approvedERC721[erc721_] = validated_;
    emit ChangeStatusERC721(erc721_, msg.sender, validated_);
  }
 
  /**
   * @notice This is made to approve a valid offer
   * @param offerId_ The offer id to validate
   */
  function approveOffer(uint offerId_) public onlyModerator onlyActiveOffers(offerId_) {
    approvedOffers[offerId_] = true;
    emit OfferApproved(offerId_);
  }

  /**
   * @notice function to set status active in an offer
   * @param offerId_ offerId to set active
   */
  function setInactive(uint offerId_) internal { 
    require(isActive(offerId_),'M108');
    offersList[offerId_].info = offersList[offerId_].info - (1 * 1e74);
  }

  /**
   * @notice function to set the minBid in an auction
   * @param offerId_ the offer id to set the minBid
   * @param min_ the value to set
   */
  function setMinBid(uint offerId_, uint min_) internal {
    offersList[offerId_].info = ((offersList[offerId_].info / 1e58) * 1e58 ) + (min_ * 1e29) + (offersList[offerId_].info % 1e29);
    emit MinBidSet(offerId_, min_);
  }

  /**
   * @notice Function to deprecate any active offer
   * @param offerId_ The offer id to deprecate
   */
  function deprecateOffer(uint256 offerId_) public onlyModerator onlyActiveOffers(offerId_)  {
    setInactive(offerId_);
    emit OfferCancelled(offerId_);
  }

  /**
   * @notice Validate an ERC20 token as payment method
   * @param token_ The token address
   * @param validated_ If is validated or not
   */
  function validateERC20(address token_, bool validated_) public onlyVotationModule {
    validERC20[token_] = validated_;
    emit ERC20Validated(token_, validated_);
  }

  /**
  * @notice Function to set {bidder_} as winner of the auction {offerId_}
  * @param offerId_ Offer index
  * @param newWinner_ The consecuent highest bidder of the auction 
  */
  function setWinner(uint256 offerId_, address newWinner_) public onlyModerator {
    (uint256 oldWinnerBalance, uint256 newWinnerBalance) = 
      (
        getActualBalance(auctionWinners[offerId_], offersList[offerId_].paymentToken),
        getActualBalance(newWinner_, offersList[offerId_].paymentToken)
      );
    require(getMinBid(offerId_) > oldWinnerBalance,'M129');
    require(getMinBid(offerId_) <= newWinnerBalance,'M130');
    auctionWinners[offerId_] = newWinner_;
    emit ChangedWinner(offerId_, newWinner_);
  }

  /**
   * @notice function to set Beru Wallet address
   * @param address_ the new address
  */
  function setBeruWallet(address address_) public onlyVotationModule() {
    beruWallet = address_;
    emit BeruWalletSet(address_);
  }

  /**
   * @notice function to set Beru Royalties
   * @param value_ value of the new royalties
  */
  function setBeruRoyalties(uint256 value_) public onlyVotationModule() {
    require(value_<=1000,'M109');
    beruRoyalies = value_;
    emit BeruRoyaliesSet(value_);
  }

//! --------------------------------------------------------------------------- GETTERS ---------------------------------------------------------------------------

   /**
   * @notice function to return the {isActive} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function isActive(uint offerId_) public view returns (bool) {
    return ((offersList[offerId_].info / 1e74) % 10) == 1 ? true : false;
  }

  /**
   * @notice function to return the {isAuction} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function isAuction(uint offerId_) public view returns (bool) {
    return ((offersList[offerId_].info / 1e73) % 10) == 1 ? true : false;
  }

  /**
   * @notice function to return the {endTime} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getEndTime(uint offerId_) public view returns (uint) {
    return (offersList[offerId_].info / 1e58) % 1e15;
  }

  /**
   * @notice function to return the {minBid} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getMinBid(uint offerId_) public view returns (uint) {
    return (offersList[offerId_].info / 1e29) % 1e29;
  }

  /**
   * @notice function to return the {value} encoded in info
   * @param offerId_ the offerId where we get the data
   */
  function getValue(uint offerId_) public view returns (uint) {
    return offersList[offerId_].info % 1e29;
  }

  /**
   * @notice function to return an array of token Ids previusly encoded
   * @param offerId_ the offerId where we get the data
   */
  function getDecodedTokenIds(uint offerId_) public view returns (uint[] memory) {
     return decode(offersList[offerId_].tokenIds);
  }

  /**
   * @notice Validates if an auction is still valid or not
   * @param offerId_ The auction
   * @return valid if it is valid or not
   */
  function validateAuctionTime(uint256 offerId_) public view onlyAuctions(offerId_) returns (bool) {
    return getEndTime(offerId_) > block.timestamp;
  }

  /**
   * @notice Function to check if {token_} is a validERC20 for payment method
   * @param token_ The token address
   * @return bool if {token_} is valid
   */
  function isValidERC20(address token_) public view returns (bool) {
    return validERC20[token_];
  }

  /**
   * @notice Helper function that returns the balance of {who} in {paymentToken} token
   * @param who_ Address to check balance
   * @param paymentToken_ Address of the token to check
   */
  function getActualBalance(address who_, address paymentToken_) public view returns (uint balance) {
    if (paymentToken_ == address(0))
      balance = address(who_).balance;
    else balance = IERC20(paymentToken_).balanceOf(who_);
  }

  /**
   * @notice function to get the encoded collection address uint
   * @param offerId_ offer Id to check
   */
  function getCollectionAddresses(uint256 offerId_) public view returns (address[] memory){
    return offersList[offerId_].collectionAddresses;
  }

}