// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "../interfaces/IAuctioneer.sol";
import "./AuctioneerAdmin.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../vendors/ExtendedBitmap.sol";
import "../interfaces/IRedemptionManager.sol";
import "../libraries/GrtLibrary.sol";

contract Auctioneer is IAuctioneer, AuctioneerAdmin, IERC721Receiver {
  using ExtendedBitmap for ExtendedBitmap.BitMap;
  using BitMaps for BitMaps.BitMap;
  ITokenContract public immutable liquidToken;
  uint128 public override releaseCounter = 0;
  uint128 public override listingCounter = 0;

  BitMaps.BitMap private dirtyTokens;

  mapping(uint128 => Release) public override releases;
  mapping(uint128 => uint256) public override pendingEth;

  ExtendedBitmap.BitMap internal bidTokens;
  ExtendedBitmap.BitMap internal soldTokens;

  IRedemptionManager public redemptionManager;

  constructor(
    address superUser,
    address _liquidToken,
    address _redemptionManager
  ) AuctioneerAdmin(superUser) {
    GrtLibrary.checkZeroAddress(superUser, "super user");
    GrtLibrary.checkZeroAddress(_liquidToken, "liquid token");
    GrtLibrary.checkZeroAddress(_redemptionManager, "redemption manager");

    liquidToken = ITokenContract(_liquidToken);
    redemptionManager = IRedemptionManager(_redemptionManager);
  }

  function _incrementReleaseCounter()
    internal
    returns (uint128 incrementedCount)
  {
    // Represents 3.402824 × 10^38 - several orders of magnitude more releases than we expect to ever create, hence this should never reasonably over-flow
    unchecked {
      incrementedCount = releaseCounter + 1;
      releaseCounter = incrementedCount;
    }
  }

  function _incrementListingCounter()
    internal
    returns (uint128 incrementedCount)
  {
    unchecked {
      incrementedCount = listingCounter + 1;
      listingCounter = incrementedCount;
    }
  }

  function _createRelease(bytes[] calldata tokenURIs)
    internal
    returns (Release memory release, uint128 releaseId)
  {
    ITokenContract.MintArgs[] memory mintArray = new ITokenContract.MintArgs[](
      tokenURIs.length
    );
    for (uint16 i = 0; i < tokenURIs.length; i++) {
      mintArray[i] = ITokenContract.MintArgs({
        to: address(this),
        tokenURI: string(tokenURIs[i])
      });
    }
    releaseId = _incrementReleaseCounter();
    emit ReleaseCreated(releaseCounter);
    uint128 tokenCount = uint128(liquidToken.mint(mintArray));
    release = Release({
      listingId: 0,
      startTokenId: (tokenCount - uint128(tokenURIs.length)) + 1,
      endTokenId: tokenCount,
      listingType: 0
    });
  }

  function _createListing(
    Release memory release,
    IListing.Listing memory listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) internal returns (Release memory _release) {
    if (release.endTokenId == 0) {
      revert InvalidRelease(msg.sender, listing.releaseId);
    }
    _release = release;
    uint128 currentId = _incrementListingCounter();
    IListing listingContract = listingRegistry[listingType];

    _release.listingId = currentId;
    _release.listingType = listingType;
    listingContract.createListing(currentId, listing, data);
    if (releaseDate != 0) {
      redemptionManager.setTimeLock(listing.releaseId, releaseDate);
      emit TimeLockSet(listing.releaseId, releaseDate);
    }
  }

  function _callSendEth(address destination, uint256 amount) internal {
    GrtLibrary.checkZeroAddress(destination, "destination");
    (bool success, ) = destination.call{value: amount}("");
    if (!success) {
      revert EthTransferFailed();
    }
  }

  function hasBid(uint128 tokenId) public view override returns (bool status) {
    status = bidTokens.get(tokenId);
  }

  function hasSold(uint128 tokenId) public view override returns (bool status) {
    status = soldTokens.get(tokenId);
  }

  function createRelease(bytes[] calldata tokenURIs)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    (Release memory release, uint128 releaseId) = _createRelease(tokenURIs);
    releases[releaseId] = release;
  }

  function createListing(
    IListing.Listing calldata listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[listing.releaseId];
    if (release.listingId != 0) {
      revert ReleaseAlreadyListed(msg.sender, listing.releaseId);
    }
    releases[listing.releaseId] = _createListing(
      release,
      listing,
      listingType,
      releaseDate,
      data
    );
  }

  function createReleaseAndList(
    uint8 listingType,
    bytes[] calldata tokenURIs,
    IListing.Listing memory listing,
    uint256 releaseDate,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    (Release memory release, uint128 releaseId) = _createRelease(tokenURIs);
    listing.releaseId = releaseId;
    releases[releaseId] = _createListing(
      release,
      listing,
      listingType,
      releaseDate,
      data
    );
  }

  function updateListing(
    uint8 listingType,
    uint128 listingId,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    IListing listingContract = listingRegistry[listingType];
    listingContract.updateListing(listingId, listing, data);
  }

  function deleteListing(uint8 listingType, uint128 listingId)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    IListing listingContract = listingRegistry[listingType];
    listingContract.deleteListing(listingId);
  }

  function relistRelease(
    uint128 releaseId,
    uint8 newListingType,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    IListing listingContract = listingRegistry[release.listingType];
    if (!(listingContract.listingEnded(release.listingId))) {
      revert ListingActive(release.listingId);
    }

    for (
      uint256 i = release.startTokenId >> 8;
      i <= release.endTokenId >> 8;
      i++
    ) {
      uint256 bid = bidTokens.getMaskedBucket(
        release.startTokenId,
        release.endTokenId,
        i * 256
      );
      uint256 sold = soldTokens.getMaskedBucket(
        release.startTokenId,
        release.endTokenId,
        i * 256
      );
      soldTokens.setBucket(i, bid | sold);
    }
    releases[releaseId] = _createListing(
      release,
      listing,
      newListingType,
      0,
      data
    );
  }

  function placeBid(
    uint128 releaseId,
    uint128 tokenId,
    bytes calldata data
  ) external payable {
    Release memory release = releases[releaseId];
    if (allListingsPaused || pausedListings.get(release.listingId)) {
      revert ListingPaused();
    }
    _tokenInRelease(release, tokenId);
    if (soldTokens.get(tokenId)) {
      revert TokenAlreadySold();
    }
    IListing listingContract = listingRegistry[release.listingType];
    IListing.Bid memory bid = IListing.Bid({
      bidder: msg.sender,
      amount: msg.value
    });
    bidTokens.set(tokenId);
    pendingEth[release.listingId] += msg.value;
    listingContract.registerBid(release.listingId, tokenId, bid, data);
  }

  function transferEth(
    uint8 listingType,
    uint128 listingId,
    address destination,
    uint256 amount
  ) external override onlyListingOperator(listingType) {
    pendingEth[listingId] -= amount;
    _callSendEth(destination, amount);
  }

  function transferToken(
    uint8 listingType,
    uint128 tokenId,
    address destination
  ) external onlyListingOperator(listingType) {
    soldTokens.set(tokenId);
    liquidToken.safeTransferFrom(address(this), destination, tokenId);
  }

  function claimToken(
    uint128 releaseId,
    uint128 tokenId,
    uint128 listingId,
    uint8 listingType
  ) external override {
    Release memory release = releases[releaseId];
    _tokenInRelease(release, tokenId);
    IListing listingInstance = listingRegistry[listingType];
    emit TokenClaimed(msg.sender, tokenId);
    listingInstance.validateTokenClaim(
      listingId,
      releaseId,
      tokenId,
      msg.sender
    );
    liquidToken.safeTransferFrom(address(this), msg.sender, tokenId);
  }

  function withdrawProceeds(
    Withdrawal[] memory withdrawals,
    address destination
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    uint256 withdrawalTotal = 0;
    uint128[] memory listings = new uint128[](withdrawals.length);

    for (uint16 i = 0; i < withdrawals.length; i++) {
      IListing listingInstance = listingRegistry[withdrawals[i].listingType];
      if (!listingInstance.listingEnded(withdrawals[i].listingId)) {
        revert ListingActive(withdrawals[i].listingId);
      }
      withdrawalTotal += pendingEth[withdrawals[i].listingId];
      listings[i] = withdrawals[i].listingId;
      delete pendingEth[withdrawals[i].listingId];
    }
    emit ProceedsWithdrawn(destination, listings);
    _callSendEth(destination, withdrawalTotal);
  }

  function withdrawTokens(
    uint128 releaseId,
    uint128[] calldata tokens,
    address destination
  ) external override onlyRole(PLATFORM_ADMIN_ROLE) {
    Release memory release = releases[releaseId];
    IListing listingInstance = listingRegistry[release.listingType];
    if (!(listingInstance.listingEnded(release.listingId))) {
      revert ListingActive(release.listingId);
    }
    for (uint16 i = 0; i < tokens.length; i++) {
      _tokenInRelease(release, tokens[i]);
      if (bidTokens.get(tokens[i]) || soldTokens.get(tokens[i])) {
        revert TokenHasBid(tokens[i]);
      }
      soldTokens.set(tokens[i]);
      liquidToken.safeTransferFrom(address(this), destination, tokens[i]);
    }
    emit TokensWithdrawn(destination, release.listingId, tokens);
  }

  function _tokenInRelease(Release memory release, uint128 tokenId)
    internal
    pure
  {
    if (release.startTokenId > tokenId || tokenId > release.endTokenId) {
      revert TokenNotInRelease(tokenId);
    }
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external pure override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
  }

  //#########################
  //####### SETTERS ########

  function setRedemptionManager(address _redemptionManager)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    redemptionManager = IRedemptionManager(_redemptionManager);
  }

  modifier onlyListingOperator(uint8 listingType) {
    if (msg.sender != address(listingRegistry[listingType])) {
      revert InvalidTransferOperator();
    }
    _;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IListing.sol";
import "./ITokenContract.sol";
import "./IAuctioneerAdmin.sol";

/// @title GRT Wines Auctioneer
/// @author Sean L
/// @notice The nerve centre of the Auctioning system for GRT. Responsible for routing calls to relevant implementation contracts for purchase and token logi
interface IAuctioneer is IAuctioneerAdmin {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for creating a Release which could include one or more tokens. E.g a box of six wines
  /// @param listingType The identifier of the auction contract which manages sale logic. Up to 255
  /// @param listingId The listing identifier - Counter from Auctioneer contract
  /// @param startTokenId Start point of included tokens
  /// @param endTokenId The end of the token range to auction
  struct Release {
    uint128 listingId;
    uint128 startTokenId;
    uint128 endTokenId;
    uint8 listingType;
  }

  /// @param listingId The release identifier - Counter from Auctioneer contract
  /// @param listingType  The identifier of the auction contract which manages sale logic
  struct Withdrawal {
    uint128 listingId;
    uint8 listingType;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a Release is created
  event ReleaseCreated(uint128 releaseId);

  /// @dev Emitted on successful token claim
  event TokenClaimed(address claimant, uint128 tokenId);

  /// @dev Emitted when unsold tokens are withdrawn
  event TokensWithdrawn(
    address indexed receiver,
    uint128 listingId,
    uint128[] tokens
  );

  /// @dev Emitted when proceeds from listings are withdrawn successfully
  event ProceedsWithdrawn(
    address indexed receiver,
    uint128[] listingIds
  );

  /// @dev Emitted on successful setting of a Time Lock
  event TimeLockSet(uint256 indexed releaseId, uint256 indexed releaseDate);

  //################
  //#### ERRORS ####

  /// @dev Thrown if an account attempts to create a listing for a release that already has a listing
  error ReleaseAlreadyListed(address sender, uint128 releaseId);

  /// @dev Thrown if the provided releaseId does not exist
  error InvalidRelease(address sender, uint128 releaseId);

  /// @dev Thrown if an account attempts to withdraw an un-sold token that is not included in the release ID provided
  error TokenNotInRelease(uint128 tokenId);

  /// @dev Thrown if an account attempts to withdraw a token that already has a bid
  error TokenHasBid(uint128 tokenId);

  /// @dev Thrown everytime unless msg.sender is the address of the listingRegistry itself
  error InvalidTransferOperator();

  /// @dev Thrown if an ETH transfer fails
  error EthTransferFailed();

  /// @dev Thrown if operations attempt to be performed on a release with a listing that is still active
  /// @param listingId The listing ID that is still considered active
  error ListingActive(uint128 listingId);

  ///@dev Thrown if the token has already sold or been otherwise withdrawn
  error TokenAlreadySold();

  //###################
  //#### FUNCTIONS ####

  /// @notice Create a release for tokens
  /// @dev Calls the liquid token contract to mint a sequential range of tokens with URIs from the tokenURIs array
  /// @param tokenURIs The URIs to be assigned to the tokens
  function createRelease(bytes[] calldata tokenURIs) external;

  /// @notice Create a listing for a release
  /// @dev Creates a Listing at the target contract based on the provided listingType
  /// @param listing The listing data
  /// @param listingType The type of listing this should be e.g EnglishAuction, Buy It Now
  /// @param releaseDate The date at which the listing is published.
  /// @param data Arbitrary additional data to be passed to the Listing contract, should additional data be required by new listing types in future
  function createListing(
    IListing.Listing calldata listing,
    uint8 listingType,
    uint256 releaseDate,
    bytes calldata data
  ) external;

  /// @notice Create a release and list in at a listing contract with one call
  /// @param listingType The listing type identifer
  /// @param tokenURIs Token URIs to be used to create a Release prior to Listing creation
  /// @param releaseDate The date at which the release is published.
  /// @param listing The listing data to pass to the listing contract
  /// @param data Arbitrary additional data should requirements change in future
  function createReleaseAndList(
    uint8 listingType,
    bytes[] calldata tokenURIs,
    IListing.Listing memory listing,
    uint256 releaseDate,
    bytes calldata data
  ) external;

  /// @notice Update a listing
  /// @dev Cannot update an active listing
  /// @param listingType The listing type identifer
  /// @param listingId The identifier of the listing to be updated
  /// @param listing The listing data to update the existing listing with
  /// @param data Arbitrary additional data should requirements change in future
  function updateListing(
    uint8 listingType,
    uint128 listingId,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Delete a listing
  /// @dev Cannot delete a listing once it has started
  /// @param listingType The listing type ID of the target listing contract
  /// @param listingId The listing ID of the listing itself
  function deleteListing(uint8 listingType, uint128 listingId) external;

  /// @notice Relist a release, maintaining funds stored in the Auctioneer
  /// @dev Assigns a new listing ID and sets new listing information on the target contract
  /// @dev Calls create listing on the target contract, even if the target is the same as the old one
  /// @param releaseId The release ID this relisting targets
  /// @param listing The listing information to relist with
  /// @param data Arbitrary additional data
  function relistRelease(
    uint128 releaseId,
    uint8 newListingType,
    IListing.Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Place a bid on a token
  /// @dev Listing must be active and not paused or all listings paused
  /// @param releaseId The ID of the release for this bid
  /// @param tokenId The token ID to be bid on
  /// @param data Arbitrary additional data
  function placeBid(
    uint128 releaseId,
    uint128 tokenId,
    bytes calldata data
  ) external payable;

  /// @notice Callback function for listing contracts to return ETH of the previous highest bidder once they are out-bid
  /// @dev Can ONLY be used as a callback from a listing contract - if msg.sender != listingRegistry[listingId] it reverts
  /// @param listingType The listing ID of the contract doing the callback
  /// @param listingId The ID of the listing
  /// @param destination The destination for the ETH transfer (previous higest bidder)
  /// @param amount The value of ETH to send
  function transferEth(
    uint8 listingType,
    uint128 listingId,
    address destination,
    uint256 amount
  ) external;

  /// @notice Callback function for listing contracts to send tokens to a user for immediate settlement listings - e.g buy it now
  /// @dev Can ONLY be used as a callback from a listing contract - if msg.sender != listingRegistry[listingId] it reverts
  /// @param listingType The listing ID of the contract doing the callback
  /// @param tokenId The ID of the token to be transferred
  /// @param destination The destination for the ETH transfer (previous higest bidder)
  function transferToken(
    uint8 listingType,
    uint128 tokenId,
    address destination
  ) external;

  /// @notice Claim a token that has been won via a non-immediate settlement sale, i.e Auction
  /// @dev Performs check at the target contract to verify the highest bidder, listing has ended etc
  /// @param tokenId The ID of the token to be checked
  /// @param listingId The ID of the listing this token was won in
  /// @param listingType The listing type this was one from
  function claimToken(
    uint128 releaseId,
    uint128 tokenId,
    uint128 listingId,
    uint8 listingType
  ) external;

  /// @notice Withdraw proceeds for a listing
  /// @dev checks each listing to verify that the sale has finished. Sends the funds for each listing to the destination. withdrawal = listing(A) + listing(B)... + listing(N)
  /// @param withdrawals Withdrawals to complete - see listing struct
  /// @param destination The destination address for the proceeds
  function withdrawProceeds(
    Withdrawal[] memory withdrawals,
    address destination
  ) external;

  /// @notice Withdraw un-sold tokens.
  /// @dev If tokens are withdrawn from the auctioneer they cannot be relisted for sale via the current auctioning system
  /// @param releaseId The release ID these tokens belong to
  /// @param tokens Array of token IDs
  /// @param destination The destination for the tokens to be withdrawn to
  function withdrawTokens(
    uint128 releaseId,
    uint128[] calldata tokens,
    address destination
  ) external;

  ///@notice Getter for specific bit in hasBid bitmap
  ///@param tokenId The token ID
  ///@return status Whether or not the token has a bid
  function hasBid(uint128 tokenId) external view returns (bool status);

  ///@notice Getter for specific bit in hasSold bitmap
  ///@param tokenId The token ID
  ///@return  status Whether or not the token has sold
  function hasSold(uint128 tokenId) external view returns (bool status);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  function releaseCounter() external returns (uint128 currentValue);

  function listingCounter() external returns (uint128 currentValue);

  ///@notice Setter for setting the redemption manager.
  ///@dev sets the address for the redemption manager so that calls to the Redemption Manager can be made.
  ///@param _redemptionManager the address of the redemption manager.
  function setRedemptionManager(address _redemptionManager) external;

  function releases(uint128 releaseId)
    external
    returns (
      uint128 listingId,
      uint128 startTokenId,
      uint128 endTokenId,
      uint8 listingType
    );

  function pendingEth(uint128 listingId) external returns (uint256 pending);

  function liquidToken() external returns (ITokenContract tokenContract);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "../interfaces/IAuctioneerAdmin.sol";
import "../interfaces/IListing.sol";
import "../interfaces/IGrtWines.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "../libraries/GrtLibrary.sol";

contract AuctioneerAdmin is IAuctioneerAdmin, IGrtWines, AccessControl {
  using BitMaps for BitMaps.BitMap;
  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");

  bool public override allListingsPaused = false;

  // Bitmap of listings that are current paused
  BitMaps.BitMap internal pausedListings;

  // Listing type ID  => listing contract instance
  mapping(uint8 => IListing) public override listingRegistry;
  // Listing contract address => Listing type ID
  mapping(address => uint8) public override addressListingLookup;

  constructor(address superUser) {
    GrtLibrary.checkZeroAddress(superUser, "super user");
    _grantRole(DEFAULT_ADMIN_ROLE, superUser);
  }

  // Internal function for pausing or unpausing all listings
  function _changeAllPause(bool status) internal {
    allListingsPaused = status;
    emit AllListingStatusChanged(msg.sender, status);
  }

  function registerListingType(uint8 listingType, address listingContract)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(listingContract, "listing contract");
    if (address(listingRegistry[listingType]) != address(0)) {
      revert ListingIdTaken();
    }
    listingRegistry[listingType] = IListing(listingContract);
    addressListingLookup[listingContract] = listingType;
    emit ListingTypeCreated(listingContract, listingType);
  }

  function pauseListing(uint128 listingId)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    if (pausedListings.get(listingId) == true) {
      revert ListingStatusAlreadySet();
    }
    pausedListings.setTo(listingId, true);
    emit ListingStatusChanged(listingId, true);
  }

  function unpauseListing(uint128 listingId)
    external
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    if (pausedListings.get(listingId) == false) {
      revert ListingStatusAlreadySet();
    }
    pausedListings.setTo(listingId, false);
    emit ListingStatusChanged(listingId, false);
  }

  function listingPauseStatus(uint128 listingId)
    external
    view
    returns (bool status)
  {
    status = pausedListings.get(listingId);
  }

  function pauseAllListings() external onlyRole(PLATFORM_ADMIN_ROLE) {
    if (allListingsPaused) {
      revert ListingStatusAlreadySet();
    }
    _changeAllPause(true);
  }

  function unpauseAllListings() external onlyRole(PLATFORM_ADMIN_ROLE) {
    if (!allListingsPaused) {
      revert ListingStatusAlreadySet();
    }
    _changeAllPause(false);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

library ExtendedBitmap {
  struct BitMap {
    mapping(uint256 => uint256) _data;
  }

  function getBucket(BitMap storage bitmap, uint256 bucketIndex)
    internal
    view
    returns (uint256 _bucket)
  {
    _bucket = bitmap._data[bucketIndex];
  }

  function setBucket(
    BitMap storage bitmap,
    uint256 bucketIndex,
    uint256 bucketContents
  ) internal {
    bitmap._data[bucketIndex] = bucketContents;
  }

  function getMaskedBucket(
    BitMap storage bitmap,
    uint256 startIndex,
    uint256 endIndex,
    uint256 index
  ) internal view returns (uint256) {
    uint256 startBucket = startIndex >> 8;
    uint256 endBucket = endIndex >> 8;
    uint256 currentBucket = index >> 8;
    uint256 result = getBucket(bitmap, currentBucket);
    //If the currentBucket we're accessing is the first bucket for this range of bits, mask the first N bits
    if (currentBucket == startBucket) {
      //The number of bits we want to mask off the start of the word
      uint256 maskNStarting = startIndex - 256 * startBucket;
      result &= type(uint256).max << maskNStarting;
    }
    //If the currentBucket we're accessing is the last bucket for this range of bits, mask the last N bits
    if (currentBucket == endBucket) {
      //The number of bits we want to mask off the end of the word
      uint256 maskNEnding = 255 - (endIndex - 256 * endBucket);
      result &= type(uint256).max >> maskNEnding;
    }
    return result;
  }

  // ################################################################
  // ## ALL BELOW FUNCTIONS ARE DIRECTLY COPIED FROM OPEN-ZEPPELIN ##
  // ################################################################

  /**
   * @dev Returns whether the bit at `index` is set.
   */
  function get(BitMap storage bitmap, uint256 index)
    internal
    view
    returns (bool)
  {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    return bitmap._data[bucket] & mask != 0;
  }

  /**
   * @dev Sets the bit at `index` to the boolean `value`.
   */
  function setTo(
    BitMap storage bitmap,
    uint256 index,
    bool value
  ) internal {
    if (value) {
      set(bitmap, index);
    } else {
      unset(bitmap, index);
    }
  }

  /**
   * @dev Sets the bit at `index`.
   */
  function set(BitMap storage bitmap, uint256 index) internal {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    bitmap._data[bucket] |= mask;
  }

  /**
   * @dev Unsets the bit at `index`.
   */
  function unset(BitMap storage bitmap, uint256 index) internal {
    uint256 bucket = index >> 8;
    uint256 mask = 1 << (index & 0xff);
    bitmap._data[bucket] &= ~mask;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "../implementations/TokenContract.sol";
import "./IGrtWines.sol";

/// @title GrtWines Redemption Manager Contract
/// @author Sean Long
/// @notice Used to manage the process of converting a Liquid Token (sitll in the Warehouse) to a Redeemed Token (Sent to the owner). User's may submit their token for redemption and the warehouse then either aborts or finalizes the redemption
/// @dev This contract needs BURNER_ROLE on the Liquid Token contract and MINTER_ROLE on the Redeemed Token Contract
/// @dev PLATFORM_ADMIN_ROLE and WAREHOUSE_MANAGER_ROLE are used to protect functions
/// @dev DEFAULT_ADMIN_ROLE is not utilised for any purpose other than being the admin for all other roles
interface IRedemptionManager is IGrtWines {
  //################
  //#### STRUCTS ####

  //################
  //#### EVENTS ####
  /// @dev Emitted on successful redemption creation
  event RedemptionCreated(address indexed sender, uint256 indexed tokenId);

  /// @dev Emitted on successful redemption finalisation
  event RedemptionFinalised(address indexed sender, uint256 indexed tokenId);

  /// @dev Emitted on successful redemption finalisation
  event RedemptionAborted(address indexed sender, uint256 indexed tokenId);

  //################
  //#### ERRORS ####

  /// @dev Thrown if the sender attempts to deploy with {platformAdmin} and {superUser} set to the same address
  error AdminSuperUserMatch();

  /// @dev Thrown if the user does not posses the correct redeemable status.
  /// @param releaseId the release for which a redemption is being created.
  error RedeemableStatusIncorrect(uint256 releaseId);

  /// @dev Thrown if the user tries to set the timelock release date to before the current block time.
  /// @param releaseDate the release date which the token is redeemable from
  error ReleaseDateInvalid(uint256 releaseDate);

  //###################
  //#### FUNCTIONS ####
  /// @notice Utilised to create a redemption. Transfers the token to this contract as escrow and sets {originalOwners}
  /// @dev Account must {approveForAll} or {approve} for the specific token to redeeem
  /// @param tokenId - The token to be redeemed
  /// @param releaseId the release for which a redemption is being redeemed.
  function createRedemption(uint256 tokenId, uint256 releaseId) external;

  /// @notice Utilised to bulk finalise tokens
  /// @dev Account must have WAREHOUSE_MANAGER_ROLE to use
  /// @dev {createRedemption} must be called first. ERC721 0 address checks will fail if calling with tokens that haven't yet had a redemption created
  /// @param tokens - Array of tokens to finalise
  function finaliseRedemption(uint256[] calldata tokens) external;

  /// @notice Utilised to abort the redemption of a token
  /// @dev Account must have PLATFORM_ADMIN_ROLE to use
  /// @dev Returns the token to the original owner and deletes the value at {originalOwners}
  /// @param tokenId - Array of {FinaliseArgs} - see for more docs
  function abortRedemption(uint256 tokenId) external;

  /// @notice Utilised to set a time lock on the redemption of a token
  /// @dev Account must have PLATFORM_ADMIN_ROLE or AUCTIONEER_ROLE to use
  /// @dev Sets the time value for a release in the timelock mapping in the Timelock contract
  /// @param releaseId - the release to update the timelock for.
  /// @param releaseDate - the date to set the timelock to.
  function setTimeLock(uint256 releaseId, uint256 releaseDate) external;

  //#################
  //#### GETTERS ####
  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);

  function WAREHOUSE_MANAGER_ROLE() external returns (bytes32 role);

  function AUCTIONEER_ROLE() external returns (bytes32 role);

  function originalOwners(uint256 tokenId) external returns (address owner);

  function liquidToken() external returns (TokenContract implementation);

  function redeemedToken() external returns (TokenContract implementation);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/// @notice Helpers for GRT Wines contracts
library GrtLibrary {
  /// @dev Thrown whenever a zero-address check fails
  /// @param field The name of the field on which the zero-address check failed
  error ZeroAddress(bytes32 field);

  /// @notice Check if a field is the zero address, if so revert with the field name
  /// @param _address The address to check
  /// @param _field The name of the field to check
  function checkZeroAddress(address _address, bytes32 _field) internal pure {
    if (_address == address(0)) {
      revert ZeroAddress(_field);
    }
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IGrtWines.sol";

interface IListing is IGrtWines {
  //################
  //#### STRUCTS ####

  /// @dev Parameters for creating a Listing. Releases and Listings are matched with {listingId}
  /// @param releaseId The release identifier - Counter from Auctioneer contract
  /// @param listingId The release identifier - Counter from Auctioneer contract
  /// @param startDate Start date of the auction listing
  /// @param endDate End date of the auction listing
  /// @param minimumBid Minumum price to allow the listing to sell for
  /// @param startingPrice Starting price for the listing
  struct Listing {
    uint128 releaseId;
    uint40 startDate;
    uint40 endDate;
    uint256 minimumBid;
    uint256 startingPrice;
  }

  /// @param bidder The release identifier - Counter from Auctioneer contract
  /// @param amount  The amount of the bid
  struct Bid {
    address bidder;
    uint256 amount;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a Listing is created
  event ListingCreated(uint128 listingId, uint128 releaseId);

  /// @dev Emitted when a Listing is updated
  event ListingUpdated(uint128 listingId);

  /// @dev Emitted when a listing is deleted
  event ListingDeleted(uint128 listingId);

  /// @dev Emitted when a bid is successfully registered
  event BidRegistered(
    address indexed bidder,
    uint256 amount,
    uint256 tokenId,
    uint256 listingId
  );

  /// @dev Emitted when bidding is extended due to a bid being received < 10 minutes before cut-off
  event BiddingExtended(uint128 listingId);

  //################
  //#### ERRORS ####
  /// @dev Throw if listing is being deleted while it is active or completed. (TODO NEED TO UPDATE LOGIC IN ENGLISH AUCTION CONTRACT)
  error ListingStarted();

  /// @dev Thrown if certain operations try to be performed on already active listings
  error ListingActive();

  /// @dev Thrown if sender requests the status of a listing that was not listed at this contract.
  error NotListedHere();

  /// @dev Thrown if a bid is invalid, e.g bid < minimum bid, bid < current bid
  error InvalidBid();

  /// @dev Thrown if a bid is placed on a listing that has not started or has expired
  error ListingNotActive();

  /// @dev Thrown if validateTokenClaim or validateEthWithdrawal calls are invalid, e.g bidding still active or claimant not the bidding winner
  error InvalidClaim();

  //###################
  //#### FUNCTIONS ####

  /// @notice Used to create a purchase listing
  /// @dev Only callable by the auctioneer (has AUCTIONEER_ROLE)
  /// @param listingId - ID of the listing
  /// @param listing - Listing struct
  function createListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Used to update a purchase listing
  /// @dev Only callable by the auctioneer (has AUCTIONEER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - ID of the listing
  /// @param listing - Listing struct
  function updateListing(
    uint128 listingId,
    Listing calldata listing,
    bytes calldata data
  ) external;

  /// @notice Used to delete a purchase listing
  /// @dev Only callable by the auctioneer (has AUCTIONEER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - ID of the listing
  function deleteListing(uint128 listingId) external;

  /// @notice Utilised to register a bid for a specific token
  /// @dev Only callable by the auctioneer (has AUCTIONEER_ROLE)
  /// @dev Only if listing has not started yet
  /// @param listingId - The listing ID that this bid relates to
  /// @param tokenId - The tokenId this bid relates to
  /// @param bid - The bid itself
  function registerBid(
    uint128 listingId,
    uint256 tokenId,
    Bid calldata bid,
    bytes calldata data
  ) external;

  /// @notice Utilised to validate that a valid claim of a token is being submitted
  /// @dev Only callable by the auctioneer (has AUCTIONEER_ROLE)
  /// @dev Either returns true on success or reverts
  /// @dev  Only returns true if the claimant is the highest bidder and listing has expired
  /// @param listingId - The listing ID that this bid relates to
  /// @param tokenId - The tokenId this bid relates to
  function validateTokenClaim(
    uint128 listingId,
    uint128 releaseId,
    uint128 tokenId,
    address claimant
  ) external returns (bool valid);

  /// @notice Check if a listing has passed its end date
  /// @dev Should be checked before placing a bid
  /// @param listingId - The id of the listing to check
  function listingEnded(uint128 listingId) external view returns (bool status);

  //#################
  //#### GETTERS ####
  function AUCTIONEER_ROLE() external returns (bytes32 role);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IGrtWines.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../interfaces/IInsuranceRegistry.sol";

/// @title GrtWines Token Contract
/// @author Sean Long
/// @notice A Re-usable contract to form part of the contract system for Trubona Wines
/// @notice Contract will be deployed multiple times with different symbols and names to form part of the claiming and auctioning system
/// @dev Almost entirely stock ERC721 with the exception of externalised mint, burn and update token URI functions which will be guarded by Open Zeppelin RBAC
/// @dev DEFAULT_ADMIN_ROLE is not utilised for any purpose other than being the admin for all other roles
interface ITokenContract is IGrtWines, IERC721 {
  //################
  //#### STRUCTS ####

  /// @dev Holds the arguments for a mint transaction
  /// @param to The account the token should be minted to
  /// @param tokenURI The metadata URI of the token
  struct MintArgs {
    address to;
    string tokenURI;
  }

  /// @dev Holds the arguments necessary for updating a token URI
  /// @param tokenId The token ID to be updated
  /// @param tokenURI The new metadata URI of the token
  struct UpdateMetadataArgs {
    uint256 tokenId;
    string tokenURI;
  }

  /// @dev Holds the arguments necessary for minting tokens with a specific ID
  /// @param to The token ID to be locked
  /// @param tokenURI The metadata URI of the token
  /// @param tokenId The token ID to be minted
  struct MintWithIdArgs {
    address to;
    string tokenURI;
    uint256 tokenId;
  }

  //################
  //#### EVENTS ####

  /// @dev Emitted when a token URI is successfully updated
  /// @param sender The sender of the transaction
  /// @param tokenId The ID of the token that was updated
  /// @param tokenURI The URI the token was updated to
  event TokenURIUpdated(
    address indexed sender,
    uint256 indexed tokenId,
    string tokenURI
  );

  /// @dev Emitted when token metadata is successfully locked
  /// @param sender The sender of the transaction
  /// @param tokenId The ID of the token that was locked
  event TokenMetadataLocked(address indexed sender, uint256 indexed tokenId);

  //################
  //#### ERRORS ####

  /// @dev Thrown if a transaction attempts to update the metadata for a token that has already had an update (locked)
  /// @param sender The sender of the transaction
  /// @param tokenId The tokenId that resulted in the error
  error TokenLocked(address sender, uint256 tokenId);

  /// @dev Thrown if an account attempts to transfer a token that has an insurance event AND msg.sender != redemptionManager
  /// @param tokenId The token ID the attempted to be transferred
  error InsuranceEventRegistered(uint256 tokenId);

  //###################
  //#### FUNCTIONS ####

  /// @notice External mint funciton for Tokens
  /// @dev Bulk mint one or more tokens via MintArgs array for gas efficency.
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE or MINTER_ROLE
  /// @param mintArgs - Array of MintArgs struct. See {MintArgs} for param docs
  function mint(MintArgs[] calldata mintArgs)
    external
    returns (uint256 tokenCount);

  /// @notice External mint function to allow minting token with an explicit ID
  /// @dev Bulk mint one or more tokens with an explicit ID - intended to be used by the RedemptionManager to maintain
  /// @dev Only accessible to MINTER_ROLE which should only be assigned to the RedemptionManager when this contract is deployed as the RedeemedToken
  /// @param mintWithIdArgs - Array of MintWithIdArgs struct. See {MintWithIdArgs} for param docs
  function mintWithId(MintWithIdArgs[] calldata mintWithIdArgs) external;

  /// @notice External burn funciton
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE or BURNER_ROLE
  /// @param tokens - Array of token IDs to burn
  function burn(uint256[] calldata tokens) external;

  /// @notice Change the metadata URI for a given token
  /// @dev Tokens may only be updated once
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE
  /// @param updateArgs - Array of UpdateMetadataArgs struct. See {UpdateMetadataArgs} for param docs
  function changeTokenMetadata(UpdateMetadataArgs[] calldata updateArgs)
    external;

  /// @notice Lock the capability for a token to be updated
  /// @dev This behaves like a fuse and cannot be undone
  /// @dev Only accessible to PLATFORM_ADMIN_ROLE
  /// @param tokens - Array of token IDs to lock
  function lockTokenMetadata(uint256[] calldata tokens) external;

  /// @notice Set the insurance registry address
  /// @param _registryAddress The Address of the insurance registry
  function setInsuranceRegistry(address _registryAddress) external;

  /// @notice Set the redemption manager address
  /// @param _managerAddress The address of the redemption manager
  function setRedemptionManager(address _managerAddress) external;

  //#################
  //#### GETTERS ####

  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);

  function MINTER_ROLE() external returns (bytes32 role);

  function BURNER_ROLE() external returns (bytes32 role);

  function tokenLocked(uint256 tokenId) external returns (bool hasUpdated);

  function insuranceRegistry()
    external
    returns (IInsuranceRegistry registryAddress);

  function redemptionManager() external returns (address managerAddress);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IListing.sol";

interface IAuctioneerAdmin {
  //################
  //#### EVENTS ####

  /// @dev Emitted when a listing type is created
  /// @param listingAddress The address of the listing contract
  /// @param listingType The ID to assign to the listing
  event ListingTypeCreated(
    address indexed listingAddress,
    uint8 indexed listingType
  );

  /// @dev Emitted when the status of a listing is paused / unpaused
  /// @param listingType The ID of the listing that had it's status changed
  /// @param status The status the listing was changed to
  event ListingStatusChanged(
    uint128 indexed listingType,
    bool status
  );

  /// @dev Emitted when all listings are globally paused / unpaused
  /// @param sender The sender of the transaction
  /// @param status The status that the global pause / unpause was changed to
  event AllListingStatusChanged(address indexed sender, bool status);

  //################
  //#### ERRORS ####

  /// @dev Thrown if the specific listing being accessed, or all listings are paused
  error ListingPaused();
  /// @dev Thrown if the listing ID has been taken by an existing implementaiton
  error ListingIdTaken();
  /// @dev Thrown if changing the pause status is a redundant call
  error ListingStatusAlreadySet();

  //###################
  //#### FUNCTIONS ####

  /// @notice Use to register a listing type logic contract
  /// @dev IDs are not sequential and it is assumed that the sender of this transaction has some intelligence around how they use this
  /// @param listingType The ID of the listing type to be created
  /// @param listingContract The address of the listing contract
  function registerListingType(uint8 listingType, address listingContract)
    external;

  /// @notice Pause a specific listing
  /// @dev Specific pause function so that this operation is idempotent
  /// @param listingId The ID of the listing to pause
  function pauseListing(uint128 listingId) external;

  /// @notice Unpause a specific listing
  /// @dev Specific unpause function so that this operation is idempotent
  /// @param listingId The ID of the listing to unpause
  function unpauseListing(uint128 listingId) external;

  /// @notice Pause all listings
  /// @dev Specific pause function so that this operation is idempotent
  function pauseAllListings() external;

  /// @notice Unpause all listings
  /// @dev Specific unpause function so that this operation is idempotent
  function unpauseAllListings() external;

  //################################
  //#### AUTO-GENERATED GETTERS ####

  function allListingsPaused() external returns (bool);

  function listingRegistry(uint8) external returns (IListing);

  function addressListingLookup(address) external returns (uint8);

  function PLATFORM_ADMIN_ROLE() external returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

interface IGrtWines {
  /// @dev Thrown if the sender has incorrect access to use a function
  /// @param sender The sender of the transaction
  error IncorrectAccess(address sender);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                     
*/

import "./IGrtWines.sol";

interface IInsuranceRegistry is IGrtWines {
  //################
  //#### STRUCTS ####

  /// @notice Data structure for registering an insurance event
  /// @param firstAffectedToken The first affected token, this allows us to easily set each bucket'
  /// @param affectedTokens Bitmap of tokens that are void
  struct InsuranceEvent {
    uint256 firstAffectedToken;
    uint256[] affectedTokens;
  }

  //################
  //#### EVENTS ####
  event InsuranceEventRegistered(
    uint256 firstAffectedToken,
    uint256[] affectedTokens
  );

  //################
  //#### ERRORS ####
  //
  //

  //###################
  //#### FUNCTIONS ####

  /// @notice Create an insurance event
  /// @dev It is assumed that the bitmap has been adequately generated off-chain
  /// @dev Emits InsuranceEventRegistered
  /// @param insuranceEvent Insurance event data
  function createInsuranceEvent(InsuranceEvent calldata insuranceEvent)
    external;

  /// @notice Check if a token has an insurance event registered
  /// @param _tokenId The token ID to check
  /// @return isTokenAffected If TRUE token has an insurance claim - transfers except to a RedemptionManager should revert.
  function checkTokenStatus(uint256 _tokenId)
    external
    view
    returns (bool isTokenAffected);

  //################################
  //#### AUTO-GENERATED GETTERS ####
  function PLATFORM_ADMIN_ROLE() external returns (bytes32 role);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

/*
  _______ .______     .___________.____    __    ____  __  .__   __.  _______     _______.
 /  _____||   _  \    |           |\   \  /  \  /   / |  | |  \ |  | |   ____|   /       |
|  |  __  |  |_)  |   `---|  |----` \   \/    \/   /  |  | |   \|  | |  |__     |   (----`
|  | |_ | |      /        |  |       \            /   |  | |  . `  | |   __|     \   \    
|  |__| | |  |\  \----.   |  |        \    /\    /    |  | |  |\   | |  |____.----)   |   
 \______| | _| `._____|   |__|         \__/  \__/     |__| |__| \__| |_______|_______/    
                                                                                    
*/

import "../interfaces/ITokenContract.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "../interfaces/IInsuranceRegistry.sol";
import "../libraries/GrtLibrary.sol";

contract TokenContract is ITokenContract, ERC721URIStorage, AccessControl {
  using Counters for Counters.Counter;

  //#########################
  //#### STATE VARIABLES ####
  Counters.Counter private _tokenIdCounter;
  mapping(uint256 => bool) public override tokenLocked;

  bytes32 public constant override PLATFORM_ADMIN_ROLE =
    keccak256("PLATFORM_ADMIN_ROLE");
  bytes32 public constant override MINTER_ROLE = keccak256("MINTER_ROLE");
  bytes32 public constant override BURNER_ROLE = keccak256("BURNER_ROLE");

  IInsuranceRegistry public override insuranceRegistry;
  address public override redemptionManager;

  //#########################
  //#### IMPLEMENTATION ####
  constructor(
    string memory _name,
    string memory _symbol,
    address platformAdmin,
    address superUser,
    address _insuranceRegistry
  ) ERC721(_name, _symbol) {
    GrtLibrary.checkZeroAddress(platformAdmin, "platform admin");
    GrtLibrary.checkZeroAddress(superUser, "super user");
    GrtLibrary.checkZeroAddress(_insuranceRegistry, "insurance registry");

    insuranceRegistry = IInsuranceRegistry(_insuranceRegistry);
    _setupRole(PLATFORM_ADMIN_ROLE, platformAdmin);
    _setupRole(DEFAULT_ADMIN_ROLE, superUser);
    _setRoleAdmin(MINTER_ROLE, PLATFORM_ADMIN_ROLE);
    _setRoleAdmin(BURNER_ROLE, PLATFORM_ADMIN_ROLE);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal view override {
    //If either of these fields are 0 address it means the token is either being minted or burned. In which case return early to continue tx without reading storage
    //See @openzeppelin ERC721.sol for further details
    if (from == address(0) || to == address(0)) {
      return;
    }
    if (
      insuranceRegistry.checkTokenStatus(tokenId) &&
      msg.sender != redemptionManager
    ) {
      revert InsuranceEventRegistered(tokenId);
    }
  }

  function mint(MintArgs[] calldata mintArgs)
    external
    override
    returns (uint256 mintCount)
  {
    bool canMint = hasRole(MINTER_ROLE, msg.sender) ||
      hasRole(PLATFORM_ADMIN_ROLE, msg.sender);
    if (!canMint) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < mintArgs.length; i++) {
      _tokenIdCounter.increment();
      uint256 currentToken = _tokenIdCounter.current();
      _safeMint(mintArgs[i].to, currentToken);
      _setTokenURI(currentToken, mintArgs[i].tokenURI);
    }
    return _tokenIdCounter.current();
  }

  function mintWithId(MintWithIdArgs[] calldata mintWithIdArgs)
    external
    override
  {
    if (!hasRole(MINTER_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < mintWithIdArgs.length; i++) {
      _safeMint(mintWithIdArgs[i].to, mintWithIdArgs[i].tokenId);
      _setTokenURI(mintWithIdArgs[i].tokenId, mintWithIdArgs[i].tokenURI);
    }
  }

  function burn(uint256[] calldata tokens) external override {
    bool canBurn = hasRole(BURNER_ROLE, msg.sender) ||
      hasRole(PLATFORM_ADMIN_ROLE, msg.sender);
    if (!canBurn) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < tokens.length; i++) {
      _burn(tokens[i]);
    }
  }

  function changeTokenMetadata(UpdateMetadataArgs[] calldata updateArgs)
    external
    override
  {
    if (!hasRole(PLATFORM_ADMIN_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }

    for (uint16 i = 0; i < updateArgs.length; i++) {
      uint256 tokenId = updateArgs[i].tokenId;
      if (tokenLocked[tokenId]) {
        revert TokenLocked(msg.sender, tokenId);
      }
      tokenLocked[tokenId] = true;
      _setTokenURI(tokenId, updateArgs[i].tokenURI);
      emit TokenURIUpdated(msg.sender, tokenId, updateArgs[i].tokenURI);
    }
  }

  function lockTokenMetadata(uint256[] calldata tokens) external override {
    if (!hasRole(PLATFORM_ADMIN_ROLE, msg.sender)) {
      revert IncorrectAccess(msg.sender);
    }
    for (uint16 i = 0; i < tokens.length; i++) {
      tokenLocked[tokens[i]] = true;
      emit TokenMetadataLocked(msg.sender, tokens[i]);
    }
  }

  function setInsuranceRegistry(address _registryAddress)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(_registryAddress, "insurance registry");
    insuranceRegistry = IInsuranceRegistry(_registryAddress);
  }

  function setRedemptionManager(address _managerAddress)
    external
    override
    onlyRole(PLATFORM_ADMIN_ROLE)
  {
    GrtLibrary.checkZeroAddress(_managerAddress, "platform manager");
    redemptionManager = _managerAddress;
  }

  //Due to multiple inhereted Open Zeppelin contracts implementing supportsInterface we must provide an override as below so Solidity knows how to resolve conflicted inheretence
  // https://github.com/OpenZeppelin/openzeppelin-contracts/issues/3107
  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(IERC165, ERC721, AccessControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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